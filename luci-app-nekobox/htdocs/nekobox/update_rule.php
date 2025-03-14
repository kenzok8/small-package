<?php
ini_set('memory_limit', '128M');
ini_set('max_execution_time', 300);

$logMessages = [];

function logMessage($filename, $message) {
    global $logMessages;
    $timestamp = date('H:i:s');
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
                logMessage(basename($download['destination']), "Start downloadin");
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
                        logMessage(basename($info['destination']), "Download successful");
                    } else {
                        logMessage(basename($info['destination']), "Save failed");
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
                    logMessage(basename($info['destination']), "Download failed (HTTP $httpCode)");
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

echo "Start updating the rule set...\n";
$urls = [
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/ads.srs" => "/etc/neko/rules/ads.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/ai.srs" => "/etc/neko/rules/ai.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/apple-cn.srs" => "/etc/neko/rules/apple-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/applications.srs" => "/etc/neko/rules/applications.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/cn.srs" => "/etc/neko/rules/cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/cnip.srs" => "/etc/neko/rules/cnip.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/disney.srs" => "/etc/neko/rules/disney.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/fakeip-filter.srs" => "/etc/neko/rules/fakeip-filter.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/games-cn.srs" => "/etc/neko/rules/games-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/google-cn.srs" => "/etc/neko/rules/google-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/microsoft-cn.srs" => "/etc/neko/rules/microsoft-cn.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/netflix.srs" => "/etc/neko/rules/netflix.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/networktest.srs" => "/etc/neko/rules/networktest.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/private.srs" => "/etc/neko/rules/private.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/privateip.srs" => "/etc/neko/rules/privateip.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/proxy.srs" => "/etc/neko/rules/proxy.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/telegramip.srs" => "/etc/neko/rules/telegramip.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/tiktok.srs" => "/etc/neko/rules/tiktok.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/youtube.srs" => "/etc/neko/rules/youtube.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/geosite/tiktok.srs" => "/etc/neko/rules/geosite/tiktok.srs",
    "https://raw.githubusercontent.com/Thaolga/neko/luci-app-neko/nekobox/rules/geosite/netflix.srs" => "/etc/neko/rules/geosite/netflix.srs"
];

$downloader = new MultiDownloader(8);

foreach ($urls as $url => $destination) {
    $downloader->addDownload($url, $destination);
}

$downloader->start();

echo "\nRule set update completed！\n\n";

foreach ($logMessages as $message) {
    echo $message . "\n";
}
?>