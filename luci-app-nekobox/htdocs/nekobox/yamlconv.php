<?php

include './cfg.php';
$tmpdata = $neko_www."/lib/tmp.txt";
if(isset($_POST['url'])){
    $dt = $_POST['url'];
    $basebuff = parse_url($dt);
    $tmp = $basebuff['scheme']."://";
    if ($basebuff['scheme'] == "vless") parseUrl($basebuff,$tmpdata);
    else if ($basebuff['scheme'] == "vmess") parseVmess($basebuff,$tmpdata);
    else if ($basebuff['scheme'] == "trojan") parseUrl($basebuff,$tmpdata);
    else if ($basebuff['scheme'] == "hysteria2") parseUrl($basebuff,$tmpdata);
    else if ($basebuff['scheme'] == "ss") parseUrl($basebuff,$tmpdata);
    else exec("echo \"ERROR, PLEASE CHECK YOUR URL!\ntrojan://...\nhysteria2://...\nvless://...\nss://...\nvmess://...\nYOU ENTERED : $tmp\" > $tmpdata");
}
function parseVmess($base,$tmpdata){
    $decoded = base64_decode($base['host']);
    $urlparsed = array();
    $arrjs = json_decode($decoded,true);
    if (!empty($arrjs['v'])){
        $urlparsed['cfgtype'] = isset($base['scheme']) ? $base['scheme'] : '';
        $urlparsed['name'] = isset($arrjs['ps']) ? $arrjs['ps'] : '';
        $urlparsed['host'] = isset($arrjs['add']) ? $arrjs['add'] : '';
        $urlparsed['port'] = isset($arrjs['port']) ? $arrjs['port'] : '';
        $urlparsed['uuid'] = isset($arrjs['id']) ? $arrjs['id'] : '';
        $urlparsed['alterId'] = isset($arrjs['aid']) ? $arrjs['aid'] : '';
        $urlparsed['type'] = isset($arrjs['net']) ? $arrjs['net'] : '';
        $urlparsed['path'] = isset($arrjs['path']) ? $arrjs['path'] : '';
        $urlparsed['security'] = isset($arrjs['type']) ? $arrjs['type'] : '';
        $urlparsed['sni'] = isset($arrjs['host']) ? $arrjs['host'] : '';
        $urlparsed['tls'] = isset($arrjs['tls']) ? $arrjs['tls'] : '';
        printcfg($urlparsed,$tmpdata);
    } else exec("echo \"DECODING FAILED!\nPLEASE CHECK YOUR URL!\" > $tmpdata");
}
function parseUrl($basebuff,$tmpdata){
    $urlparsed = array();
    $querybuff = array();
    $urlparsed['cfgtype'] = isset($basebuff['scheme']) ? $basebuff['scheme'] : '';
	$urlparsed['name'] = isset($basebuff['fragment']) ? $basebuff['fragment'] : '';
	$urlparsed['host'] = isset($basebuff['host']) ? $basebuff['host'] : '';
	$urlparsed['port'] = isset($basebuff['port']) ? $basebuff['port'] : '';

    if($urlparsed['cfgtype'] == "ss"){
        $urlparsed['uuid'] = isset($basebuff['user']) ? $basebuff['user'] : '';
        $basedata = explode(":", base64_decode($urlparsed['uuid']));
        $urlparsed['cipher'] = $basedata[0];
        $urlparsed['uuid'] = $basedata[1];
        
    }else $urlparsed['uuid'] = isset($basebuff['user']) ? $basebuff['user'] : '';

    if($urlparsed['cfgtype'] == "ss"){
        $tmpbuff = array();
        $tmpstr = "";
        $tmpquery = isset($basebuff['query']) ? $basebuff['query'] : '';
        $tmpquery2 = explode(";", $tmpquery);
        for($x = 0; $x < count($tmpquery2); $x++){
            $tmpstr .= $tmpquery2[$x]."&";
        }
        parse_str($tmpstr,$querybuff);
        $urlparsed['mux'] = isset($querybuff['mux']) ? $querybuff['mux'] : '';
        $urlparsed['host2'] = isset($querybuff['host2']) ? $querybuff['host2'] : '';
    }else parse_str($basebuff['query'],$querybuff);

    $urlparsed['type'] = isset($querybuff['type']) ? $querybuff['type'] : '';
	$urlparsed['path'] = isset($querybuff['path']) ? $querybuff['path'] : '';
    $urlparsed['mode'] = isset($querybuff['mode']) ? $querybuff['mode'] : '';
    $urlparsed['plugin'] = isset($querybuff['plugin']) ? $querybuff['plugin'] : '';
    $urlparsed['security'] = isset($querybuff['security']) ? $querybuff['security'] : '';
    $urlparsed['encryption'] = isset($querybuff['encryption']) ? $querybuff['encryption'] : '';
    $urlparsed['serviceName'] = isset($querybuff['serviceName']) ? $querybuff['serviceName'] : '';
    $urlparsed['sni'] = isset($querybuff['sni']) ? $querybuff['sni'] : '';
    printcfg($urlparsed,$tmpdata);
    //print_r ($basebuff);
    //print_r ($querybuff);
    //print_r ($urlparsed);
}
function printcfg($data,$tmpdata){
    $outcfg="";
    if ($data['cfgtype'] == "vless"){
        if(!empty($data['name'])) $outcfg .= "- name: ".$data['name']."\n";
        else $outcfg .= "- name: VLESS\n";
        $outcfg .= "  type: ".$data['cfgtype']."\n";
        $outcfg .= "  server: ".$data['host']."\n";
        $outcfg .= "  port: ".$data['port']."\n";
        $outcfg .= "  uuid: ".$data['uuid']."\n";
        $outcfg .= "  cipher: auto\n";
        $outcfg .= "  tls: true\n";
        $outcfg .= "  alterId: 0\n";
        $outcfg .= "  flow: xtls-rprx-direct\n";
        if(!empty($data['sni'])) $outcfg .= "  servername: ".$data['sni']."\n";
        else $outcfg .= "  servername: ".$data['host']."\n";
        if ($data['type'] == "ws"){
            $outcfg .= "  network: ".$data['type']."\n";
            $outcfg .= "  ws-opts: \n";
            $outcfg .= "   path: ".$data['path']."\n";
            $outcfg .= "   Headers: \n";
            $outcfg .= "      Host: ".$data['host']."\n";
        }
        else if($data['type'] == "grpc"){
            $outcfg .= "  network: ".$data['type']."\n";
            $outcfg .= "  grpc-opts: \n";
            $outcfg .= "   grpc-service-name: ".$data['serviceName']."\n";
        }
        $outcfg .= "  udp: true\n";
        $outcfg .= "  skip-cert-verify: true \n";
        exec("echo \"$outcfg\" > $tmpdata");
        //echo $outcfg;
    }
    else if ($data['cfgtype'] == "trojan" ){
        if(!empty($data['name'])) $outcfg .= "- name: ".$data['name']."\n";
        else $outcfg .= "- name: TROJAN\n";
        $outcfg .= "  type: ".$data['cfgtype']."\n";
        $outcfg .= "  server: ".$data['host']."\n";
        $outcfg .= "  port: ".$data['port']."\n";
        $outcfg .= "  password: ".$data['uuid']."\n";
        if(!empty($data['sni'])) $outcfg .= "  sni: ".$data['sni']."\n";
        else $outcfg .= "  sni: ".$data['host']."\n";
        if ($data['type'] == "ws"){
            $outcfg .= "  network: ".$data['type']."\n";
            $outcfg .= "  ws-opts: \n";
            $outcfg .= "   path: ".$data['path']."\n";
            $outcfg .= "   Headers: \n";
            $outcfg .= "      Host: ".$data['host']."\n";
        }
        else if($data['type'] == "grpc"){
            $outcfg .= "  network: ".$data['type']."\n";
            $outcfg .= "  grpc-opts: \n";
            $outcfg .= "   grpc-service-name: ".$data['serviceName']."\n";
        }
        $outcfg .= "  udp: true\n";
        $outcfg .= "  skip-cert-verify: true \n";
        exec("echo \"$outcfg\" > $tmpdata");
        //echo $outcfg;
       }
    else if ($data['cfgtype'] == "hysteria2") {
    if (!empty($data['name'])) $outcfg .= "- name: " . $data['name'] . "\n";
        else $outcfg .= "- name: HYSTERIA2\n";
        $outcfg .= "  server: " . $data['host'] . "\n";
        $outcfg .= "  port: " . $data['port'] . "\n";
        $outcfg .= "  udp: " . (isset($data['udp']) ? ($data['udp'] ? "true" : "false") : "false") . "\n";
        $outcfg .= "  skip-cert-verify: " . (isset($data['skip-cert-verify']) ? ($data['skip-cert-verify'] ? "true" : "false") : "false") . "\n";
    
        $outcfg .= "  sni: " . (isset($data['sni']) && !empty($data['sni']) ? $data['sni'] : $data['host']) . "\n";
        $outcfg .= "  type: hysteria2\n";
        $outcfg .= "  password: " . (isset($data['uuid']) ? $data['uuid'] : '') . "\n"; 
        exec("echo \"$outcfg\" > $tmpdata");
        //echo $outcfg;
    }
    else if ($data['cfgtype'] == "ss" ){
        if(!empty($data['name'])) $outcfg .= "- name: ".$data['name']."\n";
        else $outcfg .= "- name: SHADOWSOCKS\n";
        $outcfg .= "  type: ".$data['cfgtype']."\n";
        $outcfg .= "  server: ".$data['host']."\n";
        $outcfg .= "  port: ".$data['port']."\n";
        $outcfg .= "  cipher: ".$data['cipher']."\n";
        $outcfg .= "  password: ".$data['uuid']."\n";
        if ($data['plugin'] == "v2ray-plugin" | $data['plugin'] == "xray-plugin"){
            $outcfg .= "  plugin: ".$data['plugin']."\n";
            $outcfg .= "  plugin-opts: \n";
            $outcfg .= "   mode: websocket\n";
            $outcfg .= "   # path: ".$data['path']."\n";
            $outcfg .= "   mux: ".$data['mux']."\n";
            $outcfg .= "   # tls: true \n";
            $outcfg .= "   # skip-cert-verify: true \n";
            $outcfg .= "   # headers: \n";
            $outcfg .= "   #    custom: value\n";
        }
        else if($data['plugin'] == "obfs"){
            $outcfg .= "  plugin: ".$data['plugin']."\n";
            $outcfg .= "  plugin-opts: \n";
            $outcfg .= "   mode: tls\n";
            $outcfg .= "   # host: ".$data['host2']."\n";
        }
        $outcfg .= "  udp: true\n";
        $outcfg .= "  skip-cert-verify: true \n";
        exec("echo \"$outcfg\" > $tmpdata");
        //echo $outcfg;
    }
    if ($data['cfgtype'] == "vmess"){
        if(!empty($data['name'])) $outcfg .= "- name: ".$data['name']."\n";
        else $outcfg .= "- name: VMESS\n";
        $outcfg .= "  type: ".$data['cfgtype']."\n";
        $outcfg .= "  server: ".$data['host']."\n";
        $outcfg .= "  port: ".$data['port']."\n";
        $outcfg .= "  uuid: ".$data['uuid']."\n";
        $outcfg .= "  alterId: ".$data['alterId']."\n";
        $outcfg .= "  cipher: auto\n";
        if($data['tls']== "tls") $outcfg .= "  tls: true\n";
        else $outcfg .= "  tls: false\n";
        if(!empty($data['sni'])) $outcfg .= "  servername: ".$data['sni']."\n";
        else $outcfg .= "  servername: ".$data['host']."\n";
        $outcfg .= "  network: ".$data['type']."\n";
        if ($data['type'] == "ws"){
            $outcfg .= "  ws-opts: \n";
            $outcfg .= "   path: ".$data['path']."\n";
            $outcfg .= "   Headers: \n";
            $outcfg .= "      Host: ".$data['sni']."\n";
        }
        else if($data['type'] == "grpc"){
            $outcfg .= "  grpc-opts: \n";
            $outcfg .= "   grpc-service-name: ".$data['serviceName']."\n";
        }
        else if($data['type'] == "h2"){
            $outcfg .= "  h2-opts: \n";
            $outcfg .= "   host: \n";
            $outcfg .= "     - google.com \n";
            $outcfg .= "     - bing.com \n";
            $outcfg .= "   path: ".$data['path']."\n";
        }
        else if($data['type'] == "http"){
            $outcfg .= "  # http-opts: \n";
            $outcfg .= "  #   method: \"GET\"\n";
            $outcfg .= "  #   path: \n";
            $outcfg .= "  #     - '/'\n";
            $outcfg .= "  #   headers: \n";
            $outcfg .= "  #     Connection: \n";
            $outcfg .= "  #       - keep-alive\n";
        }
        $outcfg .= "  udp: true\n";
        $outcfg .= "  skip-cert-verify: true \n";
        exec("echo \"$outcfg\" > $tmpdata");
        //echo $outcfg;
    }
}
$strdata = shell_exec("cat $tmpdata");
shell_exec("rm -f $tmpdata");
?>
<!doctype html>
<html lang="en" data-bs-theme="<?php echo substr($neko_theme,0,-4) ?>">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>yamlconv - Neko</title>
    <link rel="icon" href="./assets/img/favicon.png">
    <link href="./assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="./assets/css/custom.css" rel="stylesheet">
    <link href="./assets/theme/<?php echo $neko_theme ?>" rel="stylesheet">
    <script type="text/javascript" src="./assets/js/feather.min.js"></script>
    <script type="text/javascript" src="./assets/js/jquery-2.1.3.min.js"></script>
  </head>
  <body class="container-bg">
    <div class="container text-center justify-content-md-center mb-3"></br>
        <form action="yamlconv.php" method="post">
            <div class="container text-center justify-content-md-center">
                <div class="row justify-content-md-center">
                    <div class="col input-group mb-3 justify-content-md-center">
                        <input type="text" class="form-control" name="url" placeholder="贴在这里">
                        <input class="btn btn-info col-2" type="submit" value="选择">
                    </div>
                </div>
            </div>
        </form>
        <div class="container mb-3">
            <textarea name="dt" class="form-control" rows="16"><?php echo $strdata ?></textarea>
        </div>
        <div>
            <a>支援 : </br>TROJAN(GFW, WS TLS/NTLS, GRPC)</br>HYSTERIA2(WS TLS/NTLS, HTTP, H2, GRPC)</br>VMESS(WS TLS/NTLS, HTTP, H2, GRPC)</br>VLESS(WS TLS/NTLS, XTLS, GRPC)</br>SS(DIRECT, OBFS, V2RAY/XRAY-PLUGIN)</a>
        </div>
    </div>
  </body>
</html>