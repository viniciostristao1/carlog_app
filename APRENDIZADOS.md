# CarLog — APRENDIZADOS (diário técnico + gotchas)

Topo = mais recente. Registrar aqui toda decisão técnica, gotcha e o "porquê".

## 2026-09-19 — Novo ícone do launcher: hexágono (v0.43.0)

- **Arte:** `file_00000000acb0820e81c5c909b92a0586.png` (hexágono azul/âmbar com carro, chave, pneu, checklist e bomba) virou o ícone do app. Default `ORIGEM` do `tools/gerar_icone.py` atualizado; o **logo de dentro** (carro neon, `file_00000000b310…png`) não mudou — `carlog_logo.png` saiu idêntico.
- **Processo:** `_quadrado_autocrop` (limiar 40, margem 24) cortou de 1254→1173 de largura (glow lateral) e padronizou no fundo do canto (`#00061F`); gerou `carlog_icon.png`/`carlog_fg.png` (1024). Depois `cd app && dart run flutter_launcher_icons` reescreveu os mipmaps + `drawable-*/ic_launcher_foreground.png`. Não existe `ic_launcher_round`; o manifest usa só `@mipmap/ic_launcher` (+ adaptive `mipmap-anydpi-v26`).
- **Play Store:** `store/icon_512.png` regerado do `carlog_icon.png` (Pillow, LANCZOS 512) para a ficha bater com o ícone do app.
- **Observação:** `adaptive_icon_background` segue `#000000` — a arte antiga também tinha fundo navy e o foreground opaco cobre a camada de fundo; sem regressão visual.

## 2026-09-18 — Programar: check só marca + lembrete-previsão ligado (v0.42.0)

- **Check (`_alternarFeito`):** removido o "fiz agora → reagenda" (`base + intervalo` a cada toque, que nunca marcava feito — o km subia 10.000 por clique). Agora só `copyWith(feito: !feito)` para todo item; o alvo/intervalo fica como o usuário digitou. Sem snackbar (o check verde já dá o feedback).
- **Lembrete-previsão:** `Lembrete.programacaoId` (novo, opcional; `copyWith` preserva) liga o lembrete ao item da Programar. `_sincronizarLembrete()` (topo de `revisoes_screen.dart`) cria/atualiza ao salvar — **novo e edição** (antes só no novo, por isso "não aparecia" ao editar) —, remove quando o item perde km/intervalo ou o switch "Criar lembrete" desliga, e `_excluirItem()` remove junto. Se a data muda, volta `pago: false` (nova ocorrência).
- **Data prevista:** `previsaoLembreteProgramado()` (`util/consumo.dart`, 4 testes): alvo = `kmAlvo` ou `odo + intervaloKm` (só intervalo deixou de cair no prazo fixo de meses); converte em data pelo ritmo de rodagem; alvo já vencido → hoje às 9h (alerta na hora); sem leitura de km → meses do cadastro.
- **Histórico:** o `local` na linha do título agora usa separador ` • ` (ex.: "Revisão • Oficina").

## 2026-09-18 — Ajustes no card do histórico (v0.41.0)

- **Oficina na linha do título:** o `Expanded` do título virou `Text.rich` — `TextSpan` do `local` com o estilo que ele já tinha na linha de baixo (12.5/dim/w400), separado por dois espaços. Saiu do join `data · km` (a linha de baixo ficou só com data e odômetro); o custo continua à direita. `maxLines: 1` + ellipsis no conjunto.
- **"+N" centralizado:** `_ItemChip` ganhou `textAlign: contador ? TextAlign.center : null`. Como todo chip é filho de `Expanded`, o `Container`/`Text` recebem largura fixa e o `TextAlign.center` centraliza de fato.

## 2026-09-18 — Histórico: 8 itens em grade de 3 (v0.40.0)

