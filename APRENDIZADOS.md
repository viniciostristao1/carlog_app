# CarLog — APRENDIZADOS (diário técnico + gotchas)

Topo = mais recente. Registrar aqui toda decisão técnica, gotcha e o "porquê".

## 2026-08-16 — Repo PÚBLICO, logo no AppBar, preço editável, OCR (km/número) (v0.15.0)

- **Repositório virou PÚBLICO** (`gh api -X PATCH repos/... -f visibility=public`) — limite de Actions
  minutes de repo privado estourou; público = CI sem limite. **Antes**: auditoria de segredos (tree +
  histórico completo) → limpa (nenhum `.jks`/`key.properties`/`google-services.json` jamais commitado; só
  referências a `$KEYSTORE_PASSWORD`, que vem dos **secrets do GitHub**, que continuam privados; o
  `firebase_options.dart` é config cliente pública por design). **Regra:** antes de tornar repo público,
  varrer `git log --all -p` por chaves/senhas/tokens, não só a árvore atual.
- **Logo no AppBar (item 3):** `assets/icon/carlog_logo.png` (128px, ~25KB — reduzido do `carlog_icon.png`
  1024px via PIL p/ não inflar o APK), **declarado em `flutter: assets:`** (os PNGs 1024 do
  `flutter_launcher_icons` são build-time, NÃO entram no bundle). `Image.asset` + `ClipRRect(7)` na Home.
- **Preço editável (item 1):** item segue `String` "Nome — R$ 00,00" (`_sepPreco`, `_separaPreco`,
  `_juntaPreco`). Chips viraram `InputChip` (onPressed=editar via diálogo nome+preço; onDeleted=remover).
  Cobre sugeridas (entram sem preço → toca p/ pôr) e as já salvas (edita a revisão).
- **OCR (itens 2 e 4):** NÃO amarra preço a item (`ItemLido.valor` fica null; importa só a descrição);
  ignora "número solto" (linha sem letra, ex.: "200,00") e a linha de "total" (vira `custo`); **preserva
  especificação** que não é preço ("Óleo 15W40" — o regex de valor exige `,dd`, então "15W40" fica).
  **Quilometragem** (`_kmDe`): número (≥100) perto de km/quilometragem/odômetro → `OcrResultado.km` →
  campo de odômetro (não vira item; "12 km/L" é rejeitado por ser <100). Coberto por `ocr_filtro_test`.

## 2026-08-16 — Revisões (obs./preço/limpar/busca), OCR filtra pessoal, botões bege (v0.14.0)

- **Modelo `Revisao`:** +campo `observacao` (default '', em `toJson/fromJson` e no `indiceBusca`). Como o
  store serializa o objeto inteiro, o sync cobre o campo novo automaticamente.
- **`_CartaoRevisao` (Histórico):** peças limitadas a `maxChips=4` + chip **"+N"**; recebe `termo` da lupa
  (já `semAcento`), joga o item que casa para a frente e o **destaca** (accent). A busca do `_historico`
  passou a usar `semAcento(indiceBusca).contains(semAcento(termo))` — **ignora acento/caixa** (antes era
  só `toLowerCase`, então "oleo" não achava "Óleo").
- **Form da revisão:** campo **Observações** (`_observacao`) abaixo do texto do orçamento; **Limpar** ao
  lado de "Peças/serviços" (`_itens.clear()`); **preço por peça** (`_precoItem`) — vira `"Nome — R$ 00,00"`
  (mesmo formato do OCR, modelo segue `List<String>`, sem migração).
- **OCR (item 6):** `_ehInfoPessoal(linha)` descarta e-mail/CEP/CPF/CNPJ/telefone e rótulos de cabeçalho
  (cliente/nome/endereço/rua/avenida/bairro/cep/cpf/cnpj/telefone/celular/fone/e-mail/inscrição/whats/razão
  social). **Cuidado:** NÃO incluir "contato"/"estado" no regex (peças reais: "chave de contato"). Linhas
  pessoais somem dos itens **e** do `textoBruto` salvo; o "total" ainda é detectado mesmo em linha
  filtrada. `parseTexto()` exposto com `@visibleForTesting` → `test/ocr_filtro_test.dart`.
