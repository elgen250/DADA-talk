import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/settings_service.dart';
import 'core/services/widget_sync_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home_shell/home_shell_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize HomeWidget / iOS App Group container
  await WidgetSyncService.instance.init();

  runApp(
    const ProviderScope(
      child: DadaTranslatorApp(),
    ),
  );
}

class DadaTranslatorApp extends ConsumerWidget {
  const DadaTranslatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'DADA Flutter',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: settings.locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: settings.hasCompletedOnboarding
          ? const HomeShellScreen()
          : const OnboardingScreen(),
    );
  }
}
