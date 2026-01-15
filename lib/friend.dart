// Tutta la logica e i widget friend vanno qui, funzioni e liste in library.dart
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'library.dart';

class FriendSection extends StatefulWidget {
  const FriendSection({Key? key}) : super(key: key);

  @override
  State<FriendSection> createState() => _FriendSectionState();
}

class _FriendSectionState extends State<FriendSection> {
  List<String> _friends = [];
  String? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final user = await getLoggedUser();
    final others = await getOtherUsers(user);
    setState(() {
      _currentUser = user;
      _friends = others;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg =
        isDark
            ? const Color(0xFF23232B).withOpacity(0.85)
            : const Color(0xFFF2F2F7).withOpacity(0.85);
    final Color shadow =
        isDark
            ? Colors.black.withOpacity(0.25)
            : const Color(0xFFB0B0B0).withOpacity(0.10);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      CupertinoIcons.person_2_fill,
                      size: 22,
                      color: CupertinoColors.activeBlue,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Amici',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _friends.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, i) {
                      final username = _friends[i];
                      final name = getDisplayName(username);
                      final img = getProfileImage(username);
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              img,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(name, style: const TextStyle(fontSize: 13)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
