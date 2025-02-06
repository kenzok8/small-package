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

    svg.feather {
        width: 20px !important;
        height: 20px !important;
        vertical-align: middle !important;
        margin-right: 5px !important;
        stroke: #FF00FF !important; 
        fill: none !important;
    }

    #dropArea {
        border: 2px dashed #007bff;
        padding: 20px;
        border-radius: 10px;
        text-align: center;

    }

    #dropArea.dragging {
        background-color: #e9ecef;
    }

    #dropArea p {
        color: #ff69b4; 
    }

    #uploadIcon {
        font-size: 50px;
        color: #007bff;
        cursor: pointer;
        margin-bottom: 20px;
        transition: color 0.3s;
    }

    #uploadIcon:hover {
        color: #0056b3; 
    }

    #submitBtnModal {
        display: none;
        padding: 10px 20px;
        font-size: 16px;
        border: none;
        background-color: #28a745;
        color: white;
        border-radius: 5px;
        cursor: pointer;
        transition: background-color 0.3s;
    }

    #submitBtnModal:hover {
        background-color: #218838;
    }

    .popup {
        display: none; 
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: rgba(255, 255, 255, 0.8);
        backdrop-filter: blur(10px);
        color: #333;
        padding: 20px;
        border-radius: 12px;
        z-index: 1000;
        text-align: center;
        box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
        width: 620px;
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 10px;
    }

    .popup h3 {
        grid-column: span 3;
        text-align: center;
        margin-bottom: 10px;
    }

    .popup button {
        padding: 12px;
        font-size: 14px;
        cursor: pointer;
        border: none;
        border-radius: 8px;
        background-color: rgba(0, 0, 0, 0.1);
        color: #333;
        transition: background 0.3s, transform 0.2s;
    }

    .popup button:hover {
        background: rgba(0, 0, 0, 0.2);
        transform: scale(1.05);
    }

    .popup button:active {
        transform: scale(0.95);
    }

    .popup button:last-child {
        grid-column: span 3;
        justify-self: center;
        width: 80%;
        background: rgba(255, 0, 0, 0.2);
        color: red;
    }

    .popup button:last-child:hover {
        background: rgba(255, 0, 0, 0.4);
    }

    label[for="newPath"], label[for="permissions"], .form-text {
        color: white !important;
    }

    .container-bg {
      border-radius: 12px;
      box-shadow: var(--bs-shadow-medium);
      padding: 2rem;
      margin-top: 2rem;
      margin-bottom: 2rem;
    }

@media (max-width: 768px) {
    .d-flex.justify-content-between.gap-2 {
        width: 100%;
        display: flex;
        justify-content: space-between; 
        gap: 5px; 
        padding-left: 0.7em; 
    }

    .d-flex.justify-content-between.gap-2 .btn {
        flex: 1; 
        min-width: 0; 
        text-align: center;
    }
}


@media (max-width: 768px) {
    .modal-dialog {
        max-width: 100% !important;
        margin: 30px auto;
    }

    .table thead {
        display: none;
    }

    .table tbody,
    .table tr,
    .table td {
        display: block;
        width: 100%;
    }

    .table tr {
        margin-bottom: 10px;
        border: 1px solid #dee2e6;
        border-radius: 5px;
        padding: 10px;
        background: #f8f9fa;
    }

    .table td::before {
        content: attr(data-label);
        font-weight: bold;
        display: block;
        margin-bottom: 5px;
    }

    .table td img,
    .table td video {
        display: block;
        margin: 0 auto;
    }

    .table td .btn-container {
        display: flex;
        justify-content: space-between;
        gap: 10px;
    }

    .table td .btn {
        flex: 1;
        text-align: center;
        padding: 10px;
        font-size: 14px;
        min-width: 0;
    }


@media (max-width: 768px) {
    .control-toggle {
        display: none;
    }
}
</style>
<script src="./assets/bootstrap/Sortable.min.js"></script>
<link href="./assets/bootstrap/video-js.css" rel="stylesheet" />
<script src="./assets/bootstrap/video.js"></script>
<link rel="stylesheet" href="./assets/bootstrap/all.min.css">
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
                <span class="control-toggle" style="cursor: pointer; margin-left: 10px; display: inline-flex; align-items: center; position: relative; top: -1px;"" onclick="togglePopup()" title="打开控制面板">
                    <i class="bi bi-gear" style="font-size: 0.8rem; margin-right: 5px;"></i>  
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
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
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
    background-color: #fff;;
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
    document.addEventListener("DOMContentLoaded", function () {
        var video = document.getElementById('background-video');
        var popup = document.getElementById('popup');
        var controlPanel = document.getElementById('controlPanel');

        popup.style.display = "none";
        controlPanel.style.display = "none";
    
        var savedMuteState = localStorage.getItem("videoMuted");
        if (savedMuteState !== null) {
            video.muted = savedMuteState === "true";
        }

        var savedObjectFit = localStorage.getItem("videoObjectFit");
        if (savedObjectFit) {
            video.style.objectFit = savedObjectFit;
        } else {
            video.style.objectFit = "cover"; 
        }

        updateButtonStates();

        var savedVolume = localStorage.getItem("videoVolume");
        if (savedVolume !== null) {
            video.volume = parseFloat(savedVolume);
            document.getElementById('volumeControl').value = savedVolume;
        }

        document.getElementById('volumeControl').addEventListener('input', function () {
            video.volume = this.value;
            localStorage.setItem("videoVolume", this.value);
        });

        var savedCurrentTime = localStorage.getItem("videoCurrentTime");
        if (savedCurrentTime !== null) {
            video.currentTime = parseFloat(savedCurrentTime);
        }

        var progressControl = document.getElementById('progressControl');
        progressControl.addEventListener('input', function () {
            var duration = video.duration;
            if (!isNaN(duration)) {
                video.currentTime = (progressControl.value / 100) * duration;
                localStorage.setItem("videoCurrentTime", video.currentTime);
            }
        });

        video.addEventListener('timeupdate', function () {
            var duration = video.duration;
            var currentTime = video.currentTime;
            if (!isNaN(duration)) {
                progressControl.value = (currentTime / duration) * 100;
                document.getElementById('progressTimeDisplay').textContent = formatTime(currentTime) + ' / ' + formatTime(duration);
                localStorage.setItem("videoCurrentTime", currentTime);
            }
        });

        var savedPlayState = localStorage.getItem("videoPaused");
        if (savedPlayState === "true") {
            video.pause();
            document.getElementById('playPauseBtn').textContent = '▶️ 播放';
        } else {
            video.play();
            document.getElementById('playPauseBtn').textContent = '⏸️ 暂停';
        }

        function formatTime(seconds) {
            var minutes = Math.floor(seconds / 60);
            var seconds = Math.floor(seconds % 60);
            return (minutes < 10 ? '0' : '') + minutes + ':' + (seconds < 10 ? '0' : '') + seconds;
        }
    });

    document.addEventListener("DOMContentLoaded", function() {
        var video = document.getElementById('background-video');
        var playPauseBtn = document.getElementById('playPauseBtn');
    
        setInterval(() => {
            localStorage.removeItem('videoCurrentTime');     
            video.muted = false;
            video.volume = 1;
            video.currentTime = 0;
            video.style.objectFit = 'cover';
        
            playPauseBtn.textContent = '▶️ 播放';
        }, 60 * 60 * 1000); 

        document.getElementById('clearSettingsBtn').addEventListener('click', function() {
            localStorage.removeItem('videoMuted');
            localStorage.removeItem('videoVolume');
            localStorage.removeItem('videoCurrentTime');
            localStorage.removeItem('videoObjectFit');
            localStorage.removeItem('videoPaused');
        
            video.muted = false;
            video.volume = 1;
            video.currentTime = 0;
            video.style.objectFit = 'cover';
        
            playPauseBtn.textContent = '▶️ 播放';
        
        });
    });

    var longPressTimer;
    var touchStartTime = 0;

    document.addEventListener('touchstart', function (event) {
        var touch = event.touches[0];
        touchStartTime = new Date().getTime();
    
        if (touch.clientY < window.innerHeight / 2) {
            longPressTimer = setTimeout(function () {
                togglePopup();
            }, 1000); 
        }
    });

    function togglePopup() {
        var popup = document.getElementById('popup');
    
        if (popup.style.display === "none" || popup.style.display === "") {
            popup.style.display = "grid"; 
        } else {
            popup.style.display = "none"; 
        }
    }

    function toggleAudio() {
        var video = document.getElementById('background-video');
        video.muted = !video.muted;
        localStorage.setItem("videoMuted", video.muted);
        updateButtonStates();
    }

    function toggleControlPanel() {
        var controlPanel = document.getElementById('controlPanel');
        if (controlPanel.style.display === "none" || controlPanel.style.display === "") {
            controlPanel.style.display = "block";
        } else {
            controlPanel.style.display = "none";
        }
    }

    function togglePlayPause() {
        var video = document.getElementById('background-video');
        var playPauseBtn = document.getElementById('playPauseBtn');
        if (video.paused) {
            video.play();
            playPauseBtn.textContent = '⏸️ 暂停';
            localStorage.setItem("videoPaused", "false");
        } else {
            video.pause();
            playPauseBtn.textContent = '▶️ 播放';
            localStorage.setItem("videoPaused", "true");
        }
    }

    function toggleFullScreen() {
        if (!document.fullscreenElement) {
            document.documentElement.requestFullscreen();
        } else {
            document.exitFullscreen();
        }
        updateButtonStates();
    }

    function toggleObjectFit() {
        var video = document.getElementById('background-video');
        var objectFitBtn = document.getElementById('object-fit-btn');

        switch (video.style.objectFit) {
            case "contain":
                video.style.objectFit = "cover";
                objectFitBtn.textContent = "🔲 正常显示";
                localStorage.setItem("videoObjectFit", "cover");
                break;
            case "cover":
                video.style.objectFit = "fill";
                objectFitBtn.textContent = "🖼️ 填充";
                localStorage.setItem("videoObjectFit", "fill");
                break;
            case "fill":
                video.style.objectFit = "none";
                objectFitBtn.textContent = "🔲 不缩放";
                localStorage.setItem("videoObjectFit", "none");
                break;
            case "none":
                video.style.objectFit = "scale-down";
                objectFitBtn.textContent = "🖼️ 缩小";
                localStorage.setItem("videoObjectFit", "scale-down");
                break;
            case "scale-down":
                video.style.objectFit = "contain";
                objectFitBtn.textContent = "🖼️ 铺满全屏";
                localStorage.setItem("videoObjectFit", "contain");
                break;
            default:
                video.style.objectFit = "cover"; 
                objectFitBtn.textContent = "🔲 正常显示";
                localStorage.setItem("videoObjectFit", "cover");
                break;
        }
    }

  function updateButtonStates() {
        var video = document.getElementById('background-video');
        var audioBtn = document.getElementById('audio-btn');
        var fullscreenBtn = document.getElementById('fullscreen-btn');

        audioBtn.textContent = video.muted ? "🔇 静音" : "🔊 取消静音";
        fullscreenBtn.textContent = document.fullscreenElement ? "📴 退出全屏" : "⛶ 进入全屏";
    }

    document.addEventListener("keydown", function(event) {
        if (event.ctrlKey && event.shiftKey && event.key === "Q") {
            togglePopup();
        }
    });

    document.addEventListener("fullscreenchange", updateButtonStates);
</script>

<div class="popup" id="popup">
    <h3>🔧 控制面板</h3>
    <button onclick="toggleAudio()" id="audio-btn">🔊 切换音频</button>
    <button onclick="toggleControlPanel()" id="control-btn">🎛️ 音量和进度控制</button>
    <button id="openPlayerButton"  data-bs-toggle="modal" data-bs-target="#audioPlayerModal">🎶 音乐播放器</button>
    <button type='button' onclick='openVideoPlayerModal()'><i class='fas fa-video'></i> 媒体播放器</button>
    <button onclick="toggleObjectFit()" id="object-fit-btn">🔲 切换视频显示模式</button>
    <button onclick="toggleFullScreen()" id="fullscreen-btn">⛶ 切换全屏</button>
    <button id="clear-cache-btn">🗑️ 清除缓存</button>
    <button type="button" data-bs-toggle="modal" data-bs-target="#cityModal">🌆 设置城市</button>
    <button type="button" data-bs-toggle="modal" data-bs-target="#keyHelpModal">⌨️ 键盘快捷键</button>
    <button id="startCheckBtn">🌐 启动网站检测</button>
    <button id="startWeatherBtn">🌦️ 启动天气播报</button>
    <button id="toggleAnimationBtn">🖥️ 启动方块动画</button>
    <button id="toggleSnowBtn">❄️ 启动雪花动画</button>
    <button id="toggleLightAnimationBtn">💡 启动灯光动画</button>
    <button id="toggleLightEffectBtn">✨ 启动光点动画</button>
    <button id="toggleModal"><i class="fas fa-arrows-alt-h"></i> 修改页面宽度</button>
    <button type="button" data-bs-toggle="modal" data-bs-target="#colorModal"><i class="bi-palette"></i> 主题编辑器</button>                   
    <button type="button" data-bs-toggle="modal" data-bs-target="#filesModal"><i class="bi-camera-video"></i> 设置背景</button>
    <button onclick="togglePopup()">❌ 关闭</button>
</div>
<div id="controlPanel">
    <h3>视频控制面板</h3>
    <div>
        <label for="volumeControl">音量控制</label>
        <input type="range" id="volumeControl" min="0" max="1" step="0.01" value="1">
    </div>
    <div>
        <label for="progressControl">播放进度</label>
        <input type="range" id="progressControl" min="0" max="100" step="0.1" value="0">
        <span id="progressTimeDisplay">00:00 / 00:00</span>
    </div>
    <button id="clearSettingsBtn"><i class="fas fa-trash-alt"></i> 清除视频设置</button>
    <button onclick="togglePlayPause()" id="playPauseBtn">⏸️ 暂停</button>
    <button onclick="toggleControlPanel()">❌ 关闭</button>
</div>

<script>
document.addEventListener('keydown', function(event) {
    if (event.ctrlKey && event.shiftKey && event.code === 'KeyC') {
        clearCache();
        event.preventDefault();  
    }
});

document.getElementById('clear-cache-btn').addEventListener('click', function() {
    clearCache();
});

function clearCache() {
    location.reload(true); 

    localStorage.clear();
    sessionStorage.clear();

    sessionStorage.setItem('cacheCleared', 'true');

    showNotification('缓存已清除');
    speakMessage('缓存已清除');
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
        speakMessage('缓存已清除');
        sessionStorage.removeItem('cacheCleared'); 
    }
});
</script>

