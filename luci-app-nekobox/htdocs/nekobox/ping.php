<?php
ob_start();
include './cfg.php';
$translate = [
    'Argentina' => '阿根廷',
    'Australia' => '澳大利亚',
    'Austria' => '奥地利',
    'Belgium' => '比利时',
    'Brazil' => '巴西',
    'Canada' => '加拿大',
    'Chile' => '智利',
    'China' => '中国',
    'Colombia' => '哥伦比亚',
    'Denmark' => '丹麦',
    'Egypt' => '埃及',
    'Finland' => '芬兰',
    'France' => '法国',
    'Germany' => '德国',
    'Greece' => '希腊',
    'Hong Kong' => '中国香港',
    'India' => '印度',
    'Indonesia' => '印度尼西亚',
    'Iran' => '伊朗',
    'Ireland' => '爱尔兰',
    'Israel' => '以色列',
    'Italy' => '意大利',
    'Japan' => '日本',
    'Kazakhstan' => '哈萨克斯坦',
    'Kenya' => '肯尼亚',
    'Macao' => '中国澳门',
    'Malaysia' => '马来西亚',
    'Mexico' => '墨西哥',
    'Morocco' => '摩洛哥',
    'The Netherlands' => '荷兰',
    'New Zealand' => '新西兰',
    'Nigeria' => '尼日利亚',
    'Norway' => '挪威',
    'Pakistan' => '巴基斯坦',
    'Philippines' => '菲律宾',
    'Poland' => '波兰',
    'Portugal' => '葡萄牙',
    'Russia' => '俄罗斯',
    'Saudi Arabia' => '沙特阿拉伯',
    'Singapore' => '新加坡',
    'South Africa' => '南非',
    'South Korea' => '韩国',
    'Spain' => '西班牙',
    'Sweden' => '瑞典',
    'Switzerland' => '瑞士',
    'Taiwan' => '中国台湾',
    'Thailand' => '泰国',
    'Turkey' => '土耳其',
    'United Arab Emirates' => '阿拉伯联合酋长国',
    'United Kingdom' => '英国',
    'United States' => '美国',
    'Vietnam' => '越南',
    'Afghanistan' => '阿富汗',
    'Albania' => '阿尔巴尼亚',
    'Armenia' => '亚美尼亚',
    'Bahrain' => '巴林',
    'Bangladesh' => '孟加拉国',
    'Barbados' => '巴巴多斯',
    'Belarus' => '白俄罗斯',
    'Bhutan' => '不丹',
    'Bolivia' => '玻利维亚',
    'Bosnia and Herzegovina' => '波斯尼亚和黑塞哥维那',
    'Botswana' => '博茨瓦纳',
    'Brunei' => '文莱',
    'Bulgaria' => '保加利亚',
    'Burkina Faso' => '布基纳法索',
    'Burundi' => '布隆迪',
    'Cambodia' => '柬埔寨',
    'Cameroon' => '喀麦隆',
    'Central African Republic' => '中非共和国',
    'Chad' => '乍得',
    'Comoros' => '科摩罗',
    'Congo' => '刚果',
    'Czech Republic' => '捷克共和国',
    'Dominica' => '多米尼加',
    'Dominican Republic' => '多米尼加共和国',
    'Ecuador' => '厄瓜多尔',
    'El Salvador' => '萨尔瓦多',
    'Equatorial Guinea' => '赤道几内亚',
    'Ethiopia' => '埃塞俄比亚',
    'Fiji' => '斐济',
    'Gabon' => '加蓬',
    'Gambia' => '冈比亚',
    'Georgia' => '格鲁吉亚',
    'Ghana' => '加纳',
    'Grenada' => '格林纳达',
    'Guatemala' => '危地马拉',
    'Guinea' => '几内亚',
    'Guinea-Bissau' => '几内亚比绍',
    'Haiti' => '海地',
    'Honduras' => '洪都拉斯',
    'Hungary' => '匈牙利',
    'Iceland' => '冰岛',
    'Jamaica' => '牙买加',
    'Jordan' => '约旦',
    'Kazakhstan' => '哈萨克斯坦',
    'Kuwait' => '科威特',
    'Kyrgyzstan' => '吉尔吉斯斯坦',
    'Laos' => '老挝',
    'Latvia' => '拉脱维亚',
    'Lebanon' => '黎巴嫩',
    'Lesotho' => '莱索托',
    'Liberia' => '利比里亚',
    'Libya' => '利比亚',
    'Liechtenstein' => '列支敦士登',
    'Lithuania' => '立陶宛',
    'Luxembourg' => '卢森堡',
    'Madagascar' => '马达加斯加',
    'Malawi' => '马拉维',
    'Maldives' => '马尔代夫',
    'Mali' => '马里',
    'Malta' => '马耳他',
    'Mauritania' => '毛里塔尼亚',
    'Mauritius' => '毛里求斯',
    'Moldova' => '摩尔多瓦',
    'Monaco' => '摩纳哥',
    'Mongolia' => '蒙古',
    'Montenegro' => '黑山',
    'Morocco' => '摩洛哥',
    'Mozambique' => '莫桑比克',
    'Myanmar' => '缅甸',
    'Namibia' => '纳米比亚',
    'Nauru' => '瑙鲁',
    'Nepal' => '尼泊尔',
    'Nicaragua' => '尼加拉瓜',
    'Niger' => '尼日尔',
    'Nigeria' => '尼日利亚',
    'North Korea' => '朝鲜',
    'North Macedonia' => '北马其顿',
    'Norway' => '挪威',
    'Oman' => '阿曼',
    'Pakistan' => '巴基斯坦',
    'Palau' => '帕劳',
    'Panama' => '巴拿马',
    'Papua New Guinea' => '巴布亚新几内亚',
    'Paraguay' => '巴拉圭',
    'Peru' => '秘鲁',
    'Philippines' => '菲律宾',
    'Poland' => '波兰',
    'Portugal' => '葡萄牙',
    'Qatar' => '卡塔尔',
    'Romania' => '罗马尼亚',
    'Russia' => '俄罗斯',
    'Rwanda' => '卢旺达',
    'Saint Kitts and Nevis' => '圣基茨和尼维斯',
    'Saint Lucia' => '圣卢西亚',
    'Saint Vincent and the Grenadines' => '圣文森特和格林纳丁斯',
    'Samoa' => '萨摩亚',
    'San Marino' => '圣马力诺',
    'Sao Tome and Principe' => '圣多美和普林西比',
    'Saudi Arabia' => '沙特阿拉伯',
    'Senegal' => '塞内加尔',
    'Serbia' => '塞尔维亚',
    'Seychelles' => '塞舌尔',
    'Sierra Leone' => '塞拉利昂',
    'Singapore' => '新加坡',
    'Slovakia' => '斯洛伐克',
    'Slovenia' => '斯洛文尼亚',
    'Solomon Islands' => '所罗门群岛',
    'Somalia' => '索马里',
    'South Africa' => '南非',
    'South Korea' => '韩国',
    'South Sudan' => '南苏丹',
    'Spain' => '西班牙',
    'Sri Lanka' => '斯里兰卡',
    'Sudan' => '苏丹',
    'Suriname' => '苏里南',
    'Sweden' => '瑞典',
    'Switzerland' => '瑞士',
    'Syria' => '叙利亚',
    'Taiwan' => '中国台湾',
    'Tajikistan' => '塔吉克斯坦',
    'Tanzania' => '坦桑尼亚',
    'Thailand' => '泰国',
    'Timor-Leste' => '东帝汶',
    'Togo' => '多哥',
    'Tonga' => '汤加',
    'Trinidad and Tobago' => '特立尼达和多巴哥',
    'Tunisia' => '突尼斯',
    'Turkey' => '土耳其',
    'Turkmenistan' => '土库曼斯坦',
    'Tuvalu' => '图瓦卢',
    'Uganda' => '乌干达',
    'Ukraine' => '乌克兰',
    'United Arab Emirates' => '阿拉伯联合酋长国',
    'United Kingdom' => '英国',
    'United States' => '美国',
    'Uruguay' => '乌拉圭',
    'Uzbekistan' => '乌兹别克斯坦',
    'Vanuatu' => '瓦努阿图',
    'Vatican City' => '梵蒂冈',
    'Venezuela' => '委内瑞拉',
    'Vietnam' => '越南',
    'Yemen' => '也门',
    'Zambia' => '赞比亚',
    'Zimbabwe' => '津巴布韦'
];
$lang = $_GET['lang'] ?? 'en';
?>
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

