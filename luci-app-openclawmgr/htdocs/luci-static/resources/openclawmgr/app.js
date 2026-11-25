(function() {
  var config = window.openclawmgrConfig || {};
  var container = document.getElementById("openclawmgr-app");
  if (!container) {
    return;
  }

  function parseRgb(value) {
    var m = value && value.match(/\d+/g);
    if (m && m.length >= 3) {
      return { r: parseInt(m[0], 10), g: parseInt(m[1], 10), b: parseInt(m[2], 10) };
    }
    return null;
  }

  function detectDarkMode() {
    try {
      var bg = window.getComputedStyle(document.body).backgroundColor;
      var rgb = parseRgb(bg);
      if (rgb) {
        var luminance = 0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b;
        return luminance < 128;
      }
    } catch (e) {}
    return false;
  }

  var root = container.attachShadow ? (container.shadowRoot || container.attachShadow({ mode: "open" })) : container;

  function defaultProtectedDirectories() {
    return [];
  }

  var state = {
    status: null,
    form: null,
    options: null,
    newOrigin: "",
    security: {
      runningUser: "openclawmgr",
      newDirectoryPath: "",
      directoryError: "",
      pendingAddPath: "",
      deleteTargetId: null,
      deleteTargetPath: "",
      protectedDirectories: defaultProtectedDirectories()
    },
    activeTab: "basic",
    savingSection: "",
    lastAppliedAt: "",
    statusTimer: null,
    installWatchTimer: null,
    lastTaskRunning: false,
    taskLogOpenTs: 0,
    consoleReady: false,
    consoleCheckTimer: null,
    updateCheck: {
      checking: false,
      checked: false,
      hasUpdate: false,
      upgrading: false,
      localVersion: "",
      remoteVersion: "",
      error: ""
    }
  };
  var styleText = "";
  var noticeOverlay = null;
  var noticeCard = null;
  var noticeTitle = null;
  var noticeMessage = null;
  var noticeCloseButton = null;
  var actionDialogOverlay = null;
  var actionDialogCard = null;
  state.formErrors = state.formErrors || { base_dir: "" };

  function request(url, options) {
    options = options || {};
    options.credentials = "same-origin";
    options.headers = options.headers || {};
    if (config.token) {
      options.headers["X-LuCI-Token"] = config.token;
    }
    return fetch(url, options).then(function(r) { return r.json(); });
  }

  function postJson(url, payload) {
    payload = payload || {};
    if (config.token && payload.token == null) {
      payload.token = config.token;
    }
    return request(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    });
  }

  function postForm(url, payload) {
    var body = new URLSearchParams();
    payload = payload || {};
    if (config.token && payload.token == null) {
      payload.token = config.token;
    }
    Object.keys(payload || {}).forEach(function(key) {
      body.append(key, payload[key]);
    });
    return request(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
      },
      body: body.toString()
    });
  }

  function escapeHtml(value) {
    return String(value == null ? "" : value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function defaultModelForAgent(agent) {
    return {
      openai: "gpt-5.2",
      anthropic: "claude-sonnet-4-6",
      "minimax-cn": "MiniMax-M2.5",
      moonshot: "kimi-k2.5",
      "custom-provider": "custom-model"
    }[agent] || "claude-sonnet-4-6";
  }

  function normalizeModelValue(value, fallback) {
    value = String(value || "").replace(/^\s+|\s+$/g, "");
    if (!value) {
      return String(fallback || "");
    }
    return value.replace(/^[^/]+\//, "");
  }

  function resolveModelValue(form) {
    var agent = form && form.default_agent ? form.default_agent : "anthropic";
    var value = form && form.default_model ? String(form.default_model) : "";
    return normalizeModelValue(value, defaultModelForAgent(agent));
  }

  function modelPlaceholder() {
    return "这里只填写模型名；例如 gpt-5.1";
  }

  function statusText(status) {
    if (status.runtime_preparation && status.runtime_preparation.status === "preparing" && status.running) return "准备运行环境";
    if (status.runtime_preparation && status.runtime_preparation.status === "failed") return "运行时准备失败，可重启重试";
    if (status.installing) return status.task_op === "upgrade" ? "更新中" : "安装中";
    if (!status || !status.installed) return "未安装";
    if (status.runtime_missing) return "固定运行时缺失";
    if (status.running) return "运行中";
    if (status.reachable) return "运行中（未托管）";
    return "已停止";
  }

  function statusDotClass(status) {
    if (status && status.runtime_preparation && status.runtime_preparation.status === "failed") return "is-danger";
    if (status && status.installing) return "";
    if (status && status.runtime_missing) return "is-danger";
    if (status && status.running) return "is-success";
    if (status && status.reachable) return "";
    return "is-danger";
  }

  function statusSpinSeconds(status) {
    return (backgroundStatusDelay(status) / 1000).toFixed(1);
  }

  function escapeAttr(value) {
    return escapeHtml(value).replace(/'/g, "&#39;");
  }

  function getSecurityState() {
    if (!state.security) {
      state.security = {
        runningUser: "openclawmgr",
        newDirectoryPath: "",
        directoryError: "",
        pendingAddPath: "",
        deleteTargetId: null,
        deleteTargetPath: "",
        protectedDirectories: defaultProtectedDirectories()
      };
    }
    if (!Array.isArray(state.security.protectedDirectories)) {
      state.security.protectedDirectories = defaultProtectedDirectories();
    }
    if (state.security.newDirectoryPath == null) {
      state.security.newDirectoryPath = "";
    }
    if (state.security.directoryError == null) {
      state.security.directoryError = "";
    }
    if (state.security.pendingAddPath == null) {
      state.security.pendingAddPath = "";
    }
    if (state.security.deleteTargetPath == null) {
      state.security.deleteTargetPath = "";
    }
    return state.security;
  }

  function ensureNoticeDialog() {
    if (noticeOverlay && noticeOverlay.parentNode) {
      return;
    }

    noticeOverlay = document.createElement("div");
    noticeOverlay.style.position = "fixed";
    noticeOverlay.style.inset = "0";
    noticeOverlay.style.zIndex = "2147483647";
    noticeOverlay.style.display = "none";
    noticeOverlay.style.alignItems = "center";
    noticeOverlay.style.justifyContent = "center";
    noticeOverlay.style.padding = "20px";
    noticeOverlay.style.boxSizing = "border-box";
    noticeOverlay.style.background = "rgba(15, 23, 42, 0.42)";

    noticeCard = document.createElement("div");
    noticeCard.style.width = "min(560px, calc(100vw - 40px))";
    noticeCard.style.borderRadius = "18px";
    noticeCard.style.border = "1px solid rgba(217, 225, 238, 0.95)";
    noticeCard.style.background = "#ffffff";
    noticeCard.style.boxShadow = "0 10px 28px rgba(15, 23, 42, 0.18)";
    noticeCard.style.padding = "20px";
    noticeCard.style.boxSizing = "border-box";
    noticeCard.style.color = "#1f2937";

    noticeTitle = document.createElement("h3");
    noticeTitle.style.margin = "0 0 10px";
    noticeTitle.style.fontSize = "18px";
    noticeTitle.style.fontWeight = "700";

    noticeMessage = document.createElement("div");
    noticeMessage.style.marginBottom = "16px";
    noticeMessage.style.color = "#6b7280";
    noticeMessage.style.lineHeight = "1.6";

    var footer = document.createElement("div");
    footer.style.display = "flex";
    footer.style.justifyContent = "flex-end";
    footer.style.gap = "14px";

    noticeCloseButton = document.createElement("button");
    noticeCloseButton.type = "button";
    noticeCloseButton.textContent = "知道了";
    noticeCloseButton.style.appearance = "none";
    noticeCloseButton.style.display = "inline-flex";
    noticeCloseButton.style.alignItems = "center";
    noticeCloseButton.style.justifyContent = "center";
    noticeCloseButton.style.border = "1px solid #d9e1ee";
    noticeCloseButton.style.background = "#2f67f6";
    noticeCloseButton.style.color = "#ffffff";
    noticeCloseButton.style.borderRadius = "10px";
    noticeCloseButton.style.height = "36px";
    noticeCloseButton.style.minWidth = "96px";
    noticeCloseButton.style.padding = "0 14px";
    noticeCloseButton.style.fontSize = "13px";
    noticeCloseButton.style.fontWeight = "600";
    noticeCloseButton.style.cursor = "pointer";
    noticeCloseButton.onclick = function() {
      closeNoticeDialog();
    };

    footer.appendChild(noticeCloseButton);
    noticeCard.appendChild(noticeTitle);
    noticeCard.appendChild(noticeMessage);
    noticeCard.appendChild(footer);
    noticeOverlay.appendChild(noticeCard);
    document.body.appendChild(noticeOverlay);
  }

  function openNoticeDialog(message, title) {
    ensureNoticeDialog();
    noticeTitle.textContent = String(title || "提示");
    noticeMessage.textContent = String(message || "");
    noticeOverlay.style.display = "flex";
  }

  function closeNoticeDialog() {
    if (!noticeOverlay) {
      return;
    }
    noticeOverlay.style.display = "none";
  }

  function ensureActionDialog() {
    if (actionDialogOverlay && actionDialogOverlay.parentNode) {
      return;
    }

    actionDialogOverlay = document.createElement("div");
    actionDialogOverlay.style.position = "fixed";
    actionDialogOverlay.style.inset = "0";
    actionDialogOverlay.style.zIndex = "2147483646";
    actionDialogOverlay.style.display = "none";
    actionDialogOverlay.style.alignItems = "center";
    actionDialogOverlay.style.justifyContent = "center";
    actionDialogOverlay.style.padding = "20px";
    actionDialogOverlay.style.boxSizing = "border-box";
    actionDialogOverlay.style.background = "rgba(15, 23, 42, 0.42)";

    actionDialogCard = document.createElement("div");
    actionDialogCard.style.width = "min(560px, calc(100vw - 40px))";
    actionDialogCard.style.borderRadius = "18px";
    actionDialogCard.style.border = "1px solid rgba(217, 225, 238, 0.95)";
    actionDialogCard.style.background = "#ffffff";
    actionDialogCard.style.boxShadow = "0 10px 28px rgba(15, 23, 42, 0.18)";
    actionDialogCard.style.padding = "20px";
    actionDialogCard.style.boxSizing = "border-box";
    actionDialogCard.style.color = "#1f2937";

    actionDialogOverlay.appendChild(actionDialogCard);
    document.body.appendChild(actionDialogOverlay);
  }

  function makeActionDialogText(text, muted) {
    var el = document.createElement("div");
    el.textContent = String(text || "");
    el.style.marginBottom = "10px";
    el.style.lineHeight = "1.6";
    el.style.color = muted ? "#6b7280" : "#1f2937";
    return el;
  }

  function makeActionDialogCode(text) {
    var el = document.createElement("code");
    el.textContent = String(text || "");
    el.style.display = "block";
    el.style.marginBottom = "14px";
    el.style.padding = "10px 12px";
    el.style.borderRadius = "12px";
    el.style.background = "rgba(47, 103, 246, 0.08)";
    el.style.color = "#1f2937";
    el.style.overflowWrap = "anywhere";
    return el;
  }

  function makeActionDialogFooter() {
    var el = document.createElement("div");
    el.style.display = "flex";
    el.style.justifyContent = "flex-end";
    el.style.gap = "14px";
    el.style.marginTop = "12px";
    return el;
  }

  function makeActionDialogButton(label, kind, onclick) {
    var button = document.createElement("button");
    button.type = "button";
    button.textContent = String(label || "");
    button.style.appearance = "none";
    button.style.display = "inline-flex";
    button.style.alignItems = "center";
    button.style.justifyContent = "center";
    button.style.border = "1px solid " + (kind === "danger" ? "#ef4444" : kind === "primary" ? "#2f67f6" : "#d9e1ee");
    button.style.background = kind === "danger" ? "#ef4444" : kind === "primary" ? "#2f67f6" : "#ffffff";
    button.style.color = kind === "default" ? "#1f2937" : "#ffffff";
    button.style.borderRadius = "10px";
    button.style.minWidth = "96px";
    button.style.minHeight = "36px";
    button.style.padding = "0 14px";
    button.style.fontSize = "13px";
    button.style.fontWeight = "600";
    button.style.cursor = "pointer";
    button.onclick = onclick;
    return button;
  }

  function makeActionDialogOption(title, note, onclick) {
    var button = document.createElement("button");
    var titleEl = document.createElement("span");
    var noteEl = document.createElement("span");

    button.type = "button";
    button.style.appearance = "none";
    button.style.display = "flex";
    button.style.flexDirection = "column";
    button.style.alignItems = "flex-start";
    button.style.justifyContent = "flex-start";
    button.style.gap = "4px";
    button.style.width = "100%";
    button.style.padding = "12px 14px";
    button.style.border = "1px solid #d9e1ee";
    button.style.borderRadius = "12px";
    button.style.background = "#ffffff";
    button.style.cursor = "pointer";
    button.style.textAlign = "left";
    button.onclick = onclick;

    titleEl.textContent = String(title || "");
    titleEl.style.color = "#1f2937";
    titleEl.style.fontWeight = "700";

    noteEl.textContent = String(note || "");
    noteEl.style.color = "#6b7280";
    noteEl.style.fontSize = "12px";
    noteEl.style.fontWeight = "500";

    button.appendChild(titleEl);
    button.appendChild(noteEl);
    return button;
  }

  function hideActionDialog() {
    if (actionDialogOverlay) {
      actionDialogOverlay.style.display = "none";
    }
  }

  function syncActionDialog() {
    ensureActionDialog();
    while (actionDialogCard.firstChild) {
      actionDialogCard.removeChild(actionDialogCard.firstChild);
    }

    var security = getSecurityState();
    var deleteDialogOpen = security.deleteTargetId != null;
    var addDialogOpen = !!security.pendingAddPath;

    if (!deleteDialogOpen && !addDialogOpen) {
      hideActionDialog();
      return;
    }

    var title = document.createElement("h3");
    title.style.margin = "0 0 12px";
    title.style.fontSize = "18px";
    title.style.fontWeight = "700";
    actionDialogCard.appendChild(title);

    if (deleteDialogOpen) {
      var actions = document.createElement("div");
      title.textContent = "删除禁止访问目录";
      actionDialogCard.appendChild(makeActionDialogText("确定要从保护列表中移除以下目录吗？", true));
      actionDialogCard.appendChild(makeActionDialogCode(security.deleteTargetPath || ""));
      actionDialogCard.appendChild(makeActionDialogText("请选择删除方式：", true));

      actions.style.display = "grid";
      actions.style.gap = "10px";
      actions.appendChild(makeActionDialogOption("直接删除", "仅从列表移除，不改变目录权限", function() {
        handleSecurityDelete("direct");
      }));
      actions.appendChild(makeActionDialogOption("恢复其他用户组可访问（drwxr-xr-x）", "移除并恢复权限", function() {
        handleSecurityDelete("restore");
      }));
      actionDialogCard.appendChild(actions);

      var deleteFooter = makeActionDialogFooter();
      deleteFooter.appendChild(makeActionDialogButton("取消", "default", function() {
        var nextSecurity = getSecurityState();
        nextSecurity.deleteTargetId = null;
        nextSecurity.deleteTargetPath = "";
        render();
      }));
      actionDialogCard.appendChild(deleteFooter);
    } else if (addDialogOpen) {
      title.textContent = "确认添加禁止访问目录";
      actionDialogCard.appendChild(makeActionDialogText("添加后将尝试修改该目录权限，限制 OpenClaw 对其访问：", true));
      actionDialogCard.appendChild(makeActionDialogCode(security.pendingAddPath || ""));

      var warning = document.createElement("div");
      warning.style.marginTop = "4px";
      warning.style.marginBottom = "14px";
      warning.style.padding = "12px 14px";
      warning.style.border = "1px solid rgba(245, 158, 11, 0.24)";
      warning.style.borderRadius = "12px";
      warning.style.background = "rgba(245, 158, 11, 0.08)";

      var warningTitle = document.createElement("div");
      warningTitle.textContent = "请确认你已知晓以下风险：";
      warningTitle.style.marginBottom = "8px";
      warningTitle.style.color = "#1f2937";
      warningTitle.style.fontSize = "13px";
      warningTitle.style.fontWeight = "700";

      var warningList = document.createElement("ul");
      warningList.style.margin = "0";
      warningList.style.paddingLeft = "18px";
      warningList.style.color = "#6b7280";

      [
        "该目录的 Linux 权限会被修改为仅允许 root 和 root 组访问。",
        "这可能影响其他服务、用户或脚本对该目录的正常访问。",
        "本功能不是容器或沙箱隔离，只是基于系统文件权限限制。",
        "请勿将 OpenClaw 自身的数据目录、程序目录加入禁止访问列表。"
      ].forEach(function(text) {
        var item = document.createElement("li");
        item.textContent = text;
        warningList.appendChild(item);
      });

      warning.appendChild(warningTitle);
      warning.appendChild(warningList);
      actionDialogCard.appendChild(warning);

      var addFooter = makeActionDialogFooter();
      addFooter.appendChild(makeActionDialogButton("取消", "default", function() {
        var nextSecurity = getSecurityState();
        nextSecurity.pendingAddPath = "";
        render();
      }));
      addFooter.appendChild(makeActionDialogButton("确认添加", "danger", function() {
        handleSecurityAddConfirm();
      }));
      actionDialogCard.appendChild(addFooter);
    }

    actionDialogOverlay.style.display = "flex";
  }

  function handleSecurityAddConfirm() {
    var security = getSecurityState();
    var path = security.pendingAddPath || "";
    if (!path) {
      render();
      return;
    }
    postJson(config.securityAddUrl, { path: path }).then(function(rv) {
      if (!rv || !rv.ok) {
        security.pendingAddPath = "";
        security.directoryError = (rv && rv.error) || "添加目录失败";
        render();
        return;
      }
      security.pendingAddPath = "";
      security.newDirectoryPath = "";
      security.directoryError = "";
      loadSecurityData();
    }).catch(function() {
      security.pendingAddPath = "";
      security.directoryError = "添加目录失败";
      render();
    });
  }

  function handleSecurityDelete(mode) {
    var security = getSecurityState();
    if (security.deleteTargetId == null) {
      return;
    }
    postJson(config.securityRemoveUrl, { id: security.deleteTargetId, mode: mode }).then(function(rv) {
      if (!rv || !rv.ok) {
        openNoticeDialog((rv && rv.error) || (mode === "restore" ? "恢复并删除失败" : "删除失败"));
        return;
      }
      security.deleteTargetId = null;
      security.deleteTargetPath = "";
      loadSecurityData();
    }).catch(function() {
      openNoticeDialog(mode === "restore" ? "恢复并删除失败" : "删除失败");
    });
  }

  function securityDataDirectory() {
    var formBaseDir = state.form && state.form.base_dir ? String(state.form.base_dir) : "";
    var statusBaseDir = state.status && state.status.base_dir ? String(state.status.base_dir) : "";
    var suggestedBaseDir = state.options && state.options.suggested_base_dir ? String(state.options.suggested_base_dir) : "";
    return formBaseDir || statusBaseDir || suggestedBaseDir || "";
  }

  function getFormErrors() {
    state.formErrors = state.formErrors || { base_dir: "" };
    if (state.formErrors.base_dir == null) {
      state.formErrors.base_dir = "";
    }
    return state.formErrors;
  }

  function isBaseDirErrorMessage(message) {
    var text = String(message || "");
    return text.indexOf("数据目录") >= 0 || text.indexOf("base_dir") >= 0;
  }

  function validateProtectedDirectory(path) {
    var security = getSecurityState();
    var value = String(path || "").replace(/^\s+|\s+$/g, "");
    var dataDirectory = securityDataDirectory();
    if (!value) {
      return "请输入目录路径";
    }
    if (value.charAt(0) !== "/") {
      return "请输入绝对路径";
    }
    if (value === "/") {
      return "不能添加根目录 /";
    }
    if (dataDirectory && (value === dataDirectory || value.indexOf(dataDirectory + "/") === 0)) {
      return "不能添加 OpenClaw 的运行目录";
    }
    if (dataDirectory && dataDirectory.indexOf(value + "/") === 0) {
      return "不能添加 OpenClaw 运行目录的父目录";
    }
    if (security.protectedDirectories.some(function(item) { return item.path === value; })) {
      return "该目录已在列表中";
    }
    return "";
  }

  function securityProtectionMode(level) {
    return level === "strict" ? "仅允许 root 访问" : "仅允许 root 和 root 组访问";
  }

  function securityStatusBadge(status) {
    var map = {
      active: ["已生效", "is-active"],
      inactive: ["未生效", "is-danger"],
      "not-found": ["目录不存在", "is-muted"],
      denied: ["已拒绝", "is-active"],
      "check-failed": ["检测失败", "is-danger"]
    };
    var item = map[status] || [status || "未知", "is-muted"];
    return '<span class="oclm-security-badge ' + item[1] + '">' + escapeHtml(item[0]) + '</span>';
  }

  function loadSecurityData(done) {
    if (!config.securityDataUrl) {
      if (typeof done === "function") done();
      return;
    }
    request(config.securityDataUrl).then(function(rv) {
      var security = getSecurityState();
      security.protectedDirectories = rv && rv.ok && Array.isArray(rv.items) ? rv.items : [];
      render();
      if (typeof done === "function") done(rv);
    }).catch(function() {
      getSecurityState().protectedDirectories = [];
      render();
      if (typeof done === "function") done(null);
    });
  }

  function maskedTokenUrl(url) {
    var value = String(url || "");
    if (!value) {
      return "-";
    }
    return value.replace(/(#token=)([^&#]+)/, function(_, prefix, token) {
      if (!token) {
        return prefix;
      }
      var head = token.slice(0, 6);
      var tail = token.length > 10 ? token.slice(-4) : "";
      return prefix + head + "****" + tail;
    });
  }

  function getUpdateCheck() {
    state.updateCheck = state.updateCheck || {
      checking: false,
      checked: false,
      hasUpdate: false,
      upgrading: false,
      localVersion: "",
      remoteVersion: "",
      error: ""
    };
    return state.updateCheck;
  }

  function updateActionLabel(status) {
    var updateCheck = getUpdateCheck();
    if (updateCheck.checking) return "检测中…";
    return "检测更新";
  }

  function statusNoteText(status) {
    if (status && status.installing) {
      return status.task_op === "upgrade"
        ? "更新任务正在后台运行，可打开任务日志查看进度。"
        : "安装任务正在后台运行，可打开任务日志查看进度。";
    }
    return "";
  }

  function versionNoteText() {
    var updateCheck = getUpdateCheck();
    if (updateCheck.checking) {
      return "正在检测远程版本，请稍候…";
    }
    if (updateCheck.error) {
      return updateCheck.error;
    }
    if (updateCheck.checked && updateCheck.localVersion && updateCheck.remoteVersion) {
      if (updateCheck.hasUpdate) {
        return "发现新版本：本地 " + updateCheck.localVersion + "，远程 " + updateCheck.remoteVersion;
      }
      return "当前已是最新版：本地 " + updateCheck.localVersion + "，远程 " + updateCheck.remoteVersion;
    }
    return "";
  }

  function copyIcon(className) {
    return '' +
      '<svg class="' + escapeAttr(className || "") + '" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">' +
      '<rect x="9" y="9" width="10" height="10" rx="2" stroke="currentColor" stroke-width="1.8"></rect>' +
      '<path d="M6 15H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v1" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"></path>' +
      '</svg>';
  }

  function copiedIcon(className) {
    return '' +
      '<svg class="' + escapeAttr(className || "") + '" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">' +
      '<path d="M5 12.5l4 4L19 7" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"></path>' +
      '</svg>';
  }

  function fallbackCopyText(value) {
    var el = document.createElement("textarea");
    el.value = String(value || "");
    el.setAttribute("readonly", "readonly");
    el.style.position = "fixed";
    el.style.top = "-9999px";
    el.style.left = "-9999px";
    document.body.appendChild(el);
    el.focus();
    el.select();
    var ok = false;
    try {
      ok = document.execCommand("copy");
    } catch (e) {}
    document.body.removeChild(el);
    return ok;
  }

  function copyText(value) {
    value = String(value || "");
    if (!value) {
      return Promise.resolve(false);
    }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(value).then(function() {
        return true;
      }).catch(function() {
        return fallbackCopyText(value);
      });
    }
    return Promise.resolve(fallbackCopyText(value));
  }

  function flashCopied(el) {
    if (!el) {
      return;
    }
    if (el._oclmCopyTimer) {
      window.clearTimeout(el._oclmCopyTimer);
      el._oclmCopyTimer = null;
    }
    el.classList.add("is-copied");
    el.innerHTML = copiedIcon("oclm-copy-icon");
    el._oclmCopyTimer = window.setTimeout(function() {
      el.classList.remove("is-copied");
      el.innerHTML = copyIcon("oclm-copy-icon");
      el._oclmCopyTimer = null;
    }, 1100);
  }

  function openclawIcon(className) {
    return '' +
      '<svg class="' + escapeAttr(className || "") + '" viewBox="0 0 120 120" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">' +
      '<defs>' +
      '<linearGradient id="oclm-lobster-gradient" x1="0%" y1="0%" x2="100%" y2="100%">' +
      '<stop offset="0%" stop-color="#ff4d4d"/>' +
      '<stop offset="100%" stop-color="#991b1b"/>' +
      '</linearGradient>' +
      '</defs>' +
      '<path d="M60 10 C30 10 15 35 15 55 C15 75 30 95 45 100 L45 110 L55 110 L55 100 C55 100 60 102 65 100 L65 110 L75 110 L75 100 C90 95 105 75 105 55 C105 35 90 10 60 10Z" fill="url(#oclm-lobster-gradient)"/>' +
      '<path d="M20 45 C5 40 0 50 5 60 C10 70 20 65 25 55 C28 48 25 45 20 45Z" fill="url(#oclm-lobster-gradient)"/>' +
      '<path d="M100 45 C115 40 120 50 115 60 C110 70 100 65 95 55 C92 48 95 45 100 45Z" fill="url(#oclm-lobster-gradient)"/>' +
      '<path d="M45 15 Q35 5 30 8" stroke="#ff4d4d" stroke-width="3" stroke-linecap="round"/>' +
      '<path d="M75 15 Q85 5 90 8" stroke="#ff4d4d" stroke-width="3" stroke-linecap="round"/>' +
      '<circle cx="45" cy="35" r="6" fill="#050810"/>' +
      '<circle cx="75" cy="35" r="6" fill="#050810"/>' +
      '<circle cx="46" cy="34" r="2.5" fill="#00e5cc"/>' +
      '<circle cx="76" cy="34" r="2.5" fill="#00e5cc"/>' +
      '</svg>';
  }

  function communityIcon(className) {
    return '' +
      '<svg class="' + escapeAttr(className || "") + '" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">' +
      '<path d="M8 10h8M8 14h5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"></path>' +
      '<path d="M7 19l-3 2V7a3 3 0 0 1 3-3h10a3 3 0 0 1 3 3v8a3 3 0 0 1-3 3H7Z" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"></path>' +
      '</svg>';
  }

  function refreshIcon(className) {
    return '' +
      '<svg class="' + escapeAttr(className || "") + '" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">' +
      '<path d="M21 12a9 9 0 0 1-15.4 6.4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"></path>' +
      '<path d="M3 12a9 9 0 0 1 15.4-6.4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"></path>' +
      '<path d="M3 4v5h5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"></path>' +
      '<path d="M21 20v-5h-5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"></path>' +
      '</svg>';
  }

  function trashIcon(className) {
    return '' +
      '<svg class="' + escapeAttr(className || "") + '" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">' +
      '<path d="M3 6h18" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"></path>' +
      '<path d="M8 6V4.5A1.5 1.5 0 0 1 9.5 3h5A1.5 1.5 0 0 1 16 4.5V6" stroke="currentColor" stroke-width="1.8"></path>' +
      '<path d="M19 6l-1 13a2 2 0 0 1-2 1H8a2 2 0 0 1-2-1L5 6" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"></path>' +
      '<path d="M10 11v5M14 11v5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"></path>' +
      '</svg>';
  }

  function taskWindowAvailable() {
    return !!(window.taskd && window.taskd.show_log);
  }

  function showTaskLog(taskId) {
    taskId = taskId || "openclawmgr";
    if (!taskWindowAvailable()) {
      openNoticeDialog("任务窗口不可用（未加载 taskd/xterm）。请安装 luci-lib-taskd 和 luci-lib-xterm，然后强制刷新页面。");
      return;
    }
    var now = Date.now ? Date.now() : (+new Date());
    if (state.taskLogOpenTs && now - state.taskLogOpenTs < 1500) {
      return;
    }
    state.taskLogOpenTs = now;
    window.taskd.show_log(taskId);
  }

  function stopStatusPolling() {
    if (state.statusTimer) {
      window.clearTimeout(state.statusTimer);
      state.statusTimer = null;
    }
  }

  function stopInstallWatch() {
    if (state.installWatchTimer) {
      window.clearTimeout(state.installWatchTimer);
      state.installWatchTimer = null;
    }
  }

  function stopConsoleCheck() {
    if (state.consoleCheckTimer) {
      window.clearTimeout(state.consoleCheckTimer);
      state.consoleCheckTimer = null;
    }
  }

  function pollConsoleReady(rounds) {
    rounds = typeof rounds === "number" ? rounds : 20;
    stopConsoleCheck();
    state.consoleReady = false;

    function tick(remaining) {
      request(config.readyUrl).then(function(rv) {
        state.consoleReady = !!(rv && rv.ok && rv.ready);
        updateStatusDom(state.status);
        if (!state.consoleReady && remaining > 1) {
          state.consoleCheckTimer = window.setTimeout(function() { tick(remaining - 1); }, 1000);
        } else {
          state.consoleCheckTimer = null;
        }
      }).catch(function() {
        state.consoleReady = false;
        updateStatusDom(state.status);
        if (remaining > 1) {
          state.consoleCheckTimer = window.setTimeout(function() { tick(remaining - 1); }, 1500);
        } else {
          state.consoleCheckTimer = null;
        }
      });
    }

    tick(rounds);
  }

  function backgroundStatusDelay(status) {
    if (status && status.installing) {
      return 3000;
    }
    if (!status || !status.installed) {
      return 30000;
    }
    if (status.running) {
      return 15000;
    }
    return 20000;
  }

  function ensureInstallWatch() {
    stopInstallWatch();
    state.installWatchTimer = window.setTimeout(function() {
      refreshStatus(function() {
        ensureInstallWatch();
      });
    }, backgroundStatusDelay(state.status));
  }

  function scheduleStatusRefresh(rounds, delay) {
    rounds = typeof rounds === "number" ? rounds : 6;
    delay = typeof delay === "number" ? delay : 1000;
    stopStatusPolling();

    function tick(remaining) {
      refreshStatus(function() {
        if (remaining > 1) {
          state.statusTimer = window.setTimeout(function() {
            tick(remaining - 1);
          }, delay);
        } else {
          state.statusTimer = null;
        }
      });
    }

    tick(rounds);
  }

  function render() {
    var status = state.status || {};
    var runtimeInfo = status.runtime_info;
    var runtimeAbi = runtimeInfo ? String(runtimeInfo.abi || "") + (runtimeInfo.libc && runtimeInfo.libc.version ? " " + runtimeInfo.libc.version : "") : "";
    var form = state.form || {};
    var formErrors = getFormErrors();
    var options = state.options || { base_dir_choices: [] };
    var security = getSecurityState();
    var allowedOrigins = Array.isArray(form.allowed_origins) ? form.allowed_origins : [];
    var baseDirPaths = options.base_dir_choices || [];
    var baseDirValue = String(form.base_dir || "");
    var customBaseDir = state.customBaseDir === true || (baseDirValue && baseDirPaths.indexOf(baseDirValue) < 0);
    var baseDirOptions = baseDirPaths.map(function(path) {
      var label = path === state.configuredBaseDir ? "当前目录 · " + path : path;
      return '<option value="' + escapeAttr(path) + '"' + (!customBaseDir && path === baseDirValue ? ' selected' : '') + '>' + escapeHtml(label) + '</option>';
    }).join("");
    var origins = allowedOrigins.map(function(item, index) {
      return '' +
        '<div class="oclm-origin-item">' +
        '<input class="oclm-control" type="text" value="' + escapeHtml(item) + '" data-origin-index="' + index + '" />' +
        '<button class="oclm-button oclm-button-danger" type="button" data-remove-origin="' + index + '">删除</button>' +
        '</div>';
    }).join("");

    var updateCheck = getUpdateCheck();
    var installLabel = status.installing ? (status.task_op === "upgrade" ? "更新中" : "安装中") : "立即安装";
    var installAcceleratedChecked = form.install_accelerated == null ? true : form.install_accelerated === true;
    var installChannel = form.install_channel === "latest" ? "latest" : "stable";
    var showInstallAction = !status.installed;
    var showUpdateAction = status.installed && !status.installing;
    var showServiceActions = status.installed && !status.installing;
    var activeTab = state.activeTab || "basic";
    var savingBasic = state.savingSection === "basic";
    var savingAi = state.savingSection === "ai";
    var savingAccess = state.savingSection === "access";
    var noteText = statusNoteText(status);
    var securityList = security.protectedDirectories.map(function(item) {
      return '' +
        '<div class="oclm-security-row">' +
        '<div class="oclm-security-row-main">' +
        '<div class="oclm-security-item-path"><code>' + escapeHtml(item.path) + '</code>' + securityStatusBadge(item.status) + '</div>' +
        '<div class="oclm-security-item-grid">' +
        '<div><span class="oclm-security-key">保护方式：</span>' + escapeHtml(item.protectionMode) + '</div>' +
        '<div><span class="oclm-security-key">检测结果：</span>' + escapeHtml(item.checkResult) + '</div>' +
        '</div>' +
        '</div>' +
        '<div class="oclm-security-row-actions">' +
        '<button class="oclm-icon-ghost-button" type="button" data-security-recheck="' + escapeAttr(item.id) + '" title="重新检测" aria-label="重新检测">' + refreshIcon("oclm-row-icon") + '</button>' +
        '<button class="oclm-icon-ghost-button oclm-icon-ghost-danger" type="button" data-security-delete="' + escapeAttr(item.id) + '" title="删除" aria-label="删除">' + trashIcon("oclm-row-icon") + '</button>' +
        '</div>' +
        '</div>';
    }).join("");
    var canStartService = !status.running && !status.reachable;
    var canStopService = !!status.running;

    root.innerHTML =
      '<style>' + styleText + '</style>' +
      '<div class="oclm-app"' + (detectDarkMode() ? ' data-darkmode="true"' : '') + '>' +
      '<div class="oclm-root">' +
      '<div class="oclm-shell">' +
      '<div class="oclm-header">' +
      '<h1>' + openclawIcon("oclm-title-icon") + 'OpenClaw 启动器</h1>' +
      '<p>在 OpenWrt 上原生安装、启动并管理官方 OpenClaw</p>' +
      '</div>' +

      '<section class="oclm-card">' +
      '<h2>服务状态</h2>' +
      '<div class="oclm-status-grid">' +
      '<div class="oclm-status-row"><span class="oclm-status-label">状态</span><span id="oclm-status-pill" class="oclm-status-pill" style="--oclm-spin-duration:' + escapeAttr(statusSpinSeconds(status)) + 's"><span id="oclm-status-dot" class="oclm-dot ' + statusDotClass(status) + '"></span><span class="oclm-status-spinner" aria-hidden="true"></span><span id="oclm-status-text">' + escapeHtml(statusText(status)) + '</span></span>' +
      '<span id="oclm-uptime" class="oclm-tag' + (status.running && status.uptime_human ? '' : ' oclm-hidden') + '">运行时间 <strong id="oclm-uptime-text">' + escapeHtml(status.uptime_human || "") + '</strong></span>' +
      '</div>' +
      '<div><div id="oclm-pid-row"' + ((status.running && status.pid) ? '' : ' class="oclm-hidden"') + '><div class="oclm-inline-row"><span class="oclm-tag">PID <strong id="oclm-pid">' + escapeHtml(status.pid || "") + '</strong></span></div></div></div>' +
      '<div><div class="oclm-meta-label">地址</div><div class="oclm-address-row"><span id="oclm-address-text" class="oclm-address-text">' + escapeHtml(maskedTokenUrl(status.token_url || status.base_url || "")) + '</span><button id="oclm-copy-token-url" class="oclm-icon-button' + ((status.token_url || status.base_url) ? '' : ' oclm-hidden') + '" type="button" data-copy-token-url="1" aria-label="复制地址">' + copyIcon("oclm-copy-icon") + '</button></div></div>' +
      '<div><div class="oclm-meta-label">目录</div><div id="oclm-status-base-dir">' + escapeHtml(status.base_dir || "-") + '</div></div>' +
      '<div><div class="oclm-meta-label">版本</div><div class="oclm-version-tags"><a class="oclm-tag oclm-tag-link" href="https://github.com/openclaw/openclaw/releases" target="_blank" rel="noreferrer">OpenClaw <strong id="oclm-openclaw-version">' + escapeHtml(status.openclaw_version || "-") + '</strong></a><span class="oclm-tag">Node <strong id="oclm-node-version">' + escapeHtml(status.node_version || "-") + '</strong></span>' +
      '<span id="oclm-runtime-abi" class="oclm-tag' + (runtimeInfo ? '' : ' oclm-hidden') + '">' + escapeHtml(runtimeAbi) + '</span>' +
      '<a id="oclm-runtime-source" class="oclm-tag oclm-tag-link" href="' + escapeAttr(config.runtimeUrl || '/cgi-bin/luci/admin/services/mise') + '" title="' + escapeAttr(runtimeInfo && runtimeInfo.instance || '') + '">mise 固定运行时</a>' +
      '<span id="oclm-runtime-unknown" class="oclm-tag' + (!runtimeInfo && status.installed ? '' : ' oclm-hidden') + '">运行时需检查；可重启服务准备依赖</span></div></div>' +
      '<div></div>' +
      '</div>' +
      '<div id="oclm-status-actions" class="oclm-status-actions">' +
      '<div id="oclm-install-inline" class="oclm-install-inline' + (showInstallAction ? '' : ' oclm-hidden') + '">' +
      '<button id="oclm-install-btn" class="oclm-button oclm-button-primary" type="button" data-install-action="1"' + (status.installing ? ' disabled' : '') + '>' + installLabel + '</button>' +
      '<label class="oclm-check"><input type="checkbox" id="oclm-install-accelerated"' + (installAcceleratedChecked ? ' checked' : '') + ' />Kspeeder 加速安装</label>' +
      '</div>' +
      '<button id="oclm-open-console" class="oclm-button oclm-button-primary' + ((status.running || status.reachable) ? '' : ' oclm-hidden') + '" type="button" data-open-console="1"' + (state.consoleReady ? '' : ' disabled') + '>' + openclawIcon("oclm-button-icon") + (state.consoleReady ? '打开控制台' : '控制台准备中…') + '</button>' +
      '<a id="oclm-open-community" class="oclm-button oclm-button-community" href="https://www.koolcenter.com/t/topic/19042" target="_blank" rel="noreferrer noopener">' + communityIcon("oclm-button-icon") + '玩家交流</a>' +
      '<div id="oclm-service-actions" class="oclm-service-actions-row' + (showServiceActions ? '' : ' oclm-hidden') + '">' +
      '<button id="oclm-btn-start" class="oclm-button oclm-button-service-start' + (canStartService ? '' : ' oclm-hidden') + '" type="button" data-op="start">启动服务</button>' +
      '<button id="oclm-btn-stop" class="oclm-button oclm-button-service-stop' + (canStopService ? '' : ' oclm-hidden') + '" type="button" data-op="stop">停止服务</button>' +
      '<button id="oclm-btn-restart" class="oclm-button oclm-button-service-restart" type="button" data-op="restart">重启服务</button>' +
      '</div>' +
      '<button id="oclm-cancel-install" class="oclm-button oclm-button-danger' + (status.installing ? '' : ' oclm-hidden') + '" type="button" data-op="cancel_install">停止安装</button>' +
      '</div>' +
      '<div id="oclm-status-note" class="oclm-status-note' + (noteText ? '' : ' oclm-hidden') + '">' + escapeHtml(noteText) + '</div>' +
      '</section>' +

      '<section class="oclm-card">' +
      '<div class="oclm-tabs">' +
      '<button class="oclm-tab' + (activeTab === "basic" ? ' is-active' : '') + '" type="button" data-tab="basic">基础配置</button>' +
      '<button class="oclm-tab' + (activeTab === "ai" ? ' is-active' : '') + '" type="button" data-tab="ai">AI配置</button>' +
      '<button class="oclm-tab' + (activeTab === "access" ? ' is-active' : '') + '" type="button" data-tab="access">访问控制</button>' +
      '<button class="oclm-tab' + (activeTab === "security" ? ' is-active' : '') + '" type="button" data-tab="security">安全设置</button>' +
      '<button class="oclm-tab' + (activeTab === "version" ? ' is-active' : '') + '" type="button" data-tab="version">版本管理</button>' +
      '<button class="oclm-tab' + (activeTab === "cleanup" ? ' is-active' : '') + '" type="button" data-tab="cleanup">卸载清理</button>' +
      '</div>' +
      '<div class="' + (activeTab === "basic" ? '' : 'oclm-hidden') + '">' +
      '<h2>基础配置</h2>' +
      '<div class="oclm-form-grid oclm-form-grid-ai" style="margin-top: 26px;">' +
      fieldInput("监听端口", '<input class="oclm-control" type="number" min="1025" max="65535" id="oclm-port" value="' + escapeHtml(form.port || "18789") + '" />') +
      fieldInput("监听范围", selectHtml("oclm-bind", form.bind, [
        ["lan", "所有地址"],
        ["loopback", "仅本机"],
        ["auto", "自动"]
      ])) +
      fieldInput("数据目录", '<select class="oclm-control' + (formErrors.base_dir ? ' oclm-control-danger' : '') + '" id="oclm-base-dir" aria-label="数据目录">' +
        '<option value="" disabled' + (!baseDirValue && !customBaseDir ? ' selected' : '') + '>请选择硬盘数据目录</option>' + baseDirOptions +
        '<option value="__custom__"' + (customBaseDir ? ' selected' : '') + '>自定义目录…</option></select>' +
        '<input class="oclm-control' + (customBaseDir ? '' : ' oclm-hidden') + '" type="text" id="oclm-base-dir-custom" aria-label="自定义数据目录" style="margin-top: 8px;" value="' + escapeAttr(baseDirValue) + '" placeholder="/mnt/硬盘目录/Configs/OpenClawMgr" />' +
        '<div class="oclm-hint" style="margin-top: 8px;">可选择已挂载硬盘上的目录，也可自定义。更换目录不会自动搬移已有数据。</div>' +
        '<div id="oclm-base-dir-error" class="oclm-security-error' + (formErrors.base_dir ? '' : ' oclm-hidden') + '">' + escapeHtml(formErrors.base_dir || "") + '</div>') +
      '<div class="oclm-section-submit">' +
      '<button class="oclm-button oclm-button-primary" type="button" id="oclm-save-basic"' + (savingBasic ? ' disabled' : '') + '>' + (savingBasic ? '应用中…' : '保存并应用') + '</button>' +
      (state.lastAppliedAt ? '<span class="oclm-applied-hint">已于 ' + escapeHtml(state.lastAppliedAt) + ' 更新配置</span>' : '') +
      '</div>' +
      '</div></div>' +

      '<div class="' + (activeTab === "ai" ? '' : 'oclm-hidden') + '">' +
      '<div class="oclm-section-heading"><h2>AI配置</h2><div class="oclm-hint">先配好一个能马上聊起来的默认 AI，再让openclaw协助你设置更多的AGENT、加角色等操作</div></div>' +
      '<div class="oclm-form-grid oclm-form-grid-ai">' +
      fieldInput("默认服务提供商", selectHtml("oclm-agent", form.default_agent, [
        ["openai", "OpenAI"],
        ["anthropic", "Anthropic"],
        ["minimax-cn", "MiniMax CN"],
        ["moonshot", "Moonshot CN"],
        ["custom-provider", "自定义供应商"]
      ]) + '<div class="oclm-hint">' + escapeHtml(form.default_agent === "custom-provider"
        ? "自定义供应商会写入独立的 custom-provider 配置，不会改动内置供应商。"
        : "如果你的供应商兼容 OpenAI 协议，可选择“自定义供应商”并在下方填写地址与模型。") + '</div>') +
      fieldInput("API 密钥", passwordHtml("oclm-api-key", form.provider_api_key || "", "sk-...")) +
      fieldInput(form.default_agent === "custom-provider" ? "服务地址" : "中转地址（可选）", '<input class="oclm-control" type="text" id="oclm-base-url" value="' + escapeHtml(form.provider_base_url || "") + '" placeholder="https://api.example.com" />') +
      fieldInput("默认模型", '<input class="oclm-control" type="text" id="oclm-model" value="' + escapeAttr(resolveModelValue(form)) + '" placeholder="' + escapeAttr(modelPlaceholder(form.default_agent)) + '" /><div class="oclm-hint">这里只填写模型名；例如 gpt-5.1</div>') +
      '<div class="oclm-section-submit"><button class="oclm-button oclm-button-primary" type="button" id="oclm-save-ai"' + (savingAi ? ' disabled' : '') + '>' + (savingAi ? '应用中…' : '保存 AI配置') + '</button>' + (state.lastAppliedAt ? '<span class="oclm-applied-hint">已于 ' + escapeHtml(state.lastAppliedAt) + ' 更新配置</span>' : '') + '</div>' +
      '</div></div>' +

      '<div class="' + (activeTab === "access" ? '' : 'oclm-hidden') + '">' +
      '<h2>访问控制</h2>' +
      '<div class="oclm-form-grid">' +
      fieldInput("访问令牌", passwordHtml("oclm-token", form.token || "", "")) +
      fieldInput("允许访问来源", '<div class="oclm-origin-list">' + origins +
        '<div class="oclm-origin-new"><input class="oclm-control" type="text" id="oclm-new-origin" value="' + escapeHtml(state.newOrigin || "") + '" placeholder="' + escapeHtml((options.default_origin || "http://192.168.1.1:18789")) + '" /><button class="oclm-button" type="button" id="oclm-add-origin">添加</button></div>' +
        '<div class="oclm-hint">展示：仅允许来源于该地址访问控制台的控制功能</div></div>') +
      fieldToggle("允许通过 HTTP 访问时认证", "allow_insecure_auth", form.allow_insecure_auth, "仅控制 HTTP 下的控制台认证，不影响端口监听") +
      fieldToggle("关闭设备身份校验", "disable_device_auth", form.disable_device_auth, "警告：仅建议在可信环境中开启，在内网生效") +
      '<div class="oclm-section-submit"><button class="oclm-button oclm-button-primary" type="button" id="oclm-save-access"' + (savingAccess ? ' disabled' : '') + '>' + (savingAccess ? '应用中…' : '保存访问控制设置') + '</button>' + (state.lastAppliedAt ? '<span class="oclm-applied-hint">已于 ' + escapeHtml(state.lastAppliedAt) + ' 更新配置</span>' : '') + '</div>' +
      '</div></div>' +

      '<div class="' + (activeTab === "security" ? '' : 'oclm-hidden') + '">' +
      '<div class="oclm-security-hero">' +
      '<h3 class="oclm-security-hero-title">🔒 禁止访问目录</h3>' +
      '<div class="oclm-hint">在 OpenClaw 以 ' + escapeHtml(security.runningUser) + ' 用户运行时禁止读取本地敏感目录。可能导致影响其他程序访问，请谨慎使用。</div>' +
      '</div>' +
      '<div class="oclm-security-stack">' +
      '<div class="oclm-security-card">' +
      '<div class="oclm-security-input-row">' +
      '<div class="oclm-security-input-wrap">' +
      '<input class="oclm-control' + (security.directoryError ? ' oclm-control-danger' : '') + '" type="text" id="oclm-security-path" value="' + escapeAttr(security.newDirectoryPath || "") + '" placeholder="/mnt/vio3-1/no-claw" />' +
      '<div id="oclm-security-error" class="oclm-security-error' + (security.directoryError ? '' : ' oclm-hidden') + '">' + escapeHtml(security.directoryError || "") + '</div>' +
      '<div class="oclm-hint">请输入绝对路径。不建议添加整个磁盘根目录或 OpenClaw 自身工作目录。</div>' +
      '</div>' +
      '<button class="oclm-button oclm-button-primary" type="button" id="oclm-security-add">添加目录</button>' +
      '</div>' +
      (security.protectedDirectories.length
        ? '<div class="oclm-security-list-box"><div class="oclm-security-list">' + securityList + '</div></div>'
        : '<div class="oclm-security-empty"><div class="oclm-security-empty-icon">🔒</div><div>暂无受保护的目录</div><div class="oclm-hint">添加目录以限制 OpenClaw 访问</div></div>') +
      '</div>' +
      '<div class="oclm-security-info-card">' +
      '<h3>ℹ 使用说明</h3>' +
      '<ul>' +
      '<li>本功能通过 Linux 文件权限限制 openclawmgr 用户访问目录。</li>' +
      '<li>本功能不是容器或沙箱隔离。</li>' +
      '<li>修改目录权限后，可能影响其他服务或用户访问这些目录。</li>' +
      '<li>请勿将 OpenClaw 的数据目录、程序目录加入禁止访问列表。</li>' +
      '</ul>' +
      '</div>' +
      '</div>' +
      '</div>' +

      '<div class="' + (activeTab === "version" ? '' : 'oclm-hidden') + '">' +
      '<div class="oclm-section-heading"><h2>版本管理</h2><div class="oclm-hint">openclaw 官方正在快速迭代，最新版本可能不兼容旧版本配置导致无法启动。请<a class="oclm-inline-link" href="https://www.koolcenter.com/t/topic/19042" target="_blank" rel="noreferrer noopener">加入交流群</a>了解最新稳定版本号</div></div>' +
      '<div class="oclm-form-grid">' +
      fieldInput("当前版本", '<div class="oclm-version-tags"><span class="oclm-tag">OpenClaw <strong>' + escapeHtml(status.openclaw_version || "-") + '</strong></span>' +
        (showUpdateAction ? '<button id="oclm-update-btn" class="oclm-button oclm-button-tag" type="button" data-update-action="1"' + (updateCheck.checking ? ' disabled' : '') + '>' + updateActionLabel(status) + '</button>' : '') +
        '</div>' +
        '<div class="oclm-status-note' + (versionNoteText() ? '' : ' oclm-hidden') + '">' + escapeHtml(versionNoteText()) + '</div>') +
      fieldInput("安装版本", selectHtml("oclm-install-channel", installChannel, [
        ["stable", "openclaw@2026.3.28(稳定版)"],
        ["latest", "openclaw@latest(最新版)"]
      ])) +
      '<div class="oclm-section-submit oclm-section-submit-right">' +
      '<button class="oclm-button oclm-button-primary" type="button" id="oclm-version-install" data-version-install-action="1"' + (status.installing ? ' disabled' : '') + '>' + installLabel + '</button>' +
      '</div>' +
      '</div></div>' +

      '<div class="' + (activeTab === "cleanup" ? '' : 'oclm-hidden') + '">' +
      '<h2>卸载清理</h2>' +
      '<div class="oclm-banner">以下操作会影响当前安装环境，请在确认后执行。</div>' +
      '<div class="oclm-danger-actions">' +
      '<button class="oclm-button" type="button" data-op="uninstall_openclaw">卸载 OpenClaw（保留 Node）</button>' +
      '<button class="oclm-button oclm-button-danger" type="button" data-op="uninstall">卸载</button>' +
      '<button class="oclm-button oclm-button-danger" type="button" data-op="purge">彻底清理</button>' +
      '</div>' +
      '</section>' +
      '</div></div></div>';

    syncActionDialog();
    bindEvents();
  }

  function updateStatusDom(status) {
    status = status || {};
    var gatewayActive = !!(status.running || status.reachable);

    function byId(id) {
      if (root.getElementById) return root.getElementById(id);
      return root.querySelector("#" + id);
    }

    var pill = byId("oclm-status-pill");
    var dot = byId("oclm-status-dot");
    var textEl = byId("oclm-status-text");
    if (!pill || !dot || !textEl) {
      render();
      return;
    }

    pill.style.setProperty("--oclm-spin-duration", statusSpinSeconds(status) + "s");
    dot.classList.remove("is-success");
    dot.classList.remove("is-danger");
    var cls = statusDotClass(status);
    if (cls) dot.classList.add(cls);
    textEl.textContent = statusText(status);

    var uptimeWrap = byId("oclm-uptime");
    var uptimeText = byId("oclm-uptime-text");
    if (uptimeWrap && uptimeText) {
      if (status.running && status.uptime_human) {
        uptimeText.textContent = String(status.uptime_human);
        uptimeWrap.classList.remove("oclm-hidden");
      } else {
        uptimeText.textContent = "";
        uptimeWrap.classList.add("oclm-hidden");
      }
    }

    var pidRow = byId("oclm-pid-row");
    var pidText = byId("oclm-pid");
    if (pidRow && pidText) {
      if (status.running && status.pid) {
        pidText.textContent = String(status.pid);
        pidRow.classList.remove("oclm-hidden");
      } else {
        pidText.textContent = "";
        pidRow.classList.add("oclm-hidden");
      }
    }

    var addrText = byId("oclm-address-text");
    if (addrText) addrText.textContent = maskedTokenUrl(status.token_url || status.base_url || "");
    var copyBtn = byId("oclm-copy-token-url");
    if (copyBtn) {
      if (status.token_url || status.base_url) copyBtn.classList.remove("oclm-hidden");
      else copyBtn.classList.add("oclm-hidden");
    }

    var baseDirEl = byId("oclm-status-base-dir");
    if (baseDirEl) baseDirEl.textContent = String(status.base_dir || "-");
    var openclawVerEl = byId("oclm-openclaw-version");
    if (openclawVerEl) openclawVerEl.textContent = String(status.openclaw_version || "-");
    var nodeVerEl = byId("oclm-node-version");
    if (nodeVerEl) nodeVerEl.textContent = String(status.node_version || "-");
    var runtimeInfo = status.runtime_info;
    var abiEl = byId("oclm-runtime-abi");
    var sourceEl = byId("oclm-runtime-source");
    var unknownEl = byId("oclm-runtime-unknown");
    if (abiEl) {
      abiEl.classList.toggle("oclm-hidden", !runtimeInfo);
      abiEl.textContent = runtimeInfo ? String(runtimeInfo.abi || "") + (runtimeInfo.libc && runtimeInfo.libc.version ? " " + runtimeInfo.libc.version : "") : "";
    }
    if (sourceEl) {
      sourceEl.classList.remove("oclm-hidden");
      sourceEl.title = String(runtimeInfo && runtimeInfo.instance || "");
    }
    if (unknownEl) {
      var preparation = status.runtime_preparation;
      unknownEl.classList.toggle("oclm-hidden", !!runtimeInfo && !(preparation && preparation.status === "failed") || !status.installed);
      unknownEl.textContent = preparation && preparation.error ? String(preparation.error) : "运行时需检查；可重启服务准备依赖";
    }

    var installInline = byId("oclm-install-inline");
    var installBtn = byId("oclm-install-btn");
    var updateBtn = byId("oclm-update-btn");
    var cancelInstallBtn = byId("oclm-cancel-install");
    var openConsoleBtn = byId("oclm-open-console");
    var noteEl = byId("oclm-status-note");
    var updateCheck = getUpdateCheck();

    var showInstallAction = !status.installed;
    var showUpdateAction = !!(status.installed && !status.installing);
    if (installInline) {
      if (showInstallAction) installInline.classList.remove("oclm-hidden");
      else installInline.classList.add("oclm-hidden");
    }
    if (installBtn) {
      installBtn.textContent = status.installing ? (status.task_op === "upgrade" ? "更新中" : "安装中") : "立即安装";
      installBtn.disabled = !!status.installing;
    }
    if (updateBtn) {
      updateBtn.textContent = updateActionLabel(status);
      updateBtn.disabled = !!updateCheck.checking;
      if (showUpdateAction) updateBtn.classList.remove("oclm-hidden");
      else updateBtn.classList.add("oclm-hidden");
    }
    if (cancelInstallBtn) {
      if (status.installing) cancelInstallBtn.classList.remove("oclm-hidden");
      else cancelInstallBtn.classList.add("oclm-hidden");
    }
    if (openConsoleBtn) {
      if (gatewayActive) openConsoleBtn.classList.remove("oclm-hidden");
      else openConsoleBtn.classList.add("oclm-hidden");
      openConsoleBtn.disabled = !state.consoleReady;
      openConsoleBtn.innerHTML = openclawIcon("oclm-button-icon") + (state.consoleReady ? "打开控制台" : "控制台准备中…");
    }
    if (noteEl) {
      var noteText = statusNoteText(status);
      noteEl.textContent = noteText;
      if (noteText) noteEl.classList.remove("oclm-hidden");
      else noteEl.classList.add("oclm-hidden");
    }

    var svcWrap = byId("oclm-service-actions");
    var btnStart = byId("oclm-btn-start");
    var btnStop = byId("oclm-btn-stop");
    var btnRestart = byId("oclm-btn-restart");
    var showServiceActions = !!(status.installed && !status.installing);
    var canStartService = !!(!status.running && !status.reachable);
    var canStopService = !!status.running;

    if (svcWrap) {
      if (showServiceActions) svcWrap.classList.remove("oclm-hidden");
      else svcWrap.classList.add("oclm-hidden");
    }
    if (btnStart) {
      if (showServiceActions && canStartService) btnStart.classList.remove("oclm-hidden");
      else btnStart.classList.add("oclm-hidden");
    }
    if (btnStop) {
      if (showServiceActions && canStopService) btnStop.classList.remove("oclm-hidden");
      else btnStop.classList.add("oclm-hidden");
    }
    if (btnRestart) {
      if (showServiceActions) btnRestart.classList.remove("oclm-hidden");
      else btnRestart.classList.add("oclm-hidden");
    }
  }

  function fieldInput(label, control) {
    return '<div class="oclm-field"><div class="oclm-label">' + label + '</div><div>' + control + '</div></div>';
  }

  function fieldToggle(label, key, checked, hint) {
    return '' +
      '<div class="oclm-field">' +
      '<div class="oclm-label">' + label + '</div>' +
      '<div><label class="oclm-toggle"><input type="checkbox" id="oclm-' + key + '"' + (checked ? ' checked' : '') + ' /><span class="oclm-toggle-track"></span></label>' +
      (hint ? '<div class="oclm-hint">' + hint + '</div>' : '') +
      '</div></div>';
  }

  function selectHtml(id, value, items) {
    return '<select class="oclm-select" id="' + id + '">' + items.map(function(item) {
      return '<option value="' + escapeHtml(item[0]) + '"' + (value === item[0] ? ' selected' : '') + '>' + escapeHtml(item[1]) + '</option>';
    }).join("") + '</select>';
  }

  function passwordHtml(id, value, placeholder) {
    return '' +
      '<div class="oclm-password-wrap">' +
      '<input class="oclm-control" type="password" id="' + id + '" value="' + escapeAttr(value || "") + '" placeholder="' + escapeAttr(placeholder || "") + '" />' +
      '<button class="oclm-button oclm-eye-button" type="button" data-toggle-password="' + id + '" aria-label="显示密钥">' + eyeIcon(false) + '</button>' +
      '</div>';
  }

  function eyeIcon(off) {
    if (off) {
      return '' +
        '<svg viewBox="0 0 24 24" aria-hidden="true">' +
        '<path d="M3 3l18 18"></path>' +
        '<path d="M10.6 10.7a3 3 0 0 0 4.2 4.2"></path>' +
        '<path d="M9.9 5.1A10.9 10.9 0 0 1 12 5c5.2 0 9.3 4.1 10 7-0.3 1.1-1.1 2.6-2.4 3.9"></path>' +
        '<path d="M6.2 6.2C4.3 7.6 3.2 9.6 2 12c0.7 2.9 4.8 7 10 7 1 0 2-.2 2.9-.5"></path>' +
      '</svg>';
    }
    return '' +
      '<svg viewBox="0 0 24 24" aria-hidden="true">' +
      '<path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7-10-7-10-7z"></path>' +
      '<circle cx="12" cy="12" r="3"></circle>' +
      '</svg>';
  }

  function baseDirFromDom() {
    var selected = root.getElementById("oclm-base-dir");
    var custom = root.getElementById("oclm-base-dir-custom");
    return selected && selected.value === "__custom__" ? (custom ? custom.value : "") : (selected ? selected.value : "");
  }

  function syncDraftFromDom() {
    if (!state.form) {
      state.form = {};
    }

    function getEl(id) {
      return root.getElementById ? root.getElementById(id) : root.querySelector("#" + id);
    }

    var portEl = getEl("oclm-port");
    if (portEl) state.form.port = portEl.value;

    var bindEl = getEl("oclm-bind");
    if (bindEl) state.form.bind = bindEl.value;

    var baseDirEl = getEl("oclm-base-dir");
    if (baseDirEl) state.form.base_dir = baseDirFromDom();

    var installAccelEl = getEl("oclm-install-accelerated");
    if (installAccelEl) state.form.install_accelerated = !!installAccelEl.checked;

    var installChannelEl = getEl("oclm-install-channel");
    if (installChannelEl) state.form.install_channel = installChannelEl.value === "latest" ? "latest" : "stable";

    var agentEl = getEl("oclm-agent");
    if (agentEl) state.form.default_agent = agentEl.value;

    var apiKeyEl = getEl("oclm-api-key");
    if (apiKeyEl) state.form.provider_api_key = apiKeyEl.value;

    var baseUrlEl = getEl("oclm-base-url");
    if (baseUrlEl) state.form.provider_base_url = baseUrlEl.value;

    var modelEl = getEl("oclm-model");
    if (modelEl) state.form.default_model = modelEl.value;

    var tokenEl = getEl("oclm-token");
    if (tokenEl) state.form.token = tokenEl.value;

    var allowInsecureEl = getEl("oclm-allow_insecure_auth");
    if (allowInsecureEl) state.form.allow_insecure_auth = !!allowInsecureEl.checked;

    var disableDeviceEl = getEl("oclm-disable_device_auth");
    if (disableDeviceEl) state.form.disable_device_auth = !!disableDeviceEl.checked;

    var newOriginEl = getEl("oclm-new-origin");
    if (newOriginEl) state.newOrigin = newOriginEl.value;

    var securityPathEl = getEl("oclm-security-path");
    if (securityPathEl) getSecurityState().newDirectoryPath = securityPathEl.value;

  }

  function bindEvents() {
    Array.prototype.forEach.call(root.querySelectorAll("[data-tab]"), function(el) {
      el.onclick = function() {
        syncDraftFromDom();
        state.activeTab = el.getAttribute("data-tab") || "basic";
        render();
      };
    });

    Array.prototype.forEach.call(root.querySelectorAll("[data-op]"), function(el) {
      el.onclick = function() {
        var op = el.getAttribute("data-op");
        if (!op) return;
        if (op === "uninstall_openclaw" && !window.confirm("卸载 OpenClaw 运行时但保留 Node.js，确认继续？")) return;
        if (op === "uninstall" && !window.confirm("卸载将删除运行时，但保留数据目录。确认继续？")) return;
        if (op === "purge" && !window.confirm("彻底清理会删除运行时和数据目录。确认继续？")) return;
        postForm(config.opUrl, { op: op }).then(function(rv) {
          if (!rv || !rv.ok) {
            if (rv && rv.busy && rv.running_task_id) {
              showTaskLog(rv.running_task_id);
              return;
            }
            openNoticeDialog((rv && rv.error) || "操作失败");
            return;
          }
          state.lastTaskRunning = true;
          showTaskLog((rv && (rv.running_task_id || rv.task_id)) || "openclawmgr");
          scheduleStatusRefresh(op === "restart" ? 8 : 6, 1000);
        });
      };
    });

    Array.prototype.forEach.call(root.querySelectorAll("[data-open-console]"), function(el) {
      el.onclick = function() {
        if (!state.consoleReady) {
          openNoticeDialog("控制台正在启动，请稍候再试。");
          return;
        }
        var url = (state.status && state.status.token_url) || "";
        if (!url) {
          openNoticeDialog("控制台地址不可用");
          return;
        }
        window.open(url, "_blank", "noreferrer");
      };
    });

    Array.prototype.forEach.call(root.querySelectorAll("[data-install-action]"), function(el) {
      el.onclick = function() {
        var accelerated = !!(root.getElementById("oclm-install-accelerated") && root.getElementById("oclm-install-accelerated").checked);
        var installChannel = (root.getElementById("oclm-install-channel") && root.getElementById("oclm-install-channel").value === "latest") ? "latest" : ((state.form && state.form.install_channel === "latest") ? "latest" : "stable");
        var baseDirEl = root.getElementById("oclm-base-dir");
        var baseDir = baseDirEl && baseDirEl.value ? baseDirEl.value.trim() : "";
        if (!baseDir) {
          openNoticeDialog("请先选择数据目录并保存应用，再执行安装。");
          if (baseDirEl) baseDirEl.focus();
          return;
        }
        if (!state.status || state.status.installing) {
          return;
        }
        state.status.installing = true;
        state.status.task_running = true;
        state.status.task_op = "install";
        render();
        postJson(config.configUrl, { base_dir: baseDir, install_accelerated: accelerated }).then(function(cfgRv) {
          if (!cfgRv || !cfgRv.ok) {
            state.status.installing = false;
            render();
            openNoticeDialog((cfgRv && cfgRv.error) || "保存安装选项失败");
            return;
          }
          state.form.install_accelerated = accelerated;
          state.form.install_channel = installChannel;
          state.form.base_dir = baseDir;
          return postForm(config.opUrl, { op: "install", install_channel: installChannel });
        }).then(function(rv) {
          if (!rv) return;
          if (!rv || !rv.ok) {
            if (rv && rv.busy && rv.running_task_id) {
              showTaskLog(rv.running_task_id);
              return;
            }
            state.status.installing = false;
            render();
            openNoticeDialog((rv && rv.error) || "启动安装失败");
            return;
          }
          state.lastTaskRunning = true;
          showTaskLog((rv && (rv.running_task_id || rv.task_id)) || "openclawmgr");
          scheduleStatusRefresh(10, 1000);
        }).catch(function() {
          state.status.installing = false;
          render();
          openNoticeDialog("启动安装失败");
        });
      };
    });

    Array.prototype.forEach.call(root.querySelectorAll("[data-version-install-action]"), function(el) {
      el.onclick = function() {
        var accelerated = !!(root.getElementById("oclm-install-accelerated") && root.getElementById("oclm-install-accelerated").checked);
        var installChannel = (root.getElementById("oclm-install-channel") && root.getElementById("oclm-install-channel").value === "latest") ? "latest" : "stable";
        var baseDirEl = root.getElementById("oclm-base-dir");
        var baseDir = baseDirEl && baseDirEl.value ? baseDirEl.value.trim() : "";
        var op = (state.status && state.status.installed) ? "upgrade" : "install";
        if (!baseDir) {
          openNoticeDialog("请先选择数据目录并保存应用，再执行安装。");
          if (baseDirEl) baseDirEl.focus();
          return;
        }
        if (!state.status || state.status.installing) {
          return;
        }
        state.status.installing = true;
        state.status.task_running = true;
        state.status.task_op = op;
        render();
        postJson(config.configUrl, { base_dir: baseDir, install_accelerated: accelerated }).then(function(cfgRv) {
          if (!cfgRv || !cfgRv.ok) {
            state.status.installing = false;
            state.status.task_running = false;
            state.status.task_op = "";
            render();
            openNoticeDialog((cfgRv && cfgRv.error) || "保存安装选项失败");
            return;
          }
          state.form.install_accelerated = accelerated;
          state.form.install_channel = installChannel;
          state.form.base_dir = baseDir;
          return postForm(config.opUrl, { op: op, install_channel: installChannel });
        }).then(function(rv) {
          if (!rv) return;
          if (!rv.ok) {
            if (rv.busy && rv.running_task_id) {
              showTaskLog(rv.running_task_id);
              return;
            }
            state.status.installing = false;
            state.status.task_running = false;
            state.status.task_op = "";
            render();
            openNoticeDialog((rv && rv.error) || "启动安装失败");
            return;
          }
          state.lastTaskRunning = true;
          showTaskLog((rv && (rv.running_task_id || rv.task_id)) || "openclawmgr");
          scheduleStatusRefresh(10, 1000);
        }).catch(function() {
          state.status.installing = false;
          state.status.task_running = false;
          state.status.task_op = "";
          render();
          openNoticeDialog("启动安装失败");
        });
      };
    });

    Array.prototype.forEach.call(root.querySelectorAll("[data-update-action]"), function(el) {
      el.onclick = function() {
        var updateCheck = getUpdateCheck();
        if (!state.status || !state.status.installed || state.status.installing) {
          return;
        }

        updateCheck.checking = true;
        updateCheck.error = "";
        render();
        postForm(config.checkUpdateUrl, {}).then(function(rv) {
          updateCheck.checking = false;
          if (!rv || !rv.ok) {
            updateCheck.checked = false;
            updateCheck.hasUpdate = false;
            updateCheck.error = (rv && rv.error) || "检测更新失败";
            updateCheck.localVersion = String((rv && rv.local_version) || (state.status && state.status.openclaw_version) || "");
            updateCheck.remoteVersion = String((rv && rv.remote_version) || "");
            render();
            openNoticeDialog(updateCheck.error);
            return;
          }
          updateCheck.checked = true;
          updateCheck.hasUpdate = !!rv.has_update;
          updateCheck.error = "";
          updateCheck.localVersion = String(rv.local_version || (state.status && state.status.openclaw_version) || "");
          updateCheck.remoteVersion = String(rv.remote_version || "");
          render();
        }).catch(function() {
          updateCheck.checking = false;
          updateCheck.checked = false;
          updateCheck.hasUpdate = false;
          updateCheck.error = "检测更新失败";
          render();
          openNoticeDialog("检测更新失败");
        });
      };
    });

    Array.prototype.forEach.call(root.querySelectorAll("[data-toggle-password]"), function(el) {
      el.onclick = function() {
        var id = el.getAttribute("data-toggle-password");
        var input = id ? root.getElementById(id) : null;
        if (!input) return;
        input.type = input.type === "password" ? "text" : "password";
        el.innerHTML = eyeIcon(input.type !== "password");
        el.setAttribute("aria-label", input.type === "password" ? "显示密钥" : "隐藏密钥");
      };
    });

    var installAccelerated = root.getElementById("oclm-install-accelerated");
    if (installAccelerated) {
      installAccelerated.onchange = function() {
        state.form.install_accelerated = !!installAccelerated.checked;
      };
    }

    var installChannel = root.getElementById("oclm-install-channel");
    if (installChannel) {
      installChannel.onchange = function() {
        state.form.install_channel = installChannel.value === "latest" ? "latest" : "stable";
      };
    }

    Array.prototype.forEach.call(root.querySelectorAll("[data-copy-token-url]"), function(el) {
      el.onclick = function() {
        var value = (state.status && (state.status.token_url || state.status.base_url)) || "";
        copyText(value).then(function(ok) {
          if (ok) {
            flashCopied(el);
          }
        });
      };
    });

    var agent = root.getElementById("oclm-agent");
    if (agent) {
      agent.onchange = function() {
        syncDraftFromDom();
      state.form.default_agent = agent.value;
      state.form.default_model = defaultModelForAgent(agent.value);
      render();
    };
  }

    var apiKey = root.getElementById("oclm-api-key");
    if (apiKey) {
      apiKey.oninput = function() {
        state.form.provider_api_key = apiKey.value;
      };
    }

    var baseUrl = root.getElementById("oclm-base-url");
    if (baseUrl) {
      baseUrl.oninput = function() {
        state.form.provider_base_url = baseUrl.value;
      };
    }

    var modelInput = root.getElementById("oclm-model");
    if (modelInput) {
      modelInput.oninput = function() {
        state.form.default_model = modelInput.value;
      };
    }

    var addOrigin = root.getElementById("oclm-add-origin");
    if (addOrigin) {
      addOrigin.onclick = function() {
        var input = root.getElementById("oclm-new-origin");
        var value = input && input.value ? input.value.trim() : "";
        if (!value) return;
        state.form.allowed_origins = Array.isArray(state.form.allowed_origins) ? state.form.allowed_origins : [];
        state.form.allowed_origins.push(value);
        state.newOrigin = "";
        render();
      };
    }

    var newOrigin = root.getElementById("oclm-new-origin");
    if (newOrigin) {
      newOrigin.oninput = function() {
        state.newOrigin = newOrigin.value;
      };
    }

    Array.prototype.forEach.call(root.querySelectorAll("[data-remove-origin]"), function(el) {
      el.onclick = function() {
        var index = parseInt(el.getAttribute("data-remove-origin"), 10);
        if (isNaN(index)) return;
        state.form.allowed_origins.splice(index, 1);
        render();
      };
    });

    Array.prototype.forEach.call(root.querySelectorAll("[data-origin-index]"), function(el) {
      el.oninput = function() {
        var index = parseInt(el.getAttribute("data-origin-index"), 10);
        if (!isNaN(index)) {
          state.form.allowed_origins[index] = el.value;
        }
      };
    });

    var securityPath = root.getElementById("oclm-security-path");
    if (securityPath) {
      securityPath.oninput = function() {
        var security = getSecurityState();
        security.newDirectoryPath = securityPath.value;
        if (security.directoryError) {
          security.directoryError = "";
          securityPath.classList.remove("oclm-control-danger");
          var errorEl = root.getElementById("oclm-security-error");
          if (errorEl) {
            errorEl.textContent = "";
            errorEl.classList.add("oclm-hidden");
          }
        }
      };
    }

    var securityAdd = root.getElementById("oclm-security-add");
    if (securityAdd) {
      securityAdd.onclick = function() {
        var security = getSecurityState();
        var path = securityPath && securityPath.value ? securityPath.value.replace(/^\s+|\s+$/g, "") : "";
        var error = validateProtectedDirectory(path);
        if (error) {
          security.directoryError = error;
          render();
          return;
        }
        security.pendingAddPath = path;
        render();
      };
    }

    Array.prototype.forEach.call(root.querySelectorAll("[data-security-recheck]"), function(el) {
      el.onclick = function() {
        var id = el.getAttribute("data-security-recheck");
        if (!id) return;
        postJson(config.securityRecheckUrl, { id: id }).then(function(rv) {
          if (!rv || !rv.ok) {
            openNoticeDialog((rv && rv.error) || "重新检测失败");
            return;
          }
          loadSecurityData();
        }).catch(function() {
          openNoticeDialog("重新检测失败");
        });
      };
    });

    Array.prototype.forEach.call(root.querySelectorAll("[data-security-delete]"), function(el) {
      el.onclick = function() {
        var id = el.getAttribute("data-security-delete");
        if (!id) return;
        var security = getSecurityState();
        var target = null;
        security.protectedDirectories.forEach(function(item) {
          if (item.id === id) {
            target = item;
          }
        });
        if (!target) return;
        security.deleteTargetId = id;
        security.deleteTargetPath = target.path;
        render();
      };
    });

    var saveBasic = root.getElementById("oclm-save-basic");
    var baseDirInput = root.getElementById("oclm-base-dir");
    if (baseDirInput) {
      baseDirInput.onchange = function() {
        syncDraftFromDom();
        state.customBaseDir = baseDirInput.value === "__custom__";
        if (!state.customBaseDir) state.form.base_dir = baseDirInput.value;
        getFormErrors().base_dir = "";
        render();
        if (state.customBaseDir) root.getElementById("oclm-base-dir-custom").focus();
      };
    }
    var baseDirCustomInput = root.getElementById("oclm-base-dir-custom");
    if (baseDirCustomInput) {
      baseDirCustomInput.oninput = function() {
        state.form.base_dir = baseDirCustomInput.value;
        var formErrors = getFormErrors();
        if (formErrors.base_dir) {
          formErrors.base_dir = "";
          render();
        }
      };
    }
    if (saveBasic) {
      saveBasic.onclick = function() {
        var formErrors = getFormErrors();
        var baseDirValue = baseDirFromDom();
        if (!String(baseDirValue || "").replace(/^\s+|\s+$/g, "")) {
          formErrors.base_dir = "数据目录不能为空";
          render();
          return;
        }
        formErrors.base_dir = "";
        var payload = {
          port: root.getElementById("oclm-port").value,
          bind: root.getElementById("oclm-bind").value,
          base_dir: baseDirValue,
          install_accelerated: !!(root.getElementById("oclm-install-accelerated") && root.getElementById("oclm-install-accelerated").checked),
        };
        state.savingSection = "basic";
        render();
        postJson(config.configUrl, payload).then(function(rv) { handleSaveResult(rv, "basic"); }).catch(function() {
          state.savingSection = "";
          render();
          openNoticeDialog("保存失败");
        });
      };
    }

    var saveAi = root.getElementById("oclm-save-ai");
    if (saveAi) {
      saveAi.onclick = function() {
        var agentValue = root.getElementById("oclm-agent").value;
        var modelValue = normalizeModelValue(root.getElementById("oclm-model").value, defaultModelForAgent(agentValue));
        var baseUrlValue = root.getElementById("oclm-base-url").value;
        if (agentValue === "custom-provider" && !String(baseUrlValue || "").replace(/^\s+|\s+$/g, "")) {
          openNoticeDialog("自定义供应商必须填写服务地址");
          return;
        }
        var payload = {
          default_agent: agentValue,
          default_model: modelValue,
          provider_api_key: root.getElementById("oclm-api-key").value,
          provider_base_url: baseUrlValue
        };
        state.form.default_agent = agentValue;
        state.form.default_model = modelValue;
        state.savingSection = "ai";
        render();
        postJson(config.configUrl, payload).then(function(rv) { handleSaveResult(rv, "ai"); }).catch(function() {
          state.savingSection = "";
          render();
          openNoticeDialog("保存失败");
        });
      };
    }

    var saveAccess = root.getElementById("oclm-save-access");
    if (saveAccess) {
      saveAccess.onclick = function() {
        var payload = {
          token: root.getElementById("oclm-token").value,
          allowed_origins: (Array.isArray(state.form.allowed_origins) ? state.form.allowed_origins : []).map(function(item) { return item.trim(); }).filter(Boolean),
          allow_insecure_auth: !!root.getElementById("oclm-allow_insecure_auth").checked,
          disable_device_auth: !!root.getElementById("oclm-disable_device_auth").checked
        };
        state.savingSection = "access";
        render();
        postJson(config.configUrl, payload).then(function(rv) { handleSaveResult(rv, "access"); }).catch(function() {
          state.savingSection = "";
          render();
          openNoticeDialog("保存失败");
        });
      };
    }
  }

  function handleSaveResult(rv, section) {
    if (!rv || !rv.ok) {
      var formErrors = getFormErrors();
      state.savingSection = "";
      if (section === "basic" && isBaseDirErrorMessage(rv && rv.error)) {
        formErrors.base_dir = (rv && rv.error) || "数据目录错误";
        render();
        return;
      }
      render();
      openNoticeDialog((rv && rv.error) || "保存失败");
      return;
    }
    if (section === "basic") {
      getFormErrors().base_dir = "";
    }
    postForm(config.applyUrl, {}).then(function(applyRv) {
      state.savingSection = "";
      if (!applyRv || !applyRv.ok) {
        render();
        openNoticeDialog((applyRv && applyRv.error) || "应用配置失败");
        loadConfig();
        scheduleStatusRefresh(3, 600);
        return;
      }
      state.lastAppliedAt = applyRv.applied_at || "";
      render();
      loadConfig();
      scheduleStatusRefresh(6, 800);
    }).catch(function() {
      state.savingSection = "";
      render();
      openNoticeDialog("应用配置失败");
      loadConfig();
      scheduleStatusRefresh(3, 600);
    });
  }

  function refreshStatus(done) {
    request(config.statusUrl).then(function(data) {
      state.status = data || {};
      var updateCheck = getUpdateCheck();
      if (state.status && state.status.openclaw_version) {
        updateCheck.localVersion = String(state.status.openclaw_version || "");
      }
      if (!state.status || !state.status.installed) {
        updateCheck.hasUpdate = false;
        updateCheck.checked = false;
      } else if (!state.status.installing) {
        if (updateCheck.remoteVersion && updateCheck.localVersion && updateCheck.remoteVersion === updateCheck.localVersion) {
          updateCheck.hasUpdate = false;
          updateCheck.checked = true;
          updateCheck.error = "";
        }
      }
      if (state.status && (state.status.running || state.status.reachable)) {
        if (!state.consoleReady) {
          pollConsoleReady(20);
        }
      } else {
        stopConsoleCheck();
        state.consoleReady = false;
      }
      if (state.status && state.status.task_running && !state.lastTaskRunning) {
        showTaskLog("openclawmgr");
      }
      state.lastTaskRunning = !!(state.status && state.status.task_running);
      updateStatusDom(state.status);
      ensureInstallWatch();
      if (typeof done === "function") {
        done();
      }
    }).catch(function() {
      state.status = state.status || {};
      updateStatusDom(state.status);
      ensureInstallWatch();
      if (typeof done === "function") {
        done();
      }
    });
  }

  function loadConfig() {
    request(config.configUrl).then(function(data) {
      if (!data || !data.ok) {
        return;
      }
      var currentInstallChannel = state.form && state.form.install_channel === "latest" ? "latest" : "stable";
      state.form = data.config || {};
      state.configuredBaseDir = String(state.form.base_dir || "");
      state.customBaseDir = false;
      state.form.install_channel = currentInstallChannel;
      state.form.default_model = resolveModelValue(state.form);
      state.options = data.options || {};
      if (!state.form.base_dir) {
        var suggested = state.options && state.options.suggested_base_dir ? String(state.options.suggested_base_dir) : "";
        if (suggested) {
          state.form.base_dir = suggested;
        }
      }
      render();
      loadSecurityData();
      refreshStatus();
    }).catch(function() {
      state.form = state.form || {};
      state.options = state.options || { base_dir_choices: [] };
      render();
      loadSecurityData();
    });
  }

  fetch(config.staticBase + "/app.css").then(function(r) { return r.text(); }).then(function(css) {
    styleText = css || "";
    loadConfig();
  });
})();
