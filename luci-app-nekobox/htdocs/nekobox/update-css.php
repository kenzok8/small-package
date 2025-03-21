<?php
$data = json_decode(file_get_contents('php://input'), true);

$width = isset($data['width']) ? $data['width'] : null;
$modalWidth = isset($data['modalWidth']) ? $data['modalWidth'] : null;
$applyGroup1 = isset($data['group1']) && $data['group1'] == 1;
$applyBodyBackground = isset($data['bodyBackground']) && $data['bodyBackground'] == 1;
$applyOpenWrtTheme = isset($data['openwrtTheme']) && $data['openwrtTheme'] == 1;

if ($width !== null && $modalWidth !== null) {
    $cssFilePath = 'ping.php';

    if (file_exists($cssFilePath)) {
        $cssContent = file_get_contents($cssFilePath);

        $cssContent = preg_replace('/\/\* START .container-sm \*\/.*?\/\* END .container-sm \*\//s', '', $cssContent);
        $cssContent = preg_replace('/\/\* START .modal-xl \*\/.*?\/\* END .modal-xl \*\//s', '', $cssContent);

        $containerCss = "
/* START .container-sm */
.container-sm {
    width: ${width}px !important; 
    max-width: 100%;
    margin: 0 auto;
}
/* END .container-sm */

/* START .modal-xl */
.modal-xl {
    max-width: ${modalWidth}px !important; 
}

@media (max-width: 768px) {
    .modal-xl {
        max-width: 100%;
    }
}
/* END .modal-xl */
";

        $position = strpos($cssContent, '.scrollable-container:hover {');
        if ($position !== false) {
            $scrollableCssEnd = strpos($cssContent, '}', $position);
            $newCssContent = substr($cssContent, 0, $scrollableCssEnd + 1) . "\n" . $containerCss . substr($cssContent, $scrollableCssEnd + 1);
            file_put_contents($cssFilePath, $newCssContent);
            echo json_encode(['status' => 'success', 'message' => 'CSS updated successfully']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Could not find .scrollable-container:hover style']);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'CSS file not found']);
    }
} 

if ($applyGroup1 || $applyBodyBackground) {
    $cssFilePath = 'assets/theme/transparent.css';

    if (file_exists($cssFilePath)) {
        $cssContent = file_get_contents($cssFilePath);

        if ($applyGroup1) {
            $cssContent = preg_replace('/(--bs-disabled-bg:)[^;]+;/', '$1 transparent;', $cssContent);
            $cssContent = preg_replace('/(--bs-form-select:)[^;]+;/', '$1 transparent;', $cssContent);
            $cssContent = preg_replace('/(--bs-info-bg-subtle:)[^;]+;/', '$1 transparent;', $cssContent);
        }

        if ($applyBodyBackground) {
            $cssContent = preg_replace('/(--bs-body-bg:)[^;]+;/', '$1 transparent;', $cssContent);
        }

        file_put_contents($cssFilePath, $cssContent);

        echo json_encode(['status' => 'success', 'message' => 'Transparent background applied']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'CSS file not found']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Transparent background not enabled']);
}

$pingFilePath = 'ping.php';
if (file_exists($pingFilePath)) {
    $pingContent = file_get_contents($pingFilePath);

    if ($applyOpenWrtTheme) {
        $additionalContent = '
            <!-- START OpenWRT Theme -->
            <link rel="stylesheet" href="/luci-static/spectra/css/dark.css">
            <script src="/luci-static/spectra/js/custom.js"></script>
            <!-- END OpenWRT Theme -->
        ';
        
        if (strpos($pingContent, '<!-- START OpenWRT Theme -->') === false) {
            $pingContent .= $additionalContent; 
            file_put_contents($pingFilePath, $pingContent);
            echo json_encode(['status' => 'success', 'message' => 'OpenWRT theme enabled']);
        } else {
            echo json_encode(['status' => 'info', 'message' => 'OpenWRT theme already enabled']);
        }
    } else {
        $pingContent = preg_replace('/<!-- START OpenWRT Theme -->.*?<!-- END OpenWRT Theme -->/s', '', $pingContent);
        file_put_contents($pingFilePath, $pingContent);
        echo json_encode(['status' => 'success', 'message' => 'OpenWRT theme disabled']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'ping.php not found']);
}
?>