- **`_CartaoRevisao` (`revisoes_screen.dart`):** `_maxItens = 8` + `_porLinha = 3`; o `Wrap` saiu (quebrava conforme o tamanho do texto) e entrou `_gradeItens()` — `Row`s de 3 `Expanded` (slot vazio = `SizedBox.shrink`), garantindo 3 colunas e no máximo 3 linhas. Com mais de 8 itens, o 9º chip é o "+N" (`t.maisItens`).
- **`_ItemChip`:** chip extraído (1/3 da linha, `maxLines: 1` + `ellipsis`). Fora da busca o texto passa por `resumo()` (10 primeiras letras + "…"); durante a busca fica inteiro — senão o destaque do match não apareceria.
- **`util/format.dart`:** novo `resumo(s, {max = 10})` (trim + corte com "…", sem sobrar espaço antes) com `test/format_test.dart` (4 casos).

## 2026-09-18 — Revisão × reparo no cálculo da próxima (v0.39.0)

- **Modelo:** `Revisao.ehRevisao` — default `true` e, no `fromJson`, `(j['ehRevisao'] as bool?) ?? true`: registros antigos (sem o campo) seguem contando como revisão; o usuário desmarca o que for reparo. `toJson` grava o campo.
- **Lógica (`util/consumo.dart`):** `preverRevisao` filtra `revisoes.where((r) => r.ehRevisao)` em `revsBase`, usado tanto no **alvo** (última revisão + intervalo do cadastro) quanto na **data** (base da última revisão + ritmo). As leituras de odômetro dos reparos continuam em `_leituras` (km atual e ritmo) — reparo informa o km do carro, mas não antecipa a revisão. Só reparos → `baseOdo = odoAtual`, `data == null` (card cai no "faltam X km").
- **Form (`revisao_form_screen.dart`):** `_ehRevisao` (novo = `true`; edição = valor salvo) + `_marcadorRevisao()` nas `actions` da AppBar (Checkbox + label "Revisão" + tooltip), **no lugar** do título fixo ("Revisão"/"Nova revisão") que foi removido a pedido. Checkbox e label com gestos separados (evita duplo toggle do `InkWell` em volta do `Checkbox`); o valor entra no `Revisao(...)` ao salvar.
- **Histórico:** fallback do card sem título agora é `t.revisao`/`t.reparo` conforme a flag.
- **Testes:** 2 casos novos no grupo `preverRevisao` (`consumo_test.dart`): reparo não entra no alvo/data; só reparos → alvo = km atual + intervalo e sem data. Novo `test/revisao_test.dart`: default `true`, roundtrip `toJson/fromJson` e legado sem o campo = revisão.

## 2026-09-13 — Painel com data + data do serviço no OCR (v0.38.0)

- **`TopoPainel` (Painel digital):** o item de revisão passou a mostrar `dataCurta(prev.data)` (e `t.vencida` quando atrasada); o "faltam X km" ficou só no `TopoProgresso` (modo com a barra).
- **OCR de data do serviço:** novo `services/ocr/ocr_data.dart` (`dataDoServico`) — pega datas `dd/MM/aa` aceitando `/`, `-` ou `.` e ano de 2–4 dígitos; valida dia/mês (rejeita 31/02), descarta futuras (+1 dia de tolerância) e antigas (>3 anos) e escolhe a **mais recente**. `OcrResultado` ganhou `dataServico` como parâmetro **nomeado** (não quebra chamadas) e o engine preenche a partir do texto completo. O form de revisão aplica apenas quando `_data` ainda é HOJE — edição de revisão antiga preserva a data. Novo teste `test/ocr_data_test.dart` (7 casos) + log em `OCR.md`.

## 2026-09-13 — Logo interno (carro neon) + Valor total padrão (v0.37.0)

- **Logo de DENTRO do app ≠ ícone do launcher:** `tools/gerar_icone.py` agora aceita duas artes — `ORIGEM` (ícone/launcher: carro+velocímetro+atalhos) e `LOGO_ORIGEM` (logo do AppBar/Sobre: só o carro). As duas usam o mesmo `_quadrado_autocrop`. O resize do `carlog_fg.png` voltou a ser em **uma etapa** a partir do quadrado natural (duas etapas mudava o fg e sujaria os mipmaps do launcher sem necessidade). Só `carlog_logo.png` muda; ícone/fg/mipmaps intactos.
- **Abastecimento:** `_modoTotal = o == null` no `initState` — novo abre em **Valor total**; edição abre em Preço/Litro (evita derivar `total/litros` e arredondar o preço salvo).

