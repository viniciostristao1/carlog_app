# AGENTS.md — como contribuir no CarLog (guia p/ IA: DeepSeek etc.)

Este arquivo é o **fluxo de trabalho** para qualquer agente de IA (ou pessoa) melhorar o CarLog.
O repositório é **self-contained**: tudo que você precisa está aqui, sem depender de memória externa.

## 0. Ordem de leitura (sempre)
1. [`INICIO.md`](INICIO.md) — o que é o app, estado atual, estrutura.
2. **Este `AGENTS.md`** — regras e fluxo.
3. [`ARQUITETURA.md`](ARQUITETURA.md) — padrões (como adicionar store/tela/sync).
4. [`APRENDIZADOS.md`](APRENDIZADOS.md) — **gotchas de build** (leia antes de mexer em Gradle/deps!).
5. O código da feature que vai tocar (`app/lib/features/<feature>/`).

## 1. Divisão de trabalho (o fluxo)
O `main` **compila e vira release automaticamente**. Então mudança não-auditada NÃO entra direto no `main`.

```
DeepSeek (gera/implementa)  →  branch  deepseek/<assunto>   (NUNCA commita no main)
        ↓
Auditoria (Claude/usuário): flutter analyze + flutter test + checklist de gotchas
        ↓
Merge no main  →  CI compila o APK  →  scripts/release.sh corta o release
```

- **DeepSeek:** crie uma branch `deepseek/<assunto>`, implemente, rode a verificação local (§4) e
  **abra um PR** (ou deixe a branch pronta). **Não** commite no `main`, **não** rode `release.sh`,
  **não** mexa em versão/tag — isso é o passo de auditoria.
- **Auditor (Claude/usuário):** confere o diff, roda `analyze`/`test`, checa os gotchas (§6), faz o
  **version bump** (§5), mescla no `main`, acompanha o CI e corta o release.
- Registre o que fez: 1 linha em [`ATUALIZACOES.md`](ATUALIZACOES.md) (se visível ao usuário) e o
  técnico/decisões em [`APRENDIZADOS.md`](APRENDIZADOS.md). Planos → [`IDEIAS.md`](IDEIAS.md).

## 2. Regras de ouro (NÃO violar)
- **Projeto isolado.** Só `/root/carlog_app/`. NUNCA tocar em `/root/trading*`, `/root/calistenia_app`,
  `/root/lista_app`, `/root/adm-projetos`.
- **Nunca commitar segredos:** `*.jks`, `key.properties`, `google-services.json` (já no `.gitignore`).
  *(o `firebase_options.dart` É versionado — os valores não são segredo; NÃO troque o projeto/chaves.)*
- **Não** mexer na keystore de upload nem no projeto Firebase (`carlog-b4ef3`) / `applicationId`
  (`com.vinyapps.carlog`) — quebra assinatura, login e updates.
- **Não** compilar APK localmente (a VPS é fraca) — o build de release sai na **nuvem** (GitHub Actions).
  Verifique só com `analyze` + `test`.
- **Não reintroduzir gotchas de build** (§6): minify/shrinkResources, `flutter_timezone`, etc.
- **Não** apagar/editar arquivos que você não criou sem necessidade; derive/adicione.

## 3. Convenções de código
- **Português (pt-BR)** em todo texto de UI.
- **Cores só via `AppColors`** (`theme/app_colors.dart`) — nunca `Color(0x...)` solto. `AppColors.accent`
  é âmbar; cada categoria tem sua cor (`catAbastecimento`, `catConsumo`, …).
- **Formatação via `util/format.dart`** (`moeda`, `km`, `litros`, `kmL`, `dataCurta`, `dataLonga`,
  `parseNumero` — aceita vírgula OU ponto). **IDs via `novoId()`** (`util/ids.dart`).
- **Estado = Riverpod**; persistência local = `shared_preferences` (fonte da verdade).
- **Arquitetura feature-based:** telas em `features/<x>/`, modelos em `models/`, lógica pura em `util/`
  (com teste em `test/`).
- Todo **modelo** tem `toJson`/`fromJson`. **Novo store persistido** exige passos extras — ver
  [`ARQUITETURA.md`](ARQUITETURA.md) (senão a sincronização não cobre e há "lacuna").
- Lógica de cálculo (média, previsão, parsing) vai em `util/` **com teste** — não enfie em widget.

## 4. Verificação local (obrigatória antes do PR)
```bash
cd /root/carlog_app/app
/root/flutter/bin/flutter analyze lib/     # tem de dar "No issues found!"
/root/flutter/bin/flutter test             # tem de passar (hoje 7 testes)
```
Rodar como root só emite um aviso; funciona. **Não** rode `flutter build apk` (memória/tempo).

## 5. Fluxo de release (passo do auditor, após merge no main)
1. Subir a versão em `app/pubspec.yaml` (`X.Y.Z+N` — o `+N`/versionCode **tem de crescer**; toda
   mudança visível ganha um `MINOR`). Atualize a versão exibida em `config_screen.dart` e no `INICIO.md`.
2. `git commit` + `git push origin main` → push em `app/**` dispara o CI. Acompanhe:
   `gh run watch <id> --exit-status`.
3. Com o CI **verde**: `scripts/release.sh vX.Y.Z "<nota 1 linha>"` → publica o APK de nome fixo
   `carlog.apk` (link perene `/releases/latest/download/carlog.apk`).

## 6. Checklist de gotchas de build (NÃO reintroduzir — detalhes em APRENDIZADOS.md)
- ⛔ **Minify/R8 e `shrinkResources` ficam DESLIGADOS** no release (`app/android/app/build.gradle.kts`):
  R8 com ML Kit + Firebase estourava a RAM do runner (exit 143). Só religar com runner maior.
- ⛔ **Não re-adicionar `flutter_timezone`** (conflito de JVM target). O fuso é fixo `America/Sao_Paulo`.
- ⛔ **Heap do Gradle** fica em `-Xmx4G` (`app/android/gradle.properties`) — 8G estourava o runner.
- ✅ **ML Kit exige** as regras `-dontwarn` em `app/android/app/proguard-rules.pro` (idiomas não usados)
  E `kotlin.jvm.target.validation.mode=warning` no `gradle.properties`.
- ✅ **CI compila só o APK** (o passo do AAB era cancelado por OOM); AAB só no lançamento.
- ✅ Ao adicionar **plugin nativo novo**: espere possível quebra de build na nuvem; teste com um push e
  leia o log (`gh run view <id> --log-failed`). `analyze` local NÃO pega erro de Gradle/R8/memória.

## 7. Definition of Done (checklist do PR)
- [ ] `flutter analyze lib/` limpo e `flutter test` verde.
- [ ] Texto de UI em pt-BR; cores via `AppColors`; formatação via `format.dart`.
- [ ] Se criou store novo: modelo + `store_keys` + provider + sync (ver ARQUITETURA).
- [ ] Nenhum segredo no diff; nada fora de `/root/carlog_app/`.
- [ ] Nenhum gotcha do §6 reintroduzido.
- [ ] 1 linha em `ATUALIZACOES.md` (se visível) + nota técnica em `APRENDIZADOS.md`.
- [ ] Branch `deepseek/<assunto>` (não commitou no main; não mexeu em versão/release).
