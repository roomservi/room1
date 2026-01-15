import 'package:http/http.dart' as http;
import 'dart:convert';
import '../library.dart';

// Registra una nuova attività di abbonamento nella sezione activity su Firebase
Future<void> logSubscriptionActivity(String password, String level) async {
  final url = Uri.parse('${baseUrl}activity/$password.json');
  final response = await http.get(url);
  int nextIndex = 1;
  if (response.statusCode == 200 && response.body != 'null') {
    final activities = jsonDecode(response.body) as Map<String, dynamic>;
    nextIndex = activities.length + 1;
  }
  final activityKey = 'activity ${nextIndex.toString().padLeft(2, '0')}';
  final now = DateTime.now();
  final activityData = {
    'type': 'subscription',
    'level': level,
    'date': now.toIso8601String(),
  };
  final activityUrl = Uri.parse(
    '${baseUrl}activity/$password/$activityKey.json',
  );
  await http.put(activityUrl, body: jsonEncode(activityData));
}
