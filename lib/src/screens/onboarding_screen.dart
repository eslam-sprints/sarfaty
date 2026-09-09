import 'package:flutter/material.dart';

import '../state/finance_store.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.store});

  final FinanceStore store;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _OnboardingPage(
      icon: Icons.receipt_long_rounded,
      title: 'تابع مصروفاتك بسهولة',
      body:
          'سجّل مصروفاتك اليومية نقداً أو بالبطاقة، وتابع إجمالي الشهر في نظرة واحدة',
      accent: Color(0xFF0D9488),
    ),
    _OnboardingPage(
      icon: Icons.credit_card_rounded,
      title: 'أدِر بطاقات الكريديت',
      body: 'أضف بطاقاتك، راقب المستحقات، وسجّل المدفوعات قبل موعد الاستحقاق.',
      accent: Color(0xFF0369A1),
    ),
    _OnboardingPage(
      icon: Icons.lock_outline_rounded,
      title: 'بياناتك محفوظة محلياً',
      body:
          'كل بياناتك تبقى على جهازك. يمكنك تصدير نسخة احتياطية في أي وقت من الإعدادات.',
      accent: Color(0xFF7C3AED),
    ),
  ];

  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      await widget.store.completeOnboarding();
    } on PersistenceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _next() async {
    if (_isLast) {
      await _finish();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final page = _pages[_index];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('تخطّي'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return _OnboardingPageView(page: item, scheme: scheme);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? page.accent
                          : scheme.outlineVariant.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: page.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isLast ? 'ابدأ' : 'التالي',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page, required this.scheme});

  final _OnboardingPage page;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                page.accent,
                Color.lerp(page.accent, scheme.surface, 0.25)!,
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: page.accent.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(page.icon, size: 52, color: Colors.white),
        ),
        const SizedBox(height: 36),
        Text(
          'صرفتي',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: page.accent,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Text(
          page.body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}
