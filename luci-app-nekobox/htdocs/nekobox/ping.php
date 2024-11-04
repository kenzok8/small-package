<?php
ob_start();
include './cfg.php';
$translate = [
    'United States' => '美国',
    'China' => '中国',
    'ISP' => '互联网服务提供商',
    'Japan' => '日本',
    'South Korea' => '韩国',
    'Germany' => '德国',
    'France' => '法国',
    'United Kingdom' => '英国',
    'Canada' => '加拿大',
    'Australia' => '澳大利亚',
    'Russia' => '俄罗斯',
    'India' => '印度',
    'Brazil' => '巴西',
    'Netherlands' => '荷兰',
    'Singapore' => '新加坡',
    'Hong Kong' => '香港',
    'Saudi Arabia' => '沙特阿拉伯',
    'Turkey' => '土耳其',
    'Italy' => '意大利',
    'Spain' => '西班牙',
    'Thailand' => '泰国',
    'Malaysia' => '马来西亚',
    'Indonesia' => '印度尼西亚',
    'South Africa' => '南非',
    'Mexico' => '墨西哥',
    'Israel' => '以色列',
    'Sweden' => '瑞典',
    'Switzerland' => '瑞士',
    'Norway' => '挪威',
    'Denmark' => '丹麦',
    'Belgium' => '比利时',
    'Finland' => '芬兰',
    'Poland' => '波兰',
    'Austria' => '奥地利',
    'Greece' => '希腊',
    'Portugal' => '葡萄牙',
    'Ireland' => '爱尔兰',
    'New Zealand' => '新西兰',
    'United Arab Emirates' => '阿拉伯联合酋长国',
    'Argentina' => '阿根廷',
    'Chile' => '智利',
    'Colombia' => '哥伦比亚',
    'Philippines' => '菲律宾',
    'Vietnam' => '越南',
    'Pakistan' => '巴基斯坦',
    'Egypt' => '埃及',
    'Nigeria' => '尼日利亚',
    'Kenya' => '肯尼亚',
    'Morocco' => '摩洛哥',
    'Google' => '谷歌',
    'Amazon' => '亚马逊',
    'Microsoft' => '微软',
    'Facebook' => '脸书',
    'Apple' => '苹果',
    'IBM' => 'IBM',
    'Alibaba' => '阿里巴巴',
    'Tencent' => '腾讯',
    'Baidu' => '百度',
    'Verizon' => '威瑞森',
    'AT&T' => '美国电话电报公司',
    'T-Mobile' => 'T-移动',
    'Vodafone' => '沃达丰',
    'China Telecom' => '中国电信',
    'China Unicom' => '中国联通',
    'China Mobile' => '中国移动', 
    'Chunghwa Telecom' => '中华电信',   
    'Amazon Web Services (AWS)' => '亚马逊网络服务 (AWS)',
    'Google Cloud Platform (GCP)' => '谷歌云平台 (GCP)',
    'Microsoft Azure' => '微软Azure',
    'Oracle Cloud' => '甲骨文云',
    'Alibaba Cloud' => '阿里云',
    'Tencent Cloud' => '腾讯云',
    'DigitalOcean' => '数字海洋',
    'Linode' => '林诺德',
    'OVHcloud' => 'OVH 云',
    'Hetzner' => '赫兹纳',
    'Vultr' => '沃尔特',
    'OVH' => 'OVH',
    'DreamHost' => '梦想主机',
    'InMotion Hosting' => '动态主机',
    'HostGator' => '主机鳄鱼',
    'Bluehost' => '蓝主机',
    'A2 Hosting' => 'A2主机',
    'SiteGround' => '站点地',
    'Liquid Web' => '液态网络',
    'Kamatera' => '卡玛特拉',
    'IONOS' => 'IONOS',
    'InterServer' => '互联服务器',
    'Hostwinds' => '主机之风',
    'ScalaHosting' => '斯卡拉主机',
    'GreenGeeks' => '绿色极客'
];
$lang = $_GET['lang'] ?? 'en';
?>

