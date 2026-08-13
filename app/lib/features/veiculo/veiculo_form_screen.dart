import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/veiculo.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';
import '../../util/ids.dart';
import '../fipe/fipe_picker_screen.dart';
import '../fipe/fipe_seletor.dart';

/// Cadastro/edição do veículo. Guarda também os parâmetros usados por outras
/// telas: pressão recomendada (Calibragem) e intervalo de revisão (estimativa da
/// próxima). A FIPE é preenchida pela tela "Minha FIPE".
class VeiculoFormScreen extends ConsumerStatefulWidget {
  final Veiculo? veiculo;
  const VeiculoFormScreen({super.key, this.veiculo});

  @override
  ConsumerState<VeiculoFormScreen> createState() => _VeiculoFormScreenState();
}

class _VeiculoFormScreenState extends ConsumerState<VeiculoFormScreen> {
  late final TextEditingController _apelido;
  late final TextEditingController _marca;
  late final TextEditingController _modelo;
  late final TextEditingController _ano;
  late final TextEditingController _placa;
  late final TextEditingController _tanque;
  late final TextEditingController _pDianteira;
  late final TextEditingController _pTraseira;
  late final TextEditingController _revKm;
  late final TextEditingController _revMeses;
  late Combustivel _combustivel;

  // FIPE preenchida pelo seletor (ou herdada do veículo em edição).
  String? _fipeCodigo;
  String? _fipeCodigoTabela;
  double? _fipeValor;
  String? _fipeMesRef;
  DateTime? _fipeConsultadoEm;

  @override
  void initState() {
    super.initState();
    final v = widget.veiculo;
    _apelido = TextEditingController(text: v?.apelido ?? '');
    _marca = TextEditingController(text: v?.marca ?? '');
    _modelo = TextEditingController(text: v?.modelo ?? '');
    _ano = TextEditingController(text: v?.ano?.toString() ?? '');
    _placa = TextEditingController(text: v?.placa ?? '');
    _tanque = TextEditingController(
        text: v?.tanqueLitros != null ? n1(v!.tanqueLitros!) : '');
    _pDianteira = TextEditingController(
        text: v?.pressaoDianteira != null ? n1(v!.pressaoDianteira!) : '');
    _pTraseira = TextEditingController(
        text: v?.pressaoTraseira != null ? n1(v!.pressaoTraseira!) : '');
    _revKm = TextEditingController(text: (v?.revisaoIntervaloKm ?? 10000).toString());
    _revMeses = TextEditingController(text: (v?.revisaoIntervaloMeses ?? 12).toString());
    _combustivel = v?.combustivel ?? Combustivel.flex;
    _fipeCodigo = v?.fipeCodigo;
    _fipeCodigoTabela = v?.fipeCodigoTabela;
    _fipeValor = v?.fipeValor;
    _fipeMesRef = v?.fipeMesRef;
    _fipeConsultadoEm = v?.fipeConsultadoEm;
  }

