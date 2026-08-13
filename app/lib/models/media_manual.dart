/// Cálculo de média avulso (o "coloque km e litros e eu calculo"), com um tipo
/// de trecho para o usuário comparar cidade × rodovia. Independente do histórico
/// de abastecimentos — serve para uma medição pontual.
enum TipoTrecho { cidade, rodovia, misto }

extension TipoTrechoX on TipoTrecho {
  String get rotulo => switch (this) {
        TipoTrecho.cidade => 'Cidade',
        TipoTrecho.rodovia => 'Rodovia',
        TipoTrecho.misto => 'Misto',
      };
}

class MediaManual {
  final String id;
  final DateTime data;
  final double km; // distância percorrida no trecho
  final double litros; // litros consumidos no trecho
  final TipoTrecho tipo;
  final String observacao;

  const MediaManual({
    required this.id,
    required this.data,
    required this.km,
    required this.litros,
    this.tipo = TipoTrecho.misto,
    this.observacao = '',
  });

  double get kmPorLitro => litros > 0 ? km / litros : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.toIso8601String(),
        'km': km,
        'litros': litros,
        'tipo': tipo.name,
        'observacao': observacao,
      };

  factory MediaManual.fromJson(Map<String, dynamic> j) => MediaManual(
        id: j['id'] as String,
        data: DateTime.parse(j['data'] as String),
        km: (j['km'] as num).toDouble(),
        litros: (j['litros'] as num).toDouble(),
        tipo: TipoTrecho.values.firstWhere(
          (t) => t.name == j['tipo'],
          orElse: () => TipoTrecho.misto,
        ),
        observacao: (j['observacao'] ?? '') as String,
      );
}
