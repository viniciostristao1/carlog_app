import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/abastecimento.dart';
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
    final lista = [...(ref.watch(abastecimentosProvider).value ?? const [])]
      ..sort((a, b) => b.data.compareTo(a.data));

    final agora = DateTime.now();
    final doMes = lista.where(
        (a) => a.data.year == agora.year && a.data.month == agora.month);
    final gastoMes = doMes.fold<double>(0, (s, a) => s + a.total);
    final litrosMes = doMes.fold<double>(0, (s, a) => s + a.litros);

    return Scaffold(
      appBar: AppBar(title: const Text('Abastecimentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _novo(context),
        backgroundColor: AppColors.catAbastecimento,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Abastecer'),
      ),
      body: lista.isEmpty
          ? const EstadoVazio(
              icone: Icons.local_gas_station,
              titulo: 'Nenhum abastecimento ainda',
              subtitulo:
                  'Toque em "Abastecer" para registrar litros, preço e odômetro. '
                  'Com dois tanques cheios o app já calcula sua média.',
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

class _ResumoMes extends StatelessWidget {
  final double gasto;
  final double litros;
  final int n;
  const _ResumoMes({required this.gasto, required this.litros, required this.n});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _stat('Gasto no mês', moeda(gasto))),
            Container(width: 1, height: 34, color: AppColors.line),
            Expanded(child: _stat('Litros', litros > 0 ? litros.toStringAsFixed(0) : '0')),
            Container(width: 1, height: 34, color: AppColors.line),
            Expanded(child: _stat('Abastec.', '$n')),
          ],
        ),
      ),
    );
  }

  Widget _stat(String r, String v) => Column(
        children: [
          Text(v,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(r, style: const TextStyle(color: AppColors.dim2, fontSize: 11.5)),
        ],
      );
}

class _CartaoAbastecimento extends StatelessWidget {
  final Abastecimento a;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  const _CartaoAbastecimento({
    required this.a,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
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
                title: const Text('Excluir abastecimento?'),
                content: Text('${dataLonga(a.data)} · ${litros(a.litros)}'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Excluir',
                          style: TextStyle(color: AppColors.danger))),
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
                      color: AppColors.catAbastecimento,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${litros(a.litros)}  ·  ${reais2(a.precoLitro)}/L',
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [dataCurta(a.data), km(a.odometro)].join(' · '),
                          style: const TextStyle(
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
                              style: const TextStyle(
                                  color: AppColors.dim2, fontSize: 10.5)),
                        ),
                      Text(moeda(a.total),
                          style: const TextStyle(
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
