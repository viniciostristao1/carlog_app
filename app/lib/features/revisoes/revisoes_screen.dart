import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/programacao.dart';
import '../../models/revisao.dart';
import '../../models/veiculo.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/consumo.dart';
import '../../util/format.dart';
import '../../util/ids.dart';
import '../../widgets/estado_vazio.dart';
import 'itens_sugeridos.dart';
import 'revisao_form_screen.dart';

class RevisoesScreen extends ConsumerStatefulWidget {
  const RevisoesScreen({super.key});

  @override
  ConsumerState<RevisoesScreen> createState() => _RevisoesScreenState();
}

class _RevisoesScreenState extends ConsumerState<RevisoesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _busca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _busca.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisões'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.catRevisoes,
          labelColor: AppColors.catRevisoes,
          unselectedLabelColor: AppColors.dim,
          tabs: const [Tab(text: 'Programar'), Tab(text: 'Histórico')],
        ),
      ),
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _abrirItemSheet(),
              backgroundColor: AppColors.catRevisoes,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            )
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const RevisaoFormScreen())),
              backgroundColor: AppColors.catRevisoes,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Registrar'),
            ),
      body: TabBarView(
        controller: _tab,
        children: [_programar(), _historico()],
      ),
    );
  }

  Future<void> _abrirItemSheet({ItemProgramado? original}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ItemSheet(original: original),
    );
  }

  // ─────────────────────────── Programar ───────────────────────────

  Widget _programar() {
    final abastecimentos = ref.watch(abastecimentosProvider).value ?? const [];
    final odo = ultimoOdometro(abastecimentos);
    final ritmo = ritmoKmPorDia(abastecimentos);

    final itens = [...(ref.watch(programacaoProvider).value ?? const [])]
      ..sort((a, b) {
        if (a.feito != b.feito) return a.feito ? 1 : -1;
        final fa = _faltam(a, odo);
        final fb = _faltam(b, odo);
        if (fa != null && fb != null) return fa.compareTo(fb);
        if (fa != null) return -1;
        if (fb != null) return 1;
        return b.criadoEm.compareTo(a.criadoEm);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _CartaoProximaRevisao(),
        const SizedBox(height: 14),
        if (itens.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EstadoVazio(
              icone: Icons.checklist,
              titulo: 'Nada programado ainda',
              subtitulo:
                  'Toque em "Adicionar" para anotar o que verificar/trocar. Dá '
                  'para definir o km e a frequência (ex.: óleo a cada 10.000 km).',
            ),
          )
        else
          ...itens.map((it) => _LinhaProgramado(
                item: it,
                odometroAtual: odo,
                ritmoKmDia: ritmo,
                onToggle: () => _alternarFeito(it, odo),
                onEditar: () => _abrirItemSheet(original: it),
                onExcluir: () =>
                    ref.read(programacaoProvider.notifier).remover(it.id),
              )),
      ],
    );
  }

  double? _faltam(ItemProgramado it, double? odo) {
    if (it.kmAlvo == null || odo == null) return null;
    return it.kmAlvo! - odo;
  }

  void _alternarFeito(ItemProgramado it, double? odo) {
    final notifier = ref.read(programacaoProvider.notifier);
    final base = it.kmAlvo ?? odo;
    if (it.intervaloKm != null && base != null) {
      // Recorrente: "fiz agora" → reagenda para o próximo intervalo.
      final proximo = base + it.intervaloKm!;
      notifier.salvar(it.copyWith(kmAlvo: proximo, feito: false));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Feito! Reagendado para ${km(proximo)}.')));
    } else {
      notifier.salvar(it.copyWith(feito: !it.feito));
    }
  }

  // ─────────────────────────── Histórico ───────────────────────────

  Widget _historico() {
    final todas = [...(ref.watch(revisoesProvider).value ?? const [])]
      ..sort((a, b) => b.data.compareTo(a.data));
    final termo = _busca.text.trim().toLowerCase();
    final lista = termo.isEmpty
        ? todas
        : todas.where((r) => r.indiceBusca.contains(termo)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        TextField(
          controller: _busca,
          decoration: InputDecoration(
            hintText: 'Buscar peça, serviço, oficina…',
            prefixIcon: const Icon(Icons.search, color: AppColors.dim),
            suffixIcon: termo.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.dim),
                    onPressed: () => _busca.clear(),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        if (todas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EstadoVazio(
              icone: Icons.build_circle_outlined,
              titulo: 'Sem revisões registradas',
              subtitulo:
                  'Registre o que já foi trocado. A lupa busca por peça, '
                  'serviço ou oficina.',
            ),
          )
        else if (lista.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Text('Nada encontrado para "$termo".',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.dim)),
          )
        else
          ...lista.map((r) => _CartaoRevisao(
                r: r,
                onEditar: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => RevisaoFormScreen(original: r))),
                onExcluir: () =>
                    ref.read(revisoesProvider.notifier).remover(r.id),
              )),
      ],
    );
  }
}

