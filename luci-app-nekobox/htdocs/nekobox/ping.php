<?php
$default_url = 'https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/songs.txt';

$message = '';  

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['new_url'])) {
        $new_url = $_POST['new_url'];  
        $file_path = 'url_config.txt';  
        if (file_put_contents($file_path, $new_url)) {
            $message = 'URL 更新成功！';
        } else {
            $message = '更新 URL 失败！';
        }
    }

    if (isset($_POST['reset_default'])) {
        $file_path = 'url_config.txt';  
        if (file_put_contents($file_path, $default_url)) {
            $message = '恢复默认链接成功！';
        } else {
            $message = '恢复默认链接失败！';
        }
    }
}
else {
    $new_url = file_exists('url_config.txt') ? file_get_contents('url_config.txt') : $default_url;
}
?>

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

.site-icon[onclick*="openai"] .status-icon {
  width: 62px; 
  height: 64px;
  margin-top: -2px;
}

.site-icon[onclick*="openai"] {
  width: 62px;
  height: 64px;
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
 .site-icon[onclick*="openai"],
 .site-icon[onclick*="youtube"],
 .site-icon[onclick*="github"] {
   display: none !important;
 }
}
</style>
<?php if (in_array($lang, ['zh-cn', 'en', 'auto'])): ?>
    <div id="status-bar-component" class="container-sm container-bg callout border border-3 rounded-4 col-11">
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
                    <div class="site-icon mx-1" onclick="pingHost('openai', 'OpenAI')">
                        <img src="./assets/neko/img/site_icon_06.png" id="openai-normal" title="测试 OpenAI  延迟"  class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_06.png" id="openai-gray" class="status-icon">
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
<style>
    #leafletMap {
        width: 100%;
        height: 400px;
        position: relative;
    }

    #leafletMap.fullscreen {
        width: 100vw;
        height: 100vh;
        position: fixed;
        top: 0;
        left: 0;
        z-index: 9999;
    }

    .fullscreen-btn,
    .exit-fullscreen-btn {
        position: absolute;
        top: 10px;
        right: 10px;
        background-color: #fff;
        border: 1px solid #ccc;
        padding: 5px;
        cursor: pointer;
        border-radius: 50%;
        font-size: 20px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
        z-index: 10000;
    }

    .exit-fullscreen-btn {
        display: none;
    }

    #d-ip {
        display: flex;
        align-items: center;
        gap: 5px;  
        flex-wrap: nowrap;  
    }

