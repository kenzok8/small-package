<?php
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
   body {
       font-family: 'Montserrat', sans-serif;
       line-height: 1.6;
   }
   
   .cbi-section {
       position: fixed;
       bottom: 60px;
       left: 50%;
       transform: translateX(-50%);
       width: 100%;
       max-width: 1300px;
       margin: 0 auto;
       padding: 0 15px;
       z-index: 1030;
   }

   .status {
       display: flex;
       align-items: center;
       justify-content: space-between;
       background-color: #E6E6FA;
       color: var(--bs-btn-color);
       text-align: left;
       border-radius: 8px;
       height: 65px;
       letter-spacing: 0.5px;
       box-shadow: 0 2px 10px rgba(0,0,0,0.1);
       padding: 0 30px;
       width: 100%;
   }

   .img-con {
       margin-right: 1.5rem;
   }

   .img-con img {
       width: 65px;
       height: auto;
       border-radius: 5px; 
   }

   .block {
       display: flex;
       flex-direction: column;
       justify-content: center;
       min-width: 200px;
   }

   .ip-address {
       color: #2dce89;
       font-weight: bold;
       font-size: 1.1rem;
       margin: 0;
   }

   .info {
       font-style: italic;
       color: #fb6340;
       font-weight: 520; 
       font-size: 1.1rem;
       margin: 0;
       letter-spacing: 0.02em; 
       font-style: normal; 
       -webkit-font-smoothing: antialiased;
       -moz-osx-font-smoothing: grayscale;
       text-rendering: optimizeLegibility;
   }

   .site-status {
       display: flex;
       align-items: center;
       min-width: 300px;
   }

   .status-icons {
       display: flex;
       align-items: center;
       gap: 25px;
       margin-left: auto;
       height: 100%;
   }

   .site-icon {
       display: flex;
       align-items: center;
       height: 100%;
   }

   .status-icon {
       width: auto;
       height: 48px;
       max-height: 48px;
       cursor: pointer;
       transition: all 0.3s ease;
       object-fit: contain;
       vertical-align: middle;
   }

   .status-icon:hover {
       transform: scale(1.1);
   }

   .ping-status {
       flex-grow: 1;
       text-align: center;
       margin: 0 20px;
   }

   #ping-result {
       margin: 0;
       color: #666;
       font-size: 14px;
   }

   .site-icon {
       cursor: pointer;
   }

   #flag {
       cursor: pointer;  
   }

   @media screen and (max-width: 480px) {
       .status-icons {
           gap: 4px;
       }
       
       .status-icon {
           width: 24px;
           height: 24px;  
       }

       .status {  
           padding: 0 8px;
           height: auto;
           margin-bottom: 4px;
       }

       .img-con img {
           width: 32px;
       }

       .ip-address {
           font-size: 0.5rem;
       }
       
       .info {
           font-size: 0.7rem;
       }

       .ping-status {
           margin-top: 0;
       }
   }
</style>

<?php if (in_array($lang, ['zh-cn', 'en', 'auto'])): ?>
    <fieldset class="cbi-section">
        <div class="status">
            <div class="site-status">
                <div class="img-con">
                    <img src="./assets/neko/img/loading.svg" id="flag" class="pure-img" title="国旗" onclick="IP.getIpipnetIP()">
                </div>
                <div class="block">
                    <p id="d-ip" class="ip-address">Checking...</p>
                    <p id="ipip" class="info"></p>
                </div>
            </div>  
                <div class="ping-status">
                    <p id="ping-result"></p>
                </div>         
            <div class="status-icons">
                <div class="site-icon">
                    <img src="./assets/neko/img/site_icon_01.png" id="baidu-normal" class="status-icon" style="display: none;" onclick="pingHost('baidu', 'Baidu')">
                    <img src="./assets/neko/img/site_icon1_01.png" id="baidu-gray" class="status-icon" onclick="pingHost('baidu', 'Baidu')">
                </div>
                <div class="site-icon">
                    <img src="./assets/neko/img/site_icon_02.png" id="taobao-normal" class="status-icon" style="display: none;" onclick="pingHost('taobao', '淘宝')">
                    <img src="./assets/neko/img/site_icon1_02.png" id="taobao-gray" class="status-icon" onclick="pingHost('taobao', '淘宝')">
                </div>
                <div class="site-icon">
                    <img src="./assets/neko/img/site_icon_03.png" id="google-normal" class="status-icon" style="display: none;" onclick="pingHost('google', 'Google')">
                    <img src="./assets/neko/img/site_icon1_03.png" id="google-gray" class="status-icon" onclick="pingHost('google', 'Google')">
                </div>
                <div class="site-icon">
                    <img src="./assets/neko/img/site_icon_04.png" id="youtube-normal" class="status-icon" style="display: none;" onclick="pingHost('youtube', 'YouTube')">
                    <img src="./assets/neko/img/site_icon1_04.png" id="youtube-gray" class="status-icon" onclick="pingHost('youtube', 'YouTube')">
                </div>
            </div>
        </div>
    </fieldset>
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
            youtube: 'https://www.youtube.com'
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
            resultElement.innerHTML = `<span style="font-size: 20px">正在测试 ${siteName} 的连接延迟...`;
            resultElement.style.color = '#666';        
            const startTime = performance.now();
            await fetch(url, {
                mode: 'no-cors',
                cache: 'no-cache'
            });
            const endTime = performance.now();
            const pingTime = Math.round(endTime - startTime);      
            resultElement.innerHTML = `<span style="font-size: 20px">${siteName} 连接延迟: ${pingTime}ms</span>`;
            resultElement.style.color = pingTime > 200 ? '#ff6b6b' : '#20c997';
        } catch (error) {
            resultElement.innerHTML = `${siteName} 连接超时`;
            resultElement.style.color = '#ff6b6b';
        }
    }

    let IP = {
        isRefreshing: false,
        fetchIP: async () => {
            try {
                const [ipifyResp, ipsbResp] = await Promise.all([
                    IP.get('https://api.ipify.org?format=json', 'json'),
                    IP.get('https://api-ipv4.ip.sb/geoip', 'json')
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
                const resp = await IP.get(`https://api.ip.sb/geoip/${ip}`, 'json');
                cachedIP = ip;
                cachedInfo = resp.data;
                IP.updateUI(resp.data, elID);
            } catch (error) {
                console.error("Error in Ipip function:", error);
            }
        },

        updateUI: (data, elID) => {
            let country = translate[data.country] || data.country;
            let isp = translate[data.isp] || data.isp;
            let asnOrganization = translate[data.asn_organization] || data.asn_organization;

            if (data.country === 'Taiwan') {
                country = (navigator.language === 'en') ? 'China Taiwan' : '中国台湾';
            }
            const countryAbbr = data.country_code.toLowerCase();

            document.getElementById(elID).innerHTML = `${country} ${isp} ${asnOrganization}`;
            $("#flag").attr("src", _IMG + "flags/" + countryAbbr + ".png");
            document.getElementById(elID).style.color = '#FF00FF';
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