## 2026-09-13 — Abastecimento: sem "Repetir último" + odômetro por ritmo (v0.36.0)

- **"Repetir último" removido** do form de abastecimento: chips (`_chipRepetirUltimo`/`_chipDesfazerRepetir`), métodos (`_ultimo/_aplicarUltimo/_desfazerUltimo`), estado (`_ocultarRepetir`, `_mostrarDesfazerRepetir`) e os `_backup*` correspondentes. O **Desfazer do odômetro** ficou; o "Repetir última" da revisão continua (não foi pedido).
- **`sugestaoOdometro` (`util/consumo.dart`) agora exige ≥2 leituras** (abastecimentos+revisões) para calcular o ritmo e projeta `último + km/dia × max(1, dias)`. Antes, sem ritmo ou com leitura de hoje, devolvia o próprio último km (parecia "repetir"). 4 casos novos em `consumo_test.dart` (1 leitura → null; ritmo × dias; hoje → 1 dia; revisão como base).
- **UI do valor:** chips do modo invertidos — "Valor total" à esquerda e "Preço/Litro" à direita, sem "Informar" (`informarPrecoLitro`/`informarValorTotal` encurtados). `enchiTanqueSub` removida (o SwitchListTile ficou só com o título).

## 2026-09-13 — Revisões sem kits + peças de direção/embreagem (v0.35.0)

- Removidos `KitSugerido`/`kitsRevisao` (`itens_sugeridos.dart`) e a fileira de chips de kits em `revisao_form_screen.dart` (método `_aplicarKit` também saiu). O chip **Repetir última** e o **Desfazer** continuam funcionando — usam `_ultimosAutoItens`, que NÃO era exclusivo dos kits (por isso o `_desfazerAutoItens` ficou).
- `itensSugeridos` ganhou 7 itens com intervalo 0 (= sem auto-preenchimento de km): articulação da direção, barra axial, bucha da barra estabilizadora, ponteira de direção, rolamento de embreagem, disco de embreagem e platô de embreagem. Teste novo `test/itens_sugeridos_test.dart` cobre a busca por "ponteira", "barra axial", "bucha" e "embreagem".

## 2026-09-13 — Logo neon azul + combustível no ano (v0.34.0)

- **Ícone/logo novo:** `tools/gerar_icone.py` foi adaptado para a arte atual (neon claro sobre preto): o autocrop agora pega o bbox do conteúdo **claro** (`gray > 40`, antes era escuro `< 100` no fundo âmbar) e o realce virou só `Contrast(1.04)` — o `Color/Brightness` era para o âmbar. Gera `carlog_icon.png`/`carlog_fg.png`/`carlog_logo.png`; depois `cd app && dart run flutter_launcher_icons` (mipmaps + adaptive com fundo `#000000`).
- **Layout:** o combustível saiu do `infoExtra` e entrou na linha da marca junto do ano (`'${ano} · ${rotuloCombustivel}'`); a linha de baixo agora só mostra o apelido (se houver).

## 2026-09-12 — Ano na linha da marca (v0.33.0)

- **Cabeçalho do cartão:** a linha 1 virou `Row(crossAxisAlignment: baseline, [Expanded(marca), ano])` — marca à esquerda e ano à direita, antes da placa (que fica no canto). O `infoExtra` perdeu o ano (agora só apelido + combustível). No fallback sem marca/modelo, o ano também aparece na mesma linha do título.

## 2026-09-12 — Editar pelo nome do carro (v0.32.0)

- **Lápis removido** do cabeçalho do cartão do veículo (`home_screen.dart`): a coluna de identificação (marca/modelo/info) virou um `InkWell` que chama `onEditar`, liberando ~48 px para o nome (que era cortado com frequência). Acessibilidade via `Semantics(button: true, label: t.editar)`.

