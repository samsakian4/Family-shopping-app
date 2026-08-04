import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:family_shopping_app/app.dart';
import 'package:family_shopping_app/config/env_config.dart';
import 'package:family_shopping_app/core/local/app_database.dart';
import 'package:family_shopping_app/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  EnvConfig.assertValid();

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
    // Session persistence handled by supabase_flutter; access/refresh
    // tokens are additionally mirrored into secure storage by the auth
    // feature for offline bootstrap (08_SECURITY.md - Session Management).
  );

  // Offline-first local cache (27_LOCAL_DATABASE_AND_OFFLINE_SYNC.md).
  final isar = await AppDatabase.open();

  runApp(
    ProviderScope(
      overrides: [isarProvider.overrideWithValue(isar)],
      child: const FamilyShoppingApp(),
    ),
  );
}
