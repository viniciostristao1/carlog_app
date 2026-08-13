import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'fipe_seletor.dart';

/// Tela de busca na FIPE que DEVOLVE a seleção (não salva nada). Usada pelo
/// cadastro do veículo para preencher marca/modelo/ano/combustível.
class FipePickerScreen extends StatefulWidget {
  const FipePickerScreen({super.key});

  @override
  State<FipePickerScreen> createState() => _FipePickerScreenState();
}

class _FipePickerScreenState extends State<FipePickerScreen> {
  FipeSelecao? _sel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar na tabela FIPE')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const Text('Selecione marca, modelo e ano do seu carro.',
              style: TextStyle(color: AppColors.dim, fontSize: 13)),
          const SizedBox(height: 14),
          FipeSeletor(onSelecao: (s) => setState(() => _sel = s)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _sel == null
                ? null
                : () => Navigator.of(context).pop(_sel),
            icon: const Icon(Icons.check),
            label: const Text('Usar estes dados'),
          ),
        ],
      ),
    );
  }
}
