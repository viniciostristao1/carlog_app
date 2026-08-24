import 'package:carlog/services/ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// LOG DE CASOS do "Ler foto" (espelha o `OCR.md`). Cada teste é um orçamento
/// real (ou destilado de um) com o que DEVE virar peça e o que NÃO deve. Quando
/// o OCR trouxer algo indevido, adicione a linha aqui + a regra em ocr_filtros.
void main() {
  test('caso 2026-08-24: orçamento Toyota — cabeçalhos, marca, cidade, CNPJ, km',
      () {
    const texto = '''
TOYOTA
Concessionária Auto Center
CNPJ 12.345.678/0001-90
12345678000190
Documento
Emissão: 24/08/2026
Data
Responsável: João Pereira
Belo Horizonte - MG
Placa: ABC1D23
Ano/Modelo
2013/2014
Combustível
Fábrica
Cor externa
Garantia
Sugestão
LEGENDA
Linha
Preço Total
KM:      120973
Serviço de alinhamento 80,00
Garantia estendida do motor 500,00
Troca de óleo do motor 189,90
Filtro de óleo 45,00
Óleo Toyota 5W30
Pastilha de freio dianteira
Total geral 815,80
''';
    final r = OcrService().parseTexto(texto);
    final descrs = r.itens.map((e) => e.descricao).toList();
    final low = descrs.map((d) => d.toLowerCase()).toList();
    final ctx = descrs.join(' | ');

    // km lido correto (o bug pegava um número pequeno).
    expect(r.km, 120973, reason: ctx);
    // total lido.
    expect(r.total, 815.80, reason: ctx);

    // Peças/serviços de verdade SOBREVIVEM (inclusive multi-palavra com termo
    // "garantia"/"serviço"/marca no meio — a regra é "TODAS as palavras rótulo").
    expect(low.any((d) => d.contains('alinhamento')), isTrue, reason: ctx);
    expect(low.any((d) => d.contains('garantia estendida')), isTrue, reason: ctx);
    expect(low.any((d) => d.contains('troca de óleo')), isTrue, reason: ctx);
    expect(low.any((d) => d.contains('filtro de óleo')), isTrue, reason: ctx);
    expect(low.any((d) => d.contains('5w30')), isTrue, reason: ctx);
    expect(low.any((d) => d.contains('pastilha')), isTrue, reason: ctx);

    // Ruído que NÃO pode virar item (lista do usuário).
    for (final proibido in [
      'toyota\b', 'concessionária', 'cnpj', '12345678', 'documento', 'emissão',
      'data', 'responsável', 'joão', 'belo horizonte', 'placa', 'abc1d23',
      'ano/modelo', '2013', 'combustível', 'fábrica', 'cor externa', 'garantia\b',
      'sugestão', 'legenda', 'linha\b', 'preço total', '120973',
    ]) {
      final termo = proibido.replaceAll(r'\b', '');
      // "garantia" sozinha é ruído, mas "garantia estendida…" é peça — então só
      // checo que não existe um item cuja descrição SEJA exatamente "garantia".
      if (proibido.endsWith(r'\b')) {
        expect(low.contains(termo), isFalse, reason: 'item == "$termo": $ctx');
      } else {
        expect(low.any((d) => d.contains(termo)), isFalse,
            reason: 'não deveria conter "$termo" — itens: $ctx');
      }
    }
  });
}
