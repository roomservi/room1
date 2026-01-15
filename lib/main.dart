import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart' show ChangeNotifier, ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'enter_screen.dart';
import 'navigation_bar.dart';
import 'library.dart';
import 'video_controller_provider.dart';
import 'screen_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// (navigatorKey removed with NFC service)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => VideoControllerProvider()),
      ],
      child: const OnePayApp(),
    ),
  );
}

class ThemeNotifier extends ChangeNotifier {
  bool _isDark = false;
  bool _isLoaded = false;
  bool get isDark => _isDark;
  bool get isLoaded => _isLoaded;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool('darkModeDefault') ?? false;
    } catch (e) {
      debugPrint('Errore nel caricamento del tema: $e');
      _isDark = false;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('darkModeDefault', _isDark);
    } catch (e) {
      debugPrint('Errore nel salvataggio del tema: $e');
    }
  }

  void setDefaultTheme(bool isDark) {
    _isDark = isDark;
    notifyListeners();
  }
}

class OnePayApp extends StatelessWidget {
  const OnePayApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, theme, child) {
        if (!theme.isLoaded) {
          return const CupertinoApp(
            home: CupertinoPageScaffold(
              child: Center(child: CupertinoActivityIndicator()),
            ),
          );
        }
        return CupertinoApp(
          debugShowCheckedModeBanner: false,
          theme: CupertinoThemeData(
            brightness: theme.isDark ? Brightness.dark : Brightness.light,
          ),
          home: const _RootRouter(),
        );
      },
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter({Key? key}) : super(key: key);

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _initializeScreenManager();
  }

  Future<void> _initializeScreenManager() async {
    // Load last viewed screen index on app startup
    await ScreenManager.getLastScreenIndex();
  }

  Future<void> _checkLogin() async {
    final logged = await isLoggedIn();
    setState(() {
      _loggedIn = logged;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn == null) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (_loggedIn == false) {
      return const EnterScreen();
    }
    return const CustomNavigationBar();
  }
}
