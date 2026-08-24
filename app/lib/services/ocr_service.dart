import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'ocr/ocr_engine.dart';
import 'ocr/ocr_models.dart';

// Reexporta os modelos para quem já importava só o ocr_service (form, testes).
export 'ocr/ocr_models.dart' show ItemLido, OcrResultado;

/// OCR do orçamento no próprio aparelho (Google ML Kit, offline e grátis).
///
/// Esta classe é só a "cola" com a câmera/ML Kit. Toda a INTELIGÊNCIA de separar
/// peça de cabeçalho/dado pessoal e de ler km/total está no motor puro em
/// `ocr/` (testável sem câmera). Ver `OCR.md`.
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
      return OcrEngine.analisar(rec.text);
    } finally {
      await recognizer.close();
    }
  }

  /// Só para testes: expõe o parser (motor puro, sem câmera).
  @visibleForTesting
  OcrResultado parseTexto(String texto) => OcrEngine.analisar(texto);
}
