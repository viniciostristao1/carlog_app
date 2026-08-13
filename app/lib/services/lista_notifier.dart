import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base dos stores que são uma LISTA de itens com `id`, persistida como JSON em
/// shared_preferences. Cada repositório concreto só informa a chave e como
/// serializar — o insere/atualiza/remove vem de graça e é uniforme.
abstract class ListaNotifier<T> extends AsyncNotifier<List<T>> {
  String get chave;
  T deJson(Map<String, dynamic> j);
  Map<String, dynamic> paraJson(T v);
  String idDe(T v);

  @override
  Future<List<T>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chave);
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => deJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <T>[];
    }
  }

  List<T> get _atual => List<T>.of(state.value ?? const []);

  Future<void> _persist(List<T> lista) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chave, jsonEncode(lista.map(paraJson).toList()));
    state = AsyncData(lista);
  }

  /// Insere (se novo) ou atualiza (se o id já existe).
  Future<void> salvar(T item) async {
    final lista = _atual;
    final i = lista.indexWhere((x) => idDe(x) == idDe(item));
    if (i >= 0) {
      lista[i] = item;
    } else {
      lista.add(item);
    }
    await _persist(lista);
  }

  Future<void> remover(String id) async {
    final lista = _atual..removeWhere((x) => idDe(x) == id);
    await _persist(lista);
  }
}
