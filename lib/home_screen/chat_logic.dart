import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../library.dart';

class Friend {
  final String userId;
  final String name;
  final String? photoUrl;
  final bool isOnline;

  Friend({
    required this.userId,
    required this.name,
    this.photoUrl,
    this.isOnline = false,
  });

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
    userId: json['userId'] as String,
    name: json['name'] as String,
    photoUrl: json['photoUrl'] as String?,
    isOnline: json['isOnline'] as bool? ?? false,
  );
}

Future<List<Friend>> getFriends(String userId) async {
  try {
    final url = Uri.parse('${baseUrl}users/$userId/friends.json');
    final response = await http.get(url);

    if (response.statusCode == 200 && response.body != 'null') {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data.values
          .map((friend) => Friend.fromJson(friend as Map<String, dynamic>))
          .toList();
    }
    return [];
  } catch (e) {
    debugPrint('Error fetching friends: $e');
    return [];
  }
}

Future<bool> addFriend(
  String userId,
  String friendId,
  String friendName,
) async {
  try {
    final friendData = {
      'userId': friendId,
      'name': friendName,
      'isOnline': false,
    };

    final url = Uri.parse('${baseUrl}users/$userId/friends/$friendId.json');
    final response = await http.put(url, body: json.encode(friendData));

    return response.statusCode == 200;
  } catch (e) {
    debugPrint('Error adding friend: $e');
    return false;
  }
}

class Message {
  final String sender;
  final String receiver;
  final String content;
  final DateTime timestamp;

