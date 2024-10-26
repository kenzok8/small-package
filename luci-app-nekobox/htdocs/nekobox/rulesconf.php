<?php

include './cfg.php';
$dirPath = "$neko_dir/rule_provider";
$tmpPath = "$neko_www/lib/tmprules.txt";
$rulePath = "";
$arrFiles = array();
$arrFiles = glob("$dirPath/*.yaml");
$strRules = "";
$strNewRules = "";
//print_r($arrFiles);
if(isset($_POST['rulescfg'])){
  $dt = $_POST['rulescfg'];
  $strRules = shell_exec("cat $dt");
  $rulePath = $dt;
  shell_exec("echo $dt > $tmpPath");
}
if(isset($_POST['newrulescfg'])){
  $dt = $_POST['newrulescfg'];
  $strNewRules = $dt;
  $tmpData = exec("cat $tmpPath");
  shell_exec("echo \"$strNewRules\" > $tmpData");
  shell_exec("rm $tmpPath");
}
?>
<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme,0,-4) ?>">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Rules - Neko</title>
    <link rel="icon" href="./assets/img/favicon.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
  </head>
  <body class="container-bg">
    <div class="container text-center justify-content-md-center mb-3"></br>
        <form action="rulesconf.php" method="post">
            <div class="container text-center justify-content-md-center">
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                      <select class="form-select" name="rulescfg" aria-label="themex">
                        <option selected>选择规则</option>
                        <?php foreach ($arrFiles as $file) echo "<option value=\"".$file.'">'.$file."</option>" ?>
                      </select>
                      <input class="btn btn-info" type="submit" value="选择">
                    </div>
                </div>
            </div>
        </form>
        <div class="container mb-3">
        <form action="rulesconf.php" method="post">
            <div class="container text-center justify-content-md-center">
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                      <?php if(!empty($file)) echo "<h5>$rulePath</h5>" ?>
                    </div>
                </div>
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                      <textarea class="form-control" name="newrulescfg" rows="16"><?php if (!empty($strRules))echo $strRules; else echo $strNewRules; ?></textarea>
                    </div>
                </div>
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                        <input class="btn btn-info" type="submit" value="💾 保存规则">
                    </div>
                </div>
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                      <?php if(!empty($strNewRules)) echo "<h5>RULES SUCCESSFULLY SAVED</h5>" ?>
                    </div>
                </div>
            </div>
        </form>
        </div>
    </div>
  </body>
</html>
