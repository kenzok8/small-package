const stateByElement = new WeakMap();

function normalizeBasePath(path) {
  const value = typeof path === "string" && path.trim() ? path.trim() : "/apps/kspeeder/";
  return value.endsWith("/") ? value : `${value}/`;
}

function normalizeAPIBase(context) {
  if (context && typeof context.apiBase === "string" && context.apiBase.trim()) {
    return context.apiBase.endsWith("/") ? context.apiBase : `${context.apiBase}/`;
  }
  return `${normalizeBasePath(context && context.basePath)}api/`;
}

function escapeHTML(value) {
  return String(value == null ? "" : value).replace(/[&<>"']/g, (char) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  })[char]);
}

async function fetchJSON(url, options) {
  const response = await fetch(url, {
    credentials: "same-origin",
    headers: { Accept: "application/json" },
    ...options,
  });
  const text = await response.text();
  let payload = null;
  if (text) {
    try {
      payload = JSON.parse(text);
    } catch (error) {
      throw new Error(`API returned non-JSON response (${response.status})`);
    }
  }
  if (!response.ok) {
    const message = payload && (payload.message || payload.error || payload.details);
    throw new Error(message || `API request failed (${response.status})`);
  }
  return payload || {};
}

function mirrorCounts(overview) {
  const mirrorsByProfile = overview && typeof overview.mirrors === "object" ? overview.mirrors : {};
  const result = { online: 0, total: 0, servedSpeed: "", servedDownload: "" };
  Object.values(mirrorsByProfile).forEach((profile) => {
    const mirrors = Array.isArray(profile && profile.mirrors) ? profile.mirrors : [];
    result.total += mirrors.length;
    result.online += mirrors.filter((mirror) => mirror && mirror.status === "online").length;
    if (!result.servedSpeed && profile && profile.served_speed) {
      result.servedSpeed = profile.served_speed;
    }
    if (!result.servedDownload && profile && profile.served_download) {
      result.servedDownload = profile.served_download;
    }
  });
  return result;
}

function profileRows(overview) {
  const mirrorsByProfile = overview && typeof overview.mirrors === "object" ? overview.mirrors : {};
  return Object.entries(mirrorsByProfile).map(([profile, status]) => {
    const mirrors = Array.isArray(status && status.mirrors) ? status.mirrors : [];
    const online = mirrors.filter((mirror) => mirror && mirror.status === "online").length;
    const best = mirrors.find((mirror) => mirror && mirror.status === "online") || mirrors[0] || {};
    return `
      <tr>
        <td>${escapeHTML(profile)}</td>
        <td>${online}/${mirrors.length}</td>
        <td>${escapeHTML(best.current_speed || best.test_speed || "-")}</td>
        <td>${escapeHTML(best.name || "-")}</td>
        <td>${escapeHTML(best.error_info || "-")}</td>
      </tr>
    `;
  }).join("");
}

function render(root, model) {
  const counts = mirrorCounts(model.overview);
  const source = model.overview && model.overview.source ? model.overview.source : "-";
  const error = model.error ? `<div class="notice danger">${escapeHTML(model.error)}</div>` : "";
  const refreshing = model.refreshing ? "disabled" : "";
  const rows = profileRows(model.overview);
  root.innerHTML = `
    <style>
      :host { color-scheme: light; }
      .ks-page { box-sizing: border-box; min-height: 100%; background: #f7f8fa; color: #1f2937; font: 14px/1.45 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
      .ks-wrap { box-sizing: border-box; max-width: 1080px; margin: 0 auto; padding: 18px; }
      .ks-top { display: flex; align-items: flex-start; justify-content: space-between; gap: 14px; margin-bottom: 14px; }
      h1 { margin: 0; font-size: 20px; line-height: 1.2; font-weight: 650; color: #111827; }
      .sub { margin-top: 5px; color: #667085; font-size: 13px; }
      .actions { display: flex; flex-wrap: wrap; gap: 8px; justify-content: flex-end; }
      button { border: 1px solid #cfd7e3; background: #fff; color: #1f2937; border-radius: 6px; padding: 7px 10px; font-size: 13px; cursor: pointer; }
      button.primary { background: #0f766e; border-color: #0f766e; color: #fff; }
      button:disabled { cursor: wait; opacity: .62; }
      .grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; }
      .card { border: 1px solid #e2e8f0; border-radius: 8px; background: #fff; padding: 12px; min-width: 0; }
      .label { color: #667085; font-size: 12px; margin-bottom: 6px; }
      .value { font-size: 18px; font-weight: 650; color: #111827; overflow-wrap: anywhere; }
      .notice { border-radius: 8px; padding: 10px 12px; margin-bottom: 12px; background: #fff7ed; border: 1px solid #fed7aa; color: #9a3412; }
      .notice.danger { background: #fef2f2; border-color: #fecaca; color: #b91c1c; }
      .section { margin-top: 12px; border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden; background: #fff; }
      .section-title { display: flex; justify-content: space-between; gap: 10px; padding: 11px 12px; border-bottom: 1px solid #e2e8f0; font-weight: 650; }
      table { width: 100%; border-collapse: collapse; table-layout: fixed; }
      th, td { padding: 9px 12px; border-bottom: 1px solid #edf2f7; text-align: left; vertical-align: top; overflow-wrap: anywhere; }
      th { color: #667085; font-size: 12px; font-weight: 600; background: #fbfcfd; }
      tr:last-child td { border-bottom: 0; }
      .empty { padding: 18px 12px; color: #667085; }
      @media (max-width: 720px) {
        .ks-wrap { padding: 12px; }
        .ks-top { display: block; }
        .actions { justify-content: flex-start; margin-top: 10px; }
        .grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        th:nth-child(5), td:nth-child(5) { display: none; }
      }
      @media (max-width: 430px) {
        .grid { grid-template-columns: 1fr; }
        th:nth-child(4), td:nth-child(4) { display: none; }
      }
    </style>
    <div class="ks-page">
      <div class="ks-wrap">
        <div class="ks-top">
          <div>
            <h1>KSpeeder</h1>
            <div class="sub">Docker 镜像下载加速状态</div>
          </div>
          <div class="actions">
            <button data-action="reload">刷新</button>
            <button class="primary" data-action="refresh-mirrors" ${refreshing}>${model.refreshing ? "测速中" : "刷新测速"}</button>
          </div>
        </div>
        ${error}
        <div class="grid">
          <div class="card"><div class="label">版本</div><div class="value">${escapeHTML(model.summary.version || "-")}</div></div>
          <div class="card"><div class="label">可用节点</div><div class="value">${counts.online}/${counts.total}</div></div>
          <div class="card"><div class="label">当前下发</div><div class="value">${escapeHTML(counts.servedSpeed || "-")}</div></div>
          <div class="card"><div class="label">累计下发</div><div class="value">${escapeHTML(counts.servedDownload || "-")}</div></div>
        </div>
        <div class="section">
          <div class="section-title"><span>镜像节点</span><span>${escapeHTML(source)}</span></div>
          ${rows ? `
            <table>
              <thead>
                <tr>
                  <th>类型</th>
                  <th>在线</th>
                  <th>速度</th>
                  <th>节点</th>
                  <th>错误</th>
                </tr>
              </thead>
              <tbody>${rows}</tbody>
            </table>
          ` : '<div class="empty">暂无镜像状态，确认 iStoreEnhance 服务已启动并已配置缓存目录。</div>'}
        </div>
      </div>
    </div>
  `;
}

async function loadModel(state) {
  const [summary, overview] = await Promise.all([
    fetchJSON(`${state.apiBase}summary`),
    fetchJSON(`${state.apiBase}mirrors/overview`),
  ]);
  state.model.summary = summary;
  state.model.overview = overview;
  state.model.error = "";
}

async function reload(state) {
  try {
    await loadModel(state);
  } catch (error) {
    state.model.error = error instanceof Error ? error.message : "加载失败";
  } finally {
    render(state.root, state.model);
  }
}

async function refreshMirrors(state) {
  state.model.refreshing = true;
  state.model.error = "";
  render(state.root, state.model);
  try {
    await fetchJSON(`${state.apiBase}mirrors/refresh`, { method: "POST" });
    await loadModel(state);
    if (state.hostAdapter && state.hostAdapter.toast) {
      state.hostAdapter.toast.success("KSpeeder 测速已刷新");
    }
  } catch (error) {
    state.model.error = error instanceof Error ? error.message : "刷新测速失败";
    if (state.hostAdapter && state.hostAdapter.toast) {
      state.hostAdapter.toast.error(state.model.error);
    }
  } finally {
    state.model.refreshing = false;
    render(state.root, state.model);
  }
}

export async function bootstrap() {}

export async function mount(props) {
  const root = props && props.domElement;
  if (!root) {
    return;
  }
  const context = props.context || {};
  const state = {
    root,
    apiBase: normalizeAPIBase(context),
    hostAdapter: props.hostAdapter,
    model: {
      summary: {},
      overview: {},
      error: "",
      refreshing: false,
    },
  };
  stateByElement.set(root, state);
  root.addEventListener("click", handleClick);
  render(root, state.model);
  await reload(state);
}

export async function unmount(props) {
  const root = props && props.domElement;
  if (!root) {
    return;
  }
  root.removeEventListener("click", handleClick);
  root.innerHTML = "";
  stateByElement.delete(root);
}

function handleClick(event) {
  const target = event.target && event.target.closest ? event.target.closest("[data-action]") : null;
  if (!target) {
    return;
  }
  const root = event.currentTarget;
  const state = stateByElement.get(root);
  if (!state) {
    return;
  }
  const action = target.getAttribute("data-action");
  if (action === "reload") {
    void reload(state);
  } else if (action === "refresh-mirrors") {
    void refreshMirrors(state);
  }
}

export default { bootstrap, mount, unmount };
