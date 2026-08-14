# CarLog

O **diário do seu carro**, em Flutter. Tela principal com atalhos redondos para registrar e consultar
tudo do veículo — rápido, num toque.

**Funciona (v0.1.0, offline):**
⛽ Abastecimento · 📈 Consumo/Média (km/L) · 🔧 Revisões (histórico buscável + a programar) ·
💲 Minha FIPE · 🛞 Calibragem · 🗓️ Lembretes (IPVA/seguro/…).

## Baixar o app (Android)
Link fixo — sempre a versão mais nova (basta atualizar a página):
`https://github.com/viniciostristao1/carlog_app/releases/latest/download/carlog.apk`

## Para desenvolver / contribuir (inclusive IA)
- Flutter 3.44.7 em `/root/flutter`. Código em `app/`.
- Conferir: `cd app && flutter analyze lib/` e `flutter test`.
- **Contribuindo (DeepSeek/IA):** leia [`AGENTS.md`](AGENTS.md) (fluxo + regras) e
  [`ARQUITETURA.md`](ARQUITETURA.md) (padrões: como adicionar store/tela/sync).
- Docs: [`INICIO.md`](INICIO.md) (visão + estado), [`APRENDIZADOS.md`](APRENDIZADOS.md) (técnico/gotchas),
  [`ATUALIZACOES.md`](ATUALIZACOES.md) (changelog), [`IDEIAS.md`](IDEIAS.md) (futuro),
  [`FIREBASE.md`](FIREBASE.md) (nuvem).

Build de release sai na nuvem (GitHub Actions) — a VPS não compila Android bem.
