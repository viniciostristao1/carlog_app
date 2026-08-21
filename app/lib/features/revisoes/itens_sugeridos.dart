/// Item de manutenção comum, para autocomplete na aba "Programar". O `intervaloKm`
/// é uma sugestão GENÉRICA (varia por veículo/uso) que já vem preenchida quando o
/// usuário escolhe a sugestão — sempre editável.
class ItemSugerido {
  final String nome;
  final int intervaloKm;
  const ItemSugerido(this.nome, this.intervaloKm);
}

const itensSugeridos = <ItemSugerido>[
  ItemSugerido('Óleo do motor', 10000),
  ItemSugerido('Filtro de óleo', 10000),
  ItemSugerido('Filtro de ar', 10000),
  ItemSugerido('Filtro de combustível', 20000),
  ItemSugerido('Filtro do ar-condicionado (cabine)', 15000),
  ItemSugerido('Velas de ignição', 30000),
  ItemSugerido('Cabos de vela', 40000),
  ItemSugerido('Correia dentada', 50000),
  ItemSugerido('Correia dos acessórios (alternador)', 40000),
  ItemSugerido('Fluido de freio', 20000),
  ItemSugerido('Pastilhas de freio (dianteiras)', 30000),
  ItemSugerido('Pastilhas de freio (traseiras)', 40000),
  ItemSugerido('Discos de freio', 60000),
  ItemSugerido('Rodízio dos pneus', 10000),
  ItemSugerido('Alinhamento e balanceamento', 10000),
  ItemSugerido('Geometria (alinhamento de direção)', 10000),
  ItemSugerido('Balanceamento das rodas', 10000),
  ItemSugerido('Cambagem', 0),
  ItemSugerido('Bieleta (estabilizador)', 0),
  ItemSugerido('Bucha da suspensão', 0),
  ItemSugerido('Polia (tensor/alternador)', 0),
  ItemSugerido('Amortecedores dianteiros', 60000),
  ItemSugerido('Amortecedores traseiros', 60000),
  ItemSugerido('Bateria', 40000),
  ItemSugerido('Aditivo do radiador (arrefecimento)', 40000),
  ItemSugerido('Filtro pressurizado (combustível)', 20000),
  ItemSugerido('Lâmpada do farol', 0),
  ItemSugerido('Lâmpada da lanterna/freio', 0),
  ItemSugerido('Óleo do câmbio (manual)', 60000),
  ItemSugerido('Óleo do câmbio automático', 60000),
  ItemSugerido('Fluido da direção hidráulica', 40000),
  ItemSugerido('Palhetas do limpador', 15000),
  ItemSugerido('Sonda lambda (sensor de oxigênio)', 80000),
  ItemSugerido('Vela de aquecimento (diesel)', 60000),
  ItemSugerido('Rolamento de roda dianteira', 60000),
  ItemSugerido('Rolamento de roda traseira', 60000),
];

/// Sugestões que combinam com o texto digitado (sem acento/caixa), até [max].
List<ItemSugerido> sugestoesPara(String termo, {int max = 6}) {
  final t = _norm(termo);
  if (t.isEmpty) return const [];
  final r = itensSugeridos.where((s) => _norm(s.nome).contains(t)).toList();
  return r.length > max ? r.sublist(0, max) : r;
}

String _norm(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const para = 'aaaaaeeeeiiiiooooouuuuc';
  var out = s.toLowerCase();
  for (var i = 0; i < de.length; i++) {
    out = out.replaceAll(de[i], para[i]);
  }
  return out.trim();
}
