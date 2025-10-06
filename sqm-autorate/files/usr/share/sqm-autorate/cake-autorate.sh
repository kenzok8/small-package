#!/bin/bash

# cake-autorate automatically adjusts CAKE bandwidth(s)
# in dependence on: a) receive and transmit transfer rates; and b) latency
# (or can just be used to monitor and log transfer rates and latency)

# requires: bash; and one of the supported ping binaries

# each cake-autorate instance must be configured using a corresponding config file

# Project homepage: https://github.com/lynxthecat/cake-autorate
# Licence details:  https://github.com/lynxthecat/cake-autorate/blob/master/LICENCE.md

# Author and maintainer: lynxthecat
# Contributors:  rany2; moeller0; richb-hanover

cake_autorate_version="3.1.0-PRERELEASE"

## cake-autorate uses multiple asynchronous processes including:
## main - main process
## monitor_achieved_rates - monitor network transfer rates
## maintain_pingers - manage pingers and active reflectors
## parse_${pinger_binary} - control and parse ping responses
## parse_preprocessor - prepend field for parse_${pinger_binary}
## maintain_log_file - maintain and rotate log file
##
## IPC is facilitated via FIFOs in the form of anonymous pipes
## accessible via fds in the form: ${process_name_fd}
## thereby to enable transferring instructions and data between processes

# Set the IFS to space and comma
IFS=" ,"

# Initialize file descriptors
## -1 signifies that the log file fd will not be used and
## that the log file will be written to directly
log_fd=-1
exec {main_fd}<> <(:)
exec {monitor_achieved_rates_fd}<> <(:)
exec {maintain_pingers_fd}<> <(:)
# pinger_fds are set below in dependence upon ping binary and number of pingers

# process pids are stored below in the form
# proc_pids['process_identifier']=${!}
declare -A proc_pids

# Bash correctness options
## Disable globbing (expansion of *).
set -f
## Forbid using unset variables.
#set -u
## The exit status of a pipeline is the status of the last
## command to exit with a non-zero status, or zero if no
## command exited with a non-zero status.
set -o pipefail

## Errors are intercepted via intercept_stderr below
## and sent to the log file and system log

# Possible performance improvement
export LC_ALL=C

# Set PREFIX
PREFIX=/root/cake-autorate

# shellcheck source=lib.sh
. "${PREFIX}/lib.sh"
# shellcheck source=defaults.sh
. "${PREFIX}/defaults.sh"
# get valid config overrides
mapfile -t valid_config_entries < <(grep -E '^[^(#| )].*=' "${PREFIX}/defaults.sh" | sed -e 's/[\t ]*\#.*//g' -e 's/=.*//g')

trap cleanup_and_killall INT TERM EXIT

cleanup_and_killall()
{	
	# Do not fail on error for this critical cleanup code
	set +e

	trap true INT TERM EXIT
	
	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"
	
	log_msg "INFO" "Stopping cake-autorate with PID: ${BASHPID} and config: ${config_path}"
	
	log_msg "INFO" "Killing all background processes and cleaning up temporary files."

	printf "TERMINATE\n" >&"${maintain_pingers_fd}"
	printf "TERMINATE\n" >&"${monitor_achieved_rates_fd}"

	[[ -d "${run_path}" ]] && rm -r "${run_path}"
	rmdir /var/run/cake-autorate 2>/dev/null

	# give some time for processes to gracefully exit
	sleep_s 1

	# terminate any processes that remain, save for main and intercept_stderr
	unset "proc_pids[main]"
	intercept_stderr_pid="${proc_pids[intercept_stderr]:-}"
	if [[ -n "${intercept_stderr_pid}" ]]
	then
		unset "proc_pids[intercept_stderr]"
	fi
	terminate "${proc_pids[@]}"

	# restore original stderr, and terminate intercept_stderr
	if [[ -n "${intercept_stderr_pid}" ]]
	then
		exec 2>&"${original_stderr_fd}"
		terminate "${intercept_stderr_pid}"
	fi

	log_msg "SYSLOG" "Stopped cake-autorate with PID: ${BASHPID} and config: ${config_path}"

	trap - INT TERM EXIT
	exit
}

log_msg()
{
	# send logging message to terminal, log file fifo, log file and/or system logger

	local type="${1}"
	local msg="${2}"
	local instance_id="${instance_id:-"unknown"}"
	local log_timestamp=${EPOCHREALTIME}

	case ${type} in

		DEBUG)
			((debug == 0)) && return # skip over DEBUG messages where debug disabled
			((log_DEBUG_messages_to_syslog)) && ((use_logger)) && \
				logger -t "cake-autorate.${instance_id}" "${type}: ${log_timestamp} ${msg}"
			;;

		ERROR)
			((use_logger)) && \
				logger -t "cake-autorate.${instance_id}" "${type}: ${log_timestamp} ${msg}"
			;;

		SYSLOG)
			((use_logger)) && \
				logger -t "cake-autorate.${instance_id}" "INFO: ${log_timestamp} ${msg}"
			;;

		*)
			;;
	esac

	# Output to the log file fifo if available (for rotation handling)
	# else output directly to the log file
	if (( log_fd >= 0 ))
	then
		((log_to_file)) && printf '%s; %(%F-%H:%M:%S)T; %s; %s\n' "${type}" -1 "${log_timestamp}" "${msg}" >&"${log_fd}"
	else
		((log_to_file)) && printf '%s; %(%F-%H:%M:%S)T; %s; %s\n' "${type}" -1 "${log_timestamp}" "${msg}" >> "${log_file_path}"
	fi

	((terminal)) && printf '%s; %(%F-%H:%M:%S)T; %s; %s\n' "${type}" -1 "${log_timestamp}" "${msg}"
}

print_headers()
{
	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	header="DATA_HEADER; LOG_DATETIME; LOG_TIMESTAMP; PROC_TIME_US; DL_ACHIEVED_RATE_KBPS; UL_ACHIEVED_RATE_KBPS; DL_LOAD_PERCENT; UL_LOAD_PERCENT; ICMP_TIMESTAMP; REFLECTOR; SEQUENCE; DL_OWD_BASELINE; DL_OWD_US; DL_OWD_DELTA_EWMA_US; DL_OWD_DELTA_US; DL_ADJ_DELAY_THR; UL_OWD_BASELINE; UL_OWD_US; UL_OWD_DELTA_EWMA_US; UL_OWD_DELTA_US; UL_ADJ_DELAY_THR; DL_SUM_DELAYS; DL_AVG_OWD_DELTA_US; DL_ADJ_AVG_OWD_DELTA_THR_US; UL_SUM_DELAYS; UL_AVG_OWD_DELTA_US; UL_ADJ_AVG_OWD_DELTA_THR_US; DL_LOAD_CONDITION; UL_LOAD_CONDITION; CAKE_DL_RATE_KBPS; CAKE_UL_RATE_KBPS"
	((log_to_file)) && printf '%s\n' "${header}" >> "${log_file_path}"
	((terminal)) && printf '%s\n' "${header}"

	header="LOAD_HEADER; LOG_DATETIME; LOG_TIMESTAMP; PROC_TIME_US; DL_ACHIEVED_RATE_KBPS; UL_ACHIEVED_RATE_KBPS; CAKE_DL_RATE_KBPS; CAKE_UL_RATE_KBPS"
	((log_to_file)) && printf '%s\n' "${header}" >> "${log_file_path}"
	((terminal)) && printf '%s\n' "${header}"

	header="REFLECTOR_HEADER; LOG_DATETIME; LOG_TIMESTAMP; PROC_TIME_US; REFLECTOR; MIN_SUM_OWD_BASELINES_US; SUM_OWD_BASELINES_US; SUM_OWD_BASELINES_DELTA_US; SUM_OWD_BASELINES_DELTA_THR_US; MIN_DL_DELTA_EWMA_US; DL_DELTA_EWMA_US; DL_DELTA_EWMA_DELTA_US; DL_DELTA_EWMA_DELTA_THR; MIN_UL_DELTA_EWMA_US; UL_DELTA_EWMA_US; UL_DELTA_EWMA_DELTA_US; UL_DELTA_EWMA_DELTA_THR"
	((log_to_file)) && printf '%s\n' "${header}" >> "${log_file_path}"
	((terminal)) && printf '%s\n' "${header}"

	header="SUMMARY_HEADER; LOG_DATETIME; LOG_TIMESTAMP; DL_ACHIEVED_RATE_KBPS; UL_ACHIEVED_RATE_KBPS; DL_SUM_DELAYS; UL_SUM_DELAYS; DL_AVG_OWD_DELTA_US; UL_AVG_OWD_DELTA_US; DL_LOAD_CONDITION; UL_LOAD_CONDITION; CAKE_DL_RATE_KBPS; CAKE_UL_RATE_KBPS"
	((log_to_file)) && printf '%s\n' "${header}" >> "${log_file_path}"
	((terminal)) && printf '%s\n' "${header}"
}

# MAINTAIN_LOG_FILE + HELPER FUNCTIONS

rotate_log_file()
{
	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	if [[ -f ${log_file_path} ]]
	then
		cat "${log_file_path}" > "${log_file_path}.old"
		true > "${log_file_path}"
	fi

	((output_processing_stats)) && print_headers
	t_log_file_start_us=${EPOCHREALTIME/./}
	get_log_file_size_bytes
}

reset_log_file()
{
	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	rm -f "${log_file_path}.old"
	true > "${log_file_path}"

	((output_processing_stats)) && print_headers
	t_log_file_start_us=${EPOCHREALTIME/./}
	get_log_file_size_bytes
}

generate_log_file_scripts()
{
	cat > "${run_path}/log_file_export" <<- EOT
	#!/bin/bash

	timeout_s=\${1:-20}

	if kill -USR1 "${proc_pids['maintain_log_file']}"
	then
		printf "Successfully signalled maintain_log_file process to request log file export.\n"
	else
		printf "ERROR: Failed to signal maintain_log_file process.\n" >&2
		exit 1
	fi
	rm -f "${run_path}/last_log_file_export"

	read_try=0

	while [[ ! -f "${run_path}/last_log_file_export" ]]
	do
		sleep 1
		if (( ++read_try >= \${timeout_s} ))
		then
			printf "ERROR: Timeout (\${timeout_s}s) reached before new log file export identified.\n" >&2
			exit 1
		fi
	done

	read -r log_file_export_path < "${run_path}/last_log_file_export"

	printf "Log file export complete.\n"

	printf "Log file available at location: "
	printf "\${log_file_export_path}\n"
	EOT

	cat > "${run_path}/log_file_reset" <<- EOT
	#!/bin/bash

	if kill -USR2 "${proc_pids['maintain_log_file']}"
	then
		printf "Successfully signalled maintain_log_file process to request log file reset.\n"
	else
		printf "ERROR: Failed to signal maintain_log_file process.\n" >&2
		exit 1
	fi
	EOT

	chmod +x "${run_path}/log_file_export" "${run_path}/log_file_reset"
}

export_log_file()
{
	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	printf -v log_file_export_datetime '%(%Y_%m_%d_%H_%M_%S)T'
	log_file_export_path="${log_file_path/.log/_${log_file_export_datetime}.log}"
	log_msg "DEBUG" "Exporting log file with path: ${log_file_path/.log/_${log_file_export_datetime}.log}"

	# Now export with or without compression to the appropriate export path
	if ((log_file_export_compress))
	then
		log_file_export_path="${log_file_export_path}.gz"
		if [[ -f "${log_file_path}.old" ]]
		then
			gzip -c "${log_file_path}.old" > "${log_file_export_path}"
			gzip -c "${log_file_path}" >> "${log_file_export_path}"
		else
			gzip -c "${log_file_path}" > "${log_file_export_path}"
		fi
	else
		if [[ -f "${log_file_path}.old" ]]
		then
			cp "${log_file_path}.old" "${log_file_export_path}"
			cat "${log_file_path}" >> "${log_file_export_path}"
		else
			cp "${log_file_path}" "${log_file_export_path}"
		fi
	fi

	printf '%s' "${log_file_export_path}" > "${run_path}/last_log_file_export"
}

flush_log_fd()
{
	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"
	while read -r -t 0 -u "${log_fd}"
	do
		read -r -u "${log_fd}" log_line
		printf '%s\n' "${log_line}" >> "${log_file_path}"
	done
}

get_log_file_size_bytes()
{
	log_file_size_bytes=$(wc -c "${log_file_path}" 2>/dev/null | awk '{print $1}')
	log_file_size_bytes=${log_file_size_bytes:-0}
}

kill_maintain_log_file()
{
	trap - TERM EXIT
	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"
	flush_log_fd
	exit
}