- **Botões redondos no bege:** agora `cor: AppColors.leg(AppColors.catX)` — escurecem só no tema claro
  (nos escuros `leg` devolve a cor). Revisão da decisão "categorias fixas": segue fixa nos temas escuros,
  mas no bege escurece p/ contraste (o usuário pediu explicitamente para média/calibragem).

## 2026-08-16 — Legibilidade no tema claro (Madeira) + calibragem menor (v0.13.2)

- **Problema:** as cores de categoria são FIXAS (pasteis claros pensados p/ fundo escuro) → como TEXTO
  no tema claro Madeira (bege) ficavam sem contraste (verde da média, teal da calibragem, roxo da FIPE…).
- **Fix:** `AppColors.leg(Color)` — no tema escuro devolve a cor; no claro **escurece o hue** via HSL
  (`lightness*0.42` clamp 0.40, satura ≥0.55) mantendo a identidade (verde continua verde). Aplicado só a
  TEXTO/ícones coloridos sobre superfície (média, calibragem, FIPE, valor calculado do abastecimento) —
  **NÃO nos botões redondos** (lá a cor é anel/ícone grande sobre tinta 0.14, e o usuário quis fixas).
- **Inversão da caixa do carro (só no claro):** `_CabecalhoVeiculo` usa `corCard = surface2` (bege mais
  escuro) e `corTile = surface` (bege claro) quando `AppColors.brilho == light` — literal "inverta as
  cores" (troca as duas superfícies). `_StatTile`/`_PlacaChip` receberam `fundo` por parâmetro; ícones dos
  tiles via `leg()`.
- Calibragem recomendada: caixa mais baixa (psi 24→20, padding e divisória menores, botão Editar
  `VisualDensity.compact`).

## 2026-08-15 — Fix: botões redondos sumiam (v0.13.1)

- ⚠️ **GOTCHA:** `_OutrosCarros` (faixa de outros carros na Home) usava
  `Row(crossAxisAlignment: CrossAxisAlignment.stretch, [Expanded, …])` **dentro do `ListView`** da Home.
  `stretch` no eixo cross de um `Row` = **vertical**, e o `ListView` dá altura **ilimitada** → o stretch
  pede altura infinita → **erro de layout em runtime** ("BoxConstraints forces an infinite height") que
  derrubava tudo abaixo na lista (os botões redondos "sumiam"). **Só aparecia com ≥1 carro** (com 0 carros
  `_OutrosCarros` já retornava `shrink`). **Fix:** envolver o `Row` em **`IntrinsicHeight`** (dá altura
  limitada = maior filho; stretch mantém os meio-cards com a mesma altura).
- **Não é pego por `flutter analyze` nem por teste de lógica** — é erro de LAYOUT em runtime. Adicionado
  `test/home_layout_test.dart` (widget test headless) que reproduz o padrão: sem `IntrinsicHeight`
  `takeException()` != null; com ele rende e o conteúdo abaixo continua presente. **Regra:** tela nova com
  layout não trivial → ao menos um `testWidgets` que dá `pumpWidget` (widget tests pegam
  overflow/constraint infinito; `analyze` não).

## 2026-08-15 — Temas + tamanho de fonte + idiomas EN/ES (v0.13.0)

- **Temas (item 10):** `AppColors` deixou de ser constantes e virou paleta trocável (padrão do irmão
  Calis): `Paleta` + getters (`bg/surface/surface2/line/lineStrong/text/dim/dim2/accent/onAccent/brilho`)
  lidos de `_pal`, setado por `aplicarTema(TemaApp)` dentro de `buildAppTheme(tema)`. **Categorias
  (`catX`) + `danger/ok/warn` seguem `const`** (decisão do usuário: cores de categoria fixas em todos os
  temas → menos churn). 4 temas: `ambar` (padrão, = grafite atual), `azul`, `espresso`, `madeira` (claro).