<!DOCTYPE html>
<html lang="<?php echo htmlspecialchars($lang); ?>">
<head>
    <meta charset="utf-8">
    <meta http-equiv="x-dns-prefetch-control" content="on">
    <link rel="dns-prefetch" href="//cdn.jsdelivr.net">
    <link rel="dns-prefetch" href="//whois.pconline.com.cn">
    <link rel="dns-prefetch" href="//forge.speedtest.cn">
    <link rel="dns-prefetch" href="//api-ipv4.ip.sb">
    <link rel="dns-prefetch" href="//api.ipify.org">
    <link rel="dns-prefetch" href="//api.ttt.sh">
    <link rel="dns-prefetch" href="//qqwry.api.skk.moe">
    <link rel="dns-prefetch" href="//d.skk.moe">
    <link rel="preconnect" href="https://forge.speedtest.cn">
    <link rel="preconnect" href="https://whois.pconline.com.cn">
    <link rel="preconnect" href="https://api-ipv4.ip.sb">
    <link rel="preconnect" href="https://api.ipify.org">
    <link rel="preconnect" href="https://api.ttt.sh">
    <link rel="preconnect" href="https://qqwry.api.skk.moe">
    <link rel="preconnect" href="https://d.skk.moe">
<style>
.img-con {
  width: 65px;  
  height: 55px; 
  display: flex;
  justify-content: center;
  overflow: visible;
}

#flag {
 width: auto;
 height: auto;
  max-width: 65px; 
  max-height: 55px;
  object-fit: contain;
}

.status-icon {
  width: 58px; 
  height: 58px; 
  object-fit: contain; 
  display: block;
}

.status-icons {
  display: flex;
  height: 55px;
  margin-left: auto;
}

.site-icon {
  display: flex;
  justify-content: center;
  height: 55px;
  margin: 0 6px; 
}

.mx-1 {
  margin: 0 4px;
}

.site-icon[onclick*="github"] .status-icon {
  width: 61px; 
  height: 59px;
}

.site-icon[onclick*="github"] {
  width: 60px;
  height: 57px;
  display: flex;
  justify-content: center;
}

.container-sm.container-bg.callout.border {
  padding: 12px 15px; 
  min-height: 70px; 
  display: flex;
  margin-bottom: 15px;
}

.row.align-items-center {
  width: 100%;
  margin: 0;
  display: flex;
  gap: 15px; 
  height: 55px; /
}

.col-3 {
  height: 55px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.col.text-center {
  position: static; 
  left: auto;
  transform: none;
}

.container-sm .row .col-4 {
  position: static !important;
  order: 2 !important; 
  width: 100% !important;
  padding-left: 54px !important;
  margin-top: 5px !important;
  text-align: left !important;
}

#ping-result {
  font-weight: bold;
}

#d-ip {
  color: #09B63F;
  font-weight: 700 !important;
}

.info.small {
 color: #ff69b4;
 font-weight: 600;
 white-space: nowrap;
}

.site-icon, .img-con {
 cursor: pointer !important;
 transition: all 0.2s ease !important;
 position: relative !important;
 user-select: none !important;
}

.site-icon:hover, .img-con:hover {
 transform: translateY(-2px) !important;
}

.site-icon:active, .img-con:active {
 transform: translateY(1px) !important;
 opacity: 0.8 !important;
}

