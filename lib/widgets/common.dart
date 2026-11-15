import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../l10n/strings.dart';

const green = Color(0xFF1F5A3A);
const greenSoft = Color(0xFFE3F0E7);
const amberBg = Color(0xFFFFF1D6);
const amberInk = Color(0xFF7A4A00);
const inkDark = Color(0xFF14261B);

/// Screens wider than this use a side rail and wider layouts.
const wideBreakpoint = 840.0;

/// The line under every screen: the app's theme.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: green,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 7, 16, 7 + bottom),
        child: Text(t('tagline'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      ),
    );
  }
}

/// A scrolling page whose content stays readable on wide screens.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 760});
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// A titled block of related content.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    this.title,
    this.hint,
    required this.child,
    this.color,
    this.trailing,
  });
  final String? title;
  final String? hint;
  final Widget child;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A Material (not a coloured Container) so that list tiles, switches and
    // checkboxes inside the panel can draw their ink and colours on it.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color ?? theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              if (hint != null) ...[
                const SizedBox(height: 2),
                Text(
                  hint!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (title != null || hint != null) const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class Label extends StatelessWidget {
  const Label(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class Notice extends StatelessWidget {
  const Notice(this.title, this.text, {super.key});
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: amberBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: amberInk),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: amberInk,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(color: amberInk)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.warn = false});
  final String text;
  final bool warn;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: warn ? amberBg : greenSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: warn ? amberInk : inkDark,
        ),
      ),
    );
  }
}

/// A 0..1 score drawn as a bar.
class ScoreBar extends StatelessWidget {
  const ScoreBar(this.value, {super.key, this.dark = false});
  final double value;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0).toDouble(),
        minHeight: 8,
        backgroundColor: scheme.surfaceContainerHighest,
        color: dark ? scheme.onSurface : scheme.primary,
      ),
    );
  }
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.dark = false});
  final String text;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? scheme.onSurface : scheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: dark ? scheme.surface : scheme.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// A dropdown that looks like the text fields beside it.
class PickField<T> extends StatelessWidget {
  const PickField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: [
            for (final e in items.entries)
              DropdownMenuItem<T>(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// One colour per kind of crop, used on the season strip and the calendar.
Color cropColor(Crop c) {
  switch (c.cropType) {
    case 'cereal':
      return const Color(0xFFE9C46A);
    case 'legume':
      return const Color(0xFF8FC3A3);
    case 'root/tuber':
      return const Color(0xFFE7A977);
    case 'vegetable':
      return const Color(0xFFE59A93);
    default:
      return const Color(0xFFC9B6E4);
  }
}

String cropKind(Crop c) {
  switch (c.cropType) {
    case 'cereal':
      return 'Cereals';
    case 'legume':
      return 'Legumes';
    case 'root/tuber':
      return 'Roots and tubers';
    case 'vegetable':
      return 'Vegetables';
    default:
      return 'Fruits and others';
  }
}
