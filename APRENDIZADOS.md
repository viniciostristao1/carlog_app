# CarLog — APRENDIZADOS (diário técnico + gotchas)

Topo = mais recente. Registrar aqui toda decisão técnica, gotcha e o "porquê".

## 2026-08-13 — OCR do orçamento, grátis/offline (v0.6.0)

- `google_mlkit_text_recognition` (0.15.1, modelo Latin **bundled**, roda no aparelho, sem custo/rede) +
  `image_picker` (1.2.3, câmera/galeria). `services/ocr_service.dart`: `lerDe(ImageSource)` →
  `TextRecognizer(latin).processImage` → `_parse`: separa **item × valor** por linha (regex de valor
  BR `\d{1,3}(\.\d{3})*|\d+ , \d{2}`, pega o último match como valor, resto = descrição); detecta
  **total** (linha com "total"). Fecha o recognizer no `finally`.
- UI em `RevisaoFormScreen`: "Ler foto" → sheet câmera/galeria → OCR → `_OcrReviewSheet` (checkbox por
  linha, marca por padrão linhas curtas ≤48; "Importar (N)") → adiciona itens (`desc — R$ x`) +
  `textoBruto` (buscável) + preenche `custo` com o total se vazio.
- **Defesa de build:** `kotlin.jvm.target.validation.mode=warning` no `android/gradle.properties` —
  evita o erro "Inconsistent JVM Target" caso um plugin (ML Kit) misture alvos Java/Kotlin. Sem impacto
  em runtime. (Foi o que derrubou o `flutter_timezone`; aqui prevenido.)
- Sem permissão CAMERA no manifesto de propósito: o image_picker delega ao app de câmera (evita exigir
  permissão). `analyze` limpo.
- **Build quebrou no 1º push (v0.6.0):** `R8: Missing class com.google.mlkit.vision.text.chinese/
  japanese/korean/devanagari...` — o plugin referencia reconhecedores de outros idiomas (não incluídos,
  só usamos Latin) e o minify (R8) trata classe faltante como ERRO. **Fix (v0.6.1):**
  `android/app/proguard-rules.pro` com `-dontwarn com.google.mlkit.vision.text.{chinese,devanagari,
  japanese,korean}.**` + `isMinifyEnabled=true` e `proguardFiles(...)` no release. Lição: plugin de
  ML Kit + R8 quase sempre exige regra `-dontwarn` dos idiomas não usados.

## 2026-08-13 — FIPE dentro do cadastro + ícone maior (v0.5.0)

- Cascata FIPE extraída para `features/fipe/fipe_seletor.dart` (`FipeSeletor` + `FipeSelecao` +
  `combustivelDaFipe`), reusada por `FipeScreen` (salva no veículo) e por `FipePickerScreen` (devolve a
  seleção via `Navigator.pop`). No `VeiculoFormScreen`: botão **“Preencher pela tabela FIPE”** →
  picker → preenche marca/modelo/ano/combustível + guarda os campos FIPE no state (persistem ao salvar).
- Ícone: `gerar_icone.py` com `FG=800` (~78%, era 66%) → logo maior no adaptive.

## 2026-08-13 — Ícone, FIPE→cadastro, Programar + previsão (v0.4.0)

- **Ícone:** logo do usuário (`1786658805549.png`, carro + 6 ícones, fundo âmbar) processado por
  `tools/gerar_icone.py` (Pillow no `tools_venv`): +saturação/−brilho → âmbar `#E18700` (o original
  ficava "claro"), quadrado por padding, gera `assets/icon/carlog_icon.png` (legacy) + `carlog_fg.png`
  (adaptive foreground a 66%, anel dentro da safe zone). `flutter_launcher_icons` com
  `adaptive_icon_background: #E18700`. **Accent do app trocado de teal p/ âmbar** `#F5A524`
  (`AppColors.accent`), como os irmãos. `catCalibragem` segue teal (cor de categoria).
- **FIPE → cadastro:** `_salvarNoVeiculo` agora cria/atualiza o `Veiculo` com marca/modelo/ano/
  combustível (map de `Combustivel` a partir do texto FIPE) + valor; cria veículo se não existir.
  Botão "Usar como meu carro". Placa segue manual. Tudo opcional.
- **Revisões:** abas invertidas (**Programar = índice 0**). `ItemProgramado` ganhou `kmAlvo` +
  `intervaloKm`. Sheet com autocomplete (`itens_sugeridos.dart`, normaliza acento; sugestão preenche
  intervalo típico, editável). Marcar feito em item com `intervaloKm` **reagenda** (kmAlvo += intervalo).
- **Previsão (consumo.dart):** `ritmoKmPorDia` (janela últimos 90d, fallback p/ todo histórico) +
  `previsaoData(faltamKm, kmPorDia)`. Usado na "próxima revisão" e por item (faltam km + ≈ data).
  Testado (`test/consumo_test.dart`, 7 casos verdes).

## 2026-08-13 — Firebase provisionado / nuvem ligada (v0.3.0)

Projeto **`carlog-b4ef3`** criado pelo usuário. Login Google + Firestore ativados, SHA-1 da keystore de
upload registrado (`certificate_hash` do oauth_client type 1 bate com o SHA-1 da keystore → login
reconhece o app). Wiring feito **sem** o plugin google-services (padrão FlutterFire: init por
`FirebaseOptions` explícitas):
- `firebase_config.dart`: `kFirebaseConfigured = true` + `kGoogleServerClientId` = Web client ID
  (oauth_client `client_type: 3`).
- `firebase_options.dart`: valores reais versionados (apiKey/appId/senderId/projectId/storageBucket —
  **não são segredo**; segurança = regras Firestore + SHA-1). `google-services.json` NÃO é versionado
  nem necessário (não aplicamos o plugin).
- Nenhum secret novo no CI: o `firebase_options.dart` versionado basta.
- **Gotcha herdado (lista_app):** o 1º google-services.json baixado vinha com `oauth_client: []` porque
  o usuário baixou ANTES de ativar o Google Auth + adicionar o SHA-1. Rebaixar depois de ativar os dois
  preencheu os clients (type 1 Android + type 3 Web). Sempre pedir o json DEPOIS desses passos.

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
