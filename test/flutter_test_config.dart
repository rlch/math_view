import 'dart:async';
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:math_view/math_view.dart' show RustLib;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final libPath = _findLibraryPath();
  await RustLib.init(
    externalLibrary: ExternalLibrary.open(libPath),
  );
  await testMain();
}

String _findLibraryPath() {
  final sep = Platform.pathSeparator;
  final packageRoot = _findPackageRoot();
  final rustRoot = '$packageRoot${sep}rust';

  if (Platform.isMacOS) {
    return _pickExisting([
      '$rustRoot${sep}target${sep}release${sep}libmath_view.dylib',
      '$rustRoot${sep}target${sep}debug${sep}libmath_view.dylib',
    ]);
  } else if (Platform.isLinux) {
    return _pickExisting([
      '$rustRoot${sep}target${sep}release${sep}libmath_view.so',
      '$rustRoot${sep}target${sep}debug${sep}libmath_view.so',
    ]);
  } else if (Platform.isWindows) {
    return _pickExisting([
      '$rustRoot${sep}target${sep}release${sep}math_view.dll',
      '$rustRoot${sep}target${sep}debug${sep}math_view.dll',
    ]);
  } else {
    throw UnsupportedError('Unsupported platform for unit tests');
  }
}

String _findPackageRoot() {
  var current = Directory.current;
  for (var depth = 0; depth < 8; depth++) {
    final pubspec =
        File('${current.path}${Platform.pathSeparator}pubspec.yaml');
    if (pubspec.existsSync()) {
      final content = pubspec.readAsStringSync();
      if (content.contains('name: math_view')) {
        return current.path;
      }
    }
    if (current.parent.path == current.path) break;
    current = current.parent;
  }
  return Directory.current.path;
}

String _pickExisting(List<String> candidates) {
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }
  return candidates.first;
}