<style>
#controlPanel {
    width: 80%;
    max-width: 625px;
    display: none;
    position: fixed;
    top: 20%;
    left: 50%;
    transform: translate(-50%, -50%);
    background-color: rgba(255, 255, 255, 0.8);
    backdrop-filter: blur(10px);
    padding: 20px;
    border: 1px solid rgba(255, 255, 255, 0.6);
    border-radius: 10px;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    z-index: 1000;
    overflow: hidden;
}

#controlPanel h3 {
    margin-top: 0;
    font-size: 1.5em;
    color: #333;
    text-align: center;
}

#controlPanel button {
    display: block;
    width: 100%;
    margin: 10px 0;
    padding: 10px;
    font-size: 1em;
    color: #fff;
    background-color: #007bff;
    border: none;
    border-radius: 5px;
    cursor: pointer;
    transition: background-color 0.3s;
}

#controlPanel button:hover {
    background-color: #0056b3;
}

#controlPanel input[type="range"] {
    width: 100%;
    margin: 10px 0;
}

#audioPlayerModal .modal-content {
    background: #222;
    color: #fff;
    border-radius: 12px;
    box-shadow: 0 4px 10px rgba(0, 0, 0, 0.5);
}

#audioPlayerModal .modal-header {

}

#audioPlayerModal .modal-title {
    font-size: 18px;
    font-weight: bold;
}

#audioPlayerModal .close {
    color: #fff;
    opacity: 0.8;
}

#audioPlayerModal .close:hover {
    opacity: 1;
}

.audio-player-container {
    padding: 20px;

}

.audio-player-container button {
    margin: 8px;
    padding: 10px 15px;
    font-size: 16px;
    border: none;
    border-radius: 8px;
    transition: all 0.3s ease-in-out;
    cursor: pointer;
}

.audio-player-container .btn-primary {
    background: #ff5733; 
    color: white;
}

.audio-player-container .btn-primary {
    background: #FF5722 !important; 
    color: white !important;
}

.audio-player-container .btn-primary:hover {
    background: #e64a19 !important; 
}

.audio-player-container .btn-secondary {
    background: #9C27B0 !important; 
    color: white !important;
}

.audio-player-container .btn-secondary:hover {
    background: #8E24AA !important; 
}

.audio-player-container .btn-info {
    background: #00BCD4 !important; 
    color: white !important;
}

.audio-player-container .btn-info:hover {
    background: #0097A7 !important; 
}

.audio-player-container .btn-warning {
    background: #FF9800 !important; 
    color: black !important;
}

.audio-player-container .btn-warning:hover {
    background: #FB8C00 !important; 
}

.audio-player-container .btn-dark {
    background: #8BC34A !important; 
    color: white !important;
}

.audio-player-container .btn-dark:hover {
    background: #7CB342 !important; 
}

#modalLoopButton {
    color: white !important;
    background-color: #f39c12 !important; 
}

#modalLoopButton:hover {
    background-color: #f5b041 !important; 
    color: white !important; 
}

.track-name {
    margin-top: 15px;
    font-size: 16px;
    font-weight: bold;
    color: #1db954;
    text-align: center;
}

#tooltip {
    position: absolute;
    bottom: 20px;
    left: 50%;
    transform: translateX(-50%);
    padding: 10px 15px;
    background: rgba(0, 0, 0, 0.75);
    color: #fff;
    font-size: 14px;
    border-radius: 8px;
    white-space: nowrap;
    text-align: center;
    visibility: hidden;
    opacity: 0;
    transition: opacity 0.3s ease-in-out, visibility 0.3s ease-in-out;
    box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.3);
    z-index: 1050;
}

#tooltip.show {
    visibility: visible;
    opacity: 1;
}

.datetime-container {
    text-align: center;
    margin-bottom: 15px;
    font-size: 16px;
    font-weight: bold;
    color: #ffcc00;
}

#dateDisplay,
#timeDisplay {
    margin: 0 10px;
}

#timeDisplay {
    font-style: italic;
}

#audioElement {
    margin-top: 20px;
    width: 100%;
    max-width: 600px; 
    display: block;
    margin-left: auto;
    margin-right: auto; 
}

@media (max-width: 768px) {
    .audio-player-container {
      flex-direction: column;
      align-items: center;
    }

    .audio-player-container button {
      width: 100%;
      margin: 5px 0;
    }
}

#playlistCollapse {
    max-height: 620px; 
    overflow-y: auto;  
    overflow-x: hidden; 
    background-color: rgba(0, 0, 0, 0.8); 
    backdrop-filter: blur(10px); 
    border-radius: 8px; 
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2); 
    padding: 10px; 
}

#playlistCollapse h3 {
    font-size: 1.25rem;
    font-weight: bold;
    color: #fff; 
    text-align: center;
    margin-bottom: 15px;
}

#trackList .list-group-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 12px 15px; 
    margin-bottom: 8px; 
    background-color: rgba(255, 255, 255, 0.1); 
    border: 1px solid rgba(255, 255, 255, 0.2); 
    border-radius: 5px; 
    transition: background-color 0.3s, transform 0.2s; 
}

#trackList .list-group-item.active {
    background-color: #007bff;
    color: white; 
    font-weight: bold; 
}

#trackList .list-group-item:hover {
    background-color: #0056b3; 
    color: white; 
    transform: scale(1.05); 
}

#playlistCollapse::-webkit-scrollbar {
    width: 8px; 
}

#playlistCollapse::-webkit-scrollbar-thumb {
    background-color: #007bff; 
    border-radius: 4px;
}

#playlistCollapse::-webkit-scrollbar-track {
    background-color: rgba(255, 255, 255, 0.1); 
}

#trackList .list-group-item .track-name {
    flex-grow: 1;
    font-size: 1rem;
    color: #fff; 
    text-overflow: ellipsis; 
    overflow: hidden;
    white-space: nowrap;
}

.icon-button {
    background: none;
    border: none;
    color: inherit;
    position: relative;
    cursor: pointer;
    padding: 5px;
    margin: 5px;
}
.btn-bordered {
    border: 1px solid #ccc; 
    border-radius: 5px;
    padding: 5px 10px;
}
.file-checkbox {
    margin-right: 10px;
    width: 20px;
    height: 20px;
}
.icon-button .tooltip {
    visibility: hidden;
    width: auto;
    background-color: black;
    color: #fff;
    text-align: center;
    border-radius: 5px;
    padding: 5px;
    position: absolute;
    z-index: 1;
    bottom: 125%; 
    left: 50%;
    margin-left: -60px;
    opacity: 0;
    transition: opacity 0.3s;
    white-space: nowrap;
    font-size: 16px; 
}
.icon-button .tooltip::after {
    content: "";
    position: absolute;
    top: 100%; 
    left: 50%;
    margin-left: -5px;
    border-width: 5px;
    border-style: solid;
    border-color: black transparent transparent transparent;
}
.icon-button:hover .tooltip {
    visibility: visible;
    opacity: 1;
    width: auto;
    max-width: 200px; 
    word-wrap: break-word; 
}
</style>

<div class="modal fade" id="audioPlayerModal" tabindex="-1" aria-labelledby="audioPlayerModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
  <div class="modal-dialog modal-xl" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="audioPlayerModalLabel">音乐播放器</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <div class="datetime-container">
          <span id="dateDisplay"></span> 
          <span id="timeDisplay"></span>
        </div>
        <audio id="audioElement" controls>
          <source id="audioSource" type="audio/mp3" src="your-audio-file.mp3">
          您的浏览器不支持 audio 元素。
        </audio>
        <div class="audio-player-container text-center">
          <button id="modalPlayPauseButton" class="btn btn-primary">▶ 播放</button>
          <button id="modalPrevButton" class="btn btn-secondary">⏪ 上一首</button>
          <button id="modalNextButton" class="btn btn-secondary">⏩ 下一首</button>
          <button id="modalRewindButton" class="btn btn-dark">⏪ 快退</button>
          <button id="modalFastForwardButton" class="btn btn-info">⏩ 快进</button>
          <button id="modalLoopButton" class="btn btn-warning">🔁 循环</button>
          <div class="track-name" id="trackName">没有歌曲</div>
        </div>
        <button class="btn btn-outline-primary mt-3" type="button" data-bs-toggle="collapse" data-bs-target="#playlistCollapse">
          📜 显示/隐藏播放列表
        </button>
        <button class="btn btn-outline-primary mt-3 ms-2" type="button" data-bs-toggle="modal" data-bs-target="#urlModal">🔗 定制播放列表</button>
        <button class="btn btn-outline-primary mt-3 ms-2"  id="clearStorageBtn"><i class="fas fa-trash-alt"></i> 清除播放设置</button>
        <div id="playlistCollapse" class="collapse mt-3">
          <h3>歌曲列表</h3>
          <ul id="trackList" class="list-group"></ul>
        </div>
        <div id="tooltip"></div>
      </div>
    </div>
  </div>
</div>

<script>
const audioPlayer = document.getElementById('audioElement');
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
    const decodedMessage = decodeURIComponent(message);
    logBox.textContent = decodedMessage;
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
                speakMessage('加载播放列表失败');
            }
            return response.text();
        })
        .then(data => {
            songs = data.split('\n').filter(url => url.trim() !== '');
            if (songs.length === 0) {
                throw new Error('播放列表中没有有效的歌曲');
            }
            console.log('播放列表已加载:', songs);
            const savedOrder = JSON.parse(localStorage.getItem('songOrder'));
            if (savedOrder) {
                songs = savedOrder;
            }
            updateTrackListUI(); 
            restorePlayerState();
            updateTrackName(); 
        })
        .catch(error => {
            console.error('加载播放列表时出错:', error.message);
        });
}

