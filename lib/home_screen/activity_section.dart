import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../library.dart';

class ActivitySection extends StatefulWidget {
  final bool isDark;
  final String? username;
  final bool fullscreen;
  final VoidCallback? onShowAll;

  const ActivitySection({
    Key? key,
    required this.isDark,
    required this.username,
    this.fullscreen = false,
    this.onShowAll,
  }) : super(key: key);

  @override
  State<ActivitySection> createState() => _ActivitySectionState();
}

class _ActivitySectionState extends State<ActivitySection> {
  final _notificationHeight = 110.0;
  int _selectedIdx = 0;
  late PageController _pageController;
  final Set<String> _trimmedUsers =
      {}; // track which users we've trimmed already

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      // slightly smaller fraction to avoid tiny overflow on narrow screens
      viewportFraction: 0.92,
      initialPage: _selectedIdx,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _activityDescription(Map activity) {
    final type = activity['type'] ?? '';
    final level = activity['level'] ?? '';
    final amount = activity['amount'] ?? '';
    final from = activity['from'] ?? '';
    final to = activity['to'] ?? '';
    switch (type) {
      case 'subscription':
        return "Hai attivato l'abbonamento $level";
      case 'payment':
        return "Hai effettuato un pagamento di S$amount";
      case 'transfer':
        return "Hai ricevuto un bonifico di S$amount";
      case 'transfer_received':
        return from != ''
            ? "${getDisplayName(from)} ti ha inviato S$amount"
            : "Hai ricevuto un bonifico di S$amount";
      case 'transfer_sent':
        return to != ''
            ? "Hai inviato S$amount a ${getDisplayName(to)}"
            : "Hai inviato un bonifico di S$amount";
      case 'reward':
        return "Hai ricevuto un bonus di S$amount";
      case 'upgrade':
        return "Sei passato al piano $level";
      case 'invite':
        return "Un amico si è unito con il tuo invito";
      default:
        return "Nuova notifica";
    }
  }

