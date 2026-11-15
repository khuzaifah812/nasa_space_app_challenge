import 'package:flutter/material.dart';

import 'assistant/chat_screen.dart';
import 'l10n/strings.dart';
import 'screens/onboarding.dart';
import 'widgets/common.dart';

void main() => runApp(const AgriSmartApp());

final _navigatorKey = GlobalKey<NavigatorState>();

class AgriSmartApp extends StatelessWidget {
  const AgriSmartApp({super.key});

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: green, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light ? green : scheme.surfaceContainer,
        foregroundColor: brightness == Brightness.light ? Colors.white : scheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds every screen when the language changes.
    return ValueListenableBuilder<String>(
      valueListenable: Lang.notifier,
      builder: (context, code, _) => MaterialApp(
        title: 'AgriSmart',
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        locale: Locale(code),
        // The footer line sits under every screen, below any tab bar.
        builder: (context, child) => Directionality(
          textDirection: Lang.rtl ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: child ?? const SizedBox()),
                    // the assistant, reachable from every screen
                    PositionedDirectional(
                      end: 12,
                      bottom: 96,
                      child: AssistantButton(navigatorKey: _navigatorKey),
                    ),
                  ],
                ),
              ),
              const AppFooter(),
            ],
          ),
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}
