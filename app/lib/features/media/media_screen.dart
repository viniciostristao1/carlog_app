import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/media_manual.dart';
import '../../services/prefs.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/consumo.dart';
import '../../util/format.dart';
import '../../util/ids.dart';

class MediaScreen extends ConsumerWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final abastecimentos = ref.watch(abastecimentosDoVeiculoProvider);
    final resumo = calcularConsumo(abastecimentos);
    final medias = ref.watch(mediasDoVeiculoProvider);
    final agora = DateTime.now();
    final kmMes = kmRodadosNoMes(abastecimentos, agora.year, agora.month);
    final kmMesAnt = kmRodadosNoMes(
        abastecimentos, agora.month == 1 ? agora.year - 1 : agora.year,
        agora.month == 1 ? 12 : agora.month - 1);

    return Scaffold(
      appBar: AppBar(title: Text(t.consumoMedia)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirCalculadora(context, ref),
        backgroundColor: AppColors.catConsumo,
        foregroundColor: const Color(0xFF04231A),
        icon: const Icon(Icons.calculate_outlined),
        label: Text(t.calcularMedia),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _CartaoMediaGeral(resumo: resumo),
          const SizedBox(height: 14),
          _CartaoKmMes(kmMes: kmMes, kmMesAnterior: kmMesAnt),
          const SizedBox(height: 20),
          _tituloSecao(t.mediaAvulsa),
          const SizedBox(height: 6),
          _ResumoManual(medias: medias),
          const SizedBox(height: 10),
          if (medias.isNotEmpty)
            ...(_ordenar(medias)).map((m) => _CartaoManual(
                  m: m,
                  onExcluir: () =>
                      ref.read(mediasProvider.notifier).remover(m.id),
                )),
          if (resumo.trechos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _tituloSecao(t.trechos),
            const SizedBox(height: 6),
            ...resumo.trechos.map((tr) => _CartaoTrecho(t: tr)),
          ],
        ],
      ),
    );
  }

  List<MediaManual> _ordenar(List<MediaManual> m) =>
      [...m]..sort((a, b) => b.data.compareTo(a.data));

  Widget _tituloSecao(String t) => Text(t,
      style: TextStyle(
          color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700));

  Future<void> _abrirCalculadora(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _CalculadoraSheet(),
    );
  }
}

