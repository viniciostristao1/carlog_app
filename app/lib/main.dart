import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'features/home/home_screen.dart';
import 'firebase_config.dart';
import 'firebase_options.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';
import 'util/messenger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // Nuvem só quando provisionada (ver firebase_config.dart / FIREBASE.md).
  if (kFirebaseConfigured) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: CarLogApp()));
}

class CarLogApp extends ConsumerWidget {
  const CarLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kFirebaseConfigured) {
      ref.watch(syncProvider); // mantém a sincronização ativa conforme o login
    }
    return MaterialApp(
      title: 'CarLog',
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      home: const HomeScreen(),
    );
  }
}
