import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/calibragem.dart';
import '../../models/veiculo.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';
import '../../util/ids.dart';
import '../../widgets/stepper_num.dart';

class CalibragemScreen extends ConsumerWidget {
  const CalibragemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Veiculo? v = ref.watch(veiculoSelecionadoProvider);
    final log = [...(ref.watch(calibragemDoVeiculoProvider))]
      ..sort((a, b) => b.data.compareTo(a.data));
    final ultima = log.isNotEmpty ? log.first : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Calibragem')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirSheet(context, _RegistrarSheet(veiculo: v)),
        backgroundColor: AppColors.catCalibragem,
        foregroundColor: const Color(0xFF04221E),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _CartaoPressao(
            veiculo: v,
            onEditar: v == null
                ? null
                : () => _abrirSheet(context, _EditarPressaoSheet(veiculo: v)),
          ),
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

  Future<void> _abrirSheet(BuildContext context, Widget sheet) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => sheet,
    );
  }
}

class _CartaoPressao extends StatelessWidget {
  final Veiculo? veiculo;
  final VoidCallback? onEditar;
  const _CartaoPressao({required this.veiculo, required this.onEditar});

  @override
  Widget build(BuildContext context) {
    if (veiculo == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(children: [
            Icon(Icons.info_outline, color: AppColors.catCalibragem),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cadastre o carro (tela inicial) para definir a calibragem '
                'recomendada aqui.',
                style: TextStyle(color: AppColors.dim, fontSize: 13),
              ),
            ),
          ]),
        ),
      );
    }
    final semPressao = veiculo!.pressaoDianteira == null &&
        veiculo!.pressaoTraseira == null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Calibragem recomendada',
                      style: TextStyle(color: AppColors.dim, fontSize: 13)),
                ),
                TextButton.icon(
                  onPressed: onEditar,
                  icon: Icon(semPressao ? Icons.add : Icons.edit_outlined,
                      size: 18),
                  label: Text(semPressao ? 'Definir' : 'Editar'),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.catCalibragem),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (semPressao)
              const Text('Toque em "Definir" e ajuste com − / +.',
                  style: TextStyle(color: AppColors.dim2, fontSize: 12.5))
            else
              Row(
                children: [
                  Expanded(child: _pneu('Dianteiro', veiculo!.pressaoDianteira)),
                  Container(width: 1, height: 46, color: AppColors.line),
                  Expanded(child: _pneu('Traseiro', veiculo!.pressaoTraseira)),
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
    final dias = u != null ? DateTime.now().difference(u.data).inDays : null;
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

/// Define a pressão RECOMENDADA (salva no veículo), com − / +.
class _EditarPressaoSheet extends ConsumerStatefulWidget {
  final Veiculo veiculo;
  const _EditarPressaoSheet({required this.veiculo});

  @override
  ConsumerState<_EditarPressaoSheet> createState() =>
      _EditarPressaoSheetState();
}

class _EditarPressaoSheetState extends ConsumerState<_EditarPressaoSheet> {
  late double _dianteira;
  late double _traseira;

  @override
  void initState() {
    super.initState();
    _dianteira = widget.veiculo.pressaoDianteira ?? 32;
    _traseira = widget.veiculo.pressaoTraseira ?? 32;
  }

  Future<void> _salvar() async {
    await ref.read(veiculosProvider.notifier).salvar(widget.veiculo.copyWith(
          pressaoDianteira: _dianteira,
          pressaoTraseira: _traseira,
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
          const Text('Calibragem recomendada',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: StepperNum(
                label: 'Dianteiro',
                valor: _dianteira,
                sufixo: 'psi',
                cor: AppColors.catCalibragem,
                onChanged: (v) => setState(() => _dianteira = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StepperNum(
                label: 'Traseiro',
                valor: _traseira,
                sufixo: 'psi',
                cor: AppColors.catCalibragem,
                onChanged: (v) => setState(() => _traseira = v),
              ),
            ),
          ]),
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

/// Registra uma calibragem feita (com − / + e data).
class _RegistrarSheet extends ConsumerStatefulWidget {
  final Veiculo? veiculo;
  const _RegistrarSheet({required this.veiculo});

  @override
  ConsumerState<_RegistrarSheet> createState() => _RegistrarSheetState();
}

class _RegistrarSheetState extends ConsumerState<_RegistrarSheet> {
  late double _dianteira;
  late double _traseira;
  final _obs = TextEditingController();
  DateTime _data = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dianteira = widget.veiculo?.pressaoDianteira ?? 32;
    _traseira = widget.veiculo?.pressaoTraseira ?? 32;
  }

  @override
  void dispose() {
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
          veiculoId: ref.read(veiculoSelecionadoProvider)?.id,
          data: _data,
          pressaoDianteira: _dianteira,
          pressaoTraseira: _traseira,
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
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: StepperNum(
                label: 'Dianteiro',
                valor: _dianteira,
                sufixo: 'psi',
                cor: AppColors.catCalibragem,
                onChanged: (v) => setState(() => _dianteira = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StepperNum(
                label: 'Traseiro',
                valor: _traseira,
                sufixo: 'psi',
                cor: AppColors.catCalibragem,
                onChanged: (v) => setState(() => _traseira = v),
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