maintain_log_file()
{
	trap '' INT
	trap 'kill_maintain_log_file' TERM EXIT
	trap 'export_log_file' USR1
	trap 'reset_log_file_signalled=1' USR2

	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	reset_log_file_signalled=0
	t_log_file_start_us=${EPOCHREALTIME/./}

	get_log_file_size_bytes

	while read -r -u "${log_fd}" log_line
	do

		printf '%s\n' "${log_line}" >> "${log_file_path}"

		# Verify log file size < configured maximum
		# The following two lines with costly call to 'du':
		# 	read log_file_size_bytes< <(du -b ${log_file_path}/cake-autorate.log)
		# 	log_file_size_bytes=${log_file_size_bytes//[!0-9]/}
		# can be more efficiently handled with this line:
		((log_file_size_bytes=log_file_size_bytes+${#log_line}+1))

		# Verify log file time < configured maximum
		if (( (${EPOCHREALTIME/./}-t_log_file_start_us) > log_file_max_time_us ))
		then

			log_msg "DEBUG" "log file maximum time: ${log_file_max_time_mins} minutes has elapsed so flushing and rotating log file."
			flush_log_fd
			rotate_log_file
		elif (( log_file_size_bytes > log_file_max_size_bytes ))
		then
			log_file_size_KB=$((log_file_size_bytes/1024))
			log_msg "DEBUG" "log file size: ${log_file_size_KB} KB has exceeded configured maximum: ${log_file_max_size_KB} KB so flushing and rotating log file."
			flush_log_fd
			rotate_log_file
		elif (( reset_log_file_signalled ))
		then
			log_msg "DEBUG" "received log file reset signal so flushing and resetting log file."
			flush_log_fd
			reset_log_file
			reset_log_file_signalled=0
		fi

	done
}

update_shaper_rate()
{
	local direction="${1}" # 'dl' or 'ul'

	case "${load_condition["${direction}"]}" in

		# upload Starlink satelite switching compensation, so drop down to minimum rate for upload through switching period
		ul*sss)
			shaper_rate_kbps["${direction}"]="${min_shaper_rate_kbps[${direction}]}"
			;;
		# download Starlink satelite switching compensation, so drop down to base rate for download through switching period
		dl*sss)
			shaper_rate_kbps["${direction}"]=$(( shaper_rate_kbps["${direction}"] > base_shaper_rate_kbps["${direction}"] ? base_shaper_rate_kbps["${direction}"] : shaper_rate_kbps["${direction}"] ))
			;;
		# bufferbloat detected, so decrease the rate providing not inside bufferbloat refractory period
		*bb*)
			if (( t_start_us > (t_last_bufferbloat_us["${direction}"]+bufferbloat_refractory_period_us) ))
			then
				if (( compensated_avg_owd_delta_thr_us["${direction}"] <= compensated_owd_delta_thr_us["${direction}"] ))
				then
					shaper_rate_adjust_down_bufferbloat_factor=1000
				elif (( (avg_owd_delta_us["${direction}"]-compensated_owd_delta_thr_us["${direction}"]) > 0 ))
				then
					shaper_rate_adjust_down_bufferbloat_factor=$(( (1000*(avg_owd_delta_us["${direction}"]-compensated_owd_delta_thr_us["${direction}"]))/(compensated_avg_owd_delta_thr_us["${direction}"]-compensated_owd_delta_thr_us["${direction}"]) ))
					(( shaper_rate_adjust_down_bufferbloat_factor > 1000 )) && shaper_rate_adjust_down_bufferbloat_factor=1000
				else
					shaper_rate_adjust_down_bufferbloat_factor=0
				fi
				shaper_rate_adjust_down_bufferbloat=$(( 1000*shaper_rate_min_adjust_down_bufferbloat-shaper_rate_adjust_down_bufferbloat_factor*(shaper_rate_min_adjust_down_bufferbloat-shaper_rate_max_adjust_down_bufferbloat) ))
				shaper_rate_kbps["${direction}"]=$(( (shaper_rate_kbps["${direction}"]*shaper_rate_adjust_down_bufferbloat)/1000000 )) 
				t_last_bufferbloat_us["${direction}"]="${EPOCHREALTIME/./}"
			fi
			;;
		# high load, so increase rate providing not inside bufferbloat refractory period
		*high*)
			if (( t_start_us > (t_last_bufferbloat_us["${direction}"]+bufferbloat_refractory_period_us) ))
			then
				shaper_rate_kbps["${direction}"]=$(( (shaper_rate_kbps["${direction}"]*shaper_rate_adjust_up_load_high)/1000 ))
			fi
			;;
		# low or idle load, so determine whether to decay down towards base rate, decay up towards base rate, or set as base rate
		*low*|*idle*)
			if (( t_start_us > (t_last_decay_us["${direction}"]+decay_refractory_period_us) ))
			then

				if ((shaper_rate_kbps["${direction}"] > base_shaper_rate_kbps["${direction}"]))
				then
					decayed_shaper_rate_kbps=$(( (shaper_rate_kbps["${direction}"]*shaper_rate_adjust_down_load_low)/1000 ))
					shaper_rate_kbps["${direction}"]=$(( decayed_shaper_rate_kbps > base_shaper_rate_kbps["${direction}"] ? decayed_shaper_rate_kbps : base_shaper_rate_kbps["${direction}"]))
				elif ((shaper_rate_kbps["${direction}"] < base_shaper_rate_kbps["${direction}"]))
				then
					decayed_shaper_rate_kbps=$(( (shaper_rate_kbps["${direction}"]*shaper_rate_adjust_up_load_low)/1000 ))
					shaper_rate_kbps["${direction}"]=$(( decayed_shaper_rate_kbps < base_shaper_rate_kbps["${direction}"] ? decayed_shaper_rate_kbps : base_shaper_rate_kbps["${direction}"]))
				fi

				t_last_decay_us["${direction}"]="${EPOCHREALTIME/./}"
			fi
			;;
		*)
			log_msg "ERROR" "unknown load condition: ${load_condition[${direction}]} in update_shaper_rate"
			kill $$ 2>/dev/null
			;;
	esac
	# make sure to only return rates between cur_min_rate and cur_max_rate
	((shaper_rate_kbps["${direction}"] < min_shaper_rate_kbps["${direction}"])) && shaper_rate_kbps["${direction}"]="${min_shaper_rate_kbps[${direction}]}"
	((shaper_rate_kbps["${direction}"] > max_shaper_rate_kbps["${direction}"])) && shaper_rate_kbps["${direction}"]="${max_shaper_rate_kbps[${direction}]}"
}

monitor_achieved_rates()
{
	trap '' INT

	# track rx and tx bytes transfered and divide by time since last update
	# to determine achieved dl and ul transfer rates

	local rx_bytes_path="${1}"
	local tx_bytes_path="${2}"
	local monitor_achieved_rates_interval_us="${3}" # (microseconds)

	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	compensated_monitor_achieved_rates_interval_us="${monitor_achieved_rates_interval_us}"

	[[ -f "${rx_bytes_path}" ]] && { read -r prev_rx_bytes < "${rx_bytes_path}"; } 2> /dev/null || prev_rx_bytes=0
	[[ -f "${tx_bytes_path}" ]] && { read -r prev_tx_bytes < "${tx_bytes_path}"; } 2> /dev/null || prev_tx_bytes=0

	sleep_duration_s=0
	t_start_us=0

	declare -A achieved_rate_kbps
	declare -A load_percent

	while true
	do
		t_start_us="${EPOCHREALTIME/./}"

		while read -r -t 0 -u "${monitor_achieved_rates_fd}"
		do
			unset command
			read -r -u "${monitor_achieved_rates_fd}" -a command
			case "${command[0]:-}" in

				SET_VAR)
					if [[ "${#command[@]}" -eq 3 ]]
					then
						export -n "${command[1]}=${command[2]}"
					fi
					;;
				SET_ARRAY_ELEMENT)
					if [[ "${#command[@]}" -eq 4 ]]
					then
						declare -A "${command[1]}"+="([${command[2]}]=${command[3]})"
					fi
					;;
				TERMINATE)
					log_msg "DEBUG" "Terminating monitor_achieved_rates."
					exit
					;;
				*)
					:
					;;
			esac
		done

		# If rx/tx bytes file exists, read it in, otherwise set to prev_bytes
		# This addresses interfaces going down and back up
		[[ -f "${rx_bytes_path}" ]] && { read -r rx_bytes < "${rx_bytes_path}"; } 2> /dev/null || rx_bytes="${prev_rx_bytes}"
		[[ -f "${tx_bytes_path}" ]] && { read -r tx_bytes < "${tx_bytes_path}"; } 2> /dev/null || tx_bytes="${prev_tx_bytes}"

		achieved_rate_kbps[dl]=$(( (8000*(rx_bytes - prev_rx_bytes)) / compensated_monitor_achieved_rates_interval_us ))
		achieved_rate_kbps[ul]=$(( (8000*(tx_bytes - prev_tx_bytes)) / compensated_monitor_achieved_rates_interval_us ))

		((achieved_rate_kbps[dl]<0)) && achieved_rate_kbps[dl]=0
		((achieved_rate_kbps[ul]<0)) && achieved_rate_kbps[ul]=0

		printf "SET_ARRAY_ELEMENT achieved_rate_kbps dl %s\n" "${achieved_rate_kbps[dl]}" >&"${main_fd}"
		printf "SET_ARRAY_ELEMENT achieved_rate_kbps ul %s\n" "${achieved_rate_kbps[ul]}" >&"${main_fd}"

		load_percent[dl]=$(( (100*achieved_rate_kbps[dl])/shaper_rate_kbps[dl] ))
		load_percent[ul]=$(( (100*achieved_rate_kbps[ul])/shaper_rate_kbps[ul] ))

		for pinger_fd in "${pinger_fds[@]:?}"
		do
			printf "SET_ARRAY_ELEMENT load_percent dl %s\n" "${load_percent[dl]}" >&"${pinger_fd}"
			printf "SET_ARRAY_ELEMENT load_percent ul %s\n" "${load_percent[ul]}" >&"${pinger_fd}"
		done

		if ((output_load_stats))
		then

			printf -v load_stats '%s; %s; %s; %s; %s' "${EPOCHREALTIME}" "${achieved_rate_kbps[dl]}" "${achieved_rate_kbps[ul]}" "${shaper_rate_kbps[dl]}" "${shaper_rate_kbps[ul]}"
			log_msg "LOAD" "${load_stats}"
		fi

		prev_rx_bytes="${rx_bytes}"
		prev_tx_bytes="${tx_bytes}"

		compensated_monitor_achieved_rates_interval_us=$(( monitor_achieved_rates_interval_us>(10*max_wire_packet_rtt_us) ? monitor_achieved_rates_interval_us : 10*max_wire_packet_rtt_us ))

		sleep_remaining_tick_time "${t_start_us}" "${compensated_monitor_achieved_rates_interval_us}"

	done
}


classify_load()
{
	# classify the load according to high/low/idle and add _delayed if delayed
	# thus ending up with high_delayed, low_delayed, etc.
	local direction="${1}"

	if (( load_percent["${direction}"] > high_load_thr_percent ))
	then
		load_condition["${direction}"]="high"
	elif (( achieved_rate_kbps["${direction}"] > connection_active_thr_kbps ))
	then
		load_condition["${direction}"]="low"
	else
		load_condition["${direction}"]="idle"
	fi

	((bufferbloat_detected["${direction}"])) && load_condition["${direction}"]="${load_condition[${direction}]}_bb"

	if ((sss_compensation))
	then
		# shellcheck disable=SC2154
		for sss_time_us in "${sss_times_us[@]}"
		do
			((timestamp_usecs_past_minute=${EPOCHREALTIME/./}%60000000))
			if (( (timestamp_usecs_past_minute > (sss_time_us-sss_compensation_pre_duration_us)) && (timestamp_usecs_past_minute < (sss_time_us+sss_compensation_post_duration_us)) ))
			then
				load_condition["${direction}"]="${load_condition[${direction}]}_sss"
				break
			fi
		done
	fi

	load_condition["${direction}"]="${direction}_${load_condition[${direction}]}"
}

# MAINTAIN PINGERS + ASSOCIATED HELPER FUNCTIONS

parse_preprocessor()
{
	# prepend REFLECTOR_RESPONSE and append timestamp as a checksum
	while read -r timestamp remainder
	do
		printf "REFLECTOR_RESPONSE %s %s %s\n" "${timestamp}" "${remainder}" "${timestamp}" >&"${pinger_fds[pinger]}"
	done
}

