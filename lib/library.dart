import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

// Restituisce la lista degli username degli altri utenti (amici) escluso quello loggato
Future<List<String>> getOtherUsers(String? currentUser) async {
  return users.keys.where((u) => u != currentUser).toList();
}

// Mappa username -> path card principale
const Map<String, String> userMainCardImages = {
  'alex': 'asset/images/Card alex/card 1.png',
  'edo': 'asset/images/Card edo/card 1.png',
  'tery': 'asset/images/Card tery/card 1.png',
  'tom&ila': 'asset/images/Card ixt/card 1.png',
};

// Mappa delle card degli utenti (anche per il profilo)
const Map<String, String> userCardAssets = {
  'alex': 'asset/images/Card alex/card 1.png',
  'edo': 'asset/images/Card edo/card 1.png',
  'tery': 'asset/images/Card tery/card 1.png',
  'tom&ila': 'asset/images/Card ixt/card 1.png',
};

// Ottieni path card principale
String getMainCardImage(String? username) {
  if (username == null)
    return 'asset/images/Card alex/card 1.png'; // default: card silver di alex
  return userMainCardImages[username] ?? 'asset/images/Card alex/card 1.png';
}

// Ottieni il percorso della card dell'utente
Future<String?> getUserCardAsset(
  String password, {
  required String username,
}) async {
  // Verifica che l'utente sia autenticato correttamente
  if (users[username] != password) {
    return null;
  }

  try {
    // Controlla l'abbonamento su Firebase usando il password come chiave
    final url = Uri.parse('${baseUrl}level_card/$password.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Usa direttamente il card_asset salvato su Firebase
      final cardAsset = data?['card_asset'] as String?;
      if (cardAsset != null && cardAsset.isNotEmpty) {
        return cardAsset;
      }
    }

    return userCardAssets[username]; // Se non riesce a leggere da Firebase, usa la card default
  } catch (e) {
    debugPrint('Errore nel recupero della card: $e');
    return userCardAssets[username];
  }
} // Mappa username -> nome visualizzato

const Map<String, String> userDisplayNames = {
  'alex': 'Alex',
  'edo': 'Edo',
  'tery': 'Tery',
  'tom&ila': 'Tom & Ila',
};

// Mappa username -> path immagine profilo
const Map<String, String> userProfileImages = {
  'alex': 'asset/images/Immagini profilo app/ip alex.jpg',
  'edo': 'asset/images/Immagini profilo app/ip edo.jpg',
  'tery': 'asset/images/Immagini profilo app/ip tery.jpg',
  'tom&ila': 'asset/images/Immagini profilo app/ip txi.jpg',
};

// Ottieni username loggato
Future<String?> getLoggedUser() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(loggedUserKey);
}

// Ottieni nome visualizzato
String getDisplayName(String? username) {
  if (username == null) return '';
  return userDisplayNames[username] ?? username;
}

// Ottieni path immagine profilo
String getProfileImage(String? username) {
  if (username == null) return 'asset/images/default_profile.png';
  return userProfileImages[username] ?? 'asset/images/default_profile.png';
}

// Lista utenti e password preimpostati
const Map<String, String> users = {
  'tom&ila': '49367',
  'alex': '94738',
  'edo': '00000',
  'tery': '48923',
};

// Chiave per SharedPreferences
const String loggedInKey = 'isLoggedIn';
const String loggedUserKey = 'loggedUser';
const String baseUrl = 'https://room1-4e6b4-default-rtdb.firebaseio.com/';

/// Recupera la lista degli amici con il loro stato online
Future<List<Map<String, dynamic>>> getFriends(String username) async {
  try {
    final otherUsers = await getOtherUsers(username);
    return otherUsers.map((friendName) {
      return {
        'name': friendName,
        'online':
            true, // Per ora tutti online, in futuro si può implementare la logica real-time
      };
    }).toList();
  } catch (e) {
    debugPrint('Errore nel recupero degli amici: $e');
    return [];
  }
}

