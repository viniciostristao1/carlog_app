import 'package:flutter/material.dart';

import '../../models/veiculo.dart';
import '../../theme/app_colors.dart';
import 'fipe_service.dart';

/// Seleção completa da FIPE (resultado + códigos usados para reconsulta).
class FipeSelecao {
  final FipeResultado resultado;
  final String marcaCod;
  final String modeloCod;
  final String anoCod;
  const FipeSelecao(
      this.resultado, this.marcaCod, this.modeloCod, this.anoCod);

  String get codigoTabela => '$marcaCod/$modeloCod/$anoCod';
}

/// Mapeia o texto de combustível da FIPE para o enum do veículo.
Combustivel combustivelDaFipe(String s) {
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

/// Cascata reutilizável marca → modelo → ano → valor da tabela FIPE. Chama
/// [onSelecao] com a seleção quando um valor é consultado (ou null ao limpar).
class FipeSeletor extends StatefulWidget {
  final ValueChanged<FipeSelecao?> onSelecao;
  const FipeSeletor({super.key, required this.onSelecao});

  @override
  State<FipeSeletor> createState() => _FipeSeletorState();
}

class _FipeSeletorState extends State<FipeSeletor> {
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
          'Não foi possível consultar a FIPE agora. Verifique a internet.');
    } finally {
      setState(() => _carregandoMarcas = false);
    }
  }

  Future<void> _selecionarMarca(FipeItem? m) async {
    if (m == null) return;
    widget.onSelecao(null);
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
    widget.onSelecao(null);
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
    widget.onSelecao(null);
    setState(() {
      _ano = a;
      _resultado = null;
      _carregandoValor = true;
      _erro = null;
    });
    try {
      final r = await _svc.valor(_marca!.codigo, _modelo!.codigo, a.codigo);
      setState(() => _resultado = r);
      widget.onSelecao(
          FipeSelecao(r, _marca!.codigo, _modelo!.codigo, a.codigo));
    } catch (_) {
      setState(() => _erro = 'Falha ao consultar o valor.');
    } finally {
      setState(() => _carregandoValor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 16),
        if (_carregandoValor)
          const Center(child: CircularProgressIndicator()),
        if (_resultado != null) _CartaoResultado(resultado: _resultado!),
        if (_erro != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_erro!,
                style:
                    const TextStyle(color: AppColors.danger, fontSize: 13)),
          ),
        ],
      ],
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

class _CartaoResultado extends StatelessWidget {
  final FipeResultado resultado;
  const _CartaoResultado({required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${resultado.marca} ${resultado.modelo} · ${resultado.anoModelo}',
              style: const TextStyle(color: AppColors.text, fontSize: 13.5)),
          Text('FIPE ${resultado.codigoFipe} · ${resultado.mesReferencia}',
              style: const TextStyle(color: AppColors.dim2, fontSize: 12)),
        ],
      ),
    );
  }
}
