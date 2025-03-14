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
    echo "Latest version: $fixed_version\n";
    exit;
}

exec("wget -O '$temp_file' '$download_url'", $output, $return_var);
if ($return_var !== 0) {
    die("Download failed");
}

if (!file_exists($temp_file)) {
    die("The downloaded file does not exist");
}

echo "Start extracting the file...\n";
exec("tar -xf '$temp_file' -C '$install_path'", $output, $return_var);
if ($return_var !== 0) {
    echo "Decompression failed, error message: " . implode("\n", $output);
    die("Decompression failed");
}
echo "Extraction successful \n";

exec("chown -R root:root '$install_path' 2>&1", $output, $return_var);
if ($return_var !== 0) {
    echo "Failed to change file owner, error message: " . implode("\n", $output) . "\n";
    die();
}
echo "The file owner has been changed to root.\n";

writeVersionToFile($fixed_version);
echo "Update complete! Current version: $fixed_version";

unlink($temp_file);

?>
