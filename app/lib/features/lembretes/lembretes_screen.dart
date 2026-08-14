import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/lembrete.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';
import '../../util/ids.dart';
import '../../widgets/estado_vazio.dart';

class LembretesScreen extends ConsumerWidget {
  const LembretesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = [...(ref.watch(lembretesDoVeiculoProvider))]
      ..sort((a, b) {
        if (a.pago != b.pago) return a.pago ? 1 : -1;
        return a.vencimento.compareTo(b.vencimento);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Lembretes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirForm(context, ref),
        backgroundColor: AppColors.catLembretes,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo'),
      ),
      body: lista.isEmpty
          ? const EstadoVazio(
              icone: Icons.event_available_outlined,
              titulo: 'Sem lembretes',
              subtitulo:
                  'Cadastre vencimentos de IPVA, seguro, licenciamento e afins. '
                  'O app mostra quantos dias faltam.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: lista
                  .map((l) => _CartaoLembrete(
                        l: l,
                        onEditar: () => _abrirForm(context, ref, original: l),
                        onPago: () => _marcarPago(ref, l),
                        onExcluir: () =>
                            ref.read(lembretesProvider.notifier).remover(l.id),
                      ))
                  .toList(),
            ),
    );
  }

  void _marcarPago(WidgetRef ref, Lembrete l) {
    final notifier = ref.read(lembretesProvider.notifier);
    if (l.recorrencia == Recorrencia.nenhuma) {
      notifier.salvar(l.copyWith(pago: !l.pago));
    } else {
      // Recorrente: empurra o vencimento para o próximo período e segue ativo.
      notifier.salvar(l.copyWith(
        vencimento: _proximo(l.vencimento, l.recorrencia),
        pago: false,
      ));
    }
  }

  static DateTime _proximo(DateTime d, Recorrencia r) => switch (r) {
        Recorrencia.mensal => DateTime(d.year, d.month + 1, d.day),
        Recorrencia.anual => DateTime(d.year + 1, d.month, d.day),
        Recorrencia.nenhuma => d,
      };

  Future<void> _abrirForm(BuildContext context, WidgetRef ref,
      {Lembrete? original}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LembreteFormSheet(original: original),
    );
  }
}

class _CartaoLembrete extends StatelessWidget {
  final Lembrete l;
  final VoidCallback onEditar;
  final VoidCallback onPago;
  final VoidCallback onExcluir;
  const _CartaoLembrete({
    required this.l,
    required this.onEditar,
    required this.onPago,
    required this.onExcluir,
  });

  Color _corPrazo(int dias) {
    if (dias < 0) return AppColors.danger;
    if (dias <= 15) return AppColors.warn;
    return AppColors.dim;
  }

  @override
  Widget build(BuildContext context) {
    final dias = DateTime(l.vencimento.year, l.vencimento.month, l.vencimento.day)
        .difference(DateTime.now())
        .inDays;
    final cor = l.pago ? AppColors.dim2 : _corPrazo(dias);

    return Dismissible(
      key: ValueKey(l.id),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.catLembretes.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(l.tipo.rotulo,
                        style: const TextStyle(
                            color: AppColors.catLembretes,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.titulo.isNotEmpty ? l.titulo : l.tipo.rotulo,
                          style: TextStyle(
                            color: l.pago ? AppColors.dim : AppColors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            decoration:
                                l.pago ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l.pago
                              ? 'Pago'
                              : '${dataCurta(l.vencimento)} · ${desdeAte(l.vencimento)}',
                          style: TextStyle(color: cor, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  if (l.valor != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(moeda(l.valor!),
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  IconButton(
                    tooltip: l.recorrencia == Recorrencia.nenhuma
                        ? 'Marcar pago'
                        : 'Pago — próximo período',
                    icon: Icon(
                      l.pago
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: l.pago ? AppColors.ok : AppColors.dim,
                    ),
                    onPressed: onPago,
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

class _LembreteFormSheet extends ConsumerStatefulWidget {
  final Lembrete? original;
  const _LembreteFormSheet({this.original});

  @override
  ConsumerState<_LembreteFormSheet> createState() => _LembreteFormSheetState();
}

class _LembreteFormSheetState extends ConsumerState<_LembreteFormSheet> {
  late final TextEditingController _titulo;
  late final TextEditingController _valor;
  late TipoLembrete _tipo;
  late Recorrencia _recorrencia;
  late DateTime _vencimento;

  @override
  void initState() {
    super.initState();
    final o = widget.original;
    _titulo = TextEditingController(text: o?.titulo ?? '');
    _valor = TextEditingController(text: o?.valor != null ? n2(o!.valor!) : '');
    _tipo = o?.tipo ?? TipoLembrete.ipva;
    _recorrencia = o?.recorrencia ?? Recorrencia.anual;
    _vencimento = o?.vencimento ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _titulo.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _vencimento,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _vencimento = d);
  }

  Future<void> _salvar() async {
    final l = Lembrete(
      id: widget.original?.id ?? novoId(),
      veiculoId:
          widget.original?.veiculoId ?? ref.read(veiculoSelecionadoProvider)?.id,
      tipo: _tipo,
      titulo: _titulo.text.trim(),
      vencimento: _vencimento,
      valor: parseNumero(_valor.text),
      recorrencia: _recorrencia,
      pago: widget.original?.pago ?? false,
      observacao: widget.original?.observacao ?? '',
    );
    await ref.read(lembretesProvider.notifier).salvar(l);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.original == null ? 'Novo lembrete' : 'Lembrete',
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TipoLembrete.values.map((t) {
                final sel = t == _tipo;
                return ChoiceChip(
                  label: Text(t.rotulo),
                  selected: sel,
                  onSelected: (_) => setState(() => _tipo = t),
                  selectedColor: AppColors.catLembretes.withValues(alpha: 0.25),
                  backgroundColor: AppColors.surface2,
                  labelStyle: TextStyle(
                      color: sel ? AppColors.catLembretes : AppColors.dim,
                      fontWeight: FontWeight.w600),
                  side: BorderSide(
                      color: sel ? AppColors.catLembretes : AppColors.line),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titulo,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Título (opcional)',
                  hintText: 'Ex.: IPVA 2026 — cota única'),
            ),
            const SizedBox(height: 12),
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
                  Text('Vence em ${dataLonga(_vencimento)}',
                      style: const TextStyle(
                          color: AppColors.text, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valor,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Valor (R\$, opcional)'),
            ),
            const SizedBox(height: 14),
            const Text('Repetição',
                style: TextStyle(
                    color: AppColors.dim,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Recorrencia.values.map((r) {
                final sel = r == _recorrencia;
                return ChoiceChip(
                  label: Text(r.rotulo),
                  selected: sel,
                  onSelected: (_) => setState(() => _recorrencia = r),
                  selectedColor: AppColors.accent.withValues(alpha: 0.22),
                  backgroundColor: AppColors.surface2,
                  labelStyle: TextStyle(
                      color: sel ? AppColors.accent : AppColors.dim,
                      fontWeight: FontWeight.w600),
                  side: BorderSide(
                      color: sel ? AppColors.accent : AppColors.line),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _salvar,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.catLembretes,
                  foregroundColor: Colors.white),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
