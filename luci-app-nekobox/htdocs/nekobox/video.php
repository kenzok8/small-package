<?php
date_default_timezone_set('Asia/Shanghai');
ob_start();
include './cfg.php';
?>

<!DOCTYPE html>
<html lang="zh-CN" data-bs-theme="<?php echo substr($neko_theme, 0, -4) ?>">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" href="./assets/img/nekobox.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="./assets/js/neko.js"></script>
</head>
<body>
    <style>
        .controls {
            display: flex;
            align-items: center;
            margin-bottom: 10px;
        }
        .controls label {
            margin-right: 10px;
            font-weight: bold;
            color: #FF5733;
        }
        .controls input {
            margin-right: 20px;
        }
        .controls p {
            margin: 0;
            color: #00F;
        }
    </style>
</head>
<body>
<div class="container my-3 p-3 border border-3 rounded-4" style="background-color: #f8f9fa;">
    <div class="controls">
        <label for="main-toggle">系统开关</label>
        <input type="checkbox" id="main-toggle">
        
        <label for="weather-toggle">天气播报</label>
        <input type="checkbox" id="weather-toggle">

        <label for="website-toggle">网站检查</label>
        <input type="checkbox" id="website-toggle">     
        <p>
            当前城市：
            <span id="current-city" style="font-weight: bold; color: #33FF57;">未设置</span>
        </p>
    </div>
  
    <div class="controls mt-3">
        <label>城市设置</label>
        <input type="text" id="city-input" class="form-control" placeholder="如 Beijing" style="padding: 5px;">
        <button onclick="saveCity()" class="btn btn-success mt-2" style="padding: 3px 10px;">保存城市</button>
    </div>
    <script>
    let city = 'Beijing'; 
    const apiKey = 'fc8bd2637768c286c6f1ed5f1915eb22'; 
    let systemEnabled = true; 
    let weatherEnabled = true;
    let websiteCheckEnabled = true;
    let lastHour = -1; 

    function speakMessage(message) {
        const utterance = new SpeechSynthesisUtterance(message);
        utterance.lang = 'zh-CN';
        speechSynthesis.speak(utterance);
    }

    function getGreeting() {
        const hours = new Date().getHours();
        if (hours >= 5 && hours < 12) return '早上好！';
        if (hours >= 12 && hours < 18) return '下午好！';
        if (hours >= 18 && hours < 22) return '晚上好！';
        return '夜深了，注意休息！';
    }

    function speakCurrentTime() {
        const now = new Date();
        const hours = now.getHours();
        const minutes = now.getMinutes().toString().padStart(2, '0');
        const seconds = now.getSeconds().toString().padStart(2, '0');
        const currentTime = `${hours}点${minutes}分${seconds}秒`;

        const timeOfDay = (hours >= 5 && hours < 8) ? '清晨'
                          : (hours >= 8 && hours < 11) ? '早上'
                          : (hours >= 11 && hours < 13) ? '中午'
                          : (hours >= 13 && hours < 18) ? '下午'
                          : (hours >= 18 && hours < 20) ? '傍晚'
                          : (hours >= 20 && hours < 24) ? '晚上'
                          : '凌晨';

        speakMessage(`${getGreeting()} 现在是北京时间: ${timeOfDay}${currentTime}`);
    }

    function updateHourlyTime() {
        const now = new Date();
        const hours = now.getHours();
        const minutes = now.getMinutes();
        const seconds = now.getSeconds();

        if (minutes === 0 && seconds === 0 && hours !== lastHour) {
            lastHour = hours;
            const timeOfDay = (hours >= 5 && hours < 8) ? '清晨'
                              : (hours >= 8 && hours < 11) ? '早上'
                              : (hours >= 11 && hours < 13) ? '中午'
                              : (hours >= 13 && hours < 18) ? '下午'
                              : (hours >= 18 && hours < 20) ? '傍晚'
                              : (hours >= 20 && hours < 24) ? '晚上'
                              : '凌晨';
            speakMessage(`整点播报，现在是北京时间 ${timeOfDay} ${hours}点`);
        }
    }

    const websites = [
        'https://www.youtube.com/',
        'https://www.google.com/',
        'https://www.facebook.com/',
        'https://www.twitter.com/',
        'https://www.github.com/'
    ];

    function getWebsiteStatusMessage(url, status) {
        const statusMessages = {
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
                    
                    if (!isAccessible && url === 'https://www.youtube.com/') {
                        speakMessage('无法访问 YouTube 网站，请检查网络连接。');
                    }
                })
                .catch(() => {
                    statusMessages.push(getWebsiteStatusMessage(url, false));
                    
                    if (url === 'https://www.youtube.com/') {
                        speakMessage('无法访问 YouTube 网站，请检查网络连接。');
                    }
                })
                .finally(() => {
                    requestsCompleted++;
                    if (requestsCompleted === urls.length) {
                        speakMessage(statusMessages.join(' '));
                    }
                });
        });
    }

    function getRandomPoem() {
        const poems = [
            '红豆生南国，春来发几枝。', '独在异乡为异客，每逢佳节倍思亲。',
            '海上生明月，天涯共此时。', '但愿人长久，千里共婵娟。',
            '江南好，风景旧曾谙。', '君不见黄河之水天上来，奔流到海不复回。',
            '露从今夜白，月是故乡明。', '自古逢秋悲寂寥，我言秋日胜春朝。',
            '两岸猿声啼不住，轻舟已过万重山。', '一去二三里，烟村四五家。',
            '问君何为别，心逐青云行。', '风急天高猿啸哀，渚清沙白鸟飞回。',
            '锦城虽云乐，不如早还家。', '白下驿穷冬望，红楼隔雨弄晴寒。',
            '夜泊牛渚怀古，牛渚西江夜。', '空山新雨后，天气晚来秋。',
            '山中相送罢，日暮掩柴扉。', '寒蝉凄切，对长亭晚，骤雨初歇。',
            '湖上初晴后雨，水面晕开清晖。', '孤舟蓑笠翁，独钓寒江雪。',
            '黄河远上白云间，一片孤城万仞山。', '松下问童子，言师采药去。',
            '白云深处有人家，黄鹤楼中吹玉笛。', '枯藤老树昏鸦，小桥流水人家。',
            '寒山转苍翠，秋水共长天一色。', '年年岁岁花相似，岁岁年年人不同。',
            '锦江春色来天地，玉垒浮云变古今。', '天街小雨润如酥，草色遥看近却无。',
            '长江绕郭知鱼美，苏堤春晓胜地宜。'
        ];
        return poems[Math.floor(Math.random() * poems.length)];
    }

    function speakRandomPoem() {
        const poem = getRandomPoem();
        speakMessage(`${poem}`);
    }

    function speakWeather(weather) {
        if (!weatherEnabled) return; 

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
                      `预计今天的最高气温为${tempMax}摄氏度，今晚的最低气温为${tempMin}摄氏度。`;

        if (weather.rain && weather.rain['1h']) {
            var rainProbability = weather.rain['1h'];
            message += ` 接下来一小时有${rainProbability * 100}%的降雨概率。`;
        } else if (weather.rain && weather.rain['3h']) {
            var rainProbability = weather.rain['3h'];
            message += ` 接下来三小时有${rainProbability * 100}%的降雨概率。`;
        } else {
            message += ' 今天降雨概率较低。';
        }

        message += ` 西南风速为每小时${windSpeed}米。` +
                   ` 湿度为${humidity}%。`;

        if (weatherDescription.includes('晴') || weatherDescription.includes('阳光明媚')) {
            message += ` 紫外线指数适中，如果外出，请记得涂防晒霜。`;
        } else if (weatherDescription.includes('雨') || weatherDescription.includes('阵雨') || weatherDescription.includes('雷暴')) {
            message += ` 建议您外出时携带雨伞。`;
        }

        message += ` 能见度为${visibility}公里。` +
                   `请注意安全，保持好心情，祝您有美好的一天！`;

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
            document.getElementById('current-city').textContent = city;
            speakMessage(`城市已保存为${city}，正在获取最新天气信息...`);
            fetchWeather();
        } else {
            speakMessage('请输入有效的城市名称。');
        }
    }

    document.getElementById('main-toggle').addEventListener('change', (event) => {
        systemEnabled = event.target.checked;
        localStorage.setItem('systemEnabled', systemEnabled); 
        if (systemEnabled) {
            speakMessage('系统已启用。');
            speakCurrentTime();
            speakRandomPoem();
            if (weatherEnabled) fetchWeather();
            if (websiteCheckEnabled) checkWebsiteAccess(websites); 
        } else {
            speakMessage('系统已关闭。');
        }
    });

    document.getElementById('weather-toggle').addEventListener('change', (event) => {
        weatherEnabled = event.target.checked;
        localStorage.setItem('weatherEnabled', weatherEnabled); 
        if (systemEnabled && weatherEnabled) {
            speakMessage('天气播报已启用。');
            fetchWeather();
        } else {
            speakMessage('天气播报已关闭。');
        }
    });

    document.getElementById('website-toggle').addEventListener('change', (event) => {
        websiteCheckEnabled = event.target.checked;
        localStorage.setItem('websiteCheckEnabled', websiteCheckEnabled); 
        if (systemEnabled && websiteCheckEnabled) {
            speakMessage('网站检测已启用。');
            checkWebsiteAccess(websites);
        } else {
            speakMessage('网站检测已关闭。');
        }
    });

    window.onload = function() {
        const savedCity = localStorage.getItem('city');
        if (savedCity) {
            city = savedCity;
            document.getElementById('current-city').textContent = city;
        }

        const savedSystemEnabled = localStorage.getItem('systemEnabled');
        if (savedSystemEnabled !== null) {
            systemEnabled = savedSystemEnabled === 'true';
            document.getElementById('main-toggle').checked = systemEnabled;
        } else {
            systemEnabled = true; 
            localStorage.setItem('systemEnabled', systemEnabled);
            document.getElementById('main-toggle').checked = systemEnabled;
        }

        const savedWeatherEnabled = localStorage.getItem('weatherEnabled');
        if (savedWeatherEnabled !== null) {
            weatherEnabled = savedWeatherEnabled === 'true';
            document.getElementById('weather-toggle').checked = weatherEnabled;
        } else {
            weatherEnabled = true; 
            localStorage.setItem('weatherEnabled', weatherEnabled);
            document.getElementById('weather-toggle').checked = weatherEnabled;
        }

        const savedWebsiteCheckEnabled = localStorage.getItem('websiteCheckEnabled');
        if (savedWebsiteCheckEnabled !== null) {
            websiteCheckEnabled = savedWebsiteCheckEnabled === 'true';
            document.getElementById('website-toggle').checked = websiteCheckEnabled;
        } else {
            websiteCheckEnabled = true; 
            localStorage.setItem('websiteCheckEnabled', websiteCheckEnabled);
            document.getElementById('website-toggle').checked = websiteCheckEnabled;
        }

        if (systemEnabled) {
            speakMessage('欢迎使用语音播报系统！');
        }
           if (systemEnabled && websiteCheckEnabled) {
            checkWebsiteAccess(websites);
        }
     
        if (systemEnabled) {
            speakCurrentTime();
            if (weatherEnabled) fetchWeather();
            speakRandomPoem();
        }

        setInterval(updateHourlyTime, 1000);
    };
