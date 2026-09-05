# CarLog — ATUALIZAÇÕES (o que mudou, para o usuário)

Topo = mais recente. Uma linha por mudança visível + data.

- **2026-09-05 — v0.26.0.** **Novo logo (fundo preto).** Ícone do app regenerado a partir de `file_000000005e94820e9ffd7d6feec8260a.png` (adaptive `#000000`).

- **2026-08-28 — v0.25.0.** **Desfazer sugestões.** Ao tocar em `Sugerido` ou `Repetir último/última` e `Kits`, aparece botão **Desfazer** (↩) para voltar com 1 clique — além do X para dispensar antes de usar.

- **2026-08-28 — v0.24.0.** **Dispensar sugestões.** Chips `Sugerido: X km` e `Repetir último/última` agora têm um **X** para dispensar — se não quiser o automático, toque no X e eles somem até reabrir o form.

- **2026-08-28 — v0.23.0.** **Lembrete auto.** Ao programar um item (com km-alvo ou a cada X km) o app cria automaticamente um **lembrete de Revisão** com data estimada (último odômetro + ritmo → data) — com opção `Criar lembrete` para desativar.

- **2026-08-28 — v0.22.0.** **Kits de revisão + Repetir última.** Na nova revisão, chip `Repetir última: Revisão 40k (5 itens)` copia itens/oficina da revisão anterior e 5 kits (`Kit Óleo, Filtros, Freios, Correias, Revisão 10k`) adicionam vários itens de uma vez.

- **2026-08-28 — v0.21.0.** **Abastecimento 1-toque.** Ao criar abastecimento, aparece chip `Repetir último: 38L · R$ 5,89 · Shell` que preenche litros/preço/posto/tanque cheio do último abastecimento — só falta o odômetro (que já tem o chip Sugerido).

- **2026-08-28 — v0.20.0.** **Odômetro inteligente.** Ao criar abastecimento ou revisão, se o campo de **odômetro** estiver vazio, o app sugere `último + ritmo` (km/dia dos últimos 12 meses) num chip `Sugerido: 12.345 km` — toque para preencher. Evita digitar e mantém coerência com a previsão de revisão.

- **2026-08-27 — v0.19.0.** **Terracota + Config com setas + Ler foto preciso.** (1) Tema **Blueprint renomeado para Terracota** (mesma cor navy/coral) — quem já usava continua no Terracota automaticamente. (2) **Configurações com seta:** Idioma, Tema e Tamanho da fonte agora são **dropdowns** — toque na seta ↓ para abrir as opções. (3) **Ler foto muito mais preciso:** passa a ignorar "Autorizo a execução", "Requisição", "Peças", "Disp/Disponível", "Dt. Fab", cores ("BRANCO"…), "Centro/Automotivo", nomes de cliente, "N. Pré. S", "Liberada", "Data Ini. Contr", "Impressão" + datas, cidades soltas tipo "LAJEADO", "Validade", "Entrada", "Insc.Estad.", "Previsão de Entrega", "Weiand"/oficinas, data isolada, "Total Geral", "Próxima revisão", "Estou ciente e concordo…", "<<Pág" e "VALOR TOTAL ESTIMADO" — importando só as **peças de verdade**.

- **2026-08-24 — v0.18.0.** **Ler foto mais esperto + lembretes.** (1) O **leitor de orçamento** ficou
  bem melhor: passou a **ignorar** marca do carro (TOYOTA…), concessionária, cidade, CNPJ, placa,
  Emissão, Garantia, Fábrica, Cor externa, Combustível, Ano/Modelo, Documento, Legenda, Sugestão,
  "Serviço"/"Preço Total" e afins — mantendo as **peças de verdade** (inclusive quando têm a marca no
  meio, tipo "Óleo Toyota 5W30"). (2) **Corrigida a leitura do KM** quando vinha com muitos espaços (ex.:
  "KM:      120973" — antes pegava um número errado). (3) **Lembretes:** novos já vêm como **"Sem
  repetição"** (você escolhe se repete) e o botão **Lembretes** na tela inicial mostra um **número** quando
  há aviso vencido não visto (some ao abrir os lembretes). (4) A tela **"O que importar"** ganhou um
  **botão de voltar** no topo.

