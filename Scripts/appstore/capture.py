import json
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

root = Path(__file__).resolve().parents[2]
built = Path(sys.argv[1])
computer = Path.home() / '.dotfiles/herdr/bin/herdr-computer'
lsregister = '/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'
bundle = 'com.noma4i.EMLViewer.shots'
raw = root / 'Scripts/appstore/raw'


def run(*args, check=True):
    return subprocess.run([str(arg) for arg in args], check=check, capture_output=True, text=True, timeout=30)


def windows():
    return json.loads(run(computer, 'list-windows', '--app', bundle, '--json').stdout)['windows']


def wait_for(predicate):
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        try:
            result = predicate()
            if result:
                return result
        except (subprocess.CalledProcessError, KeyError, json.JSONDecodeError):
            pass
    raise RuntimeError('Timed out waiting for screenshot window')


def main_window():
    for window in windows():
        if window['width'] == 780 and window['height'] == 835:
            return window
    return None


def capture(name, expected):
    window = wait_for(main_window)
    def loaded():
        result = json.loads(run(computer, 'get-app-state', '--app', bundle, '--window-id', window['id'], '--no-screenshot', '--json').stdout)
        return expected in result['snapshot']['treeText']
    wait_for(loaded)
    run('open', '-a', app)
    window = main_window()
    if not window or (window['width'], window['height']) != (780, 835):
        raise RuntimeError('Message window must be 780x835')
    image = raw / (name + '.png')
    previous = None
    stable = 0
    def rendered():
        nonlocal previous, stable
        run('screencapture', '-o', '-l', window['id'], image)
        digest = hashlib.sha256(image.read_bytes()).digest()
        stable = stable + 1 if digest == previous else 0
        previous = digest
        return stable >= 2
    wait_for(rendered)


def quit_app():
    run(computer, 'hotkey', '--app', bundle, '--key', 'cmd+q', '--no-screenshot', check=False)
    def stopped():
        result = run('pgrep', '-f', str(app / 'Contents/MacOS/EMLViewer'), check=False)
        return result.returncode != 0
    wait_for(stopped)


def launch(theme, file=None):
    run('defaults', 'write', bundle, 'com.noma4i.emlviewer.appearance', '-string', theme)
    run('defaults', 'write', bundle, 'mainWindowFrame', '-string', '{{200, 100}, {780, 835}}')
    args = ['open', '-n', '-a', app]
    if file:
        args.append(root / 'AppStore/demo' / file)
    run(*args)
    wait_for(main_window)
    if file:
        run('open', '-a', app, root / 'AppStore/demo' / file)


with tempfile.TemporaryDirectory(prefix='emlviewer-shots-') as directory:
    app = Path(directory) / 'EMLViewerShots.app'
    shutil.copytree(built, app, symlinks=True)
    plist = app / 'Contents/Info.plist'
    run('/usr/libexec/PlistBuddy', '-c', f'Set :CFBundleIdentifier {bundle}', plist)
    run('/usr/libexec/PlistBuddy', '-c', 'Set :CFBundleName EMLViewerShots', plist)
    run('codesign', '--force', '--deep', '-s', '-', '--entitlements', root / 'Resources/EMLViewer-Dev.entitlements', app)
    try:
        for name, theme, file, expected in [
            ('hero-light', 'light', 'field-notes.eml', 'FIELD NOTES'),
            ('outlook', 'light', 'outlook.msg', 'The spring gathering is coming together'),
            ('attachments', 'light', 'travel.eml', 'The coast is calling'),
            ('hero-nord', 'nord', 'field-notes.eml', 'FIELD NOTES'),
            ('hero-dark', 'dark', 'field-notes.eml', 'FIELD NOTES'),
        ]:
            print('Capturing', name, flush=True)
            launch(theme, file)
            capture(name, expected)
            quit_app()
        launch('light', 'field-notes.eml')
        capture('settings-message', 'FIELD NOTES')
        run(computer, 'hotkey', '--app', bundle, '--key', 'cmd+,', '--no-screenshot')
        settings = wait_for(lambda: next((w for w in windows() if 'Settings' in w['title']), None))
        run('open', '-a', app)
        if not main_window():
                raise RuntimeError('Message window must be 780x835')
        run('screencapture', '-o', '-l', settings['id'], raw / 'settings.png')
        quit_app()
        launch('light')
        capture('welcome', 'Open')
        quit_app()
    finally:
        run(computer, 'hotkey', '--app', bundle, '--key', 'cmd+q', '--no-screenshot', check=False)
        run(lsregister, '-u', app, check=False)
