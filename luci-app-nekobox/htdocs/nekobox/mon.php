<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0"> 
    <style>
        html, body {
            margin: 0;
            padding: 0;
            overflow-x: hidden;
            width: 100%;
            height: 100%;
            font-family: 'Comic Sans MS', cursive, sans-serif;
        }

        body {
            box-sizing: border-box;
            background: #f0f8ff;
        }

        nav {
            background: linear-gradient(145deg, #6a5acd, #87ceeb);
            height: 70px; 
            position: sticky;
            top: 0;
            width: 100%;
            z-index: 1000;
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
            display: flex;
            justify-content: center;
            align-items: center; 
        }

        nav:hover {
            background: linear-gradient(145deg, #87ceeb, #6a5acd);
            box-shadow: 0 12px 24px rgba(0, 0, 0, 0.3);
        }

        nav ul {
            list-style-type: none;
            padding: 0;
            margin: 0;
            display: flex;
            justify-content: center;
            position: relative;
        }

        nav ul li {
            margin: 0 15px;
            position: relative;
        }

        nav ul li a {
            text-decoration: none;
            color: #ffffff;
            font-size: 16px;
            padding: 8px 15px;
            border-radius: 25px;
            transition: background-color 0.3s, color 0.3s, transform 0.3s, box-shadow 0.3s;
            display: block;
            position: relative;
            overflow: hidden;
            white-space: nowrap;
        }

        nav ul li a:hover {
            background-color: rgba(255, 255, 255, 0.2);
            color: #6a5acd;
            transform: scale(1.1);
        }

        nav ul li a.active {
            background-color: rgba(255, 255, 255, 0.4);
            color: #6a5acd;
            font-weight: bold;
        }

        .submenu {
            display: none;
            position: absolute;
            top: 100%;
            left: 0;
            background: linear-gradient(145deg, #6a5acd, #87ceeb);
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
            border-radius: 0;
            padding: 5px 0;
            min-width: 160px;
            box-sizing: border-box;
            white-space: nowrap;
        }

        nav ul li:hover .submenu {
            display: block;
        }

        .submenu li {
            margin: 0;
            padding: 0;
        }

        .submenu li a {
            font-size: 14px;
            padding: 8px 15px;
            color: #ffffff;
            transition: background-color 0.3s, color 0.3s;
            position: relative;
            overflow: hidden;
            box-sizing: border-box;
            white-space: nowrap;
        }

        .submenu li a:hover {
            background-color: rgba(255, 255, 255, 0.2);
            color: #6a5acd;
        }

        .content {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        .cbi-map {
            width: 100vw;
            height: 100vh;
            margin: 0;
            padding: 0;
            overflow: hidden;
            background-color: black;
            position: relative;
        }

        .cbi-map iframe {
            width: 100%;
            height: 100%;
            border: none;
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        .config-menu-button {
            position: absolute;
            left: 20px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 24px;
            background-color: #87ceeb; 
            color: #fff;
            border-radius: 50%;
            padding: 10px;
            cursor: pointer;
            transition: background-color 0.3s, transform 0.3s;
        }

        .config-menu-button:hover {
            background-color: #6a5acd;
            transform: translateY(-50%) scale(1.1);
        }

        @media (max-width: 768px) {
            nav ul {
                flex-wrap: nowrap;
            }

            nav ul li {
                margin: 0 10px; 
            }

            nav ul li a {
                font-size: 14px;
                padding: 8px 10px;
            }

            .config-menu-button {
                left: 10px; 
                padding: 10px; 
                font-size: 20px; 
            }
        }
    </style>
</head>
<body>
<nav>
    <a href="/nekobox" class="config-menu-button ">
        <i>🏠</i>
    </a>
    <ul>
        <li><a href="?page=personal" class="<?= (isset($_GET['page']) && $_GET['page'] == 'personal') ? 'active' : '' ?>">  Personal</a></li>
        <li><a href="?page=video" class="<?= (isset($_GET['page']) && $_GET['page'] == 'video') ? 'active' : '' ?>"> Video</a></li>
        <li><a href="?page=neko_yacd" class="<?= (isset($_GET['page']) && $_GET['page'] == 'neko_yacd') ? 'active' : '' ?>">Meta-Yacd</a></li>
        <li><a href="?page=neko_meta" class="<?= (isset($_GET['page']) && $_GET['page'] == 'neko_meta') ? 'active' : '' ?>">MetaCubeXD</a></li>
    </ul>
</nav>

<div class="content">
    <?php
    if (isset($_GET['page'])) {
        $page = $_GET['page'];
        
        switch ($page) {
            case 'personal':
                include 'personal.php';
                break;

            case 'video':
                include 'video.php';
                break;

            case 'neko_yacd':
                echo '<div class="cbi-map">
                        <iframe id="neko"></iframe>
                      </div>
                      <script type="text/javascript">
                          fetch("/nekobox/lib/log.php?data=url_dash")
                              .then(response => response.json())
                              .then(data => {
                                  document.getElementById("neko").src = data.yacd;
                              })
                              .catch(error => {
                                  console.error("Error fetching URL data:", error);
                              });
                      </script>';
                break;

            case 'neko_meta':
                echo '<div class="cbi-map">
                        <iframe id="neko"></iframe>
                      </div>
                      <script type="text/javascript">
                          fetch("/nekobox/lib/log.php?data=url_dash")
                              .then(response => response.json())
                              .then(data => {
                                  document.getElementById("neko").src = data.meta;
                              })
                              .catch(error => {
                                  console.error("Error fetching URL data:", error);
                              });
                      </script>';
                break;

            default:
                include 'box.php';
                break;
        }
    } else {
        include 'box.php';
    }
    ?>
</div>

</body>
</html>
