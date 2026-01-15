import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'main.dart';
import 'library.dart';
import 'enter_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkDefault = false;
  String? _username;
  static const String darkModeKey = 'darkModeDefault';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadUser();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkDefault = prefs.getBool(darkModeKey) ?? false;
    });
  }

  Future<void> _loadUser() async {
    final username = await getLoggedUser();
    setState(() {
      _username = username;
    });
  }

  Future<void> _setDarkModeDefault(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(darkModeKey, value);
    setState(() {
      _isDarkDefault = value;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await logout();
    // Torna alla schermata del pin ed elimina lo stack di navigazione
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => const EnterScreen()),
      (route) => false,
    );
  }

  Future<void> _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@onepay.com',
      queryParameters: {'subject': 'Supporto OnePay'},
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDark;

    return CupertinoPageScaffold(
      backgroundColor:
          isDark
              ? const Color(0xFF1C1C1E)
              : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Icon(CupertinoIcons.settings, size: 24),
        backgroundColor:
            isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _buildGroupedSection([
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Immagine profilo
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isDark
                                    ? const Color(0xFF2C2C2E)
                                    : CupertinoColors.systemGrey5,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            getProfileImage(_username),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info utente
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _username ?? '',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? CupertinoColors.white
                                        : CupertinoColors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              getDisplayName(_username ?? ''),
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDark
                                        ? CupertinoColors.systemGrey
                                        : CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ], isDark),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Sezione Sicurezza
                  _buildSectionHeader('Sicurezza', isDark),
                  _buildGroupedSection([
                    _buildListTile(
                      context,
                      'Sicurezza',
                      trailing: const Icon(
                        CupertinoIcons.right_chevron,
                        color: CupertinoColors.systemGrey,
                      ),
                      icon: CupertinoIcons.shield_fill,
                      iconColor: CupertinoColors.systemGreen,
                      isDark: isDark,
                    ),
                    _buildListTile(
                      context,
                      'Privacy',
                      trailing: const Icon(
                        CupertinoIcons.right_chevron,
                        color: CupertinoColors.systemGrey,
                      ),
                      icon: CupertinoIcons.lock_fill,
                      iconColor: CupertinoColors.systemIndigo,
                      isDark: isDark,
                    ),
                  ], isDark),

                  const SizedBox(height: 12),

                  // Sezione Preferenze
                  _buildSectionHeader('Preferenze', isDark),
                  _buildGroupedSection([
                    _buildListTile(
                      context,
                      'Tema scuro',
                      trailing: CupertinoSwitch(
                        value: _isDarkDefault,
                        onChanged: (value) {
                          _setDarkModeDefault(value);
                          themeNotifier.setDefaultTheme(value);
                        },
                      ),
                      icon: CupertinoIcons.moon_fill,
                      iconColor: CupertinoColors.systemPurple,
                      isDark: isDark,
                    ),
                    _buildListTile(
                      context,
                      'Notifiche',
                      trailing: CupertinoSwitch(
                        value:
                            true, // TODO: Implementare la gestione delle notifiche
                        onChanged: (value) {
                          // TODO: Implementare la gestione delle notifiche
                        },
                      ),
                      icon: CupertinoIcons.bell_fill,
                      iconColor: CupertinoColors.systemRed,
                      isDark: isDark,
                    ),
                  ], isDark),

                  const SizedBox(height: 12),

                  // Sezione Supporto
                  _buildSectionHeader('Supporto e Info', isDark),
                  _buildGroupedSection([
                    _buildListTile(
                      context,
                      'Assistenza',
                      trailing: const Icon(
                        CupertinoIcons.right_chevron,
                        color: CupertinoColors.systemGrey,
                      ),
                      icon: CupertinoIcons.question_circle_fill,
                      iconColor: CupertinoColors.systemTeal,
                      onTap: _contactSupport,
                      isDark: isDark,
                    ),
                    _buildListTile(
                      context,
                      'Termini e condizioni',
                      trailing: const Icon(
                        CupertinoIcons.right_chevron,
                        color: CupertinoColors.systemGrey,
                      ),
                      icon: CupertinoIcons.doc_text_fill,
                      iconColor: CupertinoColors.systemOrange,
                      isDark: isDark,
                    ),
                    _buildListTile(
                      context,
                      'Versione',
                      trailing: Text(
                        '1.0.0',
                        style: TextStyle(
                          color:
                              isDark
                                  ? CupertinoColors.systemGrey
                                  : CupertinoColors.systemGrey,
                        ),
                      ),
                      icon: CupertinoIcons.info_circle_fill,
                      iconColor: CupertinoColors.systemGrey,
                      isDark: isDark,
                    ),
                  ], isDark),

                  const SizedBox(height: 12),

                  // Sezione Logout
                  _buildGroupedSection([
                    _buildListTile(
                      context,
                      'Logout',
                      trailing: const Icon(
                        CupertinoIcons.right_chevron,
                        color: CupertinoColors.systemGrey,
                      ),
                      icon: CupertinoIcons.square_arrow_right,
                      iconColor: CupertinoColors.destructiveRed,
                      onTap: () => _showLogoutDialog(context),
                      isDark: isDark,
                    ),
                  ], isDark),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color:
              isDark
                  ? CupertinoColors.systemGrey.withOpacity(0.8)
                  : CupertinoColors.systemGrey.withOpacity(0.8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGroupedSection(List<Widget> children, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23232B) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(35),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
    IconData? icon,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color:
                  isDark
                      ? const Color(0xFF2C2C2E)
                      : CupertinoColors.systemGrey6,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (iconColor ?? CupertinoColors.systemBlue).withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? CupertinoColors.systemBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  fontSize: 16,
                ),
              ),
            ),
            if (trailing != null)
              DefaultTextStyle(
                style: TextStyle(
                  color:
                      isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey,
                  fontSize: 16,
                ),
                child: trailing,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Provider.of<ThemeNotifier>(context, listen: false).isDark;
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: FadeTransition(
            opacity: animation,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF23232B).withOpacity(0.90)
                          : CupertinoColors.white.withOpacity(0.90),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color:
                        isDark
                            ? const Color(0xFF2C2C2E)
                            : CupertinoColors.systemGrey5.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isDark
                              ? const Color(0xFF000000).withOpacity(0.2)
                              : CupertinoColors.systemGrey.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.person_crop_circle,
                        color: CupertinoColors.systemBlue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vuoi uscire?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dovrai reinserire il pin per accedere nuovamente al tuo account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            isDark
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            borderRadius: BorderRadius.circular(20),
                            color:
                                isDark
                                    ? const Color(0xFF2C2C2E)
                                    : CupertinoColors.systemGrey6,
                            child: const Text(
                              'Annulla',
                              style: TextStyle(fontSize: 17),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            borderRadius: BorderRadius.circular(20),
                            color: CupertinoColors.destructiveRed,
                            child: const Text(
                              'Esci',
                              style: TextStyle(
                                fontSize: 17,
                                color: CupertinoColors.white,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _logout(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor:
          isDark
              ? CupertinoColors.black.withOpacity(0.4)
              : CupertinoColors.systemGrey.withOpacity(0.2),
    );
  }
}
