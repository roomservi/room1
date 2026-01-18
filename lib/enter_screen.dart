import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'library.dart';

class EnterScreen extends StatefulWidget {
  const EnterScreen({Key? key}) : super(key: key);

  @override
  State<EnterScreen> createState() => _EnterScreenState();
}

class _EnterScreenState extends State<EnterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    if (await isLoggedIn()) {
      _goToHome();
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  void _goToHome() {
    // Ricarica l'intera app per forzare il check dell'onboarding
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => const OnePayApp()),
      (route) => false,
    );
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final success = await checkLogin(username, password);
    if (success) {
      _goToHome();
    } else {
      setState(() {
        _error = 'Username o password errati';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeNotifier>(context).isDark;
    if (_loading) {
      return CupertinoPageScaffold(
        backgroundColor:
            isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemBackground,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Login',
          style: TextStyle(
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
        border: null,
        backgroundColor:
            isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemBackground,
      ),
      backgroundColor:
          isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemBackground,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.person_crop_circle,
                          size: 64,
                          color: CupertinoColors.activeBlue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Benvenuto su OnePay',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.black.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Accedi con il tuo account',
                          style: TextStyle(
                            fontSize: 15,
                            color:
                                isDark
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.inactiveGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoTextField(
                    controller: _usernameController,
                    placeholder: 'Username',
                    autocorrect: false,
                    clearButtonMode: OverlayVisibilityMode.editing,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0xFF23232B)
                              : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isDark
                                ? const Color(0xFF2C2C2E)
                                : CupertinoColors.systemGrey5.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 17,
                      color:
                          isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                    ),
                    placeholderStyle: TextStyle(
                      color:
                          isDark
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _passwordController,
                    placeholder: 'Password',
                    obscureText: true,
                    clearButtonMode: OverlayVisibilityMode.editing,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0xFF23232B)
                              : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isDark
                                ? const Color(0xFF2C2C2E)
                                : CupertinoColors.systemGrey5.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 17,
                      color:
                          isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                    ),
                    placeholderStyle: TextStyle(
                      color:
                          isDark
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(18),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text('Accedi', style: TextStyle(fontSize: 17)),
                    onPressed: _login,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
