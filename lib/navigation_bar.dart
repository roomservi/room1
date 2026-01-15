import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'dart:ui';
import 'library.dart';
import 'home_screen/home_screen.dart';
import 'valutation_screen.dart';
import 'settings_screen.dart';
import 'screen_manager.dart';

class CustomNavigationBar extends StatefulWidget {
  final int initialIndex;
  const CustomNavigationBar({Key? key, this.initialIndex = 0})
    : super(key: key);

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  late int _currentIndex;
  bool _hideNavBar = false;
  bool _isInitialized = false;

  // Cache schermate per mantenerle in memoria
  final Map<int, Widget> _screenCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initializeScreens();
  }

  Future<void> _initializeScreens() async {
    try {
      // Load last viewed screen
      final lastIndex = await ScreenManager.getLastScreenIndex();
      if (mounted) {
        setState(() {
          _currentIndex = lastIndex;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading screen index: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Widget _buildPage(int index) {
    // Return cached screen if available
    if (_screenCache.containsKey(index)) {
      return _screenCache[index]!;
    }

    late Widget page;

    if (index == 0) {
      page = HomeScreen(
        onFocusCardChanged: (focus) {
          if (_hideNavBar != focus) {
            setState(() {
              _hideNavBar = focus == 1;
            });
          }
        },
      );
    } else if (index == 1) {
      page = const ValutationScreen();
    } else {
      page = const SettingsScreen();
    }

    // Cache the screen for future use
    _screenCache[index] = page;
    return page;
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDark;
    final Color navBg =
        isDark
            ? Colors.black.withOpacity(0.85)
            : Colors.white.withOpacity(0.85);
    final Color navShadow =
        isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.08);
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          _buildPage(_currentIndex),
          AnimatedOpacity(
            opacity: _hideNavBar ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 24.0,
                  left: 16,
                  right: 16,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: navBg,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: navShadow,
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _NavBarItem(
                            icon: CupertinoIcons.house_fill,
                            label: 'Home',
                            selected: _currentIndex == 0,
                            onTap: () {
                              ScreenManager.saveScreenIndex(0);
                              setState(() => _currentIndex = 0);
                            },
                            isDark: isDark,
                          ),
                          _NavBarItem(
                            icon: CupertinoIcons.tickets_fill,
                            label: 'Valutation',
                            selected: _currentIndex == 1,
                            onTap: () {
                              ScreenManager.saveScreenIndex(1);
                              setState(() => _currentIndex = 1);
                            },
                            isDark: isDark,
                          ),
                          _NavBarItem(
                            icon: CupertinoIcons.settings_solid,
                            label: 'Settings',
                            selected: _currentIndex == 2,
                            onTap: () {
                              ScreenManager.saveScreenIndex(2);
                              setState(() => _currentIndex = 2);
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected
            ? (isDark ? CupertinoColors.activeBlue : CupertinoColors.activeBlue)
            : (isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.inactiveGray);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
