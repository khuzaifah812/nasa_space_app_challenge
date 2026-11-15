// One-time setup. Run from the project folder:
//     dart tool/setup.dart
// It creates the Android, iOS, web, Windows, macOS and Linux folders, puts
// the AgriSmart logo in as the app icon, sets the app's name, adds the
// internet permission the app needs, and downloads the packages.
// It is safe to run again after updating the project.
import 'dart:io';

Future<bool> run(String cmd, List<String> args) async {
  stdout.writeln('\n> $cmd ${args.join(' ')}');
  try {
    final p = await Process.start(cmd, args,
        runInShell: true, mode: ProcessStartMode.inheritStdio);
    return await p.exitCode == 0;
  } on ProcessException {
    return false;
  }
}

/// Inserts [line] after the first line containing [after], unless the file
/// already contains [marker]. Returns true if the file is now correct.
bool insertAfter(String path, String marker, String after, String line) {
  final file = File(path);
  if (!file.existsSync()) return false;
  final text = file.readAsStringSync();
  if (text.contains(marker)) return true;
  final lines = text.split('\n');
  final at = lines.indexWhere((l) => l.contains(after));
  if (at < 0) return false;
  lines.insert(at + 1, line);
  file.writeAsStringSync(lines.join('\n'));
  return true;
}

/// Replaces [from] with [to] in a file, on lines containing [onlyOn] if given.
void rename(String path, String from, String to, {String? onlyOn}) {
  final file = File(path);
  if (!file.existsSync()) return;
  final lines = file.readAsStringSync().split('\n');
  var changed = false;
  for (var i = 0; i < lines.length; i++) {
    if (onlyOn != null && !lines[i].contains(onlyOn)) continue;
    if (lines[i].contains(from)) {
      lines[i] = lines[i].replaceAll(from, to);
      changed = true;
    }
  }
  if (changed) file.writeAsStringSync(lines.join('\n'));
}

/// Copies the ready-made icon files over the default Flutter icons.
int copyIcons() {
  final root = Directory('branding/platform');
  if (!root.existsSync()) return 0;
  final base = root.absolute.path;
  var n = 0;
  for (final f in root.listSync(recursive: true).whereType<File>()) {
    final rel = f.absolute.path.substring(base.length + 1);
    final platform = rel.split(Platform.pathSeparator).first;
    if (!Directory(platform).existsSync()) continue; // platform not created
    final dest = File(rel)..parent.createSync(recursive: true);
    f.copySync(dest.path);
    n++;
  }
  return n;
}

