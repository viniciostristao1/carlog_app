import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/abastecimento.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';
import '../../util/ids.dart';
import '../../widgets/campo_sugestoes.dart';

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
  late final TextEditingController _total;
  late final TextEditingController _posto;
  late final TextEditingController _obs;
  late DateTime _data;
  late bool _cheio;
  bool _modoTotal = false; // false = informar preço/L; true = informar valor total

  @override
  void initState() {
    super.initState();
    final o = widget.original;
    _odometro =
        TextEditingController(text: o != null ? n0(o.odometro) : '');
    _litros = TextEditingController(text: o != null ? n1(o.litros) : '');
    _preco = TextEditingController(text: o != null ? n2(o.precoLitro) : '');
    _total = TextEditingController(text: o != null ? n2(o.total) : '');
    _posto = TextEditingController(text: o?.posto ?? '');
    _obs = TextEditingController(text: o?.observacao ?? '');
    _data = o?.data ?? DateTime.now();
    _cheio = o?.tanqueCheio ?? true;
    for (final c in [_litros, _preco, _total]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_odometro, _litros, _preco, _total, _posto, _obs]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _litrosNum => parseNumero(_litros.text) ?? 0;

  /// Total calculado (modo preço/L) = litros × preço.
  double get _totalCalc => _litrosNum * (parseNumero(_preco.text) ?? 0);

  /// Preço/L calculado (modo total) = total ÷ litros.
  double get _precoCalc =>
      _litrosNum > 0 ? (parseNumero(_total.text) ?? 0) / _litrosNum : 0;

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _data = d);
  }

  /// Postos já usados, mais recentes primeiro (para sugerir no preenchimento).
  List<String> _postosAnteriores() {
    final lista = ref.read(abastecimentosProvider).value ?? const [];
    final ordenados = [...lista]..sort((a, b) => b.data.compareTo(a.data));
    final vistos = <String>[];
    for (final a in ordenados) {
      final p = a.posto.trim();
      if (p.isNotEmpty && !vistos.contains(p)) vistos.add(p);
    }
    return vistos;
  }

  Future<void> _salvar() async {
    final odo = parseNumero(_odometro.text);
    final litros = parseNumero(_litros.text);
    if (odo == null || litros == null || litros <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Preencha o odômetro e os litros.')));
      return;
    }
    double? preco;
    if (_modoTotal) {
      final total = parseNumero(_total.text);
      if (total == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Preencha o valor total.')));
        return;
      }
      preco = total / litros;
    } else {
      preco = parseNumero(_preco.text);
      if (preco == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Preencha o preço por litro.')));
        return;
      }
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
          _campo(_litros, 'Litros',
              teclado: const TextInputType.numberWithOptions(decimal: true)),
          _seletorModo(),
          const SizedBox(height: 12),
          if (_modoTotal)
            _campo(_total, 'Valor total (R\$)',
                teclado: const TextInputType.numberWithOptions(decimal: true))
          else
            _campo(_preco, 'Preço / litro',
                teclado: const TextInputType.numberWithOptions(decimal: true)),
          _cartaoCalculado(),
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
          CampoSugestoes(
            controller: _posto,
            label: 'Posto (opcional)',
            hint: 'Ex.: Shell da avenida',
            cor: AppColors.catAbastecimento,
            sugestoes: _postosAnteriores(),
          ),
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

  Widget _seletorModo() {
    Widget chip(String txt, bool total) {
      final sel = _modoTotal == total;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _modoTotal = total),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.catAbastecimento.withValues(alpha: 0.18)
                  : AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: sel ? AppColors.catAbastecimento : AppColors.line),
            ),
            child: Text(txt,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: sel ? AppColors.catAbastecimento : AppColors.dim,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        chip('Informar preço/litro', false),
        chip('Informar valor total', true),
      ]),
    );
  }

  /// Mostra o valor calculado a partir do que NÃO foi digitado.
  Widget _cartaoCalculado() {
    final rotulo = _modoTotal ? 'Preço / litro' : 'Total';
    final valor = _modoTotal ? _precoCalc : _totalCalc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.catAbastecimento.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(rotulo,
              style: const TextStyle(color: AppColors.dim, fontSize: 14)),
          const Spacer(),
          Text(moeda(valor),
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
