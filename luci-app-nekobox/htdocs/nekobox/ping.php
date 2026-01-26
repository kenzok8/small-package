<?php
$timezone = trim(shell_exec("uci get system.@system[0].zonename 2>/dev/null"));

date_default_timezone_set($timezone ?: 'UTC');
?>

<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'clearNekoTmpDir') {
    $nekoDir = '/tmp/neko';
    $response = [
        'success' => false,
        'message' => ''
    ];

    if (is_dir($nekoDir)) {
        if (deleteNekoTmpDirectory($nekoDir)) {
            $response['success'] = true;
            $response['message'] = 'Directory cleared successfully.';
        } else {
            $response['message'] = 'Failed to delete the directory.';
        }
    } else {
        $response['message'] = 'The directory does not exist.';
    }

    header('Content-Type: application/json');
    echo json_encode($response);
    exit;
}

function deleteNekoTmpDirectory($dir) {
    if (!file_exists($dir)) {
        return true;
    }
    if (!is_dir($dir)) {
        return unlink($dir);
    }

    foreach (scandir($dir) as $item) {
        if ($item === '.' || $item === '..') {
            continue;
        }

        if (!deleteNekoTmpDirectory($dir . DIRECTORY_SEPARATOR . $item)) {
            return false;
        }
    }

    return rmdir($dir);
}
?>

<?php
$singbox_autostart = exec("uci -q get neko.cfg.singbox_autostart") ?: '0';

if (isset($_POST['save_autostart'])) {
    $autostart = isset($_POST['autostart']) ? '1' : '0';
    shell_exec("uci set neko.cfg.singbox_autostart='$autostart'");
    shell_exec("uci commit neko");
    writeToLog("Autostart setting changed to: $autostart");
    echo "<div class='log-message alert alert-danger'><span data-translate='settingSaved'></span></div>";
    $singbox_autostart = $autostart;
}
?>

<style>
.modal {
        opacity: 0;
        visibility: hidden;
}

.modal.show {
        opacity: 1;
        visibility: visible;
}

#theme-loader {
	position: fixed;
	inset: 0;
	background: linear-gradient(
        135deg,
        var(--accent-color),
        color-mix(in oklch, var(--accent-color), white 30%),
        color-mix(in oklch, var(--accent-color), black 30%)
        );
	background-size: 300% 300%;
	animation: animated-gradient 6s ease infinite;
	z-index: 9999;
	display: flex;
	align-items: center;
	justify-content: center;
	transition: opacity 0.6s ease;
	color: var(--text-primary);
	font-family: "Segoe UI", sans-serif;
}

.theme-loader-content {
	text-align: center;
	backdrop-filter: var(--glass-blur);
	padding: 2rem 3rem;
	border-radius: var(--radius);
	background: color-mix(in oklch, var(--bg-container), white 10%);
	box-shadow: 0 0 20px oklch(0 0 0 / 0.2);
}

.loader-icon {
	font-size: 3.5rem;
	animation: bounceIn 1s ease-in-out infinite alternate;
}

.loader-title {
	font-size: 1.25rem;
	margin-top: 1rem;
	opacity: 0.85;
}

@keyframes animated-gradient {
	0% {
		background-position: 0% 50%;
	}

	50% {
		background-position: 100% 50%;
	}

	100% {
		background-position: 0% 50%;
	}
}

@keyframes bounceIn {
	0% {
		transform: scale(1) translateY(0);
	}

	100% {
		transform: scale(1.1) translateY(-10px);
	}
}

.navbar {
	backdrop-filter: none;
	-webkit-backdrop-filter: none;
	border: none;
	padding: 0.8rem 1.2rem;
	border-radius: 0;
	box-shadow: none;
	color: var(--text-primary);
	transition: var(--transition);
}

.navbar-brand {
	font-size: 1.5rem !important;
	font-weight: 900 !important;
	color: var(--accent-color) !important;
	text-decoration: none;
	transition: var(--transition);
}

.nav-link::after {
        content: '';
        position: absolute;
        bottom: 0;
        left: 50%;
        transform: translateX(-50%);
        width: 0;
        height: 2px;
        background: var(--accent-color);
        transition: width var(--transition-speed) ease;
}

.nav-link:hover::after {
        width: 70%;
}

.navbar-brand:hover {
	color: var(--accent-color) !important;
}

.navbar .nav-link {
	color: var(--text-primary) !important;
	padding: 0.5rem 1rem;
	border-radius: var(--radius);
	transition: var(--transition);
	display: flex;
	align-items: center;
	gap: 0.4rem;
	font-weight: 500;
        position: relative;
}

.navbar .nav-link.active:hover,
.navbar .nav-link:hover {
	color: var(--accent-color)  !important;
}

.navbar .nav-link.active {
	color: var(--accent-color) !important;
	font-weight: 600;
}

.navbar-toggler {
	color: var(--accent-color) !important;
	border: none;
	background: transparent;
	outline: none;
}

.navbar-toggler i {
	color: var(--accent-color) !important;
	font-size: 1.8rem;
	transition: var(--transition);
}

.icon-btn-group {
	display: flex;
	flex-wrap: wrap;
	gap: 0.7rem !important;
	justify-content: flex-start;
}

.icon-btn {
	display: inline-flex !important;
	align-items: center !important;
	justify-content: center !important;
	width: 2rem !important;
	height: 2rem !important;
	padding: 0 !important;
	border-radius: 1rem !important;
	font-size: 1rem !important;
	line-height: 1 !important;
	flex-shrink: 0;
}

.log-message.alert {
	position: fixed;
	left: 20px;
	padding: 12px 16px;
	background: rgb(45, 125, 55) !important;
	color: #fff !important;
	color: white;
	border-radius: 8px;
	z-index: 9999;
	max-width: 370px;
	font-size: 15px;
	word-wrap: break-word;
	line-height: 1.5;
	box-shadow: 0 4px 6px rgba(0, 0, 0, 0.15);
	border: 1px solid rgba(255, 255, 255, 0.15);
	text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
	backdrop-filter: blur(2px);
	transform: translateY(0);
	opacity: 0;
	animation: scrollUp 12s cubic-bezier(0.25, 0.46, 0.45, 0.94) forwards;
	display: inline-block;
	margin-bottom: 10px;
	transition: transform 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

@keyframes scrollUp {
	0% {
		top: 90%;
		opacity: 0;
	}

	20% {
		opacity: 1;
	}

	80% {
		top: 50%;
		opacity: 1;
	}

	100% {
		top: 45%;
		opacity: 0;
	}
}

.white-text-table,
.white-text-table td,
.white-text-table input {
	color: var(--text-primary) !important;
}

.custom-tooltip {
	position: fixed;
	background: var(--accent-color);
	color: #fff;
	padding: 8px 12px;
	border-radius: var(--radius);
	font-size: 0.85rem;
	pointer-events: none;
	z-index: 10000000;
        white-space: normal;
        max-width: 300px;
	line-height: 1.4;
	backdrop-filter: var(--glass-blur);
	border: var(--glass-border);
	box-shadow: 0 4px 20px color-mix(in oklch, var(--bg-container), black 85%),
        inset 0 0 0 1px rgba(255, 255, 255, 0.1);
	opacity: 0;
	transform: translateY(10px);
	transition: opacity 0.2s ease-out,
        transform 0.2s ease-out;
        word-wrap: break-word;
        overflow-wrap: break-word;
}

.custom-tooltip.show {
	opacity: var(--glass-opacity);
	transform: translateY(0);
}

.custom-tooltip::after {
	content: '';
	position: absolute;
	top: -5px;
	left: 50%;
	transform: translateX(-50%) rotate(45deg);
	width: 10px;
	height: 10px;
	background: inherit;
	border-top: var(--glass-border);
	border-left: var(--glass-border);
	z-index: -1;
}

.custom-tooltip[data-position="top"]::after {
	top: auto;
	bottom: -5px;
	border: none;
	border-right: var(--glass-border);
	border-bottom: var(--glass-border);
}

@media (max-width: 768px) {
	.custom-tooltip {
		max-width: 200px;
		white-space: normal;
		font-size: 0.8rem;
	}
}

.modal-body .alert.alert-warning .note-text {
        color: #ff0000 !important;
}

@media (max-width: 600px) {
	.navbar-brand {
		flex-shrink: 1;
		min-width: 0;
		white-space: nowrap;
	}

	#dynamicTitle {
		white-space: nowrap;
	}

	.navbar-toggler i {
		font-size: 1.2rem !important;
	}

	.navbar-toggler {
		padding: 0.15rem 0.35rem;
	}
}

@media (max-width: 768px) {
	.row > .col {
		flex: 0 0 50%;
		max-width: 50%;
	}

	.row > .col:nth-child(n+3) {
		flex: 0 0 33.3333%;
		max-width: 33.3333%;
	}

	.row {
		row-gap: 13px;
	}

	.d-flex.flex-wrap.mb-4 {
		flex-wrap: nowrap !important;
	}
}

.centered-img {
        transition: transform 0.6s ease-in-out;
        transform-style: preserve-3d;
        transform: rotateY(0deg);
}
</style>

<div id="theme-loader" style="display: none;">
  <div class="theme-loader-content">
    <div class="loader-icon">🚀</div>
    <div class="loader-title">Updating...</div>
  </div>
</div>

<script>
document.addEventListener("DOMContentLoaded", () => {
  const loader = document.getElementById("theme-loader");
  const MAX_WAIT_TIME = 15000;

  document.querySelectorAll("form").forEach(form => {
    form.addEventListener("submit", (e) => {
      if (e.submitter?.classList.contains('cancel-btn')) {
        e.preventDefault();
        return;
      }

      if (form.classList.contains('no-loader')) {
        return;
      }

      if (loader) {
        loader.style.display = "flex";
        setTimeout(() => {
          loader.style.opacity = "0";
          setTimeout(() => {
            loader.style.display = "none";
            loader.style.opacity = "1";
          }, 600);
        }, MAX_WAIT_TIME);
      }
    });
  });
});
</script>

<script>
document.addEventListener('DOMContentLoaded', () => {
  const tooltip = document.createElement('div');
  tooltip.className = 'custom-tooltip';
  document.body.appendChild(tooltip);

  document.querySelectorAll('[data-tooltip]').forEach(el => {
    el.addEventListener('mouseenter', e => {
      tooltip.textContent = el.getAttribute('data-tooltip');
      tooltip.classList.add('show');

      requestAnimationFrame(() => {
        positionTooltip(e);
      });
    });

    el.addEventListener('mousemove', e => {
      positionTooltip(e);
    });

    el.addEventListener('mouseleave', () => {
      tooltip.classList.remove('show');
    });
  });

  function positionTooltip(e) {
    const spacing = 20;
    const tooltipRect = tooltip.getBoundingClientRect();
    const targetRect = e.target.getBoundingClientRect();

    const top = targetRect.bottom + spacing;
    const left = targetRect.left + (targetRect.width - tooltipRect.width) / 2;

    tooltip.style.top = `${top}px`;
    tooltip.style.left = `${left}px`;
    tooltip.dataset.position = 'bottom';
  }
});

document.addEventListener('click', e => {
  if (e.target.closest('.btn-refresh-page')) {
    location.reload();
  }
});
</script>

<div class="modal fade" id="autostartModal" tabindex="-1" aria-labelledby="autostartModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
  <div class="modal-dialog modal-lg">
    <form method="post" class="no-loader">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title" id="autostartModalLabel" data-translate="singboxAutostartTitle">
            Sing-box Auto Start
          </h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <div class="form-check form-switch">
            <input class="form-check-input" type="checkbox" name="autostart" id="autostart"
                   <?php echo ($singbox_autostart === '1') ? 'checked' : ''; ?>>
            <label class="form-check-label" for="autostart">
              <strong data-translate="enableAutostart">Enable Auto Start</strong>
            </label>
          </div>
          <div class="mt-3">
            <small class="text-muted" data-translate="autostartTip">
              When checked, Sing-box will start automatically on router reboot (if Mihomo is not running)
            </small>
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancel">Cancel</button>
          <button type="submit" name="save_autostart" class="btn btn-primary" data-translate="saveButton">Save</button>
        </div>
      </div>
    </form>
  </div>
</div>

<div class="modal fade" id="portModal" tabindex="-1" aria-labelledby="portModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered modal-xl">
    <form id="portForm" method="POST" action="./save_ports.php" class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="portModalLabel" data-translate="portInfoTitle">Port Information</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <table class="table table-light table-striped text-center align-middle w-100 mb-0 white-text-table">
          <thead class="table-light">
            <tr>
              <th style="width: 20%;" class="text-center" data-translate="componentName">Component Name</th>
              <th style="width: 16%;" class="text-center">socks-port</th>
              <th style="width: 16%;" class="text-center">mixed-port</th>
              <th style="width: 16%;" class="text-center">redir-port</th>
              <th style="width: 16%;" class="text-center">port</th>
              <th style="width: 16%;" class="text-center">tproxy-port</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>Mihomo</td>
              <td><input type="number" class="form-control text-center" name="mihomo_socks" value="<?= htmlspecialchars($neko_cfg['socks']) ?>"></td>
              <td><input type="number" class="form-control text-center" name="mihomo_mixed" value="<?= htmlspecialchars($neko_cfg['mixed']) ?>"></td>
              <td><input type="number" class="form-control text-center" name="mihomo_redir" value="<?= htmlspecialchars($neko_cfg['redir']) ?>"></td>
              <td><input type="number" class="form-control text-center" name="mihomo_port" value="<?= htmlspecialchars($neko_cfg['port']) ?>"></td>
              <td><input type="number" class="form-control text-center" name="mihomo_tproxy" value="<?= htmlspecialchars($neko_cfg['tproxy']) ?>"></td>
            </tr>
            <tr>
              <td>Sing-box</td>
              <td><input type="number" class="form-control text-center" name="singbox_http" value="<?= htmlspecialchars($http_port) ?>"></td>
              <td><input type="number" class="form-control text-center" name="singbox_mixed" value="<?= htmlspecialchars($mixed_port) ?>"></td>
              <td><input type="text" class="form-control text-center" name="singbox_mixed" value="—" disabled></td>
              <td><input type="text" class="form-control text-center" name="singbox_mixed" value="—" disabled></td>
              <td><input type="text" class="form-control text-center" name="singbox_mixed" value="—" disabled></td>
            </tr>
          </tbody>
        </table>
        <div class="text-danger text-center fw-bold mt-3 mb-1" data-translate="portChangeNotice">
          Port changes will take effect after restarting the service.
        </div>
      </div>
      <div class="modal-footer justify-content-end">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="closeButton">Close</button>
        <button type="submit" class="btn btn-primary" data-translate="save">Save</button>
      </div>
    </form>
  </div>
</div>

<?php include './language.php'; include './cfg.php'; $current = basename($_SERVER['PHP_SELF']); ?>
<html lang="<?php echo $currentLang; ?>">
<div class="modal fade" id="langModal" tabindex="-1" aria-labelledby="langModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="langModalLabel" data-translate="select_language">Select Language</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <select id="langSelect" class="form-select" onchange="changeLanguage(this.value)">
                    <option value="zh" data-translate="simplified_chinese">Simplified Chinese</option>
                    <option value="hk" data-translate="traditional_chinese">Traditional Chinese</option>
                    <option value="en" data-translate="english">English</option>
                    <option value="ko" data-translate="korean">Korean</option>
                    <option value="vi" data-translate="vietnamese">Vietnamese</option>
                    <option value="ja" data-translate="japanese"></option>
                    <option value="ru" data-translate="russian"></option>
                    <option value="de" data-translate="germany">Germany</option>
                    <option value="fr" data-translate="france">France</option>
                    <option value="ar" data-translate="arabic"></option>
                    <option value="es" data-translate="spanish">spanish</option>
                </select>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="close">Close</button>
            </div>
        </div>
    </div>
</div>

<?php
$default_url = 'https://raw.githubusercontent.com/Thaolga/Rules/main/music/songs.txt';
$file_path = __DIR__ . '/lib/url_config.txt'; 
$message = '';

if (!file_exists($file_path)) {
    if (file_put_contents($file_path, $default_url) !== false) {
        chmod($file_path, 0644); 
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['new_url'])) {
        $new_url = $_POST['new_url'];
        if (file_put_contents($file_path, $new_url) !== false) {
            chmod($file_path, 0644);  
            $message = 'Update successful!';
        } else {
            $message = 'Update failed, please check permissions.';
        }
    }

    if (isset($_POST['reset_default'])) {
        if (file_put_contents($file_path, $default_url) !== false) {
            chmod($file_path, 0644);
            $message = 'Default URL restored!';
        } else {
            $message = 'Restore failed, please check permissions.';
        }
    }
} else {
    $new_url = file_exists($file_path) ? file_get_contents($file_path) : $default_url;
}
?>

<div class="modal fade" id="colorModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" data-translate="advanced_color_control">Advanced Color Control</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <div class="row">
          <div class="col-md-6">
            <div class="card h-100">
              <div class="card-header bg-primary text-white">
                <i class="bi bi-sliders"></i> <span data-translate="color_control">Color Control</span>
              </div>
              <div class="card-body">
                <div class="mb-3">
                  <label class="form-label" data-translate="primary_hue">Primary Hue</label>
                  <div class="d-flex align-items-center">
                    <input type="range" class="form-range flex-grow-1" id="hueSlider" min="0" max="360" step="1">
                    <span class="ms-2" style="min-width: 50px;" id="hueValue">0°</span>
                  </div>
                </div>
                
                <div class="mb-3">
                  <label class="form-label" data-translate="chroma">Chroma</label>
                  <div class="d-flex align-items-center">
                    <input type="range" class="form-range flex-grow-1" id="chromaSlider" min="0" max="0.3" step="0.01">
                    <span class="ms-2" style="min-width: 50px;" id="chromaValue">0.10</span>
                  </div>
                </div>
                
                <div class="mb-3">
                  <label class="form-label" data-translate="lightness">Lightness</label>
                  <div class="d-flex align-items-center">
                    <input type="range" class="form-range flex-grow-1" id="lightnessSlider" min="0" max="100" step="1">
                    <span class="ms-2" style="min-width: 50px;" id="lightnessValue">30%</span>
                  </div>
                </div>
                
                <div class="mb-3">
                  <label class="form-label" data-translate="or_use_palette">Or use palette:</label>
                  <div class="d-flex flex-wrap gap-2">
                    <button class="btn btn-sm p-3 rounded-circle" style="background-color:#4d79ff" data-h="240" data-c="0.2" data-l="30"></button>
                    <button class="btn btn-sm p-3 rounded-circle" style="background-color:#ff4d94" data-h="340" data-c="0.25" data-l="35"></button>
                    <button class="btn btn-sm p-3 rounded-circle" style="background-color:#4dff88" data-h="150" data-c="0.18" data-l="40"></button>
                    <button class="btn btn-sm p-3 rounded-circle" style="background-color:#ffb84d" data-h="40" data-c="0.22" data-l="45"></button>
                    <button class="btn btn-sm p-3 rounded-circle" style="background-color:#bf4dff" data-h="280" data-c="0.23" data-l="50"></button>
                    <button class="btn btn-sm p-3 rounded-circle" style="background-color:#ff6b6b" data-h="10" data-c="0.24" data-l="55"></button>
                    <button class="btn btn-sm p-3 rounded-circle" style="background-color:#4eca9e" data-h="160" data-c="0.19" data-l="60"></button>
                    <button class="btn btn-sm p-3 rounded-circle" style="background-color:#ff9ff3" data-h="310" data-c="0.21" data-l="65"></button>
                    <button class="btn btn-sm p-3 rounded-circle" style="background-color:#6c757d" data-h="200" data-c="0.05" data-l="50"></button>
                    <button class="btn btn-sm p-3 rounded-circle" style="background-color:#ffc107" data-h="50" data-c="0.26" data-l="70"></button>
                  </div>
                </div>
                
                <div class="mt-3">
                  <button class="btn btn-secondary w-100" id="resetColorBtn">
                    <i class="bi bi-arrow-counterclockwise"></i> <span data-translate="reset_to_default">Reset to Default</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
          <div class="col-md-6">
            <div class="card h-100">
              <div class="card-header bg-primary text-white">
                <i class="bi bi-eye"></i> <span data-translate="color_preview">Color Preview</span>
              </div>
              <div class="card-body">
                <div id="colorPreview" style="height: 100px; border-radius: 5px; margin-bottom: 15px;"></div>
                <div class="mb-3">
                  <label class="form-label" data-translate="oklch_values">OKLCH Values:</label>
                  <div id="oklchValue" class="text-monospace">OKLCH(30%, 0.10, 260°)</div>
                </div>
                <div class="mb-3">
                  <label class="form-label" data-translate="contrast_ratio">Contrast Ratio:</label>
                  <div id="contrastRatio">21.00:1</div>
                  <div id="contrastRating" class="mt-1 text-success fw-bold"><i class="bi bi-check-circle-fill"></i> Excellent (AAA)</div>
                </div>
                <div class="mb-3">
                  <label class="form-label" data-translate="recent_colors">Recent Colors:</label>
                  <div id="recentColors" class="d-flex flex-wrap gap-2"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
          <i class="bi bi-x"></i> <span data-translate="cancel">Cancel</span>
        </button>
        <button type="button" class="btn btn-danger" id="removeAppColorBtn">
          <i class="bi bi-eraser"></i> <span data-translate="reset">Reset</span>
        </button>
        <button type="button" class="btn btn-primary" id="applyColorBtn">
          <i class="bi bi-check"></i> <span data-translate="apply_color">Apply Color</span>
        </button>
      </div>
    </div>
  </div>
</div>

<div class="modal fade" id="colorPickerModal" tabindex="-1" aria-labelledby="colorPickerModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
  <div class="modal-dialog modal-xl modal-dialog-centered">
    <div class="modal-content bg-dark text-white border border-secondary rounded">
      <div class="modal-header">
        <h5 class="modal-title" id="colorPickerModalLabel" data-translate="color_width_panel">Color & Width Panel</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <div class="row mb-3">
          <div class="col-md-6">
            <label for="containerWidth" class="form-label" data-translate="page_width">Page Width</label>
            <input type="range" class="form-range" name="containerWidth" id="containerWidth" min="800" max="5400" step="50" value="1800" style="width: 100%;">
            <div id="widthValue" class="mt-2" style="color: #FF00FF;" data-translate="current_width">Current Width: 1800px</div>
          </div>
          <div class="col-md-6">
            <label for="modalMaxWidth" class="form-label" data-translate="settings.modal.maxWidth">Modal Max Width</label>
            <input type="range" class="form-range" name="modalMaxWidth" id="modalMaxWidth" min="500" max="5400" step="50" value="800" style="width: 100%;">
            <div id="modalWidthValue" class="mt-2" style="color: #00FF00;" data-translate="current_max_width">Current Max Width: 800px</div>
          </div>
        </div>
        <div id="color-preview" class="rounded border mb-3" style="height: 100px; background: #333;"></div>
        <div class="d-flex align-items-center gap-2 mb-3">
          <div class="d-flex align-items-center justify-content-center rounded"
               style="width: 80px; height: 50px; background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.3);">
            <input type="color" id="color-selector"
                   class="form-control form-control-color p-0"
                   value="#0f3460"
                   data-tooltip="choose_color"
                   style="width: 36px; height: 36px; cursor: pointer;">
          </div>
          <div id="current-color-block"
               class="rounded d-flex align-items-center justify-content-center text-white position-relative"
               style="height: 50px; flex: 1; cursor: pointer; background: #333; border: 2px solid white; transition: all 0.3s ease;">
            <input type="text"
                   id="color-input"
                   class="form-control text-center border-0 bg-transparent text-white p-0 m-0"
                   value=" "
                   style="width: 100%; font-size: 0.9rem;">
                   <span class="fake-cursor">|</span>
          </div>
        </div>
        <div class="d-flex gap-2 mb-3">
          <button id="apply-color" class="btn btn-success flex-fill"><i class="fa fa-paint-brush"></i> <span data-translate="apply_color">Apply</span> </button>
          <button id="reset-color" class="btn btn-danger flex-fill"><i class="fa fa-undo"></i> <span data-translate="reset">Reset</span></button>
        </div>
        <div id="preset-colors" class="d-grid gap-2"></div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal"><i class="fa fa-times"></i> <span data-translate="close">Close</span></button>
      </div>
    </div>
  </div>
</div>

 <div class="control-panel-overlay" id="controlPanelOverlay" style="display:none;">
    <div class="control-panel">
        <div class="panel-header">
            <h3><i class="bi bi-gear"></i> <span data-translate="control_panel_title">Control Panel</span></h3>
            <button class="close-icon" onclick="toggleControlPanel()" data-tooltip="close">
                <i class="bi bi-x-lg"></i>
            </button>
        </div>
        <div class="buttons-grid">
            <button class="panel-btn" data-bs-toggle="modal" data-bs-target="#musicModal" data-tooltip="music_player">
                <div class="btn-icon">
                    <i class="bi bi-music-note-beamed"></i>
                </div>
                <div>
                    <div data-translate="music_player">Music Player</div>
                    <small class="opacity-75" data-translate="music_desc">Control background music settings</small>
                </div>
            </button>
            <button class="panel-btn" id="color-panel-btn" data-bs-toggle="modal" data-bs-target="#colorPickerModal">
                <div class="btn-icon">
                    <i class="bi bi-palette"></i>
                </div>
                <div>
                    <div data-translate="color_panel">Color Panel</div>
                    <small class="opacity-75" data-translate="color_desc">Customize interface colors</small>
                </div>
            </button>
            <button class="panel-btn" id="advancedColorBtn" data-tooltip="advanced_color_settings">
                <div class="btn-icon">
                    <i class="bi bi-palette2"></i>
                </div>
                <div>
                    <div data-translate="advanced_color">Advanced Color Settings</div>
                    <small class="opacity-75" data-translate="advanced_color_desc">Professional color adjustments</small>
                </div>
            </button>
            <button class="panel-btn" id="clear-cache-btn" data-tooltip="clear_cache">
                <div class="btn-icon">
                    <i class="bi bi-trash"></i>
                </div>
                <div>
                    <div data-translate="clear_cache">Clear Cache</div>
                    <small class="opacity-75" data-translate="cache_desc">Free up system resources</small>
                </div>
            </button>
            <button class="panel-btn" id="startCheckBtn" data-tooltip="start_check">
                <div class="btn-icon">
                    <i class="bi bi-globe2"></i>
                </div>
                <div>
                    <div data-translate="start_check">Start Website Check</div>
                    <small class="opacity-75" data-translate="check_desc">Diagnose website status</small>
               </div>
                    <i class="bi bi-toggle-off" id="autoCheckIcon"  style="cursor: pointer; margin-left: 10px;"></i>
            </button>
            <button class="panel-btn" id="openModalBtn" data-tooltip="open_animation">
                <div class="btn-icon">
                    <i class="bi bi-sliders"></i>
                </div>
                <div>
                    <div data-translate="open_animation">Animation Control</div>
                    <small class="opacity-75" data-translate="animation_desc">Adjust animation effects</small>
                </div>
            </button>
            <button class="panel-btn" data-bs-toggle="modal" data-bs-target="#langModal">
                <div class="btn-icon">
                    <i class="bi bi-translate"></i>
                </div>
                <div class="language-container">
                    <div>
                        <div data-translate="set_language">Set Language</div>
                        <small class="opacity-75" data-translate="language_desc">Choose interface language</small>
                    </div>
                    <img id="flagIcon" src="https://flagcdn.com/w20/cn.png" class="flag-icon" alt="Country Flag">
                </div>
            </button>
            <button class="panel-btn" onclick="window.open('./monaco.php', '_blank')">
                <div class="btn-icon">
                    <i class="bi bi-file-earmark"></i>
                </div>
                <div>
                    <div data-translate="fileHelper">File Helper</div>
                    <small class="opacity-75" data-translate="file_desc">Manage your files</small>
                </div>
            </button>
            <button class="panel-btn" id="translationToggleBtn" data-tooltip="enable">
                <div class="btn-icon" id="translationToggleIcon">
                    <i class="bi bi-toggle-off"></i>
                </div>
                <div>
                    <div data-translate="ip_info">IP Info</div>
                    <div class="opacity-75" id="translationToggleText" style="font-size: 0.85rem;">enable</div>
                </div>
            </button>
        </div>
        <div class="action-row">
            <div class="color-picker">
                <button class="btn btn-info ms-2" id="fontSwitchBtn" data-tooltip="toggle_font">
                    <i id="fontSwitchIcon" class="fa-solid fa-font" style="color: white;"></i>
                </button>
                <label for="colorPicker" data-translate="component_bg_color">Component Background</label>
                <input type="color" id="colorPicker" value="#0f3460">
            </div>
        </div>
    </div>
</div>

<div id="animationModal" class="animation-modal" style="display: none;">
    <div class="animation-modal-content">
        <button id="toggleAnimationBtn" data-translate="start_cube_animation">🖥️ Start Cube Animation</button>
        <button id="toggleSnowBtn" data-translate="start_snow_animation">❄️ Start Snow Animation</button>
        <button id="toggleLightEffectBtn" data-translate="start_light_effect_animation">✨Start Light Effect Animation</button>
        <button class="modal-close-btn" onclick="closeModal()" data-translate="close">Close</button>
    </div>
</div>