parse_tsping()
{
	trap '' INT
	trap 'terminate "${pinger_pid}" "${parse_preprocessor_pid}"' TERM EXIT

	local parse_id="${1}"
	local reflectors=("${@:2}")

	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	declare -A dl_owd_baselines_us
	declare -A ul_owd_baselines_us
	declare -A dl_owd_delta_ewmas_us
	declare -A ul_owd_delta_ewmas_us

	for (( reflector=0; reflector<no_pingers; reflector++ ))
	do
		dl_owd_baselines_us["${reflectors[reflector]}"]=100000
		ul_owd_baselines_us["${reflectors[reflector]}"]=100000
		dl_owd_delta_ewmas_us["${reflectors[reflector]}"]=0
		ul_owd_delta_ewmas_us["${reflectors[reflector]}"]=0
	done

	declare -A load_percent
	load_percent[dl]=0
	load_percent[ul]=0

	while true
	do
		unset command
		read -r -u "${pinger_fds[pinger]}" -a command
		[[ "${#command[@]}" -eq 0 ]] && continue

		case "${command[0]}" in
			REFLECTOR_RESPONSE)
				read -r timestamp reflector seq _ _ _ _ _ dl_owd_ms ul_owd_ms checksum <<< "${command[@]:1}"
				;;

			START_PINGER)

				exec {parse_preprocessor_fd}> >(parse_preprocessor)
				parse_preprocessor_pid="${!}"
				printf "SET_PROC_PID proc_pids %s %s\n" "${parse_id}_preprocessor" "${parse_preprocessor_pid}" >&"${main_fd}"
				# accommodate present tsping interval/sleep handling to prevent ping flood with only one pinger
				tsping_sleep_time=$(( no_pingers == 1 ? ping_response_interval_ms : 0 ))
				${ping_prefix_string} tsping ${ping_extra_args} --print-timestamps --machine-readable=, --sleep-time "${tsping_sleep_time}" --target-spacing "${ping_response_interval_ms}" "${reflectors[@]:0:${no_pingers}}" 2>/dev/null >&"${parse_preprocessor_fd}" &
				pinger_pid="${!}"
				printf "SET_PROC_PID proc_pids %s %s\n" "${parse_id}_pinger" "${pinger_pid}" >&"${main_fd}"
				continue
				;;

			KILL_PINGER)

				terminate "${pinger_pid}" "${parse_preprocessor_pid}"
				exec {parse_preprocessor_fd}>/dev/null
				continue
				;;

			SET_REFLECTORS)

				read -r -a reflectors <<< "${command[@]:1}"
				log_msg "DEBUG" "Read in new reflectors: ${reflectors[*]}"
				for (( reflector=0; reflector<no_pingers; reflector++ ))
				do
					dl_owd_baselines_us["${reflectors[reflector]}"]="${dl_owd_baselines_us[${reflectors[reflector]}]:-100000}"
					ul_owd_baselines_us["${reflectors[reflector]}"]="${ul_owd_baselines_us[${reflectors[reflector]}]:-100000}"
					dl_owd_delta_ewmas_us["${reflectors[reflector]}"]="${dl_owd_delta_ewmas_us[${reflectors[reflector]}]:-0}"
					ul_owd_delta_ewmas_us["${reflectors[reflector]}"]="${ul_owd_delta_ewmas_us[${reflectors[reflector]}]:-0}"
				done
				continue
				;;

			SET_VAR)

				if [[ "${#command[@]}" -eq 3 ]]
				then
					export -n "${command[1]}=${command[2]}"
				fi
				continue
				;;

			SET_ARRAY_ELEMENT)

				if [[ "${#command[@]}" -eq 4 ]]
				then
					declare -A "${command[1]}"+="([${command[2]}]=${command[3]})"
				fi
				continue
				;;

			TERMINATE)

				log_msg "DEBUG" "Terminating parse_tsping."
				exit
				;;

			*)
				continue
				;;
		esac

		[[ "${timestamp:-}" && "${reflector:-}" && "${seq:-}" && "${dl_owd_ms:-}" && "${ul_owd_ms:-}" && "${checksum:-}" ]] || continue
		[[ "${checksum}" == "${timestamp}" ]] || continue

		dl_owd_us="${dl_owd_ms}000"
		ul_owd_us="${ul_owd_ms}000"

		dl_owd_delta_us=$(( dl_owd_us - dl_owd_baselines_us[${reflector}] ))
		ul_owd_delta_us=$(( ul_owd_us - ul_owd_baselines_us[${reflector}] ))

		# tsping employs ICMP type 13 and works with timestamps: Originate; Received; Transmit; and Finished, such that:
		#
		# dl_owd_us = Finished - Transmit
		# ul_owd_us = Received - Originate
		#
		# The timestamps are supposed to relate to milliseconds past midnight UTC, albeit implementation varies, and,
		# in any case, timestamps rollover at the local and/or remote ends, and the rollover may not be synchronized.
		#
		# Such an event would result in a huge spike in dl_owd_us or ul_owd_us and a lare delta relative to the baseline.
		#
		# So, to compensate, in the event that delta > 50 mins, immediately reset the baselines to the new dl_owd_us and ul_owd_us.
		#
		# Happilly, the sum of dl_owd_baseline_us and ul_owd_baseline_us will roughly equal rtt_baseline_us.
		# And since Transmit is approximately equal to Received, RTT is approximately equal to Finished - Originate.
		# And thus the sum of dl_owd_baseline_us and ul_owd_baseline_us should not be affected by the rollover/compensation.
		# Hence working with this sum, rather than the individual components, is useful for the reflector health check in maintain_pingers().

		if (( (${dl_owd_delta_us#-} + ${ul_owd_delta_us#-}) < 3000000000 ))
		then

			dl_alpha=$(( dl_owd_us >= dl_owd_baselines_us[${reflector}] ? alpha_baseline_increase : alpha_baseline_decrease ))
			ul_alpha=$(( ul_owd_us >= ul_owd_baselines_us[${reflector}] ? alpha_baseline_increase : alpha_baseline_decrease ))

			ewma_iteration "${dl_owd_us}" "${dl_alpha}" "dl_owd_baselines_us[${reflector}]"
			ewma_iteration "${ul_owd_us}" "${ul_alpha}" "ul_owd_baselines_us[${reflector}]"

			dl_owd_delta_us=$(( dl_owd_us - dl_owd_baselines_us[${reflector}] ))
			ul_owd_delta_us=$(( ul_owd_us - ul_owd_baselines_us[${reflector}] ))
		else
			dl_owd_baselines_us[${reflector}]=${dl_owd_us}
			ul_owd_baselines_us[${reflector}]=${ul_owd_us}

			dl_owd_delta_us=0
			ul_owd_delta_us=0
		fi

		if (( load_percent[dl] < high_load_thr_percent && load_percent[ul] < high_load_thr_percent))
		then
			ewma_iteration "${dl_owd_delta_us}" "${alpha_delta_ewma}" "dl_owd_delta_ewmas_us[${reflector}]"
			ewma_iteration "${ul_owd_delta_us}" "${alpha_delta_ewma}" "ul_owd_delta_ewmas_us[${reflector}]"
		fi

		printf "REFLECTOR_RESPONSE %s %s %s %s %s %s %s %s %s %s %s\n" "${timestamp}" "${reflector}" "${seq}" "${dl_owd_baselines_us[${reflector}]}" "${dl_owd_us}" "${dl_owd_delta_ewmas_us[${reflector}]}" "${dl_owd_delta_us}" "${ul_owd_baselines_us[${reflector}]}" "${ul_owd_us}" "${ul_owd_delta_ewmas_us[${reflector}]}" "${ul_owd_delta_us}" >&"${main_fd}"

		timestamp_us="${timestamp//[.]}"

		printf "SET_ARRAY_ELEMENT dl_owd_baselines_us %s %s\n" "${reflector}" "${dl_owd_baselines_us[${reflector}]}" >&"${maintain_pingers_fd}"
		printf "SET_ARRAY_ELEMENT ul_owd_baselines_us %s %s\n" "${reflector}" "${ul_owd_baselines_us[${reflector}]}" >&"${maintain_pingers_fd}"

		printf "SET_ARRAY_ELEMENT dl_owd_delta_ewmas_us %s %s\n" "${reflector}" "${dl_owd_delta_ewmas_us[${reflector}]}" >&"${maintain_pingers_fd}"
		printf "SET_ARRAY_ELEMENT ul_owd_delta_ewmas_us %s %s\n" "${reflector}" "${ul_owd_delta_ewmas_us[${reflector}]}" >&"${maintain_pingers_fd}"

		printf "SET_ARRAY_ELEMENT last_timestamp_reflectors_us %s %s\n" "${reflector}" "${timestamp_us}" >&"${maintain_pingers_fd}"
	done
}

parse_fping()
{
	trap '' INT
	trap 'terminate "${pinger_pid}" "${parse_preprocessor_pid}"' TERM EXIT

	local parse_id="${1}"

	local reflectors=("${@:2}")

	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	declare -A dl_owd_baselines_us
	declare -A ul_owd_baselines_us
	declare -A dl_owd_delta_ewmas_us
	declare -A ul_owd_delta_ewmas_us

	for (( reflector=0; reflector<no_pingers; reflector++ ))
	do
		dl_owd_baselines_us["${reflectors[reflector]}"]=100000
		ul_owd_baselines_us["${reflectors[reflector]}"]=100000
		dl_owd_delta_ewmas_us["${reflectors[reflector]}"]=0
		ul_owd_delta_ewmas_us["${reflectors[reflector]}"]=0
	done

	declare -A load_percent
	load_percent[dl]=0
	load_percent[ul]=0

	t_start_us="${EPOCHREALTIME/./}"

	while true
	do
		unset command
		read -r -u "${pinger_fds[pinger]}" -a command
		[[ "${#command[@]}" -eq 0 ]] && continue

		case "${command[0]}" in

			REFLECTOR_RESPONSE)

				read -r timestamp reflector _ seq_rtt <<< "${command[@]:1}"
				checksum="${command[*]: -1}"
				;;

			START_PINGER)

				exec {parse_preprocessor_fd}> >(parse_preprocessor)
				parse_preprocessor_pid="${!}"
				printf "SET_PROC_PID proc_pids %s %s\n" "${parse_id}_preprocessor" "${parse_preprocessor_pid}" >&"${main_fd}"
				${ping_prefix_string} fping ${ping_extra_args} --timestamp --loop --period "${reflector_ping_interval_ms}" --interval "${ping_response_interval_ms}" --timeout 10000 "${reflectors[@]:0:${no_pingers}}" 2> /dev/null >&"${parse_preprocessor_fd}" &
				pinger_pid="${!}"
				printf "SET_PROC_PID proc_pids %s %s\n" "${parse_id}_pinger" "${pinger_pid}" >&"${main_fd}"
				continue
				;;

			KILL_PINGER)

				terminate "${pinger_pid}" "${parse_preprocessor_pid}"
				exec {parse_preprocessor_fd}>&-
				continue
				;;

			SET_REFLECTORS)

				read -r -a reflectors <<< "${command[@]:1}"
				log_msg "DEBUG" "Read in new reflectors: ${reflectors[*]}"
				for (( reflector=0; reflector<no_pingers; reflector++ ))
				do
					dl_owd_baselines_us["${reflectors[reflector]}"]="${dl_owd_baselines_us[${reflectors[reflector]}]:-100000}"
					ul_owd_baselines_us["${reflectors[reflector]}"]="${ul_owd_baselines_us[${reflectors[reflector]}]:-100000}"
					dl_owd_delta_ewmas_us["${reflectors[reflector]}"]="${dl_owd_delta_ewmas_us[${reflectors[reflector]}]:-0}"
					ul_owd_delta_ewmas_us["${reflectors[reflector]}"]="${ul_owd_delta_ewmas_us[${reflectors[reflector]}]:-0}"
				done
				continue
				;;

			SET_VAR)

				if [[ "${#command[@]}" -eq 3 ]]
				then
						export -n "${command[1]}=${command[2]}"
				fi
				continue
				;;

			SET_ARRAY_ELEMENT)

				if [[ "${#command[@]}" -eq 4 ]]
				then
						declare -A "${command[1]}"+="([${command[2]}]=${command[3]})"
				fi
				continue
				;;

			TERMINATE)

				log_msg "DEBUG" "Terminating parse_fping."
				exit
				;;

			*)
				continue
				;;
		esac

		[[ "${timestamp:-}" && "${reflector:-}" && "${seq_rtt:-}" && "${checksum:-}" ]] || continue
		[[ "${checksum}" == "${timestamp}" ]] || continue

		[[ "${seq_rtt}" =~ \[([0-9]+)\].*[[:space:]]([0-9]+)\.?([0-9]+)?[[:space:]]ms ]] || continue

		seq="${BASH_REMATCH[1]}"

		rtt_us="${BASH_REMATCH[3]}000"
		rtt_us=$((${BASH_REMATCH[2]}000+10#${rtt_us:0:3}))

		dl_owd_us=$((rtt_us/2))
		ul_owd_us="${dl_owd_us}"

		dl_alpha=$(( dl_owd_us >= dl_owd_baselines_us[${reflector}] ? alpha_baseline_increase : alpha_baseline_decrease ))

		ewma_iteration "${dl_owd_us}" "${dl_alpha}" "dl_owd_baselines_us[${reflector}]"
		ul_owd_baselines_us["${reflector}"]="${dl_owd_baselines_us[${reflector}]}"

		dl_owd_delta_us=$(( dl_owd_us - dl_owd_baselines_us[${reflector}] ))
		ul_owd_delta_us="${dl_owd_delta_us}"

		if (( load_percent[dl] < high_load_thr_percent && load_percent[ul] < high_load_thr_percent))
		then
			ewma_iteration "${dl_owd_delta_us}" "${alpha_delta_ewma}" "dl_owd_delta_ewmas_us[${reflector}]"
			ul_owd_delta_ewmas_us["${reflector}"]="${dl_owd_delta_ewmas_us[${reflector}]}"
		fi

		timestamp="${timestamp//[\[\]]}0"

		printf "REFLECTOR_RESPONSE %s %s %s %s %s %s %s %s %s %s %s\n" "${timestamp}" "${reflector}" "${seq}" "${dl_owd_baselines_us[${reflector}]}" "${dl_owd_us}" "${dl_owd_delta_ewmas_us[${reflector}]}" "${dl_owd_delta_us}" "${ul_owd_baselines_us[${reflector}]}" "${ul_owd_us}" "${ul_owd_delta_ewmas_us[${reflector}]}" "${ul_owd_delta_us}" >&"${main_fd}"

		timestamp_us="${timestamp//[.]}"

		printf "SET_ARRAY_ELEMENT dl_owd_baselines_us %s %s\n" "${reflector}" "${dl_owd_baselines_us[${reflector}]}" >&"${maintain_pingers_fd}"
		printf "SET_ARRAY_ELEMENT ul_owd_baselines_us %s %s\n" "${reflector}" "${ul_owd_baselines_us[${reflector}]}" >&"${maintain_pingers_fd}"

		printf "SET_ARRAY_ELEMENT dl_owd_delta_ewmas_us %s %s\n" "${reflector}" "${dl_owd_delta_ewmas_us[${reflector}]}" >&"${maintain_pingers_fd}"
		printf "SET_ARRAY_ELEMENT ul_owd_delta_ewmas_us %s %s\n" "${reflector}" "${ul_owd_delta_ewmas_us[${reflector}]}" >&"${maintain_pingers_fd}"

		printf "SET_ARRAY_ELEMENT last_timestamp_reflectors_us %s %s\n" "${reflector}" "${timestamp_us}" >&"${maintain_pingers_fd}"

	done
}
# IPUTILS-PING FUNCTIONS
parse_ping()
{
	trap '' INT
	trap 'terminate "${pinger_pid}" "${parse_preprocessor_pid}"' TERM EXIT

	# ping reflector, maintain baseline and output deltas to a common fifo

	local parse_id="${1}"
	local reflector="${2}"

	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	declare -A dl_owd_baselines_us
	declare -A ul_owd_baselines_us
	declare -A dl_owd_delta_ewmas_us
	declare -A ul_owd_delta_ewmas_us

	dl_owd_baselines_us["${reflector}"]=100000
	ul_owd_baselines_us["${reflector}"]=100000
	dl_owd_delta_ewmas_us["${reflector}"]=0
	ul_owd_delta_ewmas_us["${reflector}"]=0

	declare -A load_percent
	load_percent[dl]=0
	load_percent[ul]=0

	while true
	do
		unset command
		read -r -u "${pinger_fds[pinger]}" -a command
		[[ "${#command[@]}" -eq 0 ]] && continue

		case "${command[0]}" in

			REFLECTOR_RESPONSE)

				read -r timestamp _ _ _ reflector seq_rtt <<< "${command[@]:1}"
				checksum="${command[*]: -1}"
				;;

			START_PINGER)

				exec {parse_preprocessor_fd}> >(parse_preprocessor)
				parse_preprocessor_pid="${!}"
				printf "SET_PROC_PID %s %s\n" "proc_pids ${parse_id}_preprocessor" "${parse_preprocessor_pid}" >&"${main_fd}"
				${ping_prefix_string} ping ${ping_extra_args} -D -i "${reflector_ping_interval_s}" "${reflector}" 2> /dev/null >&"${parse_preprocessor_fd}" &
				pinger_pid="${!}"
				printf "SET_PROC_PID proc_pids %s %s\n" "${parse_id}_pinger" "${pinger_pid}" >&"${main_fd}"
				continue
				;;

			KILL_PINGER)

				terminate "${pinger_pid}" "${parse_preprocessor_pid}"
				exec {parse_preprocessor_fd}>&-
				continue
				;;

			SET_REFLECTOR)

				if [[ "${#command[@]}" -eq 2 ]]
				then
					reflector="${command[1]}"
					log_msg "DEBUG" "Read in new reflector: ${reflector}"
					dl_owd_baselines_us["${reflector}"]="${dl_owd_baselines_us[${reflector}]:-100000}"
					ul_owd_baselines_us["${reflector}"]="${ul_owd_baselines_us[${reflector}]:-100000}"
					dl_owd_delta_ewmas_us["${reflector}"]="${dl_owd_delta_ewmas_us[${reflector}]:-0}"
					ul_owd_delta_ewmas_us["${reflector}"]="${ul_owd_delta_ewmas_us[${reflector}]:-0}"
					continue
				fi
				;;

			SET_VAR)

				if [[ "${#command[@]}" -eq 3 ]]
				then
						export -n "${command[1]}=${command[2]}"
				fi
				continue
				;;

			SET_ARRAY_ELEMENT)

				if [[ "${#command[@]}" -eq 4 ]]
				then
						declare -A "${command[1]}"+="([${command[2]}]=${command[3]})"
				fi
				continue
				;;

			TERMINATE)

				log_msg "DEBUG" "Terminating parse_ping."
				exit
				;;

			*)

				continue
				;;

		esac

		[[ "${timestamp:-}" && "${reflector:-}" && "${seq_rtt:-}" && "${checksum:-}" ]] || continue
		[[ "${checksum}" == "${timestamp}" ]] || continue

		# If no match then skip onto the next one
		[[ "${seq_rtt}" =~ icmp_[s|r]eq=([0-9]+).*time=([0-9]+)\.?([0-9]+)?[[:space:]]ms ]] || continue

		reflector=${reflector//:/}

		seq=${BASH_REMATCH[1]}

		rtt_us=${BASH_REMATCH[3]}000
		rtt_us=$((${BASH_REMATCH[2]}000+10#${rtt_us:0:3}))

		dl_owd_us=$((rtt_us/2))
		ul_owd_us="${dl_owd_us}"

		dl_alpha=$(( dl_owd_us >= dl_owd_baselines_us[${reflector}] ? alpha_baseline_increase : alpha_baseline_decrease ))

		ewma_iteration "${dl_owd_us}" "${dl_alpha}" "dl_owd_baselines_us[${reflector}]"
		ul_owd_baselines_us["${reflector}"]="${dl_owd_baselines_us[${reflector}]}"

		dl_owd_delta_us=$(( dl_owd_us - dl_owd_baselines_us[${reflector}] ))
		ul_owd_delta_us="${dl_owd_delta_us}"

		if (( load_percent[dl] < high_load_thr_percent && load_percent[ul] < high_load_thr_percent))
		then
			ewma_iteration "${dl_owd_delta_us}" "${alpha_delta_ewma}" "dl_owd_delta_ewmas_us[${reflector}]"
			ul_owd_delta_ewmas_us["${reflector}"]="${dl_owd_delta_ewmas_us[${reflector}]}"
		fi

		timestamp="${timestamp//[\[\]]}"

		printf "REFLECTOR_RESPONSE %s %s %s %s %s %s %s %s %s %s %s\n" "${timestamp}" "${reflector}" "${seq}" "${dl_owd_baselines_us[${reflector}]}" "${dl_owd_us}" "${dl_owd_delta_ewmas_us[${reflector}]}" "${dl_owd_delta_us}" "${ul_owd_baselines_us[${reflector}]}" "${ul_owd_us}" "${ul_owd_delta_ewmas_us[${reflector}]}" "${ul_owd_delta_us}" >&"${main_fd}"

		timestamp_us="${timestamp//[.]}"

		printf "SET_ARRAY_ELEMENT dl_owd_baselines_us %s %s\n" "${reflector}" "${dl_owd_baselines_us[${reflector}]}" >&"${maintain_pingers_fd}"
		printf "SET_ARRAY_ELEMENT ul_owd_baselines_us %s %s\n" "${reflector}" "${ul_owd_baselines_us[${reflector}]}" >&"${maintain_pingers_fd}"

		printf "SET_ARRAY_ELEMENT dl_owd_delta_ewmas_us %s %s\n" "${reflector}" "${dl_owd_delta_ewmas_us[${reflector}]}" >&"${maintain_pingers_fd}"
		printf "SET_ARRAY_ELEMENT ul_owd_delta_ewmas_us %s %s\n" "${reflector}" "${ul_owd_delta_ewmas_us[${reflector}]}" >&"${maintain_pingers_fd}"
		
		printf "SET_ARRAY_ELEMENT last_timestamp_reflectors_us %s %s\n" "${reflector}" "${timestamp_us}" >&"${maintain_pingers_fd}"
	done
}

# END OF IPUTILS-PING FUNCTIONS

# GENERIC PINGER START AND STOP FUNCTIONS

start_pinger()
{
	local pinger="${1}"

	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	case ${pinger_binary} in

		tsping|fping)
			pinger=0
			printf "START_PINGER\n" >&"${pinger_fds[pinger]}"
			;;	
		ping)
			sleep_until_next_pinger_time_slot "${pinger}"
			printf "START_PINGER\n" >&"${pinger_fds[pinger]}"
			;;
		*)
			log_msg "ERROR" "Unknown pinger binary: ${pinger_binary}"
			kill $$ 2>/dev/null
			;;
	esac
}

