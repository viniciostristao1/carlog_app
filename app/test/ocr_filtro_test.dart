import 'package:carlog/services/ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Item 6: o OCR do orçamento deve DESCARTAR linhas de dado pessoal/cadastral
/// (nome, endereço, CEP, CPF/CNPJ, telefone, e-mail) e manter as peças/serviços.
void main() {
  test('filtra dados pessoais e mantém peças + total', () {
    const texto = '''
Auto Center do João
Cliente: Maria Silva
Rua das Flores, 123 - Bairro Centro
CEP 01234-567
CPF 123.456.789-00
Tel (11) 91234-5678
maria.silva@email.com
Óleo 5W30 semissintético 89,90
Filtro de óleo 35,00
Pastilha de freio dianteira 120,00
Total 244,90
''';
    final r = OcrService().parseTexto(texto);
    final descrs = r.itens.map((e) => e.descricao.toLowerCase()).toList();
    final tudo = descrs.join(' | ');

    // Peças mantidas
    expect(descrs.any((d) => d.contains('óleo')), isTrue, reason: tudo);
    expect(descrs.any((d) => d.contains('filtro')), isTrue, reason: tudo);
    expect(descrs.any((d) => d.contains('pastilha')), isTrue, reason: tudo);

    // Dados pessoais descartados
    expect(descrs.any((d) => d.contains('maria')), isFalse, reason: tudo);
    expect(descrs.any((d) => d.contains('rua')), isFalse, reason: tudo);
    expect(descrs.any((d) => d.contains('01234')), isFalse, reason: tudo);
    expect(descrs.any((d) => d.contains('123.456')), isFalse, reason: tudo);
    expect(descrs.any((d) => d.contains('@')), isFalse, reason: tudo);

    // Também some do texto salvo (buscável)
    expect(r.textoBruto.toLowerCase().contains('maria'), isFalse);
    expect(r.textoBruto.toLowerCase().contains('cep'), isFalse);

    // Total detectado
    expect(r.total, 244.90);
  });

  test('não descarta peça comum "chave de contato" (não confunde com contato)',
      () {
    final r = OcrService().parseTexto('Chave de contato 210,00\n');
    expect(r.itens.any((e) => e.descricao.toLowerCase().contains('chave')),
        isTrue);
  });
}
