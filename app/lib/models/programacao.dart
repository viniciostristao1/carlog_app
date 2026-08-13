/// Um item que o usuário quer verificar/trocar na próxima revisão (aba "Programar"
/// de Revisões). Vai marcando `feito` conforme resolve; itens feitos viram
/// candidatos a virar uma entrada do Histórico.
class ItemProgramado {
  final String id;
  final DateTime criadoEm;
  final String descricao;
  final bool feito;

  const ItemProgramado({
    required this.id,
    required this.criadoEm,
    required this.descricao,
    this.feito = false,
  });

  ItemProgramado copyWith({String? descricao, bool? feito}) => ItemProgramado(
        id: id,
        criadoEm: criadoEm,
        descricao: descricao ?? this.descricao,
        feito: feito ?? this.feito,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'criadoEm': criadoEm.toIso8601String(),
        'descricao': descricao,
        'feito': feito,
      };

  factory ItemProgramado.fromJson(Map<String, dynamic> j) => ItemProgramado(
        id: j['id'] as String,
        criadoEm: DateTime.parse(j['criadoEm'] as String),
        descricao: (j['descricao'] ?? '') as String,
        feito: (j['feito'] ?? false) as bool,
      );
}
