import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:family_shopping_app/app.dart';
import 'package:family_shopping_app/config/env_config.dart';

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

  // TODO(local-db): Isar.open(...) — added in the Local Database phase
  // (27_LOCAL_DATABASE_AND_OFFLINE_SYNC.md).

  runApp(const ProviderScope(child: FamilyShoppingApp()));
}
