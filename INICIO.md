# CarLog — INÍCIO (ler primeiro em toda tarefa)

App **Flutter** que é o **diário do carro do usuário**. Tela principal com **botões
redondos** (atalhos rápidos) para lançar/consultar: **abastecimento**, **consumo/média**,
**revisões**, **minha FIPE**, **calibragem de pneus** e **lembretes** (IPVA/seguro/etc.).
Design escuro "painel de carro". Meta futura: **Play Store**.

> ⚠️ Projeto isolado. Vive **só** em `/root/carlog_app/`.
> NUNCA tocar em `/root/trading/`, `/root/trading_acoes/`, `/root/trading_opcoes/`,
> `/root/calistenia_app/`, `/root/lista_app/`, `/root/adm-projetos/`.

> 📓 **Fluxo fixo (harness):** ao fim de cada bloco significativo →
> 1. `cd app && /root/flutter/bin/flutter analyze lib/` (e `flutter test` se tocou lógica) limpo;
> 2. **subir a versão** em `app/pubspec.yaml` (`X.Y.Z+N` → o `+N` é o versionCode, tem de crescer;
>    a tag do release = `vX.Y.Z`);
> 3. registrar em [`APRENDIZADOS.md`](APRENDIZADOS.md) (técnico) e, se for visível ao usuário,
>    UMA LINHA em [`ATUALIZACOES.md`](ATUALIZACOES.md) (topo = mais recente); planos → [`IDEIAS.md`](IDEIAS.md);
> 4. **commit + push na `main`** → o CI compila o APK/AAB na nuvem e publica no `ci-latest`;
>    depois `scripts/release.sh vX.Y.Z "<nota>"` corta o release nomeado (link perene `carlog.apk`).
>
> Papéis dos docs: referência (`INICIO`) · **como contribuir/regras (`AGENTS.md` — LER antes de editar
> código)** · mapa de padrões (`ARQUITETURA.md`) · técnico/gotchas (`APRENDIZADOS`) · changelog do
> usuário (`ATUALIZACOES`) · futuro (`IDEIAS`) · nuvem (`FIREBASE`).

## ⭐ ESTADO ATUAL (2026-08-14) — ler primeiro pós-/clear

**v0.11.0 — NUVEM LIGADA + OCR** (`flutter analyze` limpo, 7 testes de consumo/previsão passando). Repositório GitHub
**criado e no ar** (`viniciostristao1/carlog_app`, privado) — o CI compila **só o APK** a cada push
(AAB só no lançamento; ver APRENDIZADOS), assinado pela keystore de upload. **Firebase provisionado**
(projeto `carlog-b4ef3`): `kFirebaseConfigured = true`, **login Google + sync Firestore ativos**,
`firebase_options.dart` real versionado, SHA-1 da keystore registrado. v0.1.0 = base; v0.2.x
**notificações**; v0.3.0 **nuvem/login**; v0.4.0 **ícone âmbar** (logo do usuário) + accent âmbar +
**cadastro do carro pela FIPE** + **Revisões/Programar** (km-alvo, frequência, sugestões) + **previsão
de data** da próxima revisão/itens; v0.5.0 **FIPE dentro do cadastro** + ícone maior; v0.7.0 **OCR do
orçamento** (ML Kit, grátis/offline: foto → item×valor → itens + total).

**Decisões de origem (2026-08-13):** nome **CarLog** (pacote `com.vinyapps.carlog`); armazenamento
**Firebase + login Google** (escolha do usuário) — porém, como o Firebase exige o console Google do
usuário, o código já está **Firebase-ready** e o app roda **100% local** até o flag
`kFirebaseConfigured` (`app/lib/firebase_config.dart`) virar `true`; FIPE via **API pública gratuita**
(parallelum) por marca/modelo/ano + valor manual de reserva.

**O que existe e funciona (offline + nuvem):**
- **Home** — cabeçalho do veículo (SEM desenho do carro) com **6 estatísticas clicáveis** (odômetro,
  km no mês, combustível/mês, FIPE, última calibragem, previsão de revisão) + **6 botões redondos**.