function updateTrackListUI() {
    const trackListContainer = document.getElementById('trackList');
    trackListContainer.innerHTML = '';

    songs.forEach((song, index) => {
        const trackItem = document.createElement('li');
        trackItem.textContent = `${index + 1}. ${extractSongName(song)}`;
        trackItem.classList.add('list-group-item', 'track-item');
        trackItem.style.cursor = 'pointer';
        trackItem.draggable = true; 

        trackItem.addEventListener('click', () => {
            currentSongIndex = index;
            loadSong(index);
            if (isPlaying) audioPlayer.play();
            updateTrackName();
            highlightCurrentSong();
        });

        trackItem.addEventListener('dragstart', handleDragStart);
        trackItem.addEventListener('dragover', handleDragOver);
        trackItem.addEventListener('drop', handleDrop);


        trackListContainer.appendChild(trackItem);
    });

    highlightCurrentSong(); 
}



function handleDragStart(e) {
    e.dataTransfer.setData('text/plain', e.target.dataset.index);
    e.target.classList.add('dragging');
}

function handleDragOver(e) {
    e.preventDefault();
    const dragging = document.querySelector('.dragging');
    const closest = getClosestElement(e.clientY);
    if (closest) {
        trackListContainer.insertBefore(dragging, closest);
    } else {
        trackListContainer.appendChild(dragging);
    }
}

function handleDrop(e) {
    const draggedIndex = parseInt(e.dataTransfer.getData('text/plain'), 10);
    const targetIndex = Array.from(e.target.parentNode.children).indexOf(e.target);
    if (draggedIndex !== targetIndex) {
        const [draggedSong] = songs.splice(draggedIndex, 1);
        songs.splice(targetIndex, 0, draggedSong);
        saveSongOrder(); 
        updateTrackListUI(); 
    }
    document.querySelector('.dragging').classList.remove('dragging');
}

function getClosestElement(y) {
    const elements = [...document.querySelectorAll('.track-item:not(.dragging)')];
    return elements.reduce((closest, child) => {
        const box = child.getBoundingClientRect();
        const offset = y - box.top - box.height / 2;
        if (offset < 0 && offset > closest.offset) {
            return { offset, element: child };
        } else {
            return closest;
        }
    }, { offset: Number.NEGATIVE_INFINITY }).element;
}

function saveSongOrder() {
    localStorage.setItem('songOrder', JSON.stringify(songs));
}

function extractSongName(url) {
    return decodeURIComponent(url.split('/').pop());
}

function updateTrackName() {
    document.getElementById('trackName').textContent = extractSongName(songs[currentSongIndex]);
}

