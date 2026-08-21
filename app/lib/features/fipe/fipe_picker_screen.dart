import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/prefs.dart';
import '../../theme/app_colors.dart';
import 'fipe_seletor.dart';

/// Tela de busca na FIPE que DEVOLVE a seleção (não salva nada). Usada pelo
/// cadastro do veículo para preencher marca/modelo/ano/combustível.
class FipePickerScreen extends ConsumerStatefulWidget {
  const FipePickerScreen({super.key});

  @override
  ConsumerState<FipePickerScreen> createState() => _FipePickerScreenState();
}

class _FipePickerScreenState extends ConsumerState<FipePickerScreen> {
  FipeSelecao? _sel;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.buscarNaFipe)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(t.selecioneMarcaModeloAno,
              style: TextStyle(color: AppColors.dim, fontSize: 13)),
          const SizedBox(height: 14),
          FipeSeletor(onSelecao: (s) => setState(() => _sel = s)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _sel == null
                ? null
                : () => Navigator.of(context).pop(_sel),
            icon: const Icon(Icons.check),
            label: Text(t.usarEstesDados),
          ),
        ],
      ),
    );
  }
}
