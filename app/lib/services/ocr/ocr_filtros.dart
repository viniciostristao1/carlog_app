import '../../util/format.dart' show semAcento;

/// FILTROS do motor de OCR — o coração do "Ler foto". É aqui que a leitura fica
/// melhor com o tempo: em vez de listar as peças que EXISTEM (impossível), a
/// gente descreve, por LÓGICA, o que NÃO é peça e descarta. Ver `OCR.md`.
///
/// Três camadas (da mais forte para a mais fraca):
///   1) [linhaEhRuido]  — a linha tem um TOKEN estrutural (e-mail, CPF, CNPJ de
///      14 dígitos, placa, CEP, telefone, cidade "… - UF") ou um rótulo pessoal
///      forte → descarta a linha INTEIRA, tenha o que tiver.
///   2) [rotuloBloqueado] — a descrição (linha já sem o valor) é um cabeçalho:
///      **todas as suas palavras** estão no vocabulário de rótulo/ marca. Assim
///      "Serviço" cai, mas "Serviço de alinhamento" fica (tem palavra que não é
///      rótulo). É o que evita jogar fora peça de verdade.
///   3) [ehRotuloPessoaSozinho] — a linha é só "Cliente"/"Nome": o valor (o nome)
///      vem na PRÓXIMA linha → o motor pula ela também.
///
/// COMO ADICIONAR UM TERMO NOVO (quando o OCR trouxe algo que não devia):
///   • É uma palavra-cabeçalho isolada (ex.: "Emissão", "Garantia")? → some em
///     [_frasesRotulo] (uma palavra OU uma frase; a frase casa quando a linha é
///     exatamente aquelas palavras).
///   • É uma marca de carro? → [_marcas].
///   • Tem forma fixa (14 dígitos, placa, "Cidade - UF")? → uma regex em
///     [linhaEhRuido] (camada 1). Prefira LÓGICA a listar exemplos.
///   • Registre o caso no `OCR.md` (o que veio errado × regra que resolveu).

// ─────────────── camada 1: tokens estruturais / dado pessoal ───────────────

final _reEmail = RegExp(r'[\w.\-]+@[\w\-]+\.[\w.\-]+');
final _reCep = RegExp(r'\b\d{5}-\d{3}\b');
final _reCpf = RegExp(r'\b\d{3}\.\d{3}\.\d{3}-\d{2}\b');
// CNPJ formatado (00.000.000/0000-00) OU 14 dígitos corridos (pedido do usuário).
final _reCnpj = RegExp(r'\b\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}\b|(?<!\d)\d{14}(?!\d)');
final _reFone = RegExp(r'\(?\d{2}\)?\s?9?\d{4}-\d{4}');
// Placa: antiga "ABC1234"/"ABC-1234" ou Mercosul "ABC1D23" (7 caracteres).
final _rePlaca = RegExp(
  r'\b[A-Za-z]{3}[-\s]?\d{4}\b|\b[A-Za-z]{3}\d[A-Za-z]\d{2}\b',
);
// Siglas de UF — usadas para pegar "Cidade - UF" sem listar cidade nenhuma.
const _ufs = r'AC|AL|AP|AM|BA|CE|DF|ES|GO|MA|MT|MS|MG|PA|PB|PR|PE|PI|RJ|RN|RS'
    r'|RO|RR|SC|SP|SE|TO';
// Linha que TERMINA em "… - SP", "…/MG", "…, RJ" → é endereço/cidade, não peça.
final _reCidadeUf = RegExp('[-/,]\\s*(?:$_ufs)\\s*\$');

// Rótulos fortes de cabeçalho/cadastro: se aparecem em QUALQUER lugar da linha,
// a linha é cadastro (não peça). NÃO inclui palavras que também são peça
// (contato, estado, item, marca, modelo…) — essas ficam na camada 2.
final _reRotuloForte = RegExp(
  r'\b(cliente|nome|endere\w*|rua|avenida|bairro|cep|cpf|cnpj|telefone|celular'
  r'|fone|e-?mail|inscri\w*|whats\w*|raz[ãa]o\s+social|respons[áa]vel|comprador'
  r'|placa|chassi\w*|renavam|ve[íi]culo|cidade|munic[íi]pio|\buf\b|concession\w*'
  r'|quantidade|qtde?\w*|unit[áa]ri\w*|desconto|subtotal|descri[çc][ãa]o'
  r'|or[çc]amento|vencimento|pagamento)\b',
  caseSensitive: false,
);

