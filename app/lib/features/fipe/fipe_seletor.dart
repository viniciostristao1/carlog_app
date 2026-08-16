import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/strings.dart';
import '../../models/veiculo.dart';
import '../../services/prefs.dart';
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

String _norm(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const para = 'aaaaaeeeeiiiiooooouuuuc';
  var out = s.toLowerCase();
  for (var i = 0; i < de.length; i++) {
    out = out.replaceAll(de[i], para[i]);
  }
  return out;
}

/// Cascata reutilizável marca → modelo → ano → valor. Cada campo abre uma BUSCA
/// (com lupa) para filtrar por digitação — sem rolar listas enormes. Chama
/// [onSelecao] com a seleção quando um valor é consultado (ou null ao limpar).
class FipeSeletor extends ConsumerStatefulWidget {
  final ValueChanged<FipeSelecao?> onSelecao;
  const FipeSeletor({super.key, required this.onSelecao});

  @override
  ConsumerState<FipeSeletor> createState() => _FipeSeletorState();
}

class _FipeSeletorState extends ConsumerState<FipeSeletor> {
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
      setState(() => _erro = ref.read(stringsProvider).fipeIndisponivel);
    } finally {
      setState(() => _carregandoMarcas = false);
    }
  }

  Future<void> _selecionarMarca(FipeItem m) async {
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
      setState(() => _erro = ref.read(stringsProvider).falhaModelos);
    } finally {
      setState(() => _carregandoModelos = false);
    }
  }

  Future<void> _selecionarModelo(FipeItem m) async {
    if (_marca == null) return;
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
      setState(() => _erro = ref.read(stringsProvider).falhaAnos);
    } finally {
      setState(() => _carregandoAnos = false);
    }
  }

  Future<void> _selecionarAno(FipeItem a) async {
    if (_marca == null || _modelo == null) return;
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
      setState(() => _erro = ref.read(stringsProvider).falhaValor);
    } finally {
      setState(() => _carregandoValor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _campo(
          rotulo: t.marca,
          valor: _marca,
          itens: _marcas,
          carregando: _carregandoMarcas,
          habilitado: true,
          onSel: _selecionarMarca,
        ),
        const SizedBox(height: 12),
        _campo(
          rotulo: t.modelo,
          valor: _modelo,
          itens: _modelos,
          carregando: _carregandoModelos,
          habilitado: _marca != null,
          onSel: _selecionarModelo,
        ),
        const SizedBox(height: 12),
        _campo(
          rotulo: t.ano,
          valor: _ano,
          itens: _anos,
          carregando: _carregandoAnos,
          habilitado: _modelo != null,
          onSel: _selecionarAno,
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

  Widget _campo({
    required String rotulo,
    required FipeItem? valor,
    required List<FipeItem> itens,
    required bool carregando,
    required bool habilitado,
    required ValueChanged<FipeItem> onSel,
  }) {
    final t = ref.watch(stringsProvider);
    final ativo = habilitado && !carregando && itens.isNotEmpty;
    return InkWell(
      onTap: ativo
          ? () async {
              final sel = await showModalBottomSheet<FipeItem>(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) =>
                    _BuscaSheet(titulo: rotulo, itens: itens, t: t),
              );
              if (sel != null) onSel(sel);
            }
          : null,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: rotulo,
          enabled: habilitado,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                valor?.nome ??
                    (carregando
                        ? t.carregando
                        : (habilitado ? t.toqueParaBuscar : '—')),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: valor != null ? AppColors.text : AppColors.dim2),
              ),
            ),
            carregando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.search,
                    color: ativo ? AppColors.accent : AppColors.dim2),
          ],
        ),
      ),
    );
  }
}

/// Busca com lupa: campo de texto no topo + lista filtrada. Devolve o item.
class _BuscaSheet extends StatefulWidget {
  final String titulo;
  final List<FipeItem> itens;
  final AppStrings t;
  const _BuscaSheet(
      {required this.titulo, required this.itens, required this.t});

  @override
  State<_BuscaSheet> createState() => _BuscaSheetState();
}

class _BuscaSheetState extends State<_BuscaSheet> {
  final _c = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final termo = _norm(_c.text.trim());
    final filtrados = termo.isEmpty
        ? widget.itens
        : widget.itens.where((i) => _norm(i.nome).contains(termo)).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _c,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.t.buscarX(widget.titulo),
                  prefixIcon: Icon(Icons.search, color: AppColors.dim),
                  suffixIcon: _c.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: AppColors.dim),
                          onPressed: () => _c.clear(),
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: filtrados.isEmpty
                  ? Center(
                      child: Text(widget.t.nadaEncontrado,
                          style: TextStyle(color: AppColors.dim)))
                  : ListView.builder(
                      itemCount: filtrados.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(filtrados[i].nome,
                            style: TextStyle(color: AppColors.text)),
                        onTap: () => Navigator.pop(context, filtrados[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
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
              style: TextStyle(
                  color: AppColors.leg(AppColors.catFipe),
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${resultado.marca} ${resultado.modelo} · ${resultado.anoModelo}',
              style: TextStyle(color: AppColors.text, fontSize: 13.5)),
          Text('FIPE ${resultado.codigoFipe} · ${resultado.mesReferencia}',
              style: TextStyle(color: AppColors.dim2, fontSize: 12)),
        ],
      ),
    );
  }
}
