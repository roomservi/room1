import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../library.dart';
import 'profile_window.dart';

class FriendSection extends StatelessWidget {
  final bool isDark;

  const FriendSection({Key? key, required this.isDark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getLoggedUser(),
      builder: (context, snapshot) {
        final username = snapshot.data;
        if (username == null) {
          return const Center(child: CupertinoActivityIndicator());
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: getFriends(username),
          builder: (context, snapshot) {
            final friends = snapshot.data ?? [];

            if (friends.isEmpty) {
              return Center(
                child: Text(
                  'Nessun amico trovato',
                  style: TextStyle(
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
              );
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: friends.length,
              padding: const EdgeInsets.fromLTRB(12, 24, 12, 0),
              itemBuilder: (context, index) {
                final friend = friends[index];
                final friendName = friend['name'] as String? ?? '';

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              ProfileWindow.show(
                                context,
                                username: friendName,
                                isDark: isDark,
                              );
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color:
                                      isDark
                                          ? Colors.white.withOpacity(0.15)
                                          : Colors.black.withOpacity(0.1),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  getProfileImage(friendName),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        friendName,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
