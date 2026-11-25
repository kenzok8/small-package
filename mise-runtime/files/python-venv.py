"""Application-local verified venvs for a fixed public Python SDK."""
import hashlib
import json
import os
from pathlib import Path
import secrets
import shutil
import stat
import subprocess
import sys

root, sdk_path, instance, mode, *args = sys.argv[1:]
sdk = Path(sdk_path)
entry = sdk / 'bin/python3'
receipt_name = '.istore-python-runtime.json'
version = '.'.join(map(str, sys.version_info[:3]))


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def target_path(value):
    if not value.startswith('/mnt/') or '//' in value or value.endswith('/') or any(c in value.split('/') for c in ('.', '..')) or any(ord(c) < 32 or c == ':' for c in value):
        raise ValueError('Use a normalized persistent /mnt virtual environment path')
    target = Path(value)
    if target.resolve() != target:
        raise ValueError('Virtual environment parents must not contain symlinks')
    managed = Path(root)
    if target == managed or target in managed.parents:
        raise ValueError('Virtual environment cannot contain the shared storage')
    task = os.environ.get('MISE_RUNTIME_PROBE')
    probe = os.getuid() == 0 and task and target == managed / 'work' / task / 'probe-venv'
    if probe:
        journal = json.loads((managed / 'tasks' / task / 'task.json').read_text())
        probe = journal.get('status') == 'running' and journal.get('pending_environment', {}).get('id') == instance
    for name in ('environments', 'libraries', 'mise', 'wrap', 'cache', 'tasks', 'plans', 'work', 'network'):
        shared = managed / name
        if not probe and (target == shared or shared in target.parents):
            raise ValueError('Virtual environment cannot use shared SDK/manager directories')
    current = Path('/')
    for part in target.parts[1:]:
        current /= part
        if not current.exists():
            continue
        item = current.lstat()
        sticky = current != target and item.st_uid == 0 and bool(item.st_mode & stat.S_ISVTX)
        if not stat.S_ISDIR(item.st_mode) or item.st_uid not in (0, os.getuid()) or (item.st_mode & 0o022 and not sticky):
            raise ValueError('Virtual environment parent is not protected/owned by this user')
    return target


def environment(target, nonce=None):
    env = os.environ.copy()
    for key in ('PYTHONHOME', 'PYTHONPATH', 'PYTHONUSERBASE', 'PYTHONEXECUTABLE', '__PYVENV_LAUNCHER__', 'PIP_TARGET', 'PIP_PREFIX', 'PIP_USER', 'PIP_PYTHON'):
        env.pop(key, None)
    env.update(VIRTUAL_ENV=str(target), ISTORE_PYTHON_VENV=str(target), PYTHONNOUSERSITE='1', PIP_REQUIRE_VIRTUALENV='true')
    env['PATH'] = str(target / 'bin') + os.pathsep + env['PATH']
    if nonce:
        env['ISTORE_PYTHON_CREATING'] = nonce
    else:
        env.pop('ISTORE_PYTHON_CREATING', None)
    return env


def verify(target, nonce=None):
    code = "import json,sys,site;print(json.dumps({'prefix':sys.prefix,'base':sys.base_prefix,'exe':sys.executable,'user_site':site.ENABLE_USER_SITE,'version':'.'.join(map(str,sys.version_info[:3]))}))"
    result = json.loads(subprocess.check_output([str(target / 'bin/python3'), '-I', '-c', code], env=environment(target, nonce), text=True))
    if Path(result['prefix']) != target or Path(result['base']).resolve() != sdk or Path(result['exe']) != target / 'bin/python3' or result['user_site'] or result['version'] != version:
        raise ValueError('Virtual environment failed fixed SDK/launcher verification; no shared Python fallback')


def write_receipt(target, value):
    temporary = target / (receipt_name + '.new')
    with temporary.open('w') as stream:
        json.dump(value, stream, indent=2)
        stream.write('\n')
        stream.flush()
        os.fsync(stream.fileno())
    temporary.chmod(0o600)
    temporary.replace(target / receipt_name)