  String _formatDateString(String? s) {
    if (s == null || s.isEmpty) return 'Oggi';
    final parsed = DateTime.tryParse(s);
    if (parsed == null) return s;
    final dt = parsed.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    if (diff == 0) return 'Oggi, $hh:$mm';
    if (diff == 1) return 'Ieri, $hh:$mm';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  LinearGradient _subscriptionGradient(String level) {
    // base colors per level, fallback to a neutral blue-green
    final l = level.toString().toLowerCase();
    Color base;
    switch (l) {
      case 'gold':
        base = const Color(0xFFFFBF00);
        break;
      case 'diamond':
        base = const Color(0xFF64F0FF);
        break;
      case 'smerald':
        base = const Color(0xFF00C853);
        break;
      case 'ultra':
        base = const Color(0xFF5856D6);
        break;
      default:
        base = const Color(0xFF34C759);
    }

    // create two lighter/darker tones
    final h = HSLColor.fromColor(base);
    final c1 = h.withLightness((h.lightness + 0.18).clamp(0.0, 1.0)).toColor();
    final c2 = h.withLightness((h.lightness - 0.08).clamp(0.0, 1.0)).toColor();
    final c3 = h.withLightness((h.lightness + 0.05).clamp(0.0, 1.0)).toColor();

    return LinearGradient(
      colors: [c1, c3, c2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  IconData _getActivityIcon(Map activity) {
    final type = activity['type'] ?? '';
    switch (type) {
      case 'subscription':
        return CupertinoIcons.star_circle_fill;
      case 'payment':
        return CupertinoIcons.money_dollar_circle_fill;
      case 'transfer':
      case 'transfer_received':
      case 'transfer_sent':
        return CupertinoIcons.arrow_right_arrow_left_circle_fill;
      case 'reward':
        return CupertinoIcons.gift_fill;
      case 'upgrade':
        return CupertinoIcons.arrow_up_circle_fill;
      case 'invite':
        return CupertinoIcons.person_add_solid;
      default:
        return CupertinoIcons.bell_circle_fill;
    }
  }

  Color _getActivityColor(Map activity) {
    final type = activity['type'] ?? '';
    switch (type) {
      case 'subscription':
        return const Color(0xFFFFBF00); // Amber
      case 'payment':
        return const Color(0xFF34C759); // Verde mela
      case 'transfer':
      case 'transfer_received':
      case 'transfer_sent':
        return const Color(0xFF007AFF); // Blu iOS
      case 'reward':
        return const Color(0xFFFF9500); // Arancione
      case 'upgrade':
        return const Color(0xFF5856D6); // Viola
      case 'invite':
        return const Color(0xFFFF2D55); // Rosa
      default:
        return const Color(0xFF64D2FF); // Azzurro
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.username == null) {
      return const SizedBox.shrink();
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom + 54;

    return FutureBuilder<Map<String, dynamic>>(
      future: fetchUserActivities(widget.username!),
      builder: (context, snapshot) {
        final activities = snapshot.data ?? {};
        final keys = activities.keys.toList()..sort((a, b) => b.compareTo(a));
        // show only the first 5 activities
        final displayKeys = keys.take(5).toList();

        // If there are more than 5 activities, trim on the server (best-effort)
        if (keys.length > 5 &&
            widget.username != null &&
            !_trimmedUsers.contains(widget.username)) {
          _trimmedUsers.add(widget.username!);
          // perform trimming asynchronously and don't block the UI
          trimUserActivities(widget.username!, 5).catchError((e) {
            debugPrint('Failed to trim activities for ${widget.username}: $e');
          });
        }

        if (keys.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Text(
              'Nessuna attività recente',
              style: TextStyle(
                color:
                    widget.isDark
                        ? CupertinoColors.white
                        : CupertinoColors.black,
              ),
            ),
          );
        }

        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _selectedIdx = index);
                },
                scrollDirection: Axis.vertical,
                itemCount: displayKeys.length,
                itemBuilder: (context, index) {
                  final activity = activities[displayKeys[index]];
                  final type = activity['type'] ?? '';
                  final amount = activity['amount']?.toString() ?? '';
                  final dateStr = activity['date'] ?? '';
                  final level = activity['level'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: SizedBox(
                      height: _notificationHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            if (type == 'subscription')
                              Positioned.fill(
                                child: ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: 6,
                                    sigmaY: 6,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: _subscriptionGradient(level),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Positioned.fill(
                                child: Container(
                                  color:
                                      widget.isDark
                                          ? Colors.black.withOpacity(0.12)
                                          : Colors.white.withOpacity(0.02),
                                ),
                              ),
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final from =
                                            activity['from'] as String?;
                                        final to = activity['to'] as String?;
                                        final actor =
                                            (from != null && from.isNotEmpty)
                                                ? from
                                                : (to != null && to.isNotEmpty)
                                                ? to
                                                : null;
                                        if (actor != null) {
                                          return Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white24,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(48),
                                                  child: Image.asset(
                                                    getProfileImage(actor),
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          ctx,
                                                          err,
                                                          stack,
                                                        ) => Icon(
                                                          _getActivityIcon(
                                                            activity,
                                                          ),
                                                          color:
                                                              _getActivityColor(
                                                                activity,
                                                              ),
                                                          size: 22,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6.0),
                                              const Icon(
                                                CupertinoIcons.clock,
                                                size: 12,
                                                color: Colors.white70,
                                              ),
                                            ],
                                          );
                                        }

                                        // fallback to icon if no actor
                                        return Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white.withOpacity(
                                                  0.06,
                                                ),
                                              ),
                                              child: Icon(
                                                _getActivityIcon(activity),
                                                color: _getActivityColor(
                                                  activity,
                                                ),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            const Icon(
                                              CupertinoIcons.clock,
                                              size: 12,
                                              color: Colors.white70,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if ((type == 'payment' ||
                                                  type == 'transfer' ||
                                                  type == 'reward') &&
                                              amount.isNotEmpty)
                                            Text(
                                              'S$amount',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w900,
                                                color:
                                                    widget.isDark
                                                        ? Colors.white
                                                        : const Color(
                                                          0xFF111111,
                                                        ),
                                                shadows: [
                                                  const Shadow(
                                                    color: Colors.black45,
                                                    offset: Offset(0, 1),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            )
                                          else
                                            Builder(
                                              builder: (_) {
                                                final from =
                                                    activity['from'] as String?;
                                                final to =
                                                    activity['to'] as String?;
                                                final actor =
                                                    (from != null &&
                                                            from.isNotEmpty)
                                                        ? from
                                                        : (to != null &&
                                                            to.isNotEmpty)
                                                        ? to
                                                        : null;
                                                final title =
                                                    actor != null
                                                        ? getDisplayName(actor)
                                                        : (activity['level'] ??
                                                            '');
                                                return Text(
                                                  title,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        widget.isDark
                                                            ? CupertinoColors
                                                                .white
                                                            : const Color(
                                                              0xFF1C1C1E,
                                                            ),
                                                  ),
                                                );
                                              },
                                            ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _activityDescription(activity),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  widget.isDark
                                                      ? const Color(0xFFE5E5EA)
                                                      : const Color(0xFF3A3A3C),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _formatDateString(dateStr),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        widget.isDark
                                                            ? const Color(
                                                              0xFF8E8E93,
                                                            )
                                                            : const Color(
                                                              0xFF8E8E93,
                                                            ),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color:
                                                      widget.isDark
                                                          ? Colors.white12
                                                          : Colors.black12,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                type
                                                    .toString()
                                                    .replaceAll('_', ' ')
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      widget.isDark
                                                          ? const Color(
                                                            0xFF8E8E93,
                                                          )
                                                          : const Color(
                                                            0xFF8E8E93,
                                                          ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (keys.length > 1)
              Positioned(
                top: 0,
                bottom: bottomPadding,
                right: 20,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      keys.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _selectedIdx == index
                                  ? CupertinoColors.systemBlue
                                  : widget.isDark
                                  ? const Color(0xFF48484A).withOpacity(0.6)
                                  : const Color(0xFFD1D1D6).withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