- **2026-08-24 — v0.17.0.** **Novo logo e horário nos lembretes.** (1) **Ícone/logo novos** — carro com
  velocímetro e os 5 atalhos ao redor (aparece no celular e no topo do app). (2) **Lembretes agora têm
  horário:** ao criar/editar um lembrete você escolhe **a que horas quer ser avisado** (padrão 09:00) —
  antes o aviso era sempre às 9h. O horário aparece no cartão do lembrete. Lembretes antigos seguem
  avisando às 9h até você editá-los.

- **2026-08-22 — v0.16.0.** **Cara nova, backup e faxina.** (1) Novo visual **Blueprint** (azul-marinho
  com destaque coral) já vem como **tema padrão** — os temas antigos (Âmbar, Azul, Expresso, Madeira)
  continuam em **Config → Aparência**. (2) **Backup em arquivo:** em **Config → Backup**, *Exportar* gera
  um arquivo com **todos os seus dados** (salve no Drive, mande pra você…) e *Importar* traz de volta —
  ele **junta** com o que já existe, **sem apagar nada**. Rede de segurança além da nuvem. (3) **Limpar
  tudo:** botão 🧹 em **Abastecimentos** e no **Histórico** de revisões (com confirmação; mexe só no carro
  atual). (4) O **leitor de foto** ignora ainda mais rótulos de ordem de serviço (Item, Cor, ORDEM DE
  SERVIÇO, Consultor, Página, HORA…). (5) A tela **"O que importar"** não fica mais colada na câmera/topo.
  (6) O **nome do carro** ocupa **uma linha só**. (7) A **previsão de revisão** mostra **"faltam X km"**
  quando ainda não dá para estimar a data (antes aparecia um número que confundia).

- **2026-08-16 — v0.15.1.** **Leitor de foto mais esperto.** Agora ele acha a **quilometragem** mesmo
  escrita como "Km/Horas: 166.710" (número mais adiante na linha) e a joga **direto no campo de odômetro**
  (antes não ia). Também **ignora** mais rótulos de cadastro que vinham como peça: **placa, veículo,
  chassi, cidade, quantidade, descrição, desconto, subtotal** — e o **nome do cliente** quando vem logo
  após um rótulo "Cliente/Nome". (Correção: o odômetro salvava errado ao re-editar por causa do ponto de
  milhar.)

- **2026-08-16 — v0.15.0.** **Logo, preço nas peças e OCR mais útil.** (1) O **logo** do app aparece ao
  lado de "CarLog" na tela inicial. (2) Agora dá para **tocar numa peça** (na edição da revisão) para
  editar o nome ou **pôr/alterar o preço** — inclusive nas peças sugeridas e nas que já estavam salvas.
  (3) O **leitor de foto** passou a **ignorar números/preços soltos** (não amarra preço à peça — isso
  você põe tocando na peça), mas **preserva especificações** como "15W40". (4) O leitor também **puxa a
  quilometragem** do orçamento (número perto de "km"/"quilometragem") direto para o **campo de odômetro**.

- **2026-08-16 — v0.14.0.** **Revisões melhores + OCR mais esperto + botões legíveis no bege.**
  (1) Na aba **Histórico**, a caixa de cada revisão mostra só algumas peças + um **"+N"** (não cresce
  mais); ao **buscar** na lupa, a peça que casa aparece na frente e fica **destacada** — e a busca passou
  a ignorar acento/maiúsculas. (2) Ao editar uma revisão: campo **Observações** (abaixo do orçamento),
  botão **Limpar** todas as peças, e um **campo de preço** ao adicionar cada peça. (3) O **leitor de foto**
  agora **descarta** linhas de dado pessoal (nome, endereço, CEP, CPF/CNPJ, telefone, e-mail). (4) No tema
  **bege**, os **botões redondos** (média, calibragem, etc.) agora usam tom escuro para dar contraste.

