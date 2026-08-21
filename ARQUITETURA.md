# ARQUITETURA.md — padrões do CarLog (como fazer as coisas)

Mapa dos padrões recorrentes. Se você seguir estes moldes, não abre "lacuna" (ex.: dado que salva
local mas não sincroniza). Leia junto com [`AGENTS.md`](AGENTS.md).

## Fluxo de dados
```
UI (ConsumerWidget, features/…)  ──lê──►  Provider (services/repositories.dart)
        │                                        │
        └──escreve (salvar/remover)──►  Notifier  ──►  shared_preferences  (JSON, fonte da verdade)
                                                 │
                            sync_service.dart  ──►  Firestore users/{uid}  (1 campo String por store)
```
- **Local é a fonte da verdade** (funciona offline). A nuvem é um espelho (quando logado).
- Cada "store" é uma **lista de itens com `id`** (ou o objeto único `veiculo`), salva como **uma string
  JSON** numa chave do `shared_preferences`. Essa MESMA chave é um campo do doc `users/{uid}`.

## Persistência: os moldes prontos
- **Store lista** (abastecimentos, revisões, lembretes, …): estende `ListaNotifier<T>`
  (`services/lista_notifier.dart`) → ganha `salvar(item)` (insere/atualiza por `id`) e `remover(id)` de
  graça. Só informa a chave e `de/paraJson` + `idDe`.
- **Store objeto único** (veículo): `VeiculoNotifier` (AsyncNotifier<Veiculo?>).
- Tudo fica em `services/repositories.dart`; as chaves em `services/store_keys.dart`.

## ➕ Adicionar um STORE persistido novo (checklist COMPLETO)
Exemplo: um store de "multas". Faça TODOS os passos, senão a sincronização não cobre:
1. **Modelo** `models/multa.dart` com `id`, `toJson()`, `fromJson()` (e `copyWith` se editável).
2. **Chave** em `services/store_keys.dart`: `const chaveMultas = 'multas_v1';` e adicione a
   `todosOsStores`.
3. **Provider** em `services/repositories.dart`:
   ```dart
   final multasProvider = AsyncNotifierProvider<MultasNotifier, List<Multa>>(MultasNotifier.new);
   class MultasNotifier extends ListaNotifier<Multa> {
     @override String get chave => chaveMultas;
     @override Multa deJson(Map<String,dynamic> j) => Multa.fromJson(j);
     @override Map<String,dynamic> paraJson(Multa v) => v.toJson();
     @override String idDe(Multa v) => v.id;
   }
   ```
4. **Sync** em `services/sync_service.dart`: adicione `ref.invalidate(multasProvider);` em `_invalidar()`
   e um `ref.listen(multasProvider, (_, _) => controller.onLocalChange());` no `syncProvider`.
   *(o merge por id/LWW já é genérico via `todosOsStores` — não precisa mexer no algoritmo.)*
5. Se o dado gera **notificação** ou entra numa **estatística da home**, ligue lá também.

> Regra de versão da chave: mudou o formato do JSON de forma incompatível? Crie `_v2` e migre ao ler.

## Adicionar uma TELA/feature
- Pasta `features/<x>/`, tela `ConsumerWidget`/`ConsumerStatefulWidget`.
- Navegação a partir da home: um **botão redondo** (`_abrir(context, TelaX())` em `home_screen.dart`) ou
  um **cartão de estatística** clicável (`_Stat(..., onTap: ...)`).
- Formulários: controllers no `initState`, `parseNumero` para números pt-BR, salvar via
  `ref.read(xProvider.notifier).salvar(...)`.

## Multi-veículo (até 3) — MUITO IMPORTANTE ao mexer em qualquer store
- Veículos: `veiculosProvider` (lista, máx `maxVeiculos`) + `veiculoSelIdProvider` (id selecionado) +
  `veiculoSelecionadoProvider` (derivado). Salvar novo carro o seleciona; `remover(id)` reajusta a seleção.
- **Cada item de store tem `veiculoId`.** Ao CRIAR um item, carimbe:
  `veiculoId: original?.veiculoId ?? ref.read(veiculoSelecionadoProvider)?.id`.
- **Ao LER numa tela, use o provider FILTRADO** `xDoVeiculoProvider` (ex.: `abastecimentosDoVeiculoProvider`),
  NÃO o `xProvider` cru — senão mistura os carros. (Escrita continua via `xProvider.notifier`.)
- Itens antigos com `veiculoId == null` pertencem ao PRIMEIRO carro (o migrado). Não precisa migrar os
  stores de itens.
- Store novo (ver checklist acima): adicione `veiculoId` ao modelo + crie o `xDoVeiculoProvider` filtrado
  (`_doVeiculoSel`) e use-o nas telas.

## Contrato de sincronização (sync_service.dart)
- Escreve `users/{uid}` com `{ <chave>: <jsonString>, updatedAt }` por store.
- 1º snapshot no aparelho: **união por `id`** (não perde de nenhum lado). Depois: **última escrita
  vence**. Cache offline do Firestore reenvia sozinho. Gated por `kFirebaseConfigured`.

## Notificações (services/notifications.dart)
- `NotifScheduler` (provider `notifSchedulerProvider`, vivo no `main`) **reprograma tudo** (cancelAll +
  reschedule, debounce) quando lembretes/veículo/abastecimentos/revisões mudam. Toggle em Config
  (`notifAtivasProvider`). Fuso fixo `America/Sao_Paulo`. IDs estáveis por `hashCode`.

## FIPE (features/fipe/)
- `fipe_service.dart`: API pública parallelum (marcas→modelos→anos→valor), sem chave.
- `fipe_seletor.dart`: cascata reutilizável com **busca (lupa)** (`_BuscaSheet`); devolve `FipeSelecao`
  via `onSelecao`. `combustivelDaFipe(texto)` mapeia p/ o enum.
- `fipe_picker_screen.dart`: usa o seletor e **devolve** a seleção (para o cadastro do veículo).
- `fipe_screen.dart` ("Minha FIPE"): usa o seletor e **salva** o valor/identidade no veículo.

## OCR do orçamento (services/ocr_service.dart)
- `lerDe(ImageSource)` → `image_picker` → `TextRecognizer(latin)` → `_parse`: separa **item × valor**
  por linha (regex de valor BR) e detecta **total**. UI de revisão no form de Revisão
  (`_OcrReviewSheet`). Tudo no aparelho, offline.

## Sugestões / autocomplete (widgets/campo_sugestoes.dart)
- `CampoSugestoes(controller, label, sugestoes: List<String>, cor)` = TextField + chips filtradas por
  `semAcento` (util/format.dart); tocar preenche o campo. Fonte típica = histórico do usuário
  (postos distintos, oficinas distintas). Em Revisões, as **peças** somam o catálogo `itens_sugeridos`
  + itens já usados (tocar adiciona à lista).

## Testes
- Lógica pura em `util/` (ex.: `consumo.dart`) tem teste em `test/` (`consumo_test.dart`). Ao mexer em
  cálculo (média, previsão, parsing), **adicione/atualize o teste**. Rode `flutter test`.

## Cálculos-chave (util/consumo.dart)
- `calcularConsumo(abastecimentos)` → trechos tanque-cheio→tanque-cheio, média km/L ponderada.
- `kmRodadosNoMes` · `kmPorMesEstimado` · `ritmoKmPorDia(ab, dias:)` · `previsaoData(faltamKm, kmDia)`
  (base das previsões de revisão/itens e da "média 12 meses" = `ritmoKmPorDia(dias:365)*30`).
