# CarLog — IDEIAS (fila do futuro)

Datar e marcar status. Ideias saem daqui para virar versão.

## Prioridade alta (pedidas na origem, adiadas por dependência)
- **[ ] OCR do orçamento de revisão.** Tirar foto do orçamento → extrair peças/serviços automaticamente,
  virar itens buscáveis pela lupa. Plano: **Google ML Kit Text Recognition** (on-device, offline, grátis)
  via `google_mlkit_text_recognition` + `image_picker`. Hoje o app já aceita colar/digitar o texto do
  orçamento (campo `textoBruto`, buscável). *(2026-08-13)*
- **[x] Notificações de vencimento/revisão.** FEITO na v0.2.0 (`flutter_local_notifications` + timezone).
  Avisa no dia e 3 dias antes de cada lembrete e quando a próxima revisão se aproxima; toggle em
  Configurações. *Falta testar em aparelho real (agendamento só verificável no device).* *(2026-08-13)*
- **[x] Ligar a nuvem (Firebase).** FEITO na v0.3.0 — projeto `carlog-b4ef3`, login Google + sync
  Firestore. *Falta o usuário logar no app e testar o sync entre aparelhos.* *(2026-08-13)*

## Prioridade média
- **[ ] FIPE por placa.** Só digitar a placa e puxar marca/modelo/ano/valor. Exige serviço **pago**
  (a FIPE grátis é por marca/modelo/ano). Avaliar quando fizer sentido. *(2026-08-13)*
- **[ ] Ícone e nome de exibição próprios** (arte do app). *(2026-08-13)*
- **[ ] Gráfico de preço do combustível** e de evolução do consumo ao longo do tempo. *(2026-08-13)*
- **[ ] Editar observação da calibragem / anexar nota.** *(2026-08-13)*
- **[ ] Custo por km e "gasto total do carro"** (combustível + revisões + impostos) num painel. *(2026-08-13)*

## Prioridade baixa / a discutir
- **[ ] Multi-veículo** (hoje é um carro só). Exigiria escopar todos os stores por veículo. *(2026-08-13)*
- **[ ] Exportar/compartilhar** histórico (CSV/PDF). *(2026-08-13)*
- **[ ] Tema claro** (hoje só escuro; `AppColors` está pronto para virar switch de paleta). *(2026-08-13)*
- **[ ] Registro de estacionamento/pedágio como despesa** (hoje entram como lembrete). *(2026-08-13)*
