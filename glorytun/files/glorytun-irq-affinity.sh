#!/bin/sh

# Set IRQ affinity for glorytun interfaces
set_irq_affinity() {
    local irq=$1
    local cpu=$2
    local mask=$(printf "%x" $((1 << $cpu)))
    
    echo "Setting IRQ $irq to CPU $cpu (mask: $mask)"
    echo $mask > /proc/irq/$irq/smp_affinity
}

# Get interface IRQs
get_interface_irqs() {
    local interface=$1
    grep -E "$interface" /proc/interrupts | awk '{print $1}' | tr -d ':'
}

# Main function
setup_irq_affinity() {
    # Get available CPU cores
    local cpu_count=$(grep -c processor /proc/cpuinfo)
    echo "Available CPU cores: $cpu_count"
    
    # Determine tun interface
    local tun_interface=$(ip link | grep tun | awk -F': ' '{print $2}' | head -n1)
    if [ -z "$tun_interface" ]; then
        echo "No tun interface found"
        return 1
    fi
    
    echo "Found tun interface: $tun_interface"
    
    # Get IRQs for tun interface
    local irqs=$(get_interface_irqs $tun_interface)
    if [ -z "$irqs" ]; then
        echo "No IRQs found for $tun_interface"
        return 1
    fi
    
    # Distribute IRQs across available cores (except CPU0)
    local cpu=1
    for irq in $irqs; do
        set_irq_affinity $irq $cpu
        cpu=$(( (cpu + 1) % cpu_count ))
        if [ $cpu -eq 0 ]; then
            cpu=1
        fi
    done
    
    # Set RPS (Receive Packet Steering) for better packet distribution
    if [ -e /sys/class/net/$tun_interface/queues/rx-0/rps_cpus ]; then
        # Calculate mask for all CPUs except CPU0
        local rps_mask=$(printf "%x" $(( (1 << $cpu_count) - 2 )))
        echo "Setting RPS mask to $rps_mask for $tun_interface"
        echo $rps_mask > /sys/class/net/$tun_interface/queues/rx-0/rps_cpus
    fi
    
    # Set RFS (Receive Flow Steering) limits if available
    if [ -e /proc/sys/net/core/rps_sock_flow_entries ]; then
        echo 32768 > /proc/sys/net/core/rps_sock_flow_entries
        if [ -e /sys/class/net/$tun_interface/queues/rx-0/rps_flow_cnt ]; then
            echo 32768 > /sys/class/net/$tun_interface/queues/rx-0/rps_flow_cnt
        fi
    fi
    
    # Set XPS (Transmit Packet Steering) if available
    if [ -e /sys/class/net/$tun_interface/queues/tx-0/xps_cpus ]; then
        # Use all CPUs except CPU0 for transmit
        local xps_mask=$(printf "%x" $(( (1 << $cpu_count) - 2 )))
        echo "Setting XPS mask to $xps_mask for $tun_interface"
        echo $xps_mask > /sys/class/net/$tun_interface/queues/tx-0/xps_cpus
    fi
    
    # Increase network queue length for better performance
    if [ -e /sys/class/net/$tun_interface/tx_queue_len ]; then
        echo 1000 > /sys/class/net/$tun_interface/tx_queue_len
    fi
    
    echo "IRQ affinity setup completed for $tun_interface"
}

# Run the main function
setup_irq_affinity

exit 0 