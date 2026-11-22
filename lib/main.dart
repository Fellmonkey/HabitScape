import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/database/database_provider.dart';
import 'core/debug/debug_menu_overlay.dart';
import 'core/router/app_router.dart';
import 'core/settings/app_startup.dart';
import 'core/settings/text_scale.dart';
import 'core/settings/theme_mode.dart';
import 'core/startup/startup_gate.dart';
import 'core/theme/app_theme.dart';
import 'features/reminders/presentation/widgets/reminder_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  // Both cold-start side effects begin before the first frame. On web, the
  // Drift future is what downloads/compiles sqlite3.wasm and spawns the
  // worker; overlapping it with preferences avoids paying twice in sequence.
  final startup = Future.wait<void>([
    container.read(appStartupProvider.future),
    container.read(databaseReadyProvider.future),
  ]);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: StartupGate(startup: startup, child: const RythmApp()),
    ),
  );
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
