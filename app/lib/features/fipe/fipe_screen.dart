import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/veiculo.dart';
import '../../services/prefs.dart';
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
    final atual = ref.read(veiculoSelecionadoProvider);
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
    await ref.read(veiculosProvider.notifier).salvar(v);
    if (mounted) {
      final t = ref.read(stringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(atual == null
              ? t.carroCadastradoFipe
              : t.veiculoAtualizadoFipe)));
    }
  }

  Future<void> _informarManual() async {
    final t = ref.read(stringsProvider);
    final atual = ref.read(veiculoSelecionadoProvider);
    final ctrl = TextEditingController(
        text: atual?.fipeValor != null ? n2(atual!.fipeValor!) : '');
    final valor = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(t.informarValorManual),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
          ],
          decoration: InputDecoration(
              labelText: t.valorRs, hintText: t.valorHint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.cancelar)),
          TextButton(
            onPressed: () => Navigator.pop(context, parseNumero(ctrl.text)),
            child: Text(t.salvar),
          ),
        ],
      ),
    );
    if (valor != null) {
      final base = atual ?? Veiculo(id: novoId(), apelido: '');
      await ref.read(veiculosProvider.notifier).salvar(base.copyWith(
            fipeValor: valor,
            fipeMesRef: t.informadoManualmente,
            fipeConsultadoEm: DateTime.now(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final Veiculo? v = ref.watch(veiculoSelecionadoProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.minhaFipe)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (v?.fipeValor != null) _CartaoValorSalvo(veiculo: v!),
          if (v?.fipeValor != null) const SizedBox(height: 16),
          Text(t.consultarFipe,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
              t.consultarFipeSub,
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
                label: Text(t.usarComoMeuCarro),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _informarManual,
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.leg(AppColors.catFipe),
                side: BorderSide(color: AppColors.leg(AppColors.catFipe)),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.edit_outlined),
            label: Text(t.informarValorManual),
          ),
        ],
      ),
    );
  }
}

class _CartaoValorSalvo extends ConsumerWidget {
  final Veiculo veiculo;
  const _CartaoValorSalvo({required this.veiculo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.valorAtualVeiculo,
                style: TextStyle(color: AppColors.dim, fontSize: 13)),
            const SizedBox(height: 6),
            Text(moeda(veiculo.fipeValor!),
                style: TextStyle(
                    color: AppColors.leg(AppColors.catFipe),
                    fontSize: 30,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              [
                if ((veiculo.fipeMesRef ?? '').isNotEmpty)
                  t.refPrefixo(veiculo.fipeMesRef!),
                if (veiculo.fipeConsultadoEm != null)
                  t.emData(dataCurta(veiculo.fipeConsultadoEm!)),
              ].join(' · '),
              style: TextStyle(color: AppColors.dim2, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