class _CartaoProximaRevisao extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Veiculo? v = ref.watch(veiculoProvider).value;
    final abastecimentos = ref.watch(abastecimentosProvider).value ?? const [];
    final revisoes = ref.watch(revisoesProvider).value ?? const [];

    Widget wrap(Widget child) => Card(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        );

    final p = v == null
        ? PrevisaoRevisao.vazio
        : preverRevisao(v, abastecimentos, revisoes);

    if (v == null || p.alvoKm == null) {
      return wrap(const Row(children: [
        Icon(Icons.event_repeat, color: AppColors.catRevisoes),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Registre revisões e abastecimentos (com o km do painel) para o app '
            'estimar a próxima revisão pela sua rodagem.',
            style: TextStyle(color: AppColors.dim, fontSize: 13),
          ),
        ),
      ]));
    }

    final alvoKm = p.alvoKm!;
    final previsao = p.data != null ? dataLonga(p.data!) : '—';
    final vencida = p.vencida;
    final media12 = p.mediaKmMes12;

    return wrap(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(vencida ? Icons.warning_amber_rounded : Icons.event_repeat,
              color: vencida ? AppColors.warn : AppColors.catRevisoes),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                vencida ? 'Sua revisão pode estar vencida' : 'Próxima revisão',
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _mini('Alvo', km(alvoKm))),
          Expanded(
              child: _mini(vencida ? 'estava prevista' : 'Previsão', previsao)),
        ]),
        if (media12 != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.trending_up, color: AppColors.catConsumo, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Média nos últimos 12 meses',
                    style: const TextStyle(color: AppColors.dim, fontSize: 12.5)),
              ),
              Text('${km(media12)}/mês',
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
        ],
      ],
    ));
  }

  Widget _mini(String r, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(r, style: const TextStyle(color: AppColors.dim2, fontSize: 11.5)),
        ],
      );
}