## 2026-09-12 — Placa Mercosul compacta + cantos de cima (v0.31.0)

- **Largura:** `PlacaMercosul` deixou a proporção real 400×130 e usa `largura = altura * 2.45` (default `altura = 36` → ~88 px, antes ~117 px), para não empurrar o nome do carro no cabeçalho.
- **Cantos de cima:** a faixa azul ganhou `BorderRadius.vertical(top: raio − borda)` próprio. Motivo: só o clip do `Container` externo deixava o canto interno "quase reto" (o canto do filho fica dentro do raio externo quando `borda < 0,293·raio`), então a curva não aparecia. Com o raio explícito na faixa, fica igual ao canto de baixo.

## 2026-09-12 — Placa Mercosul no cartão do veículo (v0.30.0)

- **`widgets/placa_mercosul.dart`**: placa desenhada em Flutter (sem asset): fundo claro com borda proporcional, faixa azul com `_LogoMercosul` (CustomPainter de 4 arcos em cata-vento), "BRASIL" e `_BandeiraBrasil` (verde + losango amarelo + círculo azul); código em `FittedBox`. Proporção real 400×130; `altura` parametrizável (default 38) — a largura sai daí.
- Cores da placa/bandeira foram para a seção "placa Mercosul" do `AppColors` (`placaAzul/placaBranco/placaPreto/bandeira*`), seguindo a regra de não usar `Color(0x…)` solto.
- `home_screen.dart` trocou o `_PlacaChip` por `PlacaMercosul`; a variável `corTile` deixou de existir (o chip antigo era o último uso dela).
- Preview: golden temporário com o widget real (tema escuro, claro e zoom) → `adm-projetos-design/carlog-placa-mercosul.html`; teste removido depois.

## 2026-09-12 — Modo do topo virou botão único na AppBar (v0.29.0)

- **`TopoModoBotao`** substitui o `TopoModoSeletor` de 3 segmentos: sai de dentro do cartão (a home não mostra mais a linha "MODO DE EXIBIÇÃO") e entra nas `actions` da AppBar, **antes da engrenagem**, e só aparece quando há veículo selecionado.
- Alterna com `ModoTopo.values[(atual.index + 1) % values.length]`; o botão mostra o ícone do modo ATUAL (accent) e o tooltip "Modo de exibição: X". `AnimatedSwitcher` suaviza a troca do ícone.

## 2026-09-12 — Topo da home com 3 modos + seletor (v0.28.0)

- **Preferência:** `ModoTopo { painel, grade, progresso }` + `modoTopoProvider` em `services/prefs.dart` (chave `modoTopo_v1`, padrão `painel`), mesma mecânica de Tema/Fonte (`AsyncNotifier` + SharedPreferences). Não sincroniza (é por aparelho).
- **Lógica pura:** `util/consumo.dart` ganhou `ProgressoRevisao`/`progressoRevisao()` **com teste** em `consumo_test.dart` (3 casos: metade do intervalo, passou do alvo → fração 1, sem intervalo/leitura → vazio). Base = `alvoKm − revisaoIntervaloKm`; `atualKm = alvoKm − faltamKm` (mesmas leituras de abastecimentos+revisões do `preverRevisao`).
- **UI:** `features/home/topo_veiculo.dart` — `TopoModoSeletor` (3 segmentos com ícone; ativo no accent) + `TopoPainel`/`TopoGrade`/`TopoProgresso` (ConsumerWidget, recebem `DadosTopo` com valores já formatados e callbacks de navegação). `home_screen.dart` só monta `DadosTopo` e escolhe no `switch (modo)`; o antigo `_Stat/_StatTile` foi removido.
- **Preview/golden temporário:** renderiza os widgets REAIS + `SharedPreferences.setMockInitialValues({'modoTopo_v1': …, 'idioma_v1': 'pt'})` e `initializeDateFormatting('pt_BR')` (sem isso o `DateFormat` lança `LocaleDataException` mesmo com as strings em pt). Teste removido do repo (paths absolutos de fonte quebrariam o CI); página: `adm-projetos-design/carlog-topo-modos.html`.