</script>
</body>
</html>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: Arial, sans-serif;
            overflow: hidden;
            transition: background-color 0.3s ease;
        }
        #container {
            text-align: center;
            margin-top: 50px;
        }
        #player {
            width: 320px;
            height: 320px;
            margin: 50px auto;
            padding: 20px;
            background: url('/nekobox/assets/img/3.svg') no-repeat center center;
            background-size: cover;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            display: flex;
            flex-direction: column;
            align-items: center;
            border-radius: 50%;
            transform-style: preserve-3d;
            transition: transform 0.5s;
            position: relative;
            animation: rainbow 5s infinite, rotatePlayer 10s linear infinite;
        }
        #player:hover {
            transform: rotateY(360deg) rotateX(360deg);
        }
        #player h2 {
            margin-top: 0;
        }
        #audio-container {
           position: absolute;
            top: 80%;
            left: 50%;
            transform: translate(-50%, -50%);
            background-color: rgba(0, 0, 0, 1); 
            width: 100%;
            height: 100%;
        }
        #audioPlayer {
            position: absolute;
            top: 50%; 
            left: 50%;
            transform: translate(-50%, -50%);
        }

        #audioPlayer::-webkit-media-controls-panel {
            background-color: black;
        }
        #audioPlayer::-webkit-media-controls-current-time-display,
        #audioPlayer::-webkit-media-controls-time-remaining-display {
            color: #fff;
        }
        #audioPlayer::-webkit-media-controls-play-button,
        #audioPlayer::-webkit-media-controls-volume-slider-container,
        #audioPlayer::-webkit-media-controls-mute-button,
        #audioPlayer::-webkit-media-controls-timeline {
            filter: invert(1);
        }
        #controls {
            position: absolute;
            bottom: 80px; 
            left: 50%;
            transform: translateX(-50%);
            display: flex;
            justify-content: center;
            gap: 10px;
        }
        button {
            background-color: #4CAF50;
            border: none;
            color: white;
            padding: 10px 20px;
            text-align: center;
            text-decoration: none;
            display: inline-block;
            font-size: 16px;
            margin: 4px 2px;
            cursor: pointer;
            box-shadow: 0 4px #666;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        button:active {
            transform: translateY(4px);
            box-shadow: 0 2px #444;
        }
        @keyframes rotatePlayer {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        #hidePlayer, #timeDisplay {
            font-size: 24px;
            font-weight: bold;
            margin: 10px 0;
            background: linear-gradient(90deg, #FF0000, #FF7F00, #FFFF00, #00FF00, #0000FF, #4B0082, #9400D3);
            -webkit-background-clip: text;
            color: transparent;
            transition: background 1s ease;
        }
        .rounded-button {
            border-radius: 30px 15px;
        }
        #tooltip {
            position: absolute;
            background-color: green;
            color: #fff;
            padding: 5px;
            border-radius: 5px;
            display: none;
        }
        #mobile-controls {
            margin-top: 20px;
            position: relative;
            top: -35px; 
            transition: opacity 1s ease-in-out;
            opacity: 1;
        }
        #mobile-controls.hidden {
            opacity: 0;
            pointer-events: none;
        }
        body {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center; 
        }
        #top-center-container {
            display: flex;
            align-items: center; 
            justify-content: center; 
            position: absolute;
            top: 10px;
            width: 100%; 
        }
        #weather-toggle {
            margin-left: 10px; 
        }
        @media (min-width: 768px) {
            #mobile-controls {
                display: none;
            }
        }
        @media (max-width: 767px) {
            #mobile-controls {
                display: block;
            }
        }
    </style>
