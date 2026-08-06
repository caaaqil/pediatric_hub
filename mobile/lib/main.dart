import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'config/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/storage/api_endpoint.dart';
import 'presentation/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore any API address the user set on this device.
  await ApiEndpoint.load();
  runApp(const ProviderScope(child: PediatricHealthHubApp()));
}

class PediatricHealthHubApp extends ConsumerWidget {
  const PediatricHealthHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Pediatric Health Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Manual toggle in the header, persisted under the same `phh-dark` key
      // the web app uses.
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
