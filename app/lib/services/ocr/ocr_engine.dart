import 'ocr_filtros.dart';
import 'ocr_km.dart';
import 'ocr_models.dart';

/// Motor de leitura do orçamento: recebe o TEXTO cru do OCR e devolve o
/// [OcrResultado] (peças, total, km, texto buscável). É **puro** (sem plugin),
/// então dá para testar cada caso sem câmera — ver test/ocr_*_test.dart e
/// `OCR.md`. As regras de "o que NÃO é peça" moram em `ocr_filtros.dart`.
class OcrEngine {
  const OcrEngine._();

  // Valores tipo "1.234,56", "89,90" (vírgula decimal, ponto de milhar opcional).
  static final _reValor = RegExp(r'(\d{1,3}(?:\.\d{3})*|\d+),(\d{2})');

  // A linha tem letra de verdade, ou é só número/pontuação/moeda?
  static final _reTemLetra = RegExp(r'[A-Za-zÀ-ÿ]');

  static OcrResultado analisar(String texto) {
    final linhas = texto
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final itens = <ItemLido>[];
    final linhasLimpas = <String>[];
    double? total;
    int? km; // maior leitura de km do documento (odômetro domina) — ver _melhorKm
    var pularProximo = false; // valor logo após um rótulo pessoal isolado

    for (final l in linhas) {
      if (pularProximo) {
        pularProximo = false;
        continue; // ex.: o nome, na linha após um "Cliente"/"Nome" isolado
      }

      final matches = _reValor.allMatches(l).toList();
      final valorLinha =
          matches.isNotEmpty ? _parseValor(matches.last.group(0)!) : null;

      // Total = maior valor numa linha que menciona "total"; não vira item.
      final norm = l.toLowerCase();
      if (valorLinha != null && norm.contains('total')) {
        if (total == null || valorLinha > total) total = valorLinha;
        continue;
      }

      // Quilometragem: fica com a MAIOR leitura de km (carro rodado tem 5–6
      // dígitos → não deixa um número pequeno solto ganhar). Não vira item.
      final kmLinha = kmDaLinha(l);
      if (kmLinha != null) {
        if (km == null || kmLinha > km) km = kmLinha;
        continue;
      }

      // Camada 1: dado pessoal / token estrutural → descarta a linha. Se for um
      // rótulo de pessoa isolado, o valor vem na próxima linha → ignora ela também.
      if (linhaEhRuido(l)) {
        if (ehRotuloPessoaSozinho(l)) pularProximo = true;
        continue;
      }

      // Descrição = linha sem o valor no fim (o OCR NÃO amarra preço a peça).
      // Preserva especificações que não são preço (ex.: "Óleo 15W40").
      var desc = l;
      if (matches.isNotEmpty) {
        desc = l.substring(0, matches.last.start);
      }
      desc = desc.replaceAll(RegExp(r'[\s.:\-–—R\$]+$'), '').trim();

      // Ignora "número solto" (só dígitos/pontuação, ex.: "1,00", "200,00").
      if (desc.isEmpty || !_reTemLetra.hasMatch(desc)) continue;

      // Camada 2: cabeçalho cujas palavras são TODAS rótulo/marca ("Item",
      // "Serviço", "TOYOTA", "Cor: Branco") — não é peça.
      if (rotuloBloqueado(desc)) continue;

      linhasLimpas.add(l);
      itens.add(ItemLido(desc, null));
    }
    return OcrResultado(linhasLimpas.join('\n'), itens, total, km);
  }

  static double? _parseValor(String s) {
    final limpo = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo);
  }
}
