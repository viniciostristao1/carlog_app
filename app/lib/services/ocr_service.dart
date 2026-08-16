import 'package:flutter/foundation.dart' show visibleForTesting;
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

  /// Só para testes: expõe o parser (separação item×valor + filtro pessoal).
  @visibleForTesting
  OcrResultado parseTexto(String texto) => _parse(texto);

  // valores tipo "1.234,56", "89,90" (vírgula decimal, ponto de milhar opcional)
  static final _reValor = RegExp(r'(\d{1,3}(?:\.\d{3})*|\d+),(\d{2})');

  // ---- filtros de informação pessoal (não viram item nem texto salvo) ----
  static final _reEmail = RegExp(r'[\w.\-]+@[\w\-]+\.[\w.\-]+');
  static final _reCep = RegExp(r'\b\d{5}-\d{3}\b');
  static final _reCpf = RegExp(r'\b\d{3}\.\d{3}\.\d{3}-\d{2}\b');
  static final _reCnpj = RegExp(r'\b\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}\b');
  static final _reFone = RegExp(r'\(?\d{2}\)?\s?9?\d{4}-\d{4}');
  // rótulos típicos de cabeçalho/cadastro (evita palavras que são peças, ex.:
  // "chave de contato", por isso não inclui "contato"/"estado").
  static final _reRotuloPessoal = RegExp(
    r'\b(cliente|nome|endere\w*|rua|avenida|bairro|cep|cpf|cnpj|telefone|celular|fone|e-?mail|inscri\w*|whats\w*|raz[ãa]o\s+social)\b',
    caseSensitive: false,
  );

  /// Heurística: a linha parece dado pessoal/cadastral (nome, endereço, CEP,
  /// CPF/CNPJ, telefone, e-mail)? Se sim, o OCR a ignora.
  static bool _ehInfoPessoal(String l) =>
      _reEmail.hasMatch(l) ||
      _reCep.hasMatch(l) ||
      _reCpf.hasMatch(l) ||
      _reCnpj.hasMatch(l) ||
      _reFone.hasMatch(l) ||
      _reRotuloPessoal.hasMatch(l);

  OcrResultado _parse(String texto) {
    final linhas = texto
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final itens = <ItemLido>[];
    final linhasLimpas = <String>[];
    double? total;

    for (final l in linhas) {
      final matches = _reValor.allMatches(l).toList();
      final valorLinha =
          matches.isNotEmpty ? _parseValor(matches.last.group(0)!) : null;

      // total = maior valor numa linha que menciona "total" (mesmo filtrada).
      final norm = l.toLowerCase();
      if (valorLinha != null && norm.contains('total')) {
        if (total == null || valorLinha > total) total = valorLinha;
      }

      // Pula dados pessoais: não vira item nem entra no texto salvo.
      if (_ehInfoPessoal(l)) continue;
      linhasLimpas.add(l);

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
    }
    return OcrResultado(linhasLimpas.join('\n'), itens, total);
  }

  static double? _parseValor(String s) {
    final limpo = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(limpo);
  }
}
