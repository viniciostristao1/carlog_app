import 'package:carlog/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('temas', () {
    test('Neon Drift tem paleta própria (preto + verde ácido)', () {
      expect(
          AppColors.accentDoTema(TemaApp.neonDrift), const Color(0xFF39FF88));
      expect(
          AppColors.fundoDoTema(TemaApp.neonDrift), const Color(0xFF05080A));
    });

    test('Daylight é claro e branco/azul', () {
      expect(
          AppColors.accentDoTema(TemaApp.daylight), const Color(0xFF1F6FEB));
      expect(
          AppColors.fundoDoTema(TemaApp.daylight), const Color(0xFFF2F6FB));
      AppColors.aplicarTema(TemaApp.daylight);
      expect(AppColors.brilho, Brightness.light);
      AppColors.aplicarTema(TemaApp.terracota); // restaura o padrão
    });

    test('Expresso saiu do app', () {
      expect(TemaApp.values.map((t) => t.name), isNot(contains('espresso')));
    });

    test('todos os temas têm accents distintos', () {
      final accents = TemaApp.values.map(AppColors.accentDoTema).toSet();
      expect(accents.length, TemaApp.values.length);
    });
  });
}
