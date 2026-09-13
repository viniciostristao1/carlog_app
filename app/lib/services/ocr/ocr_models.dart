// Modelos do motor de OCR (leitura de orçamento). Puros, sem dependência de
// plugin — dá para testar o parser sem câmera. Ver `ocr_engine.dart`.

/// Uma linha lida do orçamento: uma descrição e, se detectado, um valor.
class ItemLido {
  final String descricao;
  final double? valor;
  const ItemLido(this.descricao, this.valor);
}

/// Resultado do OCR: o texto bruto (buscável) + as peças/serviços (só a
/// descrição — o OCR NÃO amarra preço a peça) + o total detectado (linha com
/// "total") + a quilometragem detectada (número perto de "km"/"quilometragem")
/// + a data do serviço detectada no documento (pode ser null).
class OcrResultado {
  final String textoBruto;
  final List<ItemLido> itens;
  final double? total;
  final int? km;
  final DateTime? dataServico;
  const OcrResultado(this.textoBruto, this.itens, this.total, this.km,
      {this.dataServico});
}
