import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences singleton, available as a Riverpod provider so it can
/// be overridden in tests (`SharedPreferences.setMockInitialValues`).
final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});
