/// Uma revisão/reparo já realizado (aba "Histórico" de Revisões). `itens` é a
/// lista de peças/serviços trocados — é o que a lupa busca. `textoBruto` guarda
/// o texto lido de uma foto de orçamento (OCR, ideia futura) para também ser
/// buscável.
class Revisao {
  final String id;
  final String? veiculoId;
  final DateTime data;
  final double? odometro;
  final String titulo; // "Revisão dos 40 mil", "Troca de correia"
  final List<String> itens; // peças/serviços trocados
  final double? custo;
  final String local; // oficina/concessionária
  final String textoBruto; // texto de OCR do orçamento (buscável)
  final String observacao; // anotações livres do usuário

  /// `true` = revisão (ex.: troca de óleo) → entra no cálculo da próxima
  /// revisão. `false` = reparo (ex.: lâmpada, geometria) → fica só no
  /// histórico; o odômetro ainda serve de leitura do km atual.
  final bool ehRevisao;

  const Revisao({
    required this.id,
    this.veiculoId,
    required this.data,
    this.odometro,
    this.titulo = '',
    this.itens = const [],
    this.custo,
    this.local = '',
    this.textoBruto = '',
    this.observacao = '',
    this.ehRevisao = true,
  });

  /// Concatena tudo que é buscável (título + itens + local + texto + obs.),
  /// em minúsculas, para a lupa.
  String get indiceBusca => [
        titulo,
        itens.join(' '),
        local,
        textoBruto,
        observacao,
      ].join(' ').toLowerCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'veiculoId': veiculoId,
        'data': data.toIso8601String(),
        'odometro': odometro,
        'titulo': titulo,
        'itens': itens,
        'custo': custo,
        'local': local,
        'textoBruto': textoBruto,
        'observacao': observacao,
        'ehRevisao': ehRevisao,
      };

  factory Revisao.fromJson(Map<String, dynamic> j) => Revisao(
        id: j['id'] as String,
        veiculoId: j['veiculoId'] as String?,
        data: DateTime.parse(j['data'] as String),
        odometro: (j['odometro'] as num?)?.toDouble(),
        titulo: (j['titulo'] ?? '') as String,
        itens: ((j['itens'] ?? const []) as List).map((e) => '$e').toList(),
        custo: (j['custo'] as num?)?.toDouble(),
        local: (j['local'] ?? '') as String,
        textoBruto: (j['textoBruto'] ?? '') as String,
        observacao: (j['observacao'] ?? '') as String,
        // Registros antigos (antes do campo) contam como revisão — mantém a
        // previsão que já existia; o usuário desmarca o que for reparo.
        ehRevisao: (j['ehRevisao'] as bool?) ?? true,
      );
}
