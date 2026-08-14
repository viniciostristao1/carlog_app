import 'package:intl/intl.dart';

/// Formatação pt-BR centralizada (moeda, litros, km, datas).
final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _num1 = NumberFormat('#,##0.0', 'pt_BR');
final _num2 = NumberFormat('#,##0.00', 'pt_BR');
final _num0 = NumberFormat('#,##0', 'pt_BR');
final _data = DateFormat("d 'de' MMM. y", 'pt_BR');
final _dataCurta = DateFormat('dd/MM/yy', 'pt_BR');

String moeda(num v) => _moeda.format(v);
String reais2(num v) => 'R\$ ${_num2.format(v)}';
String litros(num v) => '${_num1.format(v)} L';
String km(num v) => '${_num0.format(v)} km';
String kmL(num v) => '${_num1.format(v)} km/L';
String n1(num v) => _num1.format(v);
String n2(num v) => _num2.format(v);
String n0(num v) => _num0.format(v);

String dataLonga(DateTime d) => _data.format(d);
String dataCurta(DateTime d) => _dataCurta.format(d);

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