start_pingers()
{
	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	case ${pinger_binary} in

		tsping|fping)
			start_pinger 0
			;;
		ping)
			for ((pinger=0; pinger < no_pingers; pinger++))
			do
				start_pinger "${pinger}"
			done
			;;
		*)
			log_msg "ERROR" "Unknown pinger binary: ${pinger_binary}"
			kill $$ 2>/dev/null
			;;
	esac
}

sleep_until_next_pinger_time_slot()
{
	# wait until next pinger time slot and start pinger in its slot
	# this allows pingers to be stopped and started (e.g. during sleep or reflector rotation)
	# whilst ensuring pings will remain spaced out appropriately to maintain granularity

	local pinger="${1}"

	t_start_us=${EPOCHREALTIME/./}
	time_to_next_time_slot_us=$(( (reflector_ping_interval_us-(t_start_us-pingers_t_start_us)%reflector_ping_interval_us) + pinger*ping_response_interval_us ))
	sleep_remaining_tick_time "${t_start_us}" "${time_to_next_time_slot_us}"
}

kill_pinger()
{
	local pinger="${1}"

	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	case "${pinger_binary}" in
		tsping|fping)
			pinger=0
			;;

		*)
			;;
	esac

	printf "KILL_PINGER\n" >&"${pinger_fds[pinger]}"
}

kill_pingers()
{
	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	case "${pinger_binary}" in

		tsping|fping)
			log_msg "DEBUG" "Killing ${pinger_binary} instance."
			kill_pinger 0
			;;
		ping)
			for (( pinger=0; pinger < no_pingers; pinger++))
			do
				log_msg "DEBUG" "Killing pinger instance: ${pinger}"
				kill_pinger "${pinger}"
			done
			;;
		*)
			log_msg "ERROR" "Unknown pinger binary: ${pinger_binary}"
			kill $$ 2>/dev/null
			;;
	esac
}