def create(target):
    if target.exists() or target.is_symlink():
        raise ValueError('Target already exists; choose a new directory (existing files are preserved)')
    # The nearest existing parent must be owned by the caller. Kernel access
    # checks remain authoritative when creating any missing parent directories.
    nearest = target.parent
    while not nearest.exists():
        nearest = nearest.parent
    if nearest.stat().st_uid != os.getuid():
        raise ValueError('Ask the administrator to prepare an owned application directory')
    target.parent.mkdir(parents=True, exist_ok=True)
    target.mkdir(mode=0o700)
    owned = target.stat()
    nonce = secrets.token_hex(16)
    try:
        target_path(str(target))
        clean = os.environ.copy()
        clean.pop('VIRTUAL_ENV', None)
        clean.pop('ISTORE_PYTHON_VENV', None)
        subprocess.run([str(entry), '-m', 'venv', '--copies', '--without-pip', str(target)], env=clean, check=True)
        for name in ('python', 'python3', 'python%d.%d' % sys.version_info[:2]):
            binary = target / 'bin' / name
            if binary.exists() or binary.is_symlink():
                binary.unlink()
            shutil.copyfile(entry, binary)
            binary.chmod(0o700)
        owner_start = Path('/proc/self/stat').read_text().rsplit(')', 1)[1].split()[19]
        value = dict(schema_version=1, kind='venv', storage_root=root, sdk=str(sdk), instance=instance,
                     path=str(target), home=os.environ['HOME'], version=version, state='preparing',
                     launcher_sha256=digest(entry), config_sha256=digest(target / 'pyvenv.cfg'), config_text=(target / 'pyvenv.cfg').read_text(),
                     creation_nonce=nonce, creator_pid=os.getpid(), creator_start=owner_start,
                     creator_boot=Path('/proc/sys/kernel/random/boot_id').read_text().strip())
        write_receipt(target, value)
        verify(target, nonce)
        subprocess.run([str(target / 'bin/python3'), '-m', 'ensurepip', '--upgrade', '--default-pip'], env=environment(target, nonce), check=True)
        subprocess.run([str(target / 'bin/python3'), '-m', 'pip', '--version'], env=environment(target, nonce), check=True)
        verify(target, nonce)
        value['state'] = 'ready'
        for key in ('creation_nonce', 'creator_pid', 'creator_start', 'creator_boot'):
            value.pop(key)
        write_receipt(target, value)
        print('Virtual environment created with verified bundled pip: ' + str(target))
    except BaseException:
        if target.is_dir() and not target.is_symlink():
            current = target.stat()
            if (current.st_ino, current.st_dev) == (owned.st_ino, owned.st_dev):
                shutil.rmtree(target)
        raise


def run(target, command, rest):
    value = json.loads((target / receipt_name).read_text())
    if value.get('state') != 'ready' or value.get('storage_root') != root or value.get('sdk') != str(sdk) or value.get('instance') != instance or value.get('path') != str(target):
        raise ValueError('Virtual environment is unverified or belongs to another fixed SDK')
    verify(target)
    env = environment(target)
    if command in ('python', 'python3'):
        argv = [str(target / 'bin/python3'), *rest]
    elif command == 'pip':
        targets = ('--target', '--prefix', '--root', '--python', '--user', '--home')
        if any(v.startswith('-t') or any(v == key or v.startswith(key + '=') for key in targets) for v in rest):
            raise ValueError('Use the chosen virtual environment instead of overriding the pip target')
        # pip's site config is relative to sys.prefix. Run this check inside
        # the selected venv, where the eventual pip command reads it too.
        # Only offending option names leave this process; index credentials do
        # not appear in errors/logs and private package sources remain intact.
        policy = """from pip._internal.configuration import Configuration
from pip._internal.exceptions import ConfigurationError
import sys
config = Configuration(isolated=False)
config.load()
# get_value resolves both the older flat storage and pip 26.3's per-file
# storage. items() is not an option iterator on all supported pip versions.
for section in ('global', 'install', ':env:'):
    for option in ('target', 'prefix', 'root', 'python', 'user'):
        key = section + '.' + option
        try:
            value = config.get_value(key)
        except ConfigurationError:
            continue
        if value and (option != 'user' or str(value).lower() in ('true', '1', 'yes', 'on')):
            sys.exit('pip configuration overrides the virtual environment target; clear ' + key)
"""
        subprocess.run([str(target / 'bin/python3'), '-c', policy], env=env, check=True)
        if env.get('ISTORE_RUNTIME_ACCELERATION') == 'ks-cli':
            env['PATH'] = str(Path(__file__).parent / 'native/bin') + os.pathsep + str(sdk / 'native/bin') + os.pathsep + env['PATH']
            argv = ['/usr/bin/ks-cli', 'pip', *rest]
        else:
            argv = [str(target / 'bin/python3'), '-m', 'pip', *rest]
    elif command == '--shell':
        env.pop('ISTORE_PYTHON_VENV', None)
        argv = ['/bin/sh', *rest]
    else:
        raise ValueError('Virtual environment supports python, pip or --shell')
    os.execve(argv[0], argv, env)


try:
    if instance.split('-')[1] != version:
        raise ValueError('Executed Python version differs from fixed SDK')
    target = target_path(args[0])
    if mode == 'create' and len(args) == 1:
        create(target)
    elif mode == 'run':
        run(target, args[1] if len(args) > 1 else '--shell', args[2:])
    else:
        raise ValueError('Invalid virtual environment operation')
except (ValueError, OSError, IndexError, subprocess.SubprocessError) as error:
    print(str(error), file=sys.stderr)
    sys.exit(2)
