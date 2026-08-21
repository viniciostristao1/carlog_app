import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/abastecimento.dart';
import '../models/calibragem.dart';
import '../models/lembrete.dart';
import '../models/media_manual.dart';
import '../models/programacao.dart';
import '../models/revisao.dart';
import '../models/veiculo.dart';
import 'lista_notifier.dart';
import 'store_keys.dart';

// ─────────────────────────── Veículos (até 3) + seleção ───────────────────────────

const maxVeiculos = 3;

final veiculosProvider =
    AsyncNotifierProvider<VeiculosNotifier, List<Veiculo>>(VeiculosNotifier.new);

class VeiculosNotifier extends AsyncNotifier<List<Veiculo>> {
  @override
  Future<List<Veiculo>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chaveVeiculos);
    if (raw != null && raw.isNotEmpty) {
      try {
        return (jsonDecode(raw) as List)
            .map((e) => Veiculo.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
    // Migração do carro único antigo (veiculo_v1) → lista.
    final antigo = prefs.getString(chaveVeiculo);
    if (antigo != null && antigo.isNotEmpty) {
      try {
        final v = Veiculo.fromJson(jsonDecode(antigo) as Map<String, dynamic>);
        await _persist(prefs, [v]);
        return [v];
      } catch (_) {}
    }
    return [];
  }

  Future<void> _persist(SharedPreferences prefs, List<Veiculo> lista) async {
    await prefs.setString(
        chaveVeiculos, jsonEncode(lista.map((v) => v.toJson()).toList()));
  }

  List<Veiculo> get _atual => List<Veiculo>.of(state.value ?? const []);

  /// Insere (novo, respeitando [maxVeiculos]) ou atualiza por id. Novo vira o
  /// carro selecionado.
  Future<void> salvar(Veiculo v) async {
    final lista = _atual;
    final i = lista.indexWhere((x) => x.id == v.id);
    if (i >= 0) {
      lista[i] = v;
    } else {
      if (lista.length >= maxVeiculos) return;
      lista.add(v);
      ref.read(veiculoSelIdProvider.notifier).definir(v.id);
    }
    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs, lista);
    state = AsyncData(lista);
  }

  Future<void> remover(String id) async {
    final lista = _atual..removeWhere((x) => x.id == id);
    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs, lista);
    state = AsyncData(lista);
    if (ref.read(veiculoSelIdProvider).value == id) {
      ref
          .read(veiculoSelIdProvider.notifier)
          .definir(lista.isNotEmpty ? lista.first.id : null);
    }
  }
}

/// Id do carro selecionado (persistido).
final veiculoSelIdProvider =
    AsyncNotifierProvider<VeiculoSelIdNotifier, String?>(
        VeiculoSelIdNotifier.new);

class VeiculoSelIdNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(chaveVeiculoSel);
    return (s != null && s.isNotEmpty) ? s : null;
  }

  Future<void> definir(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(chaveVeiculoSel);
    } else {
      await prefs.setString(chaveVeiculoSel, id);
    }
    state = AsyncData(id);
  }
}

/// Veículo selecionado (derivado). Se o id salvo não existir, usa o primeiro.
final veiculoSelecionadoProvider = Provider<Veiculo?>((ref) {
  final lista = ref.watch(veiculosProvider).value ?? const [];
  if (lista.isEmpty) return null;
  final selId = ref.watch(veiculoSelIdProvider).value;
  return lista.firstWhere((v) => v.id == selId, orElse: () => lista.first);
});

/// Filtra itens de um store para o carro selecionado. Itens sem `veiculoId`
/// (dados antigos) pertencem ao PRIMEIRO carro (o migrado). Sem carro: mostra tudo.
List<T> _doVeiculoSel<T>(Ref ref, List<T> itens, String? Function(T) idDe) {
  final sel = ref.watch(veiculoSelecionadoProvider);
  if (sel == null) return itens;
  final lista = ref.watch(veiculosProvider).value ?? const [];
  final ehPrimeiro = lista.isNotEmpty && lista.first.id == sel.id;
  return itens.where((i) {
    final vid = idDe(i);
    return vid == sel.id || (vid == null && ehPrimeiro);
  }).toList();
}

// ─────────────────────────── Abastecimentos ───────────────────────────

final abastecimentosProvider =
    AsyncNotifierProvider<AbastecimentosNotifier, List<Abastecimento>>(
        AbastecimentosNotifier.new);

