/// Um item que o usuário quer verificar/trocar (aba "Programar" de Revisões).
///
/// Pode ter uma meta em km (`kmAlvo` = odômetro em que vence) e/ou uma frequência
/// (`intervaloKm` = "a cada X km"). Com o odômetro atual, o app mostra quantos km
/// faltam e uma data provável. Ao marcar como feito, itens com frequência são
/// reagendados (kmAlvo avança um intervalo).
class ItemProgramado {
  final String id;
  final DateTime criadoEm;
  final String descricao;
  final bool feito;
  final double? kmAlvo; // odômetro em que o item vence
  final int? intervaloKm; // "a cada X km"

  const ItemProgramado({
    required this.id,
    required this.criadoEm,
    required this.descricao,
    this.feito = false,
    this.kmAlvo,
    this.intervaloKm,
  });

  ItemProgramado copyWith({
    String? descricao,
    bool? feito,
    double? kmAlvo,
    int? intervaloKm,
    bool limparKmAlvo = false,
    bool limparIntervalo = false,
  }) =>
      ItemProgramado(
        id: id,
        criadoEm: criadoEm,
        descricao: descricao ?? this.descricao,
        feito: feito ?? this.feito,
        kmAlvo: limparKmAlvo ? null : (kmAlvo ?? this.kmAlvo),
        intervaloKm: limparIntervalo ? null : (intervaloKm ?? this.intervaloKm),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'criadoEm': criadoEm.toIso8601String(),
        'descricao': descricao,
        'feito': feito,
        'kmAlvo': kmAlvo,
        'intervaloKm': intervaloKm,
      };

  factory ItemProgramado.fromJson(Map<String, dynamic> j) => ItemProgramado(
        id: j['id'] as String,
        criadoEm: DateTime.parse(j['criadoEm'] as String),
        descricao: (j['descricao'] ?? '') as String,
        feito: (j['feito'] ?? false) as bool,
        kmAlvo: (j['kmAlvo'] as num?)?.toDouble(),
        intervaloKm: (j['intervaloKm'] as num?)?.toInt(),
      );
}
