/// Registro de uma calibragem de pneus (a data em que foi calibrado, e com qual
/// pressão). A pressão *recomendada* do veículo fica no [Veiculo]; aqui é o log
/// do que de fato foi feito e quando.
class Calibragem {
  final String id;
  final String? veiculoId;
  final DateTime data;
  final double? pressaoDianteira; // psi
  final double? pressaoTraseira; // psi
  final String observacao;

  const Calibragem({
    required this.id,
    this.veiculoId,
    required this.data,
    this.pressaoDianteira,
    this.pressaoTraseira,
    this.observacao = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'veiculoId': veiculoId,
        'data': data.toIso8601String(),
        'pressaoDianteira': pressaoDianteira,
        'pressaoTraseira': pressaoTraseira,
        'observacao': observacao,
      };

  factory Calibragem.fromJson(Map<String, dynamic> j) => Calibragem(
        id: j['id'] as String,
        veiculoId: j['veiculoId'] as String?,
        data: DateTime.parse(j['data'] as String),
        pressaoDianteira: (j['pressaoDianteira'] as num?)?.toDouble(),
        pressaoTraseira: (j['pressaoTraseira'] as num?)?.toDouble(),
        observacao: (j['observacao'] ?? '') as String,
      );
}
