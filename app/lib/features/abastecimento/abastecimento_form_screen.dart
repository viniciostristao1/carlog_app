import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/strings.dart';
import '../../models/abastecimento.dart';
import '../../services/prefs.dart';
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
    _odometro = TextEditingController(
        text: o?.odometro != null ? n0(o!.odometro!) : '');
    _litros =
        TextEditingController(text: o?.litros != null ? n1(o!.litros!) : '');
    _preco = TextEditingController(
        text: o?.precoLitro != null ? n2(o!.precoLitro!) : '');
    _total = TextEditingController(
        text: (o?.litros != null && o?.precoLitro != null) ? n2(o!.total) : '');
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
    final lista = ref.read(abastecimentosDoVeiculoProvider);
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
    // preço/L: informado direto, ou derivado do total (se houver litros).
    double? preco;
    if (_modoTotal) {
      final total = parseNumero(_total.text);
      if (total != null && litros != null && litros > 0) preco = total / litros;
    } else {
      preco = parseNumero(_preco.text);
    }
    // Tudo é opcional, mas ao menos um campo tem de existir.
    if (odo == null && litros == null && preco == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ref.read(stringsProvider).preenchaUmCampo)));
      return;
    }
    final a = Abastecimento(
      id: widget.original?.id ?? novoId(),
      veiculoId:
          widget.original?.veiculoId ?? ref.read(veiculoSelecionadoProvider)?.id,
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

  Future<void> _excluir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(ref.read(stringsProvider).excluirAbastecimento),
        content: Text(dataLonga(_data)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(ref.read(stringsProvider).cancelar)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(ref.read(stringsProvider).excluir,
                  style: const TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(abastecimentosProvider.notifier)
          .remover(widget.original!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.original == null ? t.novoAbastecimento : t.abastecimento),
        actions: [
          if (widget.original != null)
            IconButton(
              tooltip: t.excluir,
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _excluir,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _linhaData(t),
          const SizedBox(height: 12),
          _campo(_odometro, t.odometroKmOpc,
              teclado: TextInputType.number, soDigitos: true),
          _campo(_litros, t.litrosOpc,
              teclado: const TextInputType.numberWithOptions(decimal: true)),
          _seletorModo(t),
          const SizedBox(height: 12),
          if (_modoTotal)
            _campo(_total, t.valorTotalRs,
                teclado: const TextInputType.numberWithOptions(decimal: true))
          else
            _campo(_preco, t.precoLitro,
                teclado: const TextInputType.numberWithOptions(decimal: true)),
          _cartaoCalculado(t),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _cheio,
            onChanged: (v) => setState(() => _cheio = v),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.accent,
            title: Text(t.enchiTanque,
                style: TextStyle(color: AppColors.text)),
            subtitle: Text(
                t.enchiTanqueSub,
                style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
          ),
          const SizedBox(height: 4),
          CampoSugestoes(
            controller: _posto,
            label: t.postoOpc,
            hint: t.postoHint,
            cor: AppColors.catAbastecimento,
            sugestoes: _postosAnteriores(),
          ),
          _campo(_obs, t.observacaoOpc, capitalize: true),
          const SizedBox(height: 20),
          FilledButton(onPressed: _salvar, child: Text(t.salvar)),
        ],
      ),
    );
  }

  Widget _linhaData(AppStrings t) {
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
            Icon(Icons.event, color: AppColors.dim, size: 20),
            const SizedBox(width: 12),
            Text(dataLonga(_data),
                style: TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(t.alterar,
                style: TextStyle(color: AppColors.accent, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _seletorModo(AppStrings t) {
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
        chip(t.informarPrecoLitro, false),
        chip(t.informarValorTotal, true),
      ]),
    );
  }

  /// Mostra o valor calculado a partir do que NÃO foi digitado.
  Widget _cartaoCalculado(AppStrings t) {
    final rotulo = _modoTotal ? t.precoLitro : t.total;
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
              style: TextStyle(color: AppColors.dim, fontSize: 14)),
          const Spacer(),
          Text(moeda(valor),
              style: TextStyle(
                  color: AppColors.leg(AppColors.catAbastecimento),
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
