import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../main.dart';
import '../video_controller_provider.dart';
import 'package:flutter/material.dart';
import '../nfc_reader.dart';
import 'nfc_window.dart';
import 'upgrade_screen.dart';
import 'send_screen.dart';
import 'shop_screen.dart';
import 'upgrade_logic.dart' as upgrade;
import 'friend_section.dart';
import 'profile_window.dart';
import 'dart:ui';

import '../library.dart';
import 'card_fullscreen.dart';
import 'activity_section.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int)? onFocusCardChanged;

  const HomeScreen({Key? key, this.onFocusCardChanged}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showBalance = false;
  double? _balance;
  bool _loadingBalance = false;
  String? _cardAsset;
  String? _username;
  String? _password;
  late final PageController _pageController;
  var _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0, initialPage: 0);
    // Mostra sempre la card silver personalizzata come placeholder
    _cardAsset = getSilverCardAsset(_username ?? '');
    _loadUser();
    // Start NFC listening after first frame so context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final themeNotifier = Provider.of<ThemeNotifier>(
          context,
          listen: false,
        );
        final isDark = themeNotifier.isDark;
        NFCReader.startListening(
          onMatch: (code, value) async {
            final payload = value ?? '';
            String usernameFromMap = '';
            // If payload looks like our 'roomone' card payload, use logged user or empty
            if (payload.contains('roomone')) {
              final logged = await getLoggedUser();
              usernameFromMap = logged ?? '';
            } else {
              // try to find username by password mapping
              usernameFromMap =
                  users.entries
                      .firstWhere(
                        (e) => e.value == payload,
                        orElse: () => MapEntry(payload, payload),
                      )
                      .key;
            }
            final password = payload;
            // Ensure UI work runs on the main frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              try {
                // stop native listening before opening UI to avoid race conditions
                NFCReader.stopListening();
              } catch (_) {}
              try {
                NfcWindow.show(
                  context,
                  username: usernameFromMap,
                  isDark: isDark,
                  cardCode: code,
                  password: password,
                );
              } catch (e) {
                debugPrint('Error showing NfcWindow: $e');
              }
            });
          },
          onNoMatch: (String reason) {
            debugPrint('No NFC match found: $reason');
          },
        );
      } catch (e) {
        debugPrint('Error starting NFC listening: $e');
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await getLoggedUser();
    setState(() {
      _username = user;
      _password = users[user ?? ''] ?? '';
    });
    await _loadCardAsset();
  }

  Future<void> _loadCardAsset() async {
    if (_password == null || _username == null) {
      setState(() {
        _cardAsset = getSilverCardAsset(_username ?? ''); // mai rect1
      });
      return;
    }
    final asset = await getUserCardAsset(_password!, username: _username!);
    setState(() {
      _cardAsset =
          (asset != null && asset.isNotEmpty)
              ? asset
              : getSilverCardAsset(_username ?? ''); // mai rect1
    });
  }

  Future<void> _toggleBalance() async {
    setState(() => _showBalance = !_showBalance);
    if (_showBalance && _balance == null && !_loadingBalance) {
      setState(() => _loadingBalance = true);
      try {
        final balance = await fetchUserBalance(_username ?? '');
        if (mounted) {
          setState(() {
            _balance = balance;
            _loadingBalance = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loadingBalance = false);
        }
        print('Errore nel caricamento del bilancio: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: true);
    final isDark = themeNotifier.isDark;
    final displayName = getDisplayName(_username);
    final videoProvider = Provider.of<VideoControllerProvider>(context);
    final videoController = videoProvider.controller;
    final videoReady = videoProvider.isInitialized;
    final screenHeight = MediaQuery.of(context).size.height;
    final Color panelColor =
        isDark ? const Color(0xFF23232B) : CupertinoColors.white;

    return CupertinoPageScaffold(
      navigationBar: null,
      child: Stack(
        children: [
          if (videoReady)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: VideoPlayer(videoController),
              ),
            )
          else
            Positioned.fill(
              child: Container(color: CupertinoColors.systemBackground),
            ),
          if (videoReady)
            Positioned.fill(
              child: Container(color: CupertinoColors.black.withOpacity(0.08)),
            ),
          // Sfumatura in fondo sopra la navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 54, // altezza della dissolvenza
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      panelColor.withOpacity(0.0),
                      panelColor.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Riquadro metà inferiore con dark mode e amici
          Positioned(
            left: 0,
            right: 0,
            top: screenHeight * 0.5,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 64),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(
                      'Amici',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(height: 104, child: FriendSection(isDark: isDark)),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Text(
                      'Attività',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ActivitySection(
                      isDark: isDark,
                      username: _username,
                      fullscreen: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tre pulsanti tondi a cavallo tra riquadro e sfondo
          Positioned(
            left: 0,
            right: 0,
            top: screenHeight * 0.5 - 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => const UpgradeScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? const Color(0xFF23232B)
                                : CupertinoColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.star_lefthalf_fill, // upgrade (stelline)
                        color:
                            isDark
                                ? CupertinoColors.systemYellow
                                : CupertinoColors.activeBlue,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const SendScreen()),
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? const Color(0xFF23232B)
                                : CupertinoColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.paperplane, // send
                        color:
                            isDark
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.activeBlue,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(builder: (_) => const ShopScreen()),
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? const Color(0xFF23232B)
                                : CupertinoColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.bag, // shop
                        color:
                            isDark
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.activeBlue,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Contenuto superiore: profilo, saluto, switch tema, card
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          ProfileWindow.show(
                            context,
                            username: _username ?? '',
                            isDark: isDark,
                          );
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isDark
                                      ? Colors.white.withOpacity(0.15)
                                      : Colors.black.withOpacity(0.1),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              getProfileImage(_username),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF23232B).withOpacity(0.85)
                                  : CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Ciao $displayName',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF23232B).withOpacity(0.85)
                                  : CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pulsante NFC a sinistra
                            CupertinoButton(
                              padding: const EdgeInsets.all(6),
                              minSize: 36,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.creditcard,
                                    color: CupertinoColors.systemBlue,
                                    size: 18,
                                  ),
                                  const SizedBox(height: 2),
                                  Icon(
                                    CupertinoIcons.wifi,
                                    color: CupertinoColors.systemBlue,
                                    size: 8,
                                  ),
                                ],
                              ),
                              onPressed: () {
                                // Attiva la scansione NFC manuale
                                NFCReader.stopListening();
                                NFCReader.startListening(
                                  onMatch: (code, value) async {
                                    final payload = value ?? '';
                                    String usernameFromMap = '';
                                    if (payload.contains('roomone')) {
                                      final logged = await getLoggedUser();
                                      usernameFromMap = logged ?? '';
                                    } else {
                                      usernameFromMap =
                                          users.entries
                                              .firstWhere(
                                                (e) => e.value == payload,
                                                orElse:
                                                    () => MapEntry(
                                                      payload,
                                                      payload,
                                                    ),
                                              )
                                              .key;
                                    }
                                    final password = payload;
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (!mounted) return;
                                          try {
                                            NFCReader.stopListening();
                                          } catch (_) {}
                                          try {
                                            NfcWindow.show(
                                              context,
                                              username: usernameFromMap,
                                              isDark: isDark,
                                              cardCode: code,
                                              password: password,
                                            );
                                          } catch (e) {
                                            debugPrint(
                                              'Error showing NfcWindow: $e',
                                            );
                                          }
                                        });
                                  },
                                  onNoMatch: (String reason) {
                                    debugPrint('No NFC match found: $reason');
                                  },
                                );
                              },
                            ),
                            // Pulsante Tema a destra
                            CupertinoButton(
                              padding: const EdgeInsets.all(6),
                              minSize: 36,
                              child: Icon(
                                isDark
                                    ? CupertinoIcons.moon_fill
                                    : CupertinoIcons.sun_max_fill,
                                color:
                                    isDark
                                        ? CupertinoColors.systemYellow
                                        : CupertinoColors.activeBlue,
                              ),
                              onPressed: () => themeNotifier.toggleTheme(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child:
                      _username == null
                          ? const Center(child: CupertinoActivityIndicator())
                          : GestureDetector(
                            onTap: _toggleBalance,
                            onLongPress: () {
                              if (_cardAsset != null) {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    opaque: false,
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => CardFullscreenView(
                                          cardAsset: _cardAsset!,
                                          isDark: isDark,
                                          onVerticalDragUpdate: (delta) {
                                            if (delta < -10) {
                                              // Salva i dati su Firebase quando si trascina verso l'alto
                                              saveCardDataToFirebase(
                                                username: _username ?? '',
                                                password: _password ?? '',
                                                cardPath: _cardAsset ?? '',
                                              );
                                            }
                                          },
                                          onDismiss: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                  ),
                                );
                              }
                            },
                            child: SizedBox(
                              height: 220,
                              width: double.infinity,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder:
                                    (child, animation) => FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                layoutBuilder:
                                    (currentChild, previousChildren) => Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ...previousChildren,
                                        if (currentChild != null) currentChild,
                                      ],
                                    ),
                                child: Container(
                                  key: ValueKey(
                                    _showBalance ? 'saldo' : 'card',
                                  ),
                                  alignment: Alignment.center,
                                  height: 220,
                                  width: double.infinity,
                                  child:
                                      _showBalance
                                          ? _loadingBalance
                                              ? const CupertinoActivityIndicator()
                                              : Text(
                                                _balance != null
                                                    ? 'S${_balance!.toStringAsFixed(2)}'
                                                    : '',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.2,
                                                  shadows: [
                                                    Shadow(
                                                      offset: Offset(0, 2),
                                                      blurRadius: 4,
                                                      color: Colors.black26,
                                                    ),
                                                  ],
                                                ),
                                              )
                                          : Image.asset(
                                            _cardAsset ??
                                                getSilverCardAsset(
                                                  _username ?? '',
                                                ),
                                            fit: BoxFit.contain,
                                            height: 220,
                                          ),
                                ),
                              ),
                            ),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