function highlightCurrentSong() {
    document.querySelectorAll('.track-item').forEach((item, index) => {
        item.classList.toggle('active', index === currentSongIndex);
        if (index === currentSongIndex) {
            item.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    });
}

function loadSong(index) {
    if (index >= 0 && index < songs.length) {
        audioPlayer.src = songs[index];
        audioPlayer.addEventListener('loadedmetadata', () => {
            const savedState = JSON.parse(localStorage.getItem('playerState'));
            if (savedState) {
                audioPlayer.currentTime = savedState.currentTime || 0;
                if (savedState.isPlaying) {
                    audioPlayer.play().catch(error => {
                        console.error('恢复播放失败:', error);
                    });
                }
            }
        }, { once: true });
    }
    highlightCurrentSong(); 
}

const playPauseButton = document.getElementById('modalPlayPauseButton');
playPauseButton.addEventListener('click', function() {
    if (!isPlaying) {
        loadSong(currentSongIndex);
        audioPlayer.play().then(() => {
            isPlaying = true;
            savePlayerState();
            console.log('开始播放');
            speakMessage('开始播放');
            playPauseButton.textContent = '⏸️ 暂停';
            updateTrackName();
        }).catch(error => {
            console.log('播放失败:', error);
        });
    } else {
        audioPlayer.pause();
        isPlaying = false;
        savePlayerState();
        console.log('播放已暂停');
        speakMessage('播放已暂停');
        playPauseButton.textContent = '▶ 播放';
    }
});

document.getElementById('modalPrevButton').addEventListener('click', () => {
    currentSongIndex = (currentSongIndex - 1 + songs.length) % songs.length;
    loadSong(currentSongIndex);
    savePlayerState();
    if (isPlaying) {
        audioPlayer.play();
    }
    updateTrackName();
    highlightCurrentSong(); 
    const songName = extractSongName(songs[currentSongIndex]);
    showLogMessage(`上一首：${songName}`);
});

document.getElementById('modalNextButton').addEventListener('click', () => {
    currentSongIndex = (currentSongIndex + 1) % songs.length;
    loadSong(currentSongIndex);
    savePlayerState();
    if (isPlaying) {
        audioPlayer.play();
    }
    updateTrackName();
    highlightCurrentSong(); 
    const songName = extractSongName(songs[currentSongIndex]);
    showLogMessage(`下一首：${songName}`);
});

function updateTrackName() {
    if (songs.length > 0) {
        const currentSongUrl = songs[currentSongIndex];
        const trackName = extractSongName(currentSongUrl);
        document.getElementById('trackName').textContent = trackName || '未知歌曲';
    } else {
        document.getElementById('trackName').textContent = '没有歌曲';
    }
}

function extractSongName(url) {
    const parts = url.split('/');
    return decodeURIComponent(parts[parts.length - 1]);
}

audioPlayer.addEventListener('ended', () => {
    if (isLooping) {
        loadSong(currentSongIndex);
    } else {
        currentSongIndex = (currentSongIndex + 1) % songs.length;
        loadSong(currentSongIndex);
    }
    savePlayerState();
    if (isPlaying) {
        audioPlayer.play();
    }
    updateTrackName();
    highlightCurrentSong(); 
    const songName = extractSongName(songs[currentSongIndex]);
    showLogMessage(`自动切换到：${songName}`);
});

document.getElementById('modalRewindButton').addEventListener('click', () => {
    audioPlayer.currentTime = Math.max(audioPlayer.currentTime - 10, 0);
    console.log('快退 10 秒');
    savePlayerState();
    showLogMessage('快退 10 秒');
});

document.getElementById('modalFastForwardButton').addEventListener('click', () => {
    audioPlayer.currentTime = Math.min(audioPlayer.currentTime + 10, audioPlayer.duration || Infinity);
    console.log('快进 10 秒');
    savePlayerState();
    showLogMessage('快进 10 秒');
});

const loopButton = document.getElementById('modalLoopButton');
loopButton.addEventListener('click', () => {
    isLooping = !isLooping;
    
    if (isLooping) {
        loopButton.textContent = "🔁 循环";
        console.log('循环播放');
        showLogMessage('循环播放');
        speakMessage('循环播放');
        audioPlayer.loop = true;
    } else {
        loopButton.textContent = "🔄 顺序";
        console.log('顺序播放');
        showLogMessage('顺序播放');
        speakMessage('顺序播放');
        audioPlayer.loop = false;
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

function updateDateTime() {
    const now = new Date();

    const year = now.getFullYear();
    const month = now.getMonth() + 1;
    const day = now.getDate();
    document.getElementById('dateDisplay').textContent = `${year}年${month}月${day}日`;

    const timeString = now.toLocaleTimeString('zh-CN', { hour12: false });

    const hours = now.getHours();
    let ancientTime;
    if (hours >= 23 || hours < 1) ancientTime = '子时';
    else if (hours >= 1 && hours < 3) ancientTime = '丑时';
    else if (hours >= 3 && hours < 5) ancientTime = '寅时';
    else if (hours >= 5 && hours < 7) ancientTime = '卯时';
    else if (hours >= 7 && hours < 9) ancientTime = '辰时';
    else if (hours >= 9 && hours < 11) ancientTime = '巳时';
    else if (hours >= 11 && hours < 13) ancientTime = '午时';
    else if (hours >= 13 && hours < 15) ancientTime = '未时';
    else if (hours >= 15 && hours < 17) ancientTime = '申时';
    else if (hours >= 17 && hours < 19) ancientTime = '酉时';
    else if (hours >= 19 && hours < 21) ancientTime = '戌时';
    else ancientTime = '亥时';

    document.getElementById('timeDisplay').textContent = `${timeString} (${ancientTime})`;
}

setInterval(updateDateTime, 1000);
updateDateTime();

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

setInterval(() => {
    localStorage.removeItem('playerState');
}, 60 * 60 * 1000);

document.getElementById('clearStorageBtn').addEventListener('click', function() {
    localStorage.removeItem('playerState');
    localStorage.removeItem('songOrder'); 
    loadDefaultPlaylist(); 
    document.getElementById('modalPlayPauseButton').textContent = '▶ 播放';
    alert('Player state cleared!');
});

function restorePlayerState() {
    const state = JSON.parse(localStorage.getItem('playerState'));
    if (state) {
        currentSongIndex = state.currentSongIndex || 0;
        isLooping = state.isLooping || false;
        loadSong(currentSongIndex);
        if (state.isPlaying) {
            isPlaying = true;
            playPauseButton.textContent = '暂停';
            audioPlayer.currentTime = state.currentTime || 0;
            audioPlayer.play().catch(error => {
                console.error('恢复播放失败:', error);
            });
            playPauseButton.textContent = '⏸️ 暂停';
        }
    }
}

document.addEventListener('dblclick', function() {
    const lastShownTime = localStorage.getItem('lastModalShownTime');
    const currentTime = new Date().getTime();

    if (!lastShownTime || (currentTime - lastShownTime) > 24 * 60 * 60 * 1000) {
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

$('#audioPlayerModal').on('shown.bs.modal', function () {
    updateTrackName();
});

window.addEventListener('keydown', function(event) {
    if (event.key === 'ArrowUp') {
        currentSongIndex = (currentSongIndex - 1 + songs.length) % songs.length;
        loadSong(currentSongIndex);
        savePlayerState();
        if (isPlaying) {
            audioPlayer.play();
        }
        const songName = getSongName(songs[currentSongIndex]);
        showLogMessage(`上一首：${songName}`);
        speakMessage('上一首');
        updateTrackName();
    } else if (event.key === 'ArrowDown') {
        currentSongIndex = (currentSongIndex + 1) % songs.length;
        loadSong(currentSongIndex);
        savePlayerState();
        if (isPlaying) {
            audioPlayer.play();
        }
        const songName = getSongName(songs[currentSongIndex]);
        showLogMessage(`下一首：${songName}`);
        speakMessage('下一首');
        updateTrackName();
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
        speakMessage('已返回播放列表的第一首');
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
            speakMessage('暂停播放');
            playPauseButton.textContent = '▶ 播放';
        } else {
            audioPlayer.play().then(() => {
                isPlaying = true;
                savePlayerState();
                console.log('开始播放');
                showLogMessage('开始播放');
                speakMessage('开始播放');
                playPauseButton.textContent = '⏸️ 暂停';
            }).catch(error => {
                console.log('播放失败:', error);
            });
        }
    } else if (event.key === 'F2') {
        isLooping = !isLooping;
        const loopButton = document.getElementById('modalLoopButton');
        if (isLooping) {
            loopButton.textContent = "🔁 循环";
            audioPlayer.loop = true;
            console.log('循环播放');
            showLogMessage('循环播放');
            speakMessage('循环播放');
        } else {
            loopButton.textContent = "🔄 顺序";
            audioPlayer.loop = false;
            console.log('顺序播放');
            showLogMessage('顺序播放');
            speakMessage('顺序播放');
        }
    }
});
</script>

<div class="modal fade" id="urlModal" tabindex="-1" aria-labelledby="urlModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="urlModalLabel">更新播放列表</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form method="POST">
                    <div class="mb-3">
                        <label for="new_url" class="form-label">自定义播放列表</label>
                        <input type="text" id="new_url" name="new_url" class="form-control" value="<?php echo htmlspecialchars($new_url); ?>" required>
                    </div>
                    <button type="submit" class="btn btn-primary">保存</button>
                    <button type="button" id="resetButton" class="btn btn-secondary ms-2">恢复默认</button>
                    <button type="button" class="btn btn-secondary ms-2" data-bs-dismiss="modal">取消</button>
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
            speakMessage('打开定制播放列表');
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
    <div class="modal-dialog modal-xl">
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
                    <li><strong>Ctrl + Shift + Q键:</strong> 打开控制面板</li>
                    <li><strong>Ctrl + Shift + C键:</strong> 清空缓存数据</li>
                    <li><strong>Ctrl + Shift + V键:</strong> 定制播放列表</li>
                    <li><strong>Ctrl + Shift + X键:</strong> 设置城市</li>
                    <li><strong>手机/平板长按上半屏:</strong> 打开设置</li>
                </ul>
                <div class="sing-box-section mt-4">
                    <h5>Sing-box启动提示</h5>
                    <ul>
                    <li>如遇启动失败，请前往文件管理 ⇨ 更新数据库 ⇨ 下载 cache.db 缓存数据。</li>
                    <li>启动了无法联网，请前往防火墙设置 ⇨ 出站/入站/转发 ⇨ 接受  ⇨  保存应用</li>
                </ul>
            </div>
                </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="cityModal" tabindex="-1" aria-labelledby="cityModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
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
                        speakMessage('网站检查已完毕，感谢使用。'); 
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
            speakMessage('网站检测已开启，开始检测网站连通性...');
            checkWebsiteAccess(websites);
            isDetectionStarted = true;
        }
    });

    document.getElementById('startCheckBtn').addEventListener('click', function() {
        speakMessage('网站检测已开启，开始检测网站连通性...');
        checkWebsiteAccess(websites);
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
            speakMessage('打开城市设置');
        }

        if (event.key === 'F4') {
            fetchWeather();
            speakMessage('天气播报已开启');
        }
    });

    document.getElementById('startWeatherBtn').addEventListener('click', function() {
        speakMessage('正在获取天气信息...');
        fetchWeather();
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
            isAnimationActive = true;
            updateButtonText();
        }

        function stopAnimation() {
            clearInterval(intervalId);
            localStorage.setItem('animationActive', 'false');
            isAnimationActive = false;
            updateButtonText();
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

        function updateButtonText() {
            document.getElementById('toggleAnimationBtn').innerText = isAnimationActive ? '⏸️ 停止方块动画' : '▶ 启动方块动画';
        }

        window.addEventListener('keydown', function(event) {
            if (event.ctrlKey && event.key === 'F10') {
                isAnimationActive = !isAnimationActive;
                if (isAnimationActive) {
                    startAnimation();
                    showNotification('方块动画已启动');
                    speakMessage('方块动画已启动');
                } else {
                    stopAnimation();
                    showNotification('方块动画已停止');
                    speakMessage('方块动画已停止');
                }
            }
        });

        document.getElementById('toggleAnimationBtn').addEventListener('click', function() {
            if (isAnimationActive) {
                stopAnimation();
                showNotification('⏸️ 方块动画已停止');
                speakMessage('方块动画已停止');
            } else {
                startAnimation();
                showNotification('▶ 方块动画已启动');
                speakMessage('方块动画已启动');
            }
        });

        if (isAnimationActive) {
            startAnimation();
        }
        updateButtonText();
    })();

    function speakMessage(message) {
        const utterance = new SpeechSynthesisUtterance(message);
        utterance.lang = 'zh-CN';
        speechSynthesis.speak(utterance);
    }
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

    function speakMessage(message) {
        const utterance = new SpeechSynthesisUtterance(message);
        utterance.lang = 'zh-CN';
        speechSynthesis.speak(utterance);
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

    function toggleSnowflakes() {
        isSnowing = !isSnowing;
        saveSnowingState(isSnowing);
        if (isSnowing) {
            createSnowflakes();
            showNotification('雪花动画已启动');
            speakMessage('雪花动画已启动');
            document.getElementById('toggleSnowBtn').innerText = '⏸️ 停止雪花动画';
        } else {
            stopSnowflakes();
            showNotification('雪花动画已停止');
            speakMessage('雪花动画已停止');
            document.getElementById('toggleSnowBtn').innerText = '▶ 启动雪花动画';
        }
    }

    window.addEventListener('keydown', function(event) {
        if (event.ctrlKey && event.key === 'F6') {
            toggleSnowflakes();
        }
    });

    document.getElementById('toggleSnowBtn').addEventListener('click', toggleSnowflakes);

    if (isSnowing) {
        document.getElementById('toggleSnowBtn').innerText = '⏸️ 停止雪花动画';
    }

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
        document.getElementById('toggleLightAnimationBtn').innerText = '⏸️ 停止灯光动画';
    }

    function stopLightAnimation(showLog = true) {
        clearInterval(intervalId);
        const allLights = document.querySelectorAll('.floating-light');
        allLights.forEach(light => light.remove()); 
        localStorage.setItem('lightAnimationStatus', 'false');  
        if (showLog) showNotification('方块灯光动画已停止');
        document.getElementById('toggleLightAnimationBtn').innerText = '▶ 启动灯光动画';
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

    function speakMessage(message) {
        const utterance = new SpeechSynthesisUtterance(message);
        utterance.lang = 'zh-CN';
        speechSynthesis.speak(utterance);
    }

    function toggleLightAnimation() {
        isLightAnimationActive = !isLightAnimationActive;
        if (isLightAnimationActive) {
            startLightAnimation();
            speakMessage('方块灯光动画已启动');
        } else {
            stopLightAnimation();
            speakMessage('方块灯光动画已停止');
        }
    }

    window.addEventListener('keydown', function(event) {
        if (event.ctrlKey && event.key === 'F7') {
                toggleLightAnimation();
            }
        });

        document.getElementById('toggleLightAnimationBtn').addEventListener('click', toggleLightAnimation);

        if (isLightAnimationActive) {
            document.getElementById('toggleLightAnimationBtn').innerText = '⏸️ 停止灯光动画';
        }
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
        document.getElementById('toggleLightEffectBtn').innerText = '⏸️ 停止光点动画';
    }

    function stopLightEffect(showLog = true) {
        clearInterval(lightInterval);
        document.querySelectorAll('.light-point').forEach((light) => light.remove());
        localStorage.setItem('lightEffectAnimation', 'false');
        if (showLog) showNotification('光点动画已关闭');
        document.getElementById('toggleLightEffectBtn').innerText = '▶ 启动光点动画';
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

    function speakMessage(message) {
        const utterance = new SpeechSynthesisUtterance(message);
        utterance.lang = 'zh-CN';
        speechSynthesis.speak(utterance);
    }

    function toggleLightEffect() {
        isLightEffectActive = !isLightEffectActive;
        if (isLightEffectActive) {
            startLightEffect();
            speakMessage('光点动画已启动');
        } else {
            stopLightEffect();
            speakMessage('光点动画已关闭');
        }
    }

    window.addEventListener('keydown', function (event) {
        if (event.ctrlKey && event.key === 'F11') {
            toggleLightEffect();
                }
            });

            document.getElementById('toggleLightEffectBtn').addEventListener('click', toggleLightEffect);

            if (isLightEffectActive) {
                document.getElementById('toggleLightEffectBtn').innerText = '⏸️ 停止光点动画';
                startLightEffect(false);
            }
        })();
</script>

<script>
    document.addEventListener("DOMContentLoaded", function() {
        feather.replace();
    });
</script>

<div class="modal fade" id="widthModal" tabindex="-1" aria-labelledby="widthModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
  <div class="modal-dialog modal-xl">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="widthModalLabel">调整容器宽度</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <label for="containerWidth" class="form-label">页面宽度</label>
        <input type="range" class="form-range" name="containerWidth" id="containerWidth" min="800" max="5400" step="50" value="1800" style="width: 100%;">
        <div id="widthValue" class="mt-2" style="color: #FF00FF;">当前宽度: 1800px</div>

        <label for="modalMaxWidth" class="form-label mt-4">弹窗最大宽度</label>
        <input type="range" class="form-range" name="modalMaxWidth" id="modalMaxWidth" min="1400" max="5400" step="50" value="1400" style="width: 100%;">
        <div id="modalWidthValue" class="mt-2" style="color: #00FF00;">当前最大宽度: 1400px</div>

        <div class="form-check mt-3">
            <input class="form-check-input" type="checkbox" id="group1Background">
            <label class="form-check-label" for="group1Background">
                启用透明下拉选择框、表单选择和信息背景
            </label>
        </div>
        <div class="form-check mt-3">
            <input class="form-check-input" type="checkbox" id="bodyBackground">
            <label class="form-check-label" for="bodyBackground">
                启用透明主体背景
            </label>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
      </div>
    </div>
  </div>
</div>
<script>
const slider = document.getElementById("containerWidth");
const widthValue = document.getElementById("widthValue");
const modalSlider = document.getElementById("modalMaxWidth");
const modalWidthValue = document.getElementById("modalWidthValue");

const group1Checkbox = document.getElementById("group1Background");
const bodyBackgroundCheckbox = document.getElementById("bodyBackground");

function updateSliderColor(value, slider, valueElement) {
    let red = Math.min(Math.max((value - 800) / (2400 - 800) * 255, 0), 255);
    let green = 255 - red;
    
    slider.style.background = `linear-gradient(to right, rgb(${red}, ${green}, 255), rgb(${255 - red}, ${green}, ${255 - red}))`;
    slider.style.setProperty('--thumb-color', `rgb(${red}, ${green}, 255)`);
    valueElement.textContent = `当前宽度: ${value}px`;
    valueElement.style.color = `rgb(${red}, ${green}, 255)`;  
}

let savedWidth = localStorage.getItem('containerWidth');
let savedModalWidth = localStorage.getItem('modalMaxWidth');

if (savedWidth) {
    slider.value = savedWidth;
}
if (savedModalWidth) {
    modalSlider.value = savedModalWidth;
}

updateSliderColor(slider.value, slider, widthValue);
updateSliderColor(modalSlider.value, modalSlider, modalWidthValue);

slider.oninput = function() {
    updateSliderColor(slider.value, slider, widthValue);
    localStorage.setItem('containerWidth', slider.value);  

    sendCSSUpdate();
    showNotification(`页面宽度已更新! 当前宽度: ${slider.value}px`);
};

modalSlider.oninput = function() {
    updateSliderColor(modalSlider.value, modalSlider, modalWidthValue);
    localStorage.setItem('modalMaxWidth', modalSlider.value);  

    sendCSSUpdate();
    showNotification(`弹窗宽度已更新! 当前最大宽度: ${modalSlider.value}px`);
};

function sendCSSUpdate() {
    const width = slider.value;
    const modalWidth = modalSlider.value;
    const group1 = group1Checkbox.checked ? 1 : 0;
    const bodyBackground = bodyBackgroundCheckbox.checked ? 1 : 0;

    fetch('update-css.php', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ 
            width: width,
            modalWidth: modalWidth,
            group1: group1,
            bodyBackground: bodyBackground
        })
    }).then(response => response.json())
      .then(data => console.log('CSS 更新成功:', data))
      .catch(error => console.error('Error updating CSS:', error));
}

group1Checkbox.onchange = function() {
    sendCSSUpdate();
    showNotification(group1Checkbox.checked ? "已启用透明下拉选择框、表单选择和信息背景" : "已禁用透明禁用、表单选择和信息背景");
};

bodyBackgroundCheckbox.onchange = function() {
    sendCSSUpdate();
    showNotification(bodyBackgroundCheckbox.checked ? "已启用透明主体背景" : "已禁用透明主体背景");
};

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

const toggleModalButton = document.getElementById("toggleModal");
toggleModalButton.onclick = function() {
    const modal = new bootstrap.Modal(document.getElementById('widthModal'));
    modal.show();
};
</script>