## 2026-09-12 — Botões da home com fill degradê (v0.27.0)

- **`BotaoRedondo` fill:** o círculo trocou `color: cor.withValues(alpha: 0.14)` + `Border` (tonal/outline) por `LinearGradient(topLeft→bottomRight, [cor, escura])` e `Icon(Colors.white)`, onde `escura = HSLColor.fromColor(cor).withLightness(lightness * 0.72)`. Funciona nos 5 temas sem tocar nas categorias: a home já passa `AppColors.leg(cat)`, então no tema claro (Madeira) o degradê parte do tom já escurecido.
- **Renders de aprovação:** as 6 opções foram geradas por um golden test **temporário** (`flutter test --update-goldens`) no tamanho 390×800@2.5×, carregando `MaterialIcons` + `Roboto` do cache do Flutter via `FontLoader` e ligando `debugDisableShadows = false` apenas durante a captura (restaurar antes do fim do teste — o framework valida a var em `debugAssertAllPaintingVarsUnset`). O teste foi removido do repo de propósito: usa **path absoluto** das fontes e quebraria no CI/auditoria. Página com as imagens: `adm-projetos-design/carlog-botoes-fill.html`.
- **Verificação:** `flutter analyze lib/` limpo e `flutter test` verde (7 testes).

## 2026-08-28 — Desfazer após aplicar sugestão (v0.25.0)

- **Desfazer (voltar):** `AbastecimentoForm` e `RevisaoForm` ganharam estado de backup (`_backupOdo/_backupLitros...` e `_ultimosAutoItens`) e chips `Desfazer (↩)` após aplicar `Sugerido`/`Repetir`/`Kits`. `Sugerido` → `onPressed` salva backup, preenche e mostra `Desfazer`; `Repetir`/`Kits` → guardam lista adicionada e `local` anterior para remover no desfazer. Mantém `X` para dispensar antes.

## 2026-08-28 — Dispensar sugestões com X (v0.24.0)

- **X para dispensar:** `AbastecimentoForm` e `RevisaoForm` ganharam `bool _ocultarSugestaoOdo/_ocultarRepetir` e `InputChip(deleteIcon: close, onDeleted: setState ocultar)` no lugar de `ActionChip`. ` _sugestaoOdo()` e `_ultimo()/_ultimaRevisao()` retornam `null` se ocultado. Chip continua sumindo sozinho quando campo preenchido (`_odometro`/`_litros`/`_posto`).

## 2026-08-28 — Lembrete auto ao programar (v0.23.0)

- **Auto-lembrete:** `_ItemSheet` ganha `SwitchListTile _criarLembrete` (default `true`) e em `_salvar` cria `Lembrete(tipo:revisao, titulo:descricao, vencimento:previsaoData(falta, ritmo) ?? now+intervaloMeses*30, 09:00)` via `lembretesProvider`. Só para itens novos com `kmAlvo` ou `intervaloKm`. Reuso de `ultimoOdometro`/`ritmoKmPorDia`/`previsaoData` já existentes.

## 2026-08-28 — Kits de revisão + Repetir última (v0.22.0)

- **Kits + Repetir:** `kitsRevisao` (5 kits) em `itens_sugeridos.dart` + `Revisao? _ultimaRevisao()` (mais recente por `data` filtrada por veículo). UI só quando `_itens.isEmpty`: `ActionChip("Repetir última: $titulo (N)")` copia `itens` + `local` se vazio; `Wrap` de kits adiciona `kit.itens.where(not in _itens)`. Fica acima do campo de peça, sem poluir quando já tem itens.

## 2026-08-28 — Abastecimento 1-toque (v0.21.0)

- **Repetir último abastecimento:** `_ultimo()` pega o mais recente por `data`, `_chipRepetirUltimo` mostra `ActionChip` com `litros · preço · posto` quando `original==null` e campos vazios. `_aplicarUltimo` preenche `litros/preco/posto/tanqueCheio`. Evita redigitar posto/litros padrão. GPS de posto próximo fica para fase futura (requer permissão + `geolocator`).

