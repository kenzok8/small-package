pkt = ip{dst=to} / tcp{dst=65101} / MPCAPABLE
function cb(ttl, r_ip, mod)
	if r_ip == nil then
		r_ip = "*"
	end
	print(ttl .. ": " .. tostring(r_ip) .. " " .. tostring(mod))
--    print(tostring(mod:original():ip()))
end
result = tracebox(pkt, {callback="cb"})
print("\nResult:\n" .. tostring(result))