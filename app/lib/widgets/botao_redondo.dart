import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Botão redondo da home: um círculo PREENCHIDO com degradê da cor da categoria
/// (tom cheio → tom mais escuro) e o símbolo em branco, com o rótulo embaixo.
/// É o "atalho rápido" que o usuário toca para lançar dados.
class BotaoRedondo extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final Color cor;
  final VoidCallback onTap;

  /// Selo de contagem no canto do círculo (ex.: lembretes vencidos não lidos).
  /// 0 = sem selo.
  final int badge;

  const BotaoRedondo({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.cor,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Fill com degradê (variação aprovada): cor cheia da categoria até um tom
    // 28% mais escuro, com o ícone branco. Substitui o antigo visual "tonal +
    // borda" (outline).
    final escura = HSLColor.fromColor(cor)
        .withLightness(
            (HSLColor.fromColor(cor).lightness * 0.72).clamp(0.0, 1.0))
        .toColor();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cor, escura],
                  ),
                ),
                child: Icon(icone, color: Colors.white, size: 32),
              ),
              if (badge > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 22, minHeight: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: AppColors.bg, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 92,
            child: Text(
              rotulo,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
