import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_config.dart';
import 'auth_service.dart';
import 'repositories.dart';
import 'store_keys.dart';

/// Sincroniza todos os stores locais (JSON em shared_preferences) com o Firestore
/// quando o usuário está logado. Cada store vira um campo do documento
/// `users/{uid}`. Estratégia: no 1º snapshot faz UNIÃO (listas por id; o veículo
/// só vem da nuvem se não houver local); depois "última escrita vence".
///
/// Só roda quando `kFirebaseConfigured` é true — o [syncProvider] observa o login.
class SyncController {
  SyncController(this.ref);
  final Ref ref;

  String? _uid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Timer? _debounce;
  bool _aplicandoRemoto = false;
  bool _primeiroSnapshot = true;
  String? _ultimoSync;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  void start(String uid) {
    if (_uid == uid) return;
    stop();
    _uid = uid;
    _primeiroSnapshot = true;
    _ultimoSync = null;
    _sub = _doc(uid).snapshots().listen(_onRemote, onError: (_) {});
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _debounce?.cancel();
    _uid = null;
  }

  void dispose() => stop();

  void onLocalChange() {
    if (_aplicandoRemoto || _uid == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final uid = _uid;
      if (uid == null) return;
      await _push(uid, await SharedPreferences.getInstance());
    });
  }

  Future<void> _onRemote(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final uid = _uid;
    if (uid == null) return;
    if (snap.metadata.hasPendingWrites) return; // eco da própria escrita

    final prefs = await SharedPreferences.getInstance();

    if (!snap.exists || snap.data() == null) {
      _primeiroSnapshot = false;
      await _push(uid, prefs);
      return;
    }

    final data = snap.data()!;
    if (_primeiroSnapshot) {
      _primeiroSnapshot = false;
      _aplicandoRemoto = true;
      for (final chave in todosOsStores) {
        if (chave == chaveVeiculo) {
          _mergeObjeto(prefs, chave, data[chave]);
        } else {
          _mergeLista(prefs, chave, data[chave]);
        }
      }
      _invalidar();
      _aplicandoRemoto = false;
      _ultimoSync = _estado(prefs);
      await _push(uid, prefs);
      return;
    }

    final estadoRemoto = _estadoDe(data);
    if (estadoRemoto == _ultimoSync) return;

    _aplicandoRemoto = true;
    for (final chave in todosOsStores) {
      final remoto = data[chave];
      if (remoto is String) prefs.setString(chave, remoto);
    }
    _invalidar();
    _aplicandoRemoto = false;
    _ultimoSync = _estado(prefs);
  }

  Future<void> _push(String uid, SharedPreferences prefs) async {
    final estado = _estado(prefs);
    if (estado == _ultimoSync) return;
    _ultimoSync = estado;
    try {
      final payload = <String, dynamic>{
        for (final chave in todosOsStores) chave: prefs.getString(chave) ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _doc(uid).set(payload, SetOptions(merge: true));
    } catch (_) {
      // offline/sem permissão: o cache do Firestore reenvia quando der.
    }
  }

  String _estado(SharedPreferences prefs) => [
        for (final chave in todosOsStores) prefs.getString(chave) ?? '',
      ].join('§');

  String _estadoDe(Map<String, dynamic> data) => [
        for (final chave in todosOsStores)
          (data[chave] is String ? data[chave] as String : ''),
      ].join('§');

  void _mergeObjeto(SharedPreferences prefs, String chave, dynamic remoto) {
    final local = prefs.getString(chave);
    if ((local == null || local.isEmpty) && remoto is String) {
      prefs.setString(chave, remoto);
    }
  }

  void _mergeLista(SharedPreferences prefs, String chave, dynamic remoto) {
    final local = _parse(prefs.getString(chave));
    final rem = _parse(remoto is String ? remoto : null);
    final porId = <String, Map<String, dynamic>>{};
    for (final e in rem) {
      final id = e['id'];
      if (id is String) porId[id] = e;
    }
    for (final e in local) {
      final id = e['id'];
      if (id is String) porId.putIfAbsent(id, () => e);
    }
    prefs.setString(chave, jsonEncode(porId.values.toList()));
  }

  List<Map<String, dynamic>> _parse(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  void _invalidar() {
    ref.invalidate(veiculoProvider);
    ref.invalidate(abastecimentosProvider);
    ref.invalidate(mediasProvider);
    ref.invalidate(revisoesProvider);
    ref.invalidate(programacaoProvider);
    ref.invalidate(lembretesProvider);
    ref.invalidate(calibragemProvider);
  }
}

/// Mantém a sincronização ligada conforme o login. Observa todos os stores para
/// empurrar mudanças. Inerte enquanto `kFirebaseConfigured` for false.
final syncProvider = Provider<SyncController>((ref) {
  final controller = SyncController(ref);
  ref.onDispose(controller.dispose);

  if (!kFirebaseConfigured) return controller;

  ref.listen(authStateProvider, (prev, next) {
    final user = next.asData?.value;
    if (user != null) {
      controller.start(user.uid);
    } else {
      controller.stop();
    }
  }, fireImmediately: true);

  ref.listen(veiculoProvider, (_, _) => controller.onLocalChange());
  ref.listen(abastecimentosProvider, (_, _) => controller.onLocalChange());
  ref.listen(mediasProvider, (_, _) => controller.onLocalChange());
  ref.listen(revisoesProvider, (_, _) => controller.onLocalChange());
  ref.listen(programacaoProvider, (_, _) => controller.onLocalChange());
  ref.listen(lembretesProvider, (_, _) => controller.onLocalChange());
  ref.listen(calibragemProvider, (_, _) => controller.onLocalChange());

  return controller;
});
