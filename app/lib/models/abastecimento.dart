/// Um abastecimento. Todos os campos numéricos são **opcionais** (o usuário pode
/// registrar só o que tem à mão e completar depois). O odômetro (km do painel) é
/// o que permite calcular média/previsão; `litros × precoLitro` = total.
class Abastecimento {
  final String id;
  final DateTime data;
  final double? odometro; // km total no painel no momento do abastecimento
  final double? litros;
  final double? precoLitro;
  final bool tanqueCheio; // completou o tanque? (necessário p/ média confiável)
  final String posto;
  final String? combustivel; // rótulo livre (Gasolina comum, Etanol, ...)
  final String observacao;

  const Abastecimento({
    required this.id,
    required this.data,
    this.odometro,
    this.litros,
    this.precoLitro,
    this.tanqueCheio = true,
    this.posto = '',
    this.combustivel,
    this.observacao = '',
  });

  /// Total gasto (0 se litros/preço não informados).
  double get total => (litros ?? 0) * (precoLitro ?? 0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.toIso8601String(),
        'odometro': odometro,
        'litros': litros,
        'precoLitro': precoLitro,
        'tanqueCheio': tanqueCheio,
        'posto': posto,
        'combustivel': combustivel,
        'observacao': observacao,
      };

  factory Abastecimento.fromJson(Map<String, dynamic> j) => Abastecimento(
        id: j['id'] as String,
        data: DateTime.parse(j['data'] as String),
        odometro: (j['odometro'] as num?)?.toDouble(),
        litros: (j['litros'] as num?)?.toDouble(),
        precoLitro: (j['precoLitro'] as num?)?.toDouble(),
        tanqueCheio: (j['tanqueCheio'] ?? true) as bool,
        posto: (j['posto'] ?? '') as String,
        combustivel: j['combustivel'] as String?,
        observacao: (j['observacao'] ?? '') as String,
      );
}
