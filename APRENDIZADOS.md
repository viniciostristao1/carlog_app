# CarLog — APRENDIZADOS (diário técnico + gotchas)

Topo = mais recente. Registrar aqui toda decisão técnica, gotcha e o "porquê".

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