<div class="modal fade" id="colorModal" tabindex="-1" aria-labelledby="colorModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
  <div class="modal-dialog modal-xl">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="colorModalLabel">选择主题颜色</h5>
        <button type="button" class="close" data-bs-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
      </div>
      <div class="modal-body">
        <form method="POST" action="theme.php" id="themeForm" enctype="multipart/form-data">
          <div class="row">
            <div class="col-md-4 mb-3">
              <label for="primaryColor" class="form-label">导航栏文本色</label>
              <input type="color" class="form-control" name="primaryColor" id="primaryColor" value="#0ceda2">
            </div>
            <div class="col-md-4 mb-3">
              <label for="secondaryColor" class="form-label">导航栏悬停文本色</label>
              <input type="color" class="form-control" name="secondaryColor" id="secondaryColor" value="#00ffff">
            </div>
            <div class="col-md-4 mb-3">
              <label for="bodyBgColor" class="form-label">主背景色</label>
              <input type="color" class="form-control" name="bodyBgColor" id="bodyBgColor" value="#23407e">
            </div>
            <div class="col-md-4 mb-3">
              <label for="infoBgSubtle" class="form-label">信息背景色</label>
              <input type="color" class="form-control" name="infoBgSubtle" id="infoBgSubtle" value="#23407e">
            </div>
            <div class="col-md-4 mb-3">
              <label for="backgroundColor" class="form-label">表格背景色</label>
              <input type="color" class="form-control" name="backgroundColor" id="backgroundColor" value="#20cdd9">
            </div>
            <div class="col-md-4 mb-3">
              <label for="primaryBorderSubtle" class="form-label">表格文本色</label>
              <input type="color" class="form-control" name="primaryBorderSubtle" id="primaryBorderSubtle" value="#1815d1">
            </div>
            <div class="col-md-4 mb-3">
              <label for="checkColor" class="form-label">主标题文本色 1</label>
              <input type="color" class="form-control" name="checkColor" id="checkColor" value="#0eaf3e">
            </div>
            <div class="col-md-4 mb-3">
              <label for="labelColor" class="form-label">主标题文本色 2</label>
              <input type="color" class="form-control" name="labelColor" id="labelColor" value="#0eaf3e">
            </div>
            <div class="col-md-4 mb-3">
              <label for="lineColor" class="form-label">行数文本色</label>
              <input type="color" class="form-control" name="lineColor" id="lineColor" value="#f515f9">
            </div>
            <div class="col-md-4 mb-3">
              <label for="controlColor" class="form-label">输入框文本色 1</label>
              <input type="color" class="form-control" name="controlColor" id="controlColor" value="#0eaf3e">
            </div>
            <div class="col-md-4 mb-3">
              <label for="placeholderColor" class="form-label">输入框文本色 2</label>
              <input type="color" class="form-control" name="placeholderColor" id="placeholderColor" value="#f82af2">
            </div>
            <div class="col-md-4 mb-3">
              <label for="disabledColor" class="form-label">显示框背景色</label>
              <input type="color" class="form-control" name="disabledColor" id="disabledColor" value="#23407e">
            </div>
            <div class="col-md-4 mb-3">
              <label for="logTextColor" class="form-label">日志文本色</label>
              <input type="color" class="form-control" name="logTextColor" id="logTextColor" value="#f8f9fa">
            </div>
            <div class="col-md-4 mb-3">
              <label for="selectColor" class="form-label">主边框背景色</label>
              <input type="color" class="form-control" name="selectColor" id="selectColor" value="#23407e">
            </div>
            <div class="col-md-4 mb-3">
              <label for="radiusColor" class="form-label">主边框文本色</label>
              <input type="color" class="form-control" name="radiusColor" id="radiusColor" value="#24f086">
            </div>
            <div class="col-md-4 mb-3">
              <label for="bodyColor" class="form-label">表格文本色 1</label>
              <input type="color" class="form-control" name="bodyColor" id="bodyColor" value="#04f153">
            </div>
            <div class="col-md-4 mb-3">
              <label for="tertiaryColor" class="form-label">表格文本色 2</label>
              <input type="color" class="form-control" name="tertiaryColor" id="tertiaryColor" value="#46e1ec">
            </div>
            <div class="col-md-4 mb-3">
              <label for="tertiaryRgbColor" class="form-label">表格文本色 3</label>
              <input type="color" class="form-control" name="tertiaryRgbColor" id="tertiaryRgbColor" value="#1e90ff">
            </div>
            <div class="col-md-4 mb-3">
              <label for="ipColor" class="form-label">IP 文本色</label>
              <input type="color" class="form-control" name="ipColor" id="ipColor" value="#09B63F">
            </div>
            <div class="col-md-4 mb-3">
              <label for="ipipColor" class="form-label">运营商文本色</label>
              <input type="color" class="form-control" name="ipipColor" id="ipipColor" value="#ff69b4">
            </div>
            <div class="col-md-4 mb-3">
              <label for="detailColor" class="form-label">IP详情文本色</label>
              <input type="color" class="form-control" name="detailColor" id="detailColor" value="#FFFFFF">
            </div>
            <div class="col-md-4 mb-3">
              <label for="outlineColor" class="form-label">按键色（青色）</label>
              <input type="color" class="form-control" name="outlineColor" id="outlineColor" value="#0dcaf0">
            </div>
            <div class="col-md-4 mb-3">
              <label for="successColor" class="form-label">按键色（绿色）</label>
              <input type="color" class="form-control" name="successColor" id="successColor" value="#28a745">
            </div>
            <div class="col-md-4 mb-3">
              <label for="infoColor" class="form-label">按键色（蓝色）</label>
              <input type="color" class="form-control" name="infoColor" id="infoColor" value="#0ca2ed">
            </div>
            <div class="col-md-4 mb-3">
              <label for="warningColor" class="form-label">按键色（黄色）</label>
              <input type="color" class="form-control" name="warningColor" id="warningColor" value="#ffc107">
            </div>
            <div class="col-md-4 mb-3">
              <label for="pinkColor" class="form-label">按键色（粉红色）</label>
              <input type="color" class="form-control" name="pinkColor" id="pinkColor" value="#f82af2">
            </div>
            <div class="col-md-4 mb-3">
              <label for="dangerColor" class="form-label">按键色（红色）</label>
              <input type="color" class="form-control" name="dangerColor" id="dangerColor" value="#dc3545">
            </div>
            <div class="col-md-4 mb-3">
              <label for="heading1Color" class="form-label">标题色 1</label>
              <input type="color" class="form-control" name="heading1Color" id="heading1Color" value="#21e4f2">
            </div>
            <div class="col-md-4 mb-3">
              <label for="heading2Color" class="form-label">标题色 2</label>
              <input type="color" class="form-control" name="heading2Color" id="heading2Color" value="#65f1fb">
            </div>
            <div class="col-md-4 mb-3">
              <label for="heading3Color" class="form-label">标题色 3</label>
              <input type="color" class="form-control" name="heading3Color" id="heading3Color" value="#ffcc00">
            </div>
            <div class="col-md-4 mb-3">
              <label for="heading4Color" class="form-label">标题色 4</label>
              <input type="color" class="form-control" name="heading4Color" id="heading4Color" value="#00fbff">
            </div>
            <div class="col-md-4 mb-3">
              <label for="heading5Color" class="form-label">标题色 5</label>
              <input type="color" class="form-control" name="heading5Color" id="heading5Color" value="#ba13f6">
            </div>
            <div class="col-md-4 mb-3">
              <label for="heading6Color" class="form-label">标题色 6</label>
              <input type="color" class="form-control" name="heading6Color" id="heading6Color" value="#00ffff">
            </div>
          </div>
          <div class="col-12 mb-3">
            <label for="themeName" class="form-label">自定义主题名称</label>
            <input type="text" class="form-control" name="themeName" id="themeName" value="transparent">
          </div>
      <div class="d-flex flex-wrap justify-content-center align-items-center mb-3 gap-2">
          <button type="submit" class="btn btn-primary">保存主题</button>
          <button type="button" class="btn btn-success" id="resetButton" onclick="clearCache()">恢复默认值</button>
          <button type="button" class="btn btn-info" id="exportButton">立即备份</button>
          <button type="button" class="btn btn-warning" id="restoreButton">恢复备份</button> 
          <input type="file" id="importButton" class="form-control" accept="application/json" style="display: none;"> 
          <button type="button" class="btn btn-pink" data-bs-dismiss="modal">取消</button>
      </div>
        </form>
      </div>
    </div>
  </div>
</div>

<style>
input[type="range"] {
    -webkit-appearance: none;
    appearance: none;
    width: 100%;
    height: 10px;
    border-radius: 5px;
    background: linear-gradient(to right, #ff00ff, #00ffff);
    outline: none;
}

input[type="range"]::-webkit-slider-thumb,
input[type="range"]::-moz-range-thumb {
    -webkit-appearance: none;
    appearance: none;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: #ff00ff;
    border: none;
    cursor: pointer;
}

input[type="range"]:focus {
    outline: none;
}

#widthValue {
    color: #ff00ff;
}

.file-preview {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
}

.btn-container {
    display: flex;
    justify-content: center;
    margin-top: 10px;
}

.btn-container .btn {
    margin: 0 5px;
}

.delete-btn {
    color: white !important;
}

#videoPlayerModal .modal-body {
    display: flex;
    gap: 20px;
    height: calc(90vh - 140px);
}

#videoPlayerModal .w-75 {
    flex: 0 0 75%;
    padding-right: 20px;
    height: 100%;
}

#videoPlayerModal #videoPlayer {
    border-radius: 10px;
    width: 100%;
    height: 100%;
    background-color: #000;
}

#videoPlayerModal .w-25 {
    flex: 0 0 25%;
    height: 100%;
    display: flex;
    flex-direction: column;
}

#videoPlayerModal #playlist {
    list-style-type: none;
    padding-left: 0;
    margin: 0;
    overflow-y: auto;
    max-height: 100%;
    background-color: #000;
    border-radius: 10px;
    width: 100%;
}

#videoPlayerModal #playlist li {
    font-size: 1rem;
    padding: 12px 20px;
    border-radius: 8px;
    margin-bottom: 10px;
    background-color: #333;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
    cursor: pointer;
    transition: background-color 0.3s, box-shadow 0.3s;
}

#videoPlayerModal #playlist li:hover {
    background-color: #007bff;
    color: white;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

#videoPlayerModal #playlist li.active {
    background-color: #28a745;
    color: white;
}

@media (max-width: 768px) {
    #videoPlayerModal .modal-dialog {
        max-width: 100%;
        margin: 0;
    }

    #videoPlayerModal .modal-body {
        flex-direction: column;
    }

    #videoPlayerModal .w-75,
    #videoPlayerModal .w-25 {
        width: 100%;
    }

    .set-background-btn {
        font-size: 12px;
        padding: 5px 10px;
        width: 100px;
        height: 42px;
    }
}
</style>

<script>
    document.getElementById('useBackgroundImage').addEventListener('change', function() {
        const container = document.getElementById('backgroundImageContainer');
        container.style.display = this.checked ? 'block' : 'none';
    });
</script>

<script>
    document.getElementById('restoreButton').addEventListener('click', () => {
        document.getElementById('importButton').click();
    });

    document.getElementById('importButton').addEventListener('change', (event) => {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (e) => {
                const content = e.target.result;
                try {
                    const jsonData = JSON.parse(content); 
                    console.log('恢复的备份数据:', jsonData);
                    alert('备份已成功上传并解析！');
                } catch (error) {
                    alert('文件格式错误，请上传正确的 JSON 文件！');
                }
            };
            reader.readAsText(file);
        }
    });
</script>

<script>
    function clearCache() {
        location.reload(true);        
        localStorage.clear();   
        sessionStorage.clear(); 
        sessionStorage.setItem('cacheCleared', 'true'); 
    }

    window.addEventListener('load', function() {
        if (sessionStorage.getItem('cacheCleared') === 'true') {
            sessionStorage.removeItem('cacheCleared'); 
        }
    });
</script>