<div id="floatingLyrics" style="display: none;">
    <div class="floating-controls">
        <button class="ctrl-btn" onclick="changeTrack(-1, true)" data-tooltip="previous_track">
            <i class="fas fa-backward"></i>
        </button>
        <button class="ctrl-btn" id="floatingPlayBtn" onclick="togglePlay()" data-tooltip="play_pause">
            <i class="bi bi-play-fill"></i>
        </button>
        <button class="ctrl-btn" onclick="changeTrack(1, true)" data-tooltip="next_track">
            <i class="fas fa-forward"></i>
        </button>
        <button class="ctrl-btn" id="floatingRepeatBtn" onclick="toggleRepeat()">
            <i class="bi bi-arrow-repeat"></i>
        </button>
        <button class="ctrl-btn" id="speedToggle" data-tooltip="playback_speed">
            <span id="speedLabel">1×</span>
        </button>
        <button class="ctrl-btn" id="muteToggle" data-tooltip="volume">
            <i class="bi bi-volume-up-fill"></i>
        </button>
        <button class="ctrl-btn" id="updatePlaylistBtn" onclick="updatePlaylist()" 
                data-tooltip="update_playlist">
            <i class="fa fa-sync-alt"></i>
        </button>
        <button class="ctrl-btn" id="goFirstBtn">
            <i class="fas fa-circle-left"></i>
        </button>
        <button id="toggleFloatingLyricsBtn" class="ctrl-btn toggleFloatingLyricsBtn" data-tooltip="toggle_floating_lyrics">
            <i class="bi bi-display floatingIcon"></i>
        </button>
    </div>
    <div id="floatingCurrentSong" class="vertical-title"></div>
    <div class="vertical-lyrics"></div>
</div>

<span id="clearConfirmText" data-translate="clear_confirm" class="d-none"></span>

<div class="modal fade" id="musicModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content bg-dark text-white">
            <div class="modal-header">
                <h5 class="modal-title" id="langModalLabel" data-translate="music_player"></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <div id="floatingLyrics"></div>
                <div id="currentSong" class="mb-3 text-center font-weight-bold fs-4"></div>
                <div class="lyrics-container" id="lyricsContainer" style="height: 300px; overflow-y: auto;"></div>
            <div class="non-lyrics-content">
                <div class="progress-container mt-3">
                    <div class="progress">
                        <div class="progress-bar bg-success" role="progressbar" id="progressBar" style="width: 0%" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100"></div>
                    </div>
                </div>
                <div class="d-flex justify-content-between mt-2 small">
                    <span id="currentTime">0:00</span>
                    <span id="duration">0:00</span>
                </div>          
                <div class="controls d-flex justify-content-center gap-3 mt-4">
                    <button class="control-btn toggleFloatingLyricsBtn" data-tooltip="toggle_floating_lyrics">
                        <i class="bi bi-display floatingIcon"></i>
                    </button>
                    <button class="control-btn" id="repeatBtn" onclick="toggleRepeat()">
                        <i class="bi bi-arrow-repeat"></i>
                    </button>
                    <button class="control-btn" onclick="changeTrack(-1, true)" data-tooltip="previous_track">
                        <i class="bi bi-caret-left-fill"></i>
                    </button>
                    <button class="control-btn" id="playPauseBtn" onclick="togglePlay()" data-tooltip="play_pause">
                        <i class="bi bi-play-fill"></i>
                    </button>
                    <button class="control-btn" onclick="changeTrack(1, true)" data-tooltip="next_track">
                        <i class="bi bi-caret-right-fill"></i>
                    </button>
                    <button class="control-btn" type="button" data-bs-toggle="modal" data-bs-target="#urlModal" data-tooltip="custom_playlist">
                        <i class="bi bi-music-note-list"></i>
                    </button>
                    <button class="btn btn-volume position-relative" id="volumeToggle" data-tooltip="volume">
                        <i class="bi bi-volume-up-fill"></i>
                        <div class="volume-slider-container position-absolute bottom-100 start-50 translate-middle-x mb-1 p-2" id="volumePanel" style="display: none; width: 120px;">
                            <input type="range" class="form-range volume-slider" id="volumeSlider" min="0" max="1" step="0.01" value="1">
                        </div>
                    </button>
                </div>
                <div class="playlist mt-3" id="playlist"></div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-info" id="lyricsToggle"><i class="bi bi-chevron-down" id="lyricsIcon"></i></button>
                <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal" data-translate="cancel">Cancel</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="urlModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" data-translate="update_playlist"></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <form method="POST">
                    <div class="mb-3">
                        <label data-translate="playlist_url"></label>
                        <input 
                            type="text" 
                            name="new_url" 
                            id="new_url" 
                            class="form-control" 
                            value="<?= htmlspecialchars($new_url) ?>" 
                            required
                        >
                    </div>
                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary" data-translate="save"></button>
                        <button type="submit" name="reset_default" class="btn btn-secondary" data-translate="reset_default"></button>
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancel"></button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="confirmModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false" style="z-index: 9999;">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" data-translate="confirm_title">Confirm Action</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body" id="confirmModalMessage"></div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" data-translate="cancel">Cancel</button>
                <button type="button" class="btn btn-danger" id="confirmModalYes" data-translate="confirm">Confirm</button>
            </div>
        </div>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function () {
    const navbar = document.getElementById('navbarContent');
    const toggler = document.querySelector('.navbar-toggler');

    if (!navbar || !toggler) return;

    function isMobile() {
        return window.innerWidth < 992;
    }

    navbar.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', () => {
            if (isMobile() && navbar.classList.contains('show')) {
                toggler.click();
            }
        });
    });

    document.addEventListener('click', (e) => {
        const isInside = navbar.contains(e.target) || toggler.contains(e.target);
        if (!isInside && navbar.classList.contains('show') && isMobile()) {
            toggler.click();
        }
    });
});
</script>

<script>
function clearNekoTmpDir() {
    fetch('', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'action=clearNekoTmpDir'
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            alert(translations["tmp_neko_cleared"] || "The /tmp/neko directory has been cleared successfully.");
        } else {
            if (data.message === 'The directory does not exist.') {
                alert(translations["tmp_neko_not_exist"] || "The /tmp/neko directory does not exist. No action was taken.");
            } else {
                alert('Failed to clear the /tmp/neko directory: ' + data.message);
            }
        }
    })
    .catch(error => {
        console.error('Error:', error);
        alert('An error occurred while trying to clear the /tmp/neko directory.');
    });
}
</script>

<script>
document.addEventListener("DOMContentLoaded", function () {
    const animationModal = document.getElementById('animationModal');
    const openModalBtn = document.getElementById('openModalBtn');
    openModalBtn.addEventListener('click', function () {
        animationModal.style.display = 'flex';
    });

    animationModal.addEventListener('click', function (e) {
        if (e.target === animationModal) {
            animationModal.style.display = 'none';
        }
    });
});

function closeModal() {
    document.getElementById('animationModal').style.display = 'none';
}
</script>

<script>
document.addEventListener('DOMContentLoaded', function () {
  interact('.modal-dialog.draggable').draggable({
    allowFrom: '.modal-header',
    modifiers: [
      interact.modifiers.restrictRect({
        restriction: 'parent', 
        endOnly: true
      })
    ],
    listeners: {
      start(event) {
        event.target.style.transition = 'none';
        event.target.classList.add('dragging');
      },
      move(event) {
        const target = event.target;
        const x = (parseFloat(target.dataset.x) || 0) + event.dx;
        const y = (parseFloat(target.dataset.y) || 0) + event.dy;

        target.style.transform = `translate(${x}px, ${y}px)`;
        target.dataset.x = x;
        target.dataset.y = y;
      },
      end(event) {
        event.target.style.transition = '';
        event.target.classList.remove('dragging');
      }
    }
  });

  document.querySelectorAll('.modal').forEach(modal => {
    const dialog = modal.querySelector('.modal-dialog');
    dialog.classList.add('draggable');

    modal.addEventListener('show.bs.modal', () => {
      dialog.style.transform = ''; 
      dialog.dataset.x = 0;
      dialog.dataset.y = 0;
    });
  });
});
</script>

<script>
const langData = <?php echo json_encode($langData); ?>;  
const currentLang = "<?php echo $currentLang; ?>"; 

let translations = langData[currentLang] || langData['en'];

document.addEventListener("DOMContentLoaded", () => {
    updateLanguage(currentLang); 
    updateFlagIcon(currentLang);  
    document.getElementById("langSelect").value = currentLang; 
});

function updateLanguage(lang) {
    translations = langData[lang] || langData['en'];  

    const translateElement = (el, attribute, property) => {
        const translationKey = el.getAttribute(attribute);
        if (translations[translationKey]) {
            el[property] = translations[translationKey];
        }
    };

    document.querySelectorAll('[data-translate]').forEach(el => {
        const translationKey = el.getAttribute('data-translate');
        const dynamicContent = el.getAttribute('data-dynamic-content') || '';

        if (translations[translationKey]) {
            let translatedText = translations[translationKey];
        
            const indexValue = el.getAttribute('data-index');
            if (indexValue) {
                translatedText = translatedText.replace('{index}', indexValue);
            }
        
            const countValue = el.getAttribute('data-count');
            if (countValue) {
                translatedText = translatedText.replace('{count}', countValue);
            }

            if (el.tagName === 'OPTGROUP') {
                el.setAttribute('label', translatedText);
            } else {
                el.innerText = translatedText + dynamicContent; 
            }
        }
    });

    document.querySelectorAll('[data-translate-title]').forEach(el => {
        const translationKey = el.getAttribute('data-translate-title');
        if (translations[translationKey]) {
            el.title = translations[translationKey];
            el.setAttribute('data-tooltip', translations[translationKey]);
        } else {
            el.removeAttribute('title');
            el.removeAttribute('data-tooltip');
        }
    });

    document.querySelectorAll('[data-tooltip]').forEach(el => {
      const key = el.getAttribute('data-tooltip');
      if (translations[key]) {
        el.setAttribute('data-tooltip', translations[key]);
      }
   });

    document.querySelectorAll('[data-translate-placeholder]').forEach(el => {
        const translationKey = el.getAttribute('data-translate-placeholder');
        if (translations[translationKey]) {
            el.setAttribute('placeholder', translations[translationKey]);
            el.setAttribute('aria-label', translations[translationKey]);  
            el.setAttribute('title', translations[translationKey]); 
        }
    });

    document.querySelectorAll('pre[data-translate]').forEach(el => {
        const translationKey = el.getAttribute('data-translate');
        if (translationKey && translations[translationKey]) {
            const text = el.innerText;
            const suffix = text.includes(':') ? text.split(':').slice(1).join(':').trim() : '';
            el.innerText = translations[translationKey] + (suffix ? ': ' + suffix : '');
        }
    });

    document.querySelectorAll('[data-translate]').forEach(el => {
        const translationKey = el.getAttribute('data-translate');
        if (translationKey && translations[translationKey]) {
            el.setAttribute('label', translations[translationKey]);  
        }
    });
}

const languageStandardMap = {
    'zh': 'zh-CN',
    'hk': 'zh-TW', 
    'en': 'en-US',
    'ko': 'ko-KR',
    'ja': 'ja-JP',
    'ru': 'ru-RU',
    'ar': 'ar-EG',
    'es': 'es-ES',
    'de': 'de-DE',
    'fr': 'fr-FR',
    'th': 'th-TH',
    'bn': 'bn-BD',
    'vi': 'vi-VN'
};

const langToVoiceLangMap = {
    'zh': ['zh-CN', 'zh-HK', 'zh-TW'],
    'hk': ['zh-CN', 'zh-HK', 'zh-TW'],
    'en': ['en-US', 'en-GB', 'en-AU', 'en-CA', 'en-IN'],
    'ko': ['ko-KR'],
    'ja': ['ja-JP'],
    'vi': ['vi-VN'],
    'th': ['th-TH'],
    'ru': ['ru-RU'],
    'ar': ['ar-SA', 'ar-EG', 'ar-AE'],
    'es': ['es-ES', 'es-MX', 'es-US'],
    'de': ['de-DE', 'de-AT', 'de-CH'],
    'fr': ['fr-FR', 'fr-CA', 'fr-CH'],
    'bn': ['bn-BD', 'bn-IN']
};

function speakMessage(message) {
    const globalVoiceEnabled = localStorage.getItem('colorVoiceEnabled') !== 'false';
    if (!globalVoiceEnabled) return;

    function speakWithVoices() {
        const voices = speechSynthesis.getVoices();
        if (voices.length === 0) {
            setTimeout(speakWithVoices, 100);
            return;
        }

        const xhr = new XMLHttpRequest();
        xhr.open('GET', './lib/language.txt', true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4 && xhr.status === 200) {
                const lang = xhr.responseText.trim();
                
                const voiceKey = getVoicePreferenceKey(lang);
                const savedVoiceIndex = localStorage.getItem(voiceKey);
                
                let selectedVoice = null;
                
                if (savedVoiceIndex !== null) {
                    const targetLangs = langToVoiceLangMap[lang] || [languageStandardMap[lang] || lang];
                    const filteredVoices = voices.filter(voice => 
                        targetLangs.some(targetLang => voice.lang.startsWith(targetLang))
                    );
                    selectedVoice = filteredVoices[savedVoiceIndex];
                }
                
                if (!selectedVoice) {
                    const chineseVoiceKey = getChineseVoiceKey();
                    const savedChineseIndex = localStorage.getItem(chineseVoiceKey);
                    const chineseVoices = voices.filter(voice => 
                        ['zh-CN', 'zh-HK', 'zh-TW'].some(lang => voice.lang.startsWith(lang))
                    );
                    
                    if (savedChineseIndex !== null && chineseVoices[savedChineseIndex]) {
                        selectedVoice = chineseVoices[savedChineseIndex];
                    } else if (chineseVoices.length > 0) {
                        selectedVoice = chineseVoices[0];
                    }
                }
                
                if (!selectedVoice) {
                    selectedVoice = voices.find(voice => voice.lang.includes('zh')) || voices[0];
                }
                
                if (selectedVoice) {
                    const utterance = new SpeechSynthesisUtterance(message);
                    utterance.voice = selectedVoice;
                    speechSynthesis.speak(utterance);
                }
            }
        };
        xhr.send();
    }

    speakWithVoices();
}

function getVoicePreferenceKey(lang) {
    if (lang === 'zh' || lang === 'hk') {
        return 'voicePreference_chinese';
    }
    return `voicePreference_${lang}`;
}

function getChineseVoiceKey() {
    return 'voicePreference_chinese';
}

function updateFlagIcon(lang) {
    const flagImg = document.getElementById('flagIcon');
    if (!flagImg) return; 

    const flagMap = {
        'zh': './assets/neko/flags/cn.png', 
        'hk': './assets/neko/flags/hk.png', 
        'en': './assets/neko/flags/us.png',  
        'ko': './assets/neko/flags/kr.png',  
        'ja': './assets/neko/flags/jp.png', 
        'ru': './assets/neko/flags/ru.png',  
        'ar': './assets/neko/flags/sa.png', 
        'es': './assets/neko/flags/es.png',  
        'de': './assets/neko/flags/de.png', 
        'fr': './assets/neko/flags/fr.png',  
        'vi': './assets/neko/flags/vn.png'      
    };
    flagImg.src = flagMap[lang] || flagMap['en']; 
}

function changeLanguage(lang) {
    fetch('', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: 'lang=' + lang
    }).then(response => response.text())
      .then(data => {
          console.log(data); 
          updateLanguage(lang);  
          updateFlagIcon(lang);  
          const langLabelMap = {
              'zh': '语言已切换为简体中文',
              'hk': '語言已切換為繁體中文',
              'en': 'Language switched to English',
              'ko': '언어가 한국어로 변경되었습니다',
              'ja': '言語が日本語に変更されました',
              'ru': 'Язык переключен на русский',
              'ar': 'تم تغيير اللغة إلى العربية',
              'es': 'El idioma ha cambiado a español',
              'de': 'Sprache auf Deutsch umgestellt',
              'fr': 'Langue changée en français',
              'vi': 'Đã chuyển ngôn ngữ sang tiếng Việt'
          };

          const message = langLabelMap[lang] || 'Language switched';

          if (typeof speakMessage === 'function') {
              speakMessage(message);
          }
          if (typeof showLogMessage === 'function') {
              showLogMessage(message);
          }
      });
}
</script>

<script>
function manageNotifications() {
    const messages = document.querySelectorAll('.log-message:not(.initialized)');
    let basePosition = 20;

    const iconPaths = {
        error: 'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z',
        warning: 'M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z',
        info: 'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z'
    };

    function generateIcon(type) {
        const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="#fff" d="${iconPaths[type] || iconPaths.info}"/></svg>`;
        return `data:image/svg+xml;base64,${btoa(svg)}`;
    }

    messages.forEach((msg, index) => {
        msg.classList.add('initialized');

        const type = msg.dataset.type || (msg.classList.contains('error') ? 'error' : msg.classList.contains('warning') ? 'warning' : 'info');

        const originalContent = msg.innerHTML;
        msg.innerHTML = `
            <div class="log-content">
                <span class="log-icon" style="background-image:url('${generateIcon(type)}')"></span>
                ${originalContent}
                <button class="log-close-btn">&times;</button>
            </div>
        `;

        msg.style.transform = `translateY(${index * 70}px)`;

        setTimeout(() => {
            msg.classList.add('show');

            setTimeout(() => {
                msg.classList.remove('show');
                msg.classList.add('hiding');
                
                setTimeout(() => msg.remove(), 500);
            }, 12000);
        }, index * 150);

        const closeBtn = msg.querySelector('.log-close-btn');
        closeBtn.addEventListener('click', () => {
            msg.classList.remove('show');
            msg.classList.add('hiding');
            setTimeout(() => msg.remove(), 500);
        });
    });
}

manageNotifications();

new MutationObserver(manageNotifications).observe(document.body, {
    childList: true,
    subtree: true
});
</script>

<style>
.img-con {
	width: 65px;
	height: 45px;
	display: flex;
	justify-content: center;
	overflow: visible;
}

#flag {
	width: auto;
	height: auto;
	max-width: 65px;
	max-height: 45px;
	object-fit: contain;
}

.status-icon {
	width: 48px;
	height: 48px;
	object-fit: contain;
	display: block;
}

.status-icons {
	display: flex;
	height: 45px;
	margin-left: auto;
}

.site-icon {
	display: flex;
	justify-content: center;
	height: 45px;
	margin: 0 6px;
}

.mx-1 {
	margin: 0 4px;
}

.site-icon[onclick*="github"] .status-icon {
	width: 51px;
	height: 49px;
}

.site-icon[onclick*="github"] {
	width: 50px;
	height: 47px;
	display: flex;
	justify-content: center;
}

.site-icon[onclick*="openai"] .status-icon {
	width: 52px;
	height: 54px;
	margin-top: -2px;
}

.site-icon[onclick*="openai"] {
	width: 52px;
	height: 54px;
	display: flex;
	justify-content: center;
}

.container-sm.container-bg.callout.border {
	padding: 12px 15px;
	min-height: 70px;
	margin-bottom: 15px;
}

.row.align-items-center {
	width: 100%;
	margin: 0;
	display: flex;
	gap: 12px;
	height: 45px;
}

.col-3 {
	height: 45px;
	display: flex;
	flex-direction: column;
	justify-content: center;
}

.col.text-center {
	position: static;
	left: auto;
	transform: none;
}

.container-sm .row .col-4 {
	position: static !important;
	order: 2 !important;
	width: 100% !important;
	padding-left: 54px !important;
	margin-top: 5px !important;
	text-align: left !important;
}

#ping-result {
	font-weight: bold;
}

#d-ip {
	color: #09B63F;
	font-weight: 700 !important;
}

#d-ip > .ip-main {
	font-size: 14px !important;
}

#d-ip .badge-primary {
	font-size: 13px !important;
}

.info.small {
	color: #ff69b4;
	font-weight: 600;
	white-space: nowrap;
}

.site-icon, .img-con {
	cursor: pointer !important;
	transition: all 0.2s ease !important;
	position: relative !important;
	user-select: none !important;
}

.site-icon:hover, .img-con:hover {
	transform: translateY(-2px) !important;
}

.site-icon:active, .img-con:active {
	transform: translateY(1px) !important;
	opacity: 0.8 !important;
}

@media (max-width: 1206px) {
	.site-icon[onclick*="baidu"],
 .site-icon[onclick*="taobao"], 
 .site-icon[onclick*="google"],
 .site-icon[onclick*="openai"],
 .site-icon[onclick*="youtube"],
 .site-icon[onclick*="github"] {
		display: none !important;
	}
}

.animation-modal {
        position: absolute;
        top: 100px;
        left: 50%;
        transform: translateX(-50%);
        z-index: 1050;
        display: none;
}

.animation-modal-content {
        background: linear-gradient(135deg, #1e3c72, #2a5298);
        padding: 30px 40px;
        border-radius: 20px;
        box-shadow: 0 15px 30px rgba(0, 0, 0, 0.15);
        max-width: 400px;
        width: 90%;
        text-align: center;
        color: white;
        animation: scaleIn 0.3s ease;
}

.animation-modal-content button {
        display: block;
        width: 100%;
        padding: 12px 20px;
        margin: 10px 0;
        font-size: 1rem;
        border: none;
        border-radius: 12px;
        background: rgba(255, 255, 255, 0.2);
        color: white;
        cursor: pointer;
        transition: background 0.3s, transform 0.2s;
}

.animation-modal-content button:hover {
        background: rgba(255, 255, 255, 0.3);
        transform: scale(1.03);
}

@keyframes scaleIn {
        from {
            transform: scale(0.85);
            opacity: 0;
        }
        to {
            transform: scale(1);
            opacity: 1;
        }
}
</style>

<link rel="stylesheet" href="./assets/bootstrap/bootstrap.min.css">
<link rel="stylesheet" href="./assets/bootstrap/all.min.css">
<link rel="stylesheet" href="./assets/bootstrap/bootstrap-icons.css">
<link rel="stylesheet" href="./assets/bootstrap/leaflet.css">
<link rel="stylesheet" href="./assets/bootstrap/Control.FullScreen.min.css">
<link rel="stylesheet" href="./assets/bootstrap/custom.css">
<link rel="icon" href="./assets/img/nekobox.png">

<script src="./assets/bootstrap/jquery.min.js"></script>
<script src="./assets/bootstrap/bootstrap.bundle.min.js"></script>
<script src="./assets/js/feather.min.js"></script>
<script src="./assets/bootstrap/interact.min.js"></script>
<script src="./assets/bootstrap/Sortable.min.js"></script>
<script src="./assets/bootstrap/leaflet.js"></script>
<script src="./assets/bootstrap/Control.FullScreen.min.js"></script>
<script src="./assets/js/neko.js"></script>

<?php
$translate = [

];
$lang = $_GET['lang'] ?? 'en';
?>

<?php if (in_array($currentLang, ['zh', 'en', 'hk', 'vi', 'ja', 'ru', 'ar', 'es', 'ko', 'de', 'fr'])): ?>
    <div id="status-bar-component" class="container-sm container-bg mt-4" style="display: none;">
        <div class="row align-items-center">
            <div class="col-auto">
                <div class="img-con">
                    <img src="./assets/neko/img/loading.svg" id="flag" title="<?php echo $translations['refresh_ip']; ?>" onclick="IP.getIpipnetIP()">
                </div>
            </div>
            <div class="col-3">
                <p id="d-ip" class="ip-address mb-0">Checking...</p>
                <p id="ipip" class="info small mb-0"></p>
            </div>
            <div class="col text-center"> 
                <p id="ping-result" class="mb-0"></p>
            </div>
            <div class="col-auto ms-auto">
                <div class="status-icons d-flex">
                    <div class="site-icon mx-1" onclick="pingHost('baidu', 'Baidu')">
                        <img src="./assets/neko/img/site_icon_01.png" id="baidu-normal" title="<?php echo sprintf($translations['test_latency'], 'Baidu'); ?>" class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_01.png" id="baidu-gray" class="status-icon">
                    </div>
                    <div class="site-icon mx-1" onclick="pingHost('taobao', 'Taobao')">
                        <img src="./assets/neko/img/site_icon_02.png" id="taobao-normal" title="<?php echo sprintf($translations['test_latency'], 'Taobao'); ?>"  class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_02.png" id="taobao-gray" class="status-icon">
                    </div>
                    <div class="site-icon mx-1" onclick="pingHost('google', 'Google')">
                        <img src="./assets/neko/img/site_icon_03.png" id="google-normal" title="<?php echo sprintf($translations['test_latency'], 'Google'); ?>"  class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_03.png" id="google-gray" class="status-icon">
                    </div>
                    <div class="site-icon mx-1" onclick="pingHost('openai', 'OpenAI')">
                        <img src="./assets/neko/img/site_icon_06.png" id="openai-normal" title="<?php echo sprintf($translations['test_latency'], 'OpenAI'); ?>"  class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_06.png" id="openai-gray" class="status-icon">
                    </div>
                    <div class="site-icon mx-1" onclick="pingHost('youtube', 'YouTube')">
                        <img src="./assets/neko/img/site_icon_04.png" id="youtube-normal" title="<?php echo sprintf($translations['test_latency'], 'YouTube'); ?>" class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_04.png" id="youtube-gray" class="status-icon">
                    </div>
                    <div class="site-icon mx-1" onclick="pingHost('github', 'GitHub')">
                        <img src="./assets/neko/img/site_icon_05.png" id="github-normal" title="<?php echo sprintf($translations['test_latency'], 'GitHub'); ?>" class="status-icon" style="display: none;">
                        <img src="./assets/neko/img/site_icon1_05.png" id="github-gray" class="status-icon">
                    </div>
                </div>
            </div>
        </div>
    </div>
<?php endif; ?>

<script type="text/javascript">
const _IMG = './assets/neko/';
const translate = <?php echo json_encode($translate, JSON_UNESCAPED_UNICODE); ?>;
let cachedIP = null;
let cachedInfo = null;
let random = parseInt(Math.random() * 100000000);

const sitesToPing = {
    baidu: { url: 'https://www.baidu.com', name: 'Baidu' },
    taobao: { url: 'https://www.taobao.com', name: 'Taobao' },
    google: { url: 'https://www.google.com', name: 'Google' },
    youtube: { url: 'https://www.youtube.com', name: 'YouTube' },
    github: { url: 'https://www.github.com', name: 'GitHub' },
    openai : { url: 'https://www.openai.com', name: 'OpenAI' }
};

async function checkAllPings() {
    const pingResults = {};
    for (const [key, site] of Object.entries(sitesToPing)) {
        const { url, name } = site;
        try {
            const startTime = performance.now();
            await fetch(url, { mode: 'no-cors', cache: 'no-cache' });
            const endTime = performance.now();
            const pingTime = Math.round(endTime - startTime);
            pingResults[key] = { name, pingTime };
        } catch (error) {
            pingResults[key] = { name, pingTime: '超时' };
        }
    }
    return pingResults;
}

const checkSiteStatus = {
    sites: {
        baidu: 'https://www.baidu.com',
        taobao: 'https://www.taobao.com',
        google: 'https://www.google.com',
        youtube: 'https://www.youtube.com',
        github: 'https://www.github.com',
        openai: 'https://www.openai.com'
    },
    
    check: async function() {
        for (let [site, url] of Object.entries(this.sites)) {
            try {
                const response = await fetch(url, {
                    mode: 'no-cors',
                    cache: 'no-cache'
                });
                
                document.getElementById(`${site}-normal`).style.display = 'inline';
                document.getElementById(`${site}-gray`).style.display = 'none';
            } catch (error) {
                document.getElementById(`${site}-normal`).style.display = 'none';
                document.getElementById(`${site}-gray`).style.display = 'inline';
            }
        }
    }
};

async function pingHost(site, siteName) {
    const url = checkSiteStatus.sites[site];
    const resultElement = document.getElementById('ping-result');

    try {
        resultElement.innerHTML = `<span style="font-size: 22px">${translations.testing_latency.replace('%s', siteName)}...</span>`;
        resultElement.style.color = '#87CEFA';
        resultElement.style.display = 'block';

        const startTime = performance.now();
        await fetch(url, {
            mode: 'no-cors',
            cache: 'no-cache'
        });
        const endTime = performance.now();
        const pingTime = Math.round(endTime - startTime);

        resultElement.innerHTML = `<span style="font-size: 22px">${translations.latency_result.replace('%s', siteName).replace('%d', pingTime)}</span>`;

        if (pingTime <= 300) {
            resultElement.style.color = '#09B63F';  
        } else if (pingTime <= 700) {
            resultElement.style.color = '#FFA500';  
        } else {
            resultElement.style.color = '#ff6b6b';  
        }
    } catch (error) {
        resultElement.innerHTML = `<span style="font-size: 22px">${translations.connection_timeout.replace('%s', siteName)}</span>`;
        resultElement.style.color = '#ff6b6b';
        resultElement.style.display = 'block';
    }
    setTimeout(() => {
        resultElement.style.display = 'none';
    }, 6000);
}

document.addEventListener('DOMContentLoaded', () => {
    const translationBtn = document.getElementById('translationToggleBtn');
    const translationText = document.getElementById('translationToggleText');
    const translationIcon = document.getElementById('translationToggleIcon').querySelector('i');

    if (!localStorage.getItem('translationEnabled')) {
        localStorage.setItem('translationEnabled', 'false');
    }

    const updateButtonState = () => {
        const isEnabled = localStorage.getItem('translationEnabled') === 'true';
        translationText.textContent = isEnabled
            ? (langData[currentLang]?.disable || 'Disable')
            : (langData[currentLang]?.enable || 'Enable');

        translationIcon.className = isEnabled
            ? 'bi bi-toggle-on text-success'
            : 'bi bi-toggle-off text-white';
    };

    updateButtonState();

    translationBtn.addEventListener('click', () => {
        const newState = localStorage.getItem('translationEnabled') !== 'true';
        localStorage.setItem('translationEnabled', newState);
        updateButtonState();

        const spokenMessage = newState
            ? (langData[currentLang]?.translation_enabled || 'Translation Enabled')
            : (langData[currentLang]?.translation_disabled || 'Translation Disabled');
        speakMessage(spokenMessage);
        showLogMessage(spokenMessage);
        translationBtn.style.transform = "scale(0.95)";
        setTimeout(() => {
            translationBtn.style.transform = "scale(1)";
        }, 100);
    });
});

async function translateText(text, targetLang = null) {
    if (!text?.trim()) return text;

    if (!targetLang) {
        try {
            const response = await fetch('./lib/language.txt?t=' + new Date().getTime());
            if (response.ok) {
                const lang = await response.text();
                targetLang = lang.trim().toLowerCase() || 'zh';
            } else {
                targetLang = 'zh';
            }
        } catch (error) {
            targetLang = 'zh';
        }
    }
    
    const apiLangMap = {
        'zh':'zh-CN','zh-tw':'zh-TW','zh-CN':'zh-CN','hk':'zh-TW', 'zh-mo': 'zh-TW',
        'en':'en','ja':'ja','ko':'ko','fr':'fr','de':'de','es':'es',
        'it':'it','pt':'pt','ru':'ru','ar':'ar','hi':'hi','bn':'bn',
        'ms':'ms','id':'id','vi':'vi','th':'th','nl':'nl','pl':'pl',
        'tr':'tr','sv':'sv','no':'no','fi':'fi','da':'da','cs':'cs',
        'he':'he','el':'el','hu':'hu','ro':'ro','sk':'sk','bg':'bg','uk':'uk'
    };
    
    const apiTargetLang = apiLangMap[targetLang.toLowerCase()] || 'zh-CN';

    const detectJP = (text) => /[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]/.test(text);
    const sourceLang = detectJP(text) ? 'ja' : 'en';

    const isSameLang = () => {
        const sourceBase = sourceLang.split('-')[0];
        const targetBase = apiTargetLang.split('-')[0];
        return sourceBase === targetBase;
    };
    
    if (isSameLang()) return text;

    if (localStorage.getItem('translationEnabled') !== 'true') return text;

    const cacheKey = `trans_${sourceLang}_${apiTargetLang}_${text}`;
    const cached = localStorage.getItem(cacheKey);
    if (cached) return cached;

    const apis = [
        {
            url: `https://api.mymemory.translated.net/get?q=${encodeURIComponent(text)}&langpair=${sourceLang}|${apiTargetLang}&de=example@yourdomain.com`,
            method: 'GET',
            parse: data => data.responseData?.translatedText
        }
    ];

    const controller = new AbortController();
    try {
        const promises = apis.map(async (api) => {
            const timeoutPromise = new Promise((_, reject) => 
                setTimeout(() => reject('timeout'), api.timeout || 3000)
            );

            try {
                const fetchPromise = fetch(api.url, {
                    method: api.method,
                    headers: api.headers || {},
                    body: api.method === 'POST' ? api.body : undefined,
                    signal: controller.signal
                });
                
                const response = await Promise.race([fetchPromise, timeoutPromise]);
                if (!response.ok) throw new Error('API response not OK');
                const data = await response.json();
                return api.parse ? api.parse(data) : data?.translatedText;
            } catch (e) {
                return null;
            }
        });

        for (const promise of promises) {
            const result = await promise;
            if (result) {
                localStorage.setItem(cacheKey, result);
                clearOldCache();
                return result;
            }
        }
    } finally {
        controller.abort();
    }

    return text;
}

