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
> Papéis dos docs: referência (`INICIO`) · técnico (`APRENDIZADOS`) · changelog do usuário
> (`ATUALIZACOES`) · futuro (`IDEIAS`) · nuvem (`FIREBASE`).

## ⭐ ESTADO ATUAL (2026-08-13) — ler primeiro pós-/clear

**v0.4.0 — NUVEM LIGADA** (`flutter analyze` limpo, 7 testes de consumo/previsão passando). Repositório GitHub
**criado e no ar** (`viniciostristao1/carlog_app`, privado) — o CI compila **só o APK** a cada push
(AAB só no lançamento; ver APRENDIZADOS), assinado pela keystore de upload. **Firebase provisionado**
(projeto `carlog-b4ef3`): `kFirebaseConfigured = true`, **login Google + sync Firestore ativos**,
`firebase_options.dart` real versionado, SHA-1 da keystore registrado. v0.1.0 = base; v0.2.x
**notificações**; v0.3.0 **nuvem/login**; v0.4.0 **ícone âmbar** (logo do usuário) + accent âmbar +
**cadastro do carro pela FIPE** + **Revisões/Programar** (km-alvo, frequência, sugestões) + **previsão
de data** da próxima revisão/itens.

**Decisões de origem (2026-08-13):** nome **CarLog** (pacote `com.vinyapps.carlog`); armazenamento
**Firebase + login Google** (escolha do usuário) — porém, como o Firebase exige o console Google do
usuário, o código já está **Firebase-ready** e o app roda **100% local** até o flag
`kFirebaseConfigured` (`app/lib/firebase_config.dart`) virar `true`; FIPE via **API pública gratuita**
(parallelum) por marca/modelo/ano + valor manual de reserva.

**O que existe e funciona (local, offline):**
- **Home** com cabeçalho do veículo (odômetro, km do mês, FIPE) + **6 botões redondos**.
- **Abastecimento** — adicionar (data, odômetro, litros, preço/L, tanque cheio, posto), total ao vivo,
  histórico, excluir (swipe), resumo do mês.
- **Consumo/Média** — média geral **km/L** calculada por trechos *tanque-cheio→tanque-cheio* (soma
  parciais no meio), melhor/pior, km rodados no mês, e uma **calculadora de média avulsa**
  (cidade × rodovia) salva no histórico.
- **Revisões** — abas **Histórico** (com **lupa** que busca peça/serviço/oficina/texto do orçamento)
  e **Programar** (checklist do que verificar na próxima) + **estimativa da próxima revisão**
  (alvo em km + previsão de data pelo ritmo de rodagem).
- **Minha FIPE** — consulta em cascata marca→modelo→ano na API pública; salva o valor no veículo;
  **valor manual** como reserva.
- **Calibragem** — pressão recomendada (vem do cadastro do veículo) + data/registro da última + histórico.
- **Lembretes** — IPVA/seguro/licenciamento/etc. com "faltam X dias", recorrência (marcar pago empurra
  a data no caso recorrente), valor, excluir.
- **Configurações** — bloco de conta (login Google **quando** a nuvem estiver ligada; senão "dados
  neste aparelho") + sobre.
- **Dados 100% locais** (`shared_preferences`), já modelados para sincronizar na nuvem sem migração.

**O que falta (próximos passos, em ordem):**
1. **Criar o repositório GitHub** `viniciostristao1/carlog_app` e dar o primeiro push (dispara o CI →
   gera o APK). *Requer o usuário* (ou `gh repo create`).
2. **Instalar o APK** no celular e usar de verdade → iterar pelo feedback ([`IDEIAS.md`](IDEIAS.md)).
3. **Provisionar o Firebase** (Auth Google + Firestore) e ligar a nuvem — passo a passo em
   [`FIREBASE.md`](FIREBASE.md). Só então `kFirebaseConfigured = true`.
4. Candidatos de feature: **OCR do orçamento** (ML Kit on-device), **FIPE por placa** (serviço pago),
   **ícone próprio**. (Notificações de lembrete/revisão já entraram na v0.2.0.)

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
- `models/` — `veiculo.dart`, `abastecimento.dart`, `media_manual.dart`, `revisao.dart`,
  `programacao.dart`, `lembrete.dart`, `calibragem.dart` (todos com `toJson/fromJson`).
- `services/` — `repositories.dart` (providers Riverpod por store, via `lista_notifier.dart` base),
  `store_keys.dart` (chaves = campos do Firestore), `auth_service.dart`, `sync_service.dart` (JSON por
  store em `users/{uid}`, gated pelo flag).
- `util/` — `consumo.dart` (cálculo de média/km-mês, **com testes**), `format.dart` (pt-BR),
  `ids.dart`, `messenger.dart`.
- `theme/` — `app_colors.dart` (tokens + cor por categoria), `app_theme.dart`.
- `widgets/` — `botao_redondo.dart`, `estado_vazio.dart`.
- `features/` — `home/`, `veiculo/`, `abastecimento/`, `media/`, `revisoes/`, `fipe/`,
  `calibragem/`, `lembretes/`, `config/`.
- `firebase_config.dart` — o flag `kFirebaseConfigured` (interruptor da nuvem) + `kGoogleServerClientId`.
- `firebase_options.dart` — **placeholder** versionado (substituir ao provisionar; ver `FIREBASE.md`).

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