</style>
<link href="./assets/bootstrap/bootstrap-icons.css" rel="stylesheet">
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
    github: { url: 'https://www.github.com', name: 'GitHub' },
    openai : { url: 'https://www.openai.com', name: 'OpenAI' }
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
        github: 'https://www.github.com',
        openai: 'https://www.openai.com'
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
        if(pingTime <= 300) {
                resultElement.style.color = '#09B63F'; 
        } else if(pingTime <= 700) {
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

            let displayISP = isp;
            let displayASN = asnOrganization;

            if (isp && asnOrganization && asnOrganization.includes(isp)) {
                displayISP = '';  
            } else if (isp && asnOrganization && isp.includes(asnOrganization)) {
                displayASN = '';  
            }

            let locationInfo = `<span style="margin-left: 8px; position: relative; top: -4px;">${location} ${displayISP} ${data.asn || ''} ${displayASN}</span>`;

            const isHidden = localStorage.getItem("ipHidden") === "true";

            let simpleDisplay = `
                <div class="ip-main" style="cursor: pointer; position: relative; top: -4px;" onclick="IP.showDetailModal()" title="点击查看 IP 详细信息">
                    <div style="display: flex; align-items: center; justify-content: flex-start; gap: 10px; ">
                        <div style="display: flex; align-items: center; gap: 5px;">
                            <span id="ip-address">${isHidden ? '***.***.***.***.***' : cachedIP}</span> 
                            <span class="badge badge-primary" style="color: #333;">${country}</span>
                        </div>
                    </div>
                </div>
                <span id="toggle-ip" style="cursor: pointer; position: relative; top: -3px;  text-indent: 1ch; padding-top: 2px;" title="点击隐藏/显示 IP">
                    <i class="fa ${isHidden ? 'bi-eye-slash' : 'bi-eye'}"></i>  
                </span>
            `;

            document.getElementById('d-ip').innerHTML = simpleDisplay;
            document.getElementById('ipip').innerHTML = locationInfo;

            const countryCode = data.country_code || 'unknown';
            const flagSrc = (countryCode === 'TW') ? _IMG + "flags/cn.png"  : (countryCode !== 'unknown') ? _IMG + "flags/" + countryCode.toLowerCase() + ".png"  : './assets/neko/flags/cn.png';
            $("#flag").attr("src", flagSrc);

            document.getElementById('toggle-ip').addEventListener('click', () => {
                const ipElement = document.getElementById('ip-address');
                const iconElement = document.getElementById('toggle-ip').querySelector('i');

                if (ipElement.textContent === cachedIP) {
                    ipElement.textContent = '***.***.***.***.***';
                    iconElement.classList.remove('bi-eye');
                    iconElement.classList.add('bi-eye-slash');  
                    localStorage.setItem("ipHidden", "true");  
                } else {
                    ipElement.textContent = cachedIP;  
                    iconElement.classList.remove('bi-eye-slash');
                    iconElement.classList.add('bi-eye');  
                    localStorage.setItem("ipHidden", "false");  
                }
            });

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
                color = pingTime <= 300 ? '#09B63F' : pingTime <= 700 ? '#FFA500' : '#ff6b6b';
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
                <div class="modal-dialog modal-dialog-centered modal-xl" role="document">
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

                const fullscreenButton = document.createElement('button');
                fullscreenButton.classList.add('fullscreen-btn');
                fullscreenButton.innerHTML = '🗖';  
                document.getElementById('leafletMap').appendChild(fullscreenButton);

                const exitFullscreenButton = document.createElement('button');
                exitFullscreenButton.classList.add('exit-fullscreen-btn');
                exitFullscreenButton.innerHTML = '❎';  
                document.getElementById('leafletMap').appendChild(exitFullscreenButton);

                fullscreenButton.onclick = function() {
                    const mapContainer = document.getElementById('leafletMap');
                    mapContainer.classList.add('fullscreen');  
                    fullscreenButton.style.display = 'none';  
                    exitFullscreenButton.style.display = 'block';  
                    map.invalidateSize();
                };

                exitFullscreenButton.onclick = function() {
                    const mapContainer = document.getElementById('leafletMap');
                    mapContainer.classList.remove('fullscreen');  
                    fullscreenButton.style.display = 'block';  
                    exitFullscreenButton.style.display = 'none';  
                    map.invalidateSize();
                };
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

<script>
document.addEventListener('keydown', function(event) {
    if (event.ctrlKey && event.shiftKey && event.code === 'KeyC') {
        clearCache();
        event.preventDefault();  
    }
});

function clearCache() {
    location.reload(true); 

    localStorage.clear();
    sessionStorage.clear();

    sessionStorage.setItem('cacheCleared', 'true');

    showNotification('缓存已清除');
}

function showNotification(message) {
    var notification = document.createElement('div');
    notification.style.position = 'fixed';
    notification.style.top = '10px';
    notification.style.right = '30px';
    notification.style.backgroundColor = '#4CAF50';
    notification.style.color = '#fff';
    notification.style.padding = '10px';
    notification.style.borderRadius = '5px';
    notification.style.zIndex = '9999';
    notification.innerText = message;

    document.body.appendChild(notification);

    setTimeout(function() {
        notification.style.display = 'none';
    }, 5000); 
}

window.addEventListener('load', function() {
    if (sessionStorage.getItem('cacheCleared') === 'true') {
        showNotification('缓存已清除');
        sessionStorage.removeItem('cacheCleared'); 
    }
});
</script>

<script>
    const audioPlayer = new Audio();  
    let songs = [];  
    let currentSongIndex = 0;  
    let isPlaying = false;  
    let isReportingTime = false; 
    let isLooping = false; 
    let hasModalShown = false;

    const logBox = document.createElement('div');
    logBox.style.position = 'fixed';
    logBox.style.top = '90%';  
    logBox.style.left = '20px';
    logBox.style.padding = '10px';
    logBox.style.backgroundColor = 'green';
    logBox.style.color = 'white';
    logBox.style.borderRadius = '5px';
    logBox.style.zIndex = '9999';
    logBox.style.maxWidth = '250px'; 
    logBox.style.fontSize = '14px';
    logBox.style.display = 'none'; 
    logBox.style.maxWidth = '300px';  
    logBox.style.wordWrap = 'break-word'; 
    document.body.appendChild(logBox);

    function showLogMessage(message) {
        logBox.textContent = message;
        logBox.style.display = 'block';
        logBox.style.animation = 'scrollUp 8s ease-out forwards'; 
        logBox.style.width = 'auto'; 
        logBox.style.maxWidth = '300px'; 

        setTimeout(() => {
            logBox.style.display = 'none';
        }, 8000); 
    }

    const styleSheet = document.createElement('style');
    styleSheet.innerHTML = `
        @keyframes scrollUp {
            0% {
                top: 90%;
            }
            100% {
                top: 50%;
            }
        }
    `;
    document.head.appendChild(styleSheet);

    function loadDefaultPlaylist() {
        fetch('<?php echo $new_url; ?>')
            .then(response => {
                if (!response.ok) {
                    throw new Error('加载播放列表失败');
                }
                return response.text();
            })
            .then(data => {
                songs = data.split('\n').filter(url => url.trim() !== ''); 
                if (songs.length === 0) {
                    throw new Error('播放列表中没有有效的歌曲');
                }
                console.log('播放列表已加载:', songs);
                restorePlayerState(); 
            })
            .catch(error => {
                console.error('加载播放列表时出错:', error.message);
            });
    }

    function loadSong(index) {
        if (index >= 0 && index < songs.length) {
            audioPlayer.src = songs[index];  
            audioPlayer.addEventListener('loadedmetadata', () => {
                const savedState = JSON.parse(localStorage.getItem('playerState'));
                if (savedState && savedState.currentSongIndex === index) {
                    audioPlayer.currentTime = savedState.currentTime || 0; 
                    if (savedState.isPlaying) {
                        audioPlayer.play().catch(error => {
                            console.error('恢复播放失败:', error);
                        });
                    }
                }
            }, { once: true }); 
        }
    }

    document.addEventListener('dblclick', function () {
        if (!isPlaying) {
            loadSong(currentSongIndex);
            audioPlayer.play().then(() => {
                isPlaying = true;
                savePlayerState(); 
                console.log('开始播放');
            }).catch(error => {
                console.log('播放失败:', error);
            });
        } else {
            audioPlayer.pause();
            isPlaying = false;
            savePlayerState(); 
            console.log('播放已暂停');
        }
    });

    window.addEventListener('keydown', function (event) {
        if (event.key === 'ArrowUp') {
            currentSongIndex = (currentSongIndex - 1 + songs.length) % songs.length; 
            loadSong(currentSongIndex);
            savePlayerState(); 
            if (isPlaying) {
                audioPlayer.play();  
            }
            const songName = getSongName(songs[currentSongIndex]); 
            showLogMessage(`上一首：${songName}`);
        } else if (event.key === 'ArrowDown') {
            currentSongIndex = (currentSongIndex + 1) % songs.length; 
            loadSong(currentSongIndex);
            savePlayerState();
            if (isPlaying) {
                audioPlayer.play();
            }
            const songName = getSongName(songs[currentSongIndex]); 
            showLogMessage(`下一首：${songName}`);
        } else if (event.key === 'ArrowLeft') {
            audioPlayer.currentTime = Math.max(audioPlayer.currentTime - 10, 0); 
            console.log('快退 10 秒');
            savePlayerState();
            showLogMessage('快退 10 秒');
        } else if (event.key === 'ArrowRight') {
            audioPlayer.currentTime = Math.min(audioPlayer.currentTime + 10, audioPlayer.duration || Infinity); 
            console.log('快进 10 秒');
            savePlayerState();
            showLogMessage('快进 10 秒');
        } else if (event.key === 'Escape') { 
            localStorage.removeItem('playerState');
            currentSongIndex = 0;
            loadSong(currentSongIndex);
            savePlayerState();
            console.log('恢复到第一首');
            showLogMessage('恢复到第一首');
            if (isPlaying) {
                audioPlayer.play();
            }
        } else if (event.key === 'F9') { 
            if (isPlaying) {
                audioPlayer.pause();
                isPlaying = false;
                savePlayerState(); 
                console.log('暂停播放');
                showLogMessage('暂停播放');
            } else {
                audioPlayer.play().then(() => {
                    isPlaying = true;
                    savePlayerState(); 
                    console.log('开始播放');
                    showLogMessage('开始播放');
                }).catch(error => {
                    console.log('播放失败:', error);
                });
            }
        } else if (event.key === 'F2') { 
            isLooping = !isLooping;
            if (isLooping) {
                console.log('循环播放');
                showLogMessage('循环播放');
            } else {
                console.log('顺序播放');
                showLogMessage('顺序播放');
            }
        }
    });

    function getSongName(url) {
        const pathParts = url.split('/');
        return pathParts[pathParts.length - 1]; 
    }

    function startHourlyAlert() {
        setInterval(() => {
            const now = new Date();
            const hours = now.getHours();

            if (now.getMinutes() === 0 && !isReportingTime) {
                isReportingTime = true;  

                const timeAnnouncement = new SpeechSynthesisUtterance(`整点报时，现在是北京时间 ${hours} 点整`);
                timeAnnouncement.lang = 'zh-CN';
                speechSynthesis.speak(timeAnnouncement);

                console.log(`整点报时：现在是北京时间 ${hours} 点整`);
            }

            if (now.getMinutes() !== 0) {
                isReportingTime = false;
            }
        }, 60000); 
    }

    audioPlayer.addEventListener('ended', function () {
        if (isLooping) {
            loadSong(currentSongIndex); 
            savePlayerState();
            audioPlayer.play();
        } else {
            currentSongIndex = (currentSongIndex + 1) % songs.length;  
            loadSong(currentSongIndex);  
            savePlayerState(); 
            audioPlayer.play();
        }
    });

    function savePlayerState() {
        const state = {
            currentSongIndex,       
            currentTime: audioPlayer.currentTime,
            isPlaying,
            isLooping,
            timestamp: Date.now()
        };
        localStorage.setItem('playerState', JSON.stringify(state));
    }

    function clearExpiredPlayerState() {
        const state = JSON.parse(localStorage.getItem('playerState'));
    
        if (state) {
            const currentTime = Date.now();
            const stateAge = currentTime - state.timestamp;  

            const expirationTime = 60 * 60 * 1000;  

            if (stateAge > expirationTime) {
                localStorage.removeItem('playerState');  
                console.log('播放状态已过期，已清除');
            }
        }
    }

    setInterval(clearExpiredPlayerState, 10 * 60 * 1000);

    function restorePlayerState() {
        const state = JSON.parse(localStorage.getItem('playerState'));
        if (state) {
            currentSongIndex = state.currentSongIndex || 0;
            isLooping = state.isLooping || false; 
            loadSong(currentSongIndex);
            if (state.isPlaying) {
                isPlaying = true;
                audioPlayer.currentTime = state.currentTime || 0;
                audioPlayer.play().catch(error => {
                    console.error('恢复播放失败:', error);
                });
            }
        }
    }

    document.addEventListener('dblclick', function () {
        const lastShownTime = localStorage.getItem('lastModalShownTime'); 
        const currentTime = new Date().getTime(); 

        if (!lastShownTime || (currentTime - lastShownTime) > 4 * 60 * 60 * 1000) { 
            if (!hasModalShown) {  
                const modal = new bootstrap.Modal(document.getElementById('keyHelpModal'));
                modal.show();
                hasModalShown = true;

                localStorage.setItem('lastModalShownTime', currentTime);
            }
        }
    });

    loadDefaultPlaylist();
    startHourlyAlert();
    restorePlayerState(); 
</script>

<div class="modal fade" id="urlModal" tabindex="-1" aria-labelledby="urlModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="urlModalLabel">更新播放列表链接</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form method="POST">
                    <div class="mb-3">
                        <label for="new_url" class="form-label">自定义播放列表链接（Ctrl + Shift + C键 清空数据，必须使用下载链接才能正常播放）</label>
                        <input type="text" id="new_url" name="new_url" class="form-control" value="<?php echo htmlspecialchars($new_url); ?>" required>
                    </div>
                    <button type="submit" class="btn btn-primary">更新链接</button>
                    <button type="button" id="resetButton" class="btn btn-secondary ms-2">恢复默认链接</button>
                </form>
            </div>
        </div>
    </div>
</div>

<script>
    document.addEventListener('keydown', function(event) {
        if (event.ctrlKey && event.shiftKey && event.key === 'V') {
            var urlModal = new bootstrap.Modal(document.getElementById('urlModal'));
            urlModal.show();
        }
    });

    document.getElementById('resetButton').addEventListener('click', function() {
        fetch('', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
        body: 'reset_default=true'
    })
        .then(response => response.text())  
        .then(data => {
            var urlModal = bootstrap.Modal.getInstance(document.getElementById('urlModal'));
            urlModal.hide();

            document.getElementById('new_url').value = '<?php echo $default_url; ?>';

            showNotification('恢复默认链接成功！');
        })
        .catch(error => {
            console.error('恢复默认链接时出错:', error);
            showNotification('恢复默认链接时出错');
        });
    });

    function showNotification(message) {
        var notification = document.createElement('div');
        notification.style.position = 'fixed';
        notification.style.top = '10px';
        notification.style.right = '30px';
        notification.style.backgroundColor = '#4CAF50';
        notification.style.color = '#fff';
        notification.style.padding = '10px';
        notification.style.borderRadius = '5px';
        notification.style.zIndex = '9999';
        notification.innerText = message;

        document.body.appendChild(notification);

        setTimeout(function() {
            notification.style.display = 'none';
        }, 5000); 
    }