replace_pinger_reflector()
{
	# pingers always use reflectors[0]..[no_pingers-1] as the initial set
	# and the additional reflectors are spare reflectors should any from initial set go stale
	# a bad reflector in the initial set is replaced with ${reflectors[no_pingers]}
	# ${reflectors[no_pingers]} is then unset
	# and the the bad reflector moved to the back of the queue (last element in ${reflectors[]})
	# and finally the indices for ${reflectors} are updated to reflect the new order

	local pinger="${1}"

	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	if ((no_reflectors > no_pingers))
	then
		log_msg "DEBUG" "replacing reflector: ${reflectors[pinger]} with ${reflectors[no_pingers]}."
		kill_pinger "${pinger}"
		bad_reflector=${reflectors[pinger]}
		# overwrite the bad reflector with the reflector that is next in the queue (the one after 0..${no_pingers}-1)
		reflectors[pinger]=${reflectors[no_pingers]}
		# remove the new reflector from the list of additional reflectors beginning from ${reflectors[no_pingers]}
		unset "reflectors[no_pingers]"
		# bad reflector goes to the back of the queue
		reflectors+=("${bad_reflector}")
		# reset array indices
		mapfile -t reflectors < <(for i in "${reflectors[@]}"; do printf '%s\n' "${i}"; done)
		# set up the new pinger with the new reflector and retain pid
		case ${pinger_binary} in

			tsping|fping)
				printf "SET_REFLECTORS %s\n" "${reflectors[*]:0:${no_pingers}}" >&"${pinger_fds[0]}"
				;;
			ping)
				printf "SET_REFLECTOR %s\n" "${reflectors[pinger]}" >&"${pinger_fds[pinger]}"
				;;
			*)
				log_msg "ERROR" "Unknown pinger binary: ${pinger_binary}"
				kill $$ 2>/dev/null
				;;
		esac
		start_pinger "${pinger}"
	else
		log_msg "DEBUG" "No additional reflectors specified so just retaining: ${reflectors[pinger]}."
	fi

	log_msg "DEBUG" "Resetting reflector offences associated with reflector: ${reflectors[pinger]}."
	declare -n reflector_offences="reflector_${pinger}_offences"
	for ((i=0; i<reflector_misbehaving_detection_window; i++)) do reflector_offences[i]=0; done
	sum_reflector_offences[pinger]=0
}

# END OF GENERIC PINGER START AND STOP FUNCTIONS

kill_maintain_pingers()
{
	trap - TERM EXIT

	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	log_msg "DEBUG" "Terminating maintain_pingers."

	case "${pinger_binary}" in

		tsping|fping)
			printf "TERMINATE\n" >&"${pinger_fds[0]}"
			;;

		ping)
			for ((pinger=0; pinger < no_pingers; pinger++))
			do
				printf "TERMINATE\n" >&"${pinger_fds[pinger]}"
			done
			;;

		*)
			log_msg "ERROR" "Unknown pinger binary: ${pinger_binary}"
			kill $$ 2>/dev/null
			;;
	esac

	exit
}

change_state_maintain_pingers()
{
	local maintain_pingers_next_state="${1:-unset}"

	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	case "${maintain_pingers_next_state}" in

		START|STOP|PAUSED|RUNNING)

			if [[ "${maintain_pingers_state}" == "${maintain_pingers_next_state}" ]]
			then
				log_msg "ERROR" "Received request to change maintain_pingers state to existing state."
				return
			fi

			log_msg "DEBUG" "Changing maintain_pingers state from: ${maintain_pingers_state} to: ${maintain_pingers_next_state}"
			maintain_pingers_state=${maintain_pingers_next_state}
			;;

		*)

			log_msg "ERROR" "Received unrecognized state change request: ${maintain_pingers_next_state}. Exiting now."
			kill $$ 2>/dev/null
			;;
	esac
}

maintain_pingers()
{
	# this initiates the pingers and monitors reflector health, rotating reflectors as necessary

	trap '' INT
	trap 'kill_maintain_pingers' TERM EXIT

	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	declare -A dl_owd_baselines_us
	declare -A ul_owd_baselines_us
	declare -A dl_owd_delta_ewmas_us
	declare -A ul_owd_delta_ewmas_us
	declare -A last_timestamp_reflectors_us

	err_silence=0
	reflector_offences_idx=0
	pingers_active=0

	pingers_t_start_us="${EPOCHREALTIME/./}"
	t_last_reflector_replacement_us="${EPOCHREALTIME/./}"
	t_last_reflector_comparison_us="${EPOCHREALTIME/./}"

	for ((reflector=0; reflector < no_reflectors; reflector++))
	do
		last_timestamp_reflectors_us["${reflectors[reflector]}"]="${pingers_t_start_us}"
	done
	
	# For each pinger initialize record of offences
	for ((pinger=0; pinger < no_pingers; pinger++))
	do
		# shellcheck disable=SC2178
		declare -n reflector_offences="reflector_${pinger}_offences"
		for ((i=0; i<reflector_misbehaving_detection_window; i++)) do reflector_offences[i]=0; done
		sum_reflector_offences[pinger]=0
	done

	maintain_pingers_state="START"
	sleep_duration_s=0
	pinger=0

	case "${pinger_binary}" in

		tsping)
			parse_tsping "parse_tsping" "${reflectors[@]:0:${no_pingers}}" &
			printf "SET_PROC_PID proc_pids parse_tsping %s\n" "${!}" >&"${main_fd}"
			;;		
		fping)
			parse_fping "parse_fping" "${reflectors[@]:0:${no_pingers}}" &
			printf "SET_PROC_PID proc_pids parse_fping %s\n" "${!}" >&"${main_fd}"
			;;	
		ping)
			for((pinger=0; pinger < no_pingers; pinger++))
			do
				parse_ping "parse_ping_${pinger}" "${reflectors[pinger]}" &
				printf "SET_PROC_PID proc_pids %s %s\n" "parse_ping_${pinger}" "${!}" >&"${main_fd}"
			done
			;;
		*)
			log_msg "ERROR" "Unknown pinger binary: ${pinger_binary}"
			kill $$ 2>/dev/null
			;;
	esac


	# Reflector maintenance loop - verifies reflectors have not gone stale and rotates reflectors as necessary
	while true
	do
		t_start_us="${EPOCHREALTIME/./}"

		while read -r -t 0 -u "${maintain_pingers_fd}"
		do
			unset command
			read -r -u "${maintain_pingers_fd}" -a command
			case "${command[0]:-}" in

				CHANGE_STATE)
					if [[ "${#command[@]}" -eq 2 ]]
					then
						change_state_maintain_pingers "${command[1]}"
						# break out of reading any new IPC commands to handle next state
						# if pingers need to be started or stopped
						case "${command[1]}" in
							START|STOP)
								break
								;;
							*)
								:
								;;
						esac
					fi
					;;
				SET_ARRAY_ELEMENT)
					if [[ "${#command[@]}" -eq 4 ]]
					then
						declare -A "${command[1]}"+="([${command[2]}]=${command[3]})"
					fi
					;;
				SET_VAR)
					if [[ "${#command[@]}" -eq 3 ]]
					then
						export -n "${command[1]}=${command[2]}"
					fi
					;;
				TERMINATE)
					log_msg "DEBUG" "Terminating monitor_achieved_rates."
					exit
					;;
				*)
					true
					;;
			esac
		done

		case "${maintain_pingers_state}" in

			START)
				if ((pingers_active==0))
				then
					start_pingers
					pingers_active=1
				fi
				change_state_maintain_pingers "RUNNING"
				;;

			STOP)
				if ((pingers_active))
				then
					kill_pingers
					pingers_active=0
				fi
				change_state_maintain_pingers "PAUSED"
				;;

			PAUSED)
				;;

			RUNNING)

				if (( t_start_us>(t_last_reflector_replacement_us+reflector_replacement_interval_mins*60*1000000) ))
				then
					pinger=$((RANDOM%no_pingers))
					log_msg "DEBUG" "reflector: ${reflectors[pinger]} randomly selected for replacement."
					replace_pinger_reflector "${pinger}"
					t_last_reflector_replacement_us=${EPOCHREALTIME/./}
					continue
				fi

				if (( t_start_us>(t_last_reflector_comparison_us+reflector_comparison_interval_mins*60*1000000) ))
				then

					t_last_reflector_comparison_us=${EPOCHREALTIME/./}

					[[ "${dl_owd_baselines_us[${reflectors[0]}]:-}" && "${dl_owd_baselines_us[${reflectors[0]}]:-}" && "${ul_owd_baselines_us[${reflectors[0]}]:-}" && "${ul_owd_baselines_us[${reflectors[0]}]:-}" ]] || continue

					min_sum_owd_baselines_us=$(( dl_owd_baselines_us[${reflectors[0]}] + ul_owd_baselines_us[${reflectors[0]}] ))
					min_dl_owd_delta_ewma_us="${dl_owd_delta_ewmas_us[${reflectors[0]}]}"
					min_ul_owd_delta_ewma_us="${ul_owd_delta_ewmas_us[${reflectors[0]}]}"

					for ((pinger=0; pinger < no_pingers; pinger++))
					do
						[[ "${dl_owd_baselines_us[${reflectors[pinger]}]:-}" && "${dl_owd_delta_ewmas_us[${reflectors[pinger]}]:-}" && "${ul_owd_baselines_us[${reflectors[pinger]}]:-}" && "${ul_owd_delta_ewmas_us[${reflectors[pinger]}]:-}" ]] || continue 2

						sum_owd_baselines_us[pinger]=$(( dl_owd_baselines_us[${reflectors[pinger]}] + ul_owd_baselines_us[${reflectors[pinger]}] ))
						(( sum_owd_baselines_us[pinger] < min_sum_owd_baselines_us )) && min_sum_owd_baselines_us="${sum_owd_baselines_us[pinger]}"
						(( dl_owd_delta_ewmas_us[${reflectors[pinger]}] < min_dl_owd_delta_ewma_us )) && min_dl_owd_delta_ewma_us="${dl_owd_delta_ewmas_us[${reflectors[pinger]}]}"
						(( ul_owd_delta_ewmas_us[${reflectors[pinger]}] < min_ul_owd_delta_ewma_us )) && min_ul_owd_delta_ewma_us="${ul_owd_delta_ewmas_us[${reflectors[pinger]}]}"
					done

					for ((pinger=0; pinger < no_pingers; pinger++))
					do

						sum_owd_baselines_delta_us=$(( sum_owd_baselines_us[pinger] - min_sum_owd_baselines_us ))
						dl_owd_delta_ewma_delta_us=$(( dl_owd_delta_ewmas_us[${reflectors[pinger]}] - min_dl_owd_delta_ewma_us ))
						ul_owd_delta_ewma_delta_us=$(( ul_owd_delta_ewmas_us[${reflectors[pinger]}] - min_ul_owd_delta_ewma_us ))

						if ((output_reflector_stats))
						then
							printf -v reflector_stats '%s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s' "${EPOCHREALTIME}" "${reflectors[pinger]}" "${min_sum_owd_baselines_us}" "${sum_owd_baselines_us[pinger]}" "${sum_owd_baselines_delta_us}" "${reflector_sum_owd_baselines_delta_thr_us}" "${min_dl_owd_delta_ewma_us}" "${dl_owd_delta_ewmas_us[${reflectors[pinger]}]}" "${dl_owd_delta_ewma_delta_us}" "${reflector_owd_delta_ewma_delta_thr_us}" "${min_ul_owd_delta_ewma_us}" "${ul_owd_delta_ewmas_us[${reflectors[pinger]}]}" "${ul_owd_delta_ewma_delta_us}" "${reflector_owd_delta_ewma_delta_thr_us}"
							log_msg "REFLECTOR" "${reflector_stats}"
						fi
	
						if (( sum_owd_baselines_delta_us > reflector_sum_owd_baselines_delta_thr_us ))
						then
							log_msg "DEBUG" "Warning: reflector: ${reflectors[pinger]} sum_owd_baselines_us exceeds the minimum by set threshold."
							replace_pinger_reflector "${pinger}"
							continue 2
						fi

						if (( dl_owd_delta_ewma_delta_us > reflector_owd_delta_ewma_delta_thr_us ))
						then
							log_msg "DEBUG" "Warning: reflector: ${reflectors[pinger]} dl_owd_delta_ewma_us exceeds the minimum by set threshold."
							replace_pinger_reflector "${pinger}"
							continue 2
						fi
				
						if (( ul_owd_delta_ewma_delta_us > reflector_owd_delta_ewma_delta_thr_us ))
						then
							log_msg "DEBUG" "Warning: reflector: ${reflectors[pinger]} ul_owd_delta_ewma_us exceeds the minimum by set threshold."
							replace_pinger_reflector "${pinger}"
							continue 2
						fi
					done

				fi

				replace_pinger_reflector_enabled=1

				for ((pinger=0; pinger < no_pingers; pinger++))
				do
					# shellcheck disable=SC2178
					declare -n reflector_offences="reflector_${pinger}_offences"

					(( reflector_offences[reflector_offences_idx] )) && ((sum_reflector_offences[pinger]--))
					# shellcheck disable=SC2154
					reflector_offences[reflector_offences_idx]=$(( (${EPOCHREALTIME/./}-last_timestamp_reflectors_us[${reflectors[pinger]}]) > reflector_response_deadline_us ? 1 : 0 ))

					if (( reflector_offences[reflector_offences_idx] ))
					then
						((sum_reflector_offences[pinger]++))
						log_msg "DEBUG" "no ping response from reflector: ${reflectors[pinger]} within reflector_response_deadline: ${reflector_response_deadline_s}s"
						log_msg "DEBUG" "reflector=${reflectors[pinger]}, sum_reflector_offences=${sum_reflector_offences[pinger]} and reflector_misbehaving_detection_thr=${reflector_misbehaving_detection_thr}"
					fi

					if (( sum_reflector_offences[pinger] >= reflector_misbehaving_detection_thr ))
					then

						log_msg "DEBUG" "Warning: reflector: ${reflectors[pinger]} seems to be misbehaving."
						if ((replace_pinger_reflector_enabled))
						then
							replace_pinger_reflector "${pinger}"
							replace_pinger_reflector_enabled=0
						else
							log_msg "DEBUG" "Warning: skipping replacement of reflector: ${reflectors[pinger]} given prior replacement within this reflector health check cycle."
						fi
					fi		
				done
				((reflector_offences_idx=(reflector_offences_idx+1)%reflector_misbehaving_detection_window))
				;;
			*)
				log_msg "ERROR" "Unrecognized maintain pingers state: ${maintain_pingers_state}."
				log_msg "ERROR" "Setting state to RUNNING"
				maintain_pingers_next_state="RUNNING"
				change_maintain_pingers_state
			;;
		esac
	
		sleep_remaining_tick_time "${t_start_us}" "${reflector_health_check_interval_us}"
	done
}

