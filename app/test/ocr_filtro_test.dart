import 'package:carlog/services/ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// OCR do orçamento: descarta dado pessoal (item 6) e número solto/preço por
/// item (item 2), extrai a quilometragem (item 4) e o total, e preserva
/// especificações de peça (ex.: "15W40").
void main() {
  test('filtra pessoal, ignora preço por item, pega total e km', () {
    const texto = '''
Auto Center do João
Cliente: Maria Silva
Rua das Flores, 123 - Bairro Centro
CEP 01234-567
CPF 123.456.789-00
Tel (11) 91234-5678
maria.silva@email.com
Quilometragem: 45.000 km
Óleo 15W40 semissintético 89,90
Filtro de óleo 35,00
200,00
Total 244,90
''';
    final r = OcrService().parseTexto(texto);
    final descrs = r.itens.map((e) => e.descricao).toList();
    final low = descrs.map((d) => d.toLowerCase()).toList();
    final ctx = descrs.join(' | ');

    // Peças mantidas, e a especificação "15W40" preservada.
    expect(low.any((d) => d.contains('óleo')), isTrue, reason: ctx);
    expect(descrs.any((d) => d.contains('15W40')), isTrue, reason: ctx);
    expect(low.any((d) => d.contains('filtro')), isTrue, reason: ctx);

    // O OCR NÃO amarra preço a item.
    expect(r.itens.every((e) => e.valor == null), isTrue);
    // Nenhum item carrega o preço no texto.
    expect(descrs.any((d) => d.contains('89,90')), isFalse, reason: ctx);

    // Número solto e linha de total não viram item.
    expect(descrs.any((d) => d.trim() == '200,00'), isFalse, reason: ctx);
    expect(low.any((d) => d.contains('total')), isFalse, reason: ctx);

    // Dados pessoais descartados.
    expect(low.any((d) => d.contains('maria')), isFalse, reason: ctx);
    expect(descrs.any((d) => d.contains('01234')), isFalse, reason: ctx);

    // Quilometragem e total detectados.
    expect(r.km, 45000);
    expect(r.total, 244.90);
    // A linha de km não vira item.
    expect(low.any((d) => d.contains('quilometragem')), isFalse, reason: ctx);
  });

  test('km em vários formatos', () {
    expect(OcrService().parseTexto('KM 10000\n').km, 10000);
    expect(OcrService().parseTexto('10.000 km\n').km, 10000);
    expect(OcrService().parseTexto('Odômetro: 87.532\n').km, 87532);
    // "km/L" (consumo) não é odômetro.
    expect(OcrService().parseTexto('Media 12 km/L\n').km, isNull);
  });

  test('não descarta peça "chave de contato" (não confunde com contato)', () {
    final r = OcrService().parseTexto('Chave de contato 210,00\n');
    expect(r.itens.any((e) => e.descricao.toLowerCase().contains('chave')),
        isTrue);
  });
}
