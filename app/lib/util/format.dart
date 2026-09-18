import 'package:intl/intl.dart';

/// Formatação pt-BR centralizada (moeda, litros, km, datas).
final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _num1 = NumberFormat('#,##0.0', 'pt_BR');
final _num2 = NumberFormat('#,##0.00', 'pt_BR');
final _num0 = NumberFormat('#,##0', 'pt_BR');
final _dataCurta = DateFormat('dd/MM/yy', 'pt_BR');
final _horaCurta = DateFormat('HH:mm', 'pt_BR');

/// Locale das datas por extenso (`dataLonga`), atualizado pelo `main` quando o
/// idioma muda. Números/moeda/unidades seguem pt-BR (o carro é do Brasil).
String localeDatas = 'pt_BR';

String moeda(num v) => _moeda.format(v);
String reais2(num v) => 'R\$ ${_num2.format(v)}';
String litros(num v) => '${_num1.format(v)} L';
String km(num v) => '${_num0.format(v)} km';
String kmL(num v) => '${_num1.format(v)} km/L';
String n1(num v) => _num1.format(v);
String n2(num v) => _num2.format(v);
String n0(num v) => _num0.format(v);

String dataLonga(DateTime d) {
  switch (localeDatas) {
    case 'en_US':
      return DateFormat('MMM d, y', 'en_US').format(d);
    case 'es_ES':
      return DateFormat("d 'de' MMM y", 'es_ES').format(d);
    default:
      return DateFormat("d 'de' MMM. y", 'pt_BR').format(d);
  }
}

String dataCurta(DateTime d) => _dataCurta.format(d);

/// "HH:mm" (24h) — horário de um lembrete/notificação.
String horaCurta(DateTime d) => _horaCurta.format(d);

/// Horário efetivo de um lembrete: se a hora for meia-noite (dado antigo, salvo
/// antes do seletor de horário existir), assume **09:00**. Assim lembretes
/// antigos seguem notificando de manhã e a UI mostra um horário coerente.
DateTime comHoraEfetiva(DateTime v) => (v.hour == 0 && v.minute == 0)
    ? DateTime(v.year, v.month, v.day, 9)
    : v;

extension StringFallback on String {
  /// Retorna [fallback] se a string for vazia; senão a própria string.
  String ou(String fallback) => isEmpty ? fallback : this;
}

/// Primeiras [max] letras de um texto, com "…" quando corta (espaços nas pontas
/// somem). Para exibir em espaços estreitos — ex.: chips do histórico de
/// revisões, que precisam de 3 por linha.
String resumo(String s, {int max = 10}) {
  final t = s.trim();
  if (t.length <= max) return t;
  return '${t.substring(0, max).trimRight()}…';
}

/// Minúsculas sem acento — para buscas/sugestões que ignoram acento e caixa.
String semAcento(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const para = 'aaaaaeeeeiiiiooooouuuuc';
  var out = s.toLowerCase();
  for (var i = 0; i < de.length; i++) {
    out = out.replaceAll(de[i], para[i]);
  }
  return out;
}

/// Interpreta um número digitado em pt-BR: aceita vírgula OU ponto como decimal.
/// "1.234,5" → 1234.5; "10,5" → 10.5; "10.5" → 10.5; vazio → null.
double? parseNumero(String s) {
  var t = s.trim();
  if (t.isEmpty) return null;
  if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(t);
}

/// "há 3 dias", "hoje", "em 12 dias" — para lembretes e última calibragem.
String desdeAte(DateTime alvo, {DateTime? agora}) {
  final base = agora ?? DateTime.now();
  final dias = DateTime(alvo.year, alvo.month, alvo.day)
      .difference(DateTime(base.year, base.month, base.day))
      .inDays;
  if (dias == 0) return 'hoje';
  if (dias == 1) return 'amanhã';
  if (dias == -1) return 'ontem';
  if (dias > 1) return 'em $dias dias';
  return 'há ${-dias} dias';
}
