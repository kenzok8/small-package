// JS 逻辑可在此扩展

// 日志查询示例
function fetchLogs(params, cb) {
    let url = L.env.cgiBase + "/admin/network/wifi-ap/api/log";
    url += "?" + Object.keys(params).map(k => k + "=" + encodeURIComponent(params[k])).join("&");
    fetch(url).then(r => r.json()).then(cb);
}

// 趋势数据查询示例
function fetchTrend(metric, start, end, cb) {
    let url = L.env.cgiBase + "/admin/network/wifi-ap/api/trend_data";
    let params = {metric: metric, start_time: start, end_time: end};
    fetch(url, {method: "POST", body: new URLSearchParams(params)})
        .then(r => r.json()).then(cb);
}

// 配置热加载按钮
function reloadConfig() {
    fetch(L.env.cgiBase + "/admin/network/wifi-ap/api/reload_config")
        .then(r => r.json()).then(res => alert(res.msg || "配置已热加载"));
}

// 渲染设备表格
function renderApTable(devices) {
    const tbody = document.querySelector("#ap-table tbody");
    tbody.innerHTML = "";
    (devices || []).forEach(dev => {
        let tr = document.createElement("tr");
        tr.innerHTML = `
          <td><input type="checkbox" class="ap-select" value="${dev.mac}"></td>
          <td>${dev.mac}</td>
          <td>${dev.ip}</td>
          <td>${dev.vendor}</td>
          <td>${dev.model}</td>
          <td>${dev.firmware}</td>
          <td><span style="background:${dev.status=='online'?'#67c23a':'#dcdfe6'};color:${dev.status=='online'?'#fff':'#888'};padding:2px 8px;border-radius:8px;">${dev.status}</span></td>
          <td><progress value="${dev.cpu}" max="100"></progress> ${dev.cpu}%</td>
          <td><progress value="${dev.mem}" max="100"></progress> ${dev.mem}%</td>
          <td>${dev.clients_24g}</td>
          <td>${dev.clients_5g}</td>
          <td>${dev.signal}</td>
          <td>${dev.uptime}</td>
          <td>
            <button class="ap-reboot" data-mac="${dev.mac}">重启</button>
            <button class="ap-upgrade" data-mac="${dev.mac}">升级</button>
            <button class="ap-sync" data-mac="${dev.mac}">同步</button>
          </td>
        `;
        tbody.appendChild(tr);
    });
    // 单台命令事件
    tbody.querySelectorAll(".ap-reboot").forEach(btn => {
        btn.onclick = () => sendApCmd(btn.dataset.mac, "reboot");
    });
    tbody.querySelectorAll(".ap-upgrade").forEach(btn => {
        btn.onclick = () => sendApCmd(btn.dataset.mac, "upgrade");
    });
    tbody.querySelectorAll(".ap-sync").forEach(btn => {
        btn.onclick = () => sendApCmd(btn.dataset.mac, "reload_config");
    });
}

// 获取设备列表
function fetchApList() {
    fetch("/cgi-bin/luci/admin/network/wifi-ap/api/status")
        .then(r => r.json())
        .then(res => {
            let devs = [];
            if (res.data) devs = [res.data];
            renderApTable(devs);
        });
}

// 发送单台命令
function sendApCmd(mac, action) {
    fetch("/cgi-bin/luci/admin/network/wifi-ap/api/device", {
        method: "POST",
        body: new URLSearchParams({mac, action})
    }).then(r => r.json()).then(res => alert(res.msg || JSON.stringify(res)));
}

// 获取选中MAC
function getSelectedMacs() {
    return Array.from(document.querySelectorAll(".ap-select:checked")).map(cb => cb.value);
}

// 批量操作
function batchCmd(action) {
    let macs = getSelectedMacs();
    if (!macs.length) return alert("请选择设备");
    fetch("/cgi-bin/luci/admin/network/wifi-ap/api/device", {
        method: "POST",
        body: new URLSearchParams({action, macs: macs.join(",")})
    }).then(r => r.json()).then(res => showBatchProgress(res, action));
}

// 批量进度条与失败重试
function showBatchProgress(summary, action) {
    let el = document.getElementById("ap-batch-progress");
    let total = (summary.detail && Object.keys(summary.detail).length) || 0;
    let success = Object.values(summary.detail || {}).filter(x => x.code === 0).length;
    let fail = total - success;
    let percent = total ? Math.round((success / total) * 100) : 0;
    el.innerHTML = `
      <div style="margin:8px 0;">
        <div style="background:#eee;width:100%;height:12px;border-radius:6px;overflow:hidden;">
          <div style="background:#67c23a;width:${percent}%;height:12px;"></div>
        </div>
        <span>成功: ${success} 失败: ${fail}</span>
      </div>
    `;
    if (fail > 0 && summary.detail) {
        el.innerHTML += "<br>失败设备:<ul>" +
            Object.keys(summary.detail).filter(mac => summary.detail[mac].code !== 0).map(mac => {
                let info = summary.detail[mac];
                let msg = info.msg || info.error || JSON.stringify(info);
                return `<li>${mac}: ${msg} <button class="ap-retry-btn" data-mac="${mac}">重试</button></li>`;
            }).join("") + "</ul>";
        el.querySelectorAll(".ap-retry-btn").forEach(btn => {
            btn.onclick = function() {
                fetch("/cgi-bin/luci/admin/network/wifi-ap/api/device", {
                    method: "POST",
                    body: new URLSearchParams({action: action, mac: btn.dataset.mac})
                }).then(r => r.json()).then(res => alert("重试结果: " + JSON.stringify(res)));
            };
        });
    }
}