class _CartaoMediaGeral extends ConsumerWidget {
  final ResumoConsumo resumo;
  const _CartaoMediaGeral({required this.resumo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    if (!resumo.temMedia) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.speed, color: AppColors.catConsumo, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  t.semMediaAinda,
                  style: TextStyle(color: AppColors.dim, fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.mediaGeral,
                style: TextStyle(color: AppColors.dim, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(n1(resumo.mediaGeral!),
                    style: TextStyle(
                        color: AppColors.leg(AppColors.catConsumo),
                        fontSize: 32,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('km/L',
                      style: TextStyle(
                          color: AppColors.dim,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _mini(t.melhor, kmL(resumo.melhor!),
                        AppColors.leg(AppColors.ok))),
                Expanded(
                    child: _mini(t.pior, kmL(resumo.pior!),
                        AppColors.leg(AppColors.warn))),
                Expanded(
                    child: _mini(t.totalGasto, moeda(resumo.totalGasto),
                        AppColors.text)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(String r, String v, Color cor) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v,
              style: TextStyle(
                  color: cor, fontSize: 14.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(r, style: TextStyle(color: AppColors.dim2, fontSize: 11.5)),
        ],
      );
}

class _CartaoKmMes extends ConsumerWidget {
  final double kmMes;
  final double kmMesAnterior;
  const _CartaoKmMes({required this.kmMes, required this.kmMesAnterior});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: AppColors.catConsumo),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.kmRodadosMes,
                      style: TextStyle(color: AppColors.dim, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(kmMes > 0 ? km(kmMes) : '—',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            if (kmMesAnterior > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(t.mesAnterior,
                      style: TextStyle(color: AppColors.dim2, fontSize: 11.5)),
                  const SizedBox(height: 2),
                  Text(km(kmMesAnterior),
                      style: TextStyle(
                          color: AppColors.dim,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ResumoManual extends ConsumerWidget {
  final List<MediaManual> medias;
  const _ResumoManual({required this.medias});

  double? _mediaDe(TipoTrecho tipo) {
    final ms = medias.where((m) => m.tipo == tipo && m.litros > 0);
    if (ms.isEmpty) return null;
    final km = ms.fold<double>(0, (s, m) => s + m.km);
    final l = ms.fold<double>(0, (s, m) => s + m.litros);
    return l > 0 ? km / l : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    if (medias.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            t.usarCalcularMedia,
            style: TextStyle(color: AppColors.dim, fontSize: 13.5),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            for (final tipo in TipoTrecho.values) ...[
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _mediaDe(tipo) != null ? kmL(_mediaDe(tipo)!) : '—',
                      style: TextStyle(
                          color: AppColors.leg(AppColors.catConsumo),
                          fontSize: 15,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(t.rotuloTipoTrecho(tipo),
                        style: TextStyle(
                            color: AppColors.dim2, fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartaoManual extends ConsumerWidget {
  final MediaManual m;
  final VoidCallback onExcluir;
  const _CartaoManual({required this.m, required this.onExcluir});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.catConsumo.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(t.rotuloTipoTrecho(m.tipo),
                style: TextStyle(
                    color: AppColors.leg(AppColors.catConsumo),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${n0(m.km)} km · ${n1(m.litros)} L · ${dataCurta(m.data)}',
                style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
          ),
          Text(kmL(m.kmPorLitro),
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: AppColors.dim2),
            onPressed: onExcluir,
          ),
        ],
      ),
    );
  }
}

class _CartaoTrecho extends StatelessWidget {
  final TrechoConsumo t;
  const _CartaoTrecho({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${n0(t.distancia)} km · ${n1(t.litros)} L',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${dataCurta(t.dataInicio)} → ${dataCurta(t.dataFim)}',
                    style:
                        TextStyle(color: AppColors.dim2, fontSize: 12)),
              ],
            ),
          ),
          Text(kmL(t.kmPorLitro),
              style: TextStyle(
                  color: AppColors.leg(AppColors.catConsumo),
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Bottom sheet: calcula e salva uma média avulsa.
class _CalculadoraSheet extends ConsumerStatefulWidget {
  const _CalculadoraSheet();

  @override
  ConsumerState<_CalculadoraSheet> createState() => _CalculadoraSheetState();
}

class _CalculadoraSheetState extends ConsumerState<_CalculadoraSheet> {
  final _km = TextEditingController();
  final _litros = TextEditingController();
  TipoTrecho _tipo = TipoTrecho.misto;

  @override
  void initState() {
    super.initState();
    for (final c in [_km, _litros]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _km.dispose();
    _litros.dispose();
    super.dispose();
  }

  double? get _resultado {
    final k = parseNumero(_km.text);
    final l = parseNumero(_litros.text);
    if (k == null || l == null || l <= 0) return null;
    return k / l;
  }

  Future<void> _salvar() async {
    final k = parseNumero(_km.text);
    final l = parseNumero(_litros.text);
    if (k == null || l == null || l <= 0) return;
    await ref.read(mediasProvider.notifier).salvar(MediaManual(
          id: novoId(),
          veiculoId: ref.read(veiculoSelecionadoProvider)?.id,
          data: DateTime.now(),
          km: k,
          litros: l,
          tipo: _tipo,
        ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final r = _resultado;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.calcularMedia,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _km,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: t.kmPercorridos),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _litros,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: t.litrosGastos),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: TipoTrecho.values.map((tipo) {
              final sel = tipo == _tipo;
              return ChoiceChip(
                label: Text(t.rotuloTipoTrecho(tipo)),
                selected: sel,
                onSelected: (_) => setState(() => _tipo = tipo),
                selectedColor: AppColors.catConsumo.withValues(alpha: 0.25),
                backgroundColor: AppColors.surface2,
                labelStyle: TextStyle(
                    color: sel ? AppColors.catConsumo : AppColors.dim,
                    fontWeight: FontWeight.w600),
                side: BorderSide(
                    color: sel ? AppColors.catConsumo : AppColors.line),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              r != null ? kmL(r) : '—',
              style: TextStyle(
                  color: AppColors.leg(AppColors.catConsumo),
                  fontSize: 34,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: r != null ? _salvar : null,
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.catConsumo,
                foregroundColor: const Color(0xFF04231A)),
            child: Text(t.salvarMedicao),
          ),
        ],
      ),
    );
  }
}
