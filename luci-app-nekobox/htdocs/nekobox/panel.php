<?php

include './cfg.php';

$neko_cfg['ctrl_host'] = $_SERVER['SERVER_NAME'];

$command = "cat $selected_config | grep external-c | awk '{print $2}' | cut -d: -f2";
$port_output = shell_exec($command);

if ($port_output === null) {
    $neko_cfg['ctrl_port'] = 'default_port'; 
} else {
    $neko_cfg['ctrl_port'] = trim($port_output);
}

$yacd_link = $neko_cfg['ctrl_host'] . ':' . $neko_cfg['ctrl_port'] . '/ui/meta?hostname=' . $neko_cfg['ctrl_host'] . '&port=' . $neko_cfg['ctrl_port'] . '&secret=' . $neko_cfg['secret'];
$zash_link = $neko_cfg['ctrl_host'] . ':' . $neko_cfg['ctrl_port'] . '/ui/zashboard?hostname=' . $neko_cfg['ctrl_host'] . '&port=' . $neko_cfg['ctrl_port'] . '&secret=' . $neko_cfg['secret'];
$meta_link = $neko_cfg['ctrl_host'] . ':' . $neko_cfg['ctrl_port'] . '/ui/metacubexd?hostname=' . $neko_cfg['ctrl_host'] . '&port=' . $neko_cfg['ctrl_port'] . '&secret=' . $neko_cfg['secret'];
$dash_link = $neko_cfg['ctrl_host'] . ':' . $neko_cfg['ctrl_port'] . '/ui/dashboard?hostname=' . $neko_cfg['ctrl_host'] . '&port=' . $neko_cfg['ctrl_port'] . '&secret=' . $neko_cfg['secret'];

?>
<title>Panel - Nekobox</title>
<link rel="icon" href="./assets/img/nekobox.png">
<?php include './ping.php'; ?>
<style>
#iframeMeta {
    width: 100%;
    height: 78vh;
    transition: height 0.3s ease;
}

@media (max-width: 768px) {
    #iframeMeta {
        height: 68vh;
    }
}

body, html {
    height: 100%;
}

body {
    display: flex;
    flex-direction: column;
}

main {
    flex: 1;
}

footer {
    margin-top: 8px !important;
    padding: 8px 0;
}
</style>
<div  id="mainNavbar" class="container-sm container-bg text-center mt-4">
<?php include 'navbar.php'; ?>
<main class="container-fluid text-left px-0 px-sm-3 px-md-4 p-3">
    <iframe id="iframeMeta" class="w-100" src="http://<?=$zash_link?>" title="zash" allowfullscreen style="border-radius: 10px;"></iframe>
    <div class="mt-3 mb-0">
        <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#panelModal" data-translate="panel_settings">Panel Settings</button>
    </div>
</main>
<div class="modal fade" id="panelModal" tabindex="-1" aria-labelledby="panelModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="panelModalLabel" data-translate="select_panel">Select Panel</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div class="mb-3">
                    <label for="panelSelect" class="form-label" data-translate="select_panel">Select Panel</label>
                    <select id="panelSelect" class="form-select" onchange="changeIframe(this.value)">
                        <option value="http://<?=$zash_link?>"  data-translate="zash_panel">Zash</option>
                        <option value="http://<?=$yacd_link?>"  data-translate="yacd_panel">YACD</option>
                        <option value="http://<?=$dash_link?>"  data-translate="dash_panel">Dash</option>
                        <option value="http://<?=$meta_link?>" data-translate="metacubexd_panel">MetaCubeXD</option>
                    </select>
                </div>
                <div class="d-flex justify-content-around flex-wrap gap-2">
                    <a class="btn btn-primary btn-sm text-white" target="_blank" href="http://<?=$yacd_link?>"  data-translate="yacd_panel">YACD</a>
                    <a class="btn btn-success btn-sm text-white" target="_blank" href="http://<?=$dash_link?>"  data-translate="dash_panel">Dash</a>
                    <a class="btn btn-warning btn-sm text-white" target="_blank" href="http://<?=$meta_link?>" data-translate="metacubexd_panel">MetaCubeXD</a>
                    <a class="btn btn-info btn-sm text-white" target="_blank" href="http://<?=$zash_link?>"  data-translate="zash_panel">Zash</a>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close">Close</button>
            </div>
        </div>
    </div>
</div>
<script>
    const panelSelect = document.getElementById('panelSelect');
    const iframeMeta = document.getElementById('iframeMeta');
    const savedPanel = localStorage.getItem('selectedPanel');

    if (savedPanel) {
        iframeMeta.src = savedPanel; 
        panelSelect.value = savedPanel; 
    }

    panelSelect.addEventListener('change', function() {
        iframeMeta.src = panelSelect.value;          
        localStorage.setItem('selectedPanel', panelSelect.value);
    });

    document.getElementById('confirmPanelSelection').addEventListener('click', function() {
        var selectedPanel = panelSelect.value;
        iframeMeta.src = selectedPanel;
        var myModal = new bootstrap.Modal(document.getElementById('panelModal'));
        myModal.hide();
        localStorage.setItem('selectedPanel', selectedPanel);
    });
</script>

<script>
document.addEventListener("DOMContentLoaded", function () {
    const iframe = document.getElementById('iframeMeta');
    const buttonContainer = document.querySelector('.mt-3.mb-0');
    const footer = document.querySelector('footer');

    function adjustIframeHeight() {
        const viewportHeight = window.innerHeight;
        const buttonHeight = buttonContainer ? buttonContainer.offsetHeight : 0;
        const footerHeight = footer ? footer.offsetHeight : 0;
        const extraMargin = 40;

        const availableHeight = viewportHeight - buttonHeight - footerHeight - extraMargin;
        
        const isSmallScreen = window.innerWidth <= 768;
        const baseHeight = isSmallScreen ? viewportHeight * 0.68 : viewportHeight * 0.78;
        
        const finalHeight = Math.min(baseHeight, availableHeight);

        iframe.style.height = finalHeight + 'px';
    }

    adjustIframeHeight();
    window.addEventListener('resize', adjustIframeHeight);
});
</script>