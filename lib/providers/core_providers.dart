import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:family_shopping_app/core/network/network_info.dart';
import 'package:family_shopping_app/services/secure_storage_service.dart';

part 'core_providers.g.dart';

/// Rule (04_SYSTEM_ARCHITECTURE.md - Dependency Injection): every service
/// must be injected via a provider; no service instantiates another
/// directly.

/// The Isar instance is opened asynchronously in `main()` (it needs the
/// device's documents directory) and injected via
/// `ProviderScope(overrides: [isarProvider.overrideWithValue(isar)])`.
/// Reading this before that override is a programming error — on purpose,
/// so a missing override fails loudly instead of silently using no cache.
@Riverpod(keepAlive: true)
Isar isar(Ref ref) {
  throw UnimplementedError(
    'isarProvider must be overridden in main.dart after AppDatabase.open()',
  );
}

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage();
}

@Riverpod(keepAlive: true)
SecureStorageService secureStorageService(Ref ref) {
  return SecureStorageService(ref.watch(secureStorageProvider));
}

@Riverpod(keepAlive: true)
Connectivity connectivity(Ref ref) {
  return Connectivity();
}

@Riverpod(keepAlive: true)
NetworkInfo networkInfo(Ref ref) {
  return NetworkInfoImpl(ref.watch(connectivityProvider));
}
