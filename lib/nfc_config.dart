import 'package:flutter/services.dart' show rootBundle;

/// Loads a simple key=value text file from assets and exposes a lookup map.
///
/// File format (per line):
/// roomone/nfc/00000=utente_password
/// roomone/nfc/94738=another_password
/// Lines starting with `#` or empty lines are ignored.
class NFCConfig {
  static final Map<String, String> _mapping = {};

  /// Load mapping from asset (default: assets/nfc_users.txt)
  static Future<void> loadFromAsset([
    String assetPath = 'assets/nfc_users.txt',
  ]) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      _mapping.clear();
      for (final rawLine in content.split('\n')) {
        final line = rawLine.trim();
        if (line.isEmpty) continue;
        if (line.startsWith('#')) continue;
        final sepIndex = line.indexOf('=');
        if (sepIndex > 0) {
          final key = line.substring(0, sepIndex).trim();
          final val = line.substring(sepIndex + 1).trim();
          if (key.isNotEmpty) {
            _mapping[key] = val;
          }
        } else {
          // If no separator, treat whole line as key with empty value
          _mapping[line] = '';
        }
      }
    } catch (e) {
      // If loading fails leave mapping empty
    }
  }

  /// Return the mapped value (e.g., password or user id) for a NFC code
  static String? getValueForCode(String code) => _mapping[code];

  /// Expose immutable copy
  static Map<String, String> get mapping => Map.unmodifiable(_mapping);
}
