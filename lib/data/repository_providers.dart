import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_provider.dart';
import 'repositories/repositories.dart';

/// The data layer's public surface. UI/state code never sees Drift directly.
final repositoriesProvider = Provider<Repositories>((ref) {
  return Repositories(ref.watch(databaseProvider));
});
