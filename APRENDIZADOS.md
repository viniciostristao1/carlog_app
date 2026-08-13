# CarLog — APRENDIZADOS (diário técnico + gotchas)

Topo = mais recente. Registrar aqui toda decisão técnica, gotcha e o "porquê".

## 2026-08-13 — Notificações (v0.2.0)

**flutter_local_notifications 18.0.1 + timezone 0.9.4 + flutter_timezone 3.0.1.** Avisa no dia e 3 dias
antes de cada lembrete não-pago e quando a próxima revisão estimada se aproxima. Toggle em Config
(`notifAtivasProvider`, pref `notif_ativas_v1`); só liga após permissão. `NotifScheduler`
(`notifSchedulerProvider`, vivo no `main`) reprograma tudo (cancelAll + reschedule, debounce 600ms)
quando lembretes/veículo/abastecimentos/revisões mudam. IDs estáveis por `hashCode` do id + offset.

**Gotchas resolvidos:**
- **Desugaring obrigatório:** `isCoreLibraryDesugaringEnabled = true` em `compileOptions` +
  `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` no `dependencies {}` do
  `app/build.gradle.kts` (o plugin usa `java.time`). Sem isso o build de release quebra.
- **Manifesto:** permissões `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`,
  `RECEIVE_BOOT_COMPLETED`, `VIBRATE` + os 2 `<receiver>` do plugin (agendado + boot).
- **API v18:** `zonedSchedule` exige TANTO `androidScheduleMode` QUANTO
  `uiLocalNotificationDateInterpretation: absoluteTime` (senão erro de arg obrigatório). Fallback:
  se `exactAllowWhileIdle` falhar (sem permissão de alarme exato), reagenda `inexactAllowWhileIdle`.
- **Timezone:** `initializeTimeZones()` + `setLocalLocation(getLocation(<nome do fuso via
  flutter_timezone>))`, senão `tz.local` = UTC e o horário sai errado. `getLocalTimezone()` pode
  retornar String (v3) ou objeto com `.identifier` (v4) — tratei os dois.
- **Não-fatal:** toda chamada é try/catch; se algo falhar, o app segue.

**Fixes de CI (v0.2.1) — o 1º build de notificações quebrou:**
- `flutter_timezone 3.0.1` dava **"Inconsistent JVM Target"** (Java 11 × Kotlin 1.8) sob o Flutter
  3.44.7 (que reclama de plugins aplicando o Kotlin Gradle Plugin com target antigo). **Removido** —
  como o usuário é BR, fixamos `America/Sao_Paulo` direto (sem plugin de fuso). `timezone` (Dart puro)
  ficou. Auto-detecção de fuso vira ideia futura.
- Passo **Build AAB** era **cancelado** ("operation was canceled", ~10 min) — o runner grátis
  estourava tempo/memória compilando Firebase DUAS vezes (APK split-per-abi + AAB). O **APK sozinho
  compila OK**. CI passou a gerar **só o APK**; o AAB da Play Store sai só no lançamento. `release.sh`
  também deixou de exigir o AAB.
- Lição: validar o build na nuvem cedo; `flutter analyze` local NÃO pega conflito de JVM target de
  plugin nem limite de runner.

## 2026-08-13 — Criação (v0.1.0)

**Origem.** App do carro, inspirado na estrutura dos irmãos (`calistenia_app`, `lista_app`):
Flutter feature-based + Riverpod + docs-guia + CI que compila APK na nuvem + link perene.
Decisões do usuário: nome **CarLog**, **Firebase + login Google**, **FIPE por API grátis + manual**.

**Firebase-ready mas OFF por design.** Provisionar Firebase exige o console Google do usuário (SHA-1,
regras, Auth), que não dá para automatizar. Solução: escrever todo o código de nuvem (auth + sync)
desde já, mas atrás do flag `kFirebaseConfigured` (`firebase_config.dart` = false). Assim o app compila,
roda 100% local e é testável hoje; ligar a nuvem depois é "substituir `firebase_options.dart` + virar o
flag" (ver `FIREBASE.md`). Consequências no código:
- `main.dart` só chama `Firebase.initializeApp` se o flag for true.
- `authStateProvider` emite `Stream.empty()` quando OFF (não toca no Firebase não-inicializado).
- `syncProvider` retorna o controller sem registrar listeners quando OFF (inerte).
- `firebase_options.dart` é um **placeholder versionado** (os valores não são segredo; o app precisa
  dele para compilar). Ao provisionar, troca-se por valores reais (ou injeta via secret no CI).

**Gradle sem o plugin google-services.** De propósito: o app inicializa por `FirebaseOptions`
explícitas (padrão FlutterFire moderno), então não precisa do `google-services.json` em tempo de build
— o que evita quebrar o CI enquanto não há projeto Firebase. `minSdk = 23` (Firebase Auth).

**CI tolerante a secrets ausentes.** `build-apk.yml` só injeta keystore/firebase se o secret existir;
senão assina em **debug** (instala mesmo assim) e usa o `firebase_options.dart` versionado. Isso permite
o primeiro build já funcionar sem nenhum secret configurado. Publica no `ci-latest`; `scripts/release.sh`
corta o release nomeado com asset de nome fixo `carlog.apk` (link perene) — mesmo esquema do lista_app.

**Cálculo de consumo (o núcleo).** `util/consumo.dart`, funções puras **com testes** (`test/consumo_test.dart`,
4 casos verdes):
- Trecho *tanque-cheio→tanque-cheio*: distância = Δodômetro entre dois abastecimentos completos; litros
  = soma de TUDO abastecido no intervalo (inclui parciais no meio); km/L = distância/litros. Precisa de
  ≥2 tanques cheios. Ordena por odômetro (cronologia física).
- `mediaGeral` = distância total / litros totais (ponderada, não média das médias).
- `kmRodadosNoMes`: usa a última leitura ANTES do mês como base; senão a menor leitura do mês.
- `kmPorMesEstimado`: Δodômetro / Δdias × 30 — alimenta a previsão de data da próxima revisão.

**Persistência uniforme.** `ListaNotifier<T>` (base AsyncNotifier) dá insere/atualiza/remove por `id`
para todos os stores-lista; cada repo concreto só informa chave + (de/para)Json. Veículo é objeto único
(`VeiculoNotifier`). As chaves (`store_keys.dart`) SÃO os campos do Firestore → manter `todosOsStores`
em dia = sync cobre tudo.

**pt-BR.** `flutter_localizations` + `intl` com `initializeDateFormatting('pt_BR')` no `main` (senão o
`DateFormat` com locale pt-BR lança `LocaleDataException`). `MaterialApp.locale = pt_BR` → date pickers
em português. `parseNumero` aceita vírgula OU ponto como decimal.

**FIPE.** API pública `parallelum.com.br/fipe/api/v1/carros` (sem chave): marcas → modelos → anos →
valor. `Valor` vem "R$ 45.678,00" → parse removendo `R$`/pontos e trocando vírgula por ponto. Tela em
cascata com `DropdownButtonFormField`; salva `fipeValor/fipeMesRef/fipeCodigo` no veículo; **valor
manual** como reserva quando a API falha/sem internet.

**Analyze/testes.** `flutter analyze lib/` limpo; `flutter test` 4/4 verdes. (Rodar como root só avisa.)
`DropdownButtonFormField` usa `initialValue` e `SwitchListTile` usa `activeThumbColor` — ambos OK no
3.44.7.
