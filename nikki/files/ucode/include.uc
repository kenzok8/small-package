import { readfile, lsdir, lstat } from 'fs';

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

export function get_users() {
	return map(split(readfile('/etc/passwd'), '\n'), (x) => split(x, ':')[0]);
};

export function get_groups() {
	return map(split(readfile('/etc/group'), '\n'), (x) => split(x, ':')[0]);
};

export function get_cgroups() {
	return filter(lsdir('/sys/fs/cgroup/services'), (x) => lstat(`/sys/fs/cgroup/services/${x}`).type == 'directory');
};