// Funzione per controllare login
Future<bool> checkLogin(String username, String password) async {
  if (users[username] == password) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(loggedInKey, true);
    await prefs.setString(loggedUserKey, username);
    return true;
  }
  return false;
}

/// Recupera il bilancio dell'utente da Firebase Realtime Database
Future<double> fetchUserBalance(String username) async {
  if (username.isEmpty) return 0.0;

  try {
    // Prendiamo la password dell'utente dalla mappa users
    final password = users[username];
    if (password == null) {
      debugPrint('Password non trovata per l\'utente: $username');
      return 0.0;
    }

    // Costruiamo l'URL per accedere al bilancio
    final url = Uri.parse('${baseUrl}balances/$password.json');
    debugPrint('Richiesta bilancio URL: $url');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty && response.body != 'null') {
        final value = double.tryParse(response.body.replaceAll('"', '')) ?? 0.0;
        debugPrint('Bilancio convertito: $value');
        return value;
      }
    }
    return 0.0;
  } catch (e) {
    debugPrint('Errore nel recupero del bilancio: $e');
    return 0.0;
  }
}

/// Recupera le attività dell'utente da Firebase Realtime Database
Future<Map<String, dynamic>> fetchUserActivities(String username) async {
  final url = Uri.parse('${baseUrl}activity/$username.json');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is List) {
      // Se i dati sono una lista, converti in mappa con indice come chiave
      return {for (var i = 0; i < data.length; i++) i.toString(): data[i]};
    }
    return {};
  } else {
    throw Exception(
      'Errore nel recupero delle attività: ${response.statusCode}',
    );
  }
}

/// Keep only the first [keep] activity entries for [username] in Firebase.
/// This is a best-effort operation and will overwrite the user's activity node
/// with the reduced set containing only the most recent [keep] entries.
Future<void> trimUserActivities(String username, int keep) async {
  try {
    final url = Uri.parse('${baseUrl}activity/$username.json');
    final resp = await http.get(url);
    if (resp.statusCode != 200) return;
    if (resp.body.isEmpty || resp.body == 'null') return;
    final data = json.decode(resp.body);
    if (data is! Map<String, dynamic>) return;
    final keys = data.keys.toList()..sort((a, b) => b.compareTo(a));
    if (keys.length <= keep) return;
    final keepKeys = keys.take(keep).toList();
    final Map<String, dynamic> newMap = {};
    for (final k in keepKeys) {
      newMap[k] = data[k];
    }
    // overwrite the activity node with the trimmed map
    await http.put(url, body: json.encode(newMap));
  } catch (e) {
    debugPrint('trimUserActivities error: $e');
  }
}

// Funzione per controllare se già loggato
Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(loggedInKey) ?? false;
}

// Funzione per logout (se serve)
Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(loggedInKey);
  await prefs.remove(loggedUserKey);
}

// Salva i dati della card su Firebase
Future<void> saveCardDataToFirebase({
  required String username,
  required String password,
  required String cardPath,
}) async {
  try {
    final url = Uri.parse('${baseUrl}cards.json');
    final data = {
      'username': username,
      'password': password,
      'cardPath': cardPath,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final response = await http.post(url, body: json.encode(data));
    if (response.statusCode != 200) {
      throw Exception('Errore nel salvataggio dei dati della card');
    }
  } catch (e) {
    debugPrint('Errore nel salvataggio dei dati della card: $e');
  }
}

// Restituisce il percorso della card silver in base all'utente
String getSilverCardAsset(String? username) {
  if (username == null)
    return 'asset/images/Card alex/card 1.png'; // default: card silver di alex
  switch (username) {
    case 'alex':
      return 'asset/images/Card alex/card 1.png';
    case 'edo':
      return 'asset/images/Card edo/card 1.png';
    case 'tom&ila':
      return 'asset/images/Card ixt/card 1.png';
    case 'tery':
      return 'asset/images/Card tery/card 1.png';
    default:
      return 'asset/images/Card alex/card 1.png'; // default: card silver di alex
  }
}