</script>

<div class="modal fade" id="keyHelpModal" tabindex="-1" aria-labelledby="keyHelpModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="keyHelpModalLabel">键盘操作说明</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <ul>
                    <li><strong>鼠标左键:</strong> 双击打开播放器界面</li>
                    <li><strong>F9键:</strong> 切换播放/暂停</li>
                    <li><strong>上下箭头键:</strong> 切换上一首/下一首</li>
                    <li><strong>左右箭头键:</strong> 快进/快退 10 秒</li>
                    <li><strong>ESC键:</strong> 返回播放列表的第一首</li>
                    <li><strong>F2键:</strong> 切换循环播放和顺序播放模式</li>
                    <li><strong>F8键:</strong> 开启网站连通性检查</li>
                    <li><strong>F4键:</strong> 开启天气信息播报</li>
                    <li><strong>Ctrl + F6键:</strong> 启动/停止雪花动画 </li>
                    <li><strong>Ctrl + F7键:</strong> 启动/停止方块灯光动画 </li>
                    <li><strong>Ctrl + F10键:</strong> 启动/停止方块动画 </li>
                    <li><strong>Ctrl + F11键:</strong> 启动/停止光点动画 </li>
                    <li><strong>Ctrl + Shift + C键:</strong> 清空缓存数据</li>
                    <li><strong>Ctrl + Shift + V键:</strong> 定制播放列表</li>
                    <li><strong>Ctrl + Shift + X键:</strong> 设置城市</li>
                </ul>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="cityModal" tabindex="-1" aria-labelledby="cityModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="cityModalLabel">设置城市</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <label for="city-input">请输入城市名称：</label>
                <input type="text" id="city-input" class="form-control" placeholder="请输入城市名称">
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-primary" id="saveCityBtn">保存城市</button>
            </div>
        </div>
    </div>
