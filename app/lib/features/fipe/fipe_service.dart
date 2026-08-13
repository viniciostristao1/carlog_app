import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cliente da tabela FIPE via API pública gratuita (parallelum.com.br/fipe).
/// Fluxo em cascata: marcas → modelos → anos → valor. Sem chave/token.
class FipeService {
  static const _base = 'https://parallelum.com.br/fipe/api/v1/carros';

  Future<List<FipeItem>> marcas() => _lista('$_base/marcas');

  Future<List<FipeItem>> modelos(String marcaCod) async {
    final r = await _get('$_base/marcas/$marcaCod/modelos');
    final modelos = (r['modelos'] as List).cast<Map<String, dynamic>>();
    return modelos.map(FipeItem.fromJson).toList();
  }

  Future<List<FipeItem>> anos(String marcaCod, String modeloCod) =>
      _lista('$_base/marcas/$marcaCod/modelos/$modeloCod/anos');

  Future<FipeResultado> valor(
      String marcaCod, String modeloCod, String anoCod) async {
    final r =
        await _get('$_base/marcas/$marcaCod/modelos/$modeloCod/anos/$anoCod');
    return FipeResultado.fromJson(r);
  }

  Future<List<FipeItem>> _lista(String url) async {
    final r = await _getLista(url);
    return r.map(FipeItem.fromJson).toList();
  }

  Future<Map<String, dynamic>> _get(String url) async {
    final resp = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('FIPE respondeu ${resp.statusCode}');
    }
    return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _getLista(String url) async {
    final resp = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('FIPE respondeu ${resp.statusCode}');
    }
    return (jsonDecode(utf8.decode(resp.bodyBytes)) as List)
        .cast<Map<String, dynamic>>();
  }
}

class FipeItem {
  final String codigo;
  final String nome;
  const FipeItem({required this.codigo, required this.nome});

  factory FipeItem.fromJson(Map<String, dynamic> j) => FipeItem(
        codigo: '${j['codigo']}',
        nome: '${j['nome']}',
      );
}

class FipeResultado {
  final String valorTexto; // "R$ 45.678,00"
  final double valor; // 45678.00
  final String marca;
  final String modelo;
  final String anoModelo;
  final String combustivel;
  final String codigoFipe;
  final String mesReferencia;

  const FipeResultado({
    required this.valorTexto,
    required this.valor,
    required this.marca,
    required this.modelo,
    required this.anoModelo,
    required this.combustivel,
    required this.codigoFipe,
    required this.mesReferencia,
  });

  factory FipeResultado.fromJson(Map<String, dynamic> j) {
    final txt = '${j['Valor'] ?? ''}';
    return FipeResultado(
      valorTexto: txt,
      valor: _parseValor(txt),
      marca: '${j['Marca'] ?? ''}',
      modelo: '${j['Modelo'] ?? ''}',
      anoModelo: '${j['AnoModelo'] ?? ''}',
      combustivel: '${j['Combustivel'] ?? ''}',
      codigoFipe: '${j['CodigoFipe'] ?? ''}',
      mesReferencia: '${j['MesReferencia'] ?? ''}'.trim(),
    );
  }

  /// "R$ 45.678,00" → 45678.00
  static double _parseValor(String s) {
    final limpo = s
        .replaceAll(RegExp(r'[R$\s]'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(limpo) ?? 0;
  }
}
