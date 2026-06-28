local virtualdog = {}

virtualdog.kvm_help = function()
	return "amd KVM使用 opkg install kmod-kvm-amd\nintel KVM使用 opkg install kmod-kvm-intel"
end

return virtualdog
