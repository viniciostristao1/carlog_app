# CarLog — OCR "Ler foto" (o motor de leitura de orçamento)

> **Por que existe este doc:** o "Ler foto" é um **diferencial** do app. Ele melhora
> caso a caso. Este arquivo é o mapa do motor + o **LOG DE CASOS** (o que veio errado
> × a regra que resolveu), para retomar fácil depois de um `/clear`.

## Filosofia (a decisão de projeto)
Não dá para listar todas as **peças** que existem (universo infinito). Então fazemos o
**contrário**: descrevemos por **LÓGICA** o que **NÃO é peça** e descartamos. É *filtrar*,
não *whitelistar*. A regra de ouro que protege peça de verdade:

> Uma linha só é "cabeçalho" (descartada) quando **TODAS as suas palavras** são rótulo/
> marca. Assim **"Serviço"** cai, mas **"Serviço de alinhamento"** fica (tem palavra que
> não é rótulo). **"TOYOTA"** cai, mas **"Óleo Toyota 5W30"** fica.

## Onde fica o código (`app/lib/services/ocr/`)
| Arquivo | Papel |
|---|---|
| `ocr_models.dart` | `ItemLido`, `OcrResultado` (puros). |
| `ocr_filtros.dart` | **As regras** (o arquivo que cresce). 3 camadas — ver abaixo. |
| `ocr_km.dart` | Extração de quilometragem (odômetro). |
| `ocr_engine.dart` | `OcrEngine.analisar(texto)` — o parser puro (sem câmera). |
| `../ocr_service.dart` | Só a "cola" com câmera/ML Kit; reexporta os modelos. |

Testes: `app/test/ocr_km_test.dart`, `ocr_casos_test.dart`, `ocr_filtro_test.dart`.
Rodar: `cd app && /root/flutter/bin/flutter test test/ocr_*`.

## As 3 camadas do filtro (`ocr_filtros.dart`)
1. **`linhaEhRuido(linha)`** — a linha tem um **token estrutural** (e-mail, CEP, CPF,
   **CNPJ de 14 dígitos** formatado ou corrido, **placa** ABC1234/ABC1D23, telefone,
   **cidade "… - UF"**) ou um **rótulo forte** (cliente, endereço, veículo, chassi,
   concessionária, placa, cidade…) → descarta a **linha inteira**.
2. **`rotuloBloqueado(desc)`** — a descrição (linha já sem o valor) é cabeçalho:
   **todas** as palavras estão no vocabulário `_frasesRotulo` + `_marcas`. Em
   "rótulo: valor" só conta o que vem antes do ":" (por isso "Cor: Branco" cai).
3. **`ehRotuloPessoaSozinho(linha)`** — a linha é só "Cliente"/"Nome": o valor (o nome)
   vem na **próxima** linha → o motor pula ela também.

Km e total têm tratamento próprio no engine (não viram item):
- **km** = a **maior** leitura associada a um rótulo de km (odômetro tem 5–6 dígitos).
- **total** = o maior valor numa linha que menciona "total".

## Como melhorar quando o OCR trouxe algo errado (o fluxo)
1. Reproduza: copie o texto do orçamento (ou destile 5–10 linhas) para um teste em
   `ocr_casos_test.dart` (o que **deve** e o que **não deve** virar item).
2. Escolha a camada:
   - palavra/cabeçalho isolado (ex.: "Emissão", "Garantia") → `_frasesRotulo`.
   - marca de carro → `_marcas`.
   - forma fixa (14 dígitos, placa, "Cidade - UF") → uma **regex** em `linhaEhRuido`.
3. `flutter test test/ocr_*` verde → registre o caso no **LOG** abaixo.
4. **Prefira LÓGICA a exemplos.** Adicionar 1 cidade não escala; pegar "… - UF" sim.

## Limitações conhecidas (candidatos a melhorar)
- **Cidade sem UF** (ex.: "São Paulo" sozinho, sem "- SP") ainda passa — só pegamos
  quando vem com a sigla do estado. Ideia: pular a linha após rótulos de endereço.
- **Marca no meio de peça** ("Óleo Toyota 5W30") é mantida **de propósito** (é peça).
  Linha que é só a marca/modelo do carro ainda pode passar se tiver palavra "livre".
- OCR **não amarra preço à peça** (layouts variam) — o preço vira o total/o campo custo.

---

## LOG DE CASOS
> Formato: **data — orçamento** · o que veio errado · regra aplicada.

- **2026-08-24 — orçamento Toyota (usuário).**
  - **km errado:** o texto tinha `KM:      120973` (muitos espaços) e o motor pegou
    `130` (número pequeno solto). → `ocr_km.dart` agora pega, na linha do rótulo, o
    número com **mais dígitos**, e o engine fica com a **maior** leitura do documento.
  - **viraram item indevidamente:** Emissão, Responsável, Garantia, Fábrica, Cor externa,
    Concessionária, TOYOTA (marca), Sugestão, "Serviço", LEGENDA, Data, CNPJ (14 díg.),
    Linha, Documento, Ano/Modelo, Combustível, Placa (7 díg.), Preço Total, nome de
    cidade. → termos somados a `_frasesRotulo`/`_marcas`; CNPJ-14, placa e "Cidade - UF"
    viraram regex estrutural em `linhaEhRuido`. Coberto por `ocr_casos_test.dart`.
- **2026-08-27 — orçamento genérico (precisão de peças).**
  - **viraram item indevidamente:** "Autorizo a execução", "Serviço", "Requisição",
    "Peças", "Disp"/"Disponível", "Dt. Fab", "BRANCO" e outras cores, "Centro",
    "Centro Automotivo", nome de cliente, "N. Pré. S", "Liberada", "Data Ini. Contr",
    "Impressão" e datas de impressão, "LAJEADO" e outras cidades isoladas, "Validade",
    "Entrada", "Insc.Estad.:", "Previsão de Entrega", "Weiand" e outras oficinas,
    data isolada "27/08/2026", "Total Geral", "Próxima revisão", "Estou ciente e
    concordo...", "<<Pág", "VALOR TOTAL ESTIMADO". → expandido `_frasesRotulo` (cores,
    `autorizo/execucao/requisicao/peca/disp/dt/fab/centro/liberada/validade/entrada/
    insc/estad/previsao/geral/revisao/ciente/concordo/pag/estimado/oficina/mecanica/
    automotivo/lajeado` + variações), novos gatilhos em `linhaEhRuido`:
    `_reData` + `_ehLinhaDataOuNumerica` (data solta ou com rótulo data/impressão/
    validade/entrada/previsão), `_rePagina` (`<<Pág`/`Pág.`/`Página`), `_reAutorizoCiente`
    (`autorizo/execu/ciente/concordo`) e `_reRotuloForte` ampliado (`validad*`,
    `previs*`, `requis*`, `peca*`, `disp*`, `dispon*`, `liberad*`, `impress*`,
    `oficina*`). Filosofia mantida: só peça cai se **todas** palavras forem rótulo —
    "Entrada de ar" e "Chave de contato" seguem preservadas.
