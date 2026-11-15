// Screens 1 to 3: welcome, language, how it works.
import 'package:flutter/material.dart';

import '../analysis.dart';
import '../data/store.dart';
import '../l10n/strings.dart';
import '../engine/models.dart';
import '../widgets/common.dart';
import '../widgets/logo.dart';
import 'setup.dart';
import 'shell.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _busy = false;
  List<Map<String, dynamic>> _saved = const [];

  @override
  void initState() {
    super.initState();
    loadPlans().then((p) {
      if (mounted) setState(() => _saved = p);
    });
  }

  Future<void> _sample() async {
    setState(() => _busy = true);
    final analysis = await runAnalysis(FarmSetup()
      ..useSample = true
      ..soilType = 'Sandy loam');
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => Shell(analysis: analysis)));
  }

  Future<void> _reopen(Map<String, dynamic> plan) async {
    setState(() => _busy = true);
    try {
      final setup = FarmSetup.fromJson(plan['setup'] as Map<String, dynamic>);
      final analysis = await runAnalysis(setup);
      if (!mounted) return;
      Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => Shell(analysis: analysis)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;

    final hero = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // the logo, centred: the first thing anyone sees
        const Center(child: AgriSmartLogo(size: 160)),
        const SizedBox(height: 20),
        const Text('AgriSmart',
            textAlign: TextAlign.center,
            style: TextStyle(color: white, fontSize: 46, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(t('tagline'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: white, fontSize: 21, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(t('welcomeSub'),
            textAlign: TextAlign.center,
            style: TextStyle(color: white.withValues(alpha: 0.9), fontSize: 15)),
        const SizedBox(height: 32),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: white, foregroundColor: green),
          onPressed: _busy
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const LanguageScreen())),
          child: Text(t('getStarted')),
        ),
        const SizedBox(height: 4),
        TextButton(
          style: TextButton.styleFrom(
              foregroundColor: white, minimumSize: const Size.fromHeight(44)),
          onPressed: _busy ? null : _sample,
          child: Text(_busy ? t('openingSample') : t('demo'), style: const TextStyle(fontSize: 13)),
        ),
      ],
    );

    Widget feature(IconData icon, String title, String text) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: white.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: white, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: white, fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(text, style: TextStyle(color: white.withValues(alpha: 0.9), height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        );

    final features = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        feature(Icons.place_outlined, t('step1t'), t('step1')),
        feature(Icons.satellite_alt_outlined, t('step2t'), t('step2')),
        feature(Icons.autorenew, t('step3t'), t('step3')),
        feature(Icons.fact_check_outlined, t('step4t'), t('step4')),
      ],
    );

    final saved = _saved.isEmpty
        ? const SizedBox()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Text(t('savedPlans'),
                  style: const TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final p in _saved.take(5))
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    enabled: !_busy,
                    title: Text(p['place'] as String? ?? t('field')),
                    subtitle: Text(
                        '${(p['best'] as String?)?.isNotEmpty == true ? '${t('best')}: ${p['best']}. ' : ''}'
                        '${p['isSample'] == true ? '${t('sampleData')}. ' : ''}'
                        '${t('saved')} ${(p['savedAt'] as String).substring(0, 10)}'),
                    trailing: IconButton(
                      tooltip: t('delete'),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await deletePlan(p['savedAt'] as String);
                        final left = await loadPlans();
                        if (mounted) setState(() => _saved = left);
                      },
                    ),
                    onTap: () => _reopen(p),
                  ),
                ),
              Text(t('reopenNote'), style: const TextStyle(color: white, fontSize: 12)),
            ],
          );

    return Scaffold(
      backgroundColor: green,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= 900;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 1040 : 420),
                  child: wide
                      // desktop and tablet: hero on one side, what it does on the other
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: hero),
                            const SizedBox(width: 64),
                            Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [features, saved])),
                          ],
                        )
                      : Column(mainAxisSize: MainAxisSize.min, children: [hero, saved]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final _setup = FarmSetup();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = _setup.country;
    // The country's own languages first, then every language the app can
    // show. A language with no translation yet is listed but greyed out.
    final names = <String>[
      'English',
      for (final l in local?.languages ?? const <String>[])
        if (l != 'English') l,
      for (final n in const ['French', 'Kiswahili', 'Portuguese', 'Arabic', 'Spanish'])
        if (!(local?.languages.contains(n) ?? false)) n,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(t('language'))),
      body: PageBody(
        maxWidth: 520,
        children: [
          Text(t('chooseLanguage'),
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
          Text(tf('languagesOf', {'country': _setup.countryName}),
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          for (final l in names)
            Card(
              child: ListTile(
                enabled: Lang.codeFor(l) != null,
                leading: Icon(Lang.codeFor(l) == Lang.code
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
                title: Text(languageNames[Lang.codeFor(l)] ?? l),
                subtitle: Lang.codeFor(l) == null ? Text(t('comingSoon')) : null,
                onTap: () {
                  final code = Lang.codeFor(l);
                  if (code != null) Lang.set(code);
                },
              ),
            ),
          const SizedBox(height: 8),
          Text(t('adviceLang'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => HowItWorksScreen(setup: _setup))),
            child: Text(t('continue')),
          ),
        ],
      ),
    );
  }
}

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key, required this.setup});
  final FarmSetup setup;

  static const _steps = [
    ('step1t', 'step1'), ('step2t', 'step2'), ('step3t', 'step3'), ('step4t', 'step4'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t('howWorks'))),
      body: PageBody(
        maxWidth: 520,
        children: [
          for (var i = 0; i < _steps.length; i++)
            Panel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text('${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t(_steps[i].$1),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(t(_steps[i].$2),
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => SetupFlow(setup: setup))),
            child: Text(t('setUpField')),
          ),
        ],
      ),
    );
  }
}
