import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/debug/debug_menu_overlay.dart';
import 'core/router/app_router.dart';
import 'core/settings/text_scale.dart';
import 'core/settings/theme_mode.dart';
import 'core/theme/app_theme.dart';
import 'features/reminders/presentation/reminder_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RythmApp()));
}

class RythmApp extends ConsumerWidget {
  const RythmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textScale = ref.watch(textScaleProvider);
    return ReminderGate(
      child: MaterialApp.router(
        title: 'HabitScape',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: appRouter,
        builder: (context, child) {
          Widget? result = child ?? const SizedBox.shrink();
          // In-app text scale overrides the system scale when set.
          if (textScale != TextScaleOption.system) {
            result = MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale.factor)),
              child: result,
            );
          }
          if (kDebugMode) {
            result = DebugMenuOverlay(child: result);
          }
          return result;
        },
      ),
    );
  }
}
