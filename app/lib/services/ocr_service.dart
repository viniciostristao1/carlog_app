import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Uma linha lida do orçamento: uma descrição e, se detectado, um valor.
class ItemLido {
  final String descricao;
  final double? valor;
  const ItemLido(this.descricao, this.valor);
}

/// Resultado do OCR: o texto bruto (buscável) + as linhas separadas em
/// descrição/valor + o total detectado (linha com "total"), se houver.
class OcrResultado {
  final String textoBruto;
  final List<ItemLido> itens;
  final double? total;
  const OcrResultado(this.textoBruto, this.itens, this.total);
}

/// OCR do orçamento no próprio aparelho (Google ML Kit, offline e grátis).
class OcrService {
  final ImagePicker _picker = ImagePicker();

  /// Abre a câmera/galeria, reconhece o texto e separa item × valor.
  /// Retorna null se o usuário cancelar.
  Future<OcrResultado?> lerDe(ImageSource source) async {
    final XFile? arquivo = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2200,
    );
    if (arquivo == null) return null;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final rec =
          await recognizer.processImage(InputImage.fromFilePath(arquivo.path));
      return _parse(rec.text);
    } finally {
      await recognizer.close();
    }
  }

  // valores tipo "1.234,56", "89,90" (vírgula decimal, ponto de milhar opcional)
  static final _reValor = RegExp(r'(\d{1,3}(?:\.\d{3})*|\d+),(\d{2})');

  OcrResultado _parse(String texto) {
    final linhas = texto
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final itens = <ItemLido>[];
    double? total;

    for (final l in linhas) {
      final matches = _reValor.allMatches(l).toList();
      double? valor;
      String desc = l;
      if (matches.isNotEmpty) {
        final m = matches.last;
        valor = _parseValor(m.group(0)!);
        desc = l.substring(0, m.start);
      }
      desc = desc.replaceAll(RegExp(r'[\s.:\-–—R\$]+$'), '').trim();
      if (desc.isEmpty) desc = l;
      itens.add(ItemLido(desc, valor));

      // total = maior valor numa linha que menciona "total"
      final norm = l.toLowerCase();
      if (valor != null && norm.contains('total')) {
        if (total == null || valor > total) total = valor;
      }
    }
    return OcrResultado(texto, itens, total);
  }

  static double? _parseValor(String s) {
    final limpo = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo);
  }
}
