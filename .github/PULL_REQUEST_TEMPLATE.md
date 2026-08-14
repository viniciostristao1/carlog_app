<!-- Fluxo em AGENTS.md. Branch = deepseek/<assunto>. NÃO commitar no main; NÃO mexer em versão/release. -->

## O que muda
<!-- 1-2 linhas: o que e por quê (para o usuário). -->

## Checklist (Definition of Done — AGENTS.md §7)
- [ ] `cd app && flutter analyze lib/` limpo e `flutter test` verde
- [ ] Texto de UI em pt-BR; cores via `AppColors`; formatação via `format.dart`
- [ ] Store novo? modelo + `store_keys` (+ `todosOsStores`) + provider + sync (ver ARQUITETURA §"Adicionar um STORE")
- [ ] Sem segredos no diff (`*.jks`, `google-services.json`, `key.properties`); nada fora de `/root/carlog_app/`
- [ ] Nenhum gotcha de build reintroduzido (AGENTS.md §6: minify/shrinkResources off, sem flutter_timezone, heap 4G, dontwarn ML Kit)
- [ ] 1 linha em `ATUALIZACOES.md` (se visível) + nota em `APRENDIZADOS.md`

## Como testei
<!-- analyze/test; se tocou lógica, cite o teste. -->
