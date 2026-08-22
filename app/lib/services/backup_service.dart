import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'store_keys.dart';

/// Backup manual: exporta TODOS os stores locais para um arquivo `.json` e
/// importa de volta, **mesclando por id** (não apaga o que já existe). É a rede
/// de segurança além da nuvem — o usuário guarda o arquivo onde quiser (Drive,
/// e-mail, WhatsApp…) e restaura em qualquer aparelho.
class BackupService {
  static const _schema = 1;

  /// Monta o mapa de backup a partir das preferências. Cada store vai como o
  /// próprio JSON já serializado (lossless); `veiculo_sel_v1` é um id simples.
  static Map<String, dynamic> montar(SharedPreferences prefs) => {
        'app': 'carlog',
        'schema': _schema,
        'exportadoEm': DateTime.now().toIso8601String(),
        'dados': {
          for (final chave in todosOsStores)
            chave: prefs.getString(chave) ?? '',
        },
      };

  /// Abre a folha de compartilhamento com o arquivo `.json` do backup.
  Future<void> exportar() async {
    final prefs = await SharedPreferences.getInstance();
    final json = const JsonEncoder.withIndent('  ').convert(montar(prefs));
    final bytes = Uint8List.fromList(utf8.encode(json));
    final a = DateTime.now();
    final nome =
        'carlog-backup-${a.year}${_pad2(a.month)}${_pad2(a.day)}.json';
    // XFile.fromData (bytes) → o share_plus grava o arquivo temporário sozinho.
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'application/json', name: nome)],
      fileNameOverrides: [nome],
      subject: 'Backup CarLog',
    ));
  }

  /// Deixa o usuário escolher um `.json` e MESCLA por id nos stores locais (nada
  /// é apagado; em conflito, o dado LOCAL vence). Retorna quantos itens novos
  /// entraram, ou `null` se cancelou. Lança [FormatException] se o arquivo não
  /// for um backup do CarLog.
  Future<int?> importar() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final bytes = res?.files.single.bytes;
    if (bytes == null) return null; // cancelou

    final mapa = jsonDecode(utf8.decode(bytes));
    if (mapa is! Map || mapa['dados'] is! Map) {
      throw const FormatException('Arquivo não é um backup do CarLog.');
    }
    final dados = (mapa['dados'] as Map).cast<String, dynamic>();

    final prefs = await SharedPreferences.getInstance();
    var novos = 0;
    for (final chave in todosOsStores) {
      final vindo = dados[chave];
      if (vindo is! String || vindo.isEmpty) continue;
      if (storesObjeto.contains(chave)) {
        // id simples (carro selecionado): só adota se ainda não houver um local.
        final local = prefs.getString(chave);
        if (local == null || local.isEmpty) await prefs.setString(chave, vindo);
      } else {
        novos += await _mesclarLista(prefs, chave, vindo);
      }
    }
    return novos;
  }

  Future<int> _mesclarLista(
      SharedPreferences prefs, String chave, String backupJson) async {
    final (novoJson, novos) = mesclarLista(prefs.getString(chave), backupJson);
    if (novos > 0) await prefs.setString(chave, novoJson);
    return novos;
  }

  /// União por id (lógica pura, testável): mantém tudo que é local e acrescenta
  /// só os itens do backup cujo id ainda não existe — o LOCAL nunca é apagado
  /// nem sobrescrito. Devolve o JSON resultante e quantos itens novos entraram.
  @visibleForTesting
  static (String, int) mesclarLista(String? localJson, String? backupJson) {
    final local = _parse(localJson);
    final backup = _parse(backupJson);
    final idsLocais = <String>{
      for (final e in local)
        if (e['id'] is String) e['id'] as String,
    };
    final novosItens = <Map<String, dynamic>>[
      for (final e in backup)
        if (e['id'] is String && !idsLocais.contains(e['id'])) e,
    ];
    final resultado = [...local, ...novosItens];
    return (jsonEncode(resultado), novosItens.length);
  }

  static List<Map<String, dynamic>> _parse(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');
}
