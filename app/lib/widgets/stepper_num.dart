import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Campo numérico com botões − / + (para ir clicando). Segurar acelera.
class StepperNum extends StatelessWidget {
  final String label;
  final double valor;
  final double step;
  final double min;
  final double max;
  final String sufixo;
  final Color? cor;
  final ValueChanged<double> onChanged;

  const StepperNum({
    super.key,
    required this.label,
    required this.valor,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
    this.max = 60,
    this.sufixo = '',
    this.cor,
  });

  void _mudar(double delta) {
    var v = valor + delta;
    if (v < min) v = min;
    if (v > max) v = max;
    onChanged(double.parse(v.toStringAsFixed(1)));
  }

  @override
  Widget build(BuildContext context) {
    final texto = valor == valor.roundToDouble()
        ? valor.toStringAsFixed(0)
        : valor.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _botao(Icons.remove, () => _mudar(-step)),
              Flexible(
                child: Text(
                  sufixo.isEmpty ? texto : '$texto $sufixo',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
              ),
              _botao(Icons.add, () => _mudar(step)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _botao(IconData icone, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icone, color: cor ?? AppColors.accent, size: 22),
      ),
    );
  }
}
