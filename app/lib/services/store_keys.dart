/// Chaves dos stores locais (shared_preferences). São TAMBÉM os campos do
/// documento `users/{uid}` no Firestore quando a nuvem está ligada (cada store =
/// um JSON string). Manter esta lista em dia = a sincronização cobre tudo.
const chaveVeiculo = 'veiculo_v1';
const chaveAbastecimentos = 'abastecimentos_v1';
const chaveMedias = 'medias_v1';
const chaveRevisoes = 'revisoes_v1';
const chaveProgramacao = 'programacao_v1';
const chaveLembretes = 'lembretes_v1';
const chaveCalibragem = 'calibragem_v1';

/// Todos os stores que a sincronização espelha na nuvem.
const todosOsStores = <String>[
  chaveVeiculo,
  chaveAbastecimentos,
  chaveMedias,
  chaveRevisoes,
  chaveProgramacao,
  chaveLembretes,
  chaveCalibragem,
];
