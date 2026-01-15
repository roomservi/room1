import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../valutation_screen.dart';
import '../library.dart';
import 'card_fullscreen.dart';
import 'send_screen.dart';

class NfcWindow extends StatefulWidget {
  final String username;
  final bool isDark;
  final String cardCode; // NFC code read from tag
  final String password; // mapped value (user password/id)

  const NfcWindow({
    Key? key,
    required this.username,
    required this.isDark,
    required this.cardCode,
    required this.password,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required String username,
    required bool isDark,
    required String cardCode,
    required String password,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Material(
            type: MaterialType.transparency,
            child: NfcWindow(
              username: username,
              isDark: isDark,
              cardCode: cardCode,
              password: password,
            ),
          ),
    );
  }

  @override
  State<NfcWindow> createState() => _NfcWindowState();
}

class _NfcWindowState extends State<NfcWindow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _showBalance = false;
  double? _balance;
  bool _loadingBalance = false;
  String? _cardAsset;
  // Page controller to allow swiping between card and favorites
  late PageController _pageController;
  int _pageIndex = 0;

  // Favorites & profile-related data
  List<int> _favorites = [];
  List<dynamic> _favoriteMovies = [];
  Map<int, int> _ratings = {};
  bool _loadingFavorites = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _loadCardAsset();
    _pageController = PageController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _loadingFavorites = true);
    try {
      // First try to load from Firebase ratings/<username>
      final url = Uri.parse(
        '$baseUrl'
        'ratings/${widget.username}.json',
      );
      final resp = await http.get(url);
      if (resp.statusCode == 200 &&
          resp.body.isNotEmpty &&
          resp.body != 'null') {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        // data stored as per-movie entries: { "<movieId>": { rating, favoriteSlot, liked, saved, poster, title } }
        _favorites = [];
        _favoriteMovies = [];
        _ratings = {};

        data.forEach((k, v) {
          final mid = int.tryParse(k) ?? 0;
          if (mid == 0) return;
          if (v is Map<String, dynamic>) {
            final ratingVal = (v['rating'] as num?)?.toInt();
            final favSlot = (v['favoriteSlot'] as num?)?.toInt();
            final title = (v['title'] as String?) ?? '';
            final poster = (v['poster'] as String?) ?? '';

            if (ratingVal != null && ratingVal > 0) _ratings[mid] = ratingVal;
            if (favSlot != null && favSlot >= 0) {
              while (_favorites.length <= favSlot) _favorites.add(0);
              _favorites[favSlot] = mid;
              // build a lightweight movie entry from stored title/poster
              _favoriteMovies.add({
                'id': mid,
                'title': title,
                'poster_path': poster,
              });
            }
          }
        });
      } else {
        // No firebase ratings data for this user: show nothing
        _favorites = [];
        _favoriteMovies = [];
        _ratings = {};
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    } finally {
      if (mounted) setState(() => _loadingFavorites = false);
    }
  }

  Future<dynamic> _fetchMovieDetails(int movieId) async {
    try {
      final url = Uri.parse(
        'https://api.themoviedb.org/3/movie/$movieId?api_key=394015efe2fb5614278f8ddf9148e1e2',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching movie $movieId: $e');
    }
    return null;
  }

  Future<void> _loadCardAsset() async {
    final password = users[widget.username] ?? '';
    final asset = await getUserCardAsset(password, username: widget.username);
    if (mounted) {
      setState(() {
        _cardAsset =
            (asset != null && asset.isNotEmpty)
                ? asset
                : getSilverCardAsset(widget.username);
      });
    }
  }

  // Card-specific balance stored in Firebase under `card_balances/<cardCode>.json`
  Future<double> _fetchCardBalance(String cardCode) async {
    try {
      final url = Uri.parse(
        '${baseUrl}card_balances/${Uri.encodeComponent(cardCode)}.json',
      );
      final res = await http.get(url);
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        return double.tryParse(res.body.replaceAll('"', '')) ?? 0.0;
      }
    } catch (e) {
      debugPrint('Error fetching card balance: $e');
    }
    return 0.0;
  }

  Future<void> _setCardBalance(String cardCode, double value) async {
    try {
      final url = Uri.parse(
        '${baseUrl}card_balances/${Uri.encodeComponent(cardCode)}.json',
      );
      await http.put(url, body: json.encode(value.toStringAsFixed(2)));
    } catch (e) {
      debugPrint('Error setting card balance: $e');
    }
  }

  Future<void> _setUserBalanceByPassword(String password, double value) async {
    try {
      final encoded = Uri.encodeComponent(password);
      final url = Uri.parse('${baseUrl}balances/${encoded}.json');
      await http.put(url, body: json.encode(value.toStringAsFixed(2)));
    } catch (e) {
      debugPrint('Error setting user balance: $e');
    }
  }

  Future<double> _getUserBalanceByPassword(String password) async {
    try {
      final encoded = Uri.encodeComponent(password);
      final url = Uri.parse('${baseUrl}balances/${encoded}.json');
      final res = await http.get(url);
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        return double.tryParse(res.body.replaceAll('"', '')) ?? 0.0;
      }
    } catch (e) {
      debugPrint('Error getting user balance: $e');
    }
    return 0.0;
  }

  Future<void> _onTransfer({required bool fromCardToUser}) async {
    final controller = TextEditingController();
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: Text(fromCardToUser ? 'Riscuoti' : 'Deposita'),
            content: Column(
              children: [
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  placeholder: 'Importo',
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Annulla'),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
    );

    if (ok != true) return;
    final amount = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
    if (amount <= 0) return;

    final cardCode = widget.cardCode;
    final password = widget.password;
    final cardBal = await _fetchCardBalance(cardCode);
    final userBal = await _getUserBalanceByPassword(password);

    if (fromCardToUser) {
      if (amount > cardBal) {
        await showCupertinoDialog(
          context: context,
          builder:
              (ctx) => CupertinoAlertDialog(
                title: const Text('Errore'),
                content: const Text('Saldo insufficiente sulla card.'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
        );
        return;
      }
      final newCard = (cardBal - amount);
      final newUser = (userBal + amount);
      await _setCardBalance(cardCode, newCard);
      await _setUserBalanceByPassword(password, newUser);
    } else {
      if (amount > userBal) {
        await showCupertinoDialog(
          context: context,
          builder:
              (ctx) => CupertinoAlertDialog(
                title: const Text('Errore'),
                content: const Text('Saldo insufficiente su Firebase.'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
        );
        return;
      }
      final newCard = (cardBal + amount);
      final newUser = (userBal - amount);
      await _setCardBalance(cardCode, newCard);
      await _setUserBalanceByPassword(password, newUser);
    }

    if (!mounted) return;
    await showCupertinoDialog(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Fatto'),
            content: const Text('Transazione completata.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _toggleBalance() async {
    setState(() => _showBalance = !_showBalance);
    if (_showBalance && _balance == null && !_loadingBalance) {
      setState(() => _loadingBalance = true);
      try {
        final balance = await fetchUserBalance(widget.username);
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
        debugPrint('Errore nel caricamento del bilancio: $e');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = getDisplayName(widget.username);
    final profileImage = getProfileImage(widget.username);
    final panelColor =
        widget.isDark ? const Color(0xFF23232B) : CupertinoColors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20 * _fadeAnimation.value,
            sigmaY: 20 * _fadeAnimation.value,
          ),
          child: SlideTransition(
            position: _slideAnimation,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.45,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Finestra principale
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: Container(
                      decoration: BoxDecoration(
                        color: panelColor.withOpacity(0.9),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            children: [
                              const SizedBox(height: 65),
                              // Nome display
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      widget.isDark
                                          ? Colors.white
                                          : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Username
                              Text(
                                '@${widget.username}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      widget.isDark
                                          ? Colors.white.withOpacity(0.6)
                                          : Colors.black.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Spazio prima della card / pageview
                              const SizedBox(height: 24),
                              // PageView: page 0 = card, page 1 = favorites
                              SizedBox(
                                height: 200,
                                child: PageView(
                                  controller: _pageController,
                                  onPageChanged:
                                      (idx) => setState(() => _pageIndex = idx),
                                  children: [
                                    // Page 0: existing card view
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: _toggleBalance,
                                        onLongPress: () {
                                          if (_cardAsset != null) {
                                            Navigator.of(context).push(
                                              PageRouteBuilder(
                                                pageBuilder:
                                                    (
                                                      context,
                                                      animation,
                                                      secondaryAnimation,
                                                    ) => CardFullscreenView(
                                                      cardAsset: _cardAsset!,
                                                      isDark: widget.isDark,
                                                      onVerticalDragUpdate:
                                                          (delta) {},
                                                      onDismiss:
                                                          () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(),
                                                    ),
                                                transitionsBuilder: (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                  child,
                                                ) {
                                                  return FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  );
                                                },
                                              ),
                                            );
                                          }
                                        },
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          switchInCurve: Curves.easeOutQuart,
                                          switchOutCurve: Curves.easeInQuart,
                                          transitionBuilder:
                                              (child, animation) =>
                                                  FadeTransition(
                                                    opacity: CurvedAnimation(
                                                      parent: animation,
                                                      curve:
                                                          Curves.easeInOutCubic,
                                                    ),
                                                    child: child,
                                                  ),
                                          layoutBuilder:
                                              (
                                                currentChild,
                                                previousChildren,
                                              ) => Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  ...previousChildren,
                                                  if (currentChild != null)
                                                    currentChild,
                                                ],
                                              ),
                                          child:
                                              _showBalance
                                                  ? Container(
                                                    key: const ValueKey(
                                                      'balance',
                                                    ),
                                                    height: 120,
                                                    width: double.infinity,
                                                    child: Center(
                                                      child:
                                                          _loadingBalance
                                                              ? const CupertinoActivityIndicator()
                                                              : Text(
                                                                'S ${_balance?.toStringAsFixed(2) ?? '0.00'}',
                                                                style: TextStyle(
                                                                  fontSize: 32,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      widget.isDark
                                                                          ? Colors
                                                                              .white
                                                                          : Colors
                                                                              .black,
                                                                ),
                                                              ),
                                                    ),
                                                  )
                                                  : Container(
                                                    key: const ValueKey('card'),
                                                    height: 160,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      image:
                                                          _cardAsset != null
                                                              ? DecorationImage(
                                                                image: AssetImage(
                                                                  _cardAsset!,
                                                                ),
                                                                fit:
                                                                    BoxFit
                                                                        .contain,
                                                              )
                                                              : null,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                    ),

                                    // Page 1: Favorites + stats
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child:
                                          _loadingFavorites
                                              ? const Center(
                                                child:
                                                    CupertinoActivityIndicator(),
                                              )
                                              : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '${_favorites.length}/4 Preferiti',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Column(
                                                        children: [
                                                          Text(
                                                            '${_ratings.length}',
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          const Text(
                                                            'Visti',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white54,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(width: 18),
                                                      Column(
                                                        children: [
                                                          Text(
                                                            '${_computeAffinity()}%',
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          const Text(
                                                            'Affinità',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white54,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  // Horizontal list of up to 4 favorites - fixed heights to avoid overflow
                                                  Transform.translate(
                                                    offset: const Offset(0, -8),
                                                    child: Container(
                                                      height: 120,
                                                      child:
                                                          _favoriteMovies
                                                                  .isEmpty
                                                              ? const SizedBox.shrink() // per request: if no firebase data, show nothing
                                                              : ListView.builder(
                                                                scrollDirection:
                                                                    Axis.horizontal,
                                                                itemCount: 4,
                                                                itemBuilder: (
                                                                  ctx,
                                                                  idx,
                                                                ) {
                                                                  if (idx >=
                                                                      _favoriteMovies
                                                                          .length) {
                                                                    return Container(
                                                                      width:
                                                                          100,
                                                                      margin: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            6,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color: const Color(
                                                                          0xFF222228,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              14,
                                                                            ),
                                                                      ),
                                                                      child: const Center(
                                                                        child: Icon(
                                                                          CupertinoIcons
                                                                              .add,
                                                                          color:
                                                                              Colors.white30,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }
                                                                  final m =
                                                                      _favoriteMovies[idx];
                                                                  final poster =
                                                                      m['poster_path']
                                                                          as String?;
                                                                  final imageUrl =
                                                                      poster !=
                                                                              null
                                                                          ? 'https://image.tmdb.org/t/p/w342$poster'
                                                                          : null;
                                                                  return Container(
                                                                    width: 100,
                                                                    margin: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          6,
                                                                    ),
                                                                    child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        // fixed image height to avoid layout overflow
                                                                        ClipRRect(
                                                                          borderRadius: BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                          child: SizedBox(
                                                                            height:
                                                                                86,
                                                                            width:
                                                                                100,
                                                                            child:
                                                                                imageUrl !=
                                                                                        null
                                                                                    ? Image.network(
                                                                                      imageUrl,
                                                                                      fit:
                                                                                          BoxFit.cover,
                                                                                    )
                                                                                    : Container(
                                                                                      color:
                                                                                          Colors.grey,
                                                                                    ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              6,
                                                                        ),
                                                                        Text(
                                                                          (m['title'] ??
                                                                              m['name'] ??
                                                                              ''),
                                                                          style: const TextStyle(
                                                                            color:
                                                                                Colors.white70,
                                                                            fontSize:
                                                                                12,
                                                                          ),
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                    ),
                                  ],
                                ),
                              ),

                              // Dots indicator under PageView (constrained to avoid overflow)
                              const SizedBox(height: 10),
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 160,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(
                                      2,
                                      (i) => GestureDetector(
                                        onTap:
                                            () => _pageController.animateToPage(
                                              i,
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              curve: Curves.easeOut,
                                            ),
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          width: _pageIndex == i ? 12 : 8,
                                          height: _pageIndex == i ? 12 : 8,
                                          decoration: BoxDecoration(
                                            color:
                                                _pageIndex == i
                                                    ? Colors.white
                                                    : Colors.white24,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                          // Pulsante messaggio circolare in alto a destra
                          Positioned(
                            top: 12,
                            right: 16,
                            child: Semantics(
                              label: 'Messaggio',
                              button: true,
                              child: CupertinoButton(
                                onPressed: () async {
                                  // Evita usare il BuildContext dopo await: cattura NavigatorState.
                                  final navigator = Navigator.of(context);
                                  final loggedUser = await getLoggedUser();
                                  if (!mounted) return;
                                  // Chiudi la finestra di profilo
                                  navigator.pop();
                                  if (loggedUser != null) {
                                    // Apri la chat come finestra overlay (transparent route)
                                    navigator.push(
                                      PageRouteBuilder(
                                        opaque: false,
                                        barrierDismissible: true,
                                        pageBuilder: (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) {
                                          return ChatViewModal(
                                            currentUser: loggedUser,
                                            otherUser: widget.username,
                                            onBack:
                                                () =>
                                                    Navigator.of(context).pop(),
                                          );
                                        },
                                        transitionsBuilder: (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return FadeTransition(
                                            opacity: CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOut,
                                            ),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  } else {
                                    // Se non c'è utente loggato, apri la lista messaggi.
                                    navigator.push(
                                      CupertinoPageRoute(
                                        builder: (_) => const SendScreen(),
                                      ),
                                    );
                                  }
                                },
                                padding: EdgeInsets.zero,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color:
                                        widget.isDark
                                            ? const Color(0xFF2C2C2E)
                                            : CupertinoColors.systemGrey6,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    CupertinoIcons.chat_bubble_fill,
                                    size: 22,
                                    color: CupertinoColors.systemBlue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Large card that sticks out (half inside/outside) + action buttons
                  Positioned(
                    top: -60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          children: [
                            // Big card image
                            Container(
                              width: MediaQuery.of(context).size.width * 0.82,
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                image:
                                    _cardAsset != null
                                        ? DecorationImage(
                                          image: AssetImage(_cardAsset!),
                                          fit: BoxFit.cover,
                                        )
                                        : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed:
                                      () => _onTransfer(fromCardToUser: true),
                                  child: Container(
                                    width: 140,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          widget.isDark
                                              ? const Color(0xFF2C2C2E)
                                              : CupertinoColors.systemGrey6,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.arrow_up_circle_fill,
                                          color: CupertinoColors.systemGreen,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Riscuoti',
                                          style: TextStyle(
                                            color:
                                                widget.isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed:
                                      () => _onTransfer(fromCardToUser: false),
                                  child: Container(
                                    width: 140,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color:
                                          widget.isDark
                                              ? const Color(0xFF2C2C2E)
                                              : CupertinoColors.systemGrey6,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.arrow_down_circle_fill,
                                          color: CupertinoColors.activeBlue,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Deposita',
                                          style: TextStyle(
                                            color:
                                                widget.isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _computeAffinity() {
    if (_ratings.isEmpty) return 0;
    double sum = 0;
    _ratings.forEach((k, v) {
      sum += v.toDouble();
    });
    final avgHalf = sum / _ratings.length; // 0..10
    final pct = ((avgHalf / 10.0) * 100).round();
    return pct.clamp(0, 100);
  }

  void _showSelectTop4() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (ctx) => Container(
            color: const Color(0xFF1C1C1E),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Seleziona i 4 film preferiti',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Apri la schermata valutazioni per scegliere i tuoi preferiti e salvarli qui.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      child: const Text('Annulla'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    CupertinoButton(
                      child: const Text('Apri Valutazioni'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => const ValutationScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
    );
  }
}
