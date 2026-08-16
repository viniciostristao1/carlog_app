import 'package:flutter/material.dart';

/// Temas do CarLog. Âmbar (padrão) e Azul = grafite escuro "painel de carro"
/// (muda só o accent); Espresso = marrom escuro; Madeira = claro (madeira).
/// O usuário escolhe nas Configurações. Inspirado no app irmão (Calis Timer).
enum TemaApp { ambar, azul, espresso, madeira }

/// Uma paleta completa (tokens de cor de um tema). Fundo, superfícies, texto e
/// accent mudam por tema — por isso [AppColors] os expõe como getters que lêem
/// a paleta atual (definida por [AppColors.aplicarTema]).
class Paleta {
  final Color bg, surface, surface2, line, lineStrong, text, dim, dim2;
  final Color accent, onAccent;
  final Brightness brilho;
  const Paleta({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.dim,
    required this.dim2,
    required this.accent,
    required this.onAccent,
    required this.brilho,
  });
}

/// Paleta do CarLog. As cores por CATEGORIA (anel dos botões redondos) e as
/// funcionais (danger/ok/warn) são semânticas e constantes em todos os temas;
/// fundo/superfície/texto/accent vêm da [Paleta] atual.
abstract final class AppColors {
  // ---- tokens dependentes de tema (getters lêem a paleta atual) ----
  static Paleta _pal = _palDe(TemaApp.ambar);

  /// Troca a paleta atual (chamado em `buildAppTheme`, a cada (re)build do tema).
  static void aplicarTema(TemaApp t) => _pal = _palDe(t);

  static Color get bg => _pal.bg;
  static Color get surface => _pal.surface;
  static Color get surface2 => _pal.surface2;
  static Color get line => _pal.line;
  static Color get lineStrong => _pal.lineStrong;
  static Color get text => _pal.text;
  static Color get dim => _pal.dim;
  static Color get dim2 => _pal.dim2;
  static Color get accent => _pal.accent;
  static Color get onAccent => _pal.onAccent;
  static Brightness get brilho => _pal.brilho;

  /// Versão LEGÍVEL de uma cor de destaque sobre a superfície atual. Nos temas
  /// escuros devolve a própria cor (os pasteis claros vão bem no escuro); no
  /// tema claro (Madeira) escurece o hue para ter contraste no bege — usar em
  /// TEXTO/números coloridos (ex.: média, calibragem), NÃO nos botões redondos.
  static Color leg(Color c) {
    if (brilho == Brightness.dark) return c;
    final h = HSLColor.fromColor(c);
    return h
        .withLightness((h.lightness * 0.42).clamp(0.0, 0.40))
        .withSaturation(h.saturation < 0.5 ? 0.55 : h.saturation)
        .toColor();
  }

  // ---- helpers p/ preview do seletor de tema ----
  static Color accentDoTema(TemaApp t) => _palDe(t).accent;
  static Color onAccentDoTema(TemaApp t) => _palDe(t).onAccent;
  static Color fundoDoTema(TemaApp t) => _palDe(t).bg;
  static Color superficieDoTema(TemaApp t) => _palDe(t).surface;

  // ---- cores funcionais (constantes) ----
  static const danger = Color(0xFFFF6B6B);
  static const ok = Color(0xFF3DDC97);
  static const warn = Color(0xFFFFB020);

  // ---- cores por categoria (anel dos botões redondos da home) — fixas ----
  static const catAbastecimento = Color(0xFFFF7A1A); // laranja (combustível)
  static const catConsumo = Color(0xFF3DDC97); // verde (economia/média)
  static const catRevisoes = Color(0xFF4C9BFF); // azul (manutenção)
  static const catFipe = Color(0xFFB98BFF); // roxo (valor/FIPE)
  static const catCalibragem = Color(0xFF19C7B1); // teal (pneus)
  static const catLembretes = Color(0xFFFF6B6B); // vermelho (vencimentos)

  // ---- as 4 paletas ----
  static Paleta _palDe(TemaApp t) => switch (t) {
        TemaApp.ambar =>
          _grafite(const Color(0xFFF5A524), const Color(0xFF231402)),
        TemaApp.azul =>
          _grafite(const Color(0xFF4C9BFF), const Color(0xFF06121F)),
        TemaApp.espresso => _espresso,
        TemaApp.madeira => _madeira,
      };

  /// Grafite escuro "painel" (âmbar/azul): muda só o accent.
  static Paleta _grafite(Color accent, Color onAccent) => Paleta(
        bg: const Color(0xFF0E1116),
        surface: const Color(0xFF161B22),
        surface2: const Color(0xFF1E252F),
        line: const Color(0x14FFFFFF),
        lineStrong: const Color(0x26FFFFFF),
        text: const Color(0xFFE9EEF5),
        dim: const Color(0xFF9AA6B6),
        dim2: const Color(0xFF5D6675),
        accent: accent,
        onAccent: onAccent,
        brilho: Brightness.dark,
      );

  static const Paleta _espresso = Paleta(
    bg: Color(0xFF241F19),
    surface: Color(0xFF2E2820),
    surface2: Color(0xFF382F26),
    line: Color(0x12FFFFFF),
    lineStrong: Color(0x24FFFFFF),
    text: Color(0xFFEFE8DC),
    dim: Color(0xFFB0A390),
    dim2: Color(0xFF7A6F5E),
    accent: Color(0xFFEBA84C),
    onAccent: Color(0xFF241700),
    brilho: Brightness.dark,
  );

  static const Paleta _madeira = Paleta(
    bg: Color(0xFFDCCBB0),
    surface: Color(0xFFE7DAC3),
    surface2: Color(0xFFCFBD9C),
    line: Color(0x14000000),
    lineStrong: Color(0x28000000),
    text: Color(0xFF3A3122),
    dim: Color(0xFF7C6C52),
    dim2: Color(0xFF9A8865),
    accent: Color(0xFFB5652E),
    onAccent: Color(0xFFFFF3E7),
    brilho: Brightness.light,
  );
}
