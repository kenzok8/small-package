<?php
ini_set('memory_limit', '128M');
ini_set('max_execution_time', 300);

$logMessages = [];

function logMessage($filename, $message) {
    global $logMessages;
    $timestamp = date('H:i:s', strtotime('+8 hours'));
    $logMessages[] = "[$timestamp] $filename: $message";
}

class MultiDownloader {
    private $urls = [];
    private $maxConcurrent;
    private $running = false;
    private $mh;
    private $handles = [];
    private $retries = [];
    private $maxRetries = 3;
    
    public function __construct($maxConcurrent = 8) {
        $this->maxConcurrent = $maxConcurrent;
        $this->mh = curl_multi_init();
    }
    
    public function addDownload($url, $destination) {
        $this->urls[] = [
            'url' => $url,
            'destination' => $destination,
            'attempts' => 0
        ];
    }
    
    private function createHandle($url, $destination) {
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_TIMEOUT => 30,
            CURLOPT_SSL_VERIFYPEER => false,
            CURLOPT_USERAGENT => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        ]);
        
        $this->handles[(int)$ch] = [
            'ch' => $ch,
            'url' => $url,
            'destination' => $destination
        ];
        
        curl_multi_add_handle($this->mh, $ch);
        return $ch;
    }
    
    public function start() {
        $urlCount = count($this->urls);
        $processed = 0;
        $batch = 0;
        
        while ($processed < $urlCount) {
            while (count($this->handles) < $this->maxConcurrent && !empty($this->urls)) {
                $download = array_shift($this->urls);
                $dir = dirname($download['destination']);
                if (!is_dir($dir)) {
                    mkdir($dir, 0755, true);
                }
                logMessage(basename($download['destination']), "开始下载");
                $this->createHandle($download['url'], $download['destination']);
            }
            
            do {
                $status = curl_multi_exec($this->mh, $running);
            } while ($status === CURLM_CALL_MULTI_PERFORM);
            
            if ($running) {
                curl_multi_select($this->mh);
            }
            
            while ($completed = curl_multi_info_read($this->mh)) {
                $ch = $completed['handle'];
                $chId = (int)$ch;
                $info = $this->handles[$chId];
                
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                $content = curl_multi_getcontent($ch);
                
                if ($httpCode === 200 && $content !== false) {
                    if (file_put_contents($info['destination'], $content) !== false) {
                        logMessage(basename($info['destination']), "下载成功");
                    } else {
                        logMessage(basename($info['destination']), "保存失败");
                        if (!isset($this->retries[$info['url']]) || $this->retries[$info['url']] < $this->maxRetries) {
                            $this->retries[$info['url']] = isset($this->retries[$info['url']]) ? $this->retries[$info['url']] + 1 : 1;
                            $this->urls[] = [
                                'url' => $info['url'],
                                'destination' => $info['destination'],
                                'attempts' => $this->retries[$info['url']]
                            ];
                        }
                    }
                } else {
                    logMessage(basename($info['destination']), "下载失败 (HTTP $httpCode)");
                    if (!isset($this->retries[$info['url']]) || $this->retries[$info['url']] < $this->maxRetries) {
                        $this->retries[$info['url']] = isset($this->retries[$info['url']]) ? $this->retries[$info['url']] + 1 : 1;
                        $this->urls[] = [
                            'url' => $info['url'],
                            'destination' => $info['destination'],
                            'attempts' => $this->retries[$info['url']]
                        ];
                    }
                }
                
                curl_multi_remove_handle($this->mh, $ch);
                curl_close($ch);
                unset($this->handles[$chId]);
                $processed++;
            }
        }
    }
    
    public function __destruct() {
        curl_multi_close($this->mh);
    }
}

echo "开始更新规则集...\n";
$urls = [
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/ads.srs" => "/www/nekobox/rules/ads.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/ai.srs" => "/www/nekobox/rules/ai.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/apple-cn.srs" => "/www/nekobox/rules/apple-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/applications.srs" => "/www/nekobox/rules/applications.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/cn.srs" => "/www/nekobox/rules/cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/cnip.srs" => "/www/nekobox/rules/cnip.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/disney.srs" => "/www/nekobox/rules/disney.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/fakeip-filter.srs" => "/www/nekobox/rules/fakeip-filter.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/games-cn.srs" => "/www/nekobox/rules/games-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/google-cn.srs" => "/www/nekobox/rules/google-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/microsoft-cn.srs" => "/www/nekobox/rules/microsoft-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/netflix.srs" => "/www/nekobox/rules/netflix.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/networktest.srs" => "/www/nekobox/rules/networktest.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/private.srs" => "/www/nekobox/rules/private.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/privateip.srs" => "/www/nekobox/rules/privateip.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/proxy.srs" => "/www/nekobox/rules/proxy.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/telegramip.srs" => "/www/nekobox/rules/telegramip.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/tiktok.srs" => "/www/nekobox/rules/tiktok.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/youtube.srs" => "/www/nekobox/rules/youtube.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/geosite/tiktok.srs" => "/www/nekobox/rules/geosite/tiktok.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/geosite/netflix.srs" => "/www/nekobox/rules/geosite/netflix.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite/geosite-cn.srs" => "/www/nekobox/geosite/geosite-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/ads.srs" => "/www/nekobox/ads.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/cache.db" => "/www/nekobox/cache.db",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/cn.srs" => "/www/nekobox/cn.srs", 
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/cnip.srs" => "/www/nekobox/cnip.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geoip-apple.srs" => "/www/nekobox/geoip-apple.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geoip-cn.srs" => "/www/nekobox/geoip-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geoip-google.srs" => "/www/nekobox/geoip-google.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geoip-netflix.srs" => "/www/nekobox/geoip-netflix.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geoip-telegram.srs" => "/www/nekobox/geoip-telegram.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geoip-tiktok.srs" => "/www/nekobox/geoip-tiktok.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-apple.srs" => "/www/nekobox/geosite-apple.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-bilibili.srs" => "/www/nekobox/geosite-bilibili.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-cn.srs" => "/www/nekobox/geosite/geosite-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-disney.srs" => "/www/nekobox/geosite-disney.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-geolocation-!cn.srs" => "/www/nekobox/geosite-geolocation-!cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-github.srs" => "/www/nekobox/geosite-github.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-google.srs" => "/www/nekobox/geosite-google.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-microsoft.srs" => "/www/nekobox/geosite-microsoft.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-netflix.srs" => "/www/nekobox/geosite-netflix.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-openai.srs" => "/www/nekobox/geosite-openai.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-telegram.srs" => "/www/nekobox/geosite-telegram.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-tiktok.srs" => "/www/nekobox/geosite-tiktok.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite-youtube.srs" => "/www/nekobox/geosite-youtube.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/geosite.db" => "/www/nekobox/geosite.db"
];

$downloader = new MultiDownloader(8);

foreach ($urls as $url => $destination) {
    $downloader->addDownload($url, $destination);
}

$downloader->start();

echo "\n规则集更新完成！\n\n";

foreach ($logMessages as $message) {
    echo $message . "\n";
}
?>