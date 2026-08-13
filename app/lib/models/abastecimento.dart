/// Um abastecimento. O odômetro (km total do painel) é o que permite calcular a
/// média entre abastecimentos de "tanque cheio". `precoLitro` × `litros` = total.
class Abastecimento {
  final String id;
  final DateTime data;
  final double odometro; // km total no painel no momento do abastecimento
  final double litros;
  final double precoLitro;
  final bool tanqueCheio; // completou o tanque? (necessário p/ média confiável)
  final String posto;
  final String? combustivel; // rótulo livre (Gasolina comum, Etanol, ...)
  final String observacao;

  const Abastecimento({
    required this.id,
    required this.data,
    required this.odometro,
    required this.litros,
    required this.precoLitro,
    this.tanqueCheio = true,
    this.posto = '',
    this.combustivel,
    this.observacao = '',
  });

  double get total => litros * precoLitro;

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
        odometro: (j['odometro'] as num).toDouble(),
        litros: (j['litros'] as num).toDouble(),
        precoLitro: (j['precoLitro'] as num).toDouble(),
        tanqueCheio: (j['tanqueCheio'] ?? true) as bool,
        posto: (j['posto'] ?? '') as String,
        combustivel: j['combustivel'] as String?,
        observacao: (j['observacao'] ?? '') as String,
      );
}
