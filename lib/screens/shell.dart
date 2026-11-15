// The five tabs shown once a field is set up.
import 'package:flutter/material.dart';

import '../analysis.dart';
import '../assistant/context.dart';
import '../l10n/strings.dart';
import '../widgets/common.dart';
import 'conditions.dart';
import 'home.dart';
import 'learn.dart';
import 'review.dart';
import 'rotations.dart';
import 'setup.dart';

class Shell extends StatefulWidget {
  const Shell({super.key, required this.analysis});
  final Analysis analysis;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  static const _tabs = [
    ('tab_home', Icons.home_outlined, Icons.home),
    ('tab_conditions', Icons.wb_sunny_outlined, Icons.wb_sunny),
    ('tab_rotations', Icons.autorenew, Icons.autorenew),
    ('tab_review', Icons.fact_check_outlined, Icons.fact_check),
    ('tab_learn', Icons.menu_book_outlined, Icons.menu_book),
  ];
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    AssistantContext.analysis.value = widget.analysis;
  }

  /// Re-reads the same field with real NASA records.
  Future<void> _useNasa() async {
    setState(() => _switching = true);
    try {
      final setup = widget.analysis.setup..useSample = false;
      final fresh = await runAnalysis(setup);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => Shell(analysis: fresh)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  void _edit() => Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SetupFlow(setup: widget.analysis.setup, weather: widget.analysis.weather)));

  @override
  Widget build(BuildContext context) {
    final a = widget.analysis;
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;

    final page = switch (_tab) {
      0 => HomeTab(analysis: a, onTab: (i) => setState(() => _tab = i), onEdit: _edit),
      1 => ConditionsTab(analysis: a),
      2 => RotationsTab(analysis: a),
      3 => ReviewTab(analysis: a),
      _ => const LearnTab(),
    };

    final body = Column(
      children: [
        if (a.isSample)
          Material(
            color: amberBg,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(t('sampleBanner'),
                        style: const TextStyle(color: amberInk, fontWeight: FontWeight.w500)),
                  ),
                  TextButton.icon(
                    onPressed: _switching ? null : _useNasa,
                    icon: _switching
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.satellite_alt_outlined, size: 18),
                    label: Text(t('switchNasa')),
                  ),
                ],
              ),
            ),
          ),
        Expanded(child: page),
      ],
    );

    return Scaffold(
      body: wide
          ? Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _tab,
                    onDestinationSelected: (i) => setState(() => _tab = i),
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: scheme.surfaceContainerLow,
                    destinations: [
                      for (final tab in _tabs)
                        NavigationRailDestination(
                            icon: Icon(tab.$2), selectedIcon: Icon(tab.$3), label: Text(t(tab.$1))),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                for (final tab in _tabs)
                  NavigationDestination(
                      icon: Icon(tab.$2), selectedIcon: Icon(tab.$3), label: t(tab.$1)),
              ],
            ),
    );
  }
}