class AbastecimentosNotifier extends ListaNotifier<Abastecimento> {
  @override
  String get chave => chaveAbastecimentos;
  @override
  Abastecimento deJson(Map<String, dynamic> j) => Abastecimento.fromJson(j);
  @override
  Map<String, dynamic> paraJson(Abastecimento v) => v.toJson();
  @override
  String idDe(Abastecimento v) => v.id;
}

// ─────────────────────────── Médias manuais ───────────────────────────

final mediasProvider =
    AsyncNotifierProvider<MediasNotifier, List<MediaManual>>(
        MediasNotifier.new);

class MediasNotifier extends ListaNotifier<MediaManual> {
  @override
  String get chave => chaveMedias;
  @override
  MediaManual deJson(Map<String, dynamic> j) => MediaManual.fromJson(j);
  @override
  Map<String, dynamic> paraJson(MediaManual v) => v.toJson();
  @override
  String idDe(MediaManual v) => v.id;
}

// ─────────────────────────── Revisões (histórico) ───────────────────────────

final revisoesProvider =
    AsyncNotifierProvider<RevisoesNotifier, List<Revisao>>(RevisoesNotifier.new);

class RevisoesNotifier extends ListaNotifier<Revisao> {
  @override
  String get chave => chaveRevisoes;
  @override
  Revisao deJson(Map<String, dynamic> j) => Revisao.fromJson(j);
  @override
  Map<String, dynamic> paraJson(Revisao v) => v.toJson();
  @override
  String idDe(Revisao v) => v.id;
}

// ─────────────────────────── Programação (a fazer) ───────────────────────────

final programacaoProvider =
    AsyncNotifierProvider<ProgramacaoNotifier, List<ItemProgramado>>(
        ProgramacaoNotifier.new);

class ProgramacaoNotifier extends ListaNotifier<ItemProgramado> {
  @override
  String get chave => chaveProgramacao;
  @override
  ItemProgramado deJson(Map<String, dynamic> j) => ItemProgramado.fromJson(j);
  @override
  Map<String, dynamic> paraJson(ItemProgramado v) => v.toJson();
  @override
  String idDe(ItemProgramado v) => v.id;
}

// ─────────────────────────── Lembretes ───────────────────────────

final lembretesProvider =
    AsyncNotifierProvider<LembretesNotifier, List<Lembrete>>(
        LembretesNotifier.new);

class LembretesNotifier extends ListaNotifier<Lembrete> {
  @override
  String get chave => chaveLembretes;
  @override
  Lembrete deJson(Map<String, dynamic> j) => Lembrete.fromJson(j);
  @override
  Map<String, dynamic> paraJson(Lembrete v) => v.toJson();
  @override
  String idDe(Lembrete v) => v.id;
}

// ─────────────────────────── Calibragem (log) ───────────────────────────

final calibragemProvider =
    AsyncNotifierProvider<CalibragemNotifier, List<Calibragem>>(
        CalibragemNotifier.new);

class CalibragemNotifier extends ListaNotifier<Calibragem> {
  @override
  String get chave => chaveCalibragem;
  @override
  Calibragem deJson(Map<String, dynamic> j) => Calibragem.fromJson(j);
  @override
  Map<String, dynamic> paraJson(Calibragem v) => v.toJson();
  @override
  String idDe(Calibragem v) => v.id;
}

// ───────────── Providers FILTRADOS pelo carro selecionado (para leitura) ─────────────
// Escrita continua via <store>Provider.notifier (carimbe veiculoId ao criar).

final abastecimentosDoVeiculoProvider = Provider<List<Abastecimento>>((ref) =>
    _doVeiculoSel(ref, ref.watch(abastecimentosProvider).value ?? const [],
        (a) => a.veiculoId));

final mediasDoVeiculoProvider = Provider<List<MediaManual>>((ref) => _doVeiculoSel(
    ref, ref.watch(mediasProvider).value ?? const [], (m) => m.veiculoId));

final revisoesDoVeiculoProvider = Provider<List<Revisao>>((ref) => _doVeiculoSel(
    ref, ref.watch(revisoesProvider).value ?? const [], (r) => r.veiculoId));

final programacaoDoVeiculoProvider = Provider<List<ItemProgramado>>((ref) =>
    _doVeiculoSel(ref, ref.watch(programacaoProvider).value ?? const [],
        (p) => p.veiculoId));

final lembretesDoVeiculoProvider = Provider<List<Lembrete>>((ref) => _doVeiculoSel(
    ref, ref.watch(lembretesProvider).value ?? const [], (l) => l.veiculoId));

final calibragemDoVeiculoProvider = Provider<List<Calibragem>>((ref) =>
    _doVeiculoSel(ref, ref.watch(calibragemProvider).value ?? const [],
        (c) => c.veiculoId));
