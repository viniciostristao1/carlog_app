import 'package:carlog/services/ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// OCR do orçamento: descarta dado pessoal e rótulos de cadastro/tabela,
/// ignora número/preço solto, extrai quilometragem e total, e preserva
/// especificações de peça (ex.: "15W40").
void main() {
  test('caso real: rótulos, nome do cliente, km com texto no meio', () {
    const texto = '''
Auto Center do João
Cliente
Maria Silva Souza
Endereço: Rua das Flores, 123
CEP 01234-567
CPF 123.456.789-00
Tel (11) 91234-5678
maria.silva@email.com
Veículo: VW Gol
Placa: ABC1D23
Cidade: São Paulo
Chassi: 9BWZZZ377VT004251
Km/Horas: 166.710
Quantidade
Descrição
Óleo 15W40 semissintético 89,90
Filtro de óleo 35,00
Desconto 10,00
Subtotal 114,90
Total 124,90
''';
    final r = OcrService().parseTexto(texto);
    final descrs = r.itens.map((e) => e.descricao).toList();
    final low = descrs.map((d) => d.toLowerCase()).toList();
    final ctx = descrs.join(' | ');

    // Peças mantidas + especificação "15W40" preservada.
    expect(low.any((d) => d.contains('óleo')), isTrue, reason: ctx);
    expect(descrs.any((d) => d.contains('15W40')), isTrue, reason: ctx);
    expect(low.any((d) => d.contains('filtro')), isTrue, reason: ctx);

    // Quilometragem lida do "Km/Horas: 166.710".
    expect(r.km, 166710);
    // Total lido.
    expect(r.total, 124.90);

    // Nada de pessoal/rótulo/tabela vira item.
    for (final proibido in [
      'maria', 'flores', '01234', '123.456', '@',
      'placa', 'abc1d23', 'cidade', 'são paulo', 'veículo', 'gol',
      'chassi', '9bwzzz', 'km/horas', '166.710',
      'quantidade', 'descrição', 'desconto', 'subtotal', 'total',
    ]) {
      expect(low.any((d) => d.contains(proibido)), isFalse,
          reason: 'não deveria conter "$proibido" — itens: $ctx');
    }
  });

  test('km em vários formatos', () {
    expect(OcrService().parseTexto('KM 10000\n').km, 10000);
    expect(OcrService().parseTexto('10.000 km\n').km, 10000);
    expect(OcrService().parseTexto('Odômetro: 87.532\n').km, 87532);
    expect(OcrService().parseTexto('Km/Horas: 166.710\n').km, 166710);
    // "km/L" (consumo) não é odômetro.
    expect(OcrService().parseTexto('Media 12 km/L\n').km, isNull);
  });

  test('não descarta peça "chave de contato" (não confunde com contato)', () {
    final r = OcrService().parseTexto('Chave de contato 210,00\n');
    expect(r.itens.any((e) => e.descricao.toLowerCase().contains('chave')),
        isTrue);
  });
}