</div>

<script>
    const websites = [
        'https://www.baidu.com/', 
        'https://www.cloudflare.com/', 
        'https://openai.com/',
        'https://www.youtube.com/',
        'https://www.google.com/',
        'https://www.facebook.com/',
        'https://www.twitter.com/',
        'https://www.github.com/'
    ];

    function speakMessage(message) {
        const utterance = new SpeechSynthesisUtterance(message);
        utterance.lang = 'zh-CN';  
        speechSynthesis.speak(utterance);
    }

    function getWebsiteStatusMessage(url, status) {
        const statusMessages = {
            'https://www.baidu.com/': status ? 'Baidu 网站访问正常。' : '无法访问 Baidu 网站，请检查网络连接。',
            'https://www.cloudflare.com/': status ? 'Cloudflare 网站访问正常。' : '无法访问 Cloudflare 网站，请检查网络连接。',
            'https://openai.com/': status ? 'OpenAI 网站访问正常。' : '无法访问 OpenAI 网站，请检查网络连接。',
            'https://www.youtube.com/': status ? 'YouTube 网站访问正常。' : '无法访问 YouTube 网站，请检查网络连接。',
            'https://www.google.com/': status ? 'Google 网站访问正常。' : '无法访问 Google 网站，请检查网络连接。',
            'https://www.facebook.com/': status ? 'Facebook 网站访问正常。' : '无法访问 Facebook 网站，请检查网络连接。',
            'https://www.twitter.com/': status ? 'Twitter 网站访问正常。' : '无法访问 Twitter 网站，请检查网络连接。',
            'https://www.github.com/': status ? 'GitHub 网站访问正常。' : '无法访问 GitHub 网站，请检查网络连接。',
        };

        return statusMessages[url] || (status ? `${url} 网站访问正常。` : `无法访问 ${url} 网站，请检查网络连接。`);
    }

    function checkWebsiteAccess(urls) {
        const statusMessages = [];
        let requestsCompleted = 0;

        urls.forEach(url => {
            fetch(url, { mode: 'no-cors' })
                .then(response => {
                    const isAccessible = response.type === 'opaque';  
                    statusMessages.push(getWebsiteStatusMessage(url, isAccessible));
                })
                .catch(() => {
                    statusMessages.push(getWebsiteStatusMessage(url, false));
                })
                .finally(() => {
                    requestsCompleted++;
                    if (requestsCompleted === urls.length) {
                        speakMessage(statusMessages.join(' '));  
                        speakMessage('网站检查已完毕'); 
                    }
                });
        });
    }

    setInterval(() => {
        speakMessage('开始检测网站连通性...');
        checkWebsiteAccess(websites);  
    }, 3600000);  

    let isDetectionStarted = false;

    document.addEventListener('keydown', function(event) {
        if (event.key === 'F8' && !isDetectionStarted) {  
            event.preventDefault();  
            speakMessage('开始检测网站连通性...');
            checkWebsiteAccess(websites);
            isDetectionStarted = true;
        }
    });