@media (max-width: 1280px) {
 .site-icon[onclick*="baidu"],
 .site-icon[onclick*="taobao"], 
 .site-icon[onclick*="google"],
 .site-icon[onclick*="youtube"],
 .site-icon[onclick*="github"] {
   display: none !important;
 }
}
</style>
<?php if (in_array($lang, ['zh-cn', 'en', 'auto'])): ?>
    <div id="status-bar-component" class="container-sm container-bg callout border">
        <div class="row align-items-center">
            <div class="col-auto">
                <div class="img-con">
                    <img src="./assets/neko/img/loading.svg" id="flag" title="国旗" onclick="IP.getIpipnetIP()">
                </div>
            </div>
            <div class="col-3">
                <p id="d-ip" class="ip-address mb-0">Checking...</p>
                <p id="ipip" class="info small mb-0"></p>
            </div>
            <div class="col text-center"> 
                <p id="ping-result" class="mb-0"></p>
            </div>
            <div class="col-auto ms-auto">
                <div class="status-icons d-flex">
                    <div class="site-icon mx-1" onclick="pingHost('baidu', 'Baidu')">
                        <img src="./assets/neko/img/site_icon_01.png" id="baidu-normal" class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_01.png" id="baidu-gray" class="status-icon">
                    </div>
                    <div class="site-icon mx-1" onclick="pingHost('taobao', '淘宝')">
                        <img src="./assets/neko/img/site_icon_02.png" id="taobao-normal" class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_02.png" id="taobao-gray" class="status-icon">
                    </div>
                    <div class="site-icon mx-1" onclick="pingHost('google', 'Google')">
                        <img src="./assets/neko/img/site_icon_03.png" id="google-normal" class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_03.png" id="google-gray" class="status-icon">
                    </div>
                    <div class="site-icon mx-1" onclick="pingHost('youtube', 'YouTube')">
                        <img src="./assets/neko/img/site_icon_04.png" id="youtube-normal" class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_04.png" id="youtube-gray" class="status-icon">
                    </div>
                    <div class="site-icon mx-1" onclick="pingHost('github', 'GitHub')">
                        <img src="./assets/neko/img/site_icon_05.png" id="github-normal" title="测试 GitHub 延迟" class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_05.png" id="github-gray" class="status-icon">
                    </div>
                </div>
            </div>
        </div>
    </div>
<?php endif; ?>
<script src="./assets/neko/js/jquery.min.js"></script>
<script type="text/javascript">
const _IMG = './assets/neko/';
const translate = <?php echo json_encode($translate, JSON_UNESCAPED_UNICODE); ?>;
let cachedIP = null;
let cachedInfo = null;
let random = parseInt(Math.random() * 100000000);

const checkSiteStatus = {
    sites: {
        baidu: 'https://www.baidu.com',
        taobao: 'https://www.taobao.com',
        google: 'https://www.google.com',
        youtube: 'https://www.youtube.com',
        github: 'https://www.github.com'
    },
    
    check: async function() {
        for (let [site, url] of Object.entries(this.sites)) {
            try {
                const response = await fetch(url, {
                    mode: 'no-cors',
                    cache: 'no-cache'
                });
                
                document.getElementById(`${site}-normal`).style.display = 'inline';
                document.getElementById(`${site}-gray`).style.display = 'none';
            } catch (error) {
                document.getElementById(`${site}-normal`).style.display = 'none';
                document.getElementById(`${site}-gray`).style.display = 'inline';
            }
        }
    }
};

async function pingHost(site, siteName) {
    const url = checkSiteStatus.sites[site];
    const resultElement = document.getElementById('ping-result');

    try {
        resultElement.innerHTML = `<span style="font-size: 22px">正在测试 ${siteName} 的连接延迟...`;
        resultElement.style.color = '#87CEFA';        
        const startTime = performance.now();
        await fetch(url, {
            mode: 'no-cors',
            cache: 'no-cache'
        });
        const endTime = performance.now();
        const pingTime = Math.round(endTime - startTime);      
        resultElement.innerHTML = `<span style="font-size: 22px">${siteName} 连接延迟: ${pingTime}ms</span>`;
        if(pingTime <= 100) {
                resultElement.style.color = '#09B63F'; 
        } else if(pingTime <= 200) {
                resultElement.style.color = '#FFA500'; 
        } else {
                resultElement.style.color = '#ff6b6b'; 
        }
    } catch (error) {
        resultElement.innerHTML = `<span style="font-size: 22px">${siteName} 连接超时`;
        resultElement.style.color = '#ff6b6b';
    }
}