// 事件绑定
document.addEventListener("DOMContentLoaded", function() {
    fetchApList();
    document.getElementById("ap-refresh-btn").onclick = fetchApList;
    document.getElementById("ap-batch-reboot").onclick = () => batchCmd("reboot");
    document.getElementById("ap-batch-upgrade").onclick = () => batchCmd("upgrade");
    document.getElementById("ap-batch-sync").onclick = () => batchCmd("reload_config");
    document.getElementById("ap-select-all").onclick = function() {
        let checked = this.checked;
        document.querySelectorAll(".ap-select").forEach(cb => cb.checked = checked);
    };
    // 自动发现按钮：调用AC端API，实际发现由wifi-ap守护进程采集写入标准文件
    document.getElementById("discover-udp").onclick = function() {
        let progress = document.getElementById("discover-progress");
        progress.textContent = "UDP发现中...";
        fetch(L.env.cgiBase + "/admin/network/wifi_ac/api/device_add?discover=1")
            .then(r => r.json()).then(res => {
                progress.textContent = "发现" + (res.devices ? res.devices.length : 0) + "台设备";
                // 可选：渲染发现结果
            });
    };
    document.getElementById("discover-mdns").onclick = function() {
        let progress = document.getElementById("discover-progress");
        progress.textContent = "mDNS发现中...";
        fetch(L.env.cgiBase + "/admin/network/wifi_ac/api/device_add?mdns=1")
            .then(r => r.json()).then(res => {
                progress.textContent = "发现" + (res.devices ? res.devices.length : 0) + "台设备";
            });
    };
    document.getElementById("discover-http").onclick = function() {
        let progress = document.getElementById("discover-progress");
        progress.textContent = "HTTP注册发现中...";
        fetch(L.env.cgiBase + "/admin/network/wifi_ac/api/device_add?http=1")
            .then(r => r.json()).then(res => {
                progress.textContent = "发现" + (res.devices ? res.devices.length : 0) + "台设备";
            });
    };
    document.getElementById("ap-firmware-manage").onclick = function() {
        window.open(L.env.cgiBase + "/admin/network/wifi_ac/firmware", "_blank");
    };
    document.getElementById("ap-template-manage").onclick = function() {
        window.open(L.env.cgiBase + "/admin/network/wifi_ac/template", "_blank");
    };
});

// WebSocket实时状态推送（需后端支持ws接口，建议uhttpd/ws或lua-websockets）
// 自动刷新设备表格（可选）
if ("WebSocket" in window) {
    try {
        let ws = new WebSocket("ws://" + location.host + "/ws/wifi-ap/status");
        ws.onmessage = function(evt) {
            // 可选：自动刷新设备表格
            // fetchApList();
        };
    } catch (e) {}
}

// 趋势图WebSocket实时推送（需后端支持ws接口）
if ("WebSocket" in window) {
    try {
        let wsTrend = new WebSocket("ws://" + location.host + "/ws/wifi-ap/trend");
        wsTrend.onmessage = function(evt) {
            // 可扩展：自动刷新趋势图
            // let data = JSON.parse(evt.data);
            // updateTrendChart(data);
        };
    } catch (e) {}
}

// 建议生产环境通过HTTPS访问，防止中间人攻击

// 分块上传固件（断点续传/回滚伪实现，实际需后端配合）
function uploadFirmwareChunk(file, offset, chunkSize, cb) {
    let reader = new FileReader();
    reader.onload = function(e) {
        let chunk = e.target.result;
        let b64 = btoa(String.fromCharCode.apply(null, new Uint8Array(chunk)));
        fetch(L.env.cgiBase + "/admin/network/wifi-ap/api/firmware_chunk", {
            method: "POST",
            body: new URLSearchParams({offset, chunk: b64})
        }).then(r => r.json()).then(cb);
    };
    let blob = file.slice(offset, offset + chunkSize);
    reader.readAsArrayBuffer(blob);
}

// 固件升级进度查询
function fetchFirmwareStatus(cb) {
    fetch(L.env.cgiBase + "/admin/network/wifi-ap/api/firmware_status")
        .then(r => r.json()).then(cb);
}

// 固件回滚
function rollbackFirmware(cb) {
    fetch(L.env.cgiBase + "/admin/network/wifi-ap/api/firmware_chunk", {
        method: "POST",
        body: new URLSearchParams({action: "rollback"})
    }).then(r => r.json()).then(cb);
}

// 固件提交升级
function commitFirmware(cb) {
    fetch(L.env.cgiBase + "/admin/network/wifi-ap/api/firmware_chunk", {
        method: "POST",
        body: new URLSearchParams({action: "commit"})
    }).then(r => r.json()).then(cb);
}

// 配置模板应用
function applyTemplate(mac, tpl) {
    fetch(L.env.cgiBase + "/admin/network/wifi-ap/api/device", {
        method: "POST",
        body: new URLSearchParams({action: "apply_template", mac, tpl: JSON.stringify(tpl)})
    }).then(r => r.json()).then(res => alert(res.msg || JSON.stringify(res)));
}
