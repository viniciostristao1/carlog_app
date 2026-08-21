import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../theme/app_colors.dart';

/// Preferências de aparência (tema e tamanho de fonte), guardadas no aparelho.
/// São locais (não sincronizam): cada aparelho tem a sua.

// ─────────────────────────────── Tema ───────────────────────────────

const _kTema = 'tema_v1';

/// Tema escolhido (âmbar/azul/espresso/madeira). Padrão = âmbar (cor oficial).
final temaProvider =
    AsyncNotifierProvider<TemaNotifier, TemaApp>(TemaNotifier.new);

class TemaNotifier extends AsyncNotifier<TemaApp> {
  @override
  Future<TemaApp> build() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kTema);
    return TemaApp.values.firstWhere(
      (t) => t.name == s,
      orElse: () => TemaApp.ambar,
    );
  }

  Future<void> definir(TemaApp t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTema, t.name);
    state = AsyncData(t);
  }
}

// ─────────────────────────── Tamanho de fonte ───────────────────────────

/// Fatores de escala de fonte oferecidos (vale para o app inteiro). Normal = 1.0
/// (o tamanho de hoje); uma opção menor e duas maiores.
enum TamanhoFonte { menor, normal, maior, maximo }

extension TamanhoFonteX on TamanhoFonte {
  double get fator => switch (this) {
        TamanhoFonte.menor => 0.9,
        TamanhoFonte.normal => 1.0,
        TamanhoFonte.maior => 1.15,
        TamanhoFonte.maximo => 1.3,
      };
}

const _kFonte = 'fontScale_v1';

/// Escala de fonte escolhida. Padrão = Normal (1.0), o tamanho atual.
final fonteProvider =
    AsyncNotifierProvider<FonteNotifier, TamanhoFonte>(FonteNotifier.new);

class FonteNotifier extends AsyncNotifier<TamanhoFonte> {
  @override
  Future<TamanhoFonte> build() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kFonte);
    return TamanhoFonte.values.firstWhere(
      (t) => t.name == s,
      orElse: () => TamanhoFonte.normal,
    );
  }

  Future<void> definir(TamanhoFonte t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFonte, t.name);
    state = AsyncData(t);
  }
}

// ─────────────────────────────── Idioma ───────────────────────────────

const _kIdioma = 'idioma_v1';

/// Idioma do app (pt/en/es). Na 1ª vez segue o idioma do aparelho: pt → pt;
/// es → es; qualquer outro → inglês.
final idiomaProvider =
    AsyncNotifierProvider<IdiomaNotifier, Idioma>(IdiomaNotifier.new);

class IdiomaNotifier extends AsyncNotifier<Idioma> {
  @override
  Future<Idioma> build() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kIdioma);
    if (s != null) {
      return Idioma.values.firstWhere((i) => i.name == s,
          orElse: () => Idioma.pt);
    }
    final loc =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return switch (loc) {
      'pt' => Idioma.pt,
      'es' => Idioma.es,
      _ => Idioma.en,
    };
  }

  Future<void> definir(Idioma i) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kIdioma, i.name);
    state = AsyncData(i);
  }
}

/// Textos do app no idioma atual. Assista este provider e use `t.xxx`.
final stringsProvider = Provider<AppStrings>(
    (ref) => AppStrings(ref.watch(idiomaProvider).value ?? Idioma.pt));