Future<void> main() async {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run this from the agrismart folder (the one with pubspec.yaml).');
    exit(1);
  }
  if (!await run('flutter', ['create', '--project-name', 'agrismart', '.'])) {
    stderr.writeln('\nCould not run Flutter. Install it first: '
        'https://docs.flutter.dev/get-started/install');
    exit(1);
  }

  // App icon: the AgriSmart logo on every platform.
  stdout.writeln('App icon: copied ${copyIcons()} logo files.');

  // App name as shown under the icon and in window titles.
  rename('android/app/src/main/AndroidManifest.xml',
      'android:label="agrismart"', 'android:label="AgriSmart"');
  rename('ios/Runner/Info.plist', '<string>Agrismart</string>', '<string>AgriSmart</string>');
  rename('ios/Runner/Info.plist', '<string>agrismart</string>', '<string>AgriSmart</string>');
  rename('web/index.html', '<title>agrismart</title>', '<title>AgriSmart</title>');
  rename('web/index.html', 'content="agrismart"', 'content="AgriSmart"');
  rename('web/manifest.json', '"agrismart"', '"AgriSmart"');
  rename('windows/runner/main.cpp', 'L"agrismart"', 'L"AgriSmart"');
  rename('linux/runner/my_application.cc', '"agrismart"', '"AgriSmart"', onlyOn: 'set_title');
  rename('linux/my_application.cc', '"agrismart"', '"AgriSmart"', onlyOn: 'set_title');
  stdout.writeln('App name: set to AgriSmart.');

  // Launch screen: the Android styles reference launch_background, which
  // the copied files now paint green with the logo. iOS shows LaunchImage
  // from the storyboard; give it the brand colour behind the logo.
  rename('ios/Runner/Base.lproj/LaunchScreen.storyboard',
      'red="1" green="1" blue="1"',
      'red="0.122" green="0.353" blue="0.227"');
  stdout.writeln('Launch screen: logo on green.');

  // Keep the key file out of git. flutter create writes its own .gitignore.
  final ignore = File('.gitignore');
  final ignored = ignore.existsSync() ? ignore.readAsStringSync() : '';
  if (!ignored.split('\n').any((l) => l.trim() == '.env')) {
    ignore.writeAsStringSync('$ignored\n# AgriSmart: keep secrets out of the repository\n.env\n');
  }
  if (!File('.env').existsSync() && File('.env.example').existsSync()) {
    File('.env.example').copySync('.env');
  }
  stdout.writeln('.env is ignored by git.');

  // Website: description, brand colour, and a logo while the app loads.
  rename('web/index.html', 'content="A new Flutter project."',
      'content="AgriSmart helps farmers compare crop rotations using NASA Earth observation data. Your Farm. Your next season."');
  rename('web/manifest.json', '"A new Flutter project."',
      '"Crop rotation advice from NASA data. Your Farm. Your next season."');
  rename('web/manifest.json', '"#0175C2"', '"#1F5A3A"');
  rename('web/manifest.json', '"#hexcode"', '"#1F5A3A"');
  insertAfter('web/index.html', 'agrismart-splash', '<body>', '''
  <style>
    body { margin: 0; background: #1F5A3A; }
    #agrismart-splash { position: fixed; inset: 0; display: flex; flex-direction: column;
      align-items: center; justify-content: center; gap: 18px; background: #1F5A3A;
      color: #fff; font: 600 20px system-ui, sans-serif; }
    #agrismart-splash img { width: 128px; height: 128px; border-radius: 28px; }
    flutter-view, flt-glass-pane { position: relative; z-index: 1; }
  </style>
  <div id="agrismart-splash"><img src="icons/Icon-192.png" alt="AgriSmart logo">Your Farm. Your next season.</div>
  <script>
    window.addEventListener('flutter-first-frame', function () {
      var s = document.getElementById('agrismart-splash'); if (s) s.remove();
    });
  </script>''');
  insertAfter('web/index.html', 'name="theme-color"', '<head>',
      '  <meta name="theme-color" content="#1F5A3A">');
  stdout.writeln('Website: description, colours and loading screen set.');

  // Android release builds need permission to reach NASA's servers.
  final android = insertAfter(
      'android/app/src/main/AndroidManifest.xml',
      'android.permission.INTERNET',
      '<manifest',
      '    <uses-permission android:name="android.permission.INTERNET"/>');
  stdout.writeln(android
      ? 'Android: internet permission is set.'
      : 'Android: manifest not found or not changed (see README).');

  // macOS apps are sandboxed and need the same permission.
  for (final name in ['DebugProfile', 'Release']) {
    final ok = insertAfter(
        'macos/Runner/$name.entitlements',
        'com.apple.security.network.client',
        '<dict>',
        '\t<key>com.apple.security.network.client</key>\n\t<true/>');
    if (ok) stdout.writeln('macOS $name: internet permission is set.');
  }

  await run('flutter', ['pub', 'get']);
  stdout.writeln('\nDone. Start the app with:\n'
      '  flutter run --dart-define-from-file=.env\n'
      'Build the Android app with:\n'
      '  flutter build apk --dart-define-from-file=.env\n'
      'Build the website with:\n'
      '  flutter build web --release --dart-define-from-file=.env');
}
