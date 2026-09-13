import 'package:carlog/services/ocr/ocr_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final agora = DateTime(2026, 9, 13);

  test('lê a data completa com rótulo', () {
    expect(
        dataDoServico('Data: 12/08/2026', agora: agora), DateTime(2026, 8, 12));
  });

  test('aceita ano de 2 dígitos e separadores - e .', () {
    expect(
        dataDoServico('Emissão 05-03-26', agora: agora), DateTime(2026, 3, 5));
    expect(dataDoServico('Serviço em 01.07.2026', agora: agora),
        DateTime(2026, 7, 1));
  });

  test('entre várias, fica com a mais recente que não é futura', () {
    const t = 'Emissão 01/02/2026\nImpressão 03/02/2026\nValidade 30/12/2027';
    expect(dataDoServico(t, agora: agora), DateTime(2026, 2, 3));
  });

  test('ignora datas futuras (ex.: validade)', () {
    expect(dataDoServico('Validade: 30/12/2027', agora: agora), isNull);
  });

  test('ignora datas antigas demais (fora dos últimos 3 anos)', () {
    expect(dataDoServico('Data 10/10/2019', agora: agora), isNull);
  });

  test('não confunde valores, km nem horas com data', () {
    expect(dataDoServico('Total R\$ 1.234.567,89', agora: agora), isNull);
    expect(dataDoServico('KM: 166.710', agora: agora), isNull);
    expect(dataDoServico('Hora 12:34', agora: agora), isNull);
  });

  test('rejeita dia/mês impossíveis', () {
    expect(dataDoServico('31/02/2026', agora: agora), isNull);
    expect(dataDoServico('45/13/2026', agora: agora), isNull);
  });
}