- **2026-08-16 — v0.13.3.** **Mais contraste no tema bege.** Os **ícones** coloridos (calendário da
  média, tanque do abastecimento, ícones de revisão/FIPE/lembrete, "feito" verde, etc.) e alguns textos
  que ainda ficavam apagados no fundo claro agora escurecem para dar contraste — completa o ajuste da
  v0.13.2. Botões redondos e temas escuros seguem intactos.

- **2026-08-16 — v0.13.2.** **Legibilidade no tema Madeira (bege) + calibragem menor.** (1) Caixa da
  **calibragem recomendada** ficou mais baixa (fonte e espaçamento reduzidos). (2) No tema bege, os
  números coloridos (verde da média, teal da calibragem, roxo da FIPE, etc.) agora **escurecem** para dar
  contraste — antes sumiam no fundo claro. (3) Ainda no bege, a **caixa do carro principal** teve as cores
  invertidas: fundo bege mais escuro e os quadrinhos de info (odômetro, FIPE, previsão…) em bege claro.

- **2026-08-15 — v0.13.1.** **Correção:** os **botões redondos** ("O que você quer registrar?") sumiam
  na tela inicial quando havia carro cadastrado — um erro de layout na faixa de "outros carros" derrubava
  o conteúdo abaixo. Voltaram ao normal (Abastecimento, Consumo, Revisões, FIPE, Calibragem, Lembretes).

- **2026-08-15 — v0.13.0.** **Temas, tamanho de fonte e idiomas.** (1) 4 **temas** (Âmbar, Azul, Expresso,
  Madeira) e **4 tamanhos de fonte** nas Configurações → Aparência. (2) **Inglês e Espanhol** (Config →
  Idioma). (3) Home: os **outros carros** viraram cartões meia-largura abaixo do principal; o carro
  principal mostra **marca em cima e modelo embaixo** (lê o modelo completo); revisão vencida vira um
  **⚠ centralizado**. (4) Revisões: mais itens sugeridos (geometria, balanceamento, cambagem, bieleta,
  bucha, polia, rolamento diant./tras.); em Programar, "a cada km" vem antes de "fazer no km". (5)
  Orçamento: botão **Limpar** e uma **lupa** para achar itens importados por foto. (6) Ajustes finos de
  layout (caixa de calibragem menor, fonte da média geral).

- **2026-08-14 — v0.12.0.** **Até 3 carros!** Na tela inicial, os chips no topo trocam de carro; toque em
  **"+ Carro"** para adicionar. Cada carro tem os **seus** abastecimentos, revisões, lembretes,
  calibragem e estatísticas (odômetro, km/mês, FIPE, previsão) — o carro selecionado é o que aparece.
  Dá para **excluir** um carro no "Meu carro". (Seus dados atuais viram o 1º carro automaticamente.)

- **2026-08-14 — v0.11.0.** (1) Quando a revisão passou da data, o título vira **"Sua revisão pode estar
  vencida"** e o rótulo da data **"estava prevista"**. (2) A **calibragem recomendada** agora é definida
  **na tela de Calibragem** (saiu do cadastro do carro), com botões **− / +** para ajustar a pressão dos
  pneus dianteiros/traseiros. *(Multi-carro — até 3 — vem na próxima.)*

- **2026-08-14 — v0.10.2.** **Previsão de data da revisão refinada** (a seu pedido): a data = **data da
  última revisão + o tempo para rodar um intervalo** no seu **ritmo médio dos últimos 12 meses** (assim
  não erra quando o odômetro está desatualizado). O card mostra **Alvo (km) + Previsão (data) + média/mês**.

- **2026-08-14 — v0.10.1.** (1) **Excluir abastecimento e revisão** por botão (lixeira) na tela de
  edição — além do arrastar. (2) No abastecimento, **todos os campos são opcionais** (odômetro, litros,
  preço). (3) **Data da próxima revisão corrigida**: o **alvo em km** continua sendo a última revisão +
  o intervalo do **cadastro** (fixo); o que melhorou foi a **previsão de data**, agora calculada pelo km
  dos **últimos 12 meses juntando abastecimentos E revisões** (antes usava janela curta e só
  abastecimentos).
