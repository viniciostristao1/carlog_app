import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Placa Mercosul (reprodução da placa física): faixa azul no topo com o logo
/// do Mercosul, "BRASIL" e a bandeira, e o código em preto sobre fundo claro.
/// Usada no cartão do veículo na home (substitui o antigo chip de texto).
class PlacaMercosul extends StatelessWidget {
  final String placa;

  /// Altura da placa (a largura segue a proporção real 400×130).
  final double altura;

  const PlacaMercosul({super.key, required this.placa, this.altura = 38});

  @override
  Widget build(BuildContext context) {
    final largura = altura * 400 / 130;
    final faixa = altura * 0.32;
    final fonte = altura * 0.42;
    return Container(
      width: largura,
      height: altura,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.placaBranco,
        borderRadius: BorderRadius.circular(altura * 0.14),
        border: Border.all(
            color: AppColors.placaPreto, width: altura * 0.035),
      ),
      child: Column(
        children: [
          Container(
            height: faixa,
            color: AppColors.placaAzul,
            padding: EdgeInsets.symmetric(horizontal: largura * 0.045),
            child: Row(
              children: [
                _LogoMercosul(tamanho: faixa * 0.66),
                const Spacer(),
                Text(
                  'BRASIL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: faixa * 0.46,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    height: 1.0,
                  ),
                ),
                const Spacer(),
                _BandeiraBrasil(largura: faixa * 1.3),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: largura * 0.06),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    placa.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.placaPreto,
                      fontSize: fonte,
                      fontWeight: FontWeight.w800,
                      letterSpacing: fonte * 0.12,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo do Mercosul simplificado: 4 arcos brancos em cata-vento.
class _LogoMercosul extends StatelessWidget {
  final double tamanho;
  const _LogoMercosul({required this.tamanho});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: tamanho,
        height: tamanho,
        child: CustomPaint(painter: _PintorMercosul()),
      );
}

class _PintorMercosul extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.17
      ..strokeCap = StrokeCap.round;
    final raio = size.width * 0.30;
    final centro = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 4; i++) {
      final inicio = i * math.pi / 2 - math.pi / 4;
      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: raio),
        inicio,
        math.pi * 0.62,
        false,
        pincel,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bandeira do Brasil em miniatura (verde, losango amarelo, círculo azul).
class _BandeiraBrasil extends StatelessWidget {
  final double largura;
  const _BandeiraBrasil({required this.largura});

  @override
  Widget build(BuildContext context) {
    final altura = largura * 0.7;
    return Container(
      width: largura,
      height: altura,
      color: AppColors.bandeiraVerde,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: altura * 0.56,
              height: altura * 0.56,
              color: AppColors.bandeiraAmarelo,
            ),
          ),
          Container(
            width: altura * 0.26,
            height: altura * 0.26,
            decoration: const BoxDecoration(
              color: AppColors.bandeiraAzul,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