</script>

<script>
let city = 'Beijing';
const apiKey = 'fc8bd2637768c286c6f1ed5f1915eb22';
let systemEnabled = true;
let weatherEnabled = true;

function speakMessage(message) {
    const utterance = new SpeechSynthesisUtterance(message);
    utterance.lang = 'zh-CN';
    speechSynthesis.speak(utterance);
}

function speakWeather(weather) {
    if (!weatherEnabled || !systemEnabled) return;

    const descriptions = {
        "clear sky": "晴天", "few clouds": "少量云", "scattered clouds": "多云",
        "broken clouds": "多云", "shower rain": "阵雨", "rain": "雨", 
        "light rain": "小雨", "moderate rain": "中雨", "heavy rain": "大雨",
        "very heavy rain": "暴雨", "extreme rain": "极端降雨", "snow": "雪",
        "light snow": "小雪", "moderate snow": "中雪", "heavy snow": "大雪",
        "very heavy snow": "特大暴雪", "extreme snow": "极端降雪",
        "sleet": "雨夹雪", "freezing rain": "冻雨", "mist": "薄雾",
        "fog": "雾", "haze": "霾", "sand": "沙尘", "dust": "扬尘", "squall": "阵风",
        "tornado": "龙卷风", "ash": "火山灰", "drizzle": "毛毛雨",
        "overcast": "阴天", "partly cloudy": "局部多云", "cloudy": "多云",
        "tropical storm": "热带风暴", "hurricane": "飓风", "cold": "寒冷", 
        "hot": "炎热", "windy": "大风", "breezy": "微风", "blizzard": "暴风雪"
    };

    const weatherDescription = descriptions[weather.weather[0].description.toLowerCase()] || weather.weather[0].description;
    const temperature = weather.main.temp;
    const tempMax = weather.main.temp_max;
    const tempMin = weather.main.temp_min;
    const humidity = weather.main.humidity;
    const windSpeed = weather.wind.speed;
    const visibility = weather.visibility / 1000;

    let message = `以下是今天${city}的天气预报：当前气温为${temperature}摄氏度，${weatherDescription}。` +
                  `预计今天的最高气温为${tempMax}摄氏度，今晚的最低气温为${tempMin}摄氏度。` +
                  `西南风速为每小时${windSpeed}米。湿度为${humidity}%。` +
                  `能见度为${visibility}公里。`;

    if (temperature >= 25) {
        message += `紫外线指数较高，如果外出，请记得涂防晒霜。`;
    } else if (temperature >= 16 && temperature < 25) {
        message += `紫外线指数适中，如果外出，建议涂防晒霜。`;
    } else if (temperature >= 5 && temperature < 16) {
        message += `当前天气较冷，外出时请注意保暖。`;
    } else {
        message += `当前天气非常寒冷，外出时请注意防寒保暖。`;
    }

    if (weatherDescription.includes('雨') || weatherDescription.includes('阵雨') || weatherDescription.includes('雷暴')) {
        message += `建议您外出时携带雨伞。`;
    }

    message += `请注意安全，保持好心情，祝您有美好的一天！`;

    speakMessage(message);
    }

    function fetchWeather() {
        if (!weatherEnabled || !systemEnabled) return;
        
        const apiUrl = `https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${apiKey}&units=metric&lang=zh_cn`; 
        fetch(apiUrl)
            .then(response => response.ok ? response.json() : Promise.reject('网络响应不正常'))
            .then(data => {
                if (data.weather && data.main) {
                    speakWeather(data);
                } else {
                    console.error('无法获取天气数据');
                }
            })
            .catch(error => console.error('获取天气数据时出错:', error));
    }

    function showNotification(message) {
        var notification = document.createElement('div');
        notification.style.position = 'fixed';
        notification.style.top = '10px';
        notification.style.left = '10px';
        notification.style.backgroundColor = '#4CAF50';  
        notification.style.color = '#fff';
        notification.style.padding = '10px';
        notification.style.borderRadius = '5px';
        notification.style.zIndex = '9999';
        notification.innerText = message;

        document.body.appendChild(notification);

        setTimeout(function() {
            notification.style.display = 'none';
        }, 6000); 
    }

    function saveCity() {
        const cityInput = document.getElementById('city-input').value.trim();
        const chineseCharPattern = /[\u4e00-\u9fff]/;
        const startsWithUppercasePattern = /^[A-Z]/;
        if (chineseCharPattern.test(cityInput)) {
            speakMessage('请输入非中文的城市名称。');
        } else if (!startsWithUppercasePattern.test(cityInput)) {
            speakMessage('城市名称必须以大写英文字母开头。');
        } else if (cityInput) {
            city = cityInput;
            localStorage.setItem('city', city); 
            showNotification(`城市已保存为：${city}`);
            speakMessage(`城市已保存为${city}，正在获取最新天气信息...`);
            fetchWeather();
            const cityModal = bootstrap.Modal.getInstance(document.getElementById('cityModal'));
            cityModal.hide();
        } else {
            speakMessage('请输入有效的城市名称。');
        }
    }

    window.onload = function() {
        const storedCity = localStorage.getItem('city');
        if (storedCity) {
            city = storedCity;
            document.getElementById('current-city').style.display = 'block';
            document.getElementById('city-name').textContent = city
        }
    };

    document.addEventListener('keydown', function(event) {
        if (event.ctrlKey && event.shiftKey && event.key === 'X') {
            const cityModal = new bootstrap.Modal(document.getElementById('cityModal'));
            cityModal.show();
        }

        if (event.key === 'F4') {
            fetchWeather();
        }
    });

    document.getElementById('saveCityBtn').addEventListener('click', saveCity);

