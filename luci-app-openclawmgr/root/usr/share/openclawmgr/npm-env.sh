# Shared by the installer and interactive shell. Configuration is process-local.
oc_npm_environment() {
	export npm_config_cache="${BASE_DIR}/npm-cache"
	export npm_config_audit=false npm_config_fund=false npm_config_progress=false
	export npm_config_update_notifier=false
	export npm_config_git=/usr/share/openclawmgr/npm-git.sh
	# npm itself verifies package/dependency integrity. Never disable TLS or
	# lifecycle scripts globally just because the host uses musl.
	export npm_config_registry=https://registry.npmjs.org
	export npm_config_libc=glibc
	unset npm_config_ignore_scripts NPM_CONFIG_IGNORE_SCRIPTS
}