set_shaper_rate()
{
	# fire up tc and update max_wire_packet_compensation if there are rates to change for the given direction

	local direction="${1}" # 'dl' or 'ul'

	if (( shaper_rate_kbps["${direction}"] != last_shaper_rate_kbps["${direction}"] ))
	then
		((output_cake_changes)) && log_msg "SHAPER" "tc qdisc change root dev ${interface[${direction}]} cake bandwidth ${shaper_rate_kbps[${direction}]}Kbit"

		if ((adjust_shaper_rate["${direction}"]))
		then
			tc qdisc change root dev "${interface[${direction}]}" cake bandwidth "${shaper_rate_kbps[${direction}]}Kbit" 2> /dev/null
		else
			((output_cake_changes)) && log_msg "DEBUG" "adjust_${direction}_shaper_rate set to 0 in config, so skipping the corresponding tc qdisc change call."
		fi

		printf "SET_ARRAY_ELEMENT shaper_rate_kbps ${direction} %s\n" "${shaper_rate_kbps[${direction}]}" >&"${monitor_achieved_rates_fd}"
		last_shaper_rate_kbps["${direction}"]="${shaper_rate_kbps[${direction}]}"

		update_max_wire_packet_compensation
	fi
}

set_min_shaper_rates()
{
	log_msg "DEBUG" "Enforcing minimum shaper rates."
	shaper_rate_kbps[dl]=${min_dl_shaper_rate_kbps}
	shaper_rate_kbps[ul]=${min_ul_shaper_rate_kbps}
	set_shaper_rate "dl"
	set_shaper_rate "ul"
}

get_max_wire_packet_size_bits()
{
	local interface="${1}"
	local -n max_wire_packet_size_bits="${2}"

	read -r max_wire_packet_size_bits < "/sys/class/net/${interface}/mtu"
	[[ $(tc qdisc show dev "${interface}") =~ (atm|noatm)[[:space:]]overhead[[:space:]]([0-9]+) ]]
	max_wire_packet_size_bits=$(( 8*(max_wire_packet_size_bits+BASH_REMATCH[2]) ))
	# atm compensation = 53*ceil(X/48) bytes = 8*53*((X+8*(48-1)/(8*48)) bits = 424*((X+376)/384) bits
	[[ "${BASH_REMATCH[1]:-}" == "atm" ]] && max_wire_packet_size_bits=$(( 424*((max_wire_packet_size_bits+376)/384) ))
}

update_max_wire_packet_compensation()
{
	# Compensate for delays imposed by active traffic shaper
	# This will serve to increase the delay thr at rates below around 12Mbit/s

	dl_compensation_us=$(( (1000*dl_max_wire_packet_size_bits)/shaper_rate_kbps[dl] ))
	ul_compensation_us=$(( (1000*ul_max_wire_packet_size_bits)/shaper_rate_kbps[ul] ))

	compensated_owd_delta_thr_us[dl]=$(( dl_owd_delta_thr_us + dl_compensation_us ))
	compensated_owd_delta_thr_us[ul]=$(( ul_owd_delta_thr_us + ul_compensation_us ))
	
	compensated_avg_owd_delta_thr_us[dl]=$(( dl_avg_owd_delta_thr_us + dl_compensation_us ))
	compensated_avg_owd_delta_thr_us[ul]=$(( ul_avg_owd_delta_thr_us + ul_compensation_us ))

	max_wire_packet_rtt_us=$(( (1000*dl_max_wire_packet_size_bits)/shaper_rate_kbps[dl] + (1000*ul_max_wire_packet_size_bits)/shaper_rate_kbps[ul] ))
	
	printf "SET_VAR max_wire_packet_rtt_us %s\n" "${max_wire_packet_rtt_us}" >&"${maintain_pingers_fd}"
}

verify_ifs_up()
{
	# Check the rx/tx paths exist and give extra time for ifb's to come up if needed
	# This will block if ifs never come up
	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	while [[ ! -f ${rx_bytes_path} || ! -f ${tx_bytes_path} ]]
	do
		[[ -f ${rx_bytes_path} ]] || log_msg "DEBUG" "Warning: The configured download interface: '${dl_if}' does not appear to be present. Waiting ${if_up_check_interval_s} seconds for the interface to come up."
		[[ -f ${tx_bytes_path} ]] || log_msg "DEBUG" "Warning: The configured upload interface: '${ul_if}' does not appear to be present. Waiting ${if_up_check_interval_s} seconds for the interface to come up."
		sleep_s "${if_up_check_interval_s}"
	done
}

ewma_iteration()
{
	local value="${1}"
	local alpha="${2}" # alpha must be scaled by factor of 1000000
	local -n ewma="${3}"

	prev_ewma=${ewma}
	ewma=$(( (alpha*value+(1000000-alpha)*prev_ewma)/1000000 ))
}

change_state_main()
{
	local main_next_state="${1}"

	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	case ${main_next_state} in

		RUNNING|IDLE|STALL)

			if [[ "${main_state}" != "${main_next_state}" ]]
			then
				log_msg "DEBUG" "Changing main state from: ${main_state} to: ${main_next_state}"
				main_state=${main_next_state}
			else
				log_msg "ERROR" "Received request to change main state to existing state."
			fi
			;;

		*)

			log_msg "ERROR" "Received unrecognized main state change request: ${main_next_state}. Exiting now."
			kill $$ 2>/dev/null
			;;
	esac
}

intercept_stderr()
{
	# send stderr to log_msg and exit cake-autorate
	# use with redirection: exec 2> >(intercept_stderr)

	while read -r error
	do
		log_msg "ERROR" "${error}"
		kill $$ 2>/dev/null
	done
}

# Debug command wrapper
# Inspired by cmd_wrapper of sqm-script
debug_cmd()
{
	# Usage: debug_cmd debug_msg err_silence cmd arg1 arg2, etc.

	# Error messages are output as log_msg ERROR messages
	# Or set error_silence=1 to output errors as log_msg DEBUG messages

	local debug_msg="${1}"
	local err_silence="${2}"
	local cmd="${3}"

	log_msg "DEBUG" "Starting: ${FUNCNAME[0]} with PID: ${BASHPID}"

	shift 3

	local args=("${@}")

	local caller_id
	local err_type

	local ret
	local stderr

	err_type="ERROR"

	if ((err_silence))
	then
		err_type="DEBUG"
	fi

	stderr=$(${cmd} "${args[@]}" 2>&1)
	ret=${?}

	caller_id=$(caller)

	if ((ret==0))
	then
		log_msg "DEBUG" "debug_cmd: err_silence=${err_silence}; debug_msg=${debug_msg}; caller_id=${caller_id}; command=${cmd} ${args[*]}; result=SUCCESS"
	else
		[[ "${err_type}" == "DEBUG" && "${debug}" == "0" ]] && return # if debug disabled, then skip on DEBUG but not on ERROR

		log_msg "${err_type}" "debug_cmd: err_silence=${err_silence}; debug_msg=${debug_msg}; caller_id=${caller_id}; command=${cmd} ${args[*]}; result=FAILURE (${ret})"
		log_msg "${err_type}" "debug_cmd: LAST ERROR (${stderr})"

		frame=1
		while caller_output=$(caller "${frame}")
		do
			log_msg "${err_type}" "debug_cmd: CALL CHAIN: ${caller_output}"
			((++frame))
		done
	fi
}

# shellcheck disable=SC1090,SC2311
validate_config_entry() {
	# Must be called before loading config_path into the global scope.
	#
	# When the entry is invalid, two types are returned with the first type
	# being the invalid user type and second type is the default type with
	# the user needing to adapt the config file so that the entry uses the
	# default type.
	#
	# When the entry is valid, one type is returned and it will be the
	# the type of either the default or user type. However because in that
	# case they are both valid. It doesn't matter as they'd both have the
	# same type.

	local config_path="${1}"

	local user_type
	local valid_type

	user_type=$(unset "${2}" && . "${config_path}" && typeof "${2}")
	valid_type=$(typeof "${2}")

	if [[ "${user_type}" != "${valid_type}" ]]
	then
		printf '%s' "${user_type} ${valid_type}"
		return
	elif [[ "${user_type}" != "string" ]]
	then
		printf '%s' "${valid_type}"
		return
	fi

	# extra validation for string, check for empty string
	local -n default_value=${2}
	local user_value
	user_value=$(. "${config_path}" && local -n x="${2}" && printf '%s' "${x}")

	# if user is empty but default is not, invalid entry
	if [[ -z "${user_value}" && -n "${default_value}" ]]
	then
		printf '%s' "${user_type} ${valid_type}"
	else
		printf '%s' "${valid_type}"
	fi
}

# ======= Start of the Main Routine ========

[[ -t 1 ]] && terminal=1 || terminal=0

type logger &> /dev/null && use_logger=1 || use_logger=0 # only perform the test once.

log_file_path=/var/log/cake-autorate.log

# *** WARNING: take great care if attempting to alter the run_path! ***
# *** cake-autorate issues mkdir -p ${run_path} and rm -r ${run_path} on exit. ***
run_path=/var/run/cake-autorate/

# cake-autorate first argument is config file path
if [[ -n "${1-}" ]]
then
	config_path="${1}"
else
	config_path="${PREFIX}/config.primary.sh"
fi

if [[ ! -f "${config_path}" ]]
then
	log_msg "ERROR" "No config file found. Exiting now."
	exit 1
fi

# validate config entries before loading
mapfile -t user_config < <(grep -E '^[^(#| )].*=' "${config_path}" | sed -e 's/[\t ]*\#.*//g' -e 's/=.*//g')
config_error_count=0
for key in "${user_config[@]}"
do
	# Despite the fact that config_file_check is no longer required,
	# we make an exemption just in this case as that variable in
	# particular does not have any real impact to the operation
	# of the script.
	[[ "${key}" == "config_file_check" ]] && continue

	# shellcheck disable=SC2076
	if [[ ! " ${valid_config_entries[*]} " =~ " ${key} " ]]
	then
		((config_error_count++))
		log_msg "ERROR" "The key: '${key}' in config file: '${config_path}' is not a valid config entry."
	else
		# shellcheck disable=SC2311
		read -r user supposed <<< "$(validate_config_entry "${config_path}" "${key}")"
		if [[ -n "${supposed}" ]]
		then
			error_msg="The value of '${key}' in config file: '${config_path}' is not a valid value of type: '${supposed}'."

			case "${user}" in
				negative-*) error_msg="${error_msg} Also, negative numbers are not supported." ;;
				*) ;;
			esac

			log_msg "ERROR" "${error_msg}"
			unset error_msg

			((config_error_count++))
		fi
		unset user supposed
	fi
done
if ((config_error_count))
then
	log_msg "ERROR" "The config file: '${config_path}' contains ${config_error_count} error(s). Exiting now."
	exit 1
