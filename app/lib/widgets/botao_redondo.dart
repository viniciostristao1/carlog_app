import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Botão redondo da home: um círculo com o símbolo da categoria (na cor dela) e
/// o rótulo embaixo. É o "atalho rápido" que o usuário toca para lançar dados.
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
                  color: cor.withValues(alpha: 0.14),
                  border:
                      Border.all(color: cor.withValues(alpha: 0.55), width: 1.6),
                ),
                child: Icon(icone, color: cor, size: 32),
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