function clearOldCache() {
    const cachePrefix = 'trans_';
    const cacheKeys = Object.keys(localStorage).filter(key => 
        key.startsWith(cachePrefix)
    );
    
    if (cacheKeys.length > 1000) {
        const itemsToRemove = cacheKeys.slice(0, cacheKeys.length - 1000);
        itemsToRemove.forEach(key => localStorage.removeItem(key));
    }
}

let IP = {
    isRefreshing: false,
    lastGeoData: null, 
    ipApis: [
        {url: 'https://api.ipify.org?format=json', type: 'json', key: 'ip'},
        {url: 'https://api-ipv4.ip.sb/geoip', type: 'json', key: 'ip'},
        {url: 'https://myip.ipip.net', type: 'text'},
        {url: 'http://pv.sohu.com/cityjson', type: 'text'},
        {url: 'https://ipinfo.io/json', type: 'json', key: 'ip'},
        {url: 'https://ipapi.co/json/', type: 'json'},
        {url: 'https://freegeoip.app/json/', type: 'json'}
    ],

    fetchIP: async () => {
        let error;
        for(let api of IP.ipApis) {
            try {
                const response = await IP.get(api.url, api.type);
                if(api.type === 'json') {
                    const ipData = api.key ? response.data[api.key] : response.data;
                    cachedIP = ipData;
                    document.getElementById('d-ip').innerHTML = ipData;
                    return ipData;
                } else {
                    const ipData = response.data.match(/\d+\.\d+\.\d+\.\d+/)?.[0];
                    if(ipData) {
                        cachedIP = ipData;
                        document.getElementById('d-ip').innerHTML = ipData;
                        return ipData;
                    }
                }
            } catch(e) {
                error = e;
                console.error(`Error with ${api.url}:`, e);
                continue;
            }
        }
        throw error || new Error("All IP APIs failed");
    },

    get: (url, type) =>
        fetch(url, { 
            method: 'GET',
            cache: 'no-store'
        }).then((resp) => {
            if (type === 'text')
                return Promise.all([resp.ok, resp.status, resp.text(), resp.headers]);
            else
                return Promise.all([resp.ok, resp.status, resp.json(), resp.headers]);
        }).then(([ok, status, data, headers]) => {
            if (ok) {
                return { ok, status, data, headers };
            } else {
                throw new Error(JSON.stringify(data.error));
            }
        }).catch(error => {
            console.error("Error fetching data:", error);
            throw error;
        }),

    Ipip: async (ip, elID) => {
        const geoApis = [
            {url: `https://api.ip.sb/geoip/${ip}`, type: 'json'},
            {url: 'https://myip.ipip.net', type: 'text'},
            {url: `http://ip-api.com/json/${ip}`, type: 'json'},
            {url: `https://ipinfo.io/${ip}/json`, type: 'json'},
            {url: `https://ipapi.co/${ip}/json/`, type: 'json'},
            {url: `https://freegeoip.app/json/${ip}`, type: 'json'}
        ];

        let geoData = null;
        let error;

        for(let api of geoApis) {
            try {
                const response = await IP.get(api.url, api.type);
                geoData = response.data;
                break;
            } catch(e) {
                error = e;
                console.error(`Error with ${api.url}:`, e);
                continue;
            }
        }

        if(!geoData) {
            throw error || new Error("All Geo APIs failed");
        }

        cachedIP = ip;
        IP.lastGeoData = geoData; 
        
        IP.updateUI(geoData, elID);
    },

    updateUI: async (data, elID) => {
        try {
            const country = await translateText(data.country || translations['unknown']);
            const region = await translateText(data.region || "");
            const city = await translateText(data.city || "");
            const isp = await translateText(data.isp || "");
            const asnOrganization = await translateText(data.asn_organization || "");

            let location = `${region && city && region !== city ? `${region} ${city}` : region || city || ''}`;

            let displayISP = isp;
            let displayASN = asnOrganization;

            if (isp && asnOrganization && asnOrganization.includes(isp)) {
                displayISP = '';  
            } else if (isp && asnOrganization && isp.includes(asnOrganization)) {
                displayASN = '';  
            }

            const isSmallScreen = window.innerWidth < 768; 

            let locationInfo;
            if (isSmallScreen) {
                locationInfo = `<span style="margin-left: 8px; position: relative; top: -4px;">${location} ${data.asn || ''} ${displayASN}</span>`;
            } else {
                locationInfo = `<span style="margin-left: 8px; position: relative; top: -4px;">${location} ${displayISP} ${data.asn || ''} ${displayASN}</span>`;
            }

            const isHidden = localStorage.getItem("ipHidden") === "true";

            let simpleDisplay = `
                <div class="ip-row" style="display: flex; align-items: center; gap: 8px; flex-wrap: nowrap;">
                    <div class="ip-main" style="cursor: pointer;" onclick="handleIPClick()" title="${translations['show_ip']}">
                        <div style="display: flex; align-items: center; gap: 5px;">
                            <span id="ip-address" style="margin-left: 0.3ch">${isHidden ? '**.**.**.**.**' : cachedIP}</span> 
                            <span class="badge badge-primary" style="color: #333;">${country}</span>
                        </div>
                    </div>

                    <span id="toggle-ip" style="cursor: pointer; text-indent: 0.3ch; padding-top: 2px;" title="${translations['hide_ip']}">
                        <i class="bi ${isHidden ? 'bi-eye-slash' : 'bi-eye'}" style="font-size: 1.4rem; vertical-align: middle;"></i>  
                    </span>
            `;

            document.getElementById('d-ip').innerHTML = simpleDisplay;
            document.getElementById('ipip').innerHTML = locationInfo;

            const countryCode = data.country_code || 'unknown';
            const flagSrc = (countryCode !== 'unknown') ? _IMG + "flags/" + countryCode.toLowerCase() + ".png"  : './assets/neko/flags/cn.png';
            $("#flag").attr("src", flagSrc);

            const ipContainer = document.querySelector('.ip-row');
            const toggleIcon = document.getElementById('toggle-ip');
        
            if (ipContainer && toggleIcon) {

                toggleIcon.style.opacity = '0';

                ipContainer.addEventListener('mouseenter', function() {
                    toggleIcon.style.opacity = '1';
                });
            
                ipContainer.addEventListener('mouseleave', function() {
                    toggleIcon.style.opacity = '0';
                });
            }

            document.getElementById('toggle-ip').addEventListener('click', () => {
                const ipElement = document.getElementById('ip-address');
                const iconElement = document.getElementById('toggle-ip').querySelector('i');

                if (ipElement.textContent === cachedIP) {
                    ipElement.textContent = '***.***.***.***.***';
                    iconElement.classList.remove('bi-eye');
                    iconElement.classList.add('bi-eye-slash');  
                    localStorage.setItem("ipHidden", "true");  
                } else {
                    ipElement.textContent = cachedIP;  
                    iconElement.classList.remove('bi-eye-slash');
                    iconElement.classList.add('bi-eye');  
                    localStorage.setItem("ipHidden", "false");  
                }
            });

        } catch (error) {
            console.error("Error in updateUI:", error);
            document.getElementById('d-ip').innerHTML = langData[currentLang]['connection_timeout'];
            $("#flag").attr("src", "./assets/neko/flags/mo.png");
        }
    },

    showDetailModal: async () => {
        const data = IP.lastGeoData;
        if (!data) return;

        const translatedCountry = await translateText(data.country, currentLang) || data.country || langData[currentLang]['unknown'];
        const translatedRegion = await translateText(data.region, currentLang) || data.region || "";
        const translatedCity = await translateText(data.city, currentLang) || data.city || "";
        const translatedIsp = await translateText(data.isp, currentLang) || data.isp || "";
        const translatedAsnOrganization = await translateText(data.asn_organization, currentLang) || data.asn_organization || "";

        let country = translatedCountry;
        let region = translatedRegion;
        let city = translatedCity;
        let isp = translatedIsp;
        let asnOrganization = translatedAsnOrganization;
        let timezone = data.timezone || "";
        let asn = data.asn || "";

        let areaParts = [country, region, city].filter(Boolean);

        if (region && city && region === city) {
            areaParts = [country, region];
        }

        if (country && region && country === region) {
            areaParts = [country];
        }

        if (country && city && country === city) {
            areaParts = [country];
        }
        let areaDisplay = areaParts.join(" ");

        const pingResults = await checkAllPings();
        const delayInfoHTML = Object.entries(pingResults).map(([key, { name, pingTime }]) => {
            let color = '#ff6b6b';
            if (typeof pingTime === 'number') {
                color = pingTime <= 300 ? '#09B63F' : pingTime <= 700 ? '#FFA500' : '#ff6b6b';
            }
            return `<span style="margin-right: 20px; font-size: 18px; color: ${color};">${name}: ${pingTime === '超时' ? langData[currentLang]['timeout'] : `${pingTime}ms`}</span>`;
        }).join('');

        let lat = data.latitude || null;
        let lon = data.longitude || null;

        if (!lat || !lon) {
            try {
                const response = await fetch(`https://ipapi.co/${cachedIP}/json/`);
                const geoData = await response.json();
                lat = geoData.latitude;
                lon = geoData.longitude;
            } catch (error) {
                console.error(langData[currentLang]['geo_location_error'], error);
            }
        }

        const modalHTML = `
            <div class="modal fade custom-modal" id="ipDetailModal" tabindex="-1" role="dialog" aria-labelledby="ipDetailModalLabel" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
                <div class="modal-dialog modal-xl draggable" role="document">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title" id="ipDetailModalLabel">${translations['ip_info']}</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div class="detail-row">
                                <span class="detail-label">${translations['ip_address']}:</span>
                                <span class="detail-value">${cachedIP}</span>
                            </div>
                            <div class="detail-row">
                                <span class="detail-label">${translations['location']}:</span>
                                <span class="detail-value">${areaDisplay}</span>
                            </div>
                            <div class="detail-row">
                                <span class="detail-label">${translations['isp']}:</span>
                                <span class="detail-value">${isp}</span>
                            </div>
                            <div class="detail-row">
                                <span class="detail-label">${translations['asn']}:</span>
                                <span class="detail-value">${asn} ${asnOrganization}</span>
                            </div>
                            <div class="detail-row">
                                <span class="detail-label">${translations['timezone']}:</span>
                                <span class="detail-value">${timezone}</span>
                            </div>
                            ${lat && lon ? `
                            <div class="detail-row">
                                <span class="detail-label">${translations['latitude_longitude']}:</span>
                                <span class="detail-value">${lat}, ${lon}</span>
                            </div>
                            <div class="detail-row" style="height: 400px; margin-top: 20px;">
                                <div id="leafletMap" style="width: 100%; height: 100%;"></div>
                            </div>` : ''}
                            <h5 style="margin-top: 15px;">${translations['latency_info']}:</h5>
                            <div class="detail-row" style="display: flex; flex-wrap: wrap;">
                                ${delayInfoHTML}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;

        $('#ipDetailModal').remove();
        $('body').append(modalHTML);
        $('#ipDetailModal').modal('show');

        if (lat && lon) {
            setTimeout(() => {
                if (window._leafletMap) {
                    window._leafletMap.remove();
                }
                window._leafletMap = L.map('leafletMap').setView([lat, lon], 10);
                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: ''
                }).addTo(window._leafletMap);
                const areaDisplayForPopup = [country, region].filter(Boolean).join(" ");
                L.marker([lat, lon])
                    .addTo(window._leafletMap)
                    .bindPopup(areaDisplay)
                    .openPopup();
                try {
                    if (typeof L.Control.FullScreen !== 'undefined') {
                        const fullscreenControl = new L.Control.FullScreen({
                            position: 'topright',
                            title: 'Full Screen',
                            titleCancel: 'Exit Full Screen',
                            content: null
                        });
                        window._leafletMap.addControl(fullscreenControl);
                        console.log('FullScreen control added:', fullscreenControl);
                    } else {
                        console.error('FullScreen control plugin is not loaded.');
                    }
                } catch (error) {
                    console.error('Error adding FullScreen control:', error);
                }
            }, 200);
        }
    },

    getIpipnetIP: async () => {
        if (IP.isRefreshing) return;

        try {
            IP.isRefreshing = true;
            document.getElementById('d-ip').innerHTML = `
                <div class="ip-main">
                    <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
                    ${langData[currentLang]['checking']} 
                </div>
            `;
            document.getElementById('ipip').innerHTML = "";
            $("#flag").attr("src", _IMG + "img/loading.svg");

            const ip = await IP.fetchIP();
            await IP.Ipip(ip, 'ipip');
        } catch (error) {
            console.error("Error in getIpipnetIP function:", error);
            document.getElementById('ipip').innerHTML = langData[currentLang]['ip_info_fail'];
        } finally {
            IP.isRefreshing = false;
        }
    }
};

const style = document.createElement('style');
style.textContent = `
.ip-main {
	font-size: 15px;
	padding: 5px;
	transition: all 0.3s;
	display: inline-flex;
	align-items: center;
	gap: 8px;
}

.badge-primary {
	color: #ff69b4 !important;
	background-color: #f8f9fa !important;
	border: 1px solid #dee2e6;
}

#ipip {
	margin-left: -3px;
	font-size: 1rem;
	color: rgb(255, 0, 255) !important;
}

.ip-main:hover {
	background: #f0f0f0;
	border-radius: 4px;
}

.ip-details {
	font-size: 18px !important;
	line-height: 1.6;
}

.detail-row {
	display: flex;
	margin-bottom: 10px;
	line-height: 1.6;
}

.detail-label {
	flex: 0 0 200px;
	text-align: left;
	font-weight: 500;
	padding-right: 18px;
}

.detail-value {
	flex: 1;
	text-align: left;
	word-break: break-all;
	margin-left: 0;
}
`;
document.head.appendChild(style);
IP.getIpipnetIP();
if(typeof checkSiteStatus !== 'undefined') {
    checkSiteStatus.check();
    setInterval(() => checkSiteStatus.check(), 30000);
}

setInterval(IP.getIpipnetIP, 180000);
</script>

<script>
function handleIPClick() {
    if (window.innerWidth <= 768) {
        return;
    }
    IP.showDetailModal();
}
</script>

<script>
    function toggleControlPanel() {
        const overlay = document.getElementById('controlPanelOverlay');
        if (overlay.style.display === 'none' || overlay.style.display === '') {
            overlay.style.display = 'flex';
        } else {
            overlay.style.display = 'none';
        }
    }

    const colorPicker = document.getElementById('colorPicker');
    const controlPanel = document.querySelector('.control-panel');

    colorPicker.addEventListener('input', function() {
        const color = this.value;
        controlPanel.style.background = `linear-gradient(135deg, ${color}, #1a508b, #2d8bc0)`;
    });

    document.querySelectorAll('.panel-btn, .panel-close-btn, .close-icon').forEach(button => {
        button.addEventListener('mousedown', function() {
            this.style.transform = 'translateY(0)';
        });

        button.addEventListener('mouseup', function() {
            this.style.transform = this.classList.contains('panel-close-btn') || this.classList.contains('close-icon') ? 
                'translateY(-3px)' : 'translateY(0)';
        });

        button.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
        });
    });
</script>

<script>
document.addEventListener('keydown', function(event) {
    if (event.ctrlKey && event.shiftKey && event.code === 'KeyC') {
        clearCache();
        event.preventDefault();  
    }
});

document.getElementById('clear-cache-btn').addEventListener('click', function() {
    clearCache();
});

const notificationMessage = translations['cache_cleared_notification'];
const speechMessage = translations['cache_cleared_speech'];

function clearCache() {
    location.reload(true); 

    localStorage.clear();
    sessionStorage.clear();

    sessionStorage.setItem('cacheCleared', 'true');

    showLogMessage(translations['notificationMessage']);
    speakMessage(translations['notificationMessage']);
}

window.addEventListener('load', function() {
    if (sessionStorage.getItem('cacheCleared') === 'true') {
        showLogMessage(translations['notificationMessage']);
        speakMessage(translations['notificationMessage']);
        sessionStorage.removeItem('cacheCleared'); 
    }
});
</script>

<script>
const bars = document.querySelectorAll('.bar');
function synthWave() {
  const time = Date.now() / 1000;
  
  bars.forEach((bar, i) => {
    const frequency = 0.5 + i * 0.2; 
    const amplitude = Math.sin(time * frequency) * 50 + 50; 
    const height = amplitude * (0.8 + Math.random() * 0.2); 
    
    bar.style.height = `${Math.max(5, height)}%`;
    bar.style.backgroundColor = `hsl(${(time * 50 + i * 30) % 360}, 80%, 60%)`;
  });
  
  requestAnimationFrame(synthWave);
}
synthWave();
</script> 

<script>
function toggleFloatingLyrics() {
    const lyrics = document.getElementById('floatingLyrics');
    const isHidden = lyrics.style.display === 'none';
    lyrics.style.display = isHidden ? '' : 'none';
    localStorage.setItem('floatingLyricsVisible', isHidden ? 'true' : 'false');

    document.querySelectorAll('.toggleFloatingLyricsBtn i').forEach(icon => {
        icon.className = isHidden ? 'bi bi-display-fill floatingIcon' : 'bi bi-display floatingIcon';
    });
}

document.addEventListener('DOMContentLoaded', () => {
    const lyrics = document.getElementById('floatingLyrics');
    const isVisible = localStorage.getItem('floatingLyricsVisible') === 'true';

    lyrics.style.display = isVisible ? '' : 'none';

    document.querySelectorAll('.toggleFloatingLyricsBtn i').forEach(icon => {
        icon.className = isVisible ? 'bi bi-display-fill floatingIcon' : 'bi bi-display floatingIcon';
    });

    document.querySelectorAll('.toggleFloatingLyricsBtn').forEach(btn => {
        btn.addEventListener('click', toggleFloatingLyrics);
    });
});
</script>

<script>
const audioPlayer = new Audio();
let songs = JSON.parse(localStorage.getItem('cachedPlaylist') || '[]');
let currentTrackIndex = JSON.parse(localStorage.getItem('currentTrackIndex') || '0');
let isPlaying = JSON.parse(localStorage.getItem('isPlaying') || 'false');
let repeatMode = JSON.parse(localStorage.getItem('repeatMode') || '0');
let isHovering = false;
let isManualScroll = false;
let isSmallScreen = window.innerWidth < 768;