</head>
<body>
  </div>
 <div id="player"  onclick="toggleAnimation()">
        <p id="hidePlayer">NeKoBox</p>
        <p id="timeDisplay">00:00</p>
        <audio id="audioPlayer" controls>
            <source src="" type="audio/mpeg">
            您的浏览器不支持音频播放。
        </audio>
        <br>
        <div id="controls">
            <button id="prev" class="rounded-button">⏮️</button>
            <button id="orderLoop" class="rounded-button">🔁</button>
            <button id="play" class="rounded-button">⏸️</button>
            <button id="next" class="rounded-button">⏭️</button>
       </div>
    </div>
    <div id="mobile-controls">
        <button id="togglePlay" class="rounded-button">播放/暂停</button>
        <button id="prevMobile" class="rounded-button">上一首</button>
        <button id="nextMobile" class="rounded-button">下一首</button>
        <button id="toggleEnable" class="rounded-button">启用/禁用</button>
    </div>
    <div id="tooltip"></div>

    <script>
        let colors = ['#FF0000', '#FF7F00', '#FFFF00', '#00FF00', '#0000FF', '#4B0082', '#9400D3'];
        let isPlayingAllowed = JSON.parse(localStorage.getItem('isPlayingAllowed')) || false;
        let isLooping = false;
        let isOrdered = false;
        let currentSongIndex = 0;
        let songs = [];
        const audioPlayer = document.getElementById('audioPlayer');

        function speakMessage(message) {
            const utterance = new SpeechSynthesisUtterance(message);
            utterance.lang = 'zh-CN'; 
            speechSynthesis.speak(utterance);
        }

        function toggleAnimation() {
            const player = document.getElementById('player');
            if (player.style.animationPlayState === 'paused') {
                player.style.animationPlayState = 'running';
            } else {
                player.style.animationPlayState = 'paused';
            }
        }

        var hidePlayerButton = document.getElementById('hidePlayer');
        hidePlayerButton.addEventListener('click', function() {
            var player = document.getElementById('player');
            if (player.style.display === 'none') {
                localStorage.setItem('playerVisible', 'true');
            } else {
                player.style.display = 'none';
                localStorage.setItem('playerVisible', 'false');
            }
        });

        function applyGradient(text, elementId) {
            const element = document.getElementById(elementId);
            element.innerHTML = '';
            for (let i = 0; i < text.length; i++) {
                const span = document.createElement('span');
                span.textContent = text[i];
                span.style.color = colors[i % colors.length];
                element.appendChild(span);
            }
            const firstColor = colors.shift();
            colors.push(firstColor);
        }

        function updateTime() {
            const now = new Date();
            const hours = now.getHours();
            const timeString = now.toLocaleTimeString('zh-CN', { hour12: false });
            let ancientTime;

            if (hours >= 23 || hours < 1) {
                ancientTime = '子時';
            } else if (hours >= 1 && hours < 3) {
                ancientTime = '丑時';
            } else if (hours >= 3 && hours < 5) {
                ancientTime = '寅時';
            } else if (hours >= 5 && hours < 7) {
                ancientTime = '卯時';
            } else if (hours >= 7 && hours < 9) {
                ancientTime = '辰時';
            } else if (hours >= 9 && hours < 11) {
                ancientTime = '巳時';
            } else if (hours >= 11 && hours < 13) {
                ancientTime = '午時';
            } else if (hours >= 13 && hours < 15) {
                ancientTime = '未時';
            } else if (hours >= 15 && hours < 17) {
                ancientTime = '申時';
            } else if (hours >= 17 && hours < 19) {
                ancientTime = '酉時';
            } else if (hours >= 19 && hours < 21) {
                ancientTime = '戌時';
            } else {
                ancientTime = '亥時';
            }

            const displayString = `${timeString} (${ancientTime})`;
            applyGradient(displayString, 'timeDisplay');
        }

        applyGradient('NeKoBox', 'hidePlayer');
        updateTime();
        setInterval(updateTime, 1000);

        function showTooltip(text) {
            const tooltip = document.getElementById('tooltip');
            tooltip.textContent = text;
            tooltip.style.display = 'block';
            tooltip.style.left = (window.innerWidth - tooltip.offsetWidth - 20) + 'px';
            tooltip.style.top = '10px';
            setTimeout(hideTooltip, 5000);
        }

        function hideTooltip() {
            const tooltip = document.getElementById('tooltip');
            tooltip.style.display = 'none';
        }

        function handlePlayPause() {
            const playButton = document.getElementById('play');
            if (isPlayingAllowed) {
                if (audioPlayer.paused) {
                    showTooltip('播放');
                    audioPlayer.play();
                    playButton.textContent = '暂停';
                    speakMessage('播放');
                } else {
                    showTooltip('暂停播放');
                    audioPlayer.pause();
                    playButton.textContent = '播放';
                    speakMessage('暂停播放');
                }
            } else {
                showTooltip('播放被禁止');
                audioPlayer.pause();
                playButton.textContent = '播放';
                speakMessage('播放被禁用，按下 ESC 键重新启用播放。');
            }
        }

        function handleOrderLoop() {
            if (isPlayingAllowed) {
                const orderLoopButton = document.getElementById('orderLoop');
                if (isOrdered) {
                    isOrdered = false;
                    isLooping = !isLooping;
                    orderLoopButton.textContent = isLooping ? '循' : '';
                    showTooltip(isLooping ? '循环播放' : '暂停循环');
                    speakMessage(isLooping ? '循环播放' : '暂停循环');
                } else {
                    isOrdered = true;
                    isLooping = false;
                    orderLoopButton.textContent = '顺';
                    showTooltip('顺序播放');
                    speakMessage('顺序播放');
                }
            } else {
                speakMessage('播放被禁用，按下 ESC 键重新启用播放。');
            }
        }

        document.addEventListener('keydown', function(event) {
            switch (event.key) {
                case 'ArrowLeft':
                    if (isPlayingAllowed) {
                        document.getElementById('prev').click();
                    } else {
                        showTooltip('播放被禁止');
                        speakMessage('播放被禁用，按下 ESC 键重新启用播放。');
                    }
                    break;
                case 'ArrowRight':
                    if (isPlayingAllowed) {
                        document.getElementById('next').click();
                    } else {
                        showTooltip('播放被禁止');
                        speakMessage('播放被禁用，按下 ESC 键重新启用播放。');
                    }
                    break;
                case ' ':
                    handlePlayPause();
                    break;
                case 'ArrowUp':
                    handleOrderLoop();
                    break;
                case 'Escape':
                    isPlayingAllowed = !isPlayingAllowed;
                    localStorage.setItem('isPlayingAllowed', isPlayingAllowed); 
                    if (!isPlayingAllowed) {
                        audioPlayer.pause();
                        audioPlayer.src = '';
                        showTooltip('播放已禁用');
                        speakMessage('播放已禁用，按下 ESC 键重新启用播放。');
                    } else {
                        showTooltip('播放已启用');
                        speakMessage('播放已启用。');
                        if (songs.length > 0) {
                            loadSong(currentSongIndex);
                        }
                    }
                    break;
            }
        });

        document.getElementById('play').addEventListener('click', handlePlayPause);
        document.getElementById('next').addEventListener('click', function() {
            if (isPlayingAllowed) {
                currentSongIndex = (currentSongIndex + 1) % songs.length;
                loadSong(currentSongIndex);
                showTooltip('下一首');
                speakMessage('下一首');
            } else {
                showTooltip('播放被禁止');
                speakMessage('播放被禁用，按下 ESC 键重新启用播放。');
            }
        });
        document.getElementById('prev').addEventListener('click', function() {
            if (isPlayingAllowed) {
                currentSongIndex = (currentSongIndex - 1 + songs.length) % songs.length;
                loadSong(currentSongIndex);
                showTooltip('上一首');
                speakMessage('上一首');
            } else {
                showTooltip('播放被禁止');
                speakMessage('播放被禁用，按下 ESC 键重新启用播放。');
            }
        });
        document.getElementById('orderLoop').addEventListener('click', handleOrderLoop);

        document.getElementById('togglePlay').addEventListener('click', handlePlayPause);
        document.getElementById('prevMobile').addEventListener('click', function() {
            if (isPlayingAllowed) {
                currentSongIndex = (currentSongIndex - 1 + songs.length) % songs.length;
                loadSong(currentSongIndex);
                showTooltip('上一首');
                speakMessage('上一首');
            } else {
                showTooltip('播放被禁止');
                speakMessage('播放被禁用，按下 ESC 键即可启用音乐播放。');
            }
        });
        document.getElementById('nextMobile').addEventListener('click', function() {
            if (isPlayingAllowed) {
                currentSongIndex = (currentSongIndex + 1) % songs.length;
                loadSong(currentSongIndex);
                showTooltip('下一首');
                speakMessage('下一首');
            } else {
                showTooltip('播放被禁止');
                speakMessage('播放被禁用，按下 ESC 键即可启用音乐播放。');
            }
        });
        document.getElementById('toggleEnable').addEventListener('click', function() {
            isPlayingAllowed = !isPlayingAllowed;
            localStorage.setItem('isPlayingAllowed', isPlayingAllowed); 
            if (!isPlayingAllowed) {
                audioPlayer.pause();
                audioPlayer.src = '';
                showTooltip('播放已禁用');
                speakMessage('播放已禁用，按下 ESC 键重新启用播放。');
            } else {
                showTooltip('播放已启用');
                speakMessage('播放已启用。');
                if (songs.length > 0) {
                    loadSong(currentSongIndex);
                }
            }
        });

        function loadSong(index) {
            if (isPlayingAllowed && index >= 0 && index < songs.length) {
                audioPlayer.src = songs[index];
                audioPlayer.play();
            } else {
                audioPlayer.pause();
            }
        }

        audioPlayer.addEventListener('ended', function() {
            if (isPlayingAllowed) {
                if (isLooping) {
                    audioPlayer.currentTime = 0;
                    audioPlayer.play();
                } else {
                    currentSongIndex = (currentSongIndex + 1) % songs.length;
                    loadSong(currentSongIndex);
                }
            }
        });

        function initializePlayer() {
            if (songs.length > 0) {
                loadSong(currentSongIndex);
            }
        }

        function loadDefaultPlaylist() {
            fetch('https://raw.githubusercontent.com/Thaolga/Rules/main/Clash/songs.txt')
                .then(response => {
                    if (!response.ok) {
                        throw new Error('默认歌单加载失败，网络响应不正常');
                    }
                    return response.text();
                })
                .then(data => {
                    songs = data.split('\n').filter(url => url.trim() !== '');
                    if (songs.length === 0) {
                        throw new Error('默认歌单中没有有效的歌曲');
                    }
                    initializePlayer();
                    console.log('默认歌单已加载:', songs);
                })
                .catch(error => {
                    console.error('加载默认歌单时出错:', error.message);
                });
        }

        loadDefaultPlaylist();
        document.addEventListener('dblclick', function() {
            var player = document.getElementById('player');
            if (player.style.display === 'none') {
                player.style.display = 'flex'; 
            } else {
                player.style.display = 'none'; 
            }
        });
    </script>
</body>
</html>