<div class='modal fade' id='filesModal' tabindex='-1' aria-labelledby='filesModalLabel' aria-hidden='true' data-bs-backdrop='static' data-bs-keyboard='false'>
    <div class='modal-dialog modal-xl'>
        <div class='modal-content'>
            <div class='modal-header'>
                <h5 class='modal-title' id='filesModalLabel'>上传并管理背景图片/视频/音频</h5>
                <button type='button' class='close' data-bs-dismiss='modal' aria-label='Close'>
                    <span aria-hidden='true'>&times;</span>
                </button>
            </div>
            <div class='modal-body'>
                <div class='mb-4 d-flex justify-content-between align-items-center'>
                    <div>
                        <button type="button" class="btn btn-success mr-3" onclick="selectAll()"><i class="fas fa-check-square"></i> 全选</button>
                        <button type="button" class="btn btn-warning mr-3" onclick="deselectAll()"><i class="fas fa-square"></i> 反选</button>
                        <button type="button" class="btn btn-danger" onclick="batchDelete()"><i class="fas fa-trash-alt"></i> 批量删除</button>
                        <span id="selectedCount" class="ms-2" style="display: none;">已选中 0 个文件，总计 0 MB</span>
                    </div>
                    <div>
                        <button type='button' class='btn btn-primary mr-3' onclick='openVideoPlayerModal()' title="勾选添加到播放列表"><i class='fas fa-play'></i> 播放视频</button>
                        <button type="button" class="btn btn-pink mr-3" onclick="sortFiles()"><i class="fas fa-sort"></i> 排序</button>
                        <button type="button" class="btn btn-primary mr-3" data-bs-toggle="modal" data-bs-target="#newuploadModal">
                            <i class="fas fa-cloud-upload-alt"></i> 上传文件
                        </button>
                        <button type="button" class="btn btn-danger delete-btn" onclick="setBackground('', '', 'remove')"><i class="fas fa-trash"></i> 删除背景</button>
                    </div>
                </div>
                <table class="table table-bordered text-center">
                    <tbody id="fileTableBody">
                        <?php
                        function isImage($file) {
                            $imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
                            $fileExtension = strtolower(pathinfo($file, PATHINFO_EXTENSION));
                            return in_array($fileExtension, $imageExtensions);
                        }

                        function isVideo($file) {
                            $videoExtensions = ['mp4', 'avi', 'mkv', 'mov', 'wmv'];
                            $fileExtension = strtolower(pathinfo($file, PATHINFO_EXTENSION));
                            return in_array($fileExtension, $videoExtensions);
                        }

                        function isAudio($file) {
                            $audioExtensions = ['mp3', 'wav', 'ogg', 'flac', 'aac', 'm4a', 'webm', 'opus'];
                            $fileExtension = strtolower(pathinfo($file, PATHINFO_EXTENSION));
                            return in_array($fileExtension, $audioExtensions);
                        }

                        function getFileNameWithoutPrefix($file) {
                            $fileBaseName = pathinfo($file, PATHINFO_FILENAME);
                            $hyphenPos = strpos($fileBaseName, '-');
                            if ($hyphenPos !== false) {
                                return substr($fileBaseName, $hyphenPos + 1) . '.' . pathinfo($file, PATHINFO_EXTENSION);
                            } else {
                                return $file;
                            }
                        }

                        function formatFileSize($size) {
                            if ($size >= 1073741824) {
                                return number_format($size / 1073741824, 2) . ' GB';
                            } elseif ($size >= 1048576) {
                                return number_format($size / 1048576, 2) . ' MB';
                            } elseif ($size >= 1024) {
                                return number_format($size / 1024, 2) . ' KB';
                            } else {
                                return $size . ' bytes';
                            }
                        }

                        $picturesDir = $_SERVER['DOCUMENT_ROOT'] . '/nekobox/assets/Pictures/';
                        $backgroundHistoryFile = $_SERVER['DOCUMENT_ROOT'] . '/nekobox/background_history.txt';
                        $backgroundFiles = [];
                        if (file_exists($backgroundHistoryFile)) {
                            $backgroundFiles = array_filter(array_map('trim', file($backgroundHistoryFile)));
                        }

                        if (is_dir($picturesDir)) {
                            $files = array_diff(scandir($picturesDir), array('..', '.'));
                            usort($files, function ($a, $b) use ($backgroundFiles) {
                                $indexA = array_search($a, $backgroundFiles);
                                $indexB = array_search($b, $backgroundFiles);

                                if ($indexA === false && $indexB === false) {
                                    return 0; 
                                } elseif ($indexA === false) {
                                    return 1; 
                                } elseif ($indexB === false) {
                                    return -1; 
                                } else {
                                    return $indexA - $indexB; 
                                }
                            });

                            $fileCount = 0;
                            foreach ($files as $file) {
                                $filePath = $picturesDir . $file;
                                if (is_file($filePath)) {
                                    $fileSize = filesize($filePath);
                                    $formattedFileSize = formatFileSize($fileSize);
                                    $fileUrl = '/nekobox/assets/Pictures/' . $file;
                                    $fileNameWithoutPrefix = getFileNameWithoutPrefix($file);
                                    $fileTitle = "名称: $fileNameWithoutPrefix\n大小: $formattedFileSize";

                                    if ($fileCount % 5 == 0) {
                                        echo "<tr>";
                                    }

                                    echo "<td class='align-middle' data-label='预览' style='vertical-align: middle;'>
                                            <div class='file-preview mb-2 d-flex align-items-center'>
                                                <input type='checkbox' class='file-checkbox mb-2 mr-2' value='" . htmlspecialchars($file, ENT_QUOTES) . "' data-url='$fileUrl' data-title='$fileNameWithoutPrefix' data-size='$fileSize' onchange='updateSelectedCount()'>";

                                    if (isVideo($file)) {
                                        echo "<video width='200' controls title='$fileTitle'>
                                                  <source src='$fileUrl' type='video/mp4'>
                                                  Your browser does not support the video tag.
                                              </video>";
                                    } elseif (isImage($file)) {
                                        echo "<img src='$fileUrl' alt='$file' style='width: 200px; height: auto;' title='$fileTitle'>";
                                    } elseif (isAudio($file)) {
                                        echo "<audio width='200' controls title='$fileTitle'>
                                                  <source src='$fileUrl' type='audio/mp3'>
                                                  Your browser does not support the audio tag.
                                              </audio>";
                                    } else {
                                        echo "未知文件类型";
                                    }

                                    echo "<div class='btn-container mt-2 d-flex align-items-center'>
                                            <a href='?delete=" . htmlspecialchars($file, ENT_QUOTES) . "' onclick='return confirm(\"确定要删除吗?\")' class='icon-button btn-bordered' style='margin-right: 10px;'>
                                                <i class='fas fa-trash-alt'></i><span class='tooltip'>删除</span>
                                            </a>
                                            <button type='button' data-bs-toggle='modal' data-bs-target='#renameModal' onclick='document.getElementById(\"oldFileName\").value=\"" . htmlspecialchars($file, ENT_QUOTES) . "\"; document.getElementById(\"newFileName\").value=\"" . htmlspecialchars(getFileNameWithoutPrefix($file), ENT_QUOTES) . "\";' class='icon-button btn-bordered' style='margin-right: 10px;'>
                                                <i class='fas fa-edit'></i><span class='tooltip'>重命名</span>
                                            </button>
                                            <a href='$fileUrl' download class='icon-button btn-bordered' style='margin-right: 10px;'>
                                                <i class='fas fa-download'></i><span class='tooltip'>下载</span>
                                            </a>";

                                    if (isImage($file)) {
                                        echo "<button type='button' onclick=\"setBackground('" . htmlspecialchars($file, ENT_QUOTES) . "', 'image')\" class='icon-button btn-bordered' style='margin-left: 10px;'>
                                                <i class='fas fa-image'></i><span class='tooltip'>设置图片背景</span>
                                              </button>";
                                    } elseif (isVideo($file)) {
                                        echo "<button type='button' onclick=\"setBackground('" . htmlspecialchars($file, ENT_QUOTES) . "', 'video')\" class='icon-button btn-bordered' style='margin-left: 10px;'>
                                                <i class='fas fa-video'></i><span class='tooltip'>设置视频背景</span>
                                              </button>";
                                    } elseif (isAudio($file)) {
                                        echo "<button type='button' onclick=\"setBackground('" . htmlspecialchars($file, ENT_QUOTES) . "', 'audio')\" class='icon-button btn-bordered' style='margin-left: 10px;'>
                                                <i class='fas fa-music'></i><span class='tooltip'>设置背景音乐</span>
                                              </button>";
                                    }

                                    echo "</div></div></td>";

                                    if ($fileCount % 5 == 4) {
                                        echo "</tr>";
                                    }

                                    $fileCount++;
                                }
                            }

                            if ($fileCount % 5 != 0) {
                                echo str_repeat("<td></td>", 5 - ($fileCount % 5)) . "</tr>";
                            }
                        }

                        if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_POST['oldFileName']) && isset($_POST['newFileName'])) {
                            $oldFileName = $_POST['oldFileName'];
                            $newFileName = $_POST['newFileName'];

                            $oldFilePath = $picturesDir . $oldFileName;
                            $newFilePath = $picturesDir . $newFileName;

                            if (file_exists($oldFilePath)) {
                                if (rename($oldFilePath, $newFilePath)) {
                                    echo "<script>alert('文件重命名成功');</script>";
                                } else {
                                    echo "<script>alert('文件重命名失败');</script>";
                                }
                            } else {
                                echo "<script>alert('文件不存在');</script>";
                            }
                        }
                        ?>
                    </tbody>
                </table>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="videoPlayerModal" tabindex="-1" aria-labelledby="videoPlayerModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="videoPlayerModalLabel">媒体播放器</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body d-flex">
                <div class="w-75 pe-3">
                    <video id="videoPlayer" controls preload="auto" width="100%" height="400px" style="display: none;"></video>
                    <audio id="audioPlayer" controls preload="auto" style="width: 100%; display: none;"></audio>
                    <img id="imageViewer" src="" style="width: 100%; height: 400px; object-fit: contain; display: none;">
                </div>
                <div class="w-25 d-flex flex-column">
                    <h5>播放列表</h5>
                    <ul id="playlist" class="list-group flex-grow-1 overflow-auto"></ul>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-danger" onclick="clearPlaylist()">清空播放列表</button>
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="renameModal" tabindex="-1" aria-labelledby="renameModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <form id="renameForm" method="POST">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="renameModalLabel">重命名文件</h5>
                    <button type="button" class="close" data-bs-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <input type="hidden" name="oldFileName" id="oldFileName">
                    <div class="form-group">
                        <label for="newFileName">新文件名</label>
                        <input type="text" class="form-control" id="newFileName" name="newFileName" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                    <button type="submit" class="btn btn-primary">保存</button>
                </div>
            </div>
        </form>
    </div>
</div>

<div class="modal fade" id="newuploadModal" tabindex="-1" aria-labelledby="newuploadModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="newuploadModalLabel"><i class="fas fa-cloud-upload-alt"></i> 上传文件</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body text-center">
                <h2 class="mb-3">上传图片/视频</h2>
                <form method="POST" action="download.php" enctype="multipart/form-data">
                    <div id="dropArea" class="mb-3">
                        <i id="uploadIcon" class="fas fa-cloud-upload-alt"></i>
                        <p>拖拽文件到此区域，或点击图标选择文件。</p>
                        <p>PHP上传文件会有大小限制，如遇上传失败可以手动上传文件到 /nekobox/assets/Pictures 目录</p>
                    </div>
                    <input type="file" class="form-control mb-3" name="imageFile[]" id="imageFile" multiple style="display: none;">                   
                    <button type="submit" class="btn btn-success mt-3" id="submitBtnModal">
                        上传图片/视频
                    </button>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
                <button type="button" class="btn btn-warning" id="updatePhpConfig">更新 PHP 上传限制</button>
            </div>
        </div>
    </div>
</div>

<script>
let playlist = JSON.parse(localStorage.getItem('playlist')) || [];
let currentIndex = 0;

document.addEventListener("DOMContentLoaded", function () {
    updatePlaylistUI();
});

function clearPlaylist() {
    playlist = [];  
    updatePlaylistUI(); 
    savePlaylistToLocalStorage(); 
}

function addToPlaylist(mediaUrl, mediaTitle) {
    if (!playlist.some(item => item.url === mediaUrl)) {
        playlist.push({ url: mediaUrl, title: mediaTitle });
        updatePlaylistUI();
        savePlaylistToLocalStorage();  
    }
}

