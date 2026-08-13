import 'package:flutter/material.dart';

/// Paleta do CarLog. Tema escuro "painel de carro": grafite profundo + accent
/// teal. Cada categoria da home tem uma cor própria (o anel do botão redondo).
///
/// Por ora há um único tema (escuro). Os tokens ficam como constantes; se um dia
/// entrar tema claro, vira um switch de paleta como no app irmão.
abstract final class AppColors {
  // ---- superfícies / texto ----
  static const bg = Color(0xFF0E1116); // fundo (grafite quase preto)
  static const surface = Color(0xFF161B22); // cards
  static const surface2 = Color(0xFF1E252F); // cards elevados / campos
  static const line = Color(0x14FFFFFF); // divisórias sutis
  static const lineStrong = Color(0x26FFFFFF);
  static const text = Color(0xFFE9EEF5);
  static const dim = Color(0xFF9AA6B6); // texto secundário
  static const dim2 = Color(0xFF5D6675); // texto terciário / placeholder

  // ---- accent da marca (âmbar, como o logo e os apps irmãos) ----
  static const accent = Color(0xFFF5A524); // âmbar (ações principais)
  static const onAccent = Color(0xFF231402);
  static const danger = Color(0xFFFF6B6B);
  static const ok = Color(0xFF3DDC97);
  static const warn = Color(0xFFFFB020);

  // ---- cores por categoria (anel dos botões redondos da home) ----
  static const catAbastecimento = Color(0xFFFF7A1A); // laranja (combustível)
  static const catConsumo = Color(0xFF3DDC97); // verde (economia/média)
  static const catRevisoes = Color(0xFF4C9BFF); // azul (manutenção)
  static const catFipe = Color(0xFFB98BFF); // roxo (valor/FIPE)
  static const catCalibragem = Color(0xFF19C7B1); // teal (pneus)
  static const catLembretes = Color(0xFFFF6B6B); // vermelho (vencimentos)
}
