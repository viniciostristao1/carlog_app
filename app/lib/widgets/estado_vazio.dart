import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Placeholder amigável para listas vazias.
class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 54, color: AppColors.dim2),
            const SizedBox(height: 16),
            Text(titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitulo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.dim, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }
}
