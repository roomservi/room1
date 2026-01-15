import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'nfc_config.dart';

/// Simple NFC reader that compares read NFC payload to the mapping loaded by `NFCConfig`.
///
/// Usage example:
/// await NFCConfig.loadFromAsset();
/// NFCReader.startListening(
///   onMatch: (code, value) { /* matched user/value */ },
///   onNoMatch: (message) { /* handle not matched or errors */ },
/// );
class NFCReader {
  static bool _listening = false;

  /// Start listening for NFC tags. Calls `onMatch` when a code matches the mapping,
  /// otherwise calls `onNoMatch` with an explanatory message.
  static Future<void> startListening({
    required void Function(String code, String? value) onMatch,
    required void Function(String message) onNoMatch,
  }) async {
    if (_listening) return;
    _listening = true;

    // Ensure mapping is loaded
    await NFCConfig.loadFromAsset();

    try {
      final available = await NfcManager.instance.isAvailable();
      if (!available) {
        onNoMatch('NFC not available on this device');
        _listening = false;
        return;
      }

      await NfcManager.instance.startSession(
        onDiscovered: (tag) async {
          try {
            String? cardData;

            // Try to extract NDEF payload (UTF-8) when available
            try {
              final ndef = Ndef.from(tag);
              if (ndef != null &&
                  ndef.cachedMessage != null &&
                  ndef.cachedMessage!.records.isNotEmpty) {
                final payload = ndef.cachedMessage!.records.first.payload;
                // Some NDEF payloads include a leading language code byte; try decode and trim
                try {
                  cardData = utf8.decode(payload).trim();
                } catch (e) {
                  // fallback to hex
                  cardData =
                      payload
                          .map((b) => b.toRadixString(16).padLeft(2, '0'))
                          .join();
                }
              }
            } catch (e) {
              // ignore and try alternatives
            }

            // If still null, try tag id
            if (cardData == null) {
              try {
                final id = tag.data['id'];
                if (id is List<int>) {
                  cardData =
                      id.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
                } else if (id != null) {
                  cardData = id.toString();
                }
              } catch (e) {
                // ignore
              }
            }

            if (cardData == null) {
              onNoMatch('No readable NFC data found');
              return;
            }

            // Now check mapping
            final value = NFCConfig.getValueForCode(cardData);
            // If mapping exists, pass it; otherwise still call onMatch with raw cardData
            // so the app can handle unmapped payloads (e.g., roomone/balance:...)
            if (value != null) {
              onMatch(cardData, value);
            } else {
              onMatch(cardData, cardData);
            }
          } catch (e) {
            onNoMatch('Error processing NFC tag: $e');
          }
        },
        onError: (error) async {
          onNoMatch('NFC session error: ${error.toString()}');
        },
        alertMessage: 'Hold your NFC card near the device',
      );
    } catch (e) {
      onNoMatch('Error starting NFC session: $e');
      _listening = false;
    }
  }

  static Future<void> stopListening() async {
    if (!_listening) return;
    _listening = false;
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }
}
