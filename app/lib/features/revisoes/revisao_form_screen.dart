import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/revisao.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';
import '../../util/ids.dart';

class RevisaoFormScreen extends ConsumerStatefulWidget {
  final Revisao? original;
  const RevisaoFormScreen({super.key, this.original});

  @override
  ConsumerState<RevisaoFormScreen> createState() => _RevisaoFormScreenState();
}

class _RevisaoFormScreenState extends ConsumerState<RevisaoFormScreen> {
  late final TextEditingController _titulo;
  late final TextEditingController _odometro;
  late final TextEditingController _custo;
  late final TextEditingController _local;
  late final TextEditingController _texto;
  final _itemCtrl = TextEditingController();
  late DateTime _data;
  late List<String> _itens;

  @override
  void initState() {
    super.initState();
    final o = widget.original;
    _titulo = TextEditingController(text: o?.titulo ?? '');
    _odometro =
        TextEditingController(text: o?.odometro != null ? n0(o!.odometro!) : '');
    _custo = TextEditingController(text: o?.custo != null ? n2(o!.custo!) : '');
    _local = TextEditingController(text: o?.local ?? '');
    _texto = TextEditingController(text: o?.textoBruto ?? '');
    _data = o?.data ?? DateTime.now();
    _itens = [...(o?.itens ?? const [])];
  }

  @override
  void dispose() {
    for (final c in [_titulo, _odometro, _custo, _local, _texto, _itemCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    final t = _itemCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _itens.add(t);
      _itemCtrl.clear();
    });
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

  void _explicarOcr() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Ler foto do orçamento'),
        content: const Text(
          'Em breve: tirar foto do orçamento e o app extrai as peças/serviços '
          'automaticamente (OCR no próprio aparelho). Por enquanto, cole ou '
          'digite o texto no campo "Texto do orçamento" — ele também é buscável '
          'pela lupa.',
          style: TextStyle(color: AppColors.dim),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendi')),
        ],
      ),
    );
  }

  Future<void> _salvar() async {
    if (_titulo.text.trim().isEmpty && _itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dê um título ou adicione ao menos um item.')));
      return;
    }
    final r = Revisao(
      id: widget.original?.id ?? novoId(),
      data: _data,
      odometro: parseNumero(_odometro.text),
      titulo: _titulo.text.trim(),
      itens: _itens,
      custo: parseNumero(_custo.text),
      local: _local.text.trim(),
      textoBruto: _texto.text.trim(),
    );
    await ref.read(revisoesProvider.notifier).salvar(r);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.original == null ? 'Nova revisão' : 'Revisão')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _campo(_titulo, 'Título', hint: 'Ex.: Revisão dos 40 mil'),
          _linhaData(),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _campo(_odometro, 'Odômetro (km)',
                    teclado: TextInputType.number, soDigitos: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _campo(_custo, 'Custo (R\$)',
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true))),
          ]),
          _campo(_local, 'Oficina / concessionária'),
          const SizedBox(height: 4),
          const Text('Peças / serviços trocados',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _itemCtrl,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _addItem(),
                decoration: const InputDecoration(
                    hintText: 'Ex.: Óleo, filtro de ar, pastilha…'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addItem,
              style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent),
              icon: const Icon(Icons.add),
            ),
          ]),
          if (_itens.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _itens
                  .map((it) => Chip(
                        label: Text(it),
                        backgroundColor: AppColors.surface2,
                        labelStyle: const TextStyle(color: AppColors.text),
                        deleteIconColor: AppColors.dim,
                        onDeleted: () => setState(() => _itens.remove(it)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Texto do orçamento',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                onPressed: _explicarOcr,
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Ler foto'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _texto,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText:
                    'Cole aqui o texto do orçamento — fica buscável pela lupa.'),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _salvar, child: const Text('Salvar')),
        ],
      ),
    );
  }

  Widget _linhaData() {
    return InkWell(
      onTap: _escolherData,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, color: AppColors.dim, size: 20),
            const SizedBox(width: 12),
            Text(dataLonga(_data),
                style: const TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Text('alterar',
                style: TextStyle(color: AppColors.accent, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    String? hint,
    TextInputType teclado = TextInputType.text,
    bool soDigitos = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: teclado,
        textCapitalization: TextCapitalization.sentences,
        inputFormatters:
            soDigitos ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}