- ⚠️ **GOTCHA-mãe:** tokens de cor viraram getters → **`const` deixa de valer** em qualquer widget que
  referencie um token dinâmico (erro `invalid_constant`). Foram ~128 sítios. Corrigidos com script que
  acha o `const` externo que governa o token e o remove (`scratchpad/fix_const.py`; guiado por
  `dart analyze --format=machine`). `flutter_lints` **não** habilita `prefer_const_constructors`, então
  remover `const` de irmãos estáticos NÃO gera lint. **Ao escrever tela nova: nunca `const` em widget que
  usa `AppColors.text/dim/surface/...`** (só nas cores fixas de categoria).
- `StepperNum.cor` e `CampoSugestoes.cor` viraram `Color?` (default `AppColors.accent` deixou de ser
  const) → resolvem `cor ?? AppColors.accent` no build.
- **Fonte (item 11):** `TamanhoFonte {menor,normal,maior,maximo}` (0.9/1.0/1.15/1.3) em `prefs.dart`;
  aplicado global no `main` via `MediaQuery.withClampedTextScaling`. Grades da Home (`childAspectRatio`)
  ficaram adaptativas à escala (`/escala`, clamp) p/ o rótulo/valor não estourarem.
- **Idiomas (item 12):** `Idioma {pt,en,es}` + `AppStrings(idioma)` com `_s(pt,en,es)` em
  `lib/l10n/strings.dart`; `idiomaProvider`/`stringsProvider` em `prefs.dart`. Telas leem
  `ref.watch(stringsProvider)`; **helpers `StatelessWidget` com texto viraram `ConsumerWidget`**, e os que
  não têm `ref` recebem `AppStrings t` por parâmetro (ex.: `_OcrReviewSheet`, `_BuscaSheet`). Rótulos de
  enum saíram dos getters `.rotulo` para métodos `t.rotuloX(enum)` (os getters `.rotulo` viraram dead code
  inofensivo). `main` inicializa **todos** os locales (`initializeDateFormatting()`), seta `locale` +
  `supportedLocales` (pt/en/es) e `format.localeDatas` p/ `dataLonga` localizada; números/moeda/unidades
  seguem pt-BR de propósito (carro é do Brasil). `KeyedSubtree(ValueKey((tema,idioma)))` força repintura.
- **Itens de UI (1–9):** outros carros = cartões meia-largura (`_OutrosCarros`/`_CarroTile`, Row de
  Expanded) abaixo do principal; cabeçalho marca-em-cima/modelo-embaixo (modelo `maxLines:2`); revisão
  vencida → `⚠` centralizado no tile (flag `_Stat.alerta`); catálogo de itens ampliado
  (`itens_sugeridos.dart`); campos "a cada km"/"fazer no km" invertidos; botão **Limpar** + **lupa** de
  busca no fluxo do orçamento OCR.

## 2026-08-14 — Multi-veículo até 3 (v0.12.0)

- `veiculo` (objeto único, `veiculo_v1`) → **lista** `veiculos_v1` (`VeiculosNotifier`, máx `maxVeiculos=3`)
  + `veiculo_sel_v1` (id selecionado, `VeiculoSelIdNotifier`) + derivado `veiculoSelecionadoProvider`.
  **Migração local** automática do `veiculo_v1` antigo → lista de 1 (id preservado). `veiculo_v1` NÃO
  entra em `todosOsStores` (a migração é local; o `veiculos_v1` é que sincroniza). `veiculo_sel_v1` é
  string simples → `storesObjeto` (merge "mantém local, senão nuvem", não união por id).
- **Cada modelo ganhou `veiculoId`** (nullable). Telas leem via providers FILTRADOS
  (`xDoVeiculoProvider`, base `_doVeiculoSel`): item pertence ao carro se `veiculoId==sel` OU
  (`veiculoId==null` E é o 1º carro). Forms carimbam `veiculoId` ao criar (preservam ao editar).
  Notificações usam os dados filtrados do carro selecionado + reagendam ao trocar de carro.
- Home: `_SeletorCarros` (chips + "+ Carro"); excluir carro no form (`remover`, reajusta seleção).
- Padrão documentado no ARQUITETURA (seção multi-veículo) para o DeepSeek não misturar carros.

## 2026-08-14 — Campos opcionais + previsão de revisão refeita (v0.10.0)