- **Abastecimento** — data, odômetro, litros e **ou preço/L (calcula total) ou valor total (calcula
  preço/L)**, tanque cheio, posto; histórico, excluir (swipe), resumo do mês.
- **Consumo/Média** — média **km/L** por trechos *tanque-cheio→tanque-cheio* (soma parciais),
  melhor/pior, km no mês, **calculadora avulsa** (cidade × rodovia).
- **Revisões** — abas **Programar** (1ª: itens com km-alvo + frequência + **autocomplete** de itens
  comuns + previsão de data) e **Histórico** (**lupa** busca peça/serviço/oficina/OCR) + **previsão da
  próxima revisão** (km ou tempo) + **média km/mês dos últimos 12 meses**. **OCR do orçamento** (foto →
  transcreve → item×valor → importa itens + total; ML Kit, grátis/offline).
- **Minha FIPE** — cascata marca→modelo→ano com **busca (lupa)**; salva no veículo; **valor manual**.
- **Cadastro do carro** — identidade **só pela FIPE** (botão "Pesquisar carro"); manual só apelido,
  placa, tanque, calibragem recomendada, intervalo de revisão.
- **Calibragem** — pressão recomendada + registro/última + histórico.
- **Lembretes** — IPVA/seguro/etc. com "faltam X dias", recorrência, valor.
- **Notificações** — avisa vencimentos e revisão (toggle em Config; fuso America/Sao_Paulo).
- **Nuvem LIGADA** — login Google + sync Firestore (Config → Entrar).
- **Dados locais** (`shared_preferences`) = fonte da verdade; sync espelha cada store no Firestore.

**O que falta / próximos passos:**
1. **Usuário usar de verdade** e iterar pelo feedback ([`IDEIAS.md`](IDEIAS.md)). App instalável no link
   perene (abaixo).
2. Backlog em [`IDEIAS.md`](IDEIAS.md): **FIPE por placa** (pago), **multi-veículo**, **tema claro**,
   gráficos, exportar histórico.
3. **Reativar minify/R8** só quando houver runner de CI maior (hoje desligado por OOM — ver
   `APRENDIZADOS`); **AAB** volta na hora do lançamento na Play Store.
4. **Contribuição por IA (DeepSeek):** seguir o [`AGENTS.md`](AGENTS.md) — DeepSeek implementa em branch,
   Claude audita (`analyze`/`test`/gotchas) e só então mescla + corta release.

## O que o app faz (MVP)
Tela principal = 6 atalhos redondos:
1. **⛽ Abastecimento** — litros, preço, odômetro, posto; histórico e gasto do mês.
2. **📈 Consumo/Média** — média automática (km/L) e calculadora avulsa cidade/rodovia; km do mês.
3. **🔧 Revisões** — histórico buscável + lista "a programar" + estimativa da próxima.
4. **💲 Minha FIPE** — valor do veículo pela tabela FIPE (ou manual).
5. **🛞 Calibragem** — pressão recomendada + quando foi calibrado.
6. **🗓️ Lembretes** — vencimentos (IPVA, seguro, licenciamento…), "faltam X dias".

## Princípios (não violar)
1. **Rápido** — lançar um abastecimento/consulta em poucos toques (a home é toda atalho).
2. **Local primeiro** — funciona 100% offline; a nuvem é um plus opcional (sync sem migração).
3. **Sem dado inventado** — nada de estimativa mágica; média/consumo saem do que o usuário lança.
4. **Tudo editável / excluível.**

## Técnico
- Flutter **3.44.7** / Dart **3.12.2** em `/root/flutter`.
- Estado: **Riverpod** (`flutter_riverpod`); persistência: **shared_preferences** (fonte da verdade,
  offline); nuvem opcional: **Firebase** (Auth Google + Firestore) atrás de `kFirebaseConfigured`.
- FIPE: **http** para a API pública parallelum. Formatação pt-BR: **intl** + `flutter_localizations`.
- Arquitetura **feature-based**: `app/lib/features/<feature>/`.
- Pacote Android: **com.vinyapps.carlog** (applicationId — NÃO mudar). Nome de exibição: **CarLog**.
- `minSdk` **23** (exigência do Firebase Auth). **Build de release: na nuvem (GitHub Actions).**

