import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/strings.dart';
import '../../models/revisao.dart';
import '../../services/ocr_service.dart';
import '../../services/prefs.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';
import '../../util/ids.dart';
import '../../widgets/campo_sugestoes.dart';
import 'itens_sugeridos.dart';

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
  bool _ocrLoading = false;

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
    _itemCtrl.addListener(() => setState(() {}));
    _texto.addListener(() => setState(() {})); // mostra/oculta o botão "Limpar"
  }

  /// Oficinas já usadas, mais recentes primeiro (sugestão ao preencher).
  List<String> _oficinasAnteriores() {
    final lista = ref.read(revisoesDoVeiculoProvider);
    final ordenados = [...lista]..sort((a, b) => b.data.compareTo(a.data));
    final vistos = <String>[];
    for (final r in ordenados) {
      final o = r.local.trim();
      if (o.isNotEmpty && !vistos.contains(o)) vistos.add(o);
    }
    return vistos;
  }

  /// Sugestões de peças/serviços: catálogo comum + o que o usuário já registrou,
  /// filtradas pelo que está digitado e sem repetir o que já foi adicionado.
  List<String> _sugestoesItens() {
    final termo = semAcento(_itemCtrl.text.trim());
    final usados =
        (ref.read(revisoesDoVeiculoProvider)).expand((r) => r.itens);
    final nomes = <String>{...itensSugeridos.map((s) => s.nome), ...usados};
    final out = <String>[];
    for (final n in nomes) {
      if (n.trim().isEmpty || _itens.contains(n)) continue;
      if (termo.isNotEmpty && !semAcento(n).contains(termo)) continue;
      out.add(n);
      if (out.length >= 6) break;
    }
    return out;
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

  Future<void> _lerFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.catRevisoes),
              title: Text(ref.read(stringsProvider).tirarFoto,
                  style: TextStyle(color: AppColors.text)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.catRevisoes),
              title: Text(ref.read(stringsProvider).escolherGaleria,
                  style: TextStyle(color: AppColors.text)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    setState(() => _ocrLoading = true);
    OcrResultado? res;
    try {
      res = await OcrService().lerDe(source);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ref.read(stringsProvider).naoLeuImagem)));
      }
    } finally {
      if (mounted) setState(() => _ocrLoading = false);
    }
    if (res == null) return;
    if (res.itens.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ref.read(stringsProvider).nenhumTextoFoto)));
      }
      return;
    }

    if (!mounted) return;
    final selecionados = await showModalBottomSheet<List<ItemLido>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) =>
          _OcrReviewSheet(resultado: res!, t: ref.read(stringsProvider)),
    );

    final ocr = res;
    setState(() {
      for (final it in selecionados ?? const <ItemLido>[]) {
        _itens.add(it.valor != null
            ? '${it.descricao} — R\$ ${n2(it.valor!)}'
            : it.descricao);
      }
      final base = _texto.text.trim();
      _texto.text =
          base.isEmpty ? ocr.textoBruto : '$base\n${ocr.textoBruto}';
      if (ocr.total != null && parseNumero(_custo.text) == null) {
        _custo.text = n2(ocr.total!);
      }
    });
  }

  Future<void> _excluir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(ref.read(stringsProvider).excluirRevisao),
        content: Text(widget.original?.titulo.isNotEmpty == true
            ? widget.original!.titulo
            : dataLonga(_data)),
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
      await ref.read(revisoesProvider.notifier).remover(widget.original!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _salvar() async {
    if (_titulo.text.trim().isEmpty && _itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ref.read(stringsProvider).deTituloOuItem)));
      return;
    }
    final r = Revisao(
      id: widget.original?.id ?? novoId(),
      veiculoId:
          widget.original?.veiculoId ?? ref.read(veiculoSelecionadoProvider)?.id,
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
    final t = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.original == null ? t.novaRevisao : t.revisao),
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
          _campo(_titulo, t.titulo, hint: t.tituloRevisaoHint),
          _linhaData(t),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _campo(_odometro, t.odometroKm,
                    teclado: TextInputType.number, soDigitos: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _campo(_custo, t.custoRs,
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true))),
          ]),
          CampoSugestoes(
            controller: _local,
            label: t.oficinaConcessionaria,
            hint: t.oficinaHint,
            cor: AppColors.catRevisoes,
            sugestoes: _oficinasAnteriores(),
          ),
          const SizedBox(height: 4),
          Text(t.pecasServicos,
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
                decoration: InputDecoration(
                    hintText: t.pecaHint),
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
          if (_sugestoesItens().isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sugestoesItens()
                  .map((n) => ActionChip(
                        avatar: const Icon(Icons.add,
                            size: 16, color: AppColors.catRevisoes),
                        label: Text(n),
                        backgroundColor: AppColors.surface2,
                        labelStyle: const TextStyle(
                            color: AppColors.catRevisoes, fontSize: 12.5),
                        side: BorderSide(color: AppColors.line),
                        onPressed: () => setState(() {
                          _itens.add(n);
                          _itemCtrl.clear();
                        }),
                      ))
                  .toList(),
            ),
          ],
          if (_itens.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _itens
                  .map((it) => Chip(
                        label: Text(it),
                        backgroundColor: AppColors.surface2,
                        labelStyle: TextStyle(color: AppColors.text),
                        deleteIconColor: AppColors.dim,
                        onDeleted: () => setState(() => _itens.remove(it)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text(t.textoOrcamento,
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              if (_texto.text.trim().isNotEmpty)
                TextButton.icon(
                  onPressed: () => _texto.clear(),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  label: Text(t.limpar),
                  style: TextButton.styleFrom(foregroundColor: AppColors.dim),
                ),
              TextButton.icon(
                onPressed: _ocrLoading ? null : _lerFoto,
                icon: _ocrLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(_ocrLoading ? t.lendo : t.lerFoto),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _texto,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
                hintText: t.coleOrcamento),
          ),
          const SizedBox(height: 24),
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

/// Revisão do OCR: mostra as linhas lidas (com valor detectado) para o usuário
/// escolher o que importar como itens. O texto completo é salvo à parte (buscável).
class _OcrReviewSheet extends StatefulWidget {
  final OcrResultado resultado;
  final AppStrings t;
  const _OcrReviewSheet({required this.resultado, required this.t});

  @override
  State<_OcrReviewSheet> createState() => _OcrReviewSheetState();
}

class _OcrReviewSheetState extends State<_OcrReviewSheet> {
  late final List<bool> _sel;
  final _busca = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Por padrão, marca linhas "de item" (curtas o bastante); pula linhas muito
    // longas (provável cabeçalho/observação).
    _sel = widget.resultado.itens
        .map((it) => it.descricao.length <= 48)
        .toList();
    _busca.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final itens = widget.resultado.itens;
    final marcados = _sel.where((s) => s).length;

    // Índices dos itens que combinam com a busca (lupa) — a seleção continua
    // guardada pelo índice original, então filtrar não perde o que foi marcado.
    final termo = semAcento(_busca.text.trim());
    final visiveis = <int>[
      for (var i = 0; i < itens.length; i++)
        if (termo.isEmpty || semAcento(itens[i].descricao).contains(termo)) i,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.oQueImportar,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            t.oQueImportarSub,
            style: TextStyle(color: AppColors.dim, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _busca,
            decoration: InputDecoration(
              isDense: true,
              hintText: t.buscarItemOrcamento,
              prefixIcon: Icon(Icons.search, color: AppColors.dim),
              suffixIcon: _busca.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, color: AppColors.dim),
                      onPressed: () => _busca.clear(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: visiveis.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(t.nenhumItemEncontrado,
                        style: TextStyle(color: AppColors.dim)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: visiveis.length,
                    itemBuilder: (_, k) {
                      final i = visiveis[k];
                      final it = itens[i];
                      return CheckboxListTile(
                        value: _sel[i],
                        onChanged: (v) => setState(() => _sel[i] = v ?? false),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.catRevisoes,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(it.descricao,
                            style: TextStyle(
                                color: AppColors.text, fontSize: 14)),
                        secondary: it.valor != null
                            ? Text('R\$ ${n2(it.valor!)}',
                                style: TextStyle(
                                    color: AppColors.dim,
                                    fontWeight: FontWeight.w600))
                            : null,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                // Marca/desmarca apenas os itens visíveis (respeita a busca).
                onPressed: visiveis.isEmpty
                    ? null
                    : () => setState(() {
                          final marcar = visiveis.any((i) => !_sel[i]);
                          for (final i in visiveis) {
                            _sel[i] = marcar;
                          }
                        }),
                child: Text(
                    visiveis.any((i) => !_sel[i]) ? t.marcarTodos : t.desmarcarTodos),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  final out = <ItemLido>[];
                  for (var i = 0; i < itens.length; i++) {
                    if (_sel[i]) out.add(itens[i]);
                  }
                  Navigator.pop(context, out);
                },
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.catRevisoes,
                    foregroundColor: Colors.white),
                child: Text(t.importarN(marcados)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
