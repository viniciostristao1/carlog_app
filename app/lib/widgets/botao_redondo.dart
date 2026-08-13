import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Botão redondo da home: um círculo com o símbolo da categoria (na cor dela) e
/// o rótulo embaixo. É o "atalho rápido" que o usuário toca para lançar dados.
class BotaoRedondo extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final Color cor;
  final VoidCallback onTap;

  const BotaoRedondo({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cor.withValues(alpha: 0.14),
              border: Border.all(color: cor.withValues(alpha: 0.55), width: 1.6),
            ),
            child: Icon(icone, color: cor, size: 32),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 92,
            child: Text(
              rotulo,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
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
