import 'package:flutter/material.dart';

/// Temas do CarLog. Terracota (padrão) = azul-marinho "prancheta de oficina"
/// com destaque coral e hairlines azuladas; Âmbar e Azul = grafite escuro
/// "painel de carro" (muda só o accent); Madeira = claro (madeira); Neon Drift =
/// preto esverdeado com verde ácido; Daylight = claro branco/azul. O usuário
/// escolhe nas Configurações.
/// A escolha é persistida pelo `name` do enum e `AppStrings.nomeTema` recebe o
/// próprio enum — não existe mais dependência da POSIÇÃO no enum.
/// Legado: o valor antigo `blueprint` foi renomeado para `terracota` (mesma paleta).
enum TemaApp { ambar, azul, madeira, terracota, neonDrift, daylight }

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
  static Paleta _pal = _palDe(TemaApp.terracota);

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

  // ---- placa Mercosul (reprodução da placa física: faixa azul + fundo claro) ----
  static const placaAzul = Color(0xFF0B4CA8); // faixa superior
  static const placaBranco = Color(0xFFF7F9FC); // fundo da placa
  static const placaPreto = Color(0xFF16181C); // caracteres/borda
  static const bandeiraVerde = Color(0xFF009739); // bandeira do Brasil
  static const bandeiraAmarelo = Color(0xFFFEDD00);
  static const bandeiraAzul = Color(0xFF012169);

  // ---- as 4 paletas ----
  static Paleta _palDe(TemaApp t) => switch (t) {
        TemaApp.ambar =>
          _grafite(const Color(0xFFF5A524), const Color(0xFF231402)),
        TemaApp.azul =>
          _grafite(const Color(0xFF4C9BFF), const Color(0xFF06121F)),
        TemaApp.madeira => _madeira,
        TemaApp.terracota => _terracota,
        TemaApp.neonDrift => _neonDrift,
        TemaApp.daylight => _daylight,
      };

  /// Terracota (padrão): azul-marinho "prancheta", accent coral, linhas azuladas.
  static const Paleta _terracota = Paleta(
    bg: Color(0xFF0B1220),
    surface: Color(0xFF111C31),
    surface2: Color(0xFF17253E),
    line: Color(0x2878A5E1),
    lineStrong: Color(0x4C78A5E1),
    text: Color(0xFFE7EEF7),
    dim: Color(0xFF8098B7),
    dim2: Color(0xFF5A6E8C),
    accent: Color(0xFFFF6B4A),
    onAccent: Color(0xFF2A0A02),
    brilho: Brightness.dark,
  );

  /// Neon Drift: preto esverdeado com verde ácido (visual gamer/tech).
  static const Paleta _neonDrift = Paleta(
    bg: Color(0xFF05080A),
    surface: Color(0xFF0C1211),
    surface2: Color(0xFF131C19),
    line: Color(0xFF1E2B26),
    lineStrong: Color(0xFF2A3C35),
    text: Color(0xFFEAF7F1),
    dim: Color(0xFF7C9B8F),
    dim2: Color(0xFF52706A),
    accent: Color(0xFF39FF88),
    onAccent: Color(0xFF04220F),
    brilho: Brightness.dark,
  );

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

  /// Daylight: claro branco/azul (limpo, para uso de dia).
  static const Paleta _daylight = Paleta(
    bg: Color(0xFFF2F6FB),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE8EEF7),
    line: Color(0xFFD8E2EF),
    lineStrong: Color(0xFFC3D2E5),
    text: Color(0xFF16202E),
    dim: Color(0xFF61748C),
    dim2: Color(0xFF94A6BA),
    accent: Color(0xFF1F6FEB),
    onAccent: Color(0xFFFFFFFF),
    brilho: Brightness.light,
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
