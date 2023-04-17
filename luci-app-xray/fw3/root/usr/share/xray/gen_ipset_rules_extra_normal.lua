#!/usr/bin/lua

local special_purpose_rules = [[add tp_spec_dst_sp 255.255.255.255
add tp_spec_dst_sp 0.0.0.0/8
add tp_spec_dst_sp 10.0.0.0/8
add tp_spec_dst_sp 100.64.0.0/10
add tp_spec_dst_sp 127.0.0.0/8
add tp_spec_dst_sp 169.254.0.0/16
add tp_spec_dst_sp 172.16.0.0/12
add tp_spec_dst_sp 192.0.0.0/24
add tp_spec_dst_sp 192.31.196.0/24
add tp_spec_dst_sp 192.52.193.0/24
add tp_spec_dst_sp 192.88.99.0/24
add tp_spec_dst_sp 192.168.0.0/16
add tp_spec_dst_sp 192.175.48.0/24
add tp_spec_dst_sp 224.0.0.0/3]]

return function(proxy)
    print(special_purpose_rules)
end
