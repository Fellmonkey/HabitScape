import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ads/yandex_ads_service.dart';
import 'core/debug/debug_menu_overlay.dart';
import 'core/router/app_router.dart';
import 'core/settings/theme_mode.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget: on Android the SDK auto-initializes at app start anyway;
  // on Web this is a no-op. Never await before runApp — an extra async gap
  // before the first frame widens the web startup race where the browser's
  // initial focus event hits an unlaid-out tree (flutter/flutter#187939).
  unawaited(initializeAdsIfSupported());
  runApp(const ProviderScope(child: RythmApp()));
}

class RythmApp extends ConsumerWidget {
  const RythmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'HabitScape',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        if (kDebugMode) {
          return DebugMenuOverlay(child: child ?? const SizedBox.shrink());
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
