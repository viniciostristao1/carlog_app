import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/abastecimento.dart';
import '../../services/prefs.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';
import '../../widgets/estado_vazio.dart';
import 'abastecimento_form_screen.dart';

class AbastecimentoScreen extends ConsumerWidget {
  const AbastecimentoScreen({super.key});

  void _novo(BuildContext context, {Abastecimento? original}) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AbastecimentoFormScreen(original: original)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final lista = [...(ref.watch(abastecimentosDoVeiculoProvider))]
      ..sort((a, b) => b.data.compareTo(a.data));

    final agora = DateTime.now();
    final doMes = lista.where(
        (a) => a.data.year == agora.year && a.data.month == agora.month);
    final gastoMes = doMes.fold<double>(0, (s, a) => s + a.total);
    final litrosMes = doMes.fold<double>(0, (s, a) => s + (a.litros ?? 0));

    return Scaffold(
      appBar: AppBar(title: Text(t.abastecimentos)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _novo(context),
        backgroundColor: AppColors.catAbastecimento,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(t.abastecer),
      ),
      body: lista.isEmpty
          ? EstadoVazio(
              icone: Icons.local_gas_station,
              titulo: t.semAbastecimento,
              subtitulo: t.semAbastecimentoSub,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                _ResumoMes(gasto: gastoMes, litros: litrosMes, n: doMes.length),
                const SizedBox(height: 16),
                ...lista.map((a) => _CartaoAbastecimento(
                      a: a,
                      onEditar: () => _novo(context, original: a),
                      onExcluir: () => ref
                          .read(abastecimentosProvider.notifier)
                          .remover(a.id),
                    )),
              ],
            ),
    );
  }
}

class _ResumoMes extends ConsumerWidget {
  final double gasto;
  final double litros;
  final int n;
  const _ResumoMes({required this.gasto, required this.litros, required this.n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _stat(t.gastoNoMes, moeda(gasto))),
            Container(width: 1, height: 34, color: AppColors.line),
            Expanded(child: _stat(t.litrosLabel, litros > 0 ? litros.toStringAsFixed(0) : '0')),
            Container(width: 1, height: 34, color: AppColors.line),
            Expanded(child: _stat(t.abastecAbrev, '$n')),
          ],
        ),
      ),
    );
  }

  Widget _stat(String r, String v) => Column(
        children: [
          Text(v,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(r, style: TextStyle(color: AppColors.dim2, fontSize: 11.5)),
        ],
      );
}

class _CartaoAbastecimento extends ConsumerWidget {
  final Abastecimento a;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  const _CartaoAbastecimento({
    required this.a,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Dismissible(
      key: ValueKey(a.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: Text(t.excluirAbastecimento),
                content: Text([
                  dataLonga(a.data),
                  if (a.litros != null) litros(a.litros!),
                ].join(' · ')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(t.cancelar)),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(t.excluir,
                          style: const TextStyle(color: AppColors.danger))),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onExcluir(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onEditar,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.catAbastecimento.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      a.tanqueCheio
                          ? Icons.local_gas_station
                          : Icons.local_gas_station_outlined,
                      color: AppColors.leg(AppColors.catAbastecimento),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            if (a.litros != null) litros(a.litros!),
                            if (a.precoLitro != null)
                              '${reais2(a.precoLitro!)}/L',
                          ].join('  ·  ').ou(t.abastecimento),
                          style: TextStyle(
                              color: AppColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            dataCurta(a.data),
                            if (a.odometro != null) km(a.odometro!),
                          ].join(' · '),
                          style: TextStyle(
                              color: AppColors.dim, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (a.posto.trim().isNotEmpty)
                        SizedBox(
                          width: 96,
                          child: Text(a.posto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: AppColors.dim2, fontSize: 10.5)),
                        ),
                      if (a.litros != null && a.precoLitro != null)
                        Text(moeda(a.total),
                            style: TextStyle(
                                color: AppColors.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
