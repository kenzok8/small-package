<?php
include '../cfg.php';
$neko_log_path="$neko_dir/tmp/log.txt";
$neko_bin_log_path="$neko_dir/tmp/neko_log.txt";
$host_now=$_SERVER['SERVER_NAME'];

if(isset($_GET['data'])){
    $dt = $_GET['data'];
    if ($dt == 'neko') echo shell_exec("cat $neko_log_path");
    else if($dt == 'bin') echo shell_exec("cat $neko_bin_log_path | awk -F'[\"T.= ]' '{print \"[ \" $4 \" ] \" toupper($8) \" :\", substr($0,index($0,$11))}' | sed 's/.$//'");
    else if($dt == 'neko_ver') echo exec("$neko_dir/core/neko -v");
    else if($dt == 'core_ver') echo exec("$neko_bin -v | head -1 | awk '{print $5 \" \" $3}'");
    else if($dt == 'url_dash'){
        header("Content-type: application/json; charset=utf-8");
        $yacd = exec (" curl -m 5 -f -s $host_now/nekobox/dashboard.php | grep 'href=\"h' | cut -d '\"' -f6 | head -1");
        $zash = exec (" curl -m 5 -f -s $host_now/nekobox/dashboard.php | grep 'href=\"h' | cut -d '\"' -f6 | tail -1");
        echo "{\n";
        echo "  \"yacd\":\"$yacd\",\n";
        echo "  \"zash\":\"$zash\"\n";
        echo "}";
    }
}
?>
