import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({Key? key, required this.onComplete})
    : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true);
    widget.onComplete();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeNotifier>(context).isDark;

    return CupertinoPageScaffold(
      backgroundColor:
          isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemBackground,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _OnboardingPage(
                    icon: CupertinoIcons.sparkles,
                    title: 'Benvenuto su OnePay',
                    subtitle: 'La tua app per Room One',
                    description:
                        'Gestisci i tuoi pagamenti e i tuoi crediti in modo facile e veloce con i tuoi amici.',
                    isDark: isDark,
                  ),
                  _OnboardingPage(
                    icon: CupertinoIcons.star_circle_fill,
                    title: 'La Moneta S',
                    subtitle: 'S = Serata',
                    description:
                        'Ad ogni serata di Room One ottieni 1 S. La moneta S è la valuta esclusiva della community: rappresenta il valore di una serata e puoi usarla per pagare e ricevere pagamenti tra i membri.',
                    isDark: isDark,
                  ),
                  _OnboardingPage(
                    icon: CupertinoIcons.creditcard_fill,
                    title: 'La Tua Card',
                    subtitle: 'Unica e Personale',
                    description:
                        'Ogni membro di Room One ha una card esclusiva. La tua card rappresenta la tua identità e viene utilizzata per tracciare tutte le tue transazioni e il tuo saldo con massima trasparenza.',
                    isDark: isDark,
                  ),
                  _OnboardingPage(
                    icon: CupertinoIcons.arrow_left_right_circle_fill,
                    title: 'Come Funziona',
                    subtitle: 'Facile e Veloce',
                    description:
                        'Invia pagamenti agli amici, ricevi transazioni e controlla il tuo saldo in tempo reale. Tutto è tracciato sulla tua card personale. Sei pronto? Inizia!',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  // Indicatori (pallini)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color:
                                _currentPage == index
                                    ? CupertinoColors.activeBlue
                                    : isDark
                                    ? const Color(0xFF3A3A3C)
                                    : CupertinoColors.systemGrey5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bottone Continua/Inizia
                  CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 40,
                    ),
                    child: Text(
                      _currentPage == 3 ? 'Inizia' : 'Continua',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final bool isDark;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icona grande con sfondo gradiente
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CupertinoColors.activeBlue.withOpacity(0.2),
                    CupertinoColors.activeBlue.withOpacity(0.05),
                  ],
                ),
              ),
              child: Icon(icon, size: 60, color: CupertinoColors.activeBlue),
            ),
            const SizedBox(height: 40),
            // Titolo
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 12),
            // Sottotitolo
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue,
              ),
            ),
            const SizedBox(height: 24),
            // Descrizione
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color:
                    isDark
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