let IP = {
    isRefreshing: false,
    fetchIP: async () => {
        try {
            const [ipifyResp, ipsbResp, chinaIpResp] = await Promise.all([
                IP.get('https://api.ipify.org?format=json', 'json'),
                IP.get('https://api-ipv4.ip.sb/geoip', 'json'),
                IP.get('https://myip.ipip.net', 'text')  
            ]);

            const ipData = ipifyResp.data.ip || ipsbResp.data.ip;
            cachedIP = ipData;
            document.getElementById('d-ip').innerHTML = ipData;
            return ipData;
        } catch (error) {
            console.error("Error fetching IP:", error);
            throw error;
        }
    },

    get: (url, type) =>
        fetch(url, { 
            method: 'GET',
            cache: 'no-store'
        }).then((resp) => {
            if (type === 'text')
                return Promise.all([resp.ok, resp.status, resp.text(), resp.headers]);
            else
                return Promise.all([resp.ok, resp.status, resp.json(), resp.headers]);
        }).then(([ok, status, data, headers]) => {
            if (ok) {
                return { ok, status, data, headers };
            } else {
                throw new Error(JSON.stringify(data.error));
            }
        }).catch(error => {
            console.error("Error fetching data:", error);
            throw error;
        }),

    Ipip: async (ip, elID) => {
        try {
            const [ipsbResp, chinaIpResp] = await Promise.all([
                IP.get(`https://api.ip.sb/geoip/${ip}`, 'json'),
                IP.get(`https://myip.ipip.net`, 'text')
            ]);
            
            cachedIP = ip;
            cachedInfo = ipsbResp.data;

            let chinaIpInfo = null;
            try {
                if(chinaIpResp.data) {
                    chinaIpInfo = chinaIpResp.data;
                }
            } catch(e) {
                console.error("Error parsing China IP info:", e);
            }
            
            const mergedData = {
                ...ipsbResp.data,
               // chinaIpInfo: chinaIpInfo
            };
            
            IP.updateUI(mergedData, elID);
        } catch (error) {
            console.error("Error in Ipip function:", error);
            document.getElementById(elID).innerHTML = "获取IP信息失败";
        }
    },

    updateUI: (data, elID) => {
        try {
            if (!data || !data.country_code) {
                document.getElementById('d-ip').innerHTML = "无法获取IP信息";
                return;
            }

            let country = translate[data.country] || data.country || "未知";
            let isp = translate[data.isp] || data.isp || "";
            let asnOrganization = translate[data.asn_organization] || data.asn_organization || "";

            if (data.country === 'Taiwan') {
                country = (navigator.language === 'en') ? 'China Taiwan' : '中国台湾';
            }

            const countryAbbr = data.country_code.toLowerCase();
            const isChinaIP = ['cn', 'hk', 'mo', 'tw'].includes(countryAbbr);
        
            let firstLineInfo = `<div style="white-space: nowrap;">`;
        
            firstLineInfo += cachedIP + ' ';
        
            let ipLocation = isChinaIP ? 
                '<span style="color: #00FF00;">[国内 IP]</span> ' : 
                '<span style="color: #FF0000;">[境外 IP]</span> ';
           // firstLineInfo += ipLocation;
        
            if (data.chinaIpInfo) {
                firstLineInfo += `[${data.chinaIpInfo}]`;
            }
            firstLineInfo += `</div>`;
        
            document.getElementById('d-ip').innerHTML = firstLineInfo;
            document.getElementById('ipip').innerHTML = `${country} ${isp} ${asnOrganization}`;
            document.getElementById('ipip').style.color = '#FF00FF';
            $("#flag").attr("src", _IMG + "flags/" + countryAbbr + ".png");
        } catch (error) {
            console.error("Error in updateUI:", error);
            document.getElementById('d-ip').innerHTML = "更新IP信息显示失败";
        }
    },

    getIpipnetIP: async () => {
        if(IP.isRefreshing) return;
    
        try {
            IP.isRefreshing = true;
            document.getElementById('d-ip').innerHTML = "Checking...";
            document.getElementById('ipip').innerHTML = "Loading...";
            $("#flag").attr("src", _IMG + "img/loading.svg");
        
            const ip = await IP.fetchIP();
            await IP.Ipip(ip, 'ipip');
        } catch (error) {
            console.error("Error in getIpipnetIP function:", error);
            document.getElementById('ipip').innerHTML = "获取IP信息失败";
        } finally {
            IP.isRefreshing = false;
        }
    }
};

IP.getIpipnetIP();
checkSiteStatus.check();
setInterval(() => checkSiteStatus.check(), 30000);  
setInterval(IP.getIpipnetIP, 180000);
</script>
</body>
</html>