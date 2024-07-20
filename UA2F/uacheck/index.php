<?php
$userAgent = $_SERVER['HTTP_USER_AGENT'];
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>User-Agent Display</title>
    <style>
        /* Light mode styles (if different from your default styles) */
        @media (prefers-color-scheme: light) {
            body {
                background-color: #f0f0f0;
                color: #333;
            }

            .block {
                background-color: #fff;
                border-color: #ddd;
            }

            .title {
                color: #333;
            }

            button {
                background-color: #f8f9fa;
                border-color: #ccc;
                color: #333;
            }
        }

        /* Dark mode styles */
        @media (prefers-color-scheme: dark) {
            body {
                background-color: #333;
                color: #f0f0f0;
            }

            .block {
                background-color: #444;
                border-color: #666;
            }

            .title {
                color: #fff;
            }

            button {
                background-color: #555;
                border-color: #777;
                color: #fff;
            }

            a {
                color: #0096ff;
                text-decoration: none;
            }
            a:hover {
                text-decoration: underline;
            }
        }

        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            padding: 20px;
        }

        .block {
            border: 1px solid #ddd;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }

        @media (min-width: 1200px) {
            .block {
                max-width: 800px;
                margin: 20px auto;
            }

            .title {
                font-size: 24px;
            }
        }

        button {
            border: 1px solid #ccc;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            margin-top: 10px;
        }

    </style>
    <script>
        function jump_port(port) {
            let url = window.location.protocol + '//' + window.location.hostname;
            if (port !== 80) {
                url += ':' + port;
            }
            url += window.location.pathname;
            window.location.href = url;
        }
    </script>
</head>
<body>
<div class="block" id="php-user-agent">
    <h2 class="title">服务器端 User-Agent:</h2>
    <p><?php echo htmlspecialchars($userAgent); ?></p>
</div>
<div class="block" id="js-user-agent">
    <h2 class="title">用户端 User-Agent:</h2>
    <p></p>
</div>
<div class="block" id="ip">
    <h2 class="title">IP 地址:</h2>
    <p><?php echo $_SERVER['REMOTE_ADDR']; ?></p>
</div>
<div class="block" id="port">
    <h2 class="title">端口:</h2>
    <p><?php echo $_SERVER['SERVER_PORT']; ?></p>
<!--    if port is 80, show a link to 2333, or show a link to 80, wrap the link with button-->
    <?php if ($_SERVER['SERVER_PORT'] == 80): ?>
        <button onclick="jump_port(2333)">访问 2333 端口</button>
    <?php else: ?>
        <button onclick="jump_port(80)">访问 80 端口</button>
    <?php endif; ?>
</div>
<div class="block" id="ua2f-status">
    <h2 class="title"><a href="https://github.com/Zxilly/UA2F" target="_blank">UA2F</a> 推测状态:</h2>
    <p></p>
</div>
<script>
    document.getElementById('js-user-agent').querySelector('p').textContent = navigator.userAgent;

    // Compare server-side and client-side User-Agents
    const serverUA = document.getElementById('php-user-agent').querySelector('p').textContent;
    const clientUA = navigator.userAgent;
    const ua2fStatusText = serverUA === clientUA ? "未工作" : "正常工作";
    document.getElementById('ua2f-status').querySelector('p').textContent = ua2fStatusText;

    if (window.location.protocol === 'https:') {
        document.querySelectorAll('.block').forEach(function (element) {
            element.style.display = 'none';
        });

        const messageDiv = document.createElement('div');
        messageDiv.textContent = '此网页无法在 https 下正常工作';
        messageDiv.style.padding = '20px';
        messageDiv.style.marginTop = '20px';
        messageDiv.style.backgroundColor = '#ffcccc';
        messageDiv.style.textAlign = 'center';
        messageDiv.style.border = '1px solid #ffaaaa';
        document.body.appendChild(messageDiv);
    }

    const ip = document.getElementById('ip').querySelector('p').textContent;
    fetch('https://api.ip.sb/geoip/' + ip)
        .then(response => response.json())
        .then(data => {
            const ele = document.getElementById('ip').querySelector('p');
            ele.textContent += ' (' + data.country + ')';
            if (data.country_code !== 'CN') {
                ele.style.color = 'red';
                ele.textContent += ' 请检查是否使用了代理';
                document.getElementById('ua2f-status').querySelector('p').textContent += " (在代理下可能不准确)"
            }
        })
        .catch(error => {
            console.error('Error:', error);
        });
</script>
</body>
</html>