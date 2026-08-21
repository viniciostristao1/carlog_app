import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'features/home/home_screen.dart';
import 'firebase_config.dart';
import 'firebase_options.dart';
import 'l10n/strings.dart';
import 'services/notifications.dart';
import 'services/prefs.dart';
import 'services/sync_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'util/format.dart';
import 'util/messenger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // carrega todos os locales (pt/en/es)

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
    ref.watch(notifSchedulerProvider); // reagenda notificações quando os dados mudam

    final tema = ref.watch(temaProvider).value ?? TemaApp.ambar;
    final fonte =
        ref.watch(fonteProvider).value ?? TamanhoFonte.normal;
    final escala = fonte.fator;

    final idioma = ref.watch(idiomaProvider).value ?? Idioma.pt;
    localeDatas = idioma.localeData; // datas por extenso seguem o idioma
    final locale = switch (idioma) {
      Idioma.pt => const Locale('pt', 'BR'),
      Idioma.en => const Locale('en'),
      Idioma.es => const Locale('es'),
    };

    return MaterialApp(
      title: 'CarLog',
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(tema),
      // Troca de tema instantânea (sem a animação padrão que dava "delay").
      themeAnimationDuration: Duration.zero,
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en'),
        Locale('es'),
      ],
      // Escala de fonte do usuário no app inteiro. KeyedSubtree(ValueKey): como
      // as cores vêm de AppColors estático (não de Theme.of), trocar o tema
      // exige reconstruir a árvore para repintar tudo.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: escala,
        maxScaleFactor: escala,
        child: KeyedSubtree(key: ValueKey((tema, idioma)), child: child!),
      ),
      home: const HomeScreen(),
    );
  }
}
