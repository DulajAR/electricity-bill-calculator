import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'tariff_manifest_validator.dart';

class TariffManifestCacheService {
  TariffManifestCacheService({Directory? cacheDirectory})
    : _customCacheDirectory = cacheDirectory;

  final Directory? _customCacheDirectory;

  Future<Directory> _cacheDirectory() async {
    final Directory directory;

    if (_customCacheDirectory != null) {
      directory = _customCacheDirectory;
    } else {
      final appDirectory = await getApplicationSupportDirectory();

      directory = Directory('${appDirectory.path}/tariff_cache');
    }

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<File> _manifestFile() async {
    final directory = await _cacheDirectory();

    return File('${directory.path}/tariff_manifest.json');
  }

  Map<String, dynamic> _validateManifest(Map<String, dynamic> manifest) {
    if (manifest['schemaVersion'] != 1 || manifest['category'] != 'domestic') {
      throw const FormatException('Unsupported tariff manifest.');
    }

    final rawEntries = manifest['tariffs'];

    if (rawEntries is! List) {
      throw const FormatException('Invalid tariff manifest entries.');
    }

    final entries = <Map<String, dynamic>>[];

    for (final entry in rawEntries) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid tariff manifest entry.');
      }

      entries.add(entry);
    }

    TariffManifestValidator.validate(entries);

    return manifest;
  }

  Future<void> saveManifest(Map<String, dynamic> manifest) async {
    _validateManifest(manifest);

    final file = await _manifestFile();

    final temporaryFile = File('${file.path}.tmp');
    final backupFile = File('${file.path}.bak');

    try {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }

      await temporaryFile.writeAsString(jsonEncode(manifest), flush: true);

      if (await file.exists()) {
        if (await backupFile.exists()) {
          await backupFile.delete();
        }

        await file.rename(backupFile.path);
      }

      try {
        await temporaryFile.rename(file.path);
      } catch (_) {
        if (await backupFile.exists() && !await file.exists()) {
          await backupFile.rename(file.path);
        }

        rethrow;
      }

      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } finally {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
    }
  }

  Future<Map<String, dynamic>?> loadManifest() async {
    final file = await _manifestFile();
    final backupFile = File('${file.path}.bak');

    if (!await file.exists() && await backupFile.exists()) {
      await backupFile.rename(file.path);
    }

    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();

      final decoded = jsonDecode(content);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return _validateManifest(decoded);
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }
}