  Future<void> _buscarFipe() async {
    final sel = await Navigator.of(context).push<FipeSelecao>(
        MaterialPageRoute(builder: (_) => const FipePickerScreen()));
    if (sel == null) return;
    final r = sel.resultado;
    final anoInt = int.tryParse(r.anoModelo);
    setState(() {
      _marca.text = r.marca;
      _modelo.text = r.modelo;
      if (anoInt != null && anoInt <= 2100) _ano.text = '$anoInt';
      _combustivel = combustivelDaFipe(r.combustivel);
      _fipeCodigo = r.codigoFipe;
      _fipeCodigoTabela = sel.codigoTabela;
      _fipeValor = r.valor;
      _fipeMesRef = r.mesReferencia;
      _fipeConsultadoEm = DateTime.now();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dados preenchidos pela FIPE. Confira e salve.')));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _apelido, _marca, _modelo, _ano, _placa, _tanque,
      _pDianteira, _pTraseira, _revKm, _revMeses,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    final base = widget.veiculo;
    final v = Veiculo(
      id: base?.id ?? novoId(),
      apelido: _apelido.text.trim(),
      marca: _marca.text.trim(),
      modelo: _modelo.text.trim(),
      ano: int.tryParse(_ano.text.trim()),
      placa: _placa.text.trim(),
      combustivel: _combustivel,
      tanqueLitros: parseNumero(_tanque.text),
      pressaoDianteira: parseNumero(_pDianteira.text),
      pressaoTraseira: parseNumero(_pTraseira.text),
      revisaoIntervaloKm: int.tryParse(_revKm.text.trim()) ?? 10000,
      revisaoIntervaloMeses: int.tryParse(_revMeses.text.trim()) ?? 12,
      // FIPE (preenchida pelo seletor ou herdada)
      fipeCodigo: _fipeCodigo,
      fipeCodigoTabela: _fipeCodigoTabela,
      fipeValor: _fipeValor,
      fipeMesRef: _fipeMesRef,
      fipeConsultadoEm: _fipeConsultadoEm,
    );
    await ref.read(veiculoProvider.notifier).salvar(v);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.veiculo == null ? 'Cadastrar carro' : 'Meu carro'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _buscarFipe,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.catFipe,
                side: const BorderSide(color: AppColors.catFipe),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('Preencher pela tabela FIPE'),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Busca marca, modelo, ano e combustível pela FIPE.',
              style: TextStyle(color: AppColors.dim2, fontSize: 12)),
          const SizedBox(height: 14),
          _campo(_apelido, 'Apelido', hint: 'Ex.: Meu Onix', capitalize: true),
          Row(children: [
            Expanded(child: _campo(_marca, 'Marca', capitalize: true)),
            const SizedBox(width: 12),
            Expanded(child: _campo(_modelo, 'Modelo', capitalize: true)),
          ]),
          Row(children: [
            Expanded(
                child: _campo(_ano, 'Ano',
                    teclado: TextInputType.number, soDigitos: true)),
            const SizedBox(width: 12),
            Expanded(child: _campo(_placa, 'Placa', upper: true)),
          ]),
          const SizedBox(height: 4),
          _rotulo('Combustível'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: Combustivel.values.map((c) {
              final sel = c == _combustivel;
              return ChoiceChip(
                label: Text(c.rotulo),
                selected: sel,
                onSelected: (_) => setState(() => _combustivel = c),
                selectedColor: AppColors.accent.withValues(alpha: 0.25),
                backgroundColor: AppColors.surface2,
                labelStyle: TextStyle(
                    color: sel ? AppColors.accent : AppColors.dim,
                    fontWeight: FontWeight.w600),
                side: BorderSide(
                    color: sel ? AppColors.accent : AppColors.line),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _campo(_tanque, 'Tanque (litros)',
              teclado: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 8),
          _secao('Calibragem recomendada (psi)'),
          Row(children: [
            Expanded(
                child: _campo(_pDianteira, 'Dianteiro',
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 12),
            Expanded(
                child: _campo(_pTraseira, 'Traseiro',
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true))),
          ]),
          const SizedBox(height: 8),
          _secao('Intervalo de revisão'),
          Row(children: [
            Expanded(
                child: _campo(_revKm, 'A cada (km)',
                    teclado: TextInputType.number, soDigitos: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _campo(_revMeses, 'ou (meses)',
                    teclado: TextInputType.number, soDigitos: true)),
          ]),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _salvar,
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Widget _rotulo(String t) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(t,
            style: const TextStyle(
                color: AppColors.dim, fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _secao(String t) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10, left: 4),
        child: Text(t,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      );

  Widget _campo(
    TextEditingController c,
    String label, {
    String? hint,
    TextInputType teclado = TextInputType.text,
    bool capitalize = false,
    bool upper = false,
    bool soDigitos = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: teclado,
        textCapitalization:
            capitalize ? TextCapitalization.words : TextCapitalization.none,
        inputFormatters: [
          if (soDigitos) FilteringTextInputFormatter.digitsOnly,
          if (upper) TextInputFormatter.withFunction(
              (o, n) => n.copyWith(text: n.text.toUpperCase())),
        ],
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}
