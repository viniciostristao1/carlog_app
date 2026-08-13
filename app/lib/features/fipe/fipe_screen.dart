import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/veiculo.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';
import '../../util/ids.dart';
import 'fipe_service.dart';

class FipeScreen extends ConsumerStatefulWidget {
  const FipeScreen({super.key});

  @override
  ConsumerState<FipeScreen> createState() => _FipeScreenState();
}

class _FipeScreenState extends ConsumerState<FipeScreen> {
  final _svc = FipeService();

  List<FipeItem> _marcas = [];
  List<FipeItem> _modelos = [];
  List<FipeItem> _anos = [];
  FipeItem? _marca;
  FipeItem? _modelo;
  FipeItem? _ano;
  FipeResultado? _resultado;

  bool _carregandoMarcas = true;
  bool _carregandoModelos = false;
  bool _carregandoAnos = false;
  bool _carregandoValor = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarMarcas();
  }

  Future<void> _carregarMarcas() async {
    setState(() {
      _carregandoMarcas = true;
      _erro = null;
    });
    try {
      final m = await _svc.marcas();
      setState(() => _marcas = m);
    } catch (_) {
      setState(() => _erro =
          'Não foi possível consultar a FIPE agora. Verifique a internet ou '
          'informe o valor manualmente.');
    } finally {
      setState(() => _carregandoMarcas = false);
    }
  }

  Future<void> _selecionarMarca(FipeItem? m) async {
    if (m == null) return;
    setState(() {
      _marca = m;
      _modelo = null;
      _ano = null;
      _modelos = [];
      _anos = [];
      _resultado = null;
      _carregandoModelos = true;
      _erro = null;
    });
    try {
      final l = await _svc.modelos(m.codigo);
      setState(() => _modelos = l);
    } catch (_) {
      setState(() => _erro = 'Falha ao carregar modelos.');
    } finally {
      setState(() => _carregandoModelos = false);
    }
  }

  Future<void> _selecionarModelo(FipeItem? m) async {
    if (m == null || _marca == null) return;
    setState(() {
      _modelo = m;
      _ano = null;
      _anos = [];
      _resultado = null;
      _carregandoAnos = true;
      _erro = null;
    });
    try {
      final l = await _svc.anos(_marca!.codigo, m.codigo);
      setState(() => _anos = l);
    } catch (_) {
      setState(() => _erro = 'Falha ao carregar anos.');
    } finally {
      setState(() => _carregandoAnos = false);
    }
  }

  Future<void> _selecionarAno(FipeItem? a) async {
    if (a == null || _marca == null || _modelo == null) return;
    setState(() {
      _ano = a;
      _resultado = null;
      _carregandoValor = true;
      _erro = null;
    });
    try {
      final r = await _svc.valor(_marca!.codigo, _modelo!.codigo, a.codigo);
      setState(() => _resultado = r);
    } catch (_) {
      setState(() => _erro = 'Falha ao consultar o valor.');
    } finally {
      setState(() => _carregandoValor = false);
    }
  }

  Combustivel _combustivelDaFipe(String s) {
    final t = s.toLowerCase();
    if (t.contains('flex')) return Combustivel.flex;
    if (t.contains('diesel')) return Combustivel.diesel;
    if (t.contains('álcool') || t.contains('alcool') || t.contains('etanol')) {
      return Combustivel.etanol;
    }
    if (t.contains('gnv') || t.contains('gás') || t.contains('gas natural')) {
      return Combustivel.gnv;
    }
    if (t.contains('gasolina')) return Combustivel.gasolina;
    return Combustivel.flex;
  }

  /// Cadastra (ou atualiza) o carro com os dados da FIPE: marca, modelo, ano,
  /// combustível e valor. Cria o veículo se ainda não existir.
  Future<void> _salvarNoVeiculo() async {
    final r = _resultado;
    if (r == null || _marca == null || _modelo == null || _ano == null) return;
    final atual = ref.read(veiculoProvider).value;
    final anoInt = int.tryParse(r.anoModelo);
    final ano = (anoInt != null && anoInt <= 2100) ? anoInt : atual?.ano;
    final base = atual ?? Veiculo(id: novoId(), apelido: '');
    final v = base.copyWith(
      marca: r.marca,
      modelo: r.modelo,
      ano: ano,
      combustivel: _combustivelDaFipe(r.combustivel),
      fipeCodigo: r.codigoFipe,
      fipeCodigoTabela: '${_marca!.codigo}/${_modelo!.codigo}/${_ano!.codigo}',
      fipeValor: r.valor,
      fipeMesRef: r.mesReferencia,
      fipeConsultadoEm: DateTime.now(),
    );
    await ref.read(veiculoProvider.notifier).salvar(v);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(atual == null
              ? 'Carro cadastrado pela FIPE. Adicione a placa no cartão do veículo.'
              : 'Veículo atualizado pela FIPE.')));
    }
  }

  Future<void> _informarManual() async {
    final atual = ref.read(veiculoProvider).value;
    final ctrl = TextEditingController(
        text: atual?.fipeValor != null ? n2(atual!.fipeValor!) : '');
    final valor = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Informar valor manualmente'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
          ],
          decoration: const InputDecoration(
              labelText: 'Valor (R\$)', hintText: 'Ex.: 45000'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, parseNumero(ctrl.text)),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (valor != null) {
      final base = atual ?? Veiculo(id: novoId(), apelido: '');
      await ref.read(veiculoProvider.notifier).salvar(base.copyWith(
            fipeValor: valor,
            fipeMesRef: 'informado manualmente',
            fipeConsultadoEm: DateTime.now(),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Veiculo? v = ref.watch(veiculoProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Minha FIPE')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (v?.fipeValor != null) _CartaoValorSalvo(veiculo: v!),
          if (v?.fipeValor != null) const SizedBox(height: 16),
          const Text('Consultar tabela FIPE',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
              'Selecione marca, modelo e ano — dá para cadastrar o carro por aqui.',
              style: TextStyle(color: AppColors.dim, fontSize: 13)),
          const SizedBox(height: 14),
          _dropdown(
            rotulo: 'Marca',
            itens: _marcas,
            valor: _marca,
            carregando: _carregandoMarcas,
            onChanged: _selecionarMarca,
          ),
          const SizedBox(height: 12),
          _dropdown(
            rotulo: 'Modelo',
            itens: _modelos,
            valor: _modelo,
            carregando: _carregandoModelos,
            habilitado: _marca != null,
            onChanged: _selecionarModelo,
          ),
          const SizedBox(height: 12),
          _dropdown(
            rotulo: 'Ano',
            itens: _anos,
            valor: _ano,
            carregando: _carregandoAnos,
            habilitado: _modelo != null,
            onChanged: _selecionarAno,
          ),
          const SizedBox(height: 18),
          if (_carregandoValor)
            const Center(child: CircularProgressIndicator()),
          if (_resultado != null) _CartaoResultado(
            resultado: _resultado!,
            onSalvar: _salvarNoVeiculo,
          ),
          if (_erro != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_erro!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _informarManual,
            style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.catFipe,
                side: const BorderSide(color: AppColors.catFipe),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Informar valor manualmente'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String rotulo,
    required List<FipeItem> itens,
    required FipeItem? valor,
    required ValueChanged<FipeItem?> onChanged,
    bool carregando = false,
    bool habilitado = true,
  }) {
    return DropdownButtonFormField<FipeItem>(
      initialValue: valor,
      isExpanded: true,
      dropdownColor: AppColors.surface2,
      decoration: InputDecoration(
        labelText: rotulo,
        suffixIcon: carregando
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : null,
      ),
      hint: Text(carregando ? 'Carregando…' : 'Selecione',
          style: const TextStyle(color: AppColors.dim2)),
      items: itens
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e.nome,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.text)),
              ))
          .toList(),
      onChanged: (habilitado && !carregando) ? onChanged : null,
    );
  }
}