const showLogMessage = (function() {
    let currentIndex = 0;
    const activeLogs = new Set();
    const BASE_OFFSET = 20;
    const MARGIN = 10;

    function createIcon(type) {
        const icons = {
            error: 'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z',
            warning: 'M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z',
            info: 'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z'
        };

        const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="#fff" d="${icons[type] || icons.info}"/></svg>`;

        return `data:image/svg+xml;base64,${btoa(svg)}`;
    }

    function updatePositions() {
        let verticalPos = BASE_OFFSET;
        activeLogs.forEach(log => {
            log.style.transform = `translateY(${verticalPos}px)`;
            verticalPos += log.offsetHeight + MARGIN;
        });
    }

    return function(message, type = '') {
        const logBox = document.createElement('div');
        logBox.className = `log-box ${type}`;

        if (!type) {
            logBox.dataset.dynamicBg = 'true';
        }

        logBox.innerHTML = `
            <div class="log-content">
                <span class="log-icon" style="background-image:url('${createIcon(type)}')"></span>
                ${decodeURIComponent(message)}
                <button class="log-close-btn">&times;</button>
            </div>
        `;

        logBox.querySelector('.log-close-btn').onclick = () => {
            logBox.classList.add('exiting');
            setTimeout(() => {
                logBox.remove();
                activeLogs.delete(logBox);
                updatePositions();
            }, 300);
        };

        logBox.addEventListener('mouseenter', () =>
            logBox.style.animationPlayState = 'paused');
        logBox.addEventListener('mouseleave', () =>
            logBox.style.animationPlayState = 'running');

        document.body.appendChild(logBox);
        activeLogs.add(logBox);

        requestAnimationFrame(() => {
            logBox.classList.add('active');
            updatePositions();
        });

        setTimeout(() => {
            logBox.classList.add('exiting');
            setTimeout(() => {
                logBox.remove();
                activeLogs.delete(logBox);
                updatePositions();
            }, 300);
        }, 12000);
    };
})();

function togglePlay() {
    if (isPlaying) {
        audioPlayer.pause();
        const pauseMessage = translations['pause_playing'] || 'Pause_Playing';
        showLogMessage(pauseMessage);
        speakMessage(pauseMessage);
    } else {
        audioPlayer.play();
        const playMessage = translations['start_playing'] || 'Start_Playing';
        showLogMessage(playMessage);
        speakMessage(playMessage);
    }
    isPlaying = !isPlaying;
    updatePlayButton();
    savePlayerState();

    const btn = event.target.closest('button');
    if(btn) {
        btn.classList.add('clicked');
        setTimeout(() => btn.classList.remove('clicked'), 200);
    }
}

function updatePlayButton() {
    const btn = document.getElementById('playPauseBtn');
    const floatingBtn = document.getElementById('floatingPlayBtn');
    const icon = isPlaying ? 'bi-pause-fill' : 'bi-play-fill';
    
    btn.innerHTML = `<i class="bi ${icon}"></i>`;
    floatingBtn.innerHTML = `<i class="bi ${icon}"></i>`;
}

function changeTrack(direction, isManual = false) {
    const oldSong = songs[currentTrackIndex];
    
    if (repeatMode === 2 && !isManual) { 
        currentTrackIndex = Math.floor(Math.random() * songs.length);
    } else {
        currentTrackIndex = (currentTrackIndex + direction + songs.length) % songs.length;
    }

    const songName = decodeURIComponent(
        songs[currentTrackIndex].split('/').pop().replace(/\.\w+$/, '')
    );

    if (isManual) {
        const action = direction === -1
            ? translations['previous_track'] || 'Previous Track'
            : translations['next_track'] || 'Next Track';
        showLogMessage(`${translations['manual_switch'] || 'Manual Switch'}${action}：${songName}`);
        speakMessage(`${translations['switch_to'] || 'Switch to'}${action}：${songName}`);
    } else {
        showLogMessage(`${translations['auto_switch'] || 'Auto Switch to'}：${songName}`);
        speakMessage(`${translations['auto_play'] || 'Auto Play'}：${songName}`);
    }

    loadTrack(songs[currentTrackIndex]);
}

function toggleRepeat() {
    repeatMode = (repeatMode + 1) % 3;
    const mainBtn = document.getElementById('repeatBtn');
    const floatingBtn = document.getElementById('floatingRepeatBtn');

    [mainBtn, floatingBtn].forEach(btn => {
        btn.classList.remove('btn-success', 'btn-warning');
        btn.title = [
            translations['order_play'] || 'Order_Play',
            translations['single_loop'] || 'Single_Loop',
            translations['shuffle_play'] || 'Shuffle_Play'
        ][repeatMode];

        switch (repeatMode) {
            case 0:
                btn.innerHTML = '<i class="bi bi-arrow-repeat"></i>';
                break;
            case 1:
                btn.innerHTML = '<i class="bi bi-repeat-1"></i>';
                btn.classList.add('btn-success');
                break;
            case 2:
                btn.innerHTML = '<i class="bi bi-shuffle"></i>';
                btn.classList.add('btn-warning');
                break;
        }
    });

    showLogMessage([
        translations['order_play'] || 'Order_Play',
        translations['single_loop'] || 'Single_Loop',
        translations['shuffle_play'] || 'Shuffle_Play'
    ][repeatMode]);
    speakMessage([
        translations['order_play'] || 'Order_Play',
        translations['single_loop'] || 'Single_Loop',
        translations['shuffle_play'] || 'Shuffle_Play'
    ][repeatMode]);
    savePlayerState();
}

function updatePlaylistUI() {
    const playlist = document.getElementById('playlist');
    playlist.innerHTML = songs.map((url, index) => `
        <div class="playlist-item ${index === currentTrackIndex ? 'active' : ''}" 
             onclick="playTrack(${index})">
            ${decodeURIComponent(url.split('/').pop().replace(/\.\w+$/, ''))}
        </div>
    `).join('');
    showLogMessage(`Playlist loaded: ${songs.length} songs`);
    setTimeout(() => scrollToCurrentTrack(), 100);
}

function updatePlaylist() {
    const btn = document.getElementById('updatePlaylistBtn');
    const originalHTML = btn.innerHTML;
    btn.innerHTML = '<i class="bi bi-arrow-repeat spinning"></i>';
    
    fetch('<?php echo $new_url; ?>')
        .then(response => response.text())
        .then(data => {
            const newSongs = data.split('\n')
                .filter(url => url.trim());
            
            songs = newSongs;
            localStorage.setItem('cachedPlaylist', JSON.stringify(songs));
            
            if (currentTrackIndex >= songs.length) {
                currentTrackIndex = 0;
            }

            updatePlaylistUI();
            
            if (songs.length > 0 && songs[currentTrackIndex]) {
                loadTrack(songs[currentTrackIndex]);
            }
            
            btn.innerHTML = originalHTML;
            
            const successMsg = translations['playlist_updated'] 
                ? translations['playlist_updated'] 
                : 'Playlist updated successfully';
            const songCountMsg = translations['song_count'] 
                ? translations['song_count'].replace('{count}', songs.length) 
                : `Total ${songs.length} songs`;
            
            showLogMessage(`${successMsg}，${songCountMsg}`);
            speakMessage(`${successMsg}，${songCountMsg}`);
        })
        .catch(error => {
            console.error('Playlist update failed:', error);
            
            btn.innerHTML = '<i class="bi bi-x-circle"></i>';
            setTimeout(() => {
                btn.innerHTML = originalHTML;
            }, 1000);
            
            const errorMsg = translations['update_failed'] 
                ? translations['update_failed'] 
                : 'Playlist update failed';
            showLogMessage(errorMsg, 'error');
            speakMessage(errorMsg);
        });
}

function playTrack(index) {
    const songName = decodeURIComponent(songs[index].split('/').pop().replace(/\.\w+$/, ''));
    const message = `${translations['playlist_click'] || 'Playlist Click'}：${translations['index'] || 'Index'}：${index + 1}，${translations['song_name'] || 'Song Name'}：${songName}`;
    audioPlayer.pause();
    currentTrackIndex = index;
    loadTrack(songs[index]);
    
    isPlaying = true;
    audioPlayer.play().catch((error) => {
        isPlaying = false;
    });
    
    updatePlayButton();
    savePlayerState();
    showLogMessage(message);
    speakMessage(message);
    
    event.target.classList.add('clicked');
    setTimeout(() => event.target.classList.remove('clicked'), 200);
}

function scrollToCurrentTrack() {
    const playlist = document.getElementById('playlist');
    const activeItem = playlist.querySelector('.playlist-item.active');
    if (activeItem) {
        activeItem.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
}

function loadLyrics(songUrl) {
    const lyricsUrl = songUrl.replace(/\.\w+$/, '.lrc');
    
    window.lyrics = {};
    window.lyricTimes = [];
    
    const containers = [
        document.getElementById('lyricsContainer'),
        document.querySelector('#floatingLyrics .vertical-lyrics')
    ];
    
    containers.forEach(container => {
        const message = translations['loading_lyrics'] || 'Loading Lyrics...';
        const verticalText = message.split('').map(char => `<span class="char">${char}</span>`).join('');
    
        const statusMsg = container.id === 'lyricsContainer' 
            ? `<div id="no-lyrics">${message}</div>`
            : `<div id="noLyricsFloating" class="vertical-message">${verticalText}</div>`;

        container.innerHTML = statusMsg;
    });

    fetch(lyricsUrl)
        .then(response => {
            if (!response.ok) {
                if (response.status === 404) {
                    throw new Error('LYRICS_NOT_FOUND');
                } else {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
            }
            return response.arrayBuffer();
        })
        .then(buffer => {
            const decoder = new TextDecoder('utf-8');
            parseLyrics(decoder.decode(buffer));
            displayLyrics();
            document.dispatchEvent(new Event('lyricsLoaded'));
        })
        .catch(error => {
            if (error.message === 'LYRICS_NOT_FOUND') {
                containers.forEach(container => {
                    if (container.id === 'lyricsContainer') {
                        container.innerHTML = `<div id="no-lyrics">${translations['no_lyrics'] || 'No Lyrics Available'}</div>`;
                    } else {
                        const message = translations['no_lyrics'] || 'No Lyrics Available';
                        const verticalText = message.split('').map(char => `<span class="char">${char}</span>`).join('');
                        container.innerHTML = `<div id="noLyricsFloating" class="vertical-text">${verticalText}</div>`;
                    }
                });
            } else {
                console.error(`${translations['lyrics_load_failed'] || 'Lyrics Load Failed'}:`, error);
                containers.forEach(container => {
                    if (container.id === 'lyricsContainer') {
                        container.innerHTML = `<div id="no-lyrics">${translations['lyrics_load_failed'] || 'Failed to load lyrics'}</div>`;
                    } else {
                        const message = translations['lyrics_load_failed'] || 'Failed to load lyrics';
                        const verticalText = message.split('').map(char => `<span class="char">${char}</span>`).join('');
                        container.innerHTML = `<div id="noLyricsFloating" class="vertical-message">${verticalText}</div>`;
                    }
                });
            }
        });
}

function parseLyrics(text) {
    window.lyrics = {};
    window.lyricTimes = [];
    const regex = /\[(\d+):(\d+)\.(\d+)\](.+)/g;
    let match;
    while ((match = regex.exec(text)) !== null) {
        const time = parseInt(match[1]) * 60 + parseInt(match[2]) + parseInt(match[3])/1000;
        const content = match[4].replace(/\[\d+:\d+\.\d+\]/g, '').trim();
        lyrics[time] = content;
        lyricTimes.push(time);
    }
    lyricTimes.sort((a, b) => a - b);
}

function tokenize(text) {
    const tokens = [];
    let currentWord = '';
    
    for (const char of text) {
        if (/\s/.test(char)) {
            if (currentWord) {
                tokens.push(currentWord);
                currentWord = '';
            }
            tokens.push({ type: 'space', value: char });
            continue;
        }

        if (/[-–—]/.test(char)) {
            if (currentWord) {
                tokens.push(currentWord);
                currentWord = '';
            }
            tokens.push({ type: 'punctuation', value: char });
            continue;
        }

        if (/[a-zA-Z0-9]/.test(char)) {
            currentWord += char;
        } else {
            if (currentWord) {
                tokens.push(currentWord);
                currentWord = '';
            }
            tokens.push({ type: 'char', value: char });
        }
    }

    if (currentWord) tokens.push(currentWord);
    return tokens;
}

function createCharSpans(text, startTime, endTime) {
    const tokens = tokenize(text);
    const totalDuration = endTime - startTime;
    const charCount = text.replace(/\s/g, '').length; 
    const durationPerChar = totalDuration / charCount;

    let charIndex = 0;
    const spans = [];

    tokens.forEach(token => {
        if (typeof token === 'string') { 
            const wordSpan = document.createElement('span');
            wordSpan.className = 'word';
            const letters = token.split('');
            
            letters.forEach(letter => {
                const span = document.createElement('span');
                span.className = 'char';
                span.textContent = letter;
                span.dataset.start = startTime + charIndex * durationPerChar;
                span.dataset.end = startTime + (charIndex + 1) * durationPerChar;
                wordSpan.appendChild(span);
                charIndex++;
            });
            
            spans.push(wordSpan);
        } else if (token.type === 'space') { 
            const spaceSpan = document.createElement('span');
            spaceSpan.className = 'char space';
            spaceSpan.innerHTML = '&nbsp;';
            spans.push(spaceSpan);
        } else if (token.type === 'punctuation') { 
            const punctSpan = document.createElement('span');
            punctSpan.className = 'char punctuation';
            punctSpan.textContent = token.value;
            punctSpan.dataset.start = startTime + charIndex * durationPerChar;
            punctSpan.dataset.end = startTime + (charIndex + 1) * durationPerChar;
            spans.push(punctSpan);
            charIndex++;
        } else { 
            const span = document.createElement('span');
            span.className = 'char';
            span.textContent = token.value;
            span.dataset.start = startTime + charIndex * durationPerChar;
            span.dataset.end = startTime + (charIndex + 1) * durationPerChar;
            spans.push(span);
            charIndex++;
        }
    });

    return spans;
}

function isEnglishWord(text) {
    return /^[a-zA-Z']+$/.test(text);
}

function createCharSpans(text, startTime, endTime) {
    const elements = [];
    const words = text.split(/(\s+)/); 
    
    let currentTime = startTime;
    const totalDuration = endTime - startTime;
    const validWords = words.filter(word => word.trim().length > 0);
    const durationPerWord = totalDuration / validWords.length;

    words.forEach(word => {
        if (word.trim().length === 0) return;

        const isEnglish = isEnglishWord(word.replace(/[^a-zA-Z']/g, ''));
        const span = document.createElement('span');
        span.className = 'char';
        
        if (isEnglish) {
            span.textContent = word;
            span.dataset.start = currentTime;
            span.dataset.end = currentTime + durationPerWord;
            currentTime += durationPerWord;
        } else {
            const chars = word.split('');
            const charDuration = durationPerWord / chars.length;
            chars.forEach((char, index) => {
                const charSpan = document.createElement('span');
                charSpan.className = 'char';
                charSpan.textContent = char;
                charSpan.dataset.start = currentTime + index * charDuration;
                charSpan.dataset.end = currentTime + (index + 1) * charDuration;
                elements.push(charSpan);
            });
            currentTime += durationPerWord;
            return;
        }
        
        elements.push(span);
    });

    return elements;
}

function displayLyrics() {
    const lyricsContainer = document.getElementById('lyricsContainer');
    const floatingLyrics = document.querySelector('#floatingLyrics .vertical-lyrics');
    
    lyricsContainer.innerHTML = '';
    floatingLyrics.innerHTML = '';

    if (Object.keys(window.lyrics).length === 0) {
        const message = translations['no_lyrics'] || 'No Lyrics Available';
        const verticalText = message.split('').map(char => `<span class="char">${char}</span>`).join('');
    
        lyricsContainer.innerHTML = `<div id="no-lyrics">${message}</div>`;
        floatingLyrics.innerHTML = `<div id="noLyricsFloating" class="vertical-message">${verticalText}</div>`;
        return;
    }

    lyricTimes.forEach((time, index) => {
        const line = document.createElement('div');
        line.className = 'lyric-line';
        line.dataset.time = time;
        
        const endTime = index < lyricTimes.length - 1 
                      ? lyricTimes[index + 1] 
                      : time + 3; 
        
        const elements = createCharSpans(lyrics[time], time, endTime);
        elements.forEach(element => line.appendChild(element));
        lyricsContainer.appendChild(line);
    });

    audioPlayer.addEventListener('timeupdate', syncLyrics);
}

document.addEventListener('DOMContentLoaded', () => {
    const lyricsContainer = document.getElementById('lyricsContainer');
    
    lyricsContainer.addEventListener('mouseenter', () => {
        isHovering = true;
    });

    lyricsContainer.addEventListener('mouseleave', () => {
        isHovering = false;
        isManualScroll = false;
    });

    lyricsContainer.addEventListener('scroll', () => {
        if (isHovering) {
            isManualScroll = true;
            setTimeout(() => {
                isManualScroll = false;
            }, 3000); 
        }
    });

    loadPlayerState();
    updatePlaylistUI();
});

function syncLyrics() {
    const currentTime = audioPlayer.currentTime;
    const lyricsContainer = document.getElementById('lyricsContainer');
    const lines = lyricsContainer.querySelectorAll('.lyric-line');
    let currentLine = null;
    let hasActiveLine = false;

    lines.forEach(line => {
    line.classList.remove('highlight', 'played');
    line.style.color = 'white'; 
    });

    for (let i = lines.length - 1; i >= 0; i--) {
        const line = lines[i];
        const lineTime = parseFloat(line.dataset.time);
        if (currentTime >= lineTime) {
            line.classList.add('highlight');
            currentLine = line;
            hasActiveLine = true;
            break;
        }
    }

    if (currentLine) {
        const chars = currentLine.querySelectorAll('.char');
        chars.forEach(char => {
            const start = parseFloat(char.dataset.start);
            const end = parseFloat(char.dataset.end);

            if (currentTime >= start && currentTime <= end) {
                char.classList.add('active');
            } else if (currentTime > end && !char.classList.contains('played')) {
                char.classList.add('played');
                spawnHeartAbove(char); 
            }
        });

        const floatingContainer = document.getElementById('floatingLyrics');
        const floatingLyrics = floatingContainer.querySelector('.vertical-lyrics');
        if (!floatingLyrics.innerHTML || currentLine.dataset.time !== floatingLyrics.dataset.time) {
            floatingLyrics.innerHTML = currentLine.innerHTML;
            floatingLyrics.dataset.time = currentLine.dataset.time;
            floatingLyrics.classList.add('enter-active');
            setTimeout(() => floatingLyrics.classList.remove('enter-active'), 500);
        }

        const floatingChars = floatingLyrics.querySelectorAll('.char');
        chars.forEach((char, index) => {
            const floatingChar = floatingChars[index];
            if (!floatingChar) return;

            const start = parseFloat(char.dataset.start);
            const end = parseFloat(char.dataset.end);
            
            if (currentTime >= start && currentTime <= end) {
                floatingChar.classList.add('active');
                const progress = (currentTime - start) / (end - start);
                floatingChar.style.transform = `scale(${1 + progress * 0.2})`;
            } else {
                floatingChar.classList.remove('active');
                floatingChar.style.transform = '';
            }
        });

        if (!isSmallScreen && !isHovering && !isManualScroll) {
            const lineRect = currentLine.getBoundingClientRect();
            const containerRect = lyricsContainer.getBoundingClientRect();
            const targetPosition = lineRect.top - containerRect.top + lyricsContainer.scrollTop - (lyricsContainer.clientHeight / 2) + (lineRect.height / 2);
            
            const buffer = 50;
            if (lineRect.top < containerRect.top + buffer || 
                lineRect.bottom > containerRect.bottom - buffer) {
                lyricsContainer.scrollTo({ top: targetPosition, behavior: 'smooth' });
            }
        }

        if (!hasActiveLine && lyricsContainer.scrollTop !== 0) {
            lyricsContainer.scrollTo({ top: 0, behavior: 'smooth' });
        }
    }
}

function spawnHeartAbove(char) {
    const heart = document.createElement('span');
    heart.className = 'heart';
    heart.textContent = '💖';

    const rect = char.getBoundingClientRect();
    const offsetTop = rect.top + window.scrollY;
    const offsetLeft = rect.left + window.scrollX;

    heart.style.left = `${offsetLeft + char.offsetWidth / 2}px`;
    heart.style.top = `${offsetTop - 30}px`; 

    document.body.appendChild(heart);

    requestAnimationFrame(() => {
        heart.classList.add('pop');
    });

    setTimeout(() => {
        heart.remove(); 
    }, 1000);
}

function loadTrack(url) {
    window.lyrics = {};
    window.lyricTimes = [];
    
    const lyricsContainers = [
        document.getElementById('lyricsContainer'),
        document.querySelector('#floatingLyrics .vertical-lyrics')
    ];
    
    lyricsContainers.forEach(container => {
        container.innerHTML = `<div class="no-lyrics">${translations['loading_lyrics'] || 'Loading Lyrics...'}</div>`;
    });

    audioPlayer.pause();
    audioPlayer.src = url;
    
    audioPlayer.load();
    audioPlayer.addEventListener('canplaythrough', () => {
        audioPlayer.play().catch((error) => {
            console.log(`${translations['autoplay_blocked'] || 'Autoplay Blocked'}:`, error);
            showLogMessage(translations['click_to_play'] || 'Click play button to start');
        });
        isPlaying = true;
        updatePlayButton();
    }, { once: true });

    updatePlayButton(); 
    updatePlaylistUI();
    loadLyrics(url);
    updateCurrentSong(url);
    updateTimeDisplay();
    
    savePlayerState();
}

function initializePlayer() {
    audioPlayer.src = songs[currentTrackIndex] || '';
    audioPlayer.currentTime = JSON.parse(localStorage.getItem('currentTime') || '0');
    
    audioPlayer.addEventListener('loadedmetadata', () => {
        loadLyrics(songs[currentTrackIndex]); 
        updateCurrentSong(songs[currentTrackIndex]);
    });

    updatePlayButton();
    setRepeatButtonState();
    updateTimeDisplay(true); 
    
    if (isPlaying) {
        audioPlayer.play().catch((error) => {
            console.log(`${translations['autoplay_blocked'] || 'Autoplay Blocked'}:`, error);
            isPlaying = false;
            saveCoreState();
            updatePlayButton();
        });
    }
}

function saveCoreState() {
    localStorage.setItem('cachedPlaylist', JSON.stringify(songs));
    localStorage.setItem('currentTrackIndex', currentTrackIndex);
    localStorage.setItem('isPlaying', isPlaying);
    localStorage.setItem('repeatMode', repeatMode);
    localStorage.setItem('currentTime', audioPlayer.currentTime);
}

function updateCurrentSong(url) {
    const songName = decodeURIComponent(url.split('/').pop().replace(/\.\w+$/, ''));
    document.getElementById('currentSong').textContent = songName;
    
    const floatingTitle = document.querySelector('#floatingLyrics #floatingCurrentSong');
    if (floatingTitle) floatingTitle.textContent = songName;

    const modalTitle = document.querySelector('#musicModal #currentSong');
    if (modalTitle) modalTitle.textContent = songName;
}

function updateTimeDisplay() {
    const currentTimeElement = document.getElementById('currentTime');
    const durationElement = document.getElementById('duration');
    const progressBar = document.getElementById('progressBar');

    audioPlayer.addEventListener('timeupdate', () => {
        const currentTime = audioPlayer.currentTime;
        const duration = audioPlayer.duration || 0;
        const progress = (currentTime / duration) * 100 || 0;

        currentTimeElement.textContent = formatTime(currentTime);
        durationElement.textContent = formatTime(duration);
        progressBar.style.width = `${progress}%`;
        progressBar.setAttribute('aria-valuenow', progress);
    });

    progressBar.parentElement.addEventListener('click', (e) => {
        const rect = progressBar.parentElement.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const clickedPercent = (x / rect.width) * 100;
        const newTime = (clickedPercent / 100) * audioPlayer.duration;
        audioPlayer.currentTime = newTime;
    });
}

function formatTime(seconds) {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = Math.floor(seconds % 60);
    return `${minutes}:${remainingSeconds < 10 ? '0' : ''}${remainingSeconds}`;
}

audioPlayer.addEventListener('ended', () => {
    if (repeatMode === 1) {
        audioPlayer.play();
    } else {
        changeTrack(1); 
    }
});

function savePlayerState() {
    localStorage.setItem('playerState', JSON.stringify({
        isPlaying: isPlaying,
        repeatMode: repeatMode,
        currentTrackIndex: currentTrackIndex,
        currentTime: audioPlayer.currentTime,
        currentTrack: songs[currentTrackIndex]
    }));
}

function loadPlayerState() {
    const savedState = localStorage.getItem('playerState');
    if (savedState) {
        const state = JSON.parse(savedState);
        isPlaying = state.isPlaying; 
        repeatMode = state.repeatMode;
        currentTrackIndex = state.currentTrackIndex || 0;
        
        if (state.currentTrack) {
            audioPlayer.currentTime = state.currentTime;
            setRepeatButtonState();
        }
    }
}

function setRepeatButtonState() {
    const mainBtn = document.getElementById('repeatBtn');
    const floatingBtn = document.getElementById('floatingRepeatBtn');
    
    [mainBtn, floatingBtn].forEach(btn => {
        btn.classList.remove('btn-success', 'btn-warning');
        btn.title = [
            translations['order_play'] || 'Order_Play',
            translations['single_loop'] || 'Single_Loop',
            translations['shuffle_play'] || 'Shuffle_Play'
        ][repeatMode];
        
        switch(repeatMode) {
            case 1:
                btn.classList.add('btn-success'); 
                btn.innerHTML = '<i class="bi bi-repeat-1"></i>';
                break;
            case 2:
                btn.classList.add('btn-warning'); 
                btn.innerHTML = '<i class="bi bi-shuffle"></i>';
                break;
            default:
                btn.innerHTML = '<i class="bi bi-arrow-repeat"></i>';
        }
    });
}

function loadDefaultPlaylist() {
    fetch('<?php echo $new_url; ?>')
        .then(response => response.text())
        .then(data => {
            const newSongs = data.split('\n').filter(url => url.trim());
            
            if (JSON.stringify(songs) !== JSON.stringify(newSongs)) {
                songs = [...new Set([...songs, ...newSongs])];
                currentTrackIndex = songs.findIndex(url => url === localStorage.getItem('currentTrack'));
                if (currentTrackIndex === -1) currentTrackIndex = 0;
                localStorage.setItem('cachedPlaylist', JSON.stringify(songs));
            }
            
            updatePlaylistUI();
            initializePlayer();
            
            if (songs[currentTrackIndex]) {
                loadLyrics(songs[currentTrackIndex]);
                updateCurrentSong(songs[currentTrackIndex]);
            }
        })
        .catch(error => console.error('Playlist loading failed:', error));
}

function updatePlaylistUI() {
    const playlist = document.getElementById('playlist');
    playlist.innerHTML = songs.map((url, index) => `
        <div class="playlist-item 
            ${index === currentTrackIndex ? 'active' : ''}
            ${!isPlaying && index === currentTrackIndex ? 'paused' : ''}" 
            onclick="playTrack(${index})">
            ${decodeURIComponent(url.split('/').pop().replace(/\.\w+$/, ''))}
        </div>
    `).join('');
    setTimeout(() => {
        const activeItem = playlist.querySelector('.active');
        if (activeItem) {
            const itemTop = activeItem.offsetTop;
            const itemHeight = activeItem.offsetHeight;
            const containerHeight = playlist.offsetHeight;

            if (itemTop < playlist.scrollTop || 
                itemTop + itemHeight > playlist.scrollTop + containerHeight) {
                activeItem.scrollIntoView({
                    behavior: 'smooth',
                    block: 'center',
                    inline: 'nearest'
                });
            }

            activeItem.style.animation = 'none';
        }
    }, 300);
}

loadDefaultPlaylist();
window.addEventListener('resize', () => {
    isSmallScreen = window.innerWidth < 768;
});
</script>

<script>
  const muteToggle    = document.getElementById('muteToggle');
  const volumeToggle  = document.getElementById('volumeToggle');
  const volumePanel   = document.getElementById('volumePanel');
  const volumeSlider  = document.getElementById('volumeSlider');
  const muteIconEl    = muteToggle.querySelector('i');
  const volumeIconEl  = volumeToggle.querySelector('i');

  let lastVolume = 1;

  const savedVolume = localStorage.getItem('audioVolume');
  const savedMuted  = localStorage.getItem('audioMuted');
  if (savedVolume !== null) {
    lastVolume = parseFloat(savedVolume);
  }
  audioPlayer.volume = lastVolume;
  volumeSlider.value = lastVolume;
  audioPlayer.muted = (savedMuted === 'true');

  updateVolumeIcon();

  function togglePanel() {
    const isVisible = volumePanel.classList.contains('show');
    if (isVisible) {
      volumePanel.classList.remove('show');
      setTimeout(() => (volumePanel.style.display = 'none'), 200);
    } else {
      volumePanel.style.display = 'block';
      setTimeout(() => volumePanel.classList.add('show'), 10);
    }
  }

  function toggleMute() {
    audioPlayer.muted = !audioPlayer.muted;
    if (!audioPlayer.muted && audioPlayer.volume === 0) {
      audioPlayer.volume = lastVolume;
      volumeSlider.value = lastVolume;
    }
    localStorage.setItem('audioMuted', audioPlayer.muted);
    updateVolumeIcon();

    const muteMessage = audioPlayer.muted
      ? (translations['mute_on']  || 'Audio muted')
      : (translations['mute_off'] || 'Audio unmuted');
    showLogMessage(muteMessage);
    speakMessage(muteMessage);
  }

  function updateVolumeIcon() {
    let cls;
    if (audioPlayer.muted || audioPlayer.volume === 0) {
      cls = 'bi bi-volume-mute-fill';
    } else if (audioPlayer.volume < 0.5) {
      cls = 'bi bi-volume-down-fill';
    } else {
      cls = 'bi bi-volume-up-fill';
    }
    muteIconEl.className = cls;
    volumeIconEl.className = cls;

    if (!audioPlayer.muted) {
      lastVolume = audioPlayer.volume;
      localStorage.setItem('audioVolume', lastVolume);
    }
  }

  muteToggle.addEventListener('click', e => {
    e.stopPropagation();
    toggleMute();
  });

  volumeToggle.addEventListener('click', e => {
    e.stopPropagation();
    if (e.target === volumeIconEl) {
      toggleMute();
    } else {
      togglePanel();
    }
  });

  document.addEventListener('click', () => {
    if (volumePanel.classList.contains('show')) {
      volumePanel.classList.remove('show');
      setTimeout(() => (volumePanel.style.display = 'none'), 200);
    }
  });

  volumeSlider.addEventListener('input', e => {
    const vol = Math.round(parseFloat(e.target.value) * 100);
    audioPlayer.volume = e.target.value;
    if (audioPlayer.muted) {
      audioPlayer.muted = false;
      localStorage.setItem('audioMuted', 'false');
    }
    updateVolumeIcon();

    const volumeMessage = translations['volume_change']
      ? translations['volume_change'].replace('{vol}', vol)
      : `Volume adjusted to ${vol}%`;
    showLogMessage(volumeMessage);
    speakMessage(volumeMessage);
  });

  const speedToggle = document.getElementById('speedToggle');
  const speedLabel = document.getElementById('speedLabel');
  const speeds = [0.75, 1, 1.25, 1.5, 1.75, 2];
  let speedIndex = 1;

  const savedSpeed = localStorage.getItem('audioSpeed');
  if (savedSpeed !== null) {
    const idx = speeds.indexOf(parseFloat(savedSpeed));
    if (idx !== -1) {
      speedIndex = idx;
    }
  }

  audioPlayer.playbackRate = speeds[speedIndex];
  speedLabel.textContent = speeds[speedIndex] + '×';

  function toggleSpeed() {
    speedIndex = (speedIndex + 1) % speeds.length;
    const rate = speeds[speedIndex];
    audioPlayer.playbackRate = rate;
    speedLabel.textContent = rate + '×';
    localStorage.setItem('audioSpeed', rate);

    const speedMessage = translations['speed_change']
      ? translations['speed_change'].replace('{rate}', rate)
      : `Playback speed changed to ${rate}x`;
    showLogMessage(speedMessage);
    speakMessage(speedMessage);
  }

  speedToggle.addEventListener('click', e => {
    e.stopPropagation();
    toggleSpeed();
  });

  speedToggle.addEventListener('click', e => e.stopPropagation());
</script>

<script>
(function() {
  const toggleBtns = document.querySelectorAll('.toggleFloatingLyricsBtn');
  const box = document.getElementById('floatingLyrics');

  const savedState = localStorage.getItem('floatingLyricsVisible') === 'true';
  const savedLeft = localStorage.getItem('floatingLyricsLeft');
  const savedTop = localStorage.getItem('floatingLyricsTop');

  box.classList.toggle('visible', savedState);
  box.style.resize = 'none';
  box.style.overflow = 'auto';
  box.style.position = 'absolute';

  if (savedLeft && savedTop) {
    box.style.left = savedLeft;
    box.style.top = savedTop;
  } else {
    box.style.left = '20px';
    box.style.top = '20px';
  }

  toggleBtns.forEach(btn => {
    btn.addEventListener('click', e => {
      e.stopPropagation();
      const isNowVisible = box.classList.toggle('visible');
      localStorage.setItem('floatingLyricsVisible', isNowVisible);

      const msgKey = isNowVisible
        ? 'floating_lyrics_enabled'
        : 'floating_lyrics_disabled';
      const message = translations[msgKey] ||
        (isNowVisible
          ? "Floating lyrics enabled"
          : "Floating lyrics disabled");
      showLogMessage(message);
      speakMessage(message);
    });
  });

  let isDragging = false, offsetX = 0, offsetY = 0;

  box.addEventListener('mousedown', e => {
    if (e.target.closest('.ctrl-btn')) return;
    e.preventDefault();
    isDragging = true;
    offsetX = e.clientX - box.offsetLeft;
    offsetY = e.clientY - box.offsetTop;
  });

  document.addEventListener('mousemove', e => {
    if (!isDragging) return;
    updatePosition(e.clientX, e.clientY);
  });

  document.addEventListener('mouseup', () => {
    if (isDragging) {
      isDragging = false;
      savePosition();
    }
  });

  let touchId = null;

  box.addEventListener('touchstart', e => {
    if (e.target.closest('.ctrl-btn')) return;
    e.preventDefault();
    const touch = e.touches[0];
    touchId = touch.identifier;
    offsetX = touch.clientX - box.offsetLeft;
    offsetY = touch.clientY - box.offsetTop;
  }, { passive: false });

  document.addEventListener('touchmove', e => {
    if (!touchId) return;
    const touch = Array.from(e.touches).find(t => t.identifier === touchId);
    if (!touch) return;
    updatePosition(touch.clientX, touch.clientY);
  }, { passive: false });

  document.addEventListener('touchend', () => {
    if (touchId) {
      touchId = null;
      savePosition();
    }
  });

  function updatePosition(clientX, clientY) {
    const newLeft = (clientX - offsetX) + 'px';
    const newTop = (clientY - offsetY) + 'px';
    box.style.left = newLeft;
    box.style.top = newTop;
  }

  function savePosition() {
    localStorage.setItem('floatingLyricsLeft', box.style.left);
    localStorage.setItem('floatingLyricsTop', box.style.top);
  }
})();
</script>

<script>
document.addEventListener('keydown', function (event) {
    const target = event.target;
    const isTyping = target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable;

    if (isTyping) return;

    switch (event.code) {
        case 'ArrowUp':
            event.preventDefault();
            document.querySelector('.toggleFloatingLyricsBtn')?.click();
            break;
        case 'Delete':
          if (currentTrackIndex !== 0) {
            currentTrackIndex = 0;
            loadTrack(songs[0]);
          }
            const message = translations['back_to_first'] || 'Returned to the first song in the playlist';
            showLogMessage(message);
            speakMessage(message);
            break;
        case 'Insert':
            document.getElementById('repeatBtn')?.click();
            break;
        case 'Home':
            event.preventDefault();
            document.querySelector('.panel-btn[data-bs-target="#musicModal"]')?.click();
            break;
        case 'Escape':
            event.preventDefault();
            const confirmText = document.getElementById('clearConfirmText')?.textContent.trim() || 'Are you sure you want to clear the config?';
            showConfirmation(confirmText, () => {
                document.getElementById('clear-cache-btn')?.click();
            });
            speakMessage(translations['clear_confirm'] || 'Are you sure you want to clear the configuration?');
            break;
    }
});

document.getElementById('goFirstBtn')?.addEventListener('click', function() {
    if (currentTrackIndex !== 0) {
        currentTrackIndex = 0;
        loadTrack(songs[0]);
    }
    const message = translations['back_to_first'] || 'Returned to the first song in the playlist';
    showLogMessage(message);
    speakMessage(message);
});
</script>

<script>
const websites = [
    'https://www.baidu.com/', 
    'https://www.cloudflare.com/', 
    'https://openai.com/',
    'https://www.youtube.com/',
    'https://www.google.com/',
    'https://www.facebook.com/',
    'https://www.twitter.com/',
    'https://www.github.com/'
];

function getWebsiteStatusMessage(url, status) {
    const statusMessages = translations['statusMessages'][url] || {};
    
    const message = status 
        ? statusMessages['accessible'] || `${url} 网站访问正常。`
        : statusMessages['notAccessible'] || `无法访问 ${url} 网站，请检查网络连接。`;

    return message;
}

function checkWebsiteAccess(urls) {
    const statusMessages = [];
    let requestsCompleted = 0;

    urls.forEach(url => {
        fetch(url, { mode: 'no-cors' })
            .then(response => {
                const isAccessible = response.type === 'opaque';  
                statusMessages.push(getWebsiteStatusMessage(url, isAccessible));
            })
            .catch(() => {
                statusMessages.push(getWebsiteStatusMessage(url, false));
            })
            .finally(() => {
                requestsCompleted++;
                if (requestsCompleted === urls.length) {
                    speakMessage(statusMessages.join(' '));  
                    speakMessage(translations['websiteChecked']); 
                }
            });
    });
}

let autoCheckInterval;
let isAutoCheckEnabled = localStorage.getItem('autoCheckEnabled') === 'true';
let userInteracted = localStorage.getItem('userInteracted') === 'true';

function updateToggleIcon() {
    const icon = document.getElementById('autoCheckIcon');
    if (isAutoCheckEnabled) {
        icon.classList.replace('bi-toggle-off', 'bi-toggle-on');
    } else {
        icon.classList.replace('bi-toggle-on', 'bi-toggle-off');
    }
}

function startAutoCheck(shouldAnnounce = false) {
    if (autoCheckInterval) clearInterval(autoCheckInterval);
    autoCheckInterval = setInterval(() => {
        if (userInteracted) {
            speakMessage(translations['startCheck']);
            showLogMessage(translations['startCheck']);
        }
        checkWebsiteAccess(websites);
    }, 3600000);
    
    isAutoCheckEnabled = true;
    localStorage.setItem('autoCheckEnabled', 'true');
    updateToggleIcon();
    
    if (shouldAnnounce && userInteracted) {
        const msg = translations['autoCheckEnabled'] || "Auto check enabled";
        speakMessage(msg);
        showLogMessage(msg);
    }
}

function stopAutoCheck(shouldAnnounce = false) {
    if (autoCheckInterval) {
        clearInterval(autoCheckInterval);
        autoCheckInterval = null;
    }
    
    isAutoCheckEnabled = false;
    localStorage.setItem('autoCheckEnabled', 'false');
    updateToggleIcon();
    
    if (shouldAnnounce && userInteracted) {
        const msg = translations['autoCheckDisabled'] || "Auto check disabled";
        speakMessage(msg);
        showLogMessage(msg);
    }
}

document.addEventListener('click', function() {
    if (!userInteracted) {
        userInteracted = true;
        localStorage.setItem('userInteracted', 'true');
    }
});

document.getElementById('autoCheckIcon').addEventListener('click', function(event) {
    event.stopPropagation();
    if (isAutoCheckEnabled) {
        stopAutoCheck(true);
    } else {
        startAutoCheck(true);
    }
});

updateToggleIcon();
if (isAutoCheckEnabled) {
    startAutoCheck(false);
}

let isDetectionStarted = false;

document.addEventListener('keydown', function(event) {
    if (event.key === 'F8' && !isDetectionStarted) {  
        event.preventDefault();  
        speakMessage(translations['checkStarted']);
        checkWebsiteAccess(websites);
        isDetectionStarted = true;
    }
});

document.getElementById('startCheckBtn').addEventListener('click', function() {
    speakMessage(translations['checkStarted']);
    checkWebsiteAccess(websites);
});

function speakTimeNow() {
    const now = new Date();
    let hour = now.getHours();
    const minute = now.getMinutes();
    const second = now.getSeconds();

    if (minute !== 0 || second !== 0) return;

    let lang = currentLang.split('-')[0];
    let message = '';

    if (lang === 'zh' || lang === 'zh-tw' || lang === 'hk') {
        let period = '';
        if (hour >= 0 && hour < 6) period = translations['periods']?.['earlyMorning'] || '凌晨';
        else if (hour >= 6 && hour < 12) period = translations['periods']?.['morning'] || '早上';
        else if (hour >= 12 && hour < 18) period = translations['periods']?.['afternoon'] || '下午';
        else period = translations['periods']?.['evening'] || '晚上';

        const template = translations['timeReport'] || "整点报时，现在是北京时间{period}{hour}点整";
        message = template.replace("{period}", period).replace("{hour}", hour);
    } else {
        let period = 'AM';
        if (hour >= 12) period = 'PM';
        let displayHour = hour % 12;
        displayHour = displayHour === 0 ? 12 : displayHour;

        const template = translations['timeReport']?.[lang] || translations['timeReport']?.['en'] || "It is now {hour} {period}.";
        message = template.replace("{hour}", displayHour).replace("{period}", period);
    }

    speakMessage(message);
}

setInterval(speakTimeNow, 1000);
</script>
<style>
.animated-box {
	width: 50px;
	height: 50px;
	margin: 10px;
	background: linear-gradient(45deg, #ff6b6b, #ffd93d);
	border-radius: 10px;
	position: absolute;
	animation: complex-animation 5s infinite alternate ease-in-out;
	box-shadow: 0 10px 20px rgba(0, 0, 0, 0.3);
}

@keyframes complex-animation {
	0% {
		transform: rotate(0deg) scale(1);
		background: linear-gradient(45deg, #ff6b6b, #ffd93d);
	}

	25% {
		transform: rotate(45deg) scale(1.2);
		background: linear-gradient(135deg, #42a5f5, #66bb6a);
	}

	50% {
		transform: rotate(90deg) scale(0.8);
		background: linear-gradient(225deg, #ab47bc, #ff7043);
	}

	75% {
		transform: rotate(135deg) scale(1.5);
		background: linear-gradient(315deg, #29b6f6, #8e24aa);
	}

	100% {
		transform: rotate(180deg) scale(1);
		background: linear-gradient(45deg, #ff6b6b, #ffd93d);
	}
}
</style>

<script>
(function() {
    let isAnimationActive = localStorage.getItem('animationActive') === 'true';
    let intervalId;

    function createAnimatedBox() {
        const box = document.createElement('div');
        box.className = 'animated-box';
        document.body.appendChild(box);
        const randomX = Math.random() * window.innerWidth;
        const randomY = Math.random() * window.innerHeight;
        box.style.left = randomX + 'px';
        box.style.top = randomY + 'px';
        const randomDuration = Math.random() * 3 + 3;
        box.style.animationDuration = randomDuration + 's';
        setTimeout(() => {
            box.remove();
        }, randomDuration * 1000);
    }

    function startAnimation() {
        intervalId = setInterval(() => {
            createAnimatedBox();
        }, 1000);
        localStorage.setItem('animationActive', 'true');
        isAnimationActive = true;
        updateButtonText();
    }

    function stopAnimation() {
        clearInterval(intervalId);
        localStorage.setItem('animationActive', 'false');
        isAnimationActive = false;
        updateButtonText();
    }

    function updateButtonText() {
        document.getElementById('toggleAnimationBtn').innerText = isAnimationActive 
            ? translations['toggleButton']['stop']
            : translations['toggleButton']['start'];
    }

    window.addEventListener('keydown', function(event) {
        if (event.ctrlKey && event.key === 'F10') {
            isAnimationActive = !isAnimationActive;
            if (isAnimationActive) {
                startAnimation();
                showLogMessage(translations['startAnimation']);
                speakMessage(translations['startAnimation']);
            } else {
                stopAnimation();
                    showLogMessage(translations['stopAnimation']);
                    speakMessage(translations['stopAnimation']);
            }
        }
    });

    document.getElementById('toggleAnimationBtn').addEventListener('click', function() {
        if (isAnimationActive) {
            stopAnimation();
                showLogMessage(translations['stopAnimation']);
                speakMessage(translations['stopAnimation']);
        } else {
            startAnimation();
                showLogMessage(translations['startAnimation']);
                speakMessage(translations['startAnimation']);
        }
    });

    if (isAnimationActive) {
        startAnimation();
    }
    updateButtonText();
    })();
</script>

<style>
.snowflake {
	position: absolute;
	top: -10px;
	width: 10px;
	height: 10px;
	background-color: white;
	border-radius: 50%;
	animation: fall linear infinite;
}

@keyframes fall {
	0% {
		transform: translateY(0) rotate(0deg);
	}

	100% {
		transform: translateY(100vh) rotate(360deg);
	}
}

.snowflake:nth-child(1) {
	animation-duration: 8s;
	animation-delay: -2s;
	left: 10%;
	width: 12px;
	height: 12px;
}

.snowflake:nth-child(2) {
	animation-duration: 10s;
	animation-delay: -3s;
	left: 20%;
	width: 8px;
	height: 8px;
}

.snowflake:nth-child(3) {
	animation-duration: 12s;
	animation-delay: -1s;
	left: 30%;
	width: 15px;
	height: 15px;
}

.snowflake:nth-child(4) {
	animation-duration: 9s;
	animation-delay: -5s;
	left: 40%;
	width: 10px;
	height: 10px;
}

.snowflake:nth-child(5) {
	animation-duration: 11s;
	animation-delay: -4s;
	left: 50%;
	width: 14px;
	height: 14px;
}

.snowflake:nth-child(6) {
	animation-duration: 7s;
	animation-delay: -6s;
	left: 60%;
	width: 9px;
	height: 9px;
}

.snowflake:nth-child(7) {
	animation-duration: 8s;
	animation-delay: -7s;
	left: 70%;
	width: 11px;
	height: 11px;
}

.snowflake:nth-child(8) {
	animation-duration: 10s;
	animation-delay: -8s;
	left: 80%;
	width: 13px;
	height: 13px;
}

.snowflake:nth-child(9) {
	animation-duration: 6s;
	animation-delay: -9s;
	left: 90%;
	width: 10px;
	height: 10px;
}
</style>

<script>
    function createSnowflakes() {
        for (let i = 0; i < 80; i++) {
            let snowflake = document.createElement('div');
            snowflake.classList.add('snowflake');
                
            let size = Math.random() * 10 + 5 + 'px';  
            snowflake.style.width = size;
            snowflake.style.height = size;
                
            let speed = Math.random() * 3 + 2 + 's'; 
            snowflake.style.animationDuration = speed;

            let rotate = Math.random() * 360 + 'deg'; 
            let rotateSpeed = Math.random() * 5 + 2 + 's'; 
            snowflake.style.animationName = 'fall';
            snowflake.style.animationDuration = speed;
            snowflake.style.animationTimingFunction = 'linear';
            snowflake.style.animationIterationCount = 'infinite';

            let leftPosition = Math.random() * 100 + 'vw';  
            snowflake.style.left = leftPosition;

            snowflake.style.animationDelay = Math.random() * 5 + 's';  

            document.body.appendChild(snowflake);
        }
    }

    function stopSnowflakes() {
        let snowflakes = document.querySelectorAll('.snowflake');
        snowflakes.forEach(snowflake => snowflake.remove());
    }

    function getSnowingState() {
        return localStorage.getItem('isSnowing') === 'true';
    }

    function saveSnowingState(state) {
        localStorage.setItem('isSnowing', state);
    }

    let isSnowing = getSnowingState();

    if (isSnowing) {
        createSnowflakes();  
    }

    function toggleSnowflakes() {
        isSnowing = !isSnowing;
        saveSnowingState(isSnowing);
        if (isSnowing) {
            createSnowflakes();
            showLogMessage(translations['startSnowflakes']);
            speakMessage(translations['startSnowflakes']);
            document.getElementById('toggleSnowBtn').innerText = translations['toggleSnowButton']['stop'];
        } else {
            stopSnowflakes();
            showLogMessage(translations['stopSnowflakes']);
            speakMessage(translations['stopSnowflakes']);
            document.getElementById('toggleSnowBtn').innerText = translations['toggleSnowButton']['start'];
        }
    }

    window.addEventListener('keydown', function(event) {
        if (event.ctrlKey && event.key === 'F6') {
            toggleSnowflakes();
        }
    });

    document.getElementById('toggleSnowBtn').addEventListener('click', toggleSnowflakes);

    if (isSnowing) {
        document.getElementById('toggleSnowBtn').innerText = translations['toggleSnowButton']['stop'];
    }

</script>

<style>
@keyframes lightPulse {
	0% {
		transform: scale(0.5);
		opacity: 1;
	}

	50% {
		transform: scale(1.5);
		opacity: 0.7;
	}

	100% {
		transform: scale(3);
		opacity: 0;
	}
}

.light-point {
	position: fixed;
	width: 10px;
	height: 10px;
	background: radial-gradient(circle, rgba(255, 255, 255, 1), rgba(255, 255, 255, 0.2));
	border-radius: 50%;
	pointer-events: none;
	z-index: 9999;
	animation: lightPulse 3s linear infinite;
}
</style>

<script>
(function () {
    let isLightEffectActive = localStorage.getItem('lightEffectAnimation') === 'true';
    let lightInterval;

    function createLightPoint() {
        const lightPoint = document.createElement('div');
        lightPoint.className = 'light-point';

        const posX = Math.random() * window.innerWidth;
        const posY = Math.random() * window.innerHeight;

        lightPoint.style.left = `${posX}px`;
        lightPoint.style.top = `${posY}px`;

        const colors = ['#ffcc00', '#00ccff', '#ff6699', '#99ff66', '#cc99ff'];
        const randomColor = colors[Math.floor(Math.random() * colors.length)];
        lightPoint.style.background = `radial-gradient(circle, ${randomColor}, rgba(255, 255, 255, 0.1))`;

        document.body.appendChild(lightPoint);
        setTimeout(() => {
            lightPoint.remove();
        }, 3000); 
    }

    function startLightEffect(showLog = true) {
        if (lightInterval) clearInterval(lightInterval);
        lightInterval = setInterval(createLightPoint, 200); 
        localStorage.setItem('lightEffectAnimation', 'true');
        if (showLog) {
            showLogMessage(translations['startLightEffect']);
            speakMessage(translations['startLightEffect']);
        }
        updateButtonText();
    }

    function stopLightEffect(showLog = true) {
        clearInterval(lightInterval);
        document.querySelectorAll('.light-point').forEach((light) => light.remove());
        localStorage.setItem('lightEffectAnimation', 'false');
        if (showLog) {
            showLogMessage(translations['stopLightEffect']);
            speakMessage(translations['stopLightEffect']);
        }
        updateButtonText();
    }

    function showNotification(message) {
        const notification = document.createElement('div');
        notification.style.position = 'fixed';
        notification.style.top = '10px';
        notification.style.right = '10px';
        notification.style.padding = '10px';
        notification.style.backgroundColor = '#4CAF50';
        notification.style.color = '#fff';
        notification.style.borderRadius = '5px';
        notification.style.zIndex = 9999;
        notification.textContent = message;

        document.body.appendChild(notification);
        setTimeout(() => {
            notification.remove();
        }, 3000);
    }

    function toggleLightEffect() {
        isLightEffectActive = !isLightEffectActive;
        if (isLightEffectActive) {
            startLightEffect();
        } else {
            stopLightEffect();
        }
    }

    window.addEventListener('keydown', function (event) {
        if (event.ctrlKey && event.key === 'F11') {
            toggleLightEffect();
                }
            });

            document.getElementById('toggleLightEffectBtn').addEventListener('click', toggleLightEffect);

            if (isLightEffectActive) {
                document.getElementById('toggleLightEffectBtn').innerText = translations['toggleLightEffectButton']['stop'];
            } else {
                document.getElementById('toggleLightEffectBtn').innerText = translations['toggleLightEffectButton']['start'];
            }
        })();
</script>

<script>
    document.addEventListener("DOMContentLoaded", function() {
        feather.replace();
    });
</script>

<style>

@media (max-width: 767.98px) {
	#musicModal .modal-dialog {
		margin: 0.5rem;
		max-width: calc(100% - 1rem);
		max-height: 90vh;
	}

	#musicModal .modal-content {
		max-height: 90vh;
		display: flex;
		flex-direction: column;
	}

	#musicModal .modal-body {
		overflow-y: auto;
		max-height: calc(90vh - 120px);
		padding: 15px;
	}

	#musicModal #floatingLyrics {
		font-size: 1.1rem;
		padding: 8px 12px;
		margin-bottom: 10px;
	}

	#musicModal #currentSong {
		font-size: 1.1rem;
		margin-bottom: 8px;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	#musicModal .lyrics-container {
		height: 200px;
		font-size: 0.95rem;
		line-height: 1.6;
		padding: 10px;
		overflow-y: auto;
	}

	#musicModal .progress-container {
		margin-top: 12px;
	}

	#musicModal .d-flex.justify-content-between {
		font-size: 0.85rem;
	}

	#musicModal .controls {
		display: flex;
		flex-wrap: nowrap;
		justify-content: space-between;
		gap: 4px;
		margin-top: 15px;
		overflow-x: auto;
		padding-bottom: 5px;
	}

	#musicModal .control-btn,
        #musicModal .btn-volume {
		width: 35px;
		height: 35px;
		min-width: 35px;
		padding: 0;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 1rem;
	}

	#musicModal #playPauseBtn {
		width: 35px;
		height: 35px;
		min-width: 35px;
		font-size: 1rem;
	}

	#musicModal .btn-volume {
		position: relative;
	}

	#musicModal #volumePanel {
		position: absolute;
		bottom: 100%;
		left: 50%;
		transform: translateX(-50%);
		width: 100px;
		z-index: 10;
		background: rgba(0, 0, 0, 0.8);
		border-radius: 5px;
		display: none;
		padding: 8px;
	}

	#musicModal .btn-volume:hover #volumePanel,
        #musicModal .btn-volume:focus-within #volumePanel {
		display: block;
	}

	#musicModal .playlist {
		margin-top: 15px;
		max-height: 150px;
		overflow-y: auto;
	}

	#musicModal .playlist-item {
		padding: 6px 10px;
		font-size: 0.9rem;
	}

	#musicModal .modal-footer {
		padding: 10px 15px;
	}

	#musicModal .modal-footer .btn {
		padding: 5px 10px;
		font-size: 0.85rem;
	}

	#musicModal .modal-body::-webkit-scrollbar,
        #musicModal .lyrics-container::-webkit-scrollbar,
        #musicModal .playlist::-webkit-scrollbar {
		width: 6px;
	}

	#musicModal .modal-body::-webkit-scrollbar-track,
        #musicModal .lyrics-container::-webkit-scrollbar-track,
        #musicModal .playlist::-webkit-scrollbar-track {
		background: rgba(0, 0, 0, 0.1);
	}

	#musicModal .modal-body::-webkit-scrollbar-thumb,
        #musicModal .lyrics-container::-webkit-scrollbar-thumb,
        #musicModal .playlist::-webkit-scrollbar-thumb {
		background: #4ecca3;
		border-radius: 3px;
	}
}
</style>

<script>
document.addEventListener('DOMContentLoaded', () => {
    function initializeStyles() {
        const containerWidth = localStorage.getItem('containerWidth') || 1600;
        const modalMaxWidth = localStorage.getItem('modalMaxWidth') || 1100;
        document.documentElement.style.setProperty('--container-width', `${containerWidth}px`);
        document.documentElement.style.setProperty('--modal-max-width', `${modalMaxWidth}px`);
    }

    initializeStyles();

    const slider = document.getElementById("containerWidth");
    const widthValue = document.getElementById("widthValue");
    const modalSlider = document.getElementById("modalMaxWidth");
    const modalWidthValue = document.getElementById("modalWidthValue");

    slider.value = localStorage.getItem('containerWidth') || 1600;
    modalSlider.value = localStorage.getItem('modalMaxWidth') || 1100;

    function updateSliderColor(value, slider, valueElement) {
        let red = Math.min(Math.max((value - 800) / (5400 - 800) * 255, 0), 255);
        let green = 255 - red;
        slider.style.background = `linear-gradient(to right, rgb(${red}, ${green}, 255), rgb(${255 - red}, ${green}, ${255 - red}))`;
        slider.style.setProperty('--thumb-color', `rgb(${red}, ${green}, 255)`);
        const currentWidthText = translations && translations['current_width'] 
            ? translations['current_width'] 
            : 'Current Width';
        valueElement.textContent = `${currentWidthText}: ${value}px`;
        valueElement.style.color = `rgb(${red}, ${green}, 255)`;
    }

    updateSliderColor(slider.value, slider, widthValue);
    updateSliderColor(modalSlider.value, modalSlider, modalWidthValue);

    slider.oninput = function () {
        updateSliderColor(slider.value, slider, widthValue);
        localStorage.setItem('containerWidth', slider.value);
        document.documentElement.style.setProperty('--container-width', `${slider.value}px`);
        const msg = translations['page_width_updated'].replace('%s', slider.value);
        showLogMessage(msg);
        if (typeof speakMessage === 'function') speakMessage(msg);
    };

    modalSlider.oninput = function () {
        updateSliderColor(modalSlider.value, modalSlider, modalWidthValue);
        localStorage.setItem('modalMaxWidth', modalSlider.value);
        document.documentElement.style.setProperty('--modal-max-width', `${modalSlider.value}px`);
        const msg = translations['modal_width_updated'].replace('%s', modalSlider.value);
        showLogMessage(msg);
        if (typeof speakMessage === 'function') speakMessage(msg);
    };

    const savedColor = localStorage.getItem('themeBackgroundColor') || '';
    const preview = document.getElementById('color-preview');
    const selector = document.getElementById('color-selector');
    const input = document.getElementById('color-input');
    const colorBlock = document.getElementById('current-color-block');

    preview.style.background = savedColor;
    selector.value = savedColor;
    input.value = savedColor;
    colorBlock.style.background = savedColor;
    applyCustomBackgroundColor(savedColor);

    selector.addEventListener('input', e => {
        const color = e.target.value;
        preview.style.background = color;
        input.value = color;
        colorBlock.style.background = color;
    });

    input.addEventListener('input', e => {
        const color = e.target.value;
        if (isValidColor(color)) {
            preview.style.background = color;
            selector.value = color;
            colorBlock.style.background = color;
        }
    });

    colorBlock.addEventListener('click', () => {
        const color = selector.value;
        preview.style.background = color;
        input.value = color;
        applyCustomBackgroundColor(color);
    });

    document.getElementById('apply-color').addEventListener('click', () => {
        const color = document.getElementById('color-input').value;
        if (isValidColor(color)) {
            applyCustomBackgroundColor(color);
            const successMsgTemplate = translations['apply_color_success'] || 'Background color %s has been applied successfully.';
            const successMsg = successMsgTemplate.replace('%s', color);
            if (typeof showLogMessage === 'function') showLogMessage(successMsg);
            if (typeof speakMessage === 'function') speakMessage(successMsg);
        } else {
            const invalidMsg = translations['invalid_color'] || 'The color entered is invalid.';
            if (typeof showLogMessage === 'function') showLogMessage(invalidMsg);
            if (typeof speakMessage === 'function') speakMessage(invalidMsg);
        }
    });

    document.getElementById('reset-color').addEventListener('click', () => {
        resetCustomBackgroundColor();
        const defaultColor = '';
        preview.style.background = defaultColor;
        selector.value = defaultColor;
        input.value = defaultColor;
        colorBlock.style.background = defaultColor;
        const successMsg = translations['reset_color_success'] || 'Background color has been reset to default.';
        if (typeof showLogMessage === 'function') showLogMessage(successMsg);
        if (typeof speakMessage === 'function') speakMessage(successMsg);
    });

    generateColorPresets();
    window.addEventListener('resize', generateColorPresets);

    document.querySelectorAll('input[type=range]').forEach(range => {
        updateRangeBackground(range);
        range.addEventListener('input', () => updateRangeBackground(range));
    });
});

function isValidColor(str) {
    const s = new Option().style;
    s.color = str;
    return s.color !== '';
}

function applyCustomBackgroundColor(color) {
    document.body.style.background = color;
    localStorage.setItem('themeBackgroundColor', color);
}

function resetCustomBackgroundColor() {
    document.body.style.background = '';
    localStorage.removeItem('themeBackgroundColor');
}

function generateColorPresets() {
    const presets = [
        '#0f3460', '#0f172a', '#1e293b', '#1e3a8a', '#1d4ed8', '#2563eb',
        '#3b82f6', '#1e40af', '#3730a3', '#4c1d95', '#5b21b6', '#6d28d9',
        '#7c3aed', '#0369a1', '#0284c7', '#0ea5e9', '#38bdf8', '#7dd3fc',
        '#bae6fd', '#1d4ed8', '#60a5fa', '#93c5fd', '#bfdbfe',
        '#064e3b', '#047857', '#059669', '#10b981', '#34d399', '#6ee7b7',
        '#a7f3d0', '#d1fae5', '#166534', '#22c55e',
        '#854d0e', '#a16207', '#ca8a04', '#eab308', '#facc15', '#fde047',
        '#fef08a', '#fef9c3', '#ea580c', '#f97316', '#fb923c', '#fdba74',
        '#7f1d1d', '#b91c1c', '#dc2626', '#ef4444', '#f87171', '#fca5a5',
        '#fecaca', '#fee2e2', '#9d174d', '#be185d', '#db2777', '#ec4899',
        '#581c87', '#6b21a8', '#7e22ce', '#9333ea', '#a855f7', '#c084fc',
        '#d8b4fe', '#e9d5ff', '#5b21b6', '#7c3aed',
        '#111827', '#1f2937', '#374151', '#4b5563', '#6b7280', '#9ca3af',
        '#d1d5db', '#e5e7eb', '#f3f4f6', '#f9fafb', '#ffffff',
        '#134e4a', '#0d9488', '#14b8a6', '#2dd4bf', '#5eead4', '#99f6e4',
        '#ccfbf1', '#ecfdf5', '#0891b2', '#06b6d4',
        '#4338ca', '#4f46e5', '#6366f1', '#8b5cf6', '#a855f7', '#d946ef',
        '#ec4899', '#f43f5e', '#ef4444', '#f97316', '#f59e0b', '#eab308'
    ];

    const container = document.getElementById('preset-colors');
    container.innerHTML = '';
    container.style.gridTemplateColumns = window.innerWidth < 768 ? 'repeat(10, 1fr)' : 'repeat(15, 1fr)';

    presets.forEach(color => {
        const div = document.createElement('div');
        div.className = 'color-preset rounded';
        div.style.background = color;
        div.style.height = '30px';
        div.style.cursor = 'pointer';
        div.title = color;
        div.style.border = '2px solid transparent';
        div.addEventListener('click', () => {
            document.getElementById('color-preview').style.background = color;
            document.getElementById('color-selector').value = color;
            document.getElementById('color-input').value = color;
            document.getElementById('current-color-block').style.background = color;
            applyCustomBackgroundColor(color);
            const msgTemplate = translations['apply_color_success'] || 'Background color %s has been applied successfully.';
            const msg = msgTemplate.replace('%s', color);
            if (typeof showLogMessage === 'function') showLogMessage(msg);
            if (typeof speakMessage === 'function') speakMessage(msg);
        });
        container.appendChild(div);
    });
}

function updateRangeBackground(range) {
    const val = range.value;
    const min = range.min ? range.min : 0;
    const max = range.max ? range.max : 100;
    const percent = (val - min) / (max - min) * 100;
    range.style.background = `linear-gradient(to right, #00ff00 0%, #00ff00 ${percent}%, #ffffff ${percent}%, #ffffff 100%)`;
}
</script>

<script>
document.addEventListener("DOMContentLoaded", () => {
  const colorModal = new bootstrap.Modal(document.getElementById('colorModal'));
  let currentHue = 260, currentChroma = 0.10, currentLightness = 30;
  let recentColors = [];

  function hexToRgb(hex) {
    const fullHex = hex.replace(/^#?([a-f\d])([a-f\d])([a-f\d])$/i, 
      (_, r, g, b) => `#${r}${r}${g}${g}${b}${b}`);
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(fullHex);
    return result ? {
      r: parseInt(result[1], 16),
      g: parseInt(result[2], 16),
      b: parseInt(result[3], 16)
    } : { r: 0, g: 0, b: 0 };
  }

  function rgbToLinear(c) {
    const normalized = c / 255;
    return normalized <= 0.04045 
      ? normalized / 12.92 
      : Math.pow((normalized + 0.055) / 1.055, 2.4);
  }

  function rgbToOklch(r, g, b) {
    const [lr, lg, lb] = [r, g, b].map(rgbToLinear);
    const l = 0.4122214708 * lr + 0.5363325363 * lg + 0.0514459929 * lb;
    const m = 0.2119034982 * lr + 0.6806995451 * lg + 0.1073969566 * lb;
    const s = 0.0883024619 * lr + 0.2817188376 * lg + 0.6299787005 * lb;
    const l_ = Math.cbrt(l);
    const m_ = Math.cbrt(m);
    const s_ = Math.cbrt(s);
    const L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_;
    const a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_;
    const b_ = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_;
    const c = Math.sqrt(a ** 2 + b_ ** 2);
    let h = Math.atan2(b_, a) * 180 / Math.PI;
    h = h >= 0 ? h : h + 360;
    return { l: L * 100, c: c, h: h };
  }

  function hexToOklch(hex) {
    const { r, g, b } = hexToRgb(hex);
    return rgbToOklch(r, g, b);
  }

  function oklchToHex(h, c, l = 50) {
    const L = l / 100;
    const a = c * Math.cos(h * Math.PI / 180);
    const b = c * Math.sin(h * Math.PI / 180);
    const l_ = L + 0.3963377774 * a + 0.2158037573 * b;
    const m_ = L - 0.1055613458 * a - 0.0638541728 * b;
    const s_ = L - 0.0894841775 * a - 1.2914855480 * b;
    const [lr, lg, lb] = [l_, m_, s_].map(v => v ** 3);
    const r = 4.0767416621 * lr - 3.3077115913 * lg + 0.2309699292 * lb;
    const g = -1.2684380046 * lr + 2.6097574011 * lg - 0.3413193965 * lb;
    const bLinear = -0.0041960863 * lr - 0.7034186147 * lg + 1.7076147010 * lb;
    const toSRGB = (v) => {
      v = Math.min(Math.max(v, 0), 1);
      return v > 0.0031308 
        ? 1.055 * (v ** (1/2.4)) - 0.055 
        : 12.92 * v;
    };
    const [R, G, B] = [r, g, bLinear].map(v => Math.round(toSRGB(v) * 255));
    return `#${[R, G, B].map(x => x.toString(16).padStart(2, '0')).join('')}`.toUpperCase();
  }

  function updateTextPrimary(currentL) {
    const textL = currentL > 60 ? 20 : 95;
    document.documentElement.style.setProperty('--text-primary', `oklch(${textL}% 0 0)`);
    document.body.offsetHeight;
  }

  function updateColorPreview() {
    const hexColor = oklchToHex(currentHue, currentChroma, currentLightness);
    document.getElementById('colorPreview').style.backgroundColor = hexColor;
    const contrastRatio = calculateContrast(hexColor);
    document.getElementById('contrastRatio').textContent = contrastRatio;
    updateContrastRating(parseFloat(contrastRatio.split(':')[0]));
    document.getElementById('oklchValue').textContent = `OKLCH(${currentLightness.toFixed(0)}%, ${currentChroma.toFixed(2)}, ${Math.round(currentHue)}°)`;
  }

  function calculateContrast(hexColor) {
    const rgb = hexToRgb(hexColor);
    const luminance = (0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b) / 255;
    const textLuminance = luminance > 0.5 ? 0 : 1;
    const contrast = (Math.max(luminance, textLuminance) + 0.05) / (Math.min(luminance, textLuminance) + 0.05);
    return contrast.toFixed(2) + ":1";
  }

  function updateContrastRating(contrast) {
    const container = document.getElementById('contrastRating');
    let icon = '';
    if (contrast >= 7) {
      icon = '<i class="bi bi-check-circle-fill"></i> ';
      container.className = "mt-1 text-success fw-bold";
      container.innerHTML = `${icon}${translations['excellent_aaa'] || 'Excellent (AAA)'}`;
    } else if (contrast >= 4.5) {
      icon = '<i class="bi bi-check-circle"></i> ';
      container.className = "mt-1 text-primary fw-bold";
      container.innerHTML = `${icon}${translations['good_aa'] || 'Good (AA)'}`;
    } else {
      icon = '<i class="bi bi-exclamation-triangle-fill"></i> ';
      container.className = "mt-1 text-danger fw-bold";
      container.innerHTML = `${icon}${translations['poor_needs_improvement'] || 'Needs Improvement'}`;
    }
  }

  function adjustHue(amount) {
    currentHue = (currentHue + amount + 360) % 360;
    document.getElementById('hueSlider').value = currentHue;
    document.getElementById('hueValue').textContent = Math.round(currentHue) + '°';
    updateColorPreview();
  }

  function addToRecentColors(color) {
    recentColors = recentColors.filter(c => c !== color);
    recentColors.unshift(color);
  
    if (recentColors.length > 10) {
      recentColors.pop();
    }
  
    updateRecentColors();
    localStorage.setItem('appColorSettings', JSON.stringify({
      recentColors,
      hue: currentHue,
      chroma: currentChroma,
      lightness: currentLightness
    }));
  }

  function updateRecentColors() {
    const container = document.getElementById('recentColors');
    container.innerHTML = '';
    recentColors.forEach(color => {
      const swatch = document.createElement('button');
      swatch.className = 'btn btn-sm p-2';
      swatch.style.backgroundColor = color;
      swatch.style.width = '30px';
      swatch.style.height = '30px';
      swatch.title = color;
      swatch.addEventListener('click', function() {
        const { h, c, l } = hexToOklch(color);
        document.getElementById('hueSlider').value = h;
        document.getElementById('chromaSlider').value = c;
        document.getElementById('lightnessSlider').value = l;
        document.getElementById('hueValue').textContent = Math.round(h) + '°';
        document.getElementById('chromaValue').textContent = c.toFixed(2);
        document.getElementById('lightnessValue').textContent = l + '%';
        currentHue = h;
        currentChroma = c;
        currentLightness = l;
        updateColorPreview();
        document.getElementById('colorPicker').value = color;
        document.documentElement.style.setProperty('--base-hue', currentHue);
        document.documentElement.style.setProperty('--base-chroma', currentChroma);
        updateTextPrimary(currentLightness);
        addToRecentColors(color);
      });
      container.appendChild(swatch);
    });
  }

  function initRecentColors() {
      const savedSettings = localStorage.getItem('appColorSettings');
      let initialTheme = 'dark';
      if (savedSettings) {
          const settings = JSON.parse(savedSettings);
          recentColors = settings.recentColors || [];
          if (recentColors.length > 10) {
              recentColors = recentColors.slice(0, 10);
          }
          currentHue = settings.hue || 260;
          currentChroma = settings.chroma || 0.10;
          currentLightness = settings.lightness || 30;
          initialTheme = currentLightness > 60 ? 'light' : 'dark';
      } else {
          recentColors = [
              '#4d79ff', '#ff4d94', '#4dff88', '#ffb84d', 
              '#bf4dff', '#ff6b6b', '#4eca9e', '#ff9ff3',
              '#6c757d', '#ffc107'
          ];
      }
      document.documentElement.setAttribute('data-theme', initialTheme);
      document.getElementById('lightnessSlider').value = currentLightness;
      document.getElementById('lightnessValue').textContent = currentLightness + '%';
      updateColorPreview();
      updateTextPrimary(currentLightness);
      updateRecentColors();
  }

  const picker = document.getElementById("colorPicker");
  picker.addEventListener('input', (event) => {
    const color = event.target.value;
    const { h, c, l } = hexToOklch(color);
    currentHue = h;
    currentChroma = c;
    currentLightness = l;
    
    document.getElementById('hueSlider').value = h;
    document.getElementById('chromaSlider').value = c;
    document.getElementById('lightnessSlider').value = l;
    document.getElementById('hueValue').textContent = Math.round(h) + '°';
    document.getElementById('chromaValue').textContent = c.toFixed(2);
    document.getElementById('lightnessValue').textContent = l + '%';
    
    const theme = l > 60 ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', theme);
    
    updateColorPreview();
    document.documentElement.style.setProperty('--base-hue', currentHue);
    document.documentElement.style.setProperty('--base-chroma', currentChroma);
    updateTextPrimary(currentLightness);
    addToRecentColors(color);
  });

  document.getElementById('advancedColorBtn').addEventListener('click', () => {
    document.getElementById('hueSlider').value = currentHue;
    document.getElementById('chromaSlider').value = currentChroma;
    document.getElementById('lightnessSlider').value = currentLightness;
    document.getElementById('hueValue').textContent = Math.round(currentHue) + '°';
    document.getElementById('chromaValue').textContent = currentChroma.toFixed(2);
    document.getElementById('lightnessValue').textContent = currentLightness + '%';
    updateColorPreview();
    colorModal.show();
  });

  document.getElementById('hueSlider').addEventListener('input', function() {
    currentHue = parseFloat(this.value);
    document.getElementById('hueValue').textContent = Math.round(currentHue) + '°';
    updateColorPreview();
    document.getElementById('colorPicker').value = oklchToHex(currentHue, currentChroma, currentLightness);
    document.documentElement.style.setProperty('--base-hue', currentHue);
    updateTextPrimary(currentLightness);
  });

  document.getElementById('chromaSlider').addEventListener('input', function() {
    currentChroma = parseFloat(this.value);
    document.getElementById('chromaValue').textContent = currentChroma.toFixed(2);
    updateColorPreview();
    document.getElementById('colorPicker').value = oklchToHex(currentHue, currentChroma, currentLightness);
    document.documentElement.style.setProperty('--base-chroma', currentChroma);
    updateTextPrimary(currentLightness);
  });

  document.getElementById('lightnessSlider').addEventListener('input', function() {
    currentLightness = parseFloat(this.value);
    document.getElementById('lightnessValue').textContent = currentLightness + '%';
    updateColorPreview();
    document.getElementById('colorPicker').value = oklchToHex(currentHue, currentChroma, currentLightness);
    updateTextPrimary(currentLightness);

    const theme = currentLightness > 60 ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', theme);
  });

  document.querySelectorAll('[data-h]').forEach(button => {
    button.addEventListener('click', function() {
      currentHue = parseFloat(this.dataset.h);
      currentChroma = parseFloat(this.dataset.c);
      currentLightness = parseFloat(this.dataset.l);
      document.getElementById('hueSlider').value = currentHue;
      document.getElementById('chromaSlider').value = currentChroma;
      document.getElementById('lightnessSlider').value = currentLightness;
      document.getElementById('hueValue').textContent = Math.round(currentHue) + '°';
      document.getElementById('chromaValue').textContent = currentChroma.toFixed(2);
      document.getElementById('lightnessValue').textContent = currentLightness + '%';
      addToRecentColors(oklchToHex(currentHue, currentChroma, currentLightness));
      updateColorPreview();
      document.getElementById('colorPicker').value = oklchToHex(currentHue, currentChroma, currentLightness);
      document.documentElement.style.setProperty('--base-hue', currentHue);
      document.documentElement.style.setProperty('--base-chroma', currentChroma);
      updateTextPrimary(currentLightness);
    });
  });

  document.getElementById('applyColorBtn').addEventListener('click', function() {
      const settings = {
          hue: currentHue,
          chroma: currentChroma,
          lightness: currentLightness,
          recentColors: recentColors || []
      };
      localStorage.setItem('appColorSettings', JSON.stringify(settings));

      document.documentElement.style.setProperty('--base-hue', currentHue);
      document.documentElement.style.setProperty('--base-chroma', currentChroma);
      document.getElementById('colorPicker').value = oklchToHex(currentHue, currentChroma, currentLightness);
      updateTextPrimary(currentLightness);

      const hexColor = oklchToHex(currentHue, currentChroma, currentLightness);
      const successMsg = (translations['apply_color_success'] || 'Background color %s has been applied successfully.').replace('%s', hexColor);
      if (typeof showLogMessage === 'function') showLogMessage(successMsg);
      if (typeof speakMessage === 'function') speakMessage(successMsg);

      colorModal.hide();
  });

  document.getElementById('resetColorBtn').addEventListener('click', function() {
      currentHue = 260;
      currentChroma = 0.10;
      currentLightness = 30;
      document.getElementById('hueSlider').value = currentHue;
      document.getElementById('chromaSlider').value = currentChroma;
      document.getElementById('lightnessSlider').value = currentLightness;
      document.getElementById('hueValue').textContent = currentHue + '°';
      document.getElementById('chromaValue').textContent = currentChroma.toFixed(2);
      document.getElementById('lightnessValue').textContent = currentLightness + '%';
      updateColorPreview();
      document.getElementById('colorPicker').value = oklchToHex(currentHue, currentChroma, currentLightness);
      document.documentElement.style.setProperty('--base-hue', currentHue);
      document.documentElement.style.setProperty('--base-chroma', currentChroma);
      updateTextPrimary(currentLightness);

      const resetMsg = translations['reset_color_success'] || 'Application color settings have been reset to default.';
      if (typeof showLogMessage === 'function') showLogMessage(resetMsg);
      if (typeof speakMessage === 'function') speakMessage(resetMsg);
  });

  initRecentColors();
  const savedSettings = localStorage.getItem('appColorSettings');
  if (savedSettings) {
    const settings = JSON.parse(savedSettings);
    document.documentElement.style.setProperty('--base-hue', settings.hue || 260);
    document.documentElement.style.setProperty('--base-chroma', settings.chroma || 0.10);
    document.getElementById('colorPicker').value = oklchToHex(settings.hue || 260, settings.chroma || 0.10, settings.lightness || 30);
    updateTextPrimary(settings.lightness || 30);
  }
});

document.getElementById('removeAppColorBtn').addEventListener('click', function() {
    const confirmMsg = translations['confirm_reset_color'] || 'Are you sure you want to reset color settings to default?';

    showConfirmation(confirmMsg, function() {
        localStorage.removeItem('appColorSettings');

        let defaultHue = 260;
        let defaultChroma = 0.10;
        let defaultLightness = 30;
        document.getElementById('hueSlider').value = defaultHue;
        document.getElementById('chromaSlider').value = defaultChroma;
        document.getElementById('lightnessSlider').value = defaultLightness;
        document.getElementById('hueValue').textContent = defaultHue + '°';
        document.getElementById('chromaValue').textContent = defaultChroma.toFixed(2);
        document.getElementById('lightnessValue').textContent = defaultLightness + '%';

        if (typeof oklchToHex === 'function') {
            const hex = oklchToHex(defaultHue, defaultChroma, defaultLightness);
            document.getElementById('colorPreview').style.backgroundColor = hex;
            document.getElementById('colorPicker').value = hex;
        } else {
            document.getElementById('colorPreview').style.backgroundColor = '';
            document.getElementById('colorPicker').value = '';
        }

        let recentColorsDiv = document.getElementById('recentColors');
        if (recentColorsDiv) recentColorsDiv.innerHTML = '';

        document.documentElement.style.setProperty('--base-hue', defaultHue);
        document.documentElement.style.setProperty('--base-chroma', defaultChroma);

        document.documentElement.setAttribute('data-theme', defaultLightness > 60 ? 'light' : 'dark');

        const successMsg = translations['reset_color_success'] || 'Application color settings have been reset to default.';
        if (typeof showLogMessage === 'function') showLogMessage(successMsg);
        if (typeof speakMessage === 'function') speakMessage(successMsg);
    });
});

function checkColorChange() {
    const saved = localStorage.getItem('appColorSettings');
    
    if (saved) {
        const settings = JSON.parse(saved);
        
        const rootStyles = getComputedStyle(document.documentElement);
        const currentHueValue = parseFloat(rootStyles.getPropertyValue('--base-hue').trim()) || 0;
        const currentChromaValue = parseFloat(rootStyles.getPropertyValue('--base-chroma').trim()) || 0;
        
        if (Math.abs(settings.hue - currentHueValue) > 1 || Math.abs(settings.chroma - currentChromaValue) > 0.01) {
            document.documentElement.style.setProperty('--base-hue', settings.hue);
            document.documentElement.style.setProperty('--base-chroma', settings.chroma);
            
            const textL = settings.lightness > 60 ? 20 : 95;
            document.documentElement.style.setProperty('--text-primary', `oklch(${textL}% 0 0)`);
            
            const theme = settings.lightness > 60 ? 'light' : 'dark';
            document.documentElement.setAttribute('data-theme', theme);
        }
    }
}

setInterval(checkColorChange, 1000);
</script>

<script>
window.showConfirmation = function(message, onConfirm) {
    const decodedMessage = decodeURIComponent(message);
    const modalElement = document.getElementById('confirmModal');
    document.getElementById('confirmModalMessage').innerText = decodedMessage;

    const oldBtn = document.getElementById('confirmModalYes');
    const newBtn = oldBtn.cloneNode(true);
    oldBtn.parentNode.replaceChild(newBtn, oldBtn);

    newBtn.addEventListener('click', () => {
        const modal = bootstrap.Modal.getInstance(modalElement);
        modal.hide();
        if (typeof onConfirm === 'function') onConfirm();
    });

    let modal = bootstrap.Modal.getInstance(modalElement);
    if (!modal) {
        modal = new bootstrap.Modal(modalElement);
    }
    modal.show();
};
</script>

<script>
document.addEventListener('DOMContentLoaded', () => {
    const currentSong = document.querySelector('#currentSong');
    const floatingCurrentSong = document.getElementById('floatingCurrentSong');
    const dynamicTitle = document.getElementById('dynamicTitle');

    let usedColors = [];
    let usedLogBoxColors = [];

    function getColorListFromTheme() {
        const styles = getComputedStyle(document.documentElement);
        const lightness = styles.getPropertyValue('--l').trim();
        const chroma = styles.getPropertyValue('--c').trim();

        const colors = [];
        for (let i = 1; i <= 7; i++) {
            const hue = styles.getPropertyValue(`--base-hue-${i}`).trim();
            const color = `oklch(${lightness} ${chroma} ${hue})`;
            colors.push(color);
        }
        return colors;
    }

    function getNextColor(colorList) {
        if (usedColors.length === colorList.length) {
            usedColors = [];
        }
        const remaining = colorList.filter(c => !usedColors.includes(c));
        const next = remaining[Math.floor(Math.random() * remaining.length)];
        usedColors.push(next);
        return next;
    }

    function rotateColors() {
        const colorList = getColorListFromTheme();

        if (currentSong) {
            currentSong.style.color = getNextColor(colorList);
        }
        if (floatingCurrentSong) {
            floatingCurrentSong.style.color = getNextColor(colorList);
        }
        if (dynamicTitle) {
            dynamicTitle.style.color = getNextColor(colorList);
        }
    }

    function getLogBoxColorListFromTheme() {
        const styles = getComputedStyle(document.documentElement);
        const lightness = '35%';
        const chroma = styles.getPropertyValue('--c').trim();

        const colors = new Set();
        for (let i = 1; i <= 7; i++) {
            let hue = styles.getPropertyValue(`--base-hue-${i}`).trim();
            if (!hue) continue;
            let color = `oklch(${lightness} ${chroma} ${hue})`;
            colors.add(color);
        }
        return Array.from(colors);
    }

    function getNextLogBoxColor(colorList) {
        if (usedLogBoxColors.length >= colorList.length) {
            usedLogBoxColors = [];
        }
        const remaining = colorList.filter(c => !usedLogBoxColors.includes(c));
        const next = remaining[Math.floor(Math.random() * remaining.length)];
        usedLogBoxColors.push(next);
        return next;
    }

    function rotateLogBoxColors() {
        const colorList = getLogBoxColorListFromTheme();
        if (colorList.length === 0) return;

        document.querySelectorAll('.log-box[data-dynamic-bg="true"]').forEach(box => {
            const color = getNextLogBoxColor(colorList);
            box.style.background = color;
        });
    }

    rotateColors();
    rotateLogBoxColors();
    setInterval(rotateColors, 4000);
    setInterval(rotateLogBoxColors, 4000);
});
</script>

<style>
.lyrics-mode {
    .non-lyrics-content {
        display: none !important;
    }

    #lyricsContainer {
        height: calc(70vh - 150px) !important; 
        position: relative;
        z-index: 1000;
    }

    #currentSong {
        font-size: 1.5rem;
        margin-bottom: 1rem;
    }

    #floatingLyrics {
        display: none;
    }
}

