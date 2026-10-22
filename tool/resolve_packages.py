import json
import os
import re
import sys

project = sys.argv[1]
cache = os.path.join(os.environ['LOCALAPPDATA'], 'Pub', 'Cache', 'hosted', 'pub.dev')
flutter_root = r'D:\rabotika\prilozheniya\flutter'

packages = []
seen = set()


def add(name, root_uri, package_uri, language='dart'):
    packages.append({
        'name': name,
        'rootUri': root_uri,
        'packageUri': package_uri,
        'language': language,
    })


def file_uri(path):
    return 'file:///' + path.replace(os.sep, '/')


add('flutter', file_uri(os.path.join(flutter_root, 'packages', 'flutter')), 'lib/')
add('flutter_test', file_uri(os.path.join(flutter_root, 'packages', 'flutter_test')), 'lib/')
add('flutter_web_plugins', file_uri(os.path.join(flutter_root, 'packages', 'flutter_web_plugins')), 'lib/')
add('flutter_driver', file_uri(os.path.join(flutter_root, 'packages', 'flutter_driver')), 'lib/')
add('integration_test', file_uri(os.path.join(flutter_root, 'packages', 'integration_test')), 'lib/')

root_name = 'mebel_web'
with open(os.path.join(project, 'pubspec.yaml'), 'r', encoding='utf-8') as f:
    root_match = re.search(r'^name:\s*(\S+)', f.read(), re.M)
if root_match:
    root_name = root_match.group(1).strip()
add(root_name, '../', 'lib/')

locked = {}
lock_path = os.path.join(project, 'pubspec.lock')
if os.path.exists(lock_path):
    with open(lock_path, 'r', encoding='utf-8') as f:
        lock_text = f.read()
    entries = re.findall(r'(?ms)^  ([a-z0-9_]+):\n(.*?)(?=^  [a-z0-9_]+:\n|\Z)', lock_text)
    for name, body in entries:
        ver = re.search(r'version:\s*"([^"]+)"', body)
        if ver:
            locked[name] = ver.group(1)

for entry in sorted(os.listdir(cache)):
    folder = os.path.join(cache, entry)
    if not os.path.isdir(folder):
        continue
    pubspec = os.path.join(folder, 'pubspec.yaml')
    if not os.path.exists(pubspec):
        continue
    with open(pubspec, 'r', encoding='utf-8') as f:
        text = f.read()
    match = re.search(r'^name:\s*(\S+)', text, re.M)
    if not match:
        continue
    name = match.group(1).strip()
    if name in seen:
        continue
    if name in locked and not entry.endswith('-' + locked[name]):
        continue
    seen.add(name)
    add(name, file_uri(folder), 'lib/')

out = os.path.join(project, '.dart_tool', 'package_config.json')
os.makedirs(os.path.dirname(out), exist_ok=True)
config = {
    'configVersion': 2,
    'packages': packages,
    'generated': 'manual-offline-resolve',
    'generator': 'manual',
    'generatorVersion': '3.6.1',
}
with open(out, 'w', encoding='utf-8') as f:
    json.dump(config, f, indent=2)
print(f'wrote {len(packages)} packages to {out}')