</script>

<style>
    .animated-box {
        width: 50px;
        height: 50px;
        margin: 10px;
        background: linear-gradient(45deg, #ff6b6b, #ffd93d);
        border-radius: 10px;
        position: absolute;
        animation: complex-animation 5s infinite alternate ease-in-out;
        box-shadow: 0 10px 20px rgba(0, 0, 0, 0.3);
    }

    @keyframes complex-animation {
        0% {
            transform: rotate(0deg) scale(1);
            background: linear-gradient(45deg, #ff6b6b, #ffd93d);
        }
        25% {
            transform: rotate(45deg) scale(1.2);
            background: linear-gradient(135deg, #42a5f5, #66bb6a);
        }
        50% {
            transform: rotate(90deg) scale(0.8);
            background: linear-gradient(225deg, #ab47bc, #ff7043);
        }
        75% {
            transform: rotate(135deg) scale(1.5);
            background: linear-gradient(315deg, #29b6f6, #8e24aa);
        }
        100% {
            transform: rotate(180deg) scale(1);
            background: linear-gradient(45deg, #ff6b6b, #ffd93d);
        }
    }
</style>

<script>
    (function() {
        let isAnimationActive = localStorage.getItem('animationActive') === 'true';
        let intervalId;

        function createAnimatedBox() {
            const box = document.createElement('div');
            box.className = 'animated-box';
            document.body.appendChild(box);
            const randomX = Math.random() * window.innerWidth;
            const randomY = Math.random() * window.innerHeight;
            box.style.left = randomX + 'px';
            box.style.top = randomY + 'px';
            const randomDuration = Math.random() * 3 + 3;
            box.style.animationDuration = randomDuration + 's';
            setTimeout(() => {
                box.remove();
            }, randomDuration * 1000);
        }

        function startAnimation() {
            intervalId = setInterval(() => {
                createAnimatedBox();
            }, 1000);
            localStorage.setItem('animationActive', 'true');
        }

        function stopAnimation() {
            clearInterval(intervalId);
            localStorage.setItem('animationActive', 'false');
        }

        function showNotification(message) {
            var notification = document.createElement('div');
            notification.style.position = 'fixed';
            notification.style.top = '10px';
            notification.style.right = '30px';
            notification.style.backgroundColor = '#4CAF50';
            notification.style.color = '#fff';
            notification.style.padding = '10px';
            notification.style.borderRadius = '5px';
            notification.style.zIndex = '9999';
            notification.innerText = message;
            document.body.appendChild(notification);

            setTimeout(function() {
                notification.style.display = 'none';
            }, 5000);
        }

        window.addEventListener('keydown', function(event) {
            if (event.ctrlKey && event.key === 'F10') {
                isAnimationActive = !isAnimationActive;
                if (isAnimationActive) {
                    startAnimation();
                    showNotification('动画已启动');
                } else {
                    stopAnimation();
                    showNotification('动画已停止');
                }
            }
        });

        if (isAnimationActive) {
            startAnimation();
        }
    })();
</script>

<style>
    .snowflake {
        position: absolute;
        top: -10px;
        width: 10px;
        height: 10px;
        background-color: white;
        border-radius: 50%;
        animation: fall linear infinite;
    }

    @keyframes fall {
        0% {
            transform: translateY(0) rotate(0deg); 
        }
        100% {
            transform: translateY(100vh) rotate(360deg); 
        }
    }

    .snowflake:nth-child(1) {
        animation-duration: 8s;
        animation-delay: -2s;
        left: 10%;
        width: 12px;
        height: 12px;
    }

    .snowflake:nth-child(2) {
        animation-duration: 10s;
        animation-delay: -3s;
        left: 20%;
        width: 8px;
        height: 8px;
    }

    .snowflake:nth-child(3) {
        animation-duration: 12s;
        animation-delay: -1s;
        left: 30%;
        width: 15px;
        height: 15px;
    }

    .snowflake:nth-child(4) {
        animation-duration: 9s;
        animation-delay: -5s;
        left: 40%;
        width: 10px;
        height: 10px;
    }

    .snowflake:nth-child(5) {
        animation-duration: 11s;
        animation-delay: -4s;
        left: 50%;
        width: 14px;
        height: 14px;
    }

    .snowflake:nth-child(6) {
        animation-duration: 7s;
        animation-delay: -6s;
        left: 60%;
        width: 9px;
        height: 9px;
    }

    .snowflake:nth-child(7) {
        animation-duration: 8s;
        animation-delay: -7s;
        left: 70%;
        width: 11px;
        height: 11px;
    }

    .snowflake:nth-child(8) {
        animation-duration: 10s;
        animation-delay: -8s;
        left: 80%;
        width: 13px;
        height: 13px;
    }

    .snowflake:nth-child(9) {
        animation-duration: 6s;
        animation-delay: -9s;
        left: 90%;
        width: 10px;
        height: 10px;
    }
</style>

<script>
    function createSnowflakes() {
        for (let i = 0; i < 80; i++) {
            let snowflake = document.createElement('div');
            snowflake.classList.add('snowflake');
                
            let size = Math.random() * 10 + 5 + 'px';  
            snowflake.style.width = size;
            snowflake.style.height = size;
                
            let speed = Math.random() * 3 + 2 + 's'; 
            snowflake.style.animationDuration = speed;

            let rotate = Math.random() * 360 + 'deg'; 
            let rotateSpeed = Math.random() * 5 + 2 + 's'; 
            snowflake.style.animationName = 'fall';
            snowflake.style.animationDuration = speed;
            snowflake.style.animationTimingFunction = 'linear';
            snowflake.style.animationIterationCount = 'infinite';

            let leftPosition = Math.random() * 100 + 'vw';  
            snowflake.style.left = leftPosition;

            snowflake.style.animationDelay = Math.random() * 5 + 's';  

            document.body.appendChild(snowflake);
        }
    }

    function stopSnowflakes() {
        let snowflakes = document.querySelectorAll('.snowflake');
        snowflakes.forEach(snowflake => snowflake.remove());
    }

    function showNotification(message) {
        var notification = document.createElement('div');
        notification.style.position = 'fixed';
        notification.style.top = '10px';
        notification.style.right = '30px';
        notification.style.backgroundColor = '#4CAF50';
        notification.style.color = '#fff';
        notification.style.padding = '10px';
        notification.style.borderRadius = '5px';
        notification.style.zIndex = '9999';
        notification.innerText = message;
        document.body.appendChild(notification);
        setTimeout(function() {
            notification.style.display = 'none';
        }, 5000);
    }

    function getSnowingState() {
        return localStorage.getItem('isSnowing') === 'true';
    }

    function saveSnowingState(state) {
        localStorage.setItem('isSnowing', state);
    }

    let isSnowing = getSnowingState();

    if (isSnowing) {
        createSnowflakes();  
    }

    window.addEventListener('keydown', function(event) {
        if (event.ctrlKey && event.key === 'F6') {
            isSnowing = !isSnowing;
            saveSnowingState(isSnowing);
            if (isSnowing) {
                createSnowflakes(); 
                showNotification('雪花动画已启动');
            } else {
                stopSnowflakes(); 
                showNotification('雪花动画已停止');
            }
        }
    });
</script>

<style>
.floating-light {
    position: fixed;
    bottom: 0;
    left: 50%;
    width: 50px;
    height: 50px;
    border-radius: 10px;
    box-shadow: 0 0 10px rgba(255, 87, 51, 0.7), 0 0 20px rgba(255, 87, 51, 0.5);
    transform: translateX(-50%);
    animation: float-random 5s ease-in-out infinite;
}

.floating-light.color-1 {
    background-color: #ff5733; 
}

.floating-light.color-2 {
    background-color: #33ff57; 
}

.floating-light.color-3 {
    background-color: #5733ff; 
}

.floating-light.color-4 {
    background-color: #f5f533; 
}

.floating-light.color-5 {
    background-color: #ff33f5; 
}

@keyframes float-random {
    0% {
        transform: translateX(var(--start-x)) translateY(var(--start-y)) rotate(var(--start-rotation));
    }
    100% {
        transform: translateX(var(--end-x)) translateY(var(--end-y)) rotate(var(--end-rotation));
    }
}
</style>
<script>
(function() {
    let isLightAnimationActive = localStorage.getItem('lightAnimationStatus') === 'true'; 
    let intervalId;
    const colors = ['color-1', 'color-2', 'color-3', 'color-4', 'color-5']; 

    if (isLightAnimationActive) {
        startLightAnimation(false);  
    }

    function createLightBox() {
        const lightBox = document.createElement('div');
        const randomColor = colors[Math.floor(Math.random() * colors.length)]; 
        lightBox.classList.add('floating-light', randomColor);
        
        const startX = Math.random() * 100 - 50 + 'vw';  
        const startY = Math.random() * 100 - 50 + 'vh';  
        const endX = Math.random() * 100 - 50 + 'vw';  
        const endY = Math.random() * 100 - 50 + 'vh';  
        const rotation = Math.random() * 360 + 'deg';   

        lightBox.style.setProperty('--start-x', startX);
        lightBox.style.setProperty('--start-y', startY);
        lightBox.style.setProperty('--end-x', endX);
        lightBox.style.setProperty('--end-y', endY);
        lightBox.style.setProperty('--start-rotation', rotation);
        lightBox.style.setProperty('--end-rotation', Math.random() * 360 + 'deg');
        
        document.body.appendChild(lightBox);

        setTimeout(() => {
            lightBox.remove();
        }, 5000); 
    }

    function startLightAnimation(showLog = true) {
        intervalId = setInterval(createLightBox, 400); 
        localStorage.setItem('lightAnimationStatus', 'true');  
        if (showLog) showNotification('方块灯光动画已启动');
    }

    function stopLightAnimation(showLog = true) {
        clearInterval(intervalId);
        const allLights = document.querySelectorAll('.floating-light');
        allLights.forEach(light => light.remove()); 
        localStorage.setItem('lightAnimationStatus', 'false');  
        if (showLog) showNotification('方块灯光动画已停止');
    }

    function showNotification(message) {
        var notification = document.createElement('div');
        notification.style.position = 'fixed';
        notification.style.top = '10px';
        notification.style.right = '30px';
        notification.style.backgroundColor = '#4CAF50';
        notification.style.color = '#fff';
        notification.style.padding = '10px';
        notification.style.borderRadius = '5px';
        notification.style.zIndex = '9999';
        notification.innerText = message;
        document.body.appendChild(notification);

        setTimeout(function() {
            notification.style.display = 'none';
        }, 5000);
    }

    window.addEventListener('keydown', function(event) {
        if (event.ctrlKey && event.key === 'F7') {
            isLightAnimationActive = !isLightAnimationActive;
            if (isLightAnimationActive) {
                startLightAnimation(); 
            } else {
                stopLightAnimation();   
            }
        }
    });
})();
</script>

<style>
@keyframes lightPulse {
    0% {
        transform: scale(0.5);
        opacity: 1;
    }
    50% {
        transform: scale(1.5);
        opacity: 0.7;
    }
    100% {
        transform: scale(3);
        opacity: 0;
    }
}

.light-point {
    position: fixed;
    width: 10px;
    height: 10px;
    background: radial-gradient(circle, rgba(255, 255, 255, 1), rgba(255, 255, 255, 0.2));
    border-radius: 50%;
    pointer-events: none;
    z-index: 9999;
    animation: lightPulse 3s linear infinite;
}
</style>

<script>
(function () {
    let isLightEffectActive = localStorage.getItem('lightEffectAnimation') === 'true';
    let lightInterval;

    function createLightPoint() {
        const lightPoint = document.createElement('div');
        lightPoint.className = 'light-point';

        const posX = Math.random() * window.innerWidth;
        const posY = Math.random() * window.innerHeight;

        lightPoint.style.left = `${posX}px`;
        lightPoint.style.top = `${posY}px`;

        const colors = ['#ffcc00', '#00ccff', '#ff6699', '#99ff66', '#cc99ff'];
        const randomColor = colors[Math.floor(Math.random() * colors.length)];
        lightPoint.style.background = `radial-gradient(circle, ${randomColor}, rgba(255, 255, 255, 0.1))`;

        document.body.appendChild(lightPoint);
        setTimeout(() => {
            lightPoint.remove();
        }, 3000); 
    }

    function startLightEffect(showLog = true) {
        if (lightInterval) clearInterval(lightInterval);
        lightInterval = setInterval(createLightPoint, 200); 
        localStorage.setItem('lightEffectAnimation', 'true');
        if (showLog) showNotification('光点动画已开启');
    }

    function stopLightEffect(showLog = true) {
        clearInterval(lightInterval);
        document.querySelectorAll('.light-point').forEach((light) => light.remove());
        localStorage.setItem('lightEffectAnimation', 'false');
        if (showLog) showNotification('光点动画已关闭');
    }

    function showNotification(message) {
        const notification = document.createElement('div');
        notification.style.position = 'fixed';
        notification.style.top = '10px';
        notification.style.right = '10px';
        notification.style.padding = '10px';
        notification.style.backgroundColor = '#4CAF50';
        notification.style.color = '#fff';
        notification.style.borderRadius = '5px';
        notification.style.zIndex = 9999;
        notification.textContent = message;

        document.body.appendChild(notification);
        setTimeout(() => {
            notification.remove();
        }, 3000);
    }

    window.addEventListener('keydown', function (event) {
        if (event.ctrlKey && event.key === 'F11') {
            isLightEffectActive = !isLightEffectActive;
            if (isLightEffectActive) {
                startLightEffect();
            } else {
                stopLightEffect();
            }
        }
    });

    if (isLightEffectActive) {
        startLightEffect(false);
    }
})();
</script>

