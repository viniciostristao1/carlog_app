/// Marca um trecho "fora da média" (ex.: um intervalo com quilometragem
/// anotada errada, sem como recuperar o valor exato). Não apaga nem altera
/// nenhum abastecimento — o trecho continua visível na lista, só deixa de
/// entrar na média geral, no melhor/pior e no total gasto.
///
/// O `id` é a chave estável do trecho (ver `idTrecho` em `util/consumo.dart`).
/// Retrocompatível: `criadoEm` ausente = agora.
class TrechoExcluido {
  final String id;
  final String? veiculoId; // a qual carro pertence (null = carro original)
  final DateTime criadoEm;

  const TrechoExcluido({
    required this.id,
    this.veiculoId,
    required this.criadoEm,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'veiculoId': veiculoId,
    'criadoEm': criadoEm.toIso8601String(),
  };

  factory TrechoExcluido.fromJson(Map<String, dynamic> j) => TrechoExcluido(
    id: j['id'] as String,
    veiculoId: j['veiculoId'] as String?,
    criadoEm:
        DateTime.tryParse((j['criadoEm'] ?? '') as String) ?? DateTime.now(),
  );
}
