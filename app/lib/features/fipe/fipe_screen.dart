import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/veiculo.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';
import '../../util/ids.dart';
import 'fipe_seletor.dart';

class FipeScreen extends ConsumerStatefulWidget {
  const FipeScreen({super.key});

  @override
  ConsumerState<FipeScreen> createState() => _FipeScreenState();
}

class _FipeScreenState extends ConsumerState<FipeScreen> {
  FipeSelecao? _sel;

  Future<void> _salvarNoVeiculo() async {
    final sel = _sel;
    if (sel == null) return;
    final r = sel.resultado;
    final atual = ref.read(veiculoProvider).value;
    final anoInt = int.tryParse(r.anoModelo);
    final ano = (anoInt != null && anoInt <= 2100) ? anoInt : atual?.ano;
    final base = atual ?? Veiculo(id: novoId(), apelido: '');
    final v = base.copyWith(
      marca: r.marca,
      modelo: r.modelo,
      ano: ano,
      combustivel: combustivelDaFipe(r.combustivel),
      fipeCodigo: r.codigoFipe,
      fipeCodigoTabela: sel.codigoTabela,
      fipeValor: r.valor,
      fipeMesRef: r.mesReferencia,
      fipeConsultadoEm: DateTime.now(),
    );
    await ref.read(veiculoProvider.notifier).salvar(v);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(atual == null
              ? 'Carro cadastrado pela FIPE. Adicione a placa no cartão do veículo.'
              : 'Veículo atualizado pela FIPE.')));
    }
  }

  Future<void> _informarManual() async {
    final atual = ref.read(veiculoProvider).value;
    final ctrl = TextEditingController(
        text: atual?.fipeValor != null ? n2(atual!.fipeValor!) : '');
    final valor = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Informar valor manualmente'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
          ],
          decoration: const InputDecoration(
              labelText: 'Valor (R\$)', hintText: 'Ex.: 45000'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, parseNumero(ctrl.text)),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (valor != null) {
      final base = atual ?? Veiculo(id: novoId(), apelido: '');
      await ref.read(veiculoProvider.notifier).salvar(base.copyWith(
            fipeValor: valor,
            fipeMesRef: 'informado manualmente',
            fipeConsultadoEm: DateTime.now(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Veiculo? v = ref.watch(veiculoProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Minha FIPE')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (v?.fipeValor != null) _CartaoValorSalvo(veiculo: v!),
          if (v?.fipeValor != null) const SizedBox(height: 16),
          const Text('Consultar tabela FIPE',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
              'Selecione marca, modelo e ano — dá para cadastrar o carro por aqui.',
              style: TextStyle(color: AppColors.dim, fontSize: 13)),
          const SizedBox(height: 14),
          FipeSeletor(onSelecao: (s) => setState(() => _sel = s)),
          const SizedBox(height: 16),
          if (_sel != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _salvarNoVeiculo,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.catFipe,
                    foregroundColor: const Color(0xFF160A2B)),
                icon: const Icon(Icons.directions_car_filled_outlined),
                label: const Text('Usar como meu carro'),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _informarManual,
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.catFipe,
                side: const BorderSide(color: AppColors.catFipe),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Informar valor manualmente'),
          ),
        ],
      ),
    );
  }
}

class _CartaoValorSalvo extends StatelessWidget {
  final Veiculo veiculo;
  const _CartaoValorSalvo({required this.veiculo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Valor atual do veículo',
                style: TextStyle(color: AppColors.dim, fontSize: 13)),
            const SizedBox(height: 6),
            Text(moeda(veiculo.fipeValor!),
                style: const TextStyle(
                    color: AppColors.catFipe,
                    fontSize: 30,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              [
                if ((veiculo.fipeMesRef ?? '').isNotEmpty)
                  'Ref.: ${veiculo.fipeMesRef}',
                if (veiculo.fipeConsultadoEm != null)
                  'em ${dataCurta(veiculo.fipeConsultadoEm!)}',
              ].join(' · '),
              style: const TextStyle(color: AppColors.dim2, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