#lyricsToggle .bi {
    transition: transform 0.3s;
}
.lyrics-mode #lyricsToggle .bi {
    transform: rotate(180deg);
}
</style>

<script>
let isLyricsMode = localStorage.getItem('lyricsMode') === 'true';

function toggleLyricsMode() {
    const modal = document.getElementById('musicModal');
    const icon = document.getElementById('lyricsIcon');

    isLyricsMode = !isLyricsMode;
    modal.classList.toggle('lyrics-mode', isLyricsMode);
    localStorage.setItem('lyricsMode', isLyricsMode);

    icon.className = isLyricsMode ? 'bi bi-chevron-up' : 'bi bi-chevron-down';
}

document.addEventListener('DOMContentLoaded', () => {
    const icon = document.getElementById('lyricsIcon');
    document.getElementById('lyricsToggle').addEventListener('click', toggleLyricsMode);

    if (isLyricsMode) {
        document.getElementById('musicModal').classList.add('lyrics-mode');
        icon.className = 'bi bi-chevron-up';
    }
});
</script>

<script>
    window.toggleIpStatusBar = function() {
        const ipStatusBar = document.getElementById('status-bar-component');
        if (!ipStatusBar) return;
        
        const isHidden = ipStatusBar.style.display === 'none';

        if (isHidden) {
            ipStatusBar.style.display = '';
            localStorage.setItem('neko_ip_status_hidden', 'false');
            if (typeof speakMessage === 'function') {
                speakMessage(translations['ip_info_shown'] || 'IP Information Shown');
            }
            if (typeof showLogMessage === 'function') {
                showLogMessage(translations['ip_info_shown'] || 'IP Information Shown');
            }
        } else {
            ipStatusBar.style.display = 'none';
            localStorage.setItem('neko_ip_status_hidden', 'true');
            if (typeof speakMessage === 'function') {
                speakMessage(translations['ip_info_hidden'] || 'IP Information Hidden');
            }
            if (typeof showLogMessage === 'function') {
                showLogMessage(translations['ip_info_hidden'] || 'IP Information Hidden');
            }
        }
    };

    document.addEventListener('DOMContentLoaded', () => {
        const storedValue = localStorage.getItem('neko_ip_status_hidden');
        const ipStatusHidden = storedValue === null || storedValue === 'true';
        const ipStatusBar = document.getElementById('status-bar-component');
        
        if (ipStatusBar) {
            ipStatusBar.style.display = ipStatusHidden ? 'none' : '';
        }
        localStorage.setItem('neko_ip_status_hidden', ipStatusHidden.toString());
    });