  Message({
    required this.sender,
    required this.receiver,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'sender': sender,
    'receiver': receiver,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    sender: json['sender'] as String,
    receiver: json['receiver'] as String,
    content: json['content'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class Chat {
  final String otherUser;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool unread;

  Chat({
    required this.otherUser,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unread = false,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
    otherUser: json['otherUser'] as String,
    lastMessage: json['lastMessage'] as String,
    lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
    unread: json['unread'] as bool? ?? false,
  );
}

Future<List<Chat>> getChats(String currentUser) async {
  try {
    // Use messages root as the single source of truth. Iterate chat IDs and pick those involving currentUser.
    final url = Uri.parse('${baseUrl}messages.json');
    debugPrint('GET all messages URL: $url');
    final response = await http.get(url);
    debugPrint('GET all messages status: ${response.statusCode}');
    if (response.statusCode != 200 ||
        response.body == 'null' ||
        response.body.isEmpty) {
      debugPrint('No messages root available');
      return [];
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      debugPrint('Unexpected messages root type: ${decoded.runtimeType}');
      return [];
    }

    final List<Chat> results = [];

    for (final entry in decoded.entries) {
      final chatId = entry.key; // e.g. 'alex-tom&ila'
      if (!chatId.contains(currentUser)) continue;
      final payload = entry.value;
      if (payload == null) continue;

      try {
        if (payload is! Map<String, dynamic>) continue;
        final msgsMap = payload;

        DateTime? latestTime;
        String lastMessage = '';
        String otherUser = '';

        for (final m in msgsMap.values) {
          if (m is Map<String, dynamic>) {
            final tsStr = m['timestamp'] as String?;
            DateTime? ts;
            if (tsStr != null) {
              try {
                ts = DateTime.parse(tsStr);
              } catch (_) {}
            }
            if (latestTime == null || (ts != null && ts.isAfter(latestTime))) {
              latestTime = ts;
              lastMessage = (m['content'] as String?) ?? '';
              final sender = (m['sender'] as String?) ?? '';
              final receiver = (m['receiver'] as String?) ?? '';
              otherUser = sender == currentUser ? receiver : sender;
            }
          }
        }

        if (latestTime != null && otherUser.isNotEmpty) {
          results.add(
            Chat(
              otherUser: otherUser,
              lastMessage: lastMessage,
              lastMessageTime: latestTime,
              unread: false,
            ),
          );
        }
      } catch (e) {
        debugPrint('Failed parsing messages for chat $chatId: $e');
        continue;
      }
    }

    results.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return results;
  } catch (e) {
    debugPrint('Error fetching chats: $e');
    return [];
  }
}

Future<List<Message>> getMessages(String currentUser, String otherUser) async {
  try {
    final chatId = [currentUser, otherUser]..sort();
    final url = Uri.parse('${baseUrl}messages/${chatId.join('-')}.json');
    final response = await http.get(url);
    debugPrint('GET messages URL: $url');
    debugPrint('GET messages status: ${response.statusCode}');
    if (response.statusCode == 200) {
      if (response.body == 'null' || response.body.isEmpty) {
        debugPrint('GET messages body is null or empty');
        return [];
      }
      debugPrint(
        'GET messages body (snippet): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
      );
      final decoded = json.decode(response.body);
      Iterable<Map<String, dynamic>> items;
      if (decoded is Map<String, dynamic>) {
        items = decoded.values.map((e) => e as Map<String, dynamic>);
        debugPrint('GET messages decoded as Map with ${decoded.length} keys');
      } else if (decoded is List) {
        items = decoded
            .where((e) => e != null)
            .map((e) => e as Map<String, dynamic>);
        debugPrint('GET messages decoded as List with ${decoded.length} items');
      } else {
        debugPrint('GET messages decoded unknown type: ${decoded.runtimeType}');
        return [];
      }

      return items.map((msg) => Message.fromJson(msg)).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return [];
  } catch (e) {
    debugPrint('Error fetching messages: $e');
    return [];
  }
}

Future<bool> sendMessage(
  String sender,
  String receiver,
  String content, {
  String? messageId,
  String? timestampIso,
}) async {
  try {
    debugPrint('Sending message from $sender to $receiver');
    final chatId = [sender, receiver]..sort();
    debugPrint('Chat ID: ${chatId.join('-')}');
    final usedMessageId =
        messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final usedTimestamp =
        timestampIso != null ? DateTime.parse(timestampIso) : DateTime.now();
    final message = Message(
      sender: sender,
      receiver: receiver,
      content: content,
      timestamp: usedTimestamp,
    );
    debugPrint('Message object created: ${message.toJson()}');

    // Salva il messaggio
    final messageUrl = Uri.parse(
      '${baseUrl}messages/${chatId.join('-')}/$usedMessageId.json',
    );
    final messageResponse = await http.put(
      messageUrl,
      body: json.encode(message.toJson()),
    );

    // We now keep only the `messages` node as source of truth.
    // Do not update `chats` here. If you previously relied on a `chats` summary node,
    // remove it from Firebase; the UI now derives chat list from `messages`.

    return messageResponse.statusCode == 200;
  } catch (e) {
    debugPrint('Error sending message: $e');
    return false;
  }
}

Future<bool> markChatAsRead(String currentUser, String otherUser) async {
  try {
    // Since we keep only `messages` as source of truth, there's no `chats` node to patch.
    // This function is a noop to avoid failures if `chats` node is removed.
    debugPrint(
      'markChatAsRead: noop (using messages-only model) for $currentUser/$otherUser',
    );
    return true;
  } catch (e) {
    debugPrint('Error marking chat as read: $e');
    return false;
  }
}

/// Trasferisce `amount` dal conto di `sender` al conto di `receiver`.
/// Ritorna true se l'operazione è andata a buon fine.
Future<bool> transferMoney(
  String sender,
  String receiver,
  double amount,
) async {
  try {
    // Basic validation
    if (sender == receiver) {
      debugPrint('transferMoney: self-transfer not allowed');
      return false;
    }
    if (amount <= 0 || amount.isNaN) {
      debugPrint('transferMoney: invalid amount $amount');
      return false;
    }

    // Ottieni le 'password' usate come chiave per i bilanci
    final senderKey = users[sender];
    final receiverKey = users[receiver];
    if (senderKey == null || receiverKey == null) {
      debugPrint('Impossibile trovare le chiavi dei bilanci per gli utenti');
      return false;
    }

    final senderUrl = Uri.parse('${baseUrl}balances/$senderKey.json');
    final receiverUrl = Uri.parse('${baseUrl}balances/$receiverKey.json');

    // Leggi i bilanci attuali
    final responses = await Future.wait([
      http.get(senderUrl),
      http.get(receiverUrl),
    ]);
    if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
      debugPrint(
        'Errore nel leggere i bilanci: ${responses.map((r) => r.statusCode).toList()}',
      );
      return false;
    }

    double senderBal = 0.0;
    double receiverBal = 0.0;
    try {
      if (responses[0].body.isNotEmpty && responses[0].body != 'null') {
        senderBal =
            double.tryParse(responses[0].body.replaceAll('"', '')) ?? 0.0;
      }
      if (responses[1].body.isNotEmpty && responses[1].body != 'null') {
        receiverBal =
            double.tryParse(responses[1].body.replaceAll('"', '')) ?? 0.0;
      }
    } catch (e) {
      debugPrint('Errore nel parsing dei bilanci: $e');
      return false;
    }

    if (senderBal < amount) {
      debugPrint('Saldo insufficiente: $senderBal < $amount');
      return false;
    }

    // Round to cents
    double newSender = ((senderBal - amount) * 100).roundToDouble() / 100.0;
    double newReceiver = ((receiverBal + amount) * 100).roundToDouble() / 100.0;

    // Attempt to write new balances. We deduct sender first and if crediting receiver fails,
    // attempt to rollback the sender's balance to avoid money loss.
    final putSenderResp = await http.put(
      senderUrl,
      body: json.encode(newSender),
    );
    if (putSenderResp.statusCode != 200) {
      debugPrint(
        'Errore nel salvataggio del nuovo saldo del mittente: ${putSenderResp.statusCode}',
      );
      return false;
    }

    final putReceiverResp = await http.put(
      receiverUrl,
      body: json.encode(newReceiver),
    );
    if (putReceiverResp.statusCode != 200) {
      debugPrint(
        'Errore nel salvataggio del nuovo saldo del destinatario: ${putReceiverResp.statusCode} - attempting rollback',
      );
      // rollback sender
      try {
        await http.put(senderUrl, body: json.encode(senderBal));
      } catch (e) {
        debugPrint('Rollback failed: $e');
      }
      return false;
    }

    debugPrint('Trasferimento completato: $amount da $sender a $receiver');

    // Registra una activity per entrambi gli utenti (best-effort)
    try {
      final nowIso = DateTime.now().toIso8601String();

      Future<void> _appendActivity(
        String username,
        Map<String, dynamic> activity,
      ) async {
        final url = Uri.parse('${baseUrl}activity/$username.json');
        final resp = await http.get(url);
        Map<String, dynamic> activities = {};
        if (resp.statusCode == 200 &&
            resp.body.isNotEmpty &&
            resp.body != 'null') {
          try {
            activities = json.decode(resp.body) as Map<String, dynamic>;
          } catch (_) {
            activities = {};
          }
        }

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
        activities[activityKey] = activity;
        await http.put(url, body: json.encode(activities));
      }

      final senderActivity = {
        'type': 'transfer_sent',
        'amount': amount,
        'to': receiver,
        'date': nowIso,
      };
      final receiverActivity = {
        'type': 'transfer_received',
        'amount': amount,
        'from': sender,
        'date': nowIso,
      };

      await _appendActivity(sender, senderActivity);
      await _appendActivity(receiver, receiverActivity);
    } catch (e) {
      debugPrint('Errore nel logging dell\'activity: $e');
    }

    return true;
  } catch (e) {
    debugPrint('Error transferring money: $e');
    return false;
  }
}