fi
unset valid_config_entries user_config config_error_count key

# shellcheck source=config.primary.sh
. "${config_path}"

if [[ ${config_path} =~ config\.(.*)\.sh ]]
then
	instance_id="${BASH_REMATCH[1]}"
	run_path="/var/run/cake-autorate/${instance_id}"
else
	log_msg "ERROR" "Instance identifier 'X' set by config.X.sh cannot be empty. Exiting now."
	exit 1
fi

if [[ -n "${log_file_path_override-}" ]]
then
	if [[ ! -d ${log_file_path_override} ]]
	then
		broken_log_file_path_override=${log_file_path_override}
		log_file_path=/var/log/cake-autorate${instance_id:+.${instance_id}}.log
		log_msg "ERROR" "Log file path override: '${broken_log_file_path_override}' does not exist. Exiting now."
		exit
	fi
	log_file_path=${log_file_path_override}/cake-autorate${instance_id:+.${instance_id}}.log
else
	log_file_path=/var/log/cake-autorate${instance_id:+.${instance_id}}.log
fi

rotate_log_file # rotate here to force header prints at top of log file

# save stderr fd, redirect stderr to intercept_stderr
# intercept_stderr sends stderr to log_msg and exits cake-autorate
exec {original_stderr_fd}>&2 2> >(intercept_stderr)

proc_pids['intercept_stderr']=${!}

log_msg "SYSLOG" "Starting cake-autorate with PID: ${BASHPID} and config: ${config_path}"

# ${run_path}/ is used to store temporary files
# it should not exist on startup so if it does exit, else create the directory
if [[ -d "${run_path}" ]]
then
	if [[ -f "${run_path}/proc_pids" ]] && running_main_pid=$(awk -F= '/^main=/ {print $2}' "${run_path}/proc_pids") && [[ -d "/proc/${running_main_pid}" ]]
	then
		log_msg "ERROR" "${run_path} already exists and an instance appears to be running with main process pid ${running_main_pid}. Exiting script."
		trap - INT TERM EXIT
		exit
	else
		log_msg "DEBUG" "${run_path} already exists but no instance is running. Removing and recreating."
		rm -r "${run_path}"
		mkdir -p "${run_path}"
	fi
else
	mkdir -p "${run_path}"
fi

proc_pids['main']="${BASHPID}"

no_reflectors=${#reflectors[@]}

# Check ping binary exists
command -v "${pinger_binary}" &> /dev/null || { log_msg "ERROR" "ping binary ${pinger_binary} does not exist. Exiting script."; exit; }

# Check no_pingers <= no_reflectors
(( no_pingers > no_reflectors )) && { log_msg "ERROR" "number of pingers cannot be greater than number of reflectors. Exiting script."; exit; }

# Check dl/if interface not the same
[[ "${dl_if}" == "${ul_if}" ]] && { log_msg "ERROR" "download interface and upload interface are both set to: '${dl_if}', but cannot be the same. Exiting script."; exit; }

# Check bufferbloat detection threshold not greater than window length
(( bufferbloat_detection_thr > bufferbloat_detection_window )) && { log_msg "ERROR" "bufferbloat_detection_thr cannot be greater than bufferbloat_detection_window. Exiting script."; exit; }

# Passed error checks

if ((log_to_file))
then
	log_file_max_time_us=$((log_file_max_time_mins*60000000))
	log_file_max_size_bytes=$((log_file_max_size_KB*1024))
	exec {log_fd}<> <(:)
	maintain_log_file &
	proc_pids['maintain_log_file']=${!}
fi

# test if stdout is a tty (terminal)
if ! ((terminal))
then
	echo "stdout not a terminal so redirecting output to: ${log_file_path}"
	((log_to_file)) && exec 1>&"${log_fd}"
fi

# Initialize rx_bytes_path and tx_bytes_path if not set
if [[ -z "${rx_bytes_path-}" ]]
then
	case "${dl_if}" in
		veth*)
			rx_bytes_path="/sys/class/net/${dl_if}/statistics/tx_bytes"
			;;
		ifb*)
			rx_bytes_path="/sys/class/net/${dl_if}/statistics/tx_bytes"
			;;
		*)
			rx_bytes_path="/sys/class/net/${dl_if}/statistics/tx_bytes"
			;;
	esac
fi
if [[ -z "${tx_bytes_path-}" ]]
then
	case "${ul_if}" in
		veth*)
			tx_bytes_path="/sys/class/net/${ul_if}/statistics/rx_bytes"
			;;
		ifb*)
			tx_bytes_path="/sys/class/net/${ul_if}/statistics/rx_bytes"
			;;
		*)
			tx_bytes_path="/sys/class/net/${ul_if}/statistics/tx_bytes"
			;;
	esac
fi

if ((debug))
then
	log_msg "DEBUG" "CAKE-autorate version: ${cake_autorate_version}"
	log_msg "DEBUG" "config_path: ${config_path}"
	log_msg "DEBUG" "run_path: ${run_path}"
	log_msg "DEBUG" "log_file_path: ${log_file_path}"
	log_msg "DEBUG" "pinger_binary:${pinger_binary}"
	log_msg "DEBUG" "download interface: ${dl_if} (${min_dl_shaper_rate_kbps} / ${base_dl_shaper_rate_kbps} / ${max_dl_shaper_rate_kbps})"
	log_msg "DEBUG" "upload interface: ${ul_if} (${min_ul_shaper_rate_kbps} / ${base_ul_shaper_rate_kbps} / ${max_ul_shaper_rate_kbps})"
	log_msg "DEBUG" "rx_bytes_path: ${rx_bytes_path}"
	log_msg "DEBUG" "tx_bytes_path: ${tx_bytes_path}"
fi

# Check interfaces are up and wait if necessary for them to come up
verify_ifs_up

# Initialize variables

# Convert human readable parameters to values that work with integer arithmetic

printf -v dl_owd_delta_thr_us %.0f "${dl_owd_delta_thr_ms}e3"
printf -v ul_owd_delta_thr_us %.0f "${ul_owd_delta_thr_ms}e3"
printf -v dl_avg_owd_delta_thr_us %.0f "${dl_avg_owd_delta_thr_ms}e3"
printf -v ul_avg_owd_delta_thr_us %.0f "${ul_avg_owd_delta_thr_ms}e3"
printf -v alpha_baseline_increase %.0f "${alpha_baseline_increase}e6"
printf -v alpha_baseline_decrease %.0f "${alpha_baseline_decrease}e6"
printf -v alpha_delta_ewma %.0f "${alpha_delta_ewma}e6"
printf -v shaper_rate_min_adjust_down_bufferbloat %.0f "${shaper_rate_min_adjust_down_bufferbloat}e3"
printf -v shaper_rate_max_adjust_down_bufferbloat %.0f "${shaper_rate_max_adjust_down_bufferbloat}e3"
printf -v shaper_rate_adjust_up_load_high %.0f "${shaper_rate_adjust_up_load_high}e3"
printf -v shaper_rate_adjust_down_load_low %.0f "${shaper_rate_adjust_down_load_low}e3"
printf -v shaper_rate_adjust_up_load_low %.0f "${shaper_rate_adjust_up_load_low}e3"
printf -v high_load_thr_percent %.0f "${high_load_thr}e2"
printf -v reflector_ping_interval_ms %.0f "${reflector_ping_interval_s}e3"
printf -v reflector_ping_interval_us %.0f "${reflector_ping_interval_s}e6"
printf -v reflector_health_check_interval_us %.0f "${reflector_health_check_interval_s}e6"
printf -v monitor_achieved_rates_interval_us %.0f "${monitor_achieved_rates_interval_ms}e3"
printf -v sustained_idle_sleep_thr_us %.0f "${sustained_idle_sleep_thr_s}e6"
printf -v reflector_response_deadline_us %.0f "${reflector_response_deadline_s}e6"
printf -v reflector_sum_owd_baselines_delta_thr_us %.0f "${reflector_sum_owd_baselines_delta_thr_ms}e3"
printf -v reflector_owd_delta_ewma_delta_thr_us %.0f "${reflector_owd_delta_ewma_delta_thr_ms}e3"
printf -v startup_wait_us %.0f "${startup_wait_s}e6"
printf -v global_ping_response_timeout_us %.0f "${global_ping_response_timeout_s}e6"
printf -v bufferbloat_refractory_period_us %.0f "${bufferbloat_refractory_period_ms}e3"
printf -v decay_refractory_period_us %.0f "${decay_refractory_period_ms}e3"