</script>

<script>
document.addEventListener("DOMContentLoaded", () => {
  const btn = document.getElementById("fontSwitchBtn");
  const icon = document.getElementById("fontSwitchIcon");
  const body = document.body;
  const storageKey = "fontSwitch";

  const fonts = [
    { class: "default-font", key: "font_default", icon: "fa-font" },
    { class: "fredoka-font", key: "font_fredoka", icon: "fa-child-reaching" },
    { class: "cinzel-font", key: "font_cinzel", icon: "fa-crown" },
    { class: "system-nofo-font", key: "font_noto", icon: "fa-language" },
    { class: "noto-sans-font", key: "font_noto_sans", icon: "fa-globe" },
    { class: "system-mono-font", key: "font_mono", icon: "fa-code" },
    { class: "dm-serif-font", key: "font_dm_serif", icon: "fa-feather-pointed" }
  ];

  const savedFont = localStorage.getItem(storageKey);
  if (savedFont) {
    const fontObj = fonts.find(f => f.class === savedFont);
    body.classList.add(savedFont);
    if (fontObj) updateIcon(fontObj.icon);
  } else {
    updateIcon("fa-font");
  }

  btn.addEventListener("click", () => {
    const currentIndex = fonts.findIndex(f => body.classList.contains(f.class));
    const nextIndex = (currentIndex + 1) % fonts.length;
    const nextFont = fonts[nextIndex];

    fonts.forEach(f => body.classList.remove(f.class));
    body.classList.add(nextFont.class);

    body.classList.add("font-transition");

    setTimeout(() => {
      body.classList.remove("font-transition");
    }, 400);

    localStorage.setItem(storageKey, nextFont.class);

    updateIcon(nextFont.icon);

    const message = translations[nextFont.key] || "Switched font";
    if (typeof speakMessage === "function") speakMessage(message);
    if (typeof showLogMessage === "function") showLogMessage(message);
  });

  function updateIcon(iconName) {
    icon.className = `fa-solid ${iconName}`;
    icon.style.color = "white";
  }
});
</script>

<style>
:root {
	--base-hue: 260;
	--base-chroma: 0.03;
	--danger-base: 15;
	--base-hue-1: 20;
	--base-hue-2: 200;
	--base-hue-3: 135;
	--base-hue-4: 80;
	--base-hue-5: 270;
	--base-hue-6: 170;
	--base-hue-7: 340;
	--l: 85%;
	--c: 0.18;
	--glass-blur: blur(20px);
	--radius: 20px;
        --glass-opacity: 0.85;
        --glass-border: 1px solid rgba(255, 255, 255, 0.1);
        --shadow-intensity: 0.25;
        --text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
        --transition-speed: 0.3s;
        --highlight-intensity: 0.8;
        --border-strong: 1px solid oklch(70% 0.1 var(--base-hue) / 0.6);

	--bg-body: oklch(40% var(--base-chroma) var(--base-hue) / 90%);
	--bg-container: oklch(30% var(--base-chroma) var(--base-hue));
	--text-primary: oklch(95% 0 0);
	--accent-color: oklch(70% 0.2 calc(var(--base-hue) + 0));
	--card-bg: oklch(25% var(--base-chroma) var(--base-hue));
	--header-bg: oklch(35% var(--base-chroma) var(--base-hue));
	--border-color: oklch(40% var(--base-chroma) var(--base-hue));
	
	--btn-primary-bg: oklch(50% 0.18 var(--base-hue));
	--btn-primary-hover: color-mix(in oklch, var(--btn-primary-bg), white 12%);
	--btn-success-bg: oklch(55% 0.22 140);
	--btn-info-bg: oklch(55% 0.22 220);
	--btn-warning-bg: oklch(65% 0.18 80);
	--btn-danger-bg: oklch(55% 0.25 var(--danger-base));
	
	--item-hover-bg: color-mix(in oklch, var(--btn-primary-bg), white 15%);
	--item-hover-shadow: 0 4px 12px oklch(0 0 0 / 0.4);
	--drag-over-bg: oklch(35% 0.05 var(--base-hue) / 0.3);
	--drag-over-shadow: 0 0 25px oklch(var(--base-hue) 0.2 0.4 / 0.3);
	
	--text-secondary: oklch(75% 0.03 0);
	--success-text: oklch(75% 0.22 140);
	--info-text: oklch(75% 0.22 220);
	--warning-text: oklch(80% 0.22 80);
	--danger-text: oklch(70% 0.28 30);
	
	--ocean-bg: oklch(48% 0.32 calc(var(--base-hue) + 220));
	--forest-bg: oklch(42% 0.32 calc(var(--base-hue) + 140));
	--rose-bg: oklch(48% 0.32 calc(var(--base-hue) + 350));
	--lavender-bg: oklch(46% 0.32 calc(var(--base-hue) + 270));
	--sand-bg: oklch(45% 0.32 calc(var(--base-hue) + 60));
	
	--glass-blur: blur(20px);
	--radius: 16px;
	--transition: all 0.25s ease;
	
	--primary-color: var(--accent-color);
	--secondary-color: var(--btn-primary-bg);
	--background: var(--bg-body);
	--text-color: var(--text-primary);
}

[data-theme="light"] {
	--base-hue: 200;
	--base-chroma: 0.01;
	--l: 60%;
	--c: 0.25;

	--bg-body: oklch(95% var(--base-chroma) var(--base-hue) / 90%);
	--bg-container: oklch(99% var(--base-chroma) var(--base-hue));
	--text-primary: oklch(25% var(--base-chroma) var(--base-hue));
	--accent-color: oklch(60% 0.2 calc(var(--base-hue) + 60));
	--card-bg: oklch(96% var(--base-chroma) var(--base-hue));
	--header-bg: oklch(88% var(--base-chroma) var(--base-hue));
	--border-color: oklch(85% 0.03 var(--base-hue));
        --border-strong: 1px solid oklch(70% 0.1 var(--base-hue) / 0.6);
	
	--btn-primary-bg: oklch(60% 0.35 var(--base-hue));
	--btn-success-bg: oklch(75% 0.25 140);
	--btn-info-bg: oklch(65% 0.3 220);
	--btn-warning-bg: oklch(65% 0.25 80);
	--btn-danger-bg: oklch(55% 0.35 var(--danger-base));
	
	--item-hover-bg: color-mix(in oklch, var(--accent-color), white 25%);
	--item-hover-shadow: 0 2px 15px oklch(0 0 0 / 0.15);
	--drag-over-bg: oklch(92% 0.01 var(--base-hue) / 0.3);
	--drag-over-shadow: 0 0 20px oklch(0 0 0 / 0.1);
	
	--text-secondary: oklch(45% 0.03 0);
	--success-text: oklch(40% 0.25 140);
	--info-text: oklch(40% 0.25 220);
	--warning-text: oklch(45% 0.25 80);
	--danger-text: oklch(45% 0.35 30);
	
	--ocean-bg: oklch(85% 0.18 calc(var(--base-hue) + 220));
	--highlight-color: oklch(90% 0.15 calc(var(--base-hue) + 90));
	--soft-highlight: oklch(85% 0.1 calc(var(--base-hue) + 90));
}

@font-face {
	font-family: 'Cinzel Decorative';
           font-style: normal;
           font-weight: 700;
           src: url('./assets/webfonts/cinzel-decorative-v17-latin-700.woff2') format('woff2');
}

@font-face {
	font-family: 'Cinzel Decorative';
           font-style: normal;
           font-weight: 900;
           src: url('./assets/webfonts/cinzel-decorative-v17-latin-900.woff2') format('woff2');
}

@font-face {
        font-display: swap; 
        font-family: 'Fredoka One';
        font-style: normal;
        font-weight: 400;
           src: url('./assets/webfonts/fredoka-v16-latin-regular.woff2') format('woff2');
}

@font-face {
        font-display: swap; 
        font-family: 'Noto Serif SC';
        font-style: normal;
        font-weight: 400;
           src: url('./assets/webfonts/noto-serif-sc-v31-latin-regular.woff2') format('woff2'); 
}

@font-face {
        font-display: swap; 
        font-family: 'Comic Neue';
        font-style: normal;
        font-weight: 400;
           src: url('./assets/webfonts/comic-neue-v8-latin-regular.woff2') format('woff2'); 
}

@font-face {
        font-display: swap; 
        font-family: 'DM Serif Display';
        font-style: normal;
        font-weight: 400;
           src: url('./assets/webfonts/dm-serif-display-v15-latin-regular.woff2') format('woff2');
}

@font-face {
  font-display: swap;
  font-family: 'Noto Sans';
  font-style: normal;
  font-weight: 400;
  src: url('./assets/webfonts/noto-sans-v39-cyrillic_cyrillic-ext_devanagari_greek_greek-ext_latin_latin-ext_vietnamese-regular.woff2') format('woff2');
}

@font-face {
  font-display: swap;
  font-family: 'Noto Sans';
  font-style: normal;
  font-weight: 500;
  src: url('./assets/webfonts/noto-sans-v39-cyrillic_cyrillic-ext_devanagari_greek_greek-ext_latin_latin-ext_vietnamese-500.woff2') format('woff2');
}

body {
	margin: 0;
	color: var(--text-color);
	background-attachment: fixed;
}

#playerModal.active {
	display: flex;
	animation: slideIn 0.3s ease forwards;
}

@keyframes slideIn {
	from {
		transform: translateY(40px);
		opacity: 0;
	}

	to {
		transform: translateY(0);
		opacity: 1;
	}
}

.lyrics-container {
	flex: 1;
	overflow-y: auto;
	padding: 12px;
	margin-bottom: 15px;
	border-radius: var(--radius);
	background: var(--card-bg);
	border: var(--border-strong);
	display: flex;
	flex-direction: column;
	align-items: center;
}

.lyric-line {
	opacity: 1 !important;
	color: var(--text-primary) !important;
	font-size: 1.1rem;
	transition: all 0.3s ease;
	transition: color 0.3s;
}

.lyric-line .char {
	display: inline-block;
	white-space: nowrap;
	margin-right: 0.1rem;
}

.lyric-line .char.played {
	background: linear-gradient(...);
}