#d-ip > .ip-main {
    font-size: 15px !important;
}

#d-ip .badge-primary {
    font-size: 13px !important;
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

@media (max-width: 1206px) {
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
                    <img src="./assets/neko/img/loading.svg" id="flag" title="点击刷新 IP 地址" onclick="IP.getIpipnetIP()">
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
                        <img src="./assets/neko/img/site_icon_01.png" id="baidu-normal" title="测试 Baidu 延迟" class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_01.png" id="baidu-gray" class="status-icon">
                    </div>
                    <div class="site-icon mx-1" onclick="pingHost('taobao', 'Taobao')">
                        <img src="./assets/neko/img/site_icon_02.png" id="taobao-normal" title="测试 Taobao 延迟"  class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_02.png" id="taobao-gray" class="status-icon">
                    </div>
                    <div class="site-icon mx-1" onclick="pingHost('google', 'Google')">
                        <img src="./assets/neko/img/site_icon_03.png" id="google-normal" title="测试 Google 延迟"  class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_03.png" id="google-gray" class="status-icon">
                    </div>
                    <div class="site-icon mx-1" onclick="pingHost('youtube', 'YouTube')">
                        <img src="./assets/neko/img/site_icon_04.png" id="youtube-normal" title="测试 YouTube 延迟" class="status-icon" style="display: none;">
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
<link rel="stylesheet" href="./assets/bootstrap/leaflet.css" />
<script src="./assets/bootstrap/leaflet.js"></script>
<script type="text/javascript">
const _IMG = './assets/neko/';
const translate = <?php echo json_encode($translate, JSON_UNESCAPED_UNICODE); ?>;
let cachedIP = null;
let cachedInfo = null;
let random = parseInt(Math.random() * 100000000);

const sitesToPing = {
    baidu: { url: 'https://www.baidu.com', name: 'Baidu' },
    taobao: { url: 'https://www.taobao.com', name: 'Taobao' },
    google: { url: 'https://www.google.com', name: 'Google' },
    youtube: { url: 'https://www.youtube.com', name: 'YouTube' },
    github: { url: 'https://www.github.com', name: 'GitHub' }
};

async function checkAllPings() {
    const pingResults = {};
    for (const [key, site] of Object.entries(sitesToPing)) {
        const { url, name } = site;
        try {
            const startTime = performance.now();
            await fetch(url, { mode: 'no-cors', cache: 'no-cache' });
            const endTime = performance.now();
            const pingTime = Math.round(endTime - startTime);
            pingResults[key] = { name, pingTime };
        } catch (error) {
            pingResults[key] = { name, pingTime: '超时' };
        }
    }
    return pingResults;
}

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

async function onlineTranslate(text, targetLang = 'zh') {
    if (!text || typeof text !== 'string' || text.trim() === '') {
        return text;
    }

    const cacheKey = `trans_${text}_${targetLang}`;
    const cachedTranslation = localStorage.getItem(cacheKey);
    if (cachedTranslation) {
        return cachedTranslation;
    }

    const apis = [
        {
            url: 'https://api.mymemory.translated.net/get?q=' + encodeURIComponent(text) + '&langpair=en|' + targetLang,
            method: 'GET',
            parseResponse: (data) => data.responseData.translatedText
        },
        {
            url: 'https://libretranslate.com/translate',
            method: 'POST',
            body: JSON.stringify({
                q: text,
                source: 'en',
                target: targetLang,
                format: 'text'
            }),
            headers: {
                'Content-Type': 'application/json'
            },
            parseResponse: (data) => data.translatedText
        },
        {
            url: `https://lingva.ml/api/v1/en/${targetLang}/${encodeURIComponent(text)}`,
            method: 'GET',
            parseResponse: (data) => data.translation
        },
        {
            url: `https://simplytranslate.org/api/translate?engine=google&from=en&to=${targetLang}&text=${encodeURIComponent(text)}`,
            method: 'GET',
            parseResponse: (data) => data.translatedText
        }
    ];

    for (const api of apis) {
        try {
            const response = await fetch(api.url, {
                method: api.method,
                headers: api.headers || {},
                body: api.body || null
            });

            if (response.ok) {
                const data = await response.json();
                const translatedText = api.parseResponse(data);
                
                try {
                    localStorage.setItem(cacheKey, translatedText);
                } catch (e) {
                    clearOldCache();
                    localStorage.setItem(cacheKey, translatedText);
                }
                
                return translatedText;
            }
        } catch (error) {
            continue;
        }
    }

    return text;
}

function clearOldCache() {
    const cachePrefix = 'trans_';
    const cacheKeys = Object.keys(localStorage).filter(key => 
        key.startsWith(cachePrefix)
    );
    
    if (cacheKeys.length > 1000) {
        const itemsToRemove = cacheKeys.slice(0, cacheKeys.length - 1000);
        itemsToRemove.forEach(key => localStorage.removeItem(key));
    }
}

async function translateText(text, targetLang = 'zh') {
    if (translate[text]) {
        return translate[text];
    } 
    return await onlineTranslate(text, targetLang);
}

let IP = {
    isRefreshing: false,
    lastGeoData: null, 
    ipApis: [
        {url: 'https://api.ipify.org?format=json', type: 'json', key: 'ip'},
        {url: 'https://api-ipv4.ip.sb/geoip', type: 'json', key: 'ip'},
        {url: 'https://myip.ipip.net', type: 'text'},
        {url: 'http://pv.sohu.com/cityjson', type: 'text'},
        {url: 'https://ipinfo.io/json', type: 'json', key: 'ip'},
        {url: 'https://ipapi.co/json/', type: 'json'},
        {url: 'https://freegeoip.app/json/', type: 'json'}
    ],

    fetchIP: async () => {
        let error;
        for(let api of IP.ipApis) {
            try {
                const response = await IP.get(api.url, api.type);
                if(api.type === 'json') {
                    const ipData = api.key ? response.data[api.key] : response.data;
                    cachedIP = ipData;
                    document.getElementById('d-ip').innerHTML = ipData;
                    return ipData;
                } else {
                    const ipData = response.data.match(/\d+\.\d+\.\d+\.\d+/)?.[0];
                    if(ipData) {
                        cachedIP = ipData;
                        document.getElementById('d-ip').innerHTML = ipData;
                        return ipData;
                    }
                }
            } catch(e) {
                error = e;
                console.error(`Error with ${api.url}:`, e);
                continue;
            }
        }
        throw error || new Error("All IP APIs failed");
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
        const geoApis = [
            {url: `https://api.ip.sb/geoip/${ip}`, type: 'json'},
            {url: 'https://myip.ipip.net', type: 'text'},
            {url: `http://ip-api.com/json/${ip}`, type: 'json'},
            {url: `https://ipinfo.io/${ip}/json`, type: 'json'},
            {url: `https://ipapi.co/${ip}/json/`, type: 'json'},
            {url: `https://freegeoip.app/json/${ip}`, type: 'json'}
        ];

        let geoData = null;
        let error;

        for(let api of geoApis) {
            try {
                const response = await IP.get(api.url, api.type);
                geoData = response.data;
                break;
            } catch(e) {
                error = e;
                console.error(`Error with ${api.url}:`, e);
                continue;
            }
        }

        if(!geoData) {
            throw error || new Error("All Geo APIs failed");
        }

        cachedIP = ip;
        IP.lastGeoData = geoData; 
        
        IP.updateUI(geoData, elID);
    },

    updateUI: async (data, elID) => {
        try {
            const country = await translateText(data.country || "未知");
            const region = await translateText(data.region || "");
            const city = await translateText(data.city || "");
            const isp = await translateText(data.isp || "");
            const asnOrganization = await translateText(data.asn_organization || "");

            let location = `${region && city && region !== city ? `${region} ${city}` : region || city || ''}`;
            let simpleDisplay = `
                <div class="ip-main" style="cursor: pointer;" onclick="IP.showDetailModal()" title="点击查看 IP 详细信息">
                    ${cachedIP} <span class="badge badge-primary" style="color: #333;">${country}</span>
                </div>`;
        
            let locationInfo = `<span style="margin-left: 8px;">${location} ${isp} ${data.asn || ''} ${asnOrganization}</span>`;
        
            document.getElementById('d-ip').innerHTML = simpleDisplay;
            document.getElementById('ipip').innerHTML = locationInfo;
            const countryCode = data.country_code || 'unknown';
            const flagSrc = (countryCode !== 'unknown') ? _IMG + "flags/" + countryCode.toLowerCase() + ".png" : './assets/neko/flags/cn.png';
            $("#flag").attr("src", flagSrc);
        
        } catch (error) {
            console.error("Error in updateUI:", error);
            document.getElementById('d-ip').innerHTML = "更新 IP 信息失败";
            $("#flag").attr("src", "./assets/neko/flags/mo.png");
        }
    },

    showDetailModal: async () => {
        const data = IP.lastGeoData;
        if (!data) return;

        const translatedCountry = await translateText(data.country, 'zh');
        const translatedRegion = await translateText(data.region, 'zh');  
        const translatedCity = await translateText(data.city, 'zh');
        const translatedIsp = await translateText(data.isp, 'zh');
        const translatedAsnOrganization = await translateText(data.asn_organization, 'zh');

        let country = translatedCountry || data.country || "未知";
        let region = translatedRegion || data.region || "";
        let city = translatedCity || data.city || "";
        let isp = translatedIsp || data.isp || "";
        let asnOrganization = translatedAsnOrganization || data.asn_organization || "";
        let timezone = data.timezone || "";
        let asn = data.asn || "";

        let areaDisplay = [country, region, city].filter(Boolean).join(" ");
        if (region === city) {
            areaDisplay = `${country} ${region}`; 
        }

        let ipSupport;
        const ipv4Regex = /^(\d{1,3}\.){3}\d{1,3}$/;
        const ipv6Regex = /^[a-fA-F0-9:]+$/;
 
        if (ipv4Regex.test(cachedIP)) {
            ipSupport = 'IPv4 支持';
        } else if (ipv6Regex.test(cachedIP)) {
            ipSupport = 'IPv6 支持';
        } else {
            ipSupport = '未检测到 IPv4 或 IPv6 支持';
        }

        const pingResults = await checkAllPings();
        const delayInfoHTML = Object.entries(pingResults).map(([key, { name, pingTime }]) => {
            let color = '#ff6b6b'; 
            if (typeof pingTime === 'number') {
                color = pingTime <= 100 ? '#09B63F' : pingTime <= 200 ? '#FFA500' : '#ff6b6b';
            }
            return `<span style="margin-right: 20px; font-size: 18px; color: ${color};">${name}: ${pingTime === '超时' ? '超时' : `${pingTime}ms`}</span>`;
        }).join('');

        let lat = data.latitude || null;
        let lon = data.longitude || null;

        if (!lat || !lon) {
            try {
                const response = await fetch(`https://ipapi.co/${cachedIP}/json/`);
                const geoData = await response.json();
                lat = geoData.latitude;
                lon = geoData.longitude;
            } catch (error) {
                console.error("获取 IP 地理位置失败:", error);
            }
        }

        const modalHTML = `
            <div class="modal fade custom-modal" id="ipDetailModal" tabindex="-1" role="dialog" aria-labelledby="ipDetailModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
                <div class="modal-dialog modal-dialog-centered modal-lg" role="document">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title" id="ipDetailModalLabel">IP详细信息</h5>
                            <button type="button" class="close" data-bs-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div class="ip-details">
                                <div class="detail-row">
                                    <span class="detail-label">IP支持:</span>
                                    <span class="detail-value">${ipSupport}</span>
                            </div>
                                <div class="detail-row">
                                    <span class="detail-label">IP地址:</span>
                                    <span class="detail-value">${cachedIP}</span>
                                </div>
                                <div class="detail-row">
                                    <span class="detail-label">地区:</span>
                                    <span class="detail-value">${areaDisplay}</span>
                                </div>
                                <div class="detail-row">
                                    <span class="detail-label">运营商:</span>
                                    <span class="detail-value">${isp}</span>
                                </div>
                                <div class="detail-row">
                                    <span class="detail-label">ASN:</span>
                                    <span class="detail-value">${asn} ${asnOrganization}</span>
                                </div>
                                <div class="detail-row">
                                    <span class="detail-label">时区:</span>
                                    <span class="detail-value">${timezone}</span>
                                </div>
                                ${data.latitude && data.longitude ? `
                                <div class="detail-row">
                                    <span class="detail-label">经纬度:</span>
                                    <span class="detail-value">${data.latitude}, ${data.longitude}</span>
                                </div>` : ''}                           
                                ${lat && lon ? `
                                <div class="detail-row" style="height: 400px; margin-top: 20px;">
                                    <div id="leafletMap" style="width: 100%; height: 100%;"></div>
                                </div>` : ''}
                                <h5 style="margin-top: 15px;">延迟信息:</h5>
                                <div class="detail-row" style="display: flex; flex-wrap: wrap;">
                                    ${delayInfoHTML}
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
                        </div>
                    </div>
                </div>
            </div>
        `;

        $('#ipDetailModal').remove();
        $('body').append(modalHTML);
        $('#ipDetailModal').modal('show');

        setTimeout(() => {
            if (lat && lon) {
                const map = L.map('leafletMap').setView([lat, lon], 10);

                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);

                const popupContent = city || region || "当前位置";
                L.marker([lat, lon]).addTo(map)
                    .bindPopup(popupContent)
                    .openPopup();
            }
        }, 500); 
    },

    getIpipnetIP: async () => {
        if(IP.isRefreshing) return;
    
        try {
            IP.isRefreshing = true;
            document.getElementById('d-ip').innerHTML = `
                <div class="ip-main">
                    <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                    检查中...
                </div>
            `;
            document.getElementById('ipip').innerHTML = "";
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

const style = document.createElement('style');
style.textContent = `
.ip-main {
    font-size: 14px;
    padding: 5px;
    transition: all 0.3s;
    display: inline-flex;
    align-items: center;
    gap: 8px;
}

.badge-primary {
    color: #ff69b4 !important;
    background-color: #f8f9fa !important;
    border: 1px solid #dee2e6;
}

#ipip {
    margin-left: -3px;
}

.ip-main:hover {
    background: #f0f0f0;
    border-radius: 4px;
}

.ip-details {
    font-size: 18px !important;
    line-height: 1.6;
}

.detail-row {
    margin-bottom: 12px;
    display: flex;
}

.detail-label {
    font-weight: 500;
    color: #666;
    flex: 0 0 80px;
}

.detail-value {
    color: #333;
    flex: 1;
}

.modal-content {
    border-radius: 8px;
}

.modal-header {
    background: #f8f9fa;
    border-radius: 8px 8px 0 0;
}

.modal-body {
    padding: 20px;
}

.custom-modal .modal-header {
    background-color: #007bff;
    color: #fff;
    padding: 16px 20px;
    border-bottom: 1px solid #ddd;
    border-top-left-radius: 8px;
    border-top-right-radius: 8px;
}

.custom-modal .custom-close {
    color: #fff;
    font-size: 1.5rem;
    opacity: 0.7;
}

.custom-modal .custom-close:hover {
    color: #ddd;
    opacity: 1;
}

.custom-modal .modal-body {
    padding: 20px;
    font-size: 1rem;
    color: #333;
    line-height: 1.6;
}

.custom-modal .detail-row {
    display: flex;
    justify-content: space-between;
    padding: 8px 0;
    border-bottom: 1px solid #eee;
}

.custom-modal .detail-label {
    font-weight: 600;
    color: #555;
}

.custom-modal .detail-value {
    font-weight: 400;
    color: #333;
}

.custom-modal .modal-footer {
    background-color: #f7f7f7;
    padding: 12px 16px;
    display: flex;
    justify-content: flex-end;
    border-top: 1px solid #ddd;
}

.custom-modal .custom-close-btn {
    background-color: #007bff;
    color: #fff;
    border: none;
    padding: 8px 16px;
    font-size: 1rem;
    border-radius: 4px;
    cursor: pointer;
    transition: background-color 0.3s ease;
}

.custom-modal .custom-close-btn:hover {
    background-color: #0056b3;
}
`;
document.head.appendChild(style);
IP.getIpipnetIP();
if(typeof checkSiteStatus !== 'undefined') {
    checkSiteStatus.check();
    setInterval(() => checkSiteStatus.check(), 30000);
}

setInterval(IP.getIpipnetIP, 180000);
</script>