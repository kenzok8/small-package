<?php

ini_set('memory_limit', '128M');

$fixed_version = "v0.3.8";

function getUiVersion() {
    $versionFile = '/etc/neko/ui/meta/version.txt';

    if (file_exists($versionFile)) {
        return trim(file_get_contents($versionFile));
    } else {
        return null;
    }
}

function writeVersionToFile($version) {
    $versionFile = '/etc/neko/ui/meta/version.txt';
    file_put_contents($versionFile, $version);
}

$download_url = "https://github.com/Thaolga/neko/releases/download/$fixed_version/meta.tar";
$install_path = '/etc/neko/ui/meta';
$temp_file = '/tmp/meta-dist.tar';

if (!is_dir($install_path)) {
    mkdir($install_path, 0755, true);
}

$current_version = getUiVersion();

if (isset($_GET['check_version'])) {
    echo "最新版本: $fixed_version\n";
    exit;
}

exec("wget -O '$temp_file' '$download_url'", $output, $return_var);
if ($return_var !== 0) {
    die("下载失败！");
}

if (!file_exists($temp_file)) {
    die("下载的文件不存在！");
}

echo "开始解压文件...\n";
exec("tar -xf '$temp_file' -C '$install_path' --overwrite", $output, $return_var);
if ($return_var !== 0) {
    echo "解压失败，错误信息: " . implode("\n", $output);
    die("解压失败！");
}
echo "解压成功！\n";

exec("chown -R root:root '$install_path' 2>&1", $output, $return_var);
if ($return_var !== 0) {
    echo "更改文件拥有者失败，错误信息: " . implode("\n", $output) . "\n";
    die();
}
echo "文件拥有者已更改为 root。\n";

writeVersionToFile($fixed_version);
echo "更新完成！当前版本: $fixed_version\n";

unlink($temp_file);

?>