class _CartaoValorSalvo extends StatelessWidget {
  final Veiculo veiculo;
  const _CartaoValorSalvo({required this.veiculo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Valor atual do veículo',
                style: TextStyle(color: AppColors.dim, fontSize: 13)),
            const SizedBox(height: 6),
            Text(moeda(veiculo.fipeValor!),
                style: const TextStyle(
                    color: AppColors.catFipe,
                    fontSize: 30,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              [
                if ((veiculo.fipeMesRef ?? '').isNotEmpty)
                  'Ref.: ${veiculo.fipeMesRef}',
                if (veiculo.fipeConsultadoEm != null)
                  'em ${dataCurta(veiculo.fipeConsultadoEm!)}',
              ].join(' · '),
              style: const TextStyle(color: AppColors.dim2, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoResultado extends StatelessWidget {
  final FipeResultado resultado;
  final VoidCallback onSalvar;
  const _CartaoResultado({required this.resultado, required this.onSalvar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.catFipe.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(resultado.valorTexto,
              style: const TextStyle(
                  color: AppColors.catFipe,
                  fontSize: 30,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '${resultado.marca} ${resultado.modelo} · ${resultado.anoModelo}',
            style: const TextStyle(color: AppColors.text, fontSize: 13.5),
          ),
          Text(
            'FIPE ${resultado.codigoFipe} · ${resultado.mesReferencia}',
            style: const TextStyle(color: AppColors.dim2, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSalvar,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.catFipe,
                  foregroundColor: const Color(0xFF160A2B)),
              icon: const Icon(Icons.directions_car_filled_outlined),
              label: const Text('Usar como meu carro'),
            ),
          ),
        ],
      ),
    );
  }
}
