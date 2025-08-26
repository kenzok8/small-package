import { readfile, popen } from 'fs';

export function get_paths() {
	let result = {};
	const process = popen('. /etc/momo/scripts/include.sh && get_paths');
	if (process) {
		result = json(process);
		process.close();
	}
	return result;
};

export function uci_bool(obj) {
	return obj == null ? null : obj == '1';
};

export function uci_int(obj) {
	return obj == null ? null : int(obj);
};

export function uci_array(obj) {
	if (obj == null) {
		return [];
	}
	if (type(obj) == 'array') {
		return uniq(obj);
	}
	return [obj];
};

export function merge(target, ...sources) {
	for (let source in sources) {
		for (let key in keys(source)) {
			const target_value = target[key];
			const target_value_type = type(target_value);
			const source_value = source[key];
			const source_value_type = type(source_value);
			if (target_value_type === 'object' && source_value_type === 'object') {
				target[key] = merge(target_value, source_value);
			} else {
				target[key] = source[key];
			}
		}
	}
	return target;
};

export function merge_exists(target, ...sources) {
	for (let source in sources) {
		for (let key in keys(source)) {
			if (exists(target, key)) {
				const target_value = target[key];
				const target_value_type = type(target_value);
				const source_value = source[key];
				const source_value_type = type(source_value);
				if (target_value_type === 'object' && source_value_type === 'object') {
					target[key] = merge_exists(target_value, source_value);
				} else {
					target[key] = source[key];
				}
			}
		}
	}
	return target;
};

export function trim_all(obj) {
	if (obj == null) {
		return null;
	}
	if (type(obj) == 'string') {
		if (length(obj) == 0) {
			return null;
		}
		return obj;
	}
	if (type(obj) == 'array') {
		if (length(obj) == 0) {
			return null;
		}
		return obj;
	}
	if (type(obj) == 'object') {
		const obj_keys = keys(obj);
		for (let key in obj_keys) {
			obj[key] = trim_all(obj[key]);
			if (obj[key] == null) {
				delete obj[key];
			}
		}
		if (length(keys(obj)) == 0) {
			return null;
		}
		return obj;
	}
	return obj;
};

export function get_cgroups_version() {
	return system('mount | grep -q -w "^cgroup"') == 0 ? 1 : 2;
};

export function get_users() {
	return map(split(readfile('/etc/passwd'), '\n'), (x) => split(x, ':')[0]);
};

export function get_groups() {
	return map(split(readfile('/etc/group'), '\n'), (x) => split(x, ':')[0]);
};

export function get_cgroups() {
	const result = [];
	if (get_cgroups_version() == 2) {
		const cgroup_path = '/sys/fs/cgroup/';
		const process = popen(`find ${cgroup_path} -type d -mindepth 1`);
		if (process) {
			for (let line = process.read('line'); length(line); line = process.read('line')) {
				push(result, substr(trim(line), length(cgroup_path)));
			}
		}
	}
	return result;
};