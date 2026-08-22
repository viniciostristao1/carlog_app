import 'dart:convert';

import 'package:carlog/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mesclagem do import de backup: união por id, LOCAL sempre vence e nunca é
/// apagado. Garante que restaurar um backup não destrói dados atuais.
void main() {
  List<Map<String, dynamic>> dec(String j) =>
      (jsonDecode(j) as List).cast<Map<String, dynamic>>();

  test('acrescenta só os ids que faltam; não apaga nem sobrescreve o local', () {
    final local = jsonEncode([
      {'id': 'a', 'v': 'local-A'},
      {'id': 'b', 'v': 'local-B'},
    ]);
    final backup = jsonEncode([
      {'id': 'b', 'v': 'backup-B'}, // colide → local vence, ignora
      {'id': 'c', 'v': 'backup-C'}, // novo → entra
    ]);

    final (out, novos) = BackupService.mesclarLista(local, backup);
    final itens = dec(out);
    final porId = {for (final e in itens) e['id']: e['v']};

    expect(novos, 1);
    expect(porId, {'a': 'local-A', 'b': 'local-B', 'c': 'backup-C'});
  });

  test('local vazio recebe o backup inteiro (restauro em aparelho novo)', () {
    final backup = jsonEncode([
      {'id': 'x'},
      {'id': 'y'},
    ]);
    final (out, novos) = BackupService.mesclarLista(null, backup);
    expect(novos, 2);
    expect(dec(out).length, 2);
  });

  test('backup vazio ou inválido não muda nada', () {
    final local = jsonEncode([
      {'id': 'a'}
    ]);
    expect(BackupService.mesclarLista(local, '').$2, 0);
    expect(BackupService.mesclarLista(local, 'lixo').$2, 0);
    expect(dec(BackupService.mesclarLista(local, '').$1).length, 1);
  });
}
