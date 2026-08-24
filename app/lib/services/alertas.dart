import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lembrete.dart';
import '../util/format.dart';
import 'repositories.dart';

/// Alertas de lembrete "não lidos": quando a data+hora de um lembrete chega, o
/// botão Lembretes na home ganha um número (quantos alertas dispararam e ainda
/// não foram vistos). Abrir a tela de Lembretes marca como lidos.
///
/// É estado LOCAL do aparelho (não sincroniza): cada aparelho tem o seu "lido".

const _kAlertasLidos = 'alertas_lidos_v1';

/// Chave de uma OCORRÊNCIA de alerta: id do lembrete + o vencimento exato. Assim,
/// quando um lembrete recorrente é empurrado para a próxima data, ele vira um
/// alerta NOVO (não lido) de novo.
String chaveAlerta(Lembrete l) =>
    '${l.id}@${l.vencimento.millisecondsSinceEpoch}';

/// O lembrete "disparou"? Data+hora efetiva já passou e não está pago.
bool alertaDisparado(Lembrete l, {DateTime? agora}) =>
    !l.pago && !comHoraEfetiva(l.vencimento).isAfter(agora ?? DateTime.now());

/// Conjunto de alertas já vistos (marcados como lidos).
final alertasLidosProvider =
    AsyncNotifierProvider<AlertasLidosNotifier, Set<String>>(
        AlertasLidosNotifier.new);

class AlertasLidosNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAlertasLidos);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// Marca como lidos todos os alertas DISPARADOS dos lembretes dados (chamado
  /// ao abrir a tela de Lembretes). Só persiste se algo mudou.
  Future<void> marcarLidos(Iterable<Lembrete> lembretes) async {
    final atual = {...(state.value ?? const <String>{})};
    var mudou = false;
    for (final l in lembretes.where((e) => alertaDisparado(e))) {
      if (atual.add(chaveAlerta(l))) mudou = true;
    }
    if (!mudou) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAlertasLidos, jsonEncode(atual.toList()));
    state = AsyncData(atual);
  }
}

/// Quantos alertas de lembrete estão DISPARADOS e NÃO lidos (carro selecionado).
/// É o número do badge no botão Lembretes.
final alertasNaoLidosProvider = Provider<int>((ref) {
  final lidos = ref.watch(alertasLidosProvider).value ?? const <String>{};
  final lembretes = ref.watch(lembretesDoVeiculoProvider);
  final agora = DateTime.now();
  return lembretes
      .where((l) => alertaDisparado(l, agora: agora) && !lidos.contains(chaveAlerta(l)))
      .length;
});