/// A linha é dado pessoal / estrutural (descarta a linha inteira)?
bool linhaEhRuido(String linha) =>
    _reEmail.hasMatch(linha) ||
    _reCep.hasMatch(linha) ||
    _reCpf.hasMatch(linha) ||
    _reCnpj.hasMatch(linha) ||
    _reFone.hasMatch(linha) ||
    _rePlaca.hasMatch(linha) ||
    _reCidadeUf.hasMatch(linha) ||
    _reRotuloForte.hasMatch(linha);

/// Rótulo de pessoa SOZINHO ("Cliente", "Nome:") — o valor vem na linha
/// seguinte, que o motor também ignora.
final _reRotuloPessoaSozinho = RegExp(
  r'^(cliente|nome|raz[ãa]o\s+social|respons[áa]vel|comprador)\s*:?\s*$',
  caseSensitive: false,
);
bool ehRotuloPessoaSozinho(String linha) =>
    _reRotuloPessoaSozinho.hasMatch(linha);

// ─────────────── camada 2: vocabulário de rótulo (regra "todas as palavras") ──

/// Frases/palavras que, quando são a linha INTEIRA (só elas), indicam cabeçalho
/// e não peça. Uma linha cai quando TODAS as suas palavras estão aqui (ou em
/// [_marcas]) — logo "Serviço" cai e "Serviço de alinhamento" fica.
const _frasesRotulo = <String>[
  // — cabeçalho / ordem de serviço (base histórica) —
  'item', 'cliente', 'aguarda', 'cor', 'tipo de os',
  'contato para informacoes adicionais', 'csp', 'csr', 'csd', 'servicos',
  'servico', 'mao de obra', 'email', 'e mail', 'distribuidor', 'hora',
  'ordem de servico', 'consultor', 'historico', 'campanha de servico',
  'outros servicos necessarios recomendados', 'req', 'prisma',
  'nao tem historico', 'cliente retorno', 'comercial', 'revisado', 'inicio',
  'proxima', 'descricao', 'weiand', 'data', 'total estimado de servicos',
  'sim', 'entrega', 'data da venda', 'valor total estimado', 'termino',
  'nao', 'valor', 'estimada', 'pagina',
  // — acrescentados 2026-08-24 (orçamento Toyota do usuário) —
  'emissao', 'responsavel', 'garantia', 'fabrica', 'cor externa',
  'concessionaria', 'sugestao', 'legenda', 'linha', 'documento',
  'ano modelo', 'ano', 'modelo', 'combustivel', 'preco', 'preco total',
  'total', 'externa',
];

/// Marcas de carro — "TOYOTA" sozinho vira ruído; "Filtro Toyota" sobrevive
/// (tem palavra que não é marca). Some marcas aqui quando aparecerem.
const _marcas = <String>[
  'toyota', 'chevrolet', 'gm', 'volkswagen', 'vw', 'fiat', 'ford', 'honda',
  'hyundai', 'renault', 'nissan', 'jeep', 'peugeot', 'citroen', 'mitsubishi',
  'kia', 'bmw', 'mercedes', 'benz', 'audi', 'volvo', 'land', 'rover',
  'suzuki', 'subaru', 'chery', 'caoa', 'ram', 'dodge', 'mini', 'jac', 'byd',
  'gwm', 'haval', 'ltda', 'epp',
];

/// Vocabulário de rótulo: cada palavra de [_frasesRotulo] + [_marcas].
final Set<String> _palavrasRotulo = {
  for (final f in [..._frasesRotulo, ..._marcas])
    for (final w in f.split(RegExp(r'[^a-z]+')))
      if (w.isNotEmpty) w,
};

/// A descrição (linha já sem o valor no fim) é um cabeçalho a ignorar? Sim
/// quando TODAS as suas palavras são rótulo/marca. Em "rótulo: valor" só conta o
/// que vem antes do ":" (assim "Cor: Branco" cai pelo "cor").
bool rotuloBloqueado(String descricao) {
  final norm = semAcento(descricao);
  final rotulo =
      norm.contains(':') ? norm.substring(0, norm.indexOf(':')) : norm;
  final palavras = rotulo.split(RegExp(r'[^a-z]+')).where((w) => w.isNotEmpty);
  return palavras.isNotEmpty && palavras.every(_palavrasRotulo.contains);
}
