/// Extração da DATA DO SERVIÇO de um orçamento/nota lido no OCR.
///
/// Regra: procura datas numéricas (`dd/MM/aaaa`, `dd-MM-aa` ou `dd.MM.aa`),
/// valida dia/mês/ano, **ignora datas futuras** (ex.: "Validade") e antigas
/// demais (fora dos últimos ~3 anos) e devolve a **mais recente** — em
/// orçamento/OS as datas de emissão, serviço e impressão ficam próximas do
/// reparo. Casos cobertos: ver `test/ocr_data_test.dart`.
library;

/// Data do serviço lida em [texto], ou null se não houver data plausível.
/// [agora] injetável para teste (padrão = hoje).
DateTime? dataDoServico(String texto, {DateTime? agora}) {
  final hoje = agora ?? DateTime.now();
  final limite = hoje.subtract(const Duration(days: 3 * 365));
  final re = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})');

  DateTime? melhor;
  for (final m in re.allMatches(texto)) {
    final dia = int.parse(m.group(1)!);
    final mes = int.parse(m.group(2)!);
    var ano = int.parse(m.group(3)!);
    if (ano < 100) ano += ano < 70 ? 2000 : 1900; // "26" → 2026
    if (dia < 1 || dia > 31 || mes < 1 || mes > 12) continue;
    if (ano < 1900 || ano > hoje.year + 1) continue;

    final d = DateTime(ano, mes, dia);
    if (d.day != dia || d.month != mes) continue; // ex.: 31/02 não existe
    if (d.isAfter(hoje.add(const Duration(days: 1)))) continue; // futura
    if (d.isBefore(limite)) continue; // antiga demais
    if (melhor == null || d.isAfter(melhor)) melhor = d;
  }
  return melhor;
}
