<?php
ob_start();
include './cfg.php';
$subscriptionPath = '/etc/neko/proxy_provider/';
$subscriptionFile = $subscriptionPath . 'subscriptions.json';
$clashFile = $subscriptionPath . 'clash_config.yaml';

$message = "";
$decodedContent = ""; 
$subscriptions = [];

if (!file_exists($subscriptionPath)) {
    mkdir($subscriptionPath, 0755, true);
}

if (!file_exists($subscriptionFile)) {
    file_put_contents($subscriptionFile, json_encode([]));
}

$subscriptions = json_decode(file_get_contents($subscriptionFile), true);
if (!$subscriptions) {
    for ($i = 0; $i < 6; $i++) {
        $subscriptions[$i] = [
            'url' => '',
            'file_name' => "subscription_{$i}.yaml",
        ];
    }
}

if (isset($_POST['update'])) {
    $index = intval($_POST['index']);
    $url = $_POST['subscription_url'] ?? '';
    $customFileName = $_POST['custom_file_name'] ?? "subscription_{$index}.yaml";

    $subscriptions[$index]['url'] = $url;
    $subscriptions[$index]['file_name'] = $customFileName;

    if (!empty($url)) {
        $finalPath = $subscriptionPath . $customFileName;
        $command = "curl -fsSL -o {$finalPath} {$url}";
        exec($command . ' 2>&1', $output, $return_var);

        if ($return_var === 0) {
            $message = "订阅链接 {$url} 更新成功！文件已保存到: {$finalPath}";
        } else {
            $message = "配置更新失败！错误信息: " . implode("\n", $output);
        }
    } else {
        $message = "第" . ($index + 1) . "个订阅链接为空！";
    }

    file_put_contents($subscriptionFile, json_encode($subscriptions));
}

?>
<!DOCTYPE html>
<html lang="zh-CN" data-bs-theme="<?php echo substr($neko_theme, 0, -4) ?>">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mihomo订阅程序</title>
    
    <link rel="icon" href="./assets/img/favicon.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
</head>
<body>
    <div class="container mt-4">
        <h1 class="text-center">Mihomo订阅</h1>
        <h6 class="text-center">Mihomo订阅支持所有格式《Base64/clash格式/节点链接》</h6>

        <?php if (isset($message) && $message): ?>
            <div class="alert alert-info">
                <?php echo nl2br(htmlspecialchars($message)); ?>
            </div>
        <?php endif; ?>

<?php if (isset($subscriptions) && is_array($subscriptions)): ?>
    <div class="row">
        <?php for ($i = 0; $i < 6; $i++): ?>
            <div class="col-md-4 mb-3">
                <form method="post" class="card">
                    <div class="card-body">
                        <div class="form-group text-center">
                            <h5 for="subscription_url_<?php echo $i; ?>" class="mb-2">订阅链接 <?php echo ($i + 1); ?></h5>
                            <input type="text" name="subscription_url" id="subscription_url_<?php echo $i; ?>" value="<?php echo htmlspecialchars($subscriptions[$i]['url'] ?? ''); ?>" required class="form-control">
                        </div>
                        <div class="form-group text-center">
                            <label for="custom_file_name_<?php echo $i; ?>">自定义文件名</label>
                            <input type="text" name="custom_file_name" id="custom_file_name_<?php echo $i; ?>" value="subscription_<?php echo ($i + 1); ?>.yaml" class="form-control">
                        </div>
                        <input type="hidden" name="index" value="<?php echo $i; ?>">
                        <div class="text-center mt-3"> 
                            <button type="submit" name="update" class="btn btn-info">🔄 更新订阅 <?php echo ($i + 1); ?></button>
                        </div>
                    </div>
                </form>
            </div>

            <?php if (($i + 1) % 3 == 0 && $i < 5): ?>
                </div><div class="row">
            <?php endif; ?>
            
        <?php endfor; ?>
    </div>
<?php else: ?>
    <p>未找到订阅信息。</p>
<?php endif; ?>
    </div>

    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
</body>
</html>