function updatePlaylistUI() {
    const playlistElement = document.getElementById('playlist');
    playlistElement.innerHTML = ''; 

    playlist.forEach((media, index) => {
        const listItem = document.createElement('li');
        listItem.className = 'list-group-item';
        listItem.textContent = `${index + 1}. ${media.title}`;

        const removeButton = document.createElement('button');
        removeButton.textContent = 'X';
        removeButton.classList.add('btn', 'btn-danger', 'btn-sm', 'float-right');
        removeButton.style.display = 'none'; 
        removeButton.onclick = () => removeFromPlaylist(index);

        listItem.appendChild(removeButton);

        listItem.setAttribute('draggable', 'true');
        listItem.addEventListener('dragstart', (event) => {
            event.dataTransfer.setData('text', index);
        });
        listItem.addEventListener('dragover', (event) => {
            event.preventDefault();
        });
        listItem.addEventListener('drop', (event) => {
            event.preventDefault();
            const draggedIndex = event.dataTransfer.getData('text');
            if (draggedIndex !== index) {
                removeFromPlaylist(draggedIndex);
                addToPlaylist(media.url, media.title);  
            }
        });

        listItem.addEventListener('contextmenu', (event) => {
            event.preventDefault();
            removeButton.style.display = 'block'; 
        });

        if (index === currentIndex) {
            listItem.classList.add('active');
        }

        listItem.onclick = () => playMedia(index);
        playlistElement.appendChild(listItem);
    });

    const activeItem = playlistElement.querySelector('.active');
    if (activeItem) {
        activeItem.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
}

function removeFromPlaylist(index) {
    playlist.splice(index, 1);
    if (currentIndex === index) {
        if (playlist.length > 0) {
            playMedia(Math.min(currentIndex, playlist.length - 1));
        } else {
            currentIndex = 0;  
        }
    }
    updatePlaylistUI();
    savePlaylistToLocalStorage(); 
}

function playMedia(index) {
    if (playlist.length === 0) return;

    currentIndex = index;
    const media = playlist[index];

    const videoElement = document.getElementById('videoPlayer');
    const audioElement = document.getElementById('audioPlayer');
    const imageElement = document.getElementById('imageViewer');

    videoElement.style.display = "none";
    audioElement.style.display = "none";
    imageElement.style.display = "none";

    let mediaUrl = media.url;
    if (!mediaUrl.startsWith('http://') && !mediaUrl.startsWith('https://')) {
        mediaUrl = window.location.origin + mediaUrl;
    }

    if (/\.(mp4|avi|mkv|mov|wmv)$/i.test(mediaUrl)) {
        if (!audioElement.paused) {
            audioElement.pause();
            audioElement.currentTime = 0;
        }

        videoElement.src = "";
        videoElement.src = mediaUrl;
        videoElement.style.display = "block";
        videoElement.load();
        videoElement.play().catch((err) => {
            console.warn("自动播放被阻止:", err);
        });

        videoElement.onended = () => playNextVideo();
    } 

    else if (/\.(mp3|wav|ogg|flac|aac|m4a|webm|opus)$/i.test(mediaUrl)) {
        if (!videoElement.paused) {
            videoElement.pause();
            videoElement.currentTime = 0;
        }

        audioElement.src = "";
        audioElement.src = mediaUrl;
        audioElement.style.display = "block";
        audioElement.load();
        audioElement.play().catch((err) => {
            console.warn("自动播放被阻止:", err);
        });

        audioElement.onended = () => playNextAudio();
    } 

    else if (/\.(jpg|jpeg|png|gif|bmp|webp)$/i.test(mediaUrl)) {
        imageElement.src = mediaUrl;
        imageElement.style.display = "block";
    }

    updatePlaylistUI();
}

function playNextVideo() {
    let nextIndex = (currentIndex + 1) % playlist.length;

    while (nextIndex !== currentIndex && !/\.(mp4|avi|mkv|mov|wmv)$/i.test(playlist[nextIndex].url)) {
        nextIndex = (nextIndex + 1) % playlist.length;
    }

    playMedia(nextIndex);
}

function playNextAudio() {
    let nextIndex = (currentIndex + 1) % playlist.length;

    while (nextIndex !== currentIndex && !/\.(mp3|wav|ogg|flac|aac|m4a|webm|opus)$/i.test(playlist[nextIndex].url)) {
        nextIndex = (nextIndex + 1) % playlist.length;
    }

    playMedia(nextIndex);
}

function openVideoPlayerModal() {
    document.querySelectorAll('.file-checkbox:checked').forEach(checkbox => {
        addToPlaylist(checkbox.getAttribute('data-url'), checkbox.getAttribute('data-title'));
    });

    if (playlist.length > 0) playMedia(0);  

    const videoPlayerModal = new bootstrap.Modal(document.getElementById('videoPlayerModal'));
    videoPlayerModal.show();
}

function savePlaylistToLocalStorage() {
    localStorage.setItem('playlist', JSON.stringify(playlist));
}
</script>

<script>
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

    document.addEventListener('DOMContentLoaded', (event) => {
        var el = document.getElementById('fileTableBody');
        var sortable = new Sortable(el, {
            animation: 150,
            onEnd: function (evt) {
                var order = sortable.toArray();
                $.ajax({
                    type: 'POST',
                    url: 'order_handler.php', 
                    data: { order: order },
                    success: function (response) {
                        showNotification('排序已成功保存!');
                    },
                    error: function (xhr, status, error) {
                        showNotification('保存排序时出错: ' + error);
                    }
                });
            },
        });

        $.ajax({
            type: 'GET',
            url: 'order_handler.php', 
            success: function (response) {
                var savedOrder = JSON.parse(response);
                var fileTableBody = document.getElementById('fileTableBody');
                var rows = Array.from(fileTableBody.children);
                rows.sort(function(a, b) {
                    return savedOrder.indexOf(a.id) - savedOrder.indexOf(b.id);
                });
                rows.forEach(function(row) {
                    fileTableBody.appendChild(row);
                });
            },
            error: function (xhr, status, error) {
                console.error('加载排序时出错: ' + error);
            }
        });
    });
</script>

<script>
function batchDelete() {
    const checkboxes = document.querySelectorAll('.file-checkbox:checked');
    if (checkboxes.length === 0) {
        alert("请选择要删除的文件。");
        return;
    }

    if (!confirm("确定要删除选中的文件吗?")) {
        return;
    }

    checkboxes.forEach(checkbox => {
        const fileName = checkbox.value;
        fetch(`?delete=${encodeURIComponent(fileName)}`)
            .then(response => {
                if (response.ok) {
                    checkbox.closest('td').remove(); 
                    updateSelectedCount();
                } else {
                    alert(`删除文件失败: ${fileName}`);
                }
            })
            .catch(error => console.error('Error:', error));
    });
}

function updateSelectedCount() {
    const checkboxes = document.querySelectorAll('.file-checkbox:checked');
    const selectedCount = checkboxes.length;
    let totalSize = 0;

    checkboxes.forEach(checkbox => {
        totalSize += parseInt(checkbox.getAttribute('data-size'), 10);
    });

    const totalSizeMB = (totalSize / 1048576).toFixed(2); 
    const selectedCountElement = document.getElementById('selectedCount');
    if (selectedCount > 0) {
        selectedCountElement.style.display = 'inline';
        selectedCountElement.innerText = `已选中 ${selectedCount} 个图片/视频，总计 ${totalSizeMB} MB`;
    } else {
        selectedCountElement.style.display = 'none';
    }
}

function sortFiles() {
    const tableBody = document.getElementById('fileTableBody');
    const rows = Array.from(tableBody.getElementsByTagName('tr'));
    
    rows.sort((a, b) => {
        const aText = a.getElementsByTagName('td')[0].querySelector('.file-preview img, .file-preview video').title;
        const bText = b.getElementsByTagName('td')[0].querySelector('.file-preview img, .file-preview video').title;
        
        return aText.localeCompare(bText);
    });

    rows.forEach(row => tableBody.appendChild(row));
}

function selectAll() {
    const checkboxes = document.querySelectorAll('.file-checkbox');
    checkboxes.forEach(checkbox => checkbox.checked = true);
    updateSelectedCount();
}

function deselectAll() {
    const checkboxes = document.querySelectorAll('.file-checkbox');
    checkboxes.forEach(checkbox => checkbox.checked = false);
    updateSelectedCount();
}

function showRenameModal(event, fileName) {
    event.preventDefault();
    const modal = new bootstrap.Modal(document.getElementById('renameModal'));
    document.getElementById('oldFileName').value = fileName;
    document.getElementById('newFileName').value = fileName; 
    modal.show();
}
</script>

<script>
document.getElementById("updatePhpConfig").addEventListener("click", function() {
    if (confirm("确定要修改 PHP 上传限制吗？")) {
        fetch("update_php_config.php", {
            method: "POST",
            headers: { "Content-Type": "application/json" }
        })
        .then(response => response.json())
        .then(data => alert(data.message))
        .catch(error => alert("请求失败：" + error.message));
    }
});
</script>

<script>
    document.getElementById('uploadIcon').addEventListener('click', function() {
        document.getElementById('imageFile').click(); 
    });

    document.getElementById('imageFile').addEventListener('change', function() {
        if (this.files.length > 0) {
            document.getElementById('submitBtnModal').style.display = 'inline-block';
        } else {
            document.getElementById('submitBtnModal').style.display = 'none';
        }
    });

    const dropArea = document.getElementById('dropArea');
    dropArea.addEventListener('dragover', function(event) {
        event.preventDefault(); 
        dropArea.classList.add('dragging'); 
    });

    dropArea.addEventListener('dragleave', function() {
        dropArea.classList.remove('dragging'); 
    });

    dropArea.addEventListener('drop', function(event) {
        event.preventDefault();
        dropArea.classList.remove('dragging'); 

        const files = event.dataTransfer.files;
        document.getElementById('imageFile').files = files; 

        if (files.length > 0) {
            document.getElementById('submitBtnModal').style.display = 'inline-block'; 
        }
    });
</script>

<script>
    const fileInput = document.getElementById('imageFile');
    const dragDropArea = document.getElementById('dragDropArea');
    const submitBtn = document.getElementById('submitBtn');

    dragDropArea.addEventListener('dragover', function(e) {
        e.preventDefault();
        dragDropArea.classList.add('drag-over');
    });

    dragDropArea.addEventListener('dragleave', function(e) {
        e.preventDefault();
        dragDropArea.classList.remove('drag-over');
    });

    dragDropArea.addEventListener('drop', function(e) {
        e.preventDefault();
        dragDropArea.classList.remove('drag-over');
        
        const files = e.dataTransfer.files;
        if (files.length > 0) {
            fileInput.files = files;  
        }
    });

    fileInput.addEventListener('change', function(e) {
        const files = e.target.files;
        if (files.length > 0) {
            submitBtn.disabled = false;
        } else {
            submitBtn.disabled = true;
        }
    });

    function updateDragDropText() {
        if (fileInput.files.length > 0) {
            dragDropArea.querySelector('p').textContent = `${fileInput.files.length} 个文件已选择`;
        } else {
            dragDropArea.querySelector('p').textContent = '拖动文件到此区域，或点击选择文件';
        }
    }
</script>

<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $uploadedFilePath = '';

    $allowedTypes = [
        'image/jpeg', 'image/png', 'image/gif', 'image/bmp', 'image/webp',
        'video/mp4', 'video/avi', 'video/mkv', 'video/mov', 'video/wmv', 'video/3gp',
        'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/flac', 'audio/aac', 'audio/m4a', 'audio/webm', 'audio/opus'
    ];

    if (isset($_FILES['imageFile']) && $_FILES['imageFile']['error'] === UPLOAD_ERR_OK) {
        $targetDir = $_SERVER['DOCUMENT_ROOT'] . '/nekobox/assets/Pictures/';
        if (!file_exists($targetDir)) {
            mkdir($targetDir, 0777, true);
        }

        $fileExtension = strtolower(pathinfo($_FILES['imageFile']['name'], PATHINFO_EXTENSION));

        if (in_array($fileExtension, $allowedTypes)) {
            $targetFile = $targetDir . basename($_FILES['imageFile']['name']);
            if (move_uploaded_file($_FILES['imageFile']['tmp_name'], $targetFile)) {
                $uploadedFilePath = '/nekobox/assets/Pictures/' . basename($_FILES['imageFile']['name']);
            }
        } else {
            echo "<script>alert('不支持的文件类型！');</script>";
        }
    }
}

if (isset($_GET['delete'])) {
    $fileToDelete = $_GET['delete'];
    $picturesDir = $_SERVER['DOCUMENT_ROOT'] . '/nekobox/assets/Pictures/';
    $filePath = $picturesDir . $fileToDelete;
    if (file_exists($filePath)) {
        unlink($filePath);
        echo "<script>alert('文件已删除！'); location.reload();</script>";
        exit;
    }
}
?>

