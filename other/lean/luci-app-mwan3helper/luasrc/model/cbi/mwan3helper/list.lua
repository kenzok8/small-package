local sys = require "luci.sys"

m = Map("mwan3helper")
m.title	= translate("MWAN3 Helper")
m.description = translate("MWAN3 Helper generate IPSets")

s = m:section(TypedSection, "mwan3helper")
s.addremove = false
s.anonymous = true

o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty = false

local function get_num(ipset_name)
    local base_cmd = "ipset -q list %s | grep -E 'Number of entries:' | awk -F ': ' '{print $2}'"
    local num = sys.exec(base_cmd % ipset_name)
    if not num or num == "" then
        num = 0
    end
    return num
end


local data = {
    all_cn = {
        name = translate("中国所有IP地址"),
        ipset_name = "cn",
        num = get_num("cn")
    },
    ct = {
        name = translate("中国电信"),
        ipset_name = "ct",
        num = get_num("ct")
    },
    cnc = {
        name = translate("中国联通"),
        ipset_name = "cnc",
        num = get_num("cnc")
    },
    cmcc = {
        name = translate("中国移动/铁通"),
        ipset_name = "cmcc",
        num = get_num("cmcc")
    },
    cbtn = {
        name = translate("中国广电"),
        ipset_name = "cbtn",
        num = get_num("cbtn")
    },
    cernet = {
        name = translate("中国教育网"),
        ipset_name = "cernet",
        num = get_num("cernet")
    },
    gwbn = {
        name = translate("长城宽带/鹏博士"),
        ipset_name = "gwbn",
        num = get_num("gwbn")
    },
    othernet = {
        name = translate("中国其他ISP"),
        ipset_name = "othernet",
        num = get_num("othernet")
    },
}

local data_order = {"all_cn", "ct", "cnc", "cmcc", "cbtn", "cernet", "gwbn", "othernet"}

for i, v in ipairs(data_order) do
    local d = data[v]
    o = s:option(DummyValue, v, d.name)
    o.description = translatef("%s 条, IPSet 名称为 %s", d.num, d.ipset_name)
end

return m
