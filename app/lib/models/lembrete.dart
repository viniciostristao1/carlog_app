/// Lembrete de vencimento: IPVA, seguro, licenciamento, multa, pedágio (tag),
/// estacionamento, etc. `vencimento` alimenta a contagem "faltam X dias" e (em
/// versão futura) a notificação. `recorrencia` permite empurrar a data ao pagar.
enum TipoLembrete {
  ipva,
  seguro,
  licenciamento,
  multa,
  revisao,
  pedagio,
  estacionamento,
  outro,
}

extension TipoLembreteX on TipoLembrete {
  String get rotulo => switch (this) {
        TipoLembrete.ipva => 'IPVA',
        TipoLembrete.seguro => 'Seguro',
        TipoLembrete.licenciamento => 'Licenciamento',
        TipoLembrete.multa => 'Multa',
        TipoLembrete.revisao => 'Revisão',
        TipoLembrete.pedagio => 'Pedágio',
        TipoLembrete.estacionamento => 'Estacionamento',
        TipoLembrete.outro => 'Outro',
      };
}

enum Recorrencia { nenhuma, mensal, anual }

extension RecorrenciaX on Recorrencia {
  String get rotulo => switch (this) {
        Recorrencia.nenhuma => 'Sem repetição',
        Recorrencia.mensal => 'Mensal',
        Recorrencia.anual => 'Anual',
      };
}

class Lembrete {
  final String id;
  final String? veiculoId;
  final TipoLembrete tipo;
  final String titulo;
  final DateTime vencimento;
  final double? valor;
  final Recorrencia recorrencia;
  final bool pago;
  final String observacao;

  const Lembrete({
    required this.id,
    this.veiculoId,
    required this.tipo,
    required this.titulo,
    required this.vencimento,
    this.valor,
    this.recorrencia = Recorrencia.nenhuma,
    this.pago = false,
    this.observacao = '',
  });

  Lembrete copyWith({
    TipoLembrete? tipo,
    String? titulo,
    DateTime? vencimento,
    double? valor,
    Recorrencia? recorrencia,
    bool? pago,
    String? observacao,
  }) =>
      Lembrete(
        id: id,
        veiculoId: veiculoId,
        tipo: tipo ?? this.tipo,
        titulo: titulo ?? this.titulo,
        vencimento: vencimento ?? this.vencimento,
        valor: valor ?? this.valor,
        recorrencia: recorrencia ?? this.recorrencia,
        pago: pago ?? this.pago,
        observacao: observacao ?? this.observacao,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'veiculoId': veiculoId,
        'tipo': tipo.name,
        'titulo': titulo,
        'vencimento': vencimento.toIso8601String(),
        'valor': valor,
        'recorrencia': recorrencia.name,
        'pago': pago,
        'observacao': observacao,
      };

  factory Lembrete.fromJson(Map<String, dynamic> j) => Lembrete(
        id: j['id'] as String,
        veiculoId: j['veiculoId'] as String?,
        tipo: TipoLembrete.values.firstWhere(
          (t) => t.name == j['tipo'],
          orElse: () => TipoLembrete.outro,
        ),
        titulo: (j['titulo'] ?? '') as String,
        vencimento: DateTime.parse(j['vencimento'] as String),
        valor: (j['valor'] as num?)?.toDouble(),
        recorrencia: Recorrencia.values.firstWhere(
          (r) => r.name == j['recorrencia'],
          orElse: () => Recorrencia.nenhuma,
        ),
        pago: (j['pago'] ?? false) as bool,
        observacao: (j['observacao'] ?? '') as String,
      );
}
