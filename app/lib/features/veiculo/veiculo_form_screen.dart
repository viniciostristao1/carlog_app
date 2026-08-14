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

/// Cadastro/edição do veículo. A **identidade** (marca/modelo/ano/combustível)
/// vem da **tabela FIPE** (busca com lupa); manual só a placa, apelido, tanque,
/// calibragem recomendada e intervalo de revisão. Tudo opcional.
class VeiculoFormScreen extends ConsumerStatefulWidget {
  final Veiculo? veiculo;
  const VeiculoFormScreen({super.key, this.veiculo});

  @override
  ConsumerState<VeiculoFormScreen> createState() => _VeiculoFormScreenState();
}

class _VeiculoFormScreenState extends ConsumerState<VeiculoFormScreen> {
  late final TextEditingController _apelido;
  late final TextEditingController _placa;
  late final TextEditingController _tanque;
  late final TextEditingController _pDianteira;
  late final TextEditingController _pTraseira;
  late final TextEditingController _revKm;
  late final TextEditingController _revMeses;

  // Identidade (FIPE) — não editável à mão.
  String _marca = '';
  String _modelo = '';
  int? _ano;
  Combustivel _combustivel = Combustivel.flex;
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
    _placa = TextEditingController(text: v?.placa ?? '');
    _tanque = TextEditingController(
        text: v?.tanqueLitros != null ? n1(v!.tanqueLitros!) : '');
    _pDianteira = TextEditingController(
        text: v?.pressaoDianteira != null ? n1(v!.pressaoDianteira!) : '');
    _pTraseira = TextEditingController(
        text: v?.pressaoTraseira != null ? n1(v!.pressaoTraseira!) : '');
    _revKm =
        TextEditingController(text: (v?.revisaoIntervaloKm ?? 10000).toString());
    _revMeses = TextEditingController(
        text: (v?.revisaoIntervaloMeses ?? 12).toString());
    _marca = v?.marca ?? '';
    _modelo = v?.modelo ?? '';
    _ano = v?.ano;
    _combustivel = v?.combustivel ?? Combustivel.flex;
    _fipeCodigo = v?.fipeCodigo;
    _fipeCodigoTabela = v?.fipeCodigoTabela;
    _fipeValor = v?.fipeValor;
    _fipeMesRef = v?.fipeMesRef;
    _fipeConsultadoEm = v?.fipeConsultadoEm;
  }

  @override
  void dispose() {
    for (final c in [
      _apelido, _placa, _tanque, _pDianteira, _pTraseira, _revKm, _revMeses,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _buscarFipe() async {
    final sel = await Navigator.of(context).push<FipeSelecao>(
        MaterialPageRoute(builder: (_) => const FipePickerScreen()));
    if (sel == null) return;
    final r = sel.resultado;
    final anoInt = int.tryParse(r.anoModelo);
    setState(() {
      _marca = r.marca;
      _modelo = r.modelo;
      if (anoInt != null && anoInt <= 2100) _ano = anoInt;
      _combustivel = combustivelDaFipe(r.combustivel);
      _fipeCodigo = r.codigoFipe;
      _fipeCodigoTabela = sel.codigoTabela;
      _fipeValor = r.valor;
      _fipeMesRef = r.mesReferencia;
      _fipeConsultadoEm = DateTime.now();
    });
  }

  Future<void> _salvar() async {
    final base = widget.veiculo;
    final v = Veiculo(
      id: base?.id ?? novoId(),
      apelido: _apelido.text.trim(),
      marca: _marca,
      modelo: _modelo,
      ano: _ano,
      placa: _placa.text.trim(),
      combustivel: _combustivel,
      tanqueLitros: parseNumero(_tanque.text),
      pressaoDianteira: parseNumero(_pDianteira.text),
      pressaoTraseira: parseNumero(_pTraseira.text),
      revisaoIntervaloKm: int.tryParse(_revKm.text.trim()) ?? 10000,
      revisaoIntervaloMeses: int.tryParse(_revMeses.text.trim()) ?? 12,
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
    final temIdentidade = _marca.isNotEmpty || _modelo.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.veiculo == null ? 'Cadastrar carro' : 'Meu carro'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _CartaoIdentidade(
            marca: _marca,
            modelo: _modelo,
            ano: _ano,
            combustivel: _combustivel,
            fipeValor: _fipeValor,
            temIdentidade: temIdentidade,
            onBuscar: _buscarFipe,
          ),
          const SizedBox(height: 18),
          _campo(_apelido, 'Apelido (opcional)',
              hint: 'Ex.: Meu Onix', capitalize: true),
          _campo(_placa, 'Placa (opcional)', upper: true),
          _campo(_tanque, 'Tanque (litros, opcional)',
              teclado: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 4),
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
          FilledButton(onPressed: _salvar, child: const Text('Salvar')),
        ],
      ),
    );
  }

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
          if (upper)
            TextInputFormatter.withFunction(
                (o, n) => n.copyWith(text: n.text.toUpperCase())),
        ],
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}

class _CartaoIdentidade extends StatelessWidget {
  final String marca;
  final String modelo;
  final int? ano;
  final Combustivel combustivel;
  final double? fipeValor;
  final bool temIdentidade;
  final VoidCallback onBuscar;
  const _CartaoIdentidade({
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.combustivel,
    required this.fipeValor,
    required this.temIdentidade,
    required this.onBuscar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car_filled,
                    color: AppColors.catFipe),
                const SizedBox(width: 10),
                Expanded(
                  child: temIdentidade
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$marca $modelo'.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (ano != null) '$ano',
                                combustivel.rotulo,
                                if (fipeValor != null) moeda(fipeValor!),
                              ].join(' · '),
                              style: const TextStyle(
                                  color: AppColors.dim, fontSize: 12.5),
                            ),
                          ],
                        )
                      : const Text(
                          'Busque seu carro na tabela FIPE (marca, modelo, ano).',
                          style:
                              TextStyle(color: AppColors.dim, fontSize: 13.5),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onBuscar,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.catFipe,
                    foregroundColor: const Color(0xFF160A2B)),
                icon: const Icon(Icons.search),
                label: const Text('Pesquisar carro'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
