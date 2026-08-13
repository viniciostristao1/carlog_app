import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/abastecimento.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';
import '../../util/ids.dart';

/// Formulário de um abastecimento. Mostra o total (litros × preço/L) ao vivo.
class AbastecimentoFormScreen extends ConsumerStatefulWidget {
  final Abastecimento? original;
  const AbastecimentoFormScreen({super.key, this.original});

  @override
  ConsumerState<AbastecimentoFormScreen> createState() =>
      _AbastecimentoFormScreenState();
}

class _AbastecimentoFormScreenState
    extends ConsumerState<AbastecimentoFormScreen> {
  late final TextEditingController _odometro;
  late final TextEditingController _litros;
  late final TextEditingController _preco;
  late final TextEditingController _posto;
  late final TextEditingController _obs;
  late DateTime _data;
  late bool _cheio;

  @override
  void initState() {
    super.initState();
    final o = widget.original;
    _odometro =
        TextEditingController(text: o != null ? n0(o.odometro) : '');
    _litros = TextEditingController(text: o != null ? n1(o.litros) : '');
    _preco = TextEditingController(text: o != null ? n2(o.precoLitro) : '');
    _posto = TextEditingController(text: o?.posto ?? '');
    _obs = TextEditingController(text: o?.observacao ?? '');
    _data = o?.data ?? DateTime.now();
    _cheio = o?.tanqueCheio ?? true;
    for (final c in [_litros, _preco]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_odometro, _litros, _preco, _posto, _obs]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _total =>
      (parseNumero(_litros.text) ?? 0) * (parseNumero(_preco.text) ?? 0);

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
    final odo = parseNumero(_odometro.text);
    final litros = parseNumero(_litros.text);
    final preco = parseNumero(_preco.text);
    if (odo == null || litros == null || litros <= 0 || preco == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Preencha odômetro, litros e preço por litro.')));
      return;
    }
    final a = Abastecimento(
      id: widget.original?.id ?? novoId(),
      data: _data,
      odometro: odo,
      litros: litros,
      precoLitro: preco,
      tanqueCheio: _cheio,
      posto: _posto.text.trim(),
      observacao: _obs.text.trim(),
    );
    await ref.read(abastecimentosProvider.notifier).salvar(a);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.original == null ? 'Novo abastecimento' : 'Abastecimento'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _linhaData(),
          const SizedBox(height: 12),
          _campo(_odometro, 'Odômetro (km)',
              teclado: TextInputType.number, soDigitos: true),
          Row(children: [
            Expanded(
                child: _campo(_litros, 'Litros',
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 12),
            Expanded(
                child: _campo(_preco, 'Preço / litro',
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true))),
          ]),
          _cartaoTotal(),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _cheio,
            onChanged: (v) => setState(() => _cheio = v),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.accent,
            title: const Text('Enchi o tanque',
                style: TextStyle(color: AppColors.text)),
            subtitle: const Text(
                'Necessário para o cálculo de média confiável',
                style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
          ),
          const SizedBox(height: 4),
          _campo(_posto, 'Posto (opcional)', capitalize: true),
          _campo(_obs, 'Observação (opcional)', capitalize: true),
          const SizedBox(height: 20),
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

  Widget _cartaoTotal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.catAbastecimento.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('Total',
              style: TextStyle(color: AppColors.dim, fontSize: 14)),
          const Spacer(),
          Text(moeda(_total),
              style: const TextStyle(
                  color: AppColors.catAbastecimento,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    TextInputType teclado = TextInputType.text,
    bool capitalize = false,
    bool soDigitos = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: teclado,
        textCapitalization:
            capitalize ? TextCapitalization.sentences : TextCapitalization.none,
        inputFormatters:
            soDigitos ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