## Estrutura do código (`app/lib/`)
> Mapa de PADRÕES (como adicionar store/tela/sync) → [`ARQUITETURA.md`](ARQUITETURA.md).
- `models/` — `veiculo.dart`, `abastecimento.dart`, `media_manual.dart`, `revisao.dart`,
  `programacao.dart` (item com km-alvo/intervalo), `lembrete.dart`, `calibragem.dart` (todos `toJson/fromJson`).
- `services/` — `repositories.dart` (providers Riverpod por store, via `lista_notifier.dart` base),
  `store_keys.dart` (chaves = campos do Firestore + `todosOsStores`), `auth_service.dart`,
  `sync_service.dart` (JSON por store em `users/{uid}`), `notifications.dart` (agenda lembrete/revisão),
  `ocr_service.dart` (ML Kit: foto→texto→item×valor).
- `util/` — `consumo.dart` (média km/L, km-mês, `ritmoKmPorDia`, `previsaoData`, **com testes**),
  `format.dart` (pt-BR + `parseNumero`), `ids.dart` (`novoId`), `messenger.dart`.
- `theme/` — `app_colors.dart` (tokens + `accent` âmbar + cor por categoria), `app_theme.dart`.
- `widgets/` — `botao_redondo.dart`, `estado_vazio.dart`, `campo_sugestoes.dart` (campo + chips de
  sugestão, ex.: postos/oficinas).
- `features/` — `home/`, `veiculo/` (cadastro só-FIPE), `abastecimento/`, `media/`, `revisoes/`
  (+ `itens_sugeridos.dart`, OCR no form), `fipe/` (`fipe_service`, `fipe_seletor` c/ busca,
  `fipe_picker_screen`, `fipe_screen`), `calibragem/`, `lembretes/`, `config/`.
- `firebase_config.dart` — flag `kFirebaseConfigured` (=true) + `kGoogleServerClientId`.
- `firebase_options.dart` — config real do projeto `carlog-b4ef3` (valores não são segredo).

## Entrega & Release (como o app chega no celular)
A VPS não compila Android bem → o build sai na **nuvem** (GitHub Actions,
`.github/workflows/build-apk.yml`). O workflow é **tolerante a secrets ausentes**: sem keystore, assina
em **debug** (instala mesmo assim); sem `FIREBASE_OPTIONS_DART`, usa o `firebase_options.dart`
versionado. Ciclo por mudança:
1. Editar o código; `flutter analyze`/`test` limpos; subir a versão no `pubspec.yaml`.
2. `git commit` + `git push origin main` → push em `app/**` dispara o CI → compila APK arm64 + AAB e
   publica no **release rolling `ci-latest`**. Acompanhar: `gh run watch <id> --exit-status`.
3. Com o CI verde: `scripts/release.sh vX.Y.Z "<nota 1 linha>"` → cria o release com o APK de **nome
   fixo** `carlog.apk` → o link `/releases/latest/download/carlog.apk` serve sempre a última.

### 🔗 Link "latest" perene
- **Página:** `https://github.com/viniciostristao1/carlog_app/releases/latest`
- **APK arm64 direto:** `https://github.com/viniciostristao1/carlog_app/releases/latest/download/carlog.apk`
⚠️ Se o repo for **privado**, o download só funciona **logado no GitHub** (curl anônimo dá 404).

> **Assinatura (Play Store):** quando for lançar, gerar a keystore de upload, guardar como secrets
> `KEYSTORE_BASE64`/`KEYSTORE_PASSWORD` (alias `upload`) — o Gradle já lê `key.properties` e o CI já
> injeta condicionalmente. **Guardar backup da keystore.** Mesmo padrão do `lista_app`/`calistenia`.

## Ambiente
VPS: ~1 vCPU, pouca RAM. OK para codar/`flutter analyze`/`flutter test`; **build de APK sai na nuvem**.
