import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../settings/theme_mode.dart';
import '../theme/app_theme.dart';

/// How long a cold start may hide behind the splash before the real UI takes
/// over. Long enough to cover a warm connection on a fast device, short
/// enough that a slow device sees its own shell instead of a logo for 8s.
const _splashBudget = Duration(milliseconds: 400);

/// Shows a themed splash while the process-wide cold-start side effects
/// (preferences + the Drift connection) resolve, but never longer than
/// [_splashBudget].
///
/// The futures are started in `main` before `runApp`, so this widget only
/// waits — it never initiates work. On a fast device the connection is warm
/// before the budget expires and the app opens fully populated. On a slow one
/// the shell (and the board's skeleton) appears instead of holding the user
/// on a splash for the whole database initialization. A failure also opens
/// the gate: a genuine database error must surface from the first real query,
/// where the UI can show it.
class StartupGate extends ConsumerStatefulWidget {
  const StartupGate({required this.startup, required this.child, super.key});

  final Future<void> startup;
  final Widget child;

  @override
  ConsumerState<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<StartupGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.any<void>([widget.startup, Future<void>.delayed(_splashBudget)])
        .then(
          (_) => _open(),
          onError: (Object error, StackTrace stack) {
            if (kDebugMode || kProfileMode) {
              debugPrint('Startup failed, opening app anyway: $error\n$stack');
            }
            _open();
          },
        );
  }

  void _open() {
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) => _ready ? widget.child : const _Splash();
}

/// The boot splash. It mirrors the static HTML splash in `web/index.html`
/// (same icon, sway animation and theme colors) so the hand-off from the
/// page's splash to the first Flutter frame is invisible. It follows the
/// app's theme setting, like the rest of the UI.
class _Splash extends ConsumerWidget {
  const _Splash();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) {
              final primary = Theme.of(context).colorScheme.primary;
              return _SwayingFlower(color: primary);
            },
          ),
        ),
      ),
    );
  }
}

/// The branded flower gently sways — the same motion as the HTML splash's CSS
/// animation (10°, 2.4s, ease-in-out, alternating), so both splash versions
/// feel identical.
class _SwayingFlower extends StatefulWidget {
  const _SwayingFlower({required this.color});

  final Color color;

  @override
  State<_SwayingFlower> createState() => _SwayingFlowerState();
}

class _SwayingFlowerState extends State<_SwayingFlower>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  late final Animation<double> _sway = Tween(
    begin: -0.028,
    end: 0.028,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _sway,
      child: Icon(Icons.local_florist_outlined, size: 56, color: widget.color),
    );
  }
}
