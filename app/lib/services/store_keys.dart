/// Chaves dos stores locais (shared_preferences). São TAMBÉM os campos do
/// documento `users/{uid}` no Firestore quando a nuvem está ligada (cada store =
/// um JSON string; exceção: `veiculo_sel_v1` é um id simples).
const chaveVeiculo = 'veiculo_v1'; // LEGADO (carro único) — só p/ migração local
const chaveVeiculos = 'veiculos_v1'; // lista de veículos (até 3)
const chaveVeiculoSel = 'veiculo_sel_v1'; // id do carro selecionado
const chaveAbastecimentos = 'abastecimentos_v1';
const chaveMedias = 'medias_v1';
const chaveRevisoes = 'revisoes_v1';
const chaveProgramacao = 'programacao_v1';
const chaveLembretes = 'lembretes_v1';
const chaveCalibragem = 'calibragem_v1';

/// Stores que a sincronização espelha na nuvem. (O legado `veiculo_v1` NÃO entra:
/// a migração para `veiculos_v1` acontece localmente e é o `veiculos_v1` que sincroniza.)
const todosOsStores = <String>[
  chaveVeiculos,
  chaveVeiculoSel,
  chaveAbastecimentos,
  chaveMedias,
  chaveRevisoes,
  chaveProgramacao,
  chaveLembretes,
  chaveCalibragem,
];

/// Stores que são objeto/string simples (não uma lista de itens com id) — a
/// sincronização usa "manter local, senão nuvem" no 1º merge (não união por id).
const storesObjeto = <String>[chaveVeiculoSel];