## 2026-08-28 — Odômetro inteligente (v0.20.0)

- **`sugestaoOdometro(ab, revs)` em `util/consumo.dart`:** lê `_leituras(ab,revs)` (mesma base da previsão), pega o maior odômetro + sua data, calcula `kmDia` 12m (fallback todo histórico) e faz `ultimo + kmDia*dias(desde última leitura)`. Usado em `AbastecimentoForm` e `RevisaoForm`: se `_odometro.text` vazio e não é edição, mostra `ActionChip("Sugerido: ${n0} km")` que preenche o campo. Não sugere se já tem valor ou está editando revisão existente. Teste implícito via lógica já coberta por `consumo_test`/`ocr_km_test`.

## 2026-08-27 — Terracota + dropdowns em Configurações (v0.19.0)

- **Blueprint → Terracota:** `TemaApp.blueprint` renomeado para `terracota` (mesma paleta navy #0B1220 / coral #FF6B4A). `strings.nomeTema` agora devolve "Terracota". Migração: `prefs` mapeia valor legado `"blueprint"` → `"terracota"` para não perder preferência salva.
- **Configurações com seta (dropdown):** `_IdiomaCard`, `_TemaCard` e `_FonteCard` viraram `ExpansionTile` dentro de `Card` (`dividerColor: transparent`, `collapsedIconColor: dim`, `iconColor: accent`). Título = nome da seção, subtítulo = valor atual (idioma nome nativo, tema nome, fonte nome + "Vale para o app inteiro"), seta padrão do ExpansionTile para expandir. Mantém `AppColors` e troca instantânea.

## 2026-08-24 — Motor de OCR modular + filtros + badge de lembrete (v0.18.0)

- **OCR refatorado em `lib/services/ocr/`** (era um `ocr_service.dart` monolítico): `ocr_models`
  (ItemLido/OcrResultado), `ocr_filtros` (as REGRAS — o arquivo que cresce), `ocr_km` (odômetro),
  `ocr_engine` (parser puro `OcrEngine.analisar`). O `services/ocr_service.dart` virou só a **cola** do
  ML Kit e **reexporta** os modelos (`export 'ocr/ocr_models.dart'`) — assim o form e o teste antigo
  (`import '.../ocr_service.dart'`) seguem compilando sem mudança. Doc dedicada: **`OCR.md`** (motor +
  **log de casos**, linkado no INICIO). Testes novos: `ocr_km_test`, `ocr_casos_test`.
- **Filosofia do filtro = LÓGICA, não whitelist** (pedido explícito do usuário). Regra de ouro mantida e
  ampliada: uma linha só é cabeçalho quando **TODAS** as suas palavras são rótulo/marca (`rotuloBloqueado`)
  → "Serviço" cai, "Serviço de alinhamento" fica; "TOYOTA" cai, "Óleo Toyota 5W30" fica. 3 camadas em
  `ocr_filtros`: (1) `linhaEhRuido` = token estrutural/regex (e-mail, CEP, CPF, **CNPJ 14 díg** formatado
  OU corrido, **placa** ABC1234/ABC1D23, **cidade "… - UF"** por sufixo de sigla de estado, rótulos
  fortes); (2) vocabulário `_frasesRotulo` + `_marcas`; (3) rótulo-de-pessoa-sozinho pula a próxima linha.
  Termos somados nesta versão: emissao, responsavel, garantia, fabrica, cor externa, concessionaria,
  sugestao, servico(singular), legenda, data, linha, documento, ano/modelo, combustivel, preco/preco
  total, total, externa + marcas de carro.
- **Bug do km (`ocr_km.dart`):** "KM:      120973" (muitos espaços) pegava "130". Fix: numa linha com
  rótulo de km, pega o número com **mais dígitos** (odômetro tem 5–6); e o engine fica com a **maior**
  leitura do documento (`km = max`), em vez do `km ??=` (primeiro-vence) antigo. Cobertura em
  `ocr_km_test` (inclui "KM 130 ordem 120973" → 120973).
- **Badge de lembrete não lido:** `services/alertas.dart` — store LOCAL (não sincroniza; fora de
  `todosOsStores`) de chaves `"${id}@${vencimentoMillis}"` já vistas. `alertaDisparado` usa
  `comHoraEfetiva` (mesmo horário do agendador). `alertasNaoLidosProvider` conta os disparados e não
  lidos do carro selecionado → vira o `badge` do `BotaoRedondo` (Stack + Positioned, borda cor `bg`).
  **Abrir a `LembretesScreen` marca como lido** (virou `ConsumerStatefulWidget`; `addPostFrameCallback`
  → `marcarLidos`). A chave por vencimento faz um lembrete **recorrente** virar alerta novo a cada
  período. Default de recorrência no form mudou de `anual` → **`nenhuma`**.
- **Folha "O que importar":** título virou `Row` com `IconButton(arrow_back)` à esquerda que dá
  `Navigator.pop` (importa nada). String nova `t.voltar` (pt/en/es).

## 2026-08-24 — Novo logo + horário nos lembretes (v0.17.0)

- **Novo logo (carro + velocímetro + 5 ícones):** arte nova em `file_00000000c504820e9a8f80e5eafcb52c.png`
  (o usuário subiu pela web do GitHub → `git fetch` + `merge --ff-only`, não estava no disco). O
  `tools/gerar_icone.py` foi generalizado: aceita a origem por **argv** (default = a arte nova), e além do
  `carlog_icon.png`/`carlog_fg.png` passou a emitir também **`carlog_logo.png`** (256px, usado no AppBar/
  Sobre) — antes esse logo era feito à parte e ficava dessincronizado. Pipeline: âmbar amostrado agora é
  **`#E88F00`** (era `#E18700`) → atualizei `adaptive_icon_background` no `pubspec` e o `colors.xml` foi
  regenerado pelo `flutter_launcher_icons`. Rodar sempre: `tools_venv/bin/python tools/gerar_icone.py`
  **depois** `cd app && dart run flutter_launcher_icons` (regenera mipmaps/drawables — 10 PNGs no diff).
- **Horário nos lembretes:** o `vencimento` (DateTime) já carregava data+hora, mas a UI só tinha
  `showDatePicker` e o agendador **fixava 09:00** (`_as9`). Agora: `showTimePicker` no form
  (`_hora: TimeOfDay`, default 09:00), `_salvar` combina data+hora, e `notifications.dart` agenda no
  horário escolhido (`comHoraEfetiva(l.vencimento)`) em vez de `_as9`. **`_as9` segue só para a previsão
  de revisão** (que não tem hora). **Gotcha de dado legado:** lembretes salvos antes disso têm hora 00:00
  (o `showDatePicker` retornava meia-noite) → helper **`comHoraEfetiva(v)`** (`format.dart`) mapeia
  **00:00 → 09:00** para não notificar de madrugada; usado no agendador E no cartão, então o que a UI
  mostra bate com quando dispara. Efeito colateral aceito: não dá para escolher exatamente meia-noite
  (vira 09:00) — irrelevante p/ lembrete de carro. **`_proximo` (empurra recorrência) passou a preservar
  `hour`/`minute`** — antes recriava `DateTime(y, m, d)` e zerava a hora a cada pagamento. i18n:
  `t.horario` + `t.horarioEm(h)`; `horaCurta(DateTime)` = `HH:mm` em `format.dart`.

## 2026-08-22 — Tema Blueprint + backup em arquivo + OCR/previsão (v0.16.0)

- **Tema Blueprint (novo padrão):** `TemaApp.blueprint` foi **appendado no FIM** do enum de propósito —
  `AppStrings.nomeTema` mapeia por **índice**, então índices 0–3 (âmbar/azul/espresso/madeira) precisam
  ficar estáveis; novos temas entram sempre no fim (case `_ =>` no `nomeTema`). Paleta navy+coral em
  `_blueprint` (`app_colors.dart`). Default trocado p/ blueprint em 4 lugares: `prefs.dart` (`orElse`),
  `main.dart`, `config_screen.dart` (fallback do seletor) e o `_pal` inicial em `app_colors.dart`. As
  **cores por categoria seguem `const`** (não viraram theme-dependent) — evita refactor grande; a família
  atual (laranja/verde/azul/roxo/teal/vermelho) já casa com o marinho.
- **Backup export/import (Config → Backup):** plugins **`share_plus` ^12 + `file_picker` ^10**, usados
  **por BYTES** — export com `XFile.fromData(...)` (o share_plus grava o arquivo temporário sozinho via o
  path_provider **dele**, não precisei adicionar path_provider) e import com `pickFiles(withData:true)`
  lendo `files.single.bytes`. Import **MESCLA por id** (`BackupService.mesclarLista`, lógica pura +
  teste): o **LOCAL sempre vence e nunca é apagado** — só entram ids que faltam (restauro seguro, lição
  do Taskix). Pós-import: `ref.invalidate` de todos os stores → recarrega a UI e (se logado) o
  `syncProvider` empurra pra nuvem. Formato do arquivo: `{app,schema,exportadoEm,dados:{<store>:<json>}}`.
  ⚠️ **2 plugins NATIVOS novos** → o `flutter analyze` **não** valida o build Android; só um push no CI
  garante (R8 está OFF, então o risco de shrink não se aplica, mas o merge de manifest/Gradle sim).
- **OCR (item 1):** blacklist de rótulos de ordem de serviço. Regra: normaliza a linha (sem acento/caixa)
  e **descarta se TODAS as palavras** (só letras; números viram separador) pertencem a `_palavrasRotulo`
  (derivado das frases em `_frasesRotulo`); em "Rótulo: valor" só conta o **rótulo antes do `:`**. Assim
  "Descrição", "ORDEM DE SERVIÇO", "Cor: Branco", "Página 1 de 2", "HORA 14:30" caem, mas "Troca de óleo"
  e "Chave de contato" ficam. Roda **depois** do value-strip (sobre `desc`) e das checagens de total/km.
- **item 2:** `useSafeArea:true` na `showModalBottomSheet` da folha "O que importar" (subia até o notch).
- **item 4 (previsão):** sem data derivável (1 leitura / sem revisão-âncora), home e card mostram
  **`faltamKm`** ("faltam X km") em vez do odômetro-alvo cru que parecia data. Decisão do usuário.
- **item 3 (limpar tudo):** `ListaNotifier.removerVarios(ids)`; telas passam os ids do carro selecionado.

## 2026-08-16 — OCR km robusto + campo odômetro (bug do ponto de milhar) (v0.15.1)

- **km com texto entre rótulo e número:** `_kmDe` agora acha o rótulo (`\bkm\b`/quilometragem/odômetro) e
  pega o 1º número ADIANTE na linha (antes exigia número logo após). Pega "Km/Horas: 166.710" (166710).
- **Mais rótulos ignorados no OCR:** placa, chassi, renavam, veículo, cidade, município, uf, quantidade,
  qtd(e), unitário, desconto, subtotal, descrição, orçamento, vencimento, pagamento. **NÃO** incluir
  item/marca/modelo/contato/estado (viram peça real). Nome do cliente após rótulo isolado ("Cliente" só)
  → pula a linha seguinte (`_reRotuloSozinho` + flag `pularProximo`).
- ⚠️ **GOTCHA (odômetro salvava errado):** campo de odômetro é **digitsOnly**, mas o init usava
  `n0(odometro)` = "166.710" (ponto de milhar). `parseNumero` só troca vírgula→ponto; sem vírgula,
  `double.tryParse("166.710")` = **166,71**. Ou seja, re-salvar uma revisão/abastecimento **corrompia** o
  odômetro. **Fix:** campos digitsOnly usam **dígitos puros** (`toStringAsFixed(0)`), e o OCR grava
  `km.toString()` (não `n0`). Regra: **campo digitsOnly nunca recebe número formatado com separador**.

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
