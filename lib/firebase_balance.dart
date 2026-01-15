import 'package:firebase_database/firebase_database.dart';
import 'library.dart';

// Ottieni il pin (password) dell'utente loggato
Future<String?> getLoggedUserPin() async {
  final user = await getLoggedUser();
  if (user == null) return null;
  return users[user];
}

// Leggi il saldo dal nodo balances/<pin>
Future<double?> fetchBalanceByPin() async {
  final pin = await getLoggedUserPin();
  if (pin == null) return null;
  final dbRef = FirebaseDatabase.instance.ref();
  final snapshot = await dbRef.child('balances/$pin').get();
  if (snapshot.exists) {
    final value = snapshot.value;
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value);
    }
  }
  return null;
}
