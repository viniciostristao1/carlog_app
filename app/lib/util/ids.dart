import 'dart:math';

final _rand = Random();

/// Id curto e único o bastante para itens locais (timestamp + aleatório).
/// Usado como chave de merge na sincronização (`id` estável por item).
String novoId() {
  final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final r = _rand.nextInt(1 << 32).toRadixString(36);
  return '$ts$r';
}
