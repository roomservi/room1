import 'package:http/http.dart' as http;
import 'dart:convert';
import '../library.dart';
import 'activity_logic.dart';

// Restituisce il percorso della card per livello e utente
String getCardAssetForLevel(String username, String level) {
  final folder = username == 'tom&ila' ? 'ixt' : username;
  switch (level.toLowerCase()) {
    case 'gold':
      return 'asset/images/Card $folder/card oro 1.png';
    case 'diamond':
      return 'asset/images/Card $folder/card diamond 1.png';
    case 'smerald':
      return 'asset/images/Card $folder/card smerald 1.png';
    case 'ultra':
      return 'asset/images/Card $folder/card ultra 1.png';
    default:
      return getSilverCardAsset(username);
  }
}

// Leggi il livello di abbonamento dell'utente da Firebase
Future<String?> getUserLevel(String password) async {
  final url = Uri.parse('${baseUrl}level_card/$password/level.json');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final value = jsonDecode(response.body);
    return value is String ? value : null;
  }
  return null;
}

// Scrivi il livello di abbonamento dell'utente su Firebase (nome abbonamento con maiuscola)
Future<bool> setUserLevel(String password, String level) async {
  final levelName = level[0].toUpperCase() + level.substring(1).toLowerCase();
  final url = Uri.parse('${baseUrl}level_card/$password/level.json');
  final response = await http.put(url, body: jsonEncode(levelName));
  return response.statusCode == 200;
}

// Leggi la data di rinnovo dell'abbonamento da Firebase
Future<DateTime?> getRenewalDate(String password) async {
  final url = Uri.parse('${baseUrl}level_card/$password/renewal_date.json');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final value = jsonDecode(response.body);
    if (value is String) {
      return DateTime.tryParse(value);
    }
  }
  return null;
}

// Scrivi la data di rinnovo dell'abbonamento su Firebase
Future<bool> setRenewalDate(String password, DateTime date) async {
  final url = Uri.parse('${baseUrl}level_card/$password/renewal_date.json');
  final response = await http.put(
    url,
    body: jsonEncode(date.toIso8601String()),
  );
  return response.statusCode == 200;
}

// Salva il percorso della card su Firebase
Future<bool> setUserCardAsset(String password, String assetPath) async {
  final url = Uri.parse('${baseUrl}level_card/$password/card_asset.json');
  final response = await http.put(url, body: jsonEncode(assetPath));
  return response.statusCode == 200;
}

// Funzione da chiamare quando l'utente si abbona
Future<bool> subscribeUser(
  String password,
  String username,
  String level,
) async {
  final now = DateTime.now();
  final nextRenewal = now.add(const Duration(days: 7));
  await deductWeeklyFee(password, level);
  final assetPath = getCardAssetForLevel(username, level);
  final ok1 = await setUserLevel(password, level);
  final ok2 = await setRenewalDate(password, nextRenewal);
  final ok3 = await setUserCardAsset(password, assetPath);
  // Log activity
  await logSubscriptionActivity(username, password, level);
  return ok1 && ok2 && ok3;
}

// Leggi il percorso della card da Firebase
Future<String?> getUserCardAsset(String password, {String? username}) async {
  final url = Uri.parse('${baseUrl}level_card/$password/card_asset.json');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final value = jsonDecode(response.body);
    if (value is String && value.isNotEmpty) {
      return value;
    }
  }
  // Se non c'è asset, restituisci la card silver personalizzata
  if (username != null) {
    return getSilverCardAsset(username);
  }
  return 'asset/images/Card alex/card 1.png';
}

// Scala la quota settimanale dal balance
Future<bool> deductWeeklyFee(String password, String level) async {
  final url = Uri.parse('${baseUrl}balances/$password.json');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final value = double.tryParse(response.body.replaceAll('"', '')) ?? 0.0;
    double fee = 0.0;
    switch (level.toLowerCase()) {
      case 'gold':
        fee = 2.99;
        break;
      case 'diamond':
        fee = 5.99;
        break;
      case 'smerald':
        fee = 9.99;
        break;
      case 'ultra':
        fee = 19.99;
        break;
    }
    final newBalance = value - fee;
    final putResp = await http.put(url, body: jsonEncode(newBalance));
    return putResp.statusCode == 200;
  }
  return false;
}

// Funzione per controllare e aggiornare la data di rinnovo (da chiamare all'avvio o login)
Future<bool> checkAndRenewSubscription(
  String password,
  String username,
  String level,
) async {
  final renewalDate = await getRenewalDate(password);
  final now = DateTime.now();
  if (renewalDate == null || now.isAfter(renewalDate)) {
    final feePaid = await deductWeeklyFee(password, level);
    if (!feePaid) {
      // Saldo insufficiente: downgrade a Silver
      await initializeUserAsSilver(password, username);
      return false;
    }
    final nextRenewal = now.add(const Duration(days: 7));
    final ok = await setRenewalDate(password, nextRenewal);
    // Aggiorna anche la card asset
    final assetPath = getCardAssetForLevel(username, level);
    await setUserCardAsset(password, assetPath);
    return ok;
  }
  return true;
}

// Inizializza l'account su silver di default
Future<void> initializeUserAsSilver(String password, String username) async {
  final assetPath = getSilverCardAsset(username);
  await setUserLevel(password, 'Silver');
  await setUserCardAsset(password, assetPath);
  // Puoi anche azzerare la data di rinnovo se serve
  final url = Uri.parse('${baseUrl}level_card/$password/renewal_date.json');
  await http.put(url, body: jsonEncode(null));
}

// Scrivi una nuova attività di abbonamento nella sezione activity su Firebase
Future<bool> logSubscriptionActivity(
  String username,
  String password,
  String level,
) async {
  // Leggi le attività esistenti
  final url = Uri.parse('${baseUrl}activity/$username.json');
  final response = await http.get(url);
  Map<String, dynamic> activities = {};
  if (response.statusCode == 200 &&
      response.body.isNotEmpty &&
      response.body != 'null') {
    activities = jsonDecode(response.body);
  }
  // Trova il prossimo indice
  int nextIndex = 1;
  if (activities.isNotEmpty) {
    final keys =
        activities.keys.where((k) => k.startsWith('activity ')).toList();
    if (keys.isNotEmpty) {
      final last = keys
          .map((k) => int.tryParse(k.replaceAll('activity ', '')) ?? 0)
          .fold(0, (a, b) => a > b ? a : b);
      nextIndex = last + 1;
    }
  }
  final activityKey = 'activity ${nextIndex.toString().padLeft(2, '0')}';
  final now = DateTime.now().toIso8601String();
  final activityData = {
    'type': 'subscription',
    'level': level,
    'date': now,
    'password': password,
  };
  activities[activityKey] = activityData;
  // Scrivi su Firebase
  final putResp = await http.put(url, body: jsonEncode(activities));
  return putResp.statusCode == 200;
}