for (( i=0; i<${#sss_times_s[@]}; i++ ));
do
	printf -v sss_times_us[i] %.0f\\n "${sss_times_s[i]}e6"
done
printf -v sss_compensation_pre_duration_us %.0f "${sss_compensation_pre_duration_ms}e3"
printf -v sss_compensation_post_duration_us %.0f "${sss_compensation_post_duration_ms}e3"

ping_response_interval_us=$(( reflector_ping_interval_us/no_pingers ))
ping_response_interval_ms=$(( ping_response_interval_us/1000 ))

stall_detection_timeout_us=$(( stall_detection_thr*ping_response_interval_us ))
stall_detection_timeout_s=000000${stall_detection_timeout_us}
stall_detection_timeout_s=$(( 10#${stall_detection_timeout_s::-6})).${stall_detection_timeout_s: -6}

declare -A bufferbloat_detected
declare -A load_percent
declare -A load_condition
declare -A t_last_bufferbloat_us
declare -A t_last_decay_us
declare -A shaper_rate_kbps
declare -A last_shaper_rate_kbps
declare -A base_shaper_rate_kbps
declare -A min_shaper_rate_kbps
declare -A max_shaper_rate_kbps
declare -A interface
declare -A adjust_shaper_rate
declare -A avg_owd_delta_us
declare -A avg_owd_delta_thr_us
declare -A compensated_owd_delta_thr_us
declare -A compensated_avg_owd_delta_thr_us

base_shaper_rate_kbps[dl]="${base_dl_shaper_rate_kbps}"
base_shaper_rate_kbps[ul]="${base_ul_shaper_rate_kbps}"

min_shaper_rate_kbps[dl]="${min_dl_shaper_rate_kbps}"
min_shaper_rate_kbps[ul]="${min_ul_shaper_rate_kbps}"

max_shaper_rate_kbps[dl]="${max_dl_shaper_rate_kbps}"
max_shaper_rate_kbps[ul]="${max_ul_shaper_rate_kbps}"

shaper_rate_kbps[dl]="${base_dl_shaper_rate_kbps}"
shaper_rate_kbps[ul]="${base_ul_shaper_rate_kbps}"

last_shaper_rate_kbps[dl]=0
last_shaper_rate_kbps[ul]=0

interface[dl]="${dl_if}"
interface[ul]="${ul_if}"

adjust_shaper_rate[dl]="${adjust_dl_shaper_rate}"
adjust_shaper_rate[ul]="${adjust_ul_shaper_rate}"

dl_max_wire_packet_size_bits=0
ul_max_wire_packet_size_bits=0
get_max_wire_packet_size_bits "${dl_if}" dl_max_wire_packet_size_bits
get_max_wire_packet_size_bits "${ul_if}" ul_max_wire_packet_size_bits

avg_owd_delta_us[dl]=0
avg_owd_delta_us[ul]=0

avg_owd_delta_thr_us[dl]="${dl_avg_owd_delta_thr_us}"
avg_owd_delta_thr_us[ul]="${ul_avg_owd_delta_thr_us}"

set_shaper_rate "dl"
set_shaper_rate "ul"

update_max_wire_packet_compensation

main_state="RUNNING"

t_start_us="${EPOCHREALTIME/./}"
t_end_us="${EPOCHREALTIME/./}"

t_last_bufferbloat_us[dl]="${t_start_us}"
t_last_bufferbloat_us[ul]="${t_start_us}"
t_last_decay_us[dl]="${t_start_us}"
t_last_decay_us[ul]="${t_start_us}"

t_sustained_connection_idle_us=0
reflectors_last_timestamp_us="${EPOCHREALTIME/./}"

mapfile -t dl_delays < <(for ((i=0; i < bufferbloat_detection_window; i++)); do echo 0; done)
mapfile -t ul_delays < <(for ((i=0; i < bufferbloat_detection_window; i++)); do echo 0; done)
mapfile -t dl_owd_deltas_us < <(for ((i=0; i < bufferbloat_detection_window; i++)); do echo 0; done)
mapfile -t ul_owd_deltas_us < <(for ((i=0; i < bufferbloat_detection_window; i++)); do echo 0; done)

delays_idx=0
sum_dl_delays=0
sum_ul_delays=0
sum_dl_owd_deltas_us=0
sum_ul_owd_deltas_us=0

if ((debug))
then
	if (( bufferbloat_refractory_period_us < (bufferbloat_detection_window*ping_response_interval_us) ))
	then
		log_msg "DEBUG" "Warning: bufferbloat refractory period: ${bufferbloat_refractory_period_us} us."
		log_msg "DEBUG" "Warning: but expected time to overwrite samples in bufferbloat detection window is: $((bufferbloat_detection_window*ping_response_interval_us)) us."
		log_msg "DEBUG" "Warning: Consider increasing bufferbloat refractory period or decreasing bufferbloat detection window."
	fi
	if (( reflector_response_deadline_us < 2*reflector_ping_interval_us ))
	then
		log_msg "DEBUG" "Warning: reflector_response_deadline_s < 2*reflector_ping_interval_s"
		log_msg "DEBUG" "Warning: consider setting an increased reflector_response_deadline."
	fi
fi

# Randomize reflectors array providing randomize_reflectors set to 1
((randomize_reflectors)) && randomize_array reflectors

# Wait if ${startup_wait_s} > 0
if ((startup_wait_us>0))
then
	log_msg "DEBUG" "Waiting ${startup_wait_s} seconds before startup."
	sleep_us "${startup_wait_us}"
fi

case "${pinger_binary}" in

	tsping|fping)
		exec {pinger_fds[0]}<> <(:)
		;;

	ping)
		for ((pinger=0; pinger<=no_pingers; pinger++))
		do
			exec {pinger_fds[pinger]}<> <(:)
		done
		;;

	*)
		log_msg "ERROR" "Unknown pinger binary: ${pinger_binary}"
		exit
		;;
esac

monitor_achieved_rates "${rx_bytes_path}" "${tx_bytes_path}" "${monitor_achieved_rates_interval_us}" &
proc_pids['monitor_achieved_rates']="${!}"

maintain_pingers &
proc_pids['maintain_pingers']="${!}"

generate_log_file_scripts

log_msg "INFO" "Started cake-autorate with PID: ${BASHPID} and config: ${config_path}"

while true
do
	unset command
	read -r -u "${main_fd}" -a command
	[[ "${#command[@]}" -eq 0 ]] && continue

	case "${command[0]}" in

		REFLECTOR_RESPONSE)

			read -r timestamp reflector seq dl_owd_baseline_us dl_owd_us dl_owd_delta_ewma_us dl_owd_delta_us ul_owd_baseline_us ul_owd_us ul_owd_delta_ewma_us ul_owd_delta_us <<< "${command[@]:1}"
			;;

		SET_VAR)
			if [[ "${#command[@]}" -eq 3 ]]
			then
				export -n "${command[1]}=${command[2]}"
			fi
			;;
		SET_ARRAY_ELEMENT)
			if [[ "${#command[@]}" -eq 4 ]]
			then
				declare -A "${command[1]}"+="([${command[2]}]=${command[3]})"
			fi
			;;
		SET_PROC_PID)
			if [[ "${#command[@]}" -eq 4 ]]
			then
				declare -A "${command[1]}"+="([${command[2]}]=${command[3]})"
			fi
			true > "${run_path}/proc_pids"
			for proc_pid in "${!proc_pids[@]}"
			do
				printf "%s=%s\n" "${proc_pid}" "${proc_pids[${proc_pid}]}" >> "${run_path}/proc_pids"
			done
			;;
		*)
			;;
	esac

	case "${main_state}" in

		RUNNING)

			if [[ "${command[0]}" == "REFLECTOR_RESPONSE" && "${timestamp-}" && "${reflector-}" && "${seq-}" && "${dl_owd_baseline_us-}" && "${dl_owd_us-}" && "${dl_owd_delta_ewma_us-}" && "${dl_owd_delta_us-}" && "${ul_owd_baseline_us-}" && "${ul_owd_us-}" && "${ul_owd_delta_ewma_us-}" && "${ul_owd_delta_us-}" ]]
			then
				
				t_start_us=${EPOCHREALTIME/./}

				reflectors_last_timestamp_us="${timestamp//[.]}"

				if (( (t_start_us - 10#"${reflectors_last_timestamp_us}")>500000 ))
				then
					log_msg "DEBUG" "processed response from [${reflector}] that is > 500ms old. Skipping."
					continue
				fi

				# Keep track of delays across detection window
				
				# .. for download:
				(( dl_delays[delays_idx] )) && ((sum_dl_delays--))
				dl_delays[delays_idx]=$(( dl_owd_delta_us > compensated_owd_delta_thr_us[dl] ? 1 : 0 ))
				((dl_delays[delays_idx])) && ((sum_dl_delays++))
			
				(( sum_dl_owd_deltas_us -= dl_owd_deltas_us[delays_idx] ))
				(( dl_owd_deltas_us[delays_idx] = dl_owd_delta_us ))
				(( sum_dl_owd_deltas_us += dl_owd_delta_us ))

				# .. for upload
				(( ul_delays[delays_idx] )) && ((sum_ul_delays--))
				ul_delays[delays_idx]=$(( ul_owd_delta_us > compensated_owd_delta_thr_us[ul] ? 1 : 0 ))
				((ul_delays[delays_idx])) && ((sum_ul_delays++))
				
				(( sum_ul_owd_deltas_us -= ul_owd_deltas_us[delays_idx] ))
				(( ul_owd_deltas_us[delays_idx] = ul_owd_delta_us ))
				(( sum_ul_owd_deltas_us += ul_owd_delta_us ))
				
				# .. and move index on	
				(( delays_idx=(delays_idx+1)%bufferbloat_detection_window ))

				(( avg_owd_delta_us[dl] = sum_dl_owd_deltas_us / bufferbloat_detection_window ))
				(( avg_owd_delta_us[ul] = sum_ul_owd_deltas_us / bufferbloat_detection_window ))

				bufferbloat_detected[dl]=$(( sum_dl_delays >= bufferbloat_detection_thr ? 1 : 0 ))
				bufferbloat_detected[ul]=$(( sum_ul_delays >= bufferbloat_detection_thr ? 1 : 0 ))

				load_percent[dl]=$(( (100*achieved_rate_kbps[dl])/shaper_rate_kbps[dl] ))
				load_percent[ul]=$(( (100*achieved_rate_kbps[ul])/shaper_rate_kbps[ul] ))

				classify_load "dl"
				classify_load "ul"

				update_shaper_rate "dl"
				update_shaper_rate "ul"

				set_shaper_rate "dl"
				set_shaper_rate "ul"

				if (( output_processing_stats ))
				then
					printf -v processing_stats '%s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s' "${EPOCHREALTIME}" "${achieved_rate_kbps[dl]}" "${achieved_rate_kbps[ul]}" "${load_percent[dl]}" "${load_percent[ul]}" "${timestamp}" "${reflector}" "${seq}" "${dl_owd_baseline_us}" "${dl_owd_us}" "${dl_owd_delta_ewma_us}" "${dl_owd_delta_us}" "${compensated_owd_delta_thr_us[dl]}" "${ul_owd_baseline_us}" "${ul_owd_us}" "${ul_owd_delta_ewma_us}" "${ul_owd_delta_us}" "${compensated_owd_delta_thr_us[ul]}" "${sum_dl_delays}" "${avg_owd_delta_us[dl]}" "${compensated_avg_owd_delta_thr_us[dl]}" "${sum_ul_delays}" "${avg_owd_delta_us[ul]}" "${compensated_avg_owd_delta_thr_us[ul]}" "${load_condition[dl]}" "${load_condition[ul]}" "${shaper_rate_kbps[dl]}" "${shaper_rate_kbps[ul]}"
					log_msg "DATA" "${processing_stats}"
				fi

				if (( output_summary_stats ))
				then
					printf -v summary_stats '%s; %s; %s; %s; %s; %s; %s; %s; %s; %s' "${achieved_rate_kbps[dl]}" "${achieved_rate_kbps[ul]}" "${sum_dl_delays}" "${sum_ul_delays}" "${avg_owd_delta_us[dl]}" "${avg_owd_delta_us[ul]}" "${load_condition[dl]}" "${load_condition[ul]}" "${shaper_rate_kbps[dl]}" "${shaper_rate_kbps[ul]}"
					log_msg "SUMMARY" "${summary_stats}"
				fi

				# If base rate is sustained, increment sustained base rate timer (and break out of processing loop if enough time passes)
				if (( enable_sleep_function ))
				then
					if [[ ${load_condition[dl]} == *idle* && ${load_condition[ul]} == *idle* ]]
					then
						((t_sustained_connection_idle_us += (${EPOCHREALTIME/./}-t_end_us) ))
						if ((t_sustained_connection_idle_us > sustained_idle_sleep_thr_us))
						then
							change_state_main "IDLE"	

							log_msg "DEBUG" "Connection idle. Waiting for minimum load."
							((min_shaper_rates_enforcement)) && set_min_shaper_rates

							# update maintain_pingers state
							printf "CHANGE_STATE STOP\n" >&"${maintain_pingers_fd}"

							# reset idle timer
							t_sustained_connection_idle_us=0
						fi
					else
						# reset timer
						t_sustained_connection_idle_us=0
					fi
				fi
			elif (( (${EPOCHREALTIME/./} - reflectors_last_timestamp_us) > stall_detection_timeout_us ))
			then

				log_msg "DEBUG" "Warning: no reflector response within: ${stall_detection_timeout_s} seconds. Checking loads."

				log_msg "DEBUG" "load check is: (( ${achieved_rate_kbps[dl]} kbps > ${connection_stall_thr_kbps} kbps for download && ${achieved_rate_kbps[ul]} kbps > ${connection_stall_thr_kbps} kbps for upload ))"

				# non-zero load so despite no reflector response within stall interval, the connection not considered to have stalled
				# and therefore resume normal operation
				if (( achieved_rate_kbps[dl] > connection_stall_thr_kbps && achieved_rate_kbps[ul] > connection_stall_thr_kbps ))
				then

					log_msg "DEBUG" "load above connection stall threshold so resuming normal operation."
				else
					change_state_main "STALL"

					printf "CHANGE_STATE PAUSED\n" >&"${maintain_pingers_fd}"
					
					t_connection_stall_time_us="${EPOCHREALTIME//.}"
					global_ping_response_timeout=0
				fi

			fi
			
			t_end_us="${EPOCHREALTIME/./}"

			;;
		IDLE)
			if (( achieved_rate_kbps[dl] > connection_active_thr_kbps || achieved_rate_kbps[ul] > connection_active_thr_kbps ))
			then
				log_msg "DEBUG" "dl achieved rate: ${achieved_rate_kbps[dl]} kbps or ul achieved rate: ${achieved_rate_kbps[ul]} kbps exceeded connection active threshold: ${connection_active_thr_kbps} kbps. Resuming normal operation."
				change_state_main "RUNNING"
				printf "CHANGE_STATE START\n" >&"${maintain_pingers_fd}"
				t_sustained_connection_idle_us=0
				# Give some time to enable pingers to get set up
				reflectors_last_timestamp_us=$(( "${EPOCHREALTIME/./}" + 2*reflector_ping_interval_us ))
			fi
			;;
		STALL)
			
			[[ "${command[0]}" == "REFLECTOR_RESPONSE" && "${timestamp-}" ]] && reflectors_last_timestamp_us=${timestamp//[.]}

			if [[ "${command[0]}" == "REFLECTOR_RESPONSE" ]] || (( achieved_rate_kbps[dl] > connection_stall_thr_kbps && achieved_rate_kbps[ul] > connection_stall_thr_kbps ))
			then

				log_msg "DEBUG" "Connection stall ended. Resuming normal operation."
				printf "CHANGE_STATE RUNNING\n" >&"${maintain_pingers_fd}"
				change_state_main "RUNNING"

			fi

			if (( global_ping_response_timeout==0 && ${EPOCHREALTIME/./} > (t_connection_stall_time_us + global_ping_response_timeout_us - stall_detection_timeout_us) ))
			then
				global_ping_response_timeout=1
				((min_shaper_rates_enforcement)) && set_min_shaper_rates
				log_msg "SYSLOG" "Warning: Configured global ping response timeout: ${global_ping_response_timeout_s} seconds exceeded."
				log_msg "DEBUG" "Restarting pingers."
				printf "CHANGE_STATE STOP\n" >&"${maintain_pingers_fd}"
				printf "CHANGE_STATE START\n" >&"${maintain_pingers_fd}"
			fi
			;;
		*)
				
			log_msg "ERROR" "Unrecognized main state: ${main_state}. Exiting now."
			exit 1
			;;
	esac
	
done
