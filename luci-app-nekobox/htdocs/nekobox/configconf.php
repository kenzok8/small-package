<?php
include './cfg.php';
$strNewconfig = "";

if (isset($_POST['newconfigcfg'])) {
    $dt = $_POST['newconfigcfg'];
    $strNewconfig = $dt;
    file_put_contents($selected_config, $strNewconfig);
}

$strconfig = file_get_contents($selected_config);
?>
<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme, 0, -4) ?>">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Config Configurator - Neko</title>
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
        <div class="container mb-3">
            <form action="configconf.php" method="post">
                <div class="container text-center justify-content-md-center">
                    <div class="row justify-content-md-center">
                        <div class="col input-group mb-3 justify-content-md-center">
                            <textarea class="form-control" name="newconfigcfg" rows="22"><?php echo htmlspecialchars($strconfig); ?></textarea>
                        </div>
                    </div>
                    <div class="row justify-content-md-center">
                        <div class="col input-group mb-3 justify-content-md-center">
                            <input class="btn btn-info" type="submit" value="💾 Save Configuration">
                        </div>
                    </div>
                    <div class="row justify-content-md-center">
                        <div class="col input-group mb-3 justify-content-md-center">
                            <?php if (!empty($strNewconfig)) echo "<h5>Configuration Successfully Saved</h5>"; ?>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    </div>
</body>
</html>
