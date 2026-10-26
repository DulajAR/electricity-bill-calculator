import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'tariff_validator.dart';

class TariffCacheService {
  TariffCacheService({Directory? cacheDirectory})
    : _customCacheDirectory = cacheDirectory;

  final Directory? _customCacheDirectory;

  static final RegExp _validId = RegExp(r'^domestic_\d{4}_\d{2}_\d{2}$');

  // Get the cache directory.
  // A custom directory can be used during unit testing.
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

  // Get the cache file for a specific tariff.
  Future<File> _fileFor(String tariffId) async {
    if (!_validId.hasMatch(tariffId)) {
      throw const FormatException('Invalid tariff ID.');
    }

    final directory = await _cacheDirectory();

    return File('${directory.path}/$tariffId.json');
  }

  // Save only validated tariffs marked as verified.
  Future<void> saveTariff(Map<String, dynamic> tariff) async {
    final id = tariff['id'];

    if (id is! String || !_validId.hasMatch(id)) {
      throw const FormatException('Invalid tariff ID.');
    }

    if (tariff['status'] != 'verified') {
      throw const FormatException('Only verified tariffs may be cached.');
    }

    TariffValidator.validate(tariff);

    final file = await _fileFor(id);
    final temporaryFile = File('${file.path}.tmp');
    final backupFile = File('${file.path}.bak');

    try {
      // Remove any temporary file left by an earlier operation.
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }

      // Write the new tariff before changing the active cache.
      await temporaryFile.writeAsString(jsonEncode(tariff), flush: true);

      // Keep a backup of the existing tariff.
      if (await file.exists()) {
        if (await backupFile.exists()) {
          await backupFile.delete();
        }

        await file.rename(backupFile.path);
      }

      // Activate the newly written tariff.
      try {
        await temporaryFile.rename(file.path);
      } catch (_) {
        // Restore the previous cache if activation fails.
        if (await backupFile.exists() && !await file.exists()) {
          await backupFile.rename(file.path);
        }
        rethrow;
      }

      // The new cache is active.
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } finally {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }
    }
  }

  // Load a verified tariff from local storage.
  Future<Map<String, dynamic>?> loadTariff(String tariffId) async {
    final file = await _fileFor(tariffId);
    final backupFile = File('${file.path}.bak');

    // If an update was interrupted, try recovering the backup.
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

      if (decoded['id'] != tariffId || decoded['status'] != 'verified') {
        return null;
      }

      TariffValidator.validate(decoded);

      return decoded;
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }
}
