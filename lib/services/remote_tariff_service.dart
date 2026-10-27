import 'dart:convert';

import 'package:http/http.dart' as http;

class RemoteTariffService {
  static const String _baseUrl =
      'https://raw.githubusercontent.com/'
      'DulajAR/sri-lanka-electricity-tariffs/'
      'main/tariffs';

  final http.Client _client;
  final bool _ownsClient;

  RemoteTariffService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  // Download the tariff manifest from GitHub.
  Future<Map<String, dynamic>> fetchManifest() async {
    final uri = Uri.parse('$_baseUrl/tariff_manifest.json');

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download manifest: '
        'HTTP ${response.statusCode}',
      );
    }

    if (response.bodyBytes.length > 100000) {
      throw const FormatException('Tariff manifest exceeds size limit.');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid manifest JSON format.');
    }

    if (data['schemaVersion'] != 1 ||
        data['category'] != 'domestic' ||
        data['tariffs'] is! List) {
      throw const FormatException('Unsupported tariff manifest.');
    }

    return data;
  }

  // Download a specific tariff JSON file.
  Future<Map<String, dynamic>> fetchTariff(String tariffId) async {
    final validId = RegExp(r'^domestic_\d{4}_\d{2}_\d{2}$');

    if (!validId.hasMatch(tariffId)) {
      throw const FormatException('Invalid tariff ID.');
    }

    final uri = Uri.parse('$_baseUrl/$tariffId.json');

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to download tariff: '
        'HTTP ${response.statusCode}',
      );
    }

    if (response.bodyBytes.length > 100000) {
      throw const FormatException('Tariff JSON exceeds size limit.');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid tariff JSON format.');
    }

    if (data['id'] != tariffId || data['category'] != 'domestic') {
      throw const FormatException('Tariff metadata does not match.');
    }

    return data;
  }

  // Close the HTTP client when finished.
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
