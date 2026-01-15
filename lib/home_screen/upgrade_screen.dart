import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../library.dart';
import 'send_overlay.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'upgrade_logic.dart';
import 'back.dart';

final Map<String, String> weeklyCosts = {
  'Gold': 'S2.99/settimana',
  'Diamond': 'S5.99/settimana',
  'Smerald': 'S9.99/settimana',
  'Ultra': 'S19.99/settimana',
};

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({Key? key}) : super(key: key);

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  String? _username;
  String? _password;
  final List<String> levels = ['Gold', 'Diamond', 'Smerald', 'Ultra'];
  final Map<String, String> levelSuffix = {
    'Gold': 'oro',
    'Diamond': 'diamond',
    'Smerald': 'smerald',
    'Ultra': 'ultra',
  };
  final Map<String, List<String>> benefits = {
    'Gold': ['Assistenza prioritaria', 'Cashback 2%', 'Limite mensile 10.000S'],
    'Diamond': [
      'Assistenza VIP',
      'Cashback 5%',
      'Limite mensile 50.000S',
      'Accesso eventi esclusivi',
    ],
    'Smerald': [
      'Assistenza dedicata',
      'Cashback 10%',
      'Limite mensile illimitato',
      'Concierge personale',
      'Gift annuale',
    ],
    'Ultra': [
      'Assistenza Ultra',
      'Cashback 15%',
      'Limite mensile illimitato',
      'Concierge personale',
      'Gift annuale premium',
      'Accesso lounge aeroporti',
    ],
  };
  final Map<String, Color> levelColors = {
    'Gold': const Color(0xFFFFC300),
    'Diamond': const Color(0xFF0099FF),
    'Smerald': const Color(0xFF00D26A),
    'Ultra': const Color(0xFF8A2BE2),
  };
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _userLevel;
  DateTime? _renewalDate;
  bool _subscribing = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadLevel();
  }

  Future<void> _loadUser() async {
    final user = await getLoggedUser();
    setState(() {
      _username = user;
      _password = users[user ?? ''] ?? '';
    });
  }

  Future<void> _loadLevel() async {
    if (_password == null) return;
    final level = await getUserLevel(_password!);
    final renewal = await getRenewalDate(_password!);
    setState(() {
      _userLevel = level;
      _renewalDate = renewal;
      if (level != null) {
        final idx = levels.indexOf(level);
        _currentPage = idx >= 0 ? idx : 0;
      }
    });
  }

  Future<void> _subscribe(String level) async {
    if (_password == null || _username == null) return;
    setState(() => _subscribing = true);
    final ok = await subscribeUser(_password!, _username!, level);
    await _loadLevel();
    setState(() => _subscribing = false);
    if (!ok) {
      showSafeSnackBar(context, 'Errore abbonamento!');
    } else {
      showSafeSnackBar(context, 'Abbonamento attivo!');
    }
  }

  String getCardAsset(String? username, String level) {
    if (username == null) return getSilverCardAsset(username);
    final folder = username == 'tom&ila' ? 'ixt' : username;
    final suffix = levelSuffix[level] ?? 'oro';
    return 'asset/images/Card $folder/card $suffix 1.png';
  }

  Future<double?> fetchBalanceFromFirebase(String? password) async {
    if (password == null || password.isEmpty) return null;
    try {
      final url = Uri.parse('${baseUrl}balances/$password.json');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final value = double.tryParse(response.body.replaceAll('"', ''));
        return value;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final level = levels[_currentPage];
    final color = levelColors[level] ?? Colors.white;
    final benefitList = benefits[level] ?? [];
    final isSubscribed = _userLevel == level;
    final renewalText =
        _renewalDate != null
            ? 'Rinnovo: ${_renewalDate!.day}/${_renewalDate!.month}'
            : '';
    return Stack(
      children: [
        FutureBuilder<double?>(
          future: fetchBalanceFromFirebase(_password),
          builder: (context, snapshot) {
            final balance = snapshot.data;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              color: color,
              child: SafeArea(
                child: Stack(
                  children: [
                    // Profilo in alto con riquadro, supporto dark mode
                    Positioned(
                      left: screenWidth * 0.06,
                      right: screenWidth * 0.06,
                      top: screenHeight * 0.01, // più in alto
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 18,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF23232B)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: AssetImage(
                                getProfileImage(_username),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Text(
                                _username ?? '',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? const Color(0xFF23232B)
                                        : Colors.grey[100],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                snapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? 'S ...'
                                    : 'S${balance?.toStringAsFixed(2) ?? '--'}',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Card ingrandita sotto il titolo, più in alto
                    Positioned(
                      left: screenWidth * 0.06,
                      right: screenWidth * 0.06,
                      top: screenHeight * 0.15, // alzata rispetto a prima
                      child: SizedBox(
                        height: 270,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: levels.length,
                          onPageChanged:
                              (i) => setState(() => _currentPage = i),
                          itemBuilder: (context, idx) {
                            final l = levels[idx];
                            final asset = getCardAsset(_username, l);
                            return AspectRatio(
                              aspectRatio: 1.8,
                              child: Image.asset(asset, fit: BoxFit.contain),
                            );
                          },
                        ),
                      ),
                    ),
                    // Riquadro bianco staccato, centrato, con bordi arrotondati e benefici dentro, supporto dark mode
                    Positioned(
                      left: screenWidth * 0.06,
                      right: screenWidth * 0.06,
                      bottom: screenHeight * 0.04,
                      child: Container(
                        height: screenHeight * 0.44,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF23232B)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 18.0),
                              child: Text(
                                level,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            if (isSubscribed)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  renewalText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (final b in benefitList)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: Text(
                                            b,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color:
                                                  Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                screenWidth * 0.08,
                                0,
                                screenWidth * 0.08,
                                12,
                              ),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    colors:
                                        isSubscribed
                                            ? [Colors.grey, Colors.grey]
                                            : [color, color.withOpacity(0.7)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  color: Colors.transparent,
                                  child:
                                      _subscribing
                                          ? const CupertinoActivityIndicator()
                                          : Text(
                                            isSubscribed
                                                ? 'Abbonato'
                                                : 'Abbonati - ${weeklyCosts[level] ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  onPressed:
                                      isSubscribed || _subscribing
                                          ? null
                                          : () => _subscribe(level),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const CustomBackButton(
          onPressed: null, // Userà il comportamento di default (pop)
        ),
      ],
    );
  }
}
