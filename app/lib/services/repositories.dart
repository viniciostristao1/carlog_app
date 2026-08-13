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

// ─────────────────────────── Veículo (objeto único) ───────────────────────────

final veiculoProvider =
    AsyncNotifierProvider<VeiculoNotifier, Veiculo?>(VeiculoNotifier.new);

class VeiculoNotifier extends AsyncNotifier<Veiculo?> {
  @override
  Future<Veiculo?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chaveVeiculo);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Veiculo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> salvar(Veiculo v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chaveVeiculo, jsonEncode(v.toJson()));
    state = AsyncData(v);
  }
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
