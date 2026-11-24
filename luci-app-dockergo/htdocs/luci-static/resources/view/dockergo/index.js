'use strict';
'require view';

function loadModule(src) {
	if (window.DockerGoMount)
		return Promise.resolve();

	return new Promise(function(resolve, reject) {
		const script = document.createElement('script');
		script.type = 'module';
		script.src = src;
		script.onload = resolve;
		script.onerror = function() {
			reject(new Error('无法加载 DockerGo 前端模块'));
		};
		document.head.appendChild(script);
	});
}

function loadStylesheet(id, href) {
	if (document.getElementById(id))
		return;

	const link = document.createElement('link');
	link.id = id;
	link.rel = 'stylesheet';
	link.href = href;
	document.head.appendChild(link);
}

function loadClassicScript(src, ready) {
	if (ready())
		return Promise.resolve();

	return new Promise(function(resolve, reject) {
		const script = document.createElement('script');
		script.src = src;
		script.onload = resolve;
		script.onerror = function() {
			reject(new Error('无法加载系统任务日志组件'));
		};
		document.head.appendChild(script);
	});
}

function loadTaskDialog() {
	loadStylesheet('dockergo-xterm-style', L.resource('xterm/xterm.css'));
	loadStylesheet('dockergo-taskd-style', L.resource('tasks/tasks.css'));

	return loadClassicScript(L.resource('xterm/xterm.js'), function() {
		return typeof window.Terminal === 'function';
	}).then(function() {
		return loadClassicScript(L.resource('tasks/tasks.js'), function() {
			return Boolean(window.taskd && window.taskd.show_log);
		});
	}).then(function() {
		window.taskd.csrfToken = L.env.token;
		window.taskd.show_mask_on_stopped = true;
		window.taskd.i18n = {
			'Stop running task?': '停止正在运行的任务？',
			'Finished at:': '完成于：',
			'Failed at:': '失败于：',
			'Lost login status': '登录状态已失效',
			'Fetch log failed, retrying...': '日志获取失败，正在重试…',
			'Task does not exist or has been deleted': '任务不存在或已删除'
		};
		window.taskd.dialog_template = `
			<div id="tasks_dialog">
				<div class="dialog-title-bar">
					<span class="dialog-title" id="tasks_id"></span>
					<span class="dialog-icons">
						<span class="dialog-icon dialog-icon-close" title="停止并关闭"></span>
						<span class="dialog-icon dialog-icon-min" title="隐藏"></span>
					</span>
				</div>
				<div class="dialog-content">
					<div id="tasks_xterm_log"></div>
					<div id="tasks_result_mask">
						<span class="tasks_result_success">任务执行成功</span>
						<span class="tasks_result_failed">任务执行失败</span>
						<br>
						<span>点击右上角关闭，或点击此处查看日志</span>
					</div>
				</div>
			</div>`;
	});
}

return view.extend({
	load: function() {
		return fetch(L.resource('dockergo/app/manifest.json'), { cache: 'no-store' })
			.then(function(response) {
				if (!response.ok)
					throw new Error('无法读取 DockerGo 构建清单');

				return response.json();
			})
			.then(function(manifest) {
				const entry = manifest['index.html'];
				if (!entry || !entry.file)
					throw new Error('DockerGo 构建清单缺少入口文件');

				const styles = (entry.css || []).map(function(file) {
					return fetch(L.resource('dockergo/app/' + file), { cache: 'no-store' })
						.then(function(response) {
							if (!response.ok)
								throw new Error('无法加载 DockerGo 样式');

							return response.text();
						});
				});

				return Promise.all([
					loadModule(L.resource('dockergo/app/' + entry.file)),
					Promise.all(styles),
					loadTaskDialog()
				]);
			})
			.then(function(result) {
				return result[1].join('\n');
			});
	},

	render: function(styleText) {
		window.DockerGoConfig = Object.freeze({
				pageBase: L.url('admin/dockergo'),
			apiBase: L.url('admin/services/dockergo/api'),
			csrfToken: L.env.token
		});

		const host = E('div', {
			'id': 'dockergo-root',
			'style': 'display:block;width:100%;min-height:calc(100vh - 110px);background:#f5f7fb'
		});
		const shadow = host.attachShadow({ mode: 'open' });
		const style = document.createElement('style');
		const mount = document.createElement('div');
		const overlayHost = document.createElement('div');
		const overlayShadow = overlayHost.attachShadow({ mode: 'open' });
		const overlayStyle = document.createElement('style');
		const overlayMount = document.createElement('div');
		style.textContent = styleText;
		mount.id = 'dockergo-app';
		overlayHost.id = 'dockergo-overlay-root';
		overlayHost.style.cssText = 'position:fixed;inset:0;z-index:10000;pointer-events:none;background:transparent';
		overlayStyle.textContent = styleText;
		overlayMount.id = 'dockergo-overlay';
		overlayMount.style.cssText = 'position:fixed;inset:0;pointer-events:none';
		shadow.appendChild(style);
		shadow.appendChild(mount);
		overlayShadow.appendChild(overlayStyle);
		overlayShadow.appendChild(overlayMount);
		document.body.appendChild(overlayHost);

		window.DockerGoMount(mount, overlayMount);
		this.mountNode = mount;
		this.overlayHost = overlayHost;

		return host;
	},

	unload: function() {
		if (this.mountNode && window.DockerGoUnmount)
			window.DockerGoUnmount(this.mountNode);

		if (this.overlayHost)
			this.overlayHost.remove();

		this.mountNode = null;
		this.overlayHost = null;
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
