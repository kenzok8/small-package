<?php

include './cfg.php';

$dirPath = "$neko_dir/proxy_provider";
$tmpPath = "$neko_www/lib/tmpProxy.txt";
$arrFiles = array_merge(glob("$dirPath/*.yaml"), glob("$dirPath/*.json"));
$strProxy = "";
$strNewProxy = "";
$proxyPath = "";

if (isset($_POST['proxycfg'])) {
    $proxyPath = $_POST['proxycfg'];
    $strProxy = file_get_contents($proxyPath);
    file_put_contents($tmpPath, $proxyPath);
}

if (isset($_POST['newproxycfg'])) {
    $strNewProxy = $_POST['newproxycfg'];
    $proxyPath = file_get_contents($tmpPath);
    file_put_contents($proxyPath, $strNewProxy);
    unlink($tmpPath);
}
?>
<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme, 0, -4) ?>">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Proxy - Neko</title>
    <link rel="icon" href="./assets/img/favicon.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
</head>
<body class="container-bg">
<div class="container text-center justify-content-md-center mb-3">
    <br>
    <form action="proxyconf.php" method="post">
        <div class="container text-center justify-content-md-center">
            <div class="row justify-content-md-center">
                <div class="col input-group mb-3 justify-content-md-center">
                    <select class="form-select" name="proxycfg" aria-label="themex">
                        <option selected>Select Proxy</option>
                        <?php foreach ($arrFiles as $file): ?>
                            <option value="<?php echo htmlspecialchars($file); ?>"><?php echo htmlspecialchars($file); ?></option>
                        <?php endforeach; ?>
                    </select>
                    <input class="btn btn-info" type="submit" value="Select">
                </div>
            </div>
        </div>
    </form>
    <div class="container mb-3">
        <form action="proxyconf.php" method="post">
            <div class="container text-center justify-content-md-center">
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                        <?php if (!empty($proxyPath)) echo "<h5>" . htmlspecialchars($proxyPath) . "</h5>"; ?>
                    </div>
                </div>
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                        <textarea class="form-control" name="newproxycfg" rows="16"><?php echo htmlspecialchars($strProxy ?: $strNewProxy); ?></textarea>
                    </div>
                </div>
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                        <input class="btn btn-info" type="submit" value="💾 Save Proxy">
                    </div>
                </div>
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                        <?php if (!empty($strNewProxy)) echo "<h5>Proxy modified successfully</h5>"; ?>
                    </div>
                </div>
            </div>
        </form>   
        </div>
    </div>
  </body>
</html>