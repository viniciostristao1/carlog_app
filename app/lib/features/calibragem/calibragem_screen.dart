import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/calibragem.dart';
import '../../models/veiculo.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';
import '../../util/ids.dart';

class CalibragemScreen extends ConsumerWidget {
  const CalibragemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Veiculo? v = ref.watch(veiculoProvider).value;
    final log = [...(ref.watch(calibragemProvider).value ?? const [])]
      ..sort((a, b) => b.data.compareTo(a.data));
    final ultima = log.isNotEmpty ? log.first : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Calibragem')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _registrar(context, ref, v),
        backgroundColor: AppColors.catCalibragem,
        foregroundColor: const Color(0xFF04221E),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _CartaoPressao(veiculo: v),
          const SizedBox(height: 14),
          _CartaoUltima(ultima: ultima),
          const SizedBox(height: 20),
          if (log.isNotEmpty) ...[
            const Text('Histórico',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...log.map((c) => _LinhaCalibragem(
                  c: c,
                  onExcluir: () =>
                      ref.read(calibragemProvider.notifier).remover(c.id),
                )),
          ],
        ],
      ),
    );
  }

  Future<void> _registrar(
      BuildContext context, WidgetRef ref, Veiculo? v) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RegistrarSheet(veiculo: v),
    );
  }
}

class _CartaoPressao extends StatelessWidget {
  final Veiculo? veiculo;
  const _CartaoPressao({required this.veiculo});

  @override
  Widget build(BuildContext context) {
    final temPressao = veiculo?.pressaoDianteira != null ||
        veiculo?.pressaoTraseira != null;
    if (!temPressao) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(children: [
            Icon(Icons.info_outline, color: AppColors.catCalibragem),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Defina a calibragem recomendada no cadastro do carro (tela '
                'inicial → cartão do veículo) para vê-la aqui.',
                style: TextStyle(color: AppColors.dim, fontSize: 13),
              ),
            ),
          ]),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Calibragem recomendada',
                style: TextStyle(color: AppColors.dim, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _pneu('Dianteiro', veiculo?.pressaoDianteira)),
                Container(width: 1, height: 46, color: AppColors.line),
                Expanded(
                    child: _pneu('Traseiro', veiculo?.pressaoTraseira)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pneu(String r, double? psi) => Column(
        children: [
          Text(psi != null ? n1(psi) : '—',
              style: const TextStyle(
                  color: AppColors.catCalibragem,
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
          const Text('psi',
              style: TextStyle(color: AppColors.dim, fontSize: 12)),
          const SizedBox(height: 4),
          Text(r, style: const TextStyle(color: AppColors.dim2, fontSize: 12)),
        ],
      );
}

class _CartaoUltima extends StatelessWidget {
  final Calibragem? ultima;
  const _CartaoUltima({required this.ultima});

  @override
  Widget build(BuildContext context) {
    final u = ultima;
    final dias = u != null
        ? DateTime.now().difference(u.data).inDays
        : null;
    final alerta = dias != null && dias >= 30;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(alerta ? Icons.warning_amber_rounded : Icons.tire_repair,
                color: alerta ? AppColors.warn : AppColors.catCalibragem),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Última calibragem',
                      style: TextStyle(color: AppColors.dim, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    u != null
                        ? '${dataLonga(u.data)} (${desdeAte(u.data)})'
                        : 'Ainda não registrada',
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                  if (alerta) ...[
                    const SizedBox(height: 2),
                    const Text('Já faz um tempo — vale calibrar.',
                        style: TextStyle(color: AppColors.warn, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaCalibragem extends StatelessWidget {
  final Calibragem c;
  final VoidCallback onExcluir;
  const _LinhaCalibragem({required this.c, required this.onExcluir});

  @override
  Widget build(BuildContext context) {
    final pressoes = [
      if (c.pressaoDianteira != null) 'D ${n1(c.pressaoDianteira!)}',
      if (c.pressaoTraseira != null) 'T ${n1(c.pressaoTraseira!)}',
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.tire_repair, color: AppColors.catCalibragem, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dataLonga(c.data),
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                if (pressoes.isNotEmpty || c.observacao.isNotEmpty)
                  Text(
                    [if (pressoes.isNotEmpty) '$pressoes psi', c.observacao]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: const TextStyle(color: AppColors.dim, fontSize: 12.5),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.dim2),
            onPressed: onExcluir,
          ),
        ],
      ),
    );
  }
}

class _RegistrarSheet extends ConsumerStatefulWidget {
  final Veiculo? veiculo;
  const _RegistrarSheet({required this.veiculo});

  @override
  ConsumerState<_RegistrarSheet> createState() => _RegistrarSheetState();
}

class _RegistrarSheetState extends ConsumerState<_RegistrarSheet> {
  late final TextEditingController _dianteira;
  late final TextEditingController _traseira;
  final _obs = TextEditingController();
  DateTime _data = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dianteira = TextEditingController(
        text: widget.veiculo?.pressaoDianteira != null
            ? n1(widget.veiculo!.pressaoDianteira!)
            : '');
    _traseira = TextEditingController(
        text: widget.veiculo?.pressaoTraseira != null
            ? n1(widget.veiculo!.pressaoTraseira!)
            : '');
  }

  @override
  void dispose() {
    _dianteira.dispose();
    _traseira.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _data = d);
  }

  Future<void> _salvar() async {
    await ref.read(calibragemProvider.notifier).salvar(Calibragem(
          id: novoId(),
          data: _data,
          pressaoDianteira: parseNumero(_dianteira.text),
          pressaoTraseira: parseNumero(_traseira.text),
          observacao: _obs.text.trim(),
        ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registrar calibragem',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          InkWell(
            onTap: _escolherData,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(children: [
                const Icon(Icons.event, color: AppColors.dim, size: 20),
                const SizedBox(width: 12),
                Text(dataLonga(_data),
                    style: const TextStyle(
                        color: AppColors.text, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _dianteira,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Dianteiro (psi)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _traseira,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Traseiro (psi)'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _obs,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Observação (opcional)'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _salvar,
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.catCalibragem,
                foregroundColor: const Color(0xFF04221E)),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
