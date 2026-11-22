import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
    Future.any<void>([
      widget.startup,
      Future<void>.delayed(_splashBudget),
    ]).then(
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

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_florist_outlined, size: 56),
            SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    ),
  );
}