- **2026-08-14 — v0.9.0.** (1) No histórico de abastecimento, o **nome do posto** aparece pequeno
  **acima do valor**. (2) Ao lançar abastecimento, o app **sugere os postos** que você já usou; (3) em
  revisões, **sugere a oficina** já usada; (4) no registro de revisão, **sugestões de peças** (como no
  Programar). (5) A **"próxima revisão"** (e a média de 12 meses) foi para a aba **Programar**.
- **2026-08-14 — v0.8.1.** Lista de itens para programar melhorada (**amortecedores dianteiros/
  traseiros**, **lâmpadas**, **filtro pressurizado**). Na tela inicial, os cartões agora são
  **clicáveis**: **Calibragem** abre a tela de calibragem e **Prev. revisão** abre a aba **Programar**
  (os outros também levam à tela relacionada).
- **2026-08-14 — v0.8.0.** (1) No **abastecimento**, escolha **“informar preço/litro”** (calcula o
  total) ou **“informar valor total”** (calcula o preço/litro). (2) Na **próxima revisão**, aparece a
  **média de km/mês dos últimos 12 meses**. (3) Botão do cadastro renomeado para **“Pesquisar carro”**.
  (4) Removido o desenho do carro da tela inicial.
- **2026-08-14 — v0.7.0.** (1) **Ler foto do orçamento (OCR)** — em *Revisões → Registrar → “Ler foto”*,
  fotografe (ou escolha da galeria) e o app **transcreve**, separa **item × valor** e preenche os itens
  + total (grátis, offline, no aparelho). (2) **Cadastro do carro só pela FIPE**, com **busca (lupa)**
  em marca/modelo/ano — sem rolar listas gigantes. (3) **Tela inicial** sem informação repetida: agora
  mostra **odômetro, km no mês, combustível no mês, FIPE, última calibragem e previsão de revisão**.
  (4) **Logo maior** no ícone.
- **2026-08-13 — v0.5.0.** (1) No **Cadastrar veículo** agora tem **“Preencher pela tabela FIPE”** —
  busca marca/modelo/ano/combustível ali dentro do cadastro; (2) **logo/ícone um pouco maior**.
- **2026-08-13 — v0.4.0.** (1) **Ícone novo** (seu logo, âmbar mais forte) e o app ficou **âmbar** como
  os irmãos; (2) em **Minha FIPE**, o botão **“Usar como meu carro”** já cadastra marca/modelo/ano/
  combustível (só a placa é manual); (3) **Revisões** — aba **Programar virou a 1ª**, cada item aceita
  **km-alvo** e **frequência (a cada X km)**, com **sugestões** (digite “óleo” → “Óleo do motor”) e
  **previsão de data**; (4) a **próxima revisão** agora estima a **data provável** pelo seu ritmo de
  rodagem (km dos abastecimentos).
- **2026-08-13 — v0.3.0.** Nuvem ligada: em Configurações, **entre com Google** → seus dados
  (abastecimentos, revisões, lembretes…) passam a **sincronizar** e sobrevivem à troca de celular.
- **2026-08-13 — v0.2.1.** Notificações: em Configurações, ligue "Avisar sobre vencimentos e revisão"
  (pede permissão) → o app te avisa no dia e 3 dias antes de cada lembrete, e quando a próxima
  revisão se aproxima.
- **2026-08-13 — v0.1.0 (primeira versão).** Home com 6 atalhos redondos; Abastecimento (com total
  ao vivo e gasto do mês); Consumo/Média automática (km/L) + calculadora cidade/rodovia + km do mês;
  Revisões (histórico buscável pela lupa + lista "a programar" + estimativa da próxima); Minha FIPE
  (consulta por marca/modelo/ano ou valor manual); Calibragem (pressão recomendada + registro);
  Lembretes (IPVA/seguro/etc. com "faltam X dias"). Tudo salvo no aparelho.