<script>
function setBackground(filename, type, action = 'set') {
    const bodyData = 'filename=' + encodeURIComponent(filename) + '&type=' + type;

    if (action === 'set') {
        fetch('/nekobox/set_background.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'action=set&' + bodyData
        })
        .then(response => response.text())
        .then(data => {
            sessionStorage.setItem('notificationMessage', data);
            sessionStorage.setItem('notificationType', 'success');
                 location.reload(); 
        })
        .catch(error => {
            console.error('Error:', error);
            sessionStorage.setItem('notificationMessage', "操作失败，请稍后再试");
            sessionStorage.setItem('notificationType', 'error');
                location.reload(); 
        });
    }

    else if (action === 'remove') {
        fetch('/nekobox/set_background.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'action=remove'
        })
        .then(response => response.text())
        .then(data => {
            sessionStorage.setItem('notificationMessage', data);
            sessionStorage.setItem('notificationType', 'success');
                location.reload(); 
        })
        .catch(error => {
            console.error('Error:', error);
            sessionStorage.setItem('notificationMessage', "删除失败，请稍后再试");
            sessionStorage.setItem('notificationType', 'error');
                location.reload(); 
        });
    }
}

function showNotification(message, type = 'success') {
    var notification = document.createElement('div');
    notification.style.position = 'fixed';
    notification.style.top = '10px';
    notification.style.left = '30px'; 
    notification.style.padding = '10px';
    notification.style.borderRadius = '5px';
    notification.style.zIndex = '9999';
    notification.style.color = '#fff'; 
    notification.innerText = message;

    if (type === 'success') {
        notification.style.backgroundColor = '#4CAF50'; 
    } else if (type === 'error') {
        notification.style.backgroundColor = '#F44336'; 
    }

    document.body.appendChild(notification);

    setTimeout(function() {
        notification.style.display = 'none';
    }, 5000); 
}

window.addEventListener('load', function() {
    var message = sessionStorage.getItem('notificationMessage');
    var type = sessionStorage.getItem('notificationType');

    if (message) {
        showNotification(message, type); 
        sessionStorage.removeItem('notificationMessage');
        sessionStorage.removeItem('notificationType');
    }
});

</script>

<script>
  document.addEventListener("DOMContentLoaded", function() {
    const colorInputs = document.querySelectorAll('input[type="color"]');
    
    colorInputs.forEach(input => {
      if (localStorage.getItem(input.name)) {
        input.value = localStorage.getItem(input.name);
      }

      input.addEventListener('input', function() {
        localStorage.setItem(input.name, input.value);
      });
    });

    const useBackgroundImageCheckbox = document.getElementById('useBackgroundImage');
    const backgroundImageContainer = document.getElementById('backgroundImageContainer');

    const savedBackgroundImageState = localStorage.getItem('useBackgroundImage');
    if (savedBackgroundImageState === 'true') {
      useBackgroundImageCheckbox.checked = true;
      backgroundImageContainer.style.display = 'block';
    } else {
      useBackgroundImageCheckbox.checked = false;
      backgroundImageContainer.style.display = 'none';
    }

    useBackgroundImageCheckbox.addEventListener('change', function() {
      if (useBackgroundImageCheckbox.checked) {
        backgroundImageContainer.style.display = 'block';
      } else {
        backgroundImageContainer.style.display = 'none';
      }

      localStorage.setItem('useBackgroundImage', useBackgroundImageCheckbox.checked);
    });

    document.getElementById('resetButton').addEventListener('click', function() {
      document.getElementById('primaryColor').value = '#0ceda2';
      document.getElementById('secondaryColor').value = '#00ffff';
      document.getElementById('bodyBgColor').value = '#23407e';
      document.getElementById('infoBgSubtle').value = '#23407e';
      document.getElementById('backgroundColor').value = '#20cdd9';
      document.getElementById('primaryBorderSubtle').value = '#1815d1';
      document.getElementById('checkColor').value = '#0eaf3e';
      document.getElementById('labelColor').value = '#0eaf3e';
      document.getElementById('lineColor').value = '#f515f9';
      document.getElementById('controlColor').value = '#0eaf3e';
      document.getElementById('placeholderColor').value = '#f82af2';
      document.getElementById('disabledColor').value = '#23407e';
      document.getElementById('logTextColor').value = '#f8f9fa';
      document.getElementById('selectColor').value = '#23407e';
      document.getElementById('radiusColor').value = '#14b863';
      document.getElementById('bodyColor').value = '#04f153';
      document.getElementById('tertiaryColor').value = '#46e1ec';
      document.getElementById('ipColor').value = '#09b63f';
      document.getElementById('ipipColor').value = '#ff69b4';
      document.getElementById('detailColor').value = '#FFFFFF';
      document.getElementById('outlineColor').value = '#0dcaf0';
      document.getElementById('successColor').value = '#28a745';
      document.getElementById('infoColor').value = '#0ca2ed';
      document.getElementById('warningColor').value = '#ffc107';
      document.getElementById('pinkColor').value = '#f82af2';
      document.getElementById('dangerColor').value = '#dc3545';
      document.getElementById('tertiaryRgbColor').value = '#1e90ff';
      document.getElementById('heading1Color').value = '#21e4f2';
      document.getElementById('heading2Color').value = '#65f1fb';
      document.getElementById('heading3Color').value = '#ffcc00';
      document.getElementById('heading4Color').value = '#00fbff';
      document.getElementById('heading5Color').value = '#ba13f6';
      document.getElementById('heading6Color').value = '#00ffff';   
      localStorage.clear();
    });

    document.getElementById('exportButton').addEventListener('click', function() {
      const settings = {
        primaryColor: document.getElementById('primaryColor').value,
        secondaryColor: document.getElementById('secondaryColor').value,
        bodyBgColor: document.getElementById('bodyBgColor').value,
        infoBgSubtle: document.getElementById('infoBgSubtle').value,
        backgroundColor: document.getElementById('backgroundColor').value,
        primaryBorderSubtle: document.getElementById('primaryBorderSubtle').value,
        checkColor: document.getElementById('checkColor').value,
        labelColor: document.getElementById('labelColor').value,
        lineColor: document.getElementById('lineColor').value,
        controlColor: document.getElementById('controlColor').value,
        placeholderColor: document.getElementById('placeholderColor').value,
        disabledColor: document.getElementById('disabledColor').value,
        logTextColor: document.getElementById('logTextColor').value,
        selectColor: document.getElementById('selectColor').value,
        radiusColor: document.getElementById('radiusColor').value,
        bodyColor: document.getElementById('bodyColor').value,
        tertiaryColor: document.getElementById('tertiaryColor').value,
        tertiaryRgbColor: document.getElementById('tertiaryRgbColor').value,
        ipColor: document.getElementById('ipColor').value,
        ipipColor: document.getElementById('ipipColor').value,
        detailColor: document.getElementById('detailColor').value,
        outlineColor: document.getElementById('outlineColor').value,
        successColor: document.getElementById('successColor').value,
        infoColor: document.getElementById('infoColor').value,
        warningColor: document.getElementById('warningColor').value,
        pinkColor: document.getElementById('pinkColor').value,
        dangerColor: document.getElementById('dangerColor').value,
        heading1Color: document.getElementById('heading1Color').value,
        heading2Color: document.getElementById('heading2Color').value,
        heading3Color: document.getElementById('heading3Color').value,
        heading4Color: document.getElementById('heading4Color').value,
        heading5Color: document.getElementById('heading5Color').value,
        heading6Color: document.getElementById('heading6Color').value,
        useBackgroundImage: document.getElementById('useBackgroundImage').checked,
        backgroundImage: document.getElementById('backgroundImage').value
      };

      const blob = new Blob([JSON.stringify(settings)], { type: 'application/json' });
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = 'theme-settings.json';
      link.click();
    });

    document.getElementById('importButton').addEventListener('change', function(event) {
      const file = event.target.files[0];
      if (file && file.type === 'application/json') {
        const reader = new FileReader();
        reader.onload = function(e) {
          const settings = JSON.parse(e.target.result);

          document.getElementById('primaryColor').value = settings.primaryColor;
          document.getElementById('secondaryColor').value = settings.secondaryColor;
          document.getElementById('bodyBgColor').value = settings.bodyBgColor;
          document.getElementById('infoBgSubtle').value = settings.infoBgSubtle;
          document.getElementById('backgroundColor').value = settings.backgroundColor;
          document.getElementById('primaryBorderSubtle').value = settings.primaryBorderSubtle;
          document.getElementById('checkColor').value = settings.checkColor;
          document.getElementById('labelColor').value = settings.labelColor;
          document.getElementById('lineColor').value = settings.lineColor;
          document.getElementById('controlColor').value = settings.controlColor;
          document.getElementById('placeholderColor').value = settings.placeholderColor;
          document.getElementById('disabledColor').value = settings.disabledColor;
          document.getElementById('logTextColor').value = settings.logTextColor;
          document.getElementById('selectColor').value = settings.selectColor;
          document.getElementById('radiusColor').value = settings.radiusColor;
          document.getElementById('bodyColor').value = settings.bodyColor;
          document.getElementById('tertiaryColor').value = settings.tertiaryColor;
          document.getElementById('tertiaryRgbColor').value = settings.tertiaryRgbColor;
          document.getElementById('ipColor').value = settings.ipColor;
          document.getElementById('ipipColor').value = settings.ipipColor;
          document.getElementById('detailColor').value = settings.detailColor;
          document.getElementById('outlineColor').value = settings.outlineColor;
          document.getElementById('successColor').value = settings.successColor;
          document.getElementById('infoColor').value = settings.infoColor;
          document.getElementById('warningColor').value = settings.warningColor;
          document.getElementById('pinkColor').value = settings.pinkColor;
          document.getElementById('dangerColor').value = settings.dangerColor;
          document.getElementById('heading1Color').value = settings.heading1Color;
          document.getElementById('heading2Color').value = settings.heading2Color;
          document.getElementById('heading3Color').value = settings.heading3Color;
          document.getElementById('heading4Color').value = settings.heading4Color;
          document.getElementById('heading5Color').value = settings.heading5Color;
          document.getElementById('heading6Color').value = settings.heading6Color;
          document.getElementById('useBackgroundImage').checked = settings.useBackgroundImage;

          const backgroundImageContainer = document.getElementById('backgroundImageContainer');
          backgroundImageContainer.style.display = settings.useBackgroundImage ? 'block' : 'none';
          document.getElementById('backgroundImage').value = settings.backgroundImage || '';

          localStorage.setItem('primaryColor', settings.primaryColor);
          localStorage.setItem('secondaryColor', settings.secondaryColor);
          localStorage.setItem('bodyBgColor', settings.bodyBgColor);
          localStorage.setItem('infoBgSubtle', settings.infoBgSubtle);
          localStorage.setItem('backgroundColor', settings.backgroundColor);
          localStorage.setItem('primaryBorderSubtle', settings.primaryBorderSubtle);
          localStorage.setItem('checkColor', settings.checkColor);
          localStorage.setItem('labelColor', settings.labelColor);
          localStorage.setItem('lineColor', settings.lineColor);
          localStorage.setItem('controlColor', settings.controlColor);
          localStorage.setItem('placeholderColor', settings.placeholderColor);
          localStorage.setItem('disabledColor', settings.disabledColor);
          localStorage.setItem('logTextColor', settings.logTextColor);
          localStorage.setItem('selectColor', settings.selectColor);
          localStorage.setItem('radiusColor', settings.radiusColor);
          localStorage.setItem('bodyColor', settings.bodyColor);
          localStorage.setItem('tertiaryColor', settings.tertiaryColor);
          localStorage.setItem('tertiaryRgbColor', settings.tertiaryRgbColor);
          localStorage.setItem('ipColor', settings.ipColor);
          localStorage.setItem('ipipColor', settings.ipipColor);
          localStorage.setItem('detailColor', settings.detailColor);
          localStorage.setItem('outlineColor', settings.outlineColor);
          localStorage.setItem('successColor', settings.successColor);
          localStorage.setItem('infoColor', settings.infoColor);
          localStorage.setItem('warningColor', settings.warningColor);
          localStorage.setItem('pinkColor', settings.pinkColor);
          localStorage.setItem('dangerColor', settings.dangerColor);
          localStorage.setItem('heading1Color', settings.heading1Color);
          localStorage.setItem('heading2Color', settings.heading2Color);
          localStorage.setItem('heading3Color', settings.heading3Color);
          localStorage.setItem('heading4Color', settings.heading4Color);
          localStorage.setItem('heading5Color', settings.heading5Color);
          localStorage.setItem('heading6Color', settings.heading6Color);
          localStorage.setItem('useBackgroundImage', settings.useBackgroundImage);
          localStorage.setItem('backgroundImage', settings.backgroundImage);
        };
        reader.readAsText(file);
      }
    });
  });
</script>