.lyric-line.highlight {
	color: var(--text-primary) !important;
	font-size: 1.3rem;
}

.lyric-line.highlight .char {
	transition: all 0.1s ease;
}

.lyric-line.highlight .char.active {
	opacity: 1;
	transform: scale(1.3);
	background: linear-gradient(
        90deg,
        oklch(65% 0.25 15) 0%, 
        oklch(70% 0.25 50) 25%,
        oklch(75% 0.25 85) 50%, 
        oklch(70% 0.25 135) 75%,
        oklch(65% 0.25 240) 100%
    );
	background-size: 200% auto;
	background-clip: text;
	-webkit-background-clip: text;
	color: transparent !important;
	animation: color-flow 1s linear infinite;
	0 0 10px rgba(255,51,102,0.5),
        0 0 15px rgba(102,255,51,0.5),
        0 0 20px rgba(51,204,255,0.5);
}

.lyric-line.enter-active {
	animation: textPop 0.5s ease;
}

@keyframes textPop {
	from {
		opacity: 0;
		transform: translateY(10px);
	}

	to {
		opacity: 1;
		transform: translateY(0);
	}
}

@keyframes color-flow {
	0% {
		background-position: 0% 50%;
	}

	50% {
		background-position: 100% 50%;
	}

	100% {
		background-position: 0% 50%;
	}
}

.char.space {
	display: inline;
	min-width: 0.5em;
}

.progress-container {
	width: 100%;
	height: 6px;
	background: var(--border-color);
	border-radius: 4px;
	margin: 16px 0;
	overflow: hidden;
}

.progress-bar {
	height: 100%;
	background: var(--accent-color);
	transition: width 0.2s ease;
}

.controls {
	display: flex;
	justify-content: center;
	gap: 20px;
	margin-top: 15px;
}

.control-btn, #volumeToggle {
	background: var(--card-bg);
	border: var(--border-strong);
	color: var(--text-color);
	width: 48px;
	height: 48px;
	border-radius: 50%;
	cursor: pointer;
	font-size: 1.2rem;
	transition: all 0.3s ease;
}

.control-btn:hover, #volumeToggle:hover {
	background: var(--item-hover-bg);
	transform: scale(1.1);
}

#playPauseBtn {
	width: 60px;
	height: 60px;
	font-size: 1.5rem;
	background: var(--accent-color);
	color: var(--text-primary);
	box-shadow: 0 4px 20px rgba(var(--accent-color), 0.3);
}

.playlist {
	margin-top: 20px;
	max-height: 380px;
	overflow-y: auto;
	padding: 10px;
	border-radius: var(--radius);
	background: var(--card-bg);
        box-shadow: 
            inset 1px 1px 2px rgba(255, 255, 255, 0.1),
            inset -1px -1px 2px rgba(0, 0, 0, 0.15),
            inset 1px -1px 1px rgba(0, 0, 0, 0.08),
            inset -1px 1px 1px rgba(0, 0, 0, 0.08);
	border: var(--border-strong);
        transition: all 0.3s ease;
}

.lyrics-container:hover,
.playlist:hover {
        transform: translateY(-2px);
        box-shadow: 
            inset 1px 1px 2px rgba(255, 255, 255, 0.1),
            inset -1px -1px 2px rgba(0, 0, 0, 0.15),
            inset 1px -1px 1px rgba(0, 0, 0, 0.08),
            inset -1px 1px 1px rgba(0, 0, 0, 0.08),
            0 4px 8px rgba(0, 0, 0, 0.1);
}

.playlist-item {
	padding: 10px 14px;
	border-radius: 10px;
	cursor: pointer;
	transition: all 0.2s ease;
	font-size: 0.95rem;
}

.playlist-item:hover {
	background: var(--item-hover-bg);
	color: #fff;
	font-weight: bold;
}

.playlist-item.active {
	background: var(--rose-bg);
	color: white;
	font-weight: bold;
}

#floatingLyrics {
	position: fixed;
	top: 1%;
	left: 4.5%;
	background: var(--bg-container);
	padding: 15px 10px;
	border-radius: 20px;
	backdrop-filter: var(--glass-blur);
	display: none;
	opacity: 0;
	pointer-events: none;
	cursor: grab;
	transition: opacity 0.3s ease;
	writing-mode: vertical-rl;
	text-orientation: mixed;
	line-height: 2;
	z-index: 1060;
	flex-direction: column;
	gap: 0.5em;
	width: 200px;
	resize: none;
	overflow: auto;
	user-select: none;
	border: var(--border-strong);
}

@keyframes float {
	from {
		transform: translateY(0);
	}

	to {
		transform: translateY(-10px);
	}
}

@keyframes breath {
	0%, 100% {
		--glow-primary: oklch(85% 0.32 var(--glow-base));
		box-shadow: 0 0 10px 2px color-mix(in oklch, var(--glow-primary), transparent 50%),
            inset 0 -10px 20px color-mix(in oklch, var(--glow-primary), transparent 70%);
	}

	50% {
		--glow-primary: oklch(92% 0.38 var(--glow-base));
		box-shadow: 0 0 20px 4px color-mix(in oklch, var(--glow-primary), transparent 30%),
            inset 0 -15px 30px color-mix(in oklch, var(--glow-primary), transparent 50%);
	}
}

[data-theme="dark"] #floatingLyrics {
	--glow-base: var(--base-hue);
	--glow-primary: oklch(88% 0.35 var(--glow-base));
	--glow-secondary: oklch(85% 0.3 calc(var(--glow-base) + 15));
	border: 1px solid color-mix(in oklch, var(--glow-primary), transparent 10%);
	box-shadow: 0 0 12px 2px color-mix(in oklch, var(--glow-primary), transparent 40%),
        inset 0 -12px 24px color-mix(in oklch, var(--glow-primary), transparent 60%);
	animation: float 3s ease-in-out infinite alternate,
        breath 4s ease-in-out infinite;
}

[data-theme="dark"] #floatingLyrics:hover {
	animation-play-state: paused;
	--glow-primary: oklch(92% 0.38 var(--glow-base));
	box-shadow: 0 0 20px 4px color-mix(in oklch, var(--glow-primary), transparent 30%),
        inset 0 -15px 30px color-mix(in oklch, var(--glow-primary), transparent 50%);
}

#floatingLyrics.visible {
	display: flex;
	opacity: 1;
	pointer-events: auto;
	cursor: move;
}

#floatingLyrics #floatingCurrentSong.vertical-title {
	font-size: 1.8rem;
	font-weight: 700;
	writing-mode: vertical-rl;
	padding-right: 0.5em;
	margin-left: auto;
	margin-right: auto;
	text-shadow: 0px 1px 2px rgba(0, 0, 0, 0.3), 
                 0px -1px 2px rgba(255, 255, 255, 0.4);
}

#floatingLyrics .vertical-lyrics {
	writing-mode: vertical-rl;
	text-combine-upright: all;
}

#floatingLyrics .char {
	font-size: 1.6rem;
	transition: transform 0.3s ease;
	display: inline-block;
	position: relative;
	margin-bottom: 10px;
}

.floating-controls {
	display: flex;
	flex-direction: row;
	gap: 0.8em;
	margin-bottom: 1em;
	order: -1;
}

.ctrl-btn {
	background: var(--bg-body);
	border: var(--border-strong);
	color: var(--text-primary) !important;
	border-radius: 50%;
	width: 36px;
	height: 36px;
	display: flex;
	align-items: center;
	justify-content: center;
	transition: all 0.3s ease;
	backdrop-filter: blur(5px);
}

.ctrl-btn:hover {
	background: var(--item-hover-bg);
	transform: scale(1.1);
}

.ctrl-btn.clicked {
	transform: scale(0.9);
	background: rgba(50, 205, 50, 0.5);
}

.ctrl-btn i {
	font-size: 1.6rem;
	display: block;
	vertical-align: middle;
	line-height: 1;
	margin: 0;
	padding: 0;
}

#currentSong.vertical-title {
	margin-top: 0.5em;
	border-right: none;
	padding-right: 0;
	padding-bottom: 0.8em;
	margin-right: 0;
	writing-mode: horizontal-tb;
}

.vertical-lyrics {
	margin-top: 0.5em;
	overflow-x: hidden;
	max-width: 100%;
	word-break: break-all;
}

.char {
	transition: all 0.3s ease;
	display: inline-block;
	margin-right: 2px;
}

#floatingLyrics .char.active {
	color: var(--accent-color);
	animation: bounce-scale 0.6s ease-out;
	transform: scale(1.3);
	position: relative;
	text-shadow: none !important;
}

@keyframes bounce-scale {
	0% {
		transform: scale(1);
	}

	50% {
		transform: scale(1.3);
	}

	70% {
		transform: scale(1.1);
	}

	100% {
		transform: scale(1);
	}
}

.char.played {
	transform: scale(1) !important;
}

.playlist {
	counter-reset: list-item;
}

.playlist-item::before {
	content: counter(list-item) ".";
	counter-increment: list-item;
	margin-right: 8px;
	opacity: 0.6;
}

.time-display {
	display: flex;
	justify-content: space-between;
	margin-top: 8px;
	font-size: 0.9em;
	color: var(--text-secondary);
}

.progress-container {
	cursor: pointer;
}

.char.active {
	transform: scale(1.2);
}

.char[data-start] + .char[data-start] {
	margin-left: 12px;
}

.lyrics-loading {
	position: relative;
	min-height: 100px;
}

#no-lyrics {
	text-align: center;
	color: var(--text-secondary);
	padding: 2rem;
	font-size: 1.8em;
}

#noLyricsFloating {
	width: min-content;
	max-width: 4em;
	text-align: center;
	color: var(--text-primary) !important;
	line-height: 1.2;
	font-size: 1.5rem;
	padding: 10px 2px;
	letter-spacing: 0.2em;
	writing-mode: vertical-rl;
	text-orientation: upright;
}

@keyframes glow {
	0% {
		opacity: 0.8;
	}

	50% {
		opacity: 1;
	}

	100% {
		opacity: 0.8;
	}
}

.progress-bar {
	height: 100%;
	background: var(--btn-success-bg);
	border-radius: 4px;
	transition: width 0.1s linear;
}

.progress-overlay {
	position: absolute;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
	z-index: 2;
}

#currentSong {
	font-weight: bold !important;
	color: var(--accent-color);
	text-shadow: 0px 1px 2px rgba(0, 0, 0, 0.3), 
                 0px -1px 2px rgba(255, 255, 255, 0.4);
}

#volumePanel {
	position: absolute;
	bottom: 100%;
	left: 50%;
	transform: translateX(-50%);
	margin-bottom: 10px;
	background-color: var(--card-bg);
	border: var(--border-strong);
	border-radius: 0.5rem;
	padding: 10px;
	width: 160px;
	box-shadow: 0 4px 10px var(--border-color);
	z-index: 1000;
	display: none;
}

#volumeSlider {
	width: 100%;
	accent-color: var(--text-color);
}

#volumeLabel {
	color: var(--text-color);
	font-size: 0.9rem;
	text-align: right;
	margin-top: 5px;
}

.heart {
	position: absolute;
	font-size: 2rem;
	color: #ff69b4;
	pointer-events: none;
	opacity: 0;
	z-index: 9999;
	animation: heartAnimation 1s ease-in-out forwards;
}

@keyframes heartAnimation {
	0% {
		transform: scale(1) translateY(0);
		opacity: 1;
	}

	50% {
		transform: scale(1.5) translateY(-50px);
		opacity: 1;
	}

	100% {
		transform: scale(0) translateY(-100px);
		opacity: 0;
	}
}

.log-box {
	position: fixed;
	left: 20px;
	padding: 12px 16px;
	background: var(--accent-color);
	color: white;
	border-radius: 8px;
	z-index: 9999;
	max-width: 370px;
	font-size: 15px;
	word-wrap: break-word;
	line-height: 1.5;
	box-shadow: 0 4px 6px rgba(0, 0, 0, 0.15);
	border: var(--border-strong);
	text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
	backdrop-filter: blur(2px);
	transform: translateY(0);
	opacity: 0;
	animation: scrollUp 12s cubic-bezier(0.25, 0.46, 0.45, 0.94) forwards;
	display: inline-block;
	margin-bottom: 10px;
	transition: transform 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

@keyframes scrollUp {
	0% {
		top: 90%;
		opacity: 0;
	}

	20% {
		opacity: 1;
	}

	80% {
		top: 50%;
		opacity: 1;
	}

	100% {
		top: 45%;
		opacity: 0;
	}
}

.log-box.exiting {
	animation: fadeOut 0.3s forwards;
}

.log-content {
	padding: 6px 20px 6px 8px;
	color: white;
}

.log-close-btn {
	position: absolute;
	top: 6px;
	right: 10px;
	background: transparent;
	border: none;
	color: inherit;
	cursor: pointer;
	font-size: 20px;
	line-height: 1;
	opacity: 0;
	pointer-events: none;
	transition: opacity 0.2s;
}

.log-box:hover .log-close-btn {
	opacity: 0.7;
	pointer-events: auto;
}

.log-box:hover .log-close-btn:hover {
	opacity: 1;
}

@keyframes fadeOut {
	to {
		opacity: 0;
		transform: translateY(-20px) scale(0.95);
	}
}

.log-icon {
	display: inline-block;
	width: 20px;
	height: 20px;
	margin-right: 3px;
	vertical-align: middle;
}

.log-box.error {
	background: linear-gradient(145deg, #ff4444, #cc0000);
}

.log-box.warning {
	background: linear-gradient(145deg, #ffc107, #ffab00);
}

.log-box.info {
	background: linear-gradient(145deg, #2196F3, #1976D2);
}

@media (max-width: 768px) {
	.log-box {
		left: 10px;
		right: 10px;
		max-width: none;
		font-size: 14px;
	}
}

.list-group-item {
	cursor: pointer;
	color: var(--text-primary);
	background: var(--bg-container);
	border: var(--border-strong);
	transition: background 0.3s ease;
}

.list-group-item:hover {
	background: var(--item-hover-bg);
	color: white !important;
}

.list-group-item:hover .text-muted,
.list-group-item:hover .text-truncate {
	color: white !important;
}

.list-group-item.active {
	background: var(--accent-color);
	color: white;
	border: 1px solid var(--accent-color);
}

.list-group-item.active .badge,
.list-group-item.active .text-truncate,
.list-group-item.active small,
.list-group-item.active i {
	color: white !important;
}

.list-group-item .delete-item {
	cursor: pointer;
}

.modal-xl {
	max-width: 60% !important;
	width: 90% !important;
}

@media (max-width: 768px) {
	.modal-xl {
		max-width: 95% !important;
		width: 95% !important;
		margin: 1rem auto !important;
	}
}

@media (max-width: 576px) {
	.modal-xl {
		max-width: 100% !important;
		width: 100% !important;
		margin: 0.5rem auto !important;
	}
}

@media (max-width: 768px) {
	.container-sm .btn i {
		margin-right: 0;
	}

	.container-sm .btn {
		font-size: 9px;
	}
}

@media (max-width: 768px) {
	.modal-body img {
		display: none;
	}

	.datetime-container {
		font-size: 17px !important;
	}
}

@media (max-width: 768px) {

	.section-container .nav-pills {
		justify-content: center !important;
	}

	.section-container .nav-pills .nav-link {
		text-align: center;
	}
}

.control-panel-overlay {
	position: fixed;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
	background: none !important;
        backdrop-filter: none !important;
	display: none;
	justify-content: center;
	align-items: center;
	z-index: 1050;
	backdrop-filter: blur(3px);
        transition: opacity 0.3s ease;
}

.control-panel {
	--primary-gradient: linear-gradient(135deg, #0f3460, #1a508b, #2d8bc0);
	--button-hover: rgba(255, 255, 255, 0.2);
	--panel-padding: 20px;
	background: var(--primary-gradient);
	border-radius: 20px;
	box-shadow: 0 15px 35px rgba(0, 0, 0, 0.5);
	overflow: hidden;
	padding: var(--panel-padding);
	position: relative;
	z-index: 10;
	max-width: 1000px;
	width: 90%;
	margin: 0;
	display: block;
}

.control-panel::before {
	content: '';
	position: absolute;
	top: 0;
	left: 0;
	right: 0;
	bottom: 0;
	background: url('data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiPjxkZWZzPjxwYXR0ZXJuIGlkPSJwYXR0ZXJuIiB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHBhdHRlcm5Vbml0cz0idXNlclNwYWNlT25Vc2UiIHBhdHRlcm5UcmFuc2Zvcm09InJvdGF0ZSg0NSkiPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjAuNSIgZmlsbD0iIzEzNDI3OSIvPjwvcGF0dGVybj48L2RlZnM+PHJlY3Qgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgZmlsbD0idXJsKCNwYXR0ZXJuKSIgb3BhY2l0eT0iMC4xIi8+PC9zdmc+');
	opacity: 0.1;
	z-index: -1;
}

.panel-header {
	display: flex;
	align-items: center;
	justify-content: space-between;
	margin-bottom: 25px;
	padding-bottom: 15px;
	border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.panel-header h3 {
	margin: 0;
	font-weight: 600;
	font-size: 1.8rem;
	display: flex;
	align-items: center;
	gap: 12px;
	color: var(--accent-color);
}

.panel-header h3 i {
	background: rgba(255, 255, 255, 0.15);
	width: 50px;
	height: 50px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 1.5rem;
}

.close-icon {
	background: #e74c3c;
	border: none;
	color: white;
	width: 35px;
	height: 35px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	cursor: pointer;
	transition: transform 0.3s ease, box-shadow 0.3s ease;
	transform: scale(1);
}

.close-icon:hover {
	transform: scale(1.1);
	box-shadow: 0 6px 15px rgba(0, 0, 0, 0.2);
}

.close-icon i,
.close-icon svg,
.close-icon span {
	transition: transform 0.3s ease;
	transform: rotate(0deg);
}

.close-icon:hover i,
.close-icon:hover svg {
	transform: rotate(180deg);
}

.buttons-grid {
	display: grid;
	grid-template-columns: repeat(3, 1fr);
	gap: 15px;
	margin-bottom: 15px;
}

.action-row {
	display: flex;
	justify-content: flex-end;
	gap: 15px;
	padding-top: 15px;
	border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.panel-btn {
	background: rgba(255, 255, 255, 0.1);
	border: none;
	color: white;
	padding: 15px;
	border-radius: 12px;
	font-weight: 500;
	display: flex;
	align-items: center;
	gap: 12px;
	transition: all 0.3s ease;
	cursor: pointer;
	width: 100%;
	text-align: left;
	backdrop-filter: blur(5px);
	box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

.panel-btn:hover {
	background: var(--button-hover);
	transform: translateY(-3px);
	box-shadow: 0 7px 20px rgba(0, 0, 0, 0.2);
}

.panel-btn:active {
	transform: translateY(0);
}

.panel-btn i {
	font-size: 1.4rem;
	min-width: 30px;
}

.btn-icon {
	display: flex;
	align-items: center;
	justify-content: center;
	width: 40px;
	height: 40px;
	background: rgba(255, 255, 255, 0.15);
	border-radius: 10px;
	font-size: 1.2rem;
}

.btn-icon i {
	margin-left: 0.6ch;
	position: relative;
	top: 0.09em;
}

.color-picker {
	display: flex;
	align-items: center;
	gap: 15px;
	background: rgba(255, 255, 255, 0.1);
	padding: 10px 15px;
	border-radius: 12px;
	backdrop-filter: blur(5px);
	box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

.color-picker label {
	font-weight: 500;
	white-space: nowrap;
        color: white !important;
}

.color-picker input {
	width: 40px;
	height: 32px;
	border: none;
	background: transparent;
	cursor: pointer;
	padding: 0;
	border-radius: 8px;
	overflow: hidden;
}

.panel-close-btn {
	background: rgba(255, 255, 255, 0.1);
	border: none;
	color: white;
	padding: 10px 25px;
	border-radius: 12px;
	font-weight: 500;
	display: flex;
	align-items: center;
	gap: 10px;
	transition: all 0.3s ease;
	cursor: pointer;
	backdrop-filter: blur(5px);
	box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

.panel-close-btn:hover {
	background: rgba(231, 76, 60, 0.2);
	transform: translateY(-3px) scale(1.05);
	box-shadow: 0 7px 20px rgba(0, 0, 0, 0.2);
}

.language-container {
	display: flex;
	align-items: center;
	gap: 25px;
}

.flag-icon {
	width: 50px;
	height: 40px;
	border-radius: 3px;
	object-fit: cover;
}

@media (max-width: 992px) {
	.buttons-grid {
		grid-template-columns: repeat(2, 1fr);
	}
}

@media (max-width: 576px) {
	.buttons-grid {
		grid-template-columns: 1fr;
	}

	.action-row {
		flex-direction: column;
	}

	.color-picker {
		width: 100%;
		justify-content: space-between;
	}

	.panel-close-btn {
		width: 100%;
		justify-content: center;
	}
}

.flag-container {
	display: flex;
	align-items: center;
	gap: 10px;
}

.flag-icon {
	width: 30px;
	height: 20px;
	border-radius: 3px;
	object-fit: cover;
}

label[for="newPath"], label[for="permissions"], .form-text {
	color: white !important;
}

.container-bg {
	border-radius: 12px;
	box-shadow: var(--bs-shadow-medium);
	padding: 2rem;
	margin-top: 2rem;
	margin-bottom: 2rem;
}

#log-message {
	transition: opacity 0.5s ease;
}
@media (max-width: 767.98px) {
	#colorModal .modal-dialog,
            #colorPickerModal .modal-dialog {
		max-height: 95vh;
		margin: 1rem;
	}

	#colorModal .modal-content,
            #colorPickerModal .modal-content {
		max-height: 95vh;
		display: flex;
		flex-direction: column;
	}

	#colorModal .modal-body,
            #colorPickerModal .modal-body {
		overflow-y: auto;
		max-height: calc(90vh - 120px);
		padding: 15px;
	}

	#colorModal .row {
		flex-direction: column;
	}

	#colorModal .col-md-6 {
		width: 100%;
		margin-bottom: 15px;
	}

	#colorModal .card {
		margin-bottom: 10px;
	}

	#colorModal .mb-3 {
		margin-bottom: 12px !important;
	}

	#colorModal .form-label {
		font-size: 0.9rem;
		margin-bottom: 6px;
	}

	#colorModal .d-flex {
		gap: 8px;
	}

	#colorModal .gap-2 > button {
		width: 24px;
		height: 24px;
		padding: 0;
	}

	#colorPickerModal .modal-body > .row {
		flex-direction: column;
	}

	#colorPickerModal .col-md-6 {
		width: 100%;
		margin-bottom: 15px;
	}

	#colorPickerModal .form-label {
		font-size: 0.9rem;
		margin-bottom: 6px;
	}

	#colorPickerModal .mb-3 {
		margin-bottom: 12px !important;
	}

	#colorPickerModal #color-preview {
		height: 80px;
	}

	#colorPickerModal .d-flex {
		gap: 8px;
	}

	#colorPickerModal #current-color-block {
		height: 40px;
		font-size: 0.85rem;
	}

	#colorPickerModal #apply-color,
            #colorPickerModal #reset-color {
		height: 42px;
		display: flex;
		align-items: center;
		justify-content: center;
	}
}

html, body {
	overflow-y: scroll !important;
	scrollbar-width: none !important;
	-ms-overflow-style: none !important;
}

html::-webkit-scrollbar, body::-webkit-scrollbar {
	display: none !important;
	width: 0 !important;
	background: transparent !important;
}

.link-box a {
	color: var(--accent-color) !important;
}

h2#neko-title.neko-title-style {
	color: var(--accent-color) !important;
}

.table.custom-table thead th {
	color: var(--purple-text) !important;
}


.container-sm .row a {
	color: var(--accent-color) !important;
	text-decoration: none;
	transition: color 0.3s ease;
}

.container-sm .row a:hover {
	color: var(--purple-text) !important;
}

.container-sm .row a .bi {
	color: inherit;
}

.form-select option {
	background-color: var(--header-bg)  !important;
	color: var(--text-primary) !important;
}

.form-select {
	color: var(--accent-color) !important;
}

.form-select option:hover {
	background: var(--border-color) !important;
	color: var(--accent-color) !important;
}

.modal-footer {
	position: relative;
	height: 60px;
	flex-shrink: 0;
	border: none !important;
	box-shadow: none !important;
	background-color: var(--header-bg) !important;
	border-top: 1px solid var(--border-color) !important;
}

.container-bg,
.modal-content,
.table {
	--bg-l: oklch(30% 0 0);
	color: oklch(calc(100% - var(--bg-l)) 0 0) !important;
}

.container-bg {
	padding: 20px;
	border-radius: 10px;
	background: var(--bg-container);
	box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
}

.card {
	--card-padding: 1.25rem;
	--card-border-width: 1px;
	position: relative;
	display: flex;
	flex-direction: column;
	min-width: 0;
	background: var(--bg-container) !important;
	border: var(--border-strong);
	border-radius: var(--radius);
	box-shadow: 0 2px 8px color-mix(in oklch, var(--border-color), transparent 70%);
	transform: translateY(-2px);
	transition: var(--transition);
	overflow: hidden;
}

.card:hover {
	transform: translateY(-2px);
	box-shadow: 0 6px 16px color-mix(in oklch, var(--border-color), transparent 60%),
        0 0 0 1px var(--accent-color);
}

.card-header {
	padding: calc(var(--card-padding) * 0.8) var(--card-padding);
	background: var(--header-bg);
	border-bottom: var(--card-border-width) solid var(--border-color);
	font-weight: 600;
	color: var(--text-primary);
	display: flex;
	align-items: center;
	gap: 0.75rem;
}

.card-body {
	padding: var(--card-padding);
	flex: 1 1 auto;
	color: var(--text-primary);
	background: var(--bg-container);
}

.card-footer {
	padding: calc(var(--card-padding) * 0.8) var(--card-padding);
	background: var(--header-bg);
	border-top: var(--card-border-width) solid var(--border-color);
	display: flex;
	align-items: center;
	gap: 0.75rem;
}

.card-glass {
	background: color-mix(in oklch, var(--card-bg), transparent 15%);
	backdrop-filter: var(--glass-blur);
	border-color: color-mix(in oklch, var(--border-color), white 30%);
}

.card-elevated {
	--card-shadow-color: color-mix(in oklch, var(--border-color), black 30%);
	box-shadow: 0 3px 6px var(--card-shadow-color),
        0 8px 24px color-mix(in oklch, var(--card-shadow-color), transparent 70%);
}

