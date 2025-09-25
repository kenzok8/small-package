<nav class="navbar navbar-expand-lg sticky-top">
    <div class="container-sm container px-1 px-sm-3 px-md-4">
        <a class="navbar-brand d-flex align-items-center" href="#">
            <?= $iconHtml ?>
            <span id="dynamicTitle" style="color: var(--accent-color); letter-spacing: 1px; cursor: pointer;" onclick="window.open('<?= $titleLink ?>', '_blank')"><?= htmlspecialchars($title) ?></span>
        </a>
        <button class="navbar-toggler" data-bs-toggle="collapse" data-bs-target="#navbarContent">
            <i class="bi bi-list" style="color: var(--accent-color); font-size: 1.8rem;"></i>
        </button>
        <div class="collapse navbar-collapse" id="navbarContent">
            <ul class="navbar-nav me-auto mb-2 mb-lg-0" style="font-size: 18px;">
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'index.php' ? 'active' : '' ?>" href="./index.php">
                        <i class="bi bi-house-door"></i>
                        <span data-translate="home">Home</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'panel.php' ? 'active' : '' ?>" href="./panel.php">
                        <i class="bi bi-bar-chart"></i>
                        <span data-translate="panel">Panel</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'singbox.php' ? 'active' : '' ?>" href="./singbox.php">
                        <i class="bi bi-box"></i>
                        <span data-translate="document">Document</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $current == 'settings.php' ? 'active' : '' ?>" href="./settings.php">
                        <i class="bi bi-gear"></i>
                        <span data-translate="settings">Settings</span>
                    </a>
                </li>
            </ul>
            <div class="d-flex align-items-center">
                <div class="me-0 d-block">
                    <button type="button" class="btn btn-primary icon-btn me-2" onclick="toggleControlPanel()" data-tooltip="control_panel"><i class="bi bi-gear"> </i></button>
                    <button type="button" class="btn btn-deepskyblue icon-btn me-2" data-bs-toggle="modal" data-bs-target="#autostartModal" data-tooltip="autostartTooltip"><i class="fas fa-power-off"></i></button>
                    <button type="button" class="btn btn-danger icon-btn me-2" data-bs-toggle="modal" data-bs-target="#langModal" data-tooltip="set_language"><i class="bi bi-translate"></i></button>
                    <button type="button" class="btn btn-success icon-btn me-2" data-bs-toggle="modal" data-bs-target="#musicModal" data-tooltip="music_player"><i class="bi bi-music-note-beamed"></i></button>
                    <button type="button" class="btn btn-warning icon-btn me-2" id="toggleIpStatusBtn"  onclick="toggleIpStatusBar()" data-tooltip="hide_ip_info"><i class="bi bi-eye-slash"> </i></button>
                    <button type="button" class="btn btn-pink icon-btn me-2 d-none d-sm-inline" data-bs-toggle="modal" data-bs-target="#portModal" data-tooltip="viewPortInfoButton"><i class="bi bi-plug"></i></button>
                    <button type="button" class="btn btn-success icon-btn me-2" id="updatePhpConfig" data-tooltip="unlock_php_upload_limit"><i class="bi bi-unlock"></i></button>
                    <button type="button" class="btn-refresh-page btn btn-orange icon-btn me-2 d-none d-sm-inline"><i class="fas fa-sync-alt"></i></button>
                    <button type="button" class="btn btn-fuchsia icon-btn me-2 d-none d-sm-inline" onclick="handleIPClick()" data-tooltip="show_ip"><i class="fas fa-globe"></i></button>
                    <button type="button" class="btn btn-info icon-btn me-2" onclick="document.getElementById('colorPicker').click()" data-tooltip="component_bg_color"><i class="bi bi-palette"></i></button>
                    <input type="color" id="colorPicker" value="#0f3460" style="display: none;">
            </div>
        </div>
    </div>
</nav>

<script>
    document.getElementById("updatePhpConfig").addEventListener("click", function() {
        const confirmText = translations['confirm_update_php'] || "Are you sure you want to update PHP configuration?";
        speakMessage(confirmText);
        showConfirmation(confirmText, () => {
            fetch("update_php_config.php", {
                method: "POST",
                headers: { "Content-Type": "application/json" }
            })
            .then(response => response.json())
            .then(data => {
                const msg = data.message || "Configuration updated successfully.";
                showLogMessage(msg);
                speakMessage(msg);
            })
            .catch(error => {
                const errMsg = translations['request_failed'] || ("Request failed: " + error.message);
                showLogMessage(errMsg);
                speakMessage(errMsg);
            });
        });
    });
</script>