- **Abastecimento: `odometro`, `litros`, `precoLitro` agora NULLABLE** (`double?`). `total = (litros ??
  0)*(preco ?? 0)`. `fromJson` já tolera antigos (não-nulos). Ajustado tudo em `consumo.dart` (filtra
  nulos), cards e resumos (mostram só o que existe; `String.ou(fallback)` em `format.dart`). Regra de
  salvar: ao menos 1 campo presente. **Excluir** abastecimento/revisão por botão lixeira na AppBar de
  edição (`_excluir`), além do swipe.
- **`preverRevisao(v, ab, revs)` (novo, em consumo.dart, COM teste):** o BUG era a **DATA**, não o alvo.
  **Alvo (km) = última revisão + `v.revisaoIntervaloKm` (do CADASTRO, fixo)** — NÃO inferir do histórico
  (o usuário deixou claro: "10 mil da última revisão sempre será o alvo"). O que melhorou: **odômetro
  atual = maior leitura de abastecimentos + revisões**; **ritmo = km/dia dos últimos 365 dias juntando
  as duas fontes** (antes: só abastecimentos, janela 90 dias → data muito errada); fallback por tempo
  (última revisão + `revisaoIntervaloMeses` do cadastro). Reusado na home, no card de Revisões e nas
  notificações. `kmPorMesEstimado` removido. *(v0.10.0 tinha inferido o intervalo do histórico —
  revertido na v0.10.1 a pedido do usuário.)*
- **v0.10.2 — método da DATA (definido pelo usuário):** `data = data da última revisão + (intervalo_km
  ÷ ritmo_km_dia_12meses)`. É uma **cadência por tempo** que NÃO depende do odômetro atual (que costuma
  estar desatualizado — o usuário lança abastecimento esporádico). `vencida = data.isBefore(now)`. O
  card de Revisões passou a mostrar **Alvo + Previsão(data) + média/mês** (tirado o "faltam km", que
  confundia por causa do odômetro velho). Teste trava a data ≈ últimaRevisão + intervalo/ritmo.

## 2026-08-14 — Cadastro só-FIPE com busca, home-estatísticas, logo maior (v0.7.0)

- **3ª quebra do OCR: "Removing unused resources requires unused code shrinking to be turned on"** — o
  Flutter liga `shrinkResources` no release; ao pôr `isMinifyEnabled=false` ficou inconsistente. Fix:
  `isShrinkResources=false` junto. (v0.7.0 foi o 1º build verde com o OCR.)
- **Cadastro só-FIPE:** `VeiculoFormScreen` perdeu os campos manuais de marca/modelo/ano/combustível;
  identidade vem do `FipePickerScreen` (botão "Buscar na tabela FIPE"), mostrada num cartão read-only.
  Manuais só: apelido, placa, tanque, calibragem recomendada, intervalo de revisão.
- **Busca (lupa) na FIPE:** `FipeSeletor` trocou os `DropdownButtonFormField` por campos que abrem um
  `_BuscaSheet` (TextField + lista filtrada, normaliza acento) — evita rolar ~90 marcas / centenas de
  modelos.
- **Home sem duplicidade:** `_CabecalhoVeiculo` não repete mais marca/modelo (título = apelido OU
  marca/modelo; subtítulo só com apelido). Grade de 6 estatísticas: odômetro, km/mês, combustível/mês,
  FIPE, última calibragem, **previsão de revisão** (menor data entre km-based e tempo-based;
  `_estimativaRevisao`).
- **Ícone maior:** `gerar_icone.py` faz **autocrop** do conteúdo (bbox do navy sobre o âmbar) antes de
  quadrar → desenhos preenchem; `FG=944` (~92%).

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
- **2ª quebra (v0.6.1): exit code 143** ("operation was canceled" após ~12 min) = processo **morto por
  falta de memória**. O R8 com ML Kit + Firebase é pesado E o `gradle.properties` pedia **`-Xmx8G` num
  runner de ~7 GB** (provável causa também do AAB cancelado lá atrás). **Fix (v0.6.2):** `-Xmx8G→4G`
  (+ MaxMetaspace 4G→1G) e **`isMinifyEnabled=false`** no release (desliga o R8 — passo mais pesado).
  APK fica um pouco maior, mas o build é estável. Reativar minify só com runner maior.

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