.card-floating {
	position: relative;
	top: 0;
	transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.card-floating:hover {
	top: -4px;
	box-shadow: 0 12px 28px color-mix(in oklch, var(--border-color), transparent 60%),
        0 0 0 1px var(--accent-color);
}

.card-badge {
	position: absolute;
	top: -0.5rem;
	right: 1rem;
	background: var(--btn-danger-bg);
	color: var(--text-primary);
	padding: 0.25rem 0.75rem;
	border-radius: calc(var(--radius) * 2);
	font-size: 0.75rem;
	font-weight: bold;
	box-shadow: 0 2px 4px oklch(0% 0 0 / 0.2);
	z-index: 1;
}

@media (max-width: 768px) {
	.card {
		--card-padding: 1rem;
		border-radius: calc(var(--radius) * 0.8);
	}

	.card-elevated {
		box-shadow: 0 2px 4px color-mix(in oklch, var(--border-color), transparent 70%),
                0 4px 12px color-mix(in oklch, var(--border-color), transparent 80%);
	}
}

@media (prefers-color-scheme: dark) {
	.card {
		--card-shadow-color: oklch(0% 0 0 / 0.4);
	}

	.card-glass {
		background: color-mix(in oklch, var(--card-bg), transparent 20%);
		border-color: color-mix(in oklch, var(--border-color), black 30%);
	}
}

[data-theme="dark"] .container-sm .card {
	--glow-base: var(--base-hue);
	--glow-primary: oklch(82% 0.32 var(--glow-base));
	--glow-secondary: oklch(78% 0.28 calc(var(--glow-base) + 10));
	border: 1px solid color-mix(in oklch, var(--glow-primary), transparent 20%);
	box-shadow: 0 2px 8px 1px color-mix(in oklch, var(--glow-primary), transparent 40%),
        0 4px 24px 2px color-mix(in oklch, var(--glow-secondary), transparent 60%),
        inset 0 0 12px color-mix(in oklch, var(--glow-primary), transparent 70%);
	transform: translateY(-2px) !important;
	transition: all 0.25s ease-out;
	animation: breath 3s ease-in-out infinite;
}

[data-theme="dark"] .container-sm .card:hover {
	--glow-primary: oklch(88% 0.35 var(--glow-base));
	--glow-secondary: oklch(85% 0.3 calc(var(--glow-base) + 15));
	box-shadow: 0 4px 16px 2px color-mix(in oklch, var(--glow-primary), transparent 30%),
        0 8px 32px 4px color-mix(in oklch, var(--glow-secondary), transparent 50%),
        inset 0 0 24px color-mix(in oklch, var(--glow-primary), transparent 60%);
	transform: translateY(-4px) !important;
        /* animation-play-state: paused; */
}

@keyframes breath {
	0%, 100% {
		--glow-primary: oklch(82% 0.32 var(--glow-base));
		--glow-secondary: oklch(78% 0.28 calc(var(--glow-base) + 10));
		box-shadow: 0 2px 8px 1px color-mix(in oklch, var(--glow-primary), transparent 40%),
                0 4px 24px 2px color-mix(in oklch, var(--glow-secondary), transparent 60%),
                inset 0 0 12px color-mix(in oklch, var(--glow-primary), transparent 70%);
	}

	50% {
		--glow-primary: oklch(88% 0.35 var(--glow-base));
		--glow-secondary: oklch(85% 0.3 calc(var(--glow-base) + 15));
		box-shadow: 0 4px 16px 2px color-mix(in oklch, var(--glow-primary), transparent 30%),
                0 8px 32px 4px color-mix(in oklch, var(--glow-secondary), transparent 50%),
                inset 0 0 24px color-mix(in oklch, var(--glow-primary), transparent 60%);
	}
}

[data-theme="dark"] .neko-title-style {
	--glow-base: var(--base-hue);
	--glow-primary: oklch(92% 0.35 var(--glow-base));
	--glow-secondary: oklch(88% 0.3 calc(var(--glow-base) + 10));
	animation: nekoBreath 3s ease-in-out infinite;
	text-shadow: 1px 1px 0 color-mix(in oklch, var(--glow-primary), #999 50%),
        2px 2px 0 color-mix(in oklch, var(--glow-primary), #888 50%),
        3px 3px 0 color-mix(in oklch, var(--glow-primary), #777 50%),
        4px 4px 0 color-mix(in oklch, var(--glow-primary), #666 50%),
        0 0 10px color-mix(in oklch, var(--glow-primary), transparent 60%),
        0 0 20px color-mix(in oklch, var(--glow-secondary), transparent 70%) !important;
}

[data-theme="dark"] .neko-title-style:hover {
	--glow-primary: oklch(96% 0.38 var(--glow-base));
	--glow-secondary: oklch(92% 0.32 calc(var(--glow-base) + 15));
	text-shadow: 1px 1px 1px color-mix(in oklch, var(--glow-primary), #999 50%),
        2px 2px 1px color-mix(in oklch, var(--glow-primary), #888 50%),
        3px 3px 2px color-mix(in oklch, var(--glow-primary), #777 50%),
        4px 4px 2px color-mix(in oklch, var(--glow-primary), #666 50%),
        0 0 15px color-mix(in oklch, var(--glow-primary), transparent 50%),
        0 0 30px color-mix(in oklch, var(--glow-secondary), transparent 60%) !important;
}

@keyframes nekoBreath {
	0%, 100% {
		--glow-primary: oklch(88% 0.32 var(--glow-base));
		text-shadow: 1px 1px 0 color-mix(in oklch, var(--glow-primary), #999 50%),
                2px 2px 0 color-mix(in oklch, var(--glow-primary), #888 50%),
                3px 3px 0 color-mix(in oklch, var(--glow-primary), #777 50%),
                4px 4px 0 color-mix(in oklch, var(--glow-primary), #666 50%),
                0 0 8px color-mix(in oklch, var(--glow-primary), transparent 70%),
                0 0 15px color-mix(in oklch, var(--glow-secondary), transparent 80%);
	}

	50% {
		--glow-primary: oklch(96% 0.38 var(--glow-base));
		text-shadow: 1px 1px 0 color-mix(in oklch, var(--glow-primary), #999 50%),
                2px 2px 0 color-mix(in oklch, var(--glow-primary), #888 50%),
                3px 3px 0 color-mix(in oklch, var(--glow-primary), #777 50%),
                4px 4px 0 color-mix(in oklch, var(--glow-primary), #666 50%),
                0 0 15px color-mix(in oklch, var(--glow-primary), transparent 50%),
                0 0 30px color-mix(in oklch, var(--glow-secondary), transparent 60%);
	}
}

.footer-text {
	color: var(--accent-color) !important;
	font-weight: 700;
}

.footer-text b {
	font-weight: 800;
	letter-spacing: 0.5px;
}

.log-content-container {
	border: var(--border-strong);
	border-radius: var(--radius);
	margin-bottom: 0.5rem;
	overflow: hidden;
	box-shadow: var(--item-hover-shadow);
	transition: var(--transition);
}

.log-actions {
	padding: 0.5rem 0;
	background: none !important;
	border-radius: 0 !important;
	border: none !important;
	display: flex;
	justify-content: center;
}

.log-actions.multiple-actions {
	padding: 0.5rem;
	background: none !important;
	border-radius: 0 !important;
	border: none !important;
	justify-content: center;
}

.log-action-group {
	display: flex;
	align-items: center;
	gap: 0.5rem;
	flex-wrap: wrap;
	width: auto;
	background: none !important;
	border-radius: 0 !important;
	border: none !important;
}

.log-content-container:hover {
	border-color: var(--accent-color);
	box-shadow: 0 4px 16px color-mix(in oklch, var(--accent-color), transparent 85%);
}

.log-content-area {
	display: block;
	width: 100%;
	height: 330px;
	margin-top: 15px;
	margin-left: 15px;
	padding: 0.75rem;
	margin: 0;
	font-family: Consolas, "Courier New", monospace;
	font-size: 0.875rem;
	line-height: 1.5;
	color: var(--text-primary);
	background: var(--bg-container);
	border: 0;
	border-radius: 0;
	resize: vertical;
	white-space: pre-wrap;
	overflow: auto;
	box-shadow: inset 0 1px 3px oklch(0% 0 0 / 0.1);
	transition: var(--transition);
}

.log-content-area:focus {
	outline: none;
	box-shadow: inset 0 1px 3px oklch(0% 0 0 / 0.15),
        0 0 0 2px var(--accent-color);
}

.btn-clear-log {
	color: #fff;
	background: var(--btn-danger-bg);
	border: var(--border-strong);
	padding: 0.375rem 0.75rem;
	font-size: 0.875rem;
	border-radius: calc(var(--radius) / 2);
	transition: var(--transition);
}

.btn-clear-log:hover {
	color: #fff;
	background: color-mix(in oklch, var(--btn-danger-bg), black 10%);
	transform: translateY(-1px);
}

.btn-schedule {
	color: #fff;
	background: var(--btn-primary-bg);
	border: var(--border-strong);
	padding: 0.375rem 0.75rem;
	font-size: 0.875rem;
	border-radius: calc(var(--radius) / 2);
	transition: var(--transition);
}

.btn-schedule:hover {
	color: #fff;
	background: var(--btn-primary-hover);
	box-shadow: 0 2px 8px color-mix(in oklch, var(--accent-color), transparent 80%);
}

.form-check {
	margin-bottom: 0;
	display: flex;
	align-items: center;
	gap: 0.5rem;
}

.form-check-input {
	width: 1.1em;
	height: 1.1em;
	margin: 0;
	background-color: var(--bg-container);
	border: var(--border-strong);
	appearance: none;
	-webkit-appearance: none;
	transition: var(--transition);
}

.form-check-input:checked {
	background-color: var(--accent-color);
	border-color: var(--accent-color);
	background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 20 20'%3e%3cpath fill='none' stroke='%23fff' stroke-linecap='round' stroke-linejoin='round' stroke-width='3' d='M6 10l3 3l6-6'/%3e%3c/svg%3e");
}

.form-check-label {
	color: var(--text-secondary);
	font-size: 0.875rem;
	cursor: pointer;
}

@media (max-width: 768px) {
	.log-content-container {
		border-radius: calc(var(--radius) * 0.8);
	}

	.log-action-group {
		flex-direction: column;
		align-items: stretch;
		gap: 0.5rem;
	}

	.btn-clear-log,
        .btn-schedule {
		width: 100%;
		justify-content: center;
	}

	.form-check {
		justify-content: center;
	}
}

@media (prefers-color-scheme: dark) {
	.log-content-area {
		box-shadow: inset 0 1px 3px oklch(0% 0 0 / 0.3);
	}

	.form-check-input {
		background-color: var(--bg-body);
	}
}

.table {
	--bs-table-bg: var(--card-bg);
	--bs-table-color: var(--text-primary);
	--bs-table-border-color: var(--border-color);
	--bs-table-striped-bg: rgba(0, 0, 0, 0.05);
}

.img-thumbnail {
	background: var(--bg-container);
	border: var(--border-strong);
}

#toggleButton {
	background-color: var(--sand-bg);
}

.modal-content {
	background: var(--bg-container);
	border: var(--border-strong);
}

.modal-header {
	background: var(--header-bg);
	border-bottom: 1px solid var(--border-color);
}

.modal-title {
	color: var(--accent-color) !important;
}

.modal-body {
	background: var(--card-bg);
	color: var(--text-primary);
}

label {
	color: var(--text-primary) !important;
}

.btn-primary,
.btn-success,
.btn-info,
.btn-warning,
.btn btn-danger,
.btn-pink {
	color: white !important;
}

.container-bg {
	border-radius: 12px !important;
	margin-top: 1rem !important;
}

.neko-title-style {
	font-family: 'Cinzel Decorative', cursive;
	font-weight: 900;
	font-size: 80px;
	letter-spacing: 4px;
	text-align: center;
	margin-top: 20px;
	transition: all var(--bs-transition-speed);
	color: #fff;
	text-shadow:
		1px 1px 0 #999,
		2px 2px 0 #888,
		3px 3px 0 #777,
		4px 4px 0 #666,
		5px 5px 10px rgba(0,0,0,0.3);
	transform-style: preserve-3d;
	perspective: 1000px;
}

.neko-title-style:hover {
	transform: rotateX(5deg) rotateY(-5deg) skew(-5deg);
	text-shadow:
		1px 1px 1px #999,
		2px 2px 1px #888,
		3px 3px 2px #777,
		4px 4px 2px #666,
		5px 5px 10px rgba(0,0,0,0.4);
}

.form-select {
	background-color: var(--card-bg) !important;
}

.form-control {
	background-color: var(--card-bg) !important;
	color: var(--text-primary) !important;
}

.form-control:focus {
	background-color: var(--card-bg) !important;
	border-color: #4eedf9 !important;
	box-shadow: none !important;
}

 table td,.alert.alert-info {
	background-color: var(--card-bg) !important;
        border: var(--border-strong) !important;
}

.form-control::placeholder {
	color: var(--text-primary) !important;
	opacity: 1;
}

.form-label, legend.form-label {
        font-size: 1rem !important;
        font-weight: 500 !important;
        line-height: 1.5 !important;
}

#customTemplateUrl {
        display: none;
}

input[type="text"] {
	background-color: var(--header-bg);
	color: var(--text-primary);
	border: var(--border-strong);
}

#color-input {
	background: transparent !important;
	border: none !important;
	color: white !important;
	font-size: 0.9rem !important;
	width: 100% !important;
	text-align: center !important;
	padding: 0 !important;
	margin: 0 !important;
	box-shadow: none !important;
	outline: none !important;
}

.input-wrapper {
	position: relative;
	display: inline-block;
	width: 100%;
}

.fake-cursor {
	position: absolute;
	top: 50%;
	left: 50%;
	transform: translate(calc(-50% + 3.7ch), -50%);
	color: white;
	animation: blinkCursor 1s step-start infinite;
	pointer-events: none;
	font-size: 0.9rem;
	font-weight: normal;
}

@keyframes blinkCursor {
	50% {
		opacity: 0;
	}
}

footer {
	margin-top: 10px !important;
	padding: 8px 0;
	color: var(--btn-primary-bg);
	font-size: 1.1rem;
	font-weight: 500;
}

footer p {
	margin: 0;
}

h1 {
	color: oklch(var(--l) var(--c) var(--base-hue)) !important;
	font-weight: 900;
}

h2 ,h3, h4 ,h5, h6 {
        color: var(--accent-color) !important;
        font-weight: bold;
}

h1:hover, h2:hover {
	opacity: 0.9;
	transform: translateY(-1px);
}

a.link-primary:hover {
        color: var(--ocean-bg) !important;
}

a.link-primary:hover svg,
a.link-primary:hover svg path {
        stroke: var(--ocean-bg) !important;
        fill: var(--ocean-bg) !important;
}

.row > a.btn,
.row > a.btn i,
.row > a.btn span {
	transition: color 0.3s ease;
}

.row > a.btn:hover,
.row > a.btn:hover i,
.row > a.btn:hover span {
	color: var(--ocean-bg) !important;
}

.triangle-icon {
	border-top: 12px solid var(--accent-color) !important;
}

table {
	border-collapse: separate;
	border-spacing: 0;
	width: 100%;
}

thead.table-light th {
	font-weight: 600;
	padding: 0.85rem 1.25rem;
	border: none !important;
	background: var(--accent-color) !important;
	color: #fff !important;
	text-align: left;
	font-size: 0.925rem;
	transition: all 0.2s ease;
}

thead.table-light th:hover {
	background: color-mix(in oklch, var(--accent-color), black 10%) !important;
}

thead.table-light tr:first-child th:first-child {
	border-top-left-radius: var(--radius) !important;
}

thead.table-light tr:first-child th:last-child {
	border-top-right-radius: var(--radius) !important;
}

thead.table-light th:not(:last-child)::after {
	content: none;
}

.btn-primary,
.btn-primary svg,
.btn-primary svg * {
	color: white !important;
	stroke: white !important;
}

@media (max-width: 768px) {
	h1 {
		font-size: 1.8rem;
	}

	h2 {
		font-size: 1.5rem;
	}
}

.alert,
.alert.alert-info ul,
.alert.alert-info ul li {
	color: var(--text-primary) !important;
}

button.btn,
a.btn,
input.btn {
	transition: transform 0.2s ease !important;
}

button.btn:hover,
a.btn:hover,
input.btn:hover,
button.btn:focus,
a.btn:focus,
input.btn:focus {
	transform: scale(1.05) !important;
}

#logTabs .nav-link:hover {
	color: var(--ocean-bg) !important;
}

svg.feather {
        width: 20px !important;
        height: 20px !important;
        vertical-align: middle !important;
        margin-right: 5px !important;
        stroke: var(--btn-primary-bg) !important;
        fill: none !important;
}

svg.feather:hover,
.custom-icon:hover {
        color: var(--btn-primary-bg); 
}

.custom-icon {
        color: var(--accent-color);   
        font-size: 18px;           
        vertical-align: middle;
        margin-right: 5px;
        transition: color 0.25s ease;
}

* {
	scrollbar-width: thin;
	scrollbar-color: var(--accent-color) var(--header-bg);
}

*::-webkit-scrollbar {
	width: 6px;
	height: 6px;

	background: transparent;
}

*::-webkit-scrollbar-track {
	background: var(--header-bg);
	border-radius: 3px;
	margin: 4px 0;
}

*::-webkit-scrollbar-thumb {
	background: var(--accent-color);
	border-radius: 3px;
	transition: background 0.3s ease;
	min-height: 40px;
	min-width: 40px;
}

*::-webkit-scrollbar-thumb:hover {
	background: color-mix(in oklch, var(--accent-color), white 20%);
}

body {
        color: var(--text-primary);
        -webkit-backdrop-filter: blur(10px);
        transition: all 0.3s ease;
        font-family: 'Fredoka One', cursive;
        font-weight: 400; 
        background: oklch(var(--bg-l) var(--base-chroma) var(--base-hue));
}

body.default-font {
        font-family: system-ui, sans-serif;
        font-weight: 400;
}

body.system-nofo-font {
        font-family: 'Noto Serif SC';
        font-weight: 400;
}

body.system-mono-font {
        font-family: 'Comic Neue';
        font-weight: 400;
}

body.dm-serif-font {
	font-family: 'DM Serif Display';
	font-weight: 400;
}

body.cinzel-font {
        font-family: 'Cinzel Decorative';
        font-weight: 700;
}

body.noto-sans-font {
        font-family: 'Noto Sans';
        font-weight: 400;
}

body.font-transition {
        animation: fontFade 0.4s ease-in-out;
}

@keyframes fontFade {
        0% {
          opacity: 0.3;
          transform: scale(0.98);
        }
        100% {
          opacity: 1;
          transform: scale(1);
        }
}

.modal-backdrop {
	background: oklch(0 0 0 / 0.4);
}

.color-preset {
	transition: transform 0.2s ease;
}

.color-preset:hover {
	transform: scale(1.1);
}

#color-input {
	font-weight: 700 !important;
	color: white !important;
}

@supports (color: oklch(1 0 0)) {
	#color-input {
		color: oklch(0.95 0 0) !important;
	}
}

input,
textarea,
select,
button {
        font-family: inherit !important;
}

input[type=range] {
	-webkit-appearance: none;
	width: 100%;
	height: 8px;
	border-radius: 5px;
	background: var(--accent-color) !important;
	outline: none;
	transition: background 0.3s ease;
}

input[type=range]:hover {
	background: linear-gradient(
        to right,
        var(--btn-primary-bg),
        var(--accent-color)
    ) !important;
}

input[type=range]::-webkit-slider-thumb {
	-webkit-appearance: none;
	appearance: none;
	width: 18px;
	height: 18px;
	border-radius: 50%;
	background: #ffffff !important;
	border: var(--border-strong) !important;
	cursor: pointer;
	transition: background 0.3s ease, transform 0.2s ease, border-color 0.3s ease;
}

input[type=range]::-webkit-slider-thumb:hover {
	background: #f0f0f0 !important;
	transform: scale(1.2);
}

input[type=range]::-moz-range-thumb {
	width: 18px;
	height: 18px;
	border-radius: 50%;
	background: #ffffff !important;
	border: 2px solid var(--accent-color) !important;
	cursor: pointer;
	transition: background 0.3s ease, transform 0.2s ease, border-color 0.3s ease;
}

input[type=range]::-moz-range-thumb:hover {
	background: #f0f0f0 !important;
	transform: scale(1.2);
}

input[type=range]::-ms-thumb {
	width: 18px;
	height: 18px;
	border-radius: 50%;
	background: #ffffff !important;
	border: 2px solid var(--accent-color) !important;
	cursor: pointer;
	transition: background 0.3s ease, transform 0.2s ease, border-color 0.3s ease;
}

.panel-header h3,
.panel-header button.close-icon,
.panel-header button.close-icon i {
	color: var(--accent-color) !important;
}

#modalWidthValue,
#widthValue {
	color: var(--text-primary) !important;
}

.btn {
	border: none;
	border-radius: var(--radius);
	transition: var(--transition);
	font-weight: 500;
	position: relative;
	overflow: visible;
}

.btn-primary {
	background: var(--btn-primary-bg);
	color: var(--text-primary);
}

.btn-primary:hover {
	background: var(--btn-primary-hover);
	box-shadow: var(--item-hover-shadow);
}

.btn-success {
	background: var(--btn-success-bg);
	color: var(--success-text);
}

.btn-success:hover {
	background: color-mix(in oklch, var(--btn-success-bg), white 10%);
	box-shadow: var(--item-hover-shadow);
}

.btn-info {
	background: var(--btn-info-bg);
	color: var(--info-text);
}

.btn-info:hover {
	background: color-mix(in oklch, var(--btn-info-bg), white 10%);
	box-shadow: var(--item-hover-shadow);
}

.btn-danger {
	background: oklch(55% 0.25 25);
	color: oklch(95% 0.05 25);
}

.btn-danger:hover {
	background: oklch(60% 0.25 25);
}

.btn-warning {
	background: oklch(75% 0.22 80);
	color: oklch(25% 0.05 80);
}

.btn-warning:hover {
	background: oklch(80% 0.22 80);
}

[data-theme="light"] {
	--danger-text: oklch(95% 0.05 25);
	--warning-text: oklch(20% 0.15 80);
	.btn-danger {
    background: oklch(60% 0.3 25);
	color: var(--danger-text);
}

.btn-warning {
	background: oklch(85% 0.25 80);
	color: var(--warning-text);
}
}

.btn-outline-primary {
	border: 1px solid var(--btn-primary-bg);
	color: var(--btn-primary-bg);
	background: transparent;
}

.btn-outline-primary:hover {
	background: var(--btn-primary-bg);
	color: var(--text-primary);
}

.btn-sm {
	padding: 0.25rem 0.5rem;
	font-size: 0.875rem;
}

.btn-lg {
	padding: 0.5rem 1rem;
	font-size: 1.25rem;
}

.ace_search {
	background: var(--bg-container) !important;
	border: var(--border-strong) !important;
	border-radius: var(--radius);
	box-shadow: var(--item-hover-shadow);
	padding: 8px 12px !important;
	color: var(--text-primary);
	backdrop-filter: var(--glass-blur);
	transition: var(--transition);
}

.ace_search_form, .ace_replace_form {
	display: flex;
	align-items: center;
	gap: 8px;
	margin-bottom: 8px;
}

.ace_search_field {
	background: var(--card-bg) !important;
	border: var(--border-strong) !important;
	color: var(--text-primary) !important;
	padding: 6px 12px !important;
	border-radius: calc(var(--radius) - 4px) !important;
	font-size: 14px !important;
	min-width: 200px;
	transition: var(--transition);
}

.ace_search_field:focus {
	border-color: var(--accent-color) !important;
	outline: none;
	box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent-color), transparent 70%);
}

.ace_searchbtn {
	background: var(--btn-primary-bg) !important;
	color: white !important;
	border: none !important;
	border-radius: calc(var(--radius) - 4px) !important;
	background-image: none !important;
	padding: 6px 12px !important;
	font-size: 13px !important;
	cursor: pointer;
	transition: var(--transition);
	display: inline-flex;
	align-items: center;
	justify-content: center;
	min-width: 60px;
	filter: contrast(1.2) brightness(1.1);
}

.ace_searchbtn:hover {
	background: var(--btn-primary-hover) !important;
	color: white !important;
}

.ace_searchbtn.prev,
.ace_searchbtn.next {
	position: relative;
}

.ace_searchbtn.prev::before,
.ace_searchbtn.next::before {
	content: "";
	font-size: 14px;
	color: white !important;
	filter: contrast(1.3);
	display: inline-block;
	line-height: 1;
}

.ace_searchbtn.prev::before {
	content: "↑";
}

.ace_searchbtn.next::before {
	content: "↓";
}

.ace_searchbtn .ace_icon,
.ace_searchbtn::after {
	display: none !important;
	opacity: 0 !important;
}

.ace_searchbtn_close {
	background: transparent !important;
	color: var(--text-secondary) !important;
	position: absolute;
	right: 12px;
	top: 12px;
	cursor: pointer;
	font-size: 16px;
	transition: var(--transition);
	width: 20px;
	height: 20px;
	display: flex;
	align-items: center;
	justify-content: center;
	border-radius: 3px;
}

.ace_searchbtn_close:hover {
	color: white !important;
	background: var(--btn-primary-bg) !important;
}

.ace_searchbtn_close::before {
	content: "×";
}

.ace_search_options {
	display: flex;
	align-items: center;
	gap: 8px;
	margin-top: 8px;
}

.ace_button {
	background: var(--btn-primary-bg) !important;
	color: white !important;
	border: none !important;
	border-radius: calc(var(--radius) - 4px) !important;
	padding: 4px 8px !important;
	font-size: 12px !important;
	cursor: pointer;
	transition: var(--transition);
	filter: contrast(1.2);
}

.ace_button:hover {
	background: var(--btn-primary-hover) !important;
	color: white !important;
}

.ace_search_counter {
	color: var(--text-secondary);
	font-size: 12px;
	margin-right: auto;
}

[action="toggleRegexpMode"] {
	background: var(--btn-info-bg) !important;
	color: white !important;
}
[action="toggleCaseSensitive"] {
	background: var(--btn-warning-bg) !important;
	color: white !important;
}
[action="toggleWholeWords"] {
	background: var(--btn-success-bg) !important;
	color: white !important;
}
[action="searchInSelection"] {
	background: var(--ocean-bg) !important;
	color: white !important;
}
[action="toggleReplace"] {
	background: var(--lavender-bg) !important;
	color: white !important;
}

#editorStatus {
	font-weight: bold !important;
	font-size: 0.9rem !important;
	color: var(--text-secondary) !important;
}

#editorStatus #lineColumnDisplay,
#editorStatus #charCountDisplay {
	font-size: 1.1rem !important;
	color: var(--info-text) !important;
	transition: var(--transition) !important;
}

#editorStatus:hover #lineColumnDisplay,
#editorStatus:hover #charCountDisplay {
	color: var(--accent-color) !important;
}

[data-theme="light"] #editorStatus #lineColumnDisplay,
[data-theme="light"] #editorStatus #charCountDisplay {
	color: var(--info-text) !important;
}

.btn-close {
	width: 15px !important;
	height: 15px !important;
	background-color: #30e8dc !important;
	border-radius: 6px !important;
	border: none !important;
	position: relative !important;
	display: flex !important;
	align-items: center !important;
	justify-content: center !important;
	cursor: pointer !important;
	transition: background-color 0.2s ease, transform 0.2s ease !important;
}

.btn-close::before, 
.btn-close::after {
	content: '' !important;
	position: absolute !important;
	width: 12px !important;
	height: 2px !important;
	background-color: #ff4d4f !important;
	border-radius: 2px !important;
	transition: background-color 0.2s ease !important;
}

.btn-close::before {
	transform: rotate(45deg) !important;
}

.btn-close::after {
	transform: rotate(-45deg) !important;
}

.btn-close:hover {
	background-color: #30e8dc !important;
	transform: scale(1.1) !important;
}

.btn-close:hover::before, 
.btn-close:hover::after {
	background-color: #d9363e !important;
}

.btn-close:active {
	transform: scale(0.9) !important;
}

@media (max-width: 768px) {
	.control-panel {
		display: flex;
		flex-direction: column;
		max-height: 100vh;
	}

	.buttons-grid {
		overflow-y: auto;
		flex-grow: 1;
		padding-right: 8px;
		-webkit-overflow-scrolling: touch;
	}
}

@media (max-width: 768px) {
	#toggle-ip {
		display: none !important;
	}
}

.scrollable-container:hover {
	overflow: auto;
}

:root {
	--container-width: 2350px;
	--modal-max-width: 1100px;
}

.container-sm {
	width: var(--container-width) !important;
	max-width: 100%;
	margin: 0 auto;
}

.modal-xl {
	max-width: var(--modal-max-width) !important;
	margin: 0 auto;
}

@media (max-width: 768px) {
	.modal-xl {
		max-width: 100%;
	}
}

[data-theme="dark"] {
	--glow-base: var(--base-hue);
	--glow-primary: oklch(88% 0.35 var(--glow-base));
	--glow-secondary: oklch(85% 0.3 calc(var(--glow-base) + 15));
}

[data-theme="dark"] .form-select,
[data-theme="dark"] .form-control:disabled,
[data-theme="dark"] input[type="text"] {
	border: 1px solid color-mix(in oklch, var(--glow-primary), transparent 30%);
	box-shadow: 0 0 8px 1px color-mix(in oklch, var(--glow-primary), transparent 60%),
              inset 0 -4px 12px color-mix(in oklch, var(--glow-primary), transparent 80%);
	transition: box-shadow 0.3s ease;
}

[data-theme="dark"] .form-select:hover,
[data-theme="dark"] .form-select:focus,
[data-theme="dark"] input[type="text"]:hover,
[data-theme="dark"] input[type="text"]:focus {
	box-shadow: 0 0 12px 2px color-mix(in oklch, var(--glow-primary), transparent 40%),
              inset 0 -6px 16px color-mix(in oklch, var(--glow-primary), transparent 70%);
}

[data-theme="dark"] .form-control:disabled {
	opacity: 0.7;
	box-shadow: 0 0 4px 0 color-mix(in oklch, var(--glow-primary), transparent 70%),
              inset 0 -2px 8px color-mix(in oklch, var(--glow-primary), transparent 90%);
}

[data-theme="dark"] .form-check-input[type="checkbox"] {
	border: 1px solid color-mix(in oklch, var(--glow-primary), transparent 50%);
	background-color: color-mix(in oklch, var(--bg-body), transparent 20%);
	box-shadow: 0 0 6px color-mix(in oklch, var(--glow-primary), transparent 70%);
	transition: all 0.3s ease;
}

[data-theme="dark"] .form-check-input:checked[type="checkbox"] {
	background-color: var(--glow-primary);
	border-color: var(--glow-primary);
	box-shadow: 0 0 8px var(--glow-primary),
        inset 0 0 4px white;
}

[data-theme="dark"] .form-check-input[type="radio"] {
	border: 1px solid color-mix(in oklch, var(--glow-primary), transparent 50%);
	background-color: color-mix(in oklch, var(--bg-body), transparent 20%);
	box-shadow: 0 0 6px color-mix(in oklch, var(--glow-primary), transparent 70%);
	transition: all 0.3s ease;
}

[data-theme="dark"] .form-check-input:checked[type="radio"] {
	background-color: var(--glow-primary);
	border-color: var(--glow-primary);
	box-shadow: 0 0 8px var(--glow-primary),
        inset 0 0 6px color-mix(in oklch, white, transparent 60%);
}

[data-theme="dark"] .form-check-input:hover {
	box-shadow: 0 0 10px color-mix(in oklch, var(--glow-primary), transparent 50%);
}

[data-theme="dark"] .form-check-input:disabled {
	opacity: 0.5;
	box-shadow: 0 0 4px color-mix(in oklch, var(--glow-primary), transparent 80%);
}

[data-theme="dark"] table a svg {
	filter: drop-shadow(0 0 2px color-mix(in oklch, var(--glow-primary), transparent 30%));
	transition: filter 0.3s ease;
}

[data-theme="dark"] table a:hover svg {
	filter: drop-shadow(0 0 6px var(--glow-primary));
}

[data-theme="dark"] #dynamicTitle,h2,h3,h4,h5,h6 {
	position: relative;
	color: color-mix(in oklch, var(--glow-primary), white 20%);
	text-shadow: 0 0 5px color-mix(in oklch, var(--glow-primary), transparent 40%),
        0 0 15px color-mix(in oklch, var(--glow-primary), transparent 70%);
	animation: text-glow-pulse 3s ease-in-out infinite alternate;
}

@keyframes text-glow-pulse {
	0% {
		text-shadow: 0 0 5px color-mix(in oklch, var(--glow-primary), transparent 40%),
      0 0 15px color-mix(in oklch, var(--glow-primary), transparent 70%);
	}

	100% {
		text-shadow: 0 0 10px color-mix(in oklch, var(--glow-primary), transparent 30%),
      0 0 25px color-mix(in oklch, var(--glow-primary), transparent 60%);
	}
}

.rounded-3.border {
	border: var(--border-strong) !important;
}
</style>