class _LinhaProgramado extends StatelessWidget {
  final ItemProgramado item;
  final double? odometroAtual;
  final double? ritmoKmDia;
  final VoidCallback onToggle;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  const _LinhaProgramado({
    required this.item,
    required this.odometroAtual,
    required this.ritmoKmDia,
    required this.onToggle,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final partes = <String>[];
    Color corSub = AppColors.dim;
    if (item.kmAlvo != null) {
      partes.add('para ${km(item.kmAlvo!)}');
      if (odometroAtual != null) {
        final faltam = item.kmAlvo! - odometroAtual!;
        if (faltam <= 0) {
          partes.add('vencido');
          corSub = AppColors.warn;
        } else {
          partes.add('faltam ${km(faltam)}');
          final data = previsaoData(faltam, ritmoKmDia);
          if (data != null) partes.add('≈ ${dataCurta(data)}');
          if (faltam <= 500) corSub = AppColors.warn;
        }
      }
    }
    if (item.intervaloKm != null) {
      partes.add('a cada ${km(item.intervaloKm!.toDouble())}');
    }
    final sub = partes.join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onEditar,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    item.feito
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: item.feito ? AppColors.ok : AppColors.dim,
                  ),
                  onPressed: onToggle,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.descricao,
                        style: TextStyle(
                          color: item.feito ? AppColors.dim2 : AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration:
                              item.feito ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (sub.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(sub,
                            style: TextStyle(color: corSub, fontSize: 12.5)),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.close, size: 18, color: AppColors.dim2),
                  onPressed: onExcluir,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartaoRevisao extends StatelessWidget {
  final Revisao r;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  const _CartaoRevisao(
      {required this.r, required this.onEditar, required this.onExcluir});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      onDismissed: (_) => onExcluir(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onEditar,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.titulo.isNotEmpty ? r.titulo : 'Revisão',
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (r.custo != null)
                        Text(moeda(r.custo!),
                            style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      dataCurta(r.data),
                      if (r.odometro != null) km(r.odometro!),
                      if (r.local.isNotEmpty) r.local,
                    ].join(' · '),
                    style: const TextStyle(color: AppColors.dim, fontSize: 12.5),
                  ),
                  if (r.itens.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: r.itens
                          .take(8)
                          .map((it) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(it,
                                    style: const TextStyle(
                                        color: AppColors.dim, fontSize: 11.5)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Folha para adicionar/editar um item programado (descrição com autocomplete,
/// km-alvo e frequência).
class _ItemSheet extends ConsumerStatefulWidget {
  final ItemProgramado? original;
  const _ItemSheet({this.original});

  @override
  ConsumerState<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends ConsumerState<_ItemSheet> {
  late final TextEditingController _desc;
  late final TextEditingController _kmAlvo;
  late final TextEditingController _intervalo;

  @override
  void initState() {
    super.initState();
    final o = widget.original;
    _desc = TextEditingController(text: o?.descricao ?? '');
    _kmAlvo =
        TextEditingController(text: o?.kmAlvo != null ? n0(o!.kmAlvo!) : '');
    _intervalo = TextEditingController(
        text: o?.intervaloKm != null ? '${o!.intervaloKm}' : '');
    _desc.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _desc.dispose();
    _kmAlvo.dispose();
    _intervalo.dispose();
    super.dispose();
  }

  void _escolher(ItemSugerido s) {
    _desc.text = s.nome;
    _desc.selection =
        TextSelection.collapsed(offset: _desc.text.length);
    if (_intervalo.text.trim().isEmpty && s.intervaloKm > 0) {
      _intervalo.text = '${s.intervaloKm}';
    }
    setState(() {});
  }

  Future<void> _salvar() async {
    final desc = _desc.text.trim();
    if (desc.isEmpty) return;
    final base = widget.original ??
        ItemProgramado(id: novoId(), criadoEm: DateTime.now(), descricao: desc);
    final item = base.copyWith(
      descricao: desc,
      kmAlvo: parseNumero(_kmAlvo.text),
      intervaloKm: int.tryParse(_intervalo.text.trim().replaceAll('.', '')),
      limparKmAlvo: parseNumero(_kmAlvo.text) == null,
      limparIntervalo: _intervalo.text.trim().isEmpty,
    );
    await ref.read(programacaoProvider.notifier).salvar(item);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final desc = _desc.text.trim();
    final sug = sugestoesPara(desc).where((s) => s.nome != desc).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.original == null ? 'Novo item' : 'Editar item',
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _desc,
              autofocus: widget.original == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'O que verificar/trocar',
                  hintText: 'Ex.: óleo, filtro de ar, velas…'),
            ),
            if (sug.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sug
                    .map((s) => ActionChip(
                          label: Text(s.nome),
                          backgroundColor: AppColors.surface2,
                          labelStyle: const TextStyle(
                              color: AppColors.catRevisoes, fontSize: 12.5),
                          side: const BorderSide(color: AppColors.line),
                          onPressed: () => _escolher(s),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _kmAlvo,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'Fazer no km', hintText: 'ex.: 60000'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _intervalo,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: 'A cada (km)', hintText: 'ex.: 10000'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            const Text(
              'Ambos opcionais. Com o km, o app mostra quanto falta e a data '
              'provável (pelo seu ritmo de rodagem).',
              style: TextStyle(color: AppColors.dim2, fontSize: 12),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _salvar,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.catRevisoes,
                  foregroundColor: Colors.white),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
