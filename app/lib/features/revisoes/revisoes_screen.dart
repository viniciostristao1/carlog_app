import 'package:flutter/material.dart';
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
  final _novoItem = TextEditingController();

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
    _novoItem.dispose();
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
          tabs: const [Tab(text: 'Histórico'), Tab(text: 'Programar')],
        ),
      ),
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const RevisaoFormScreen())),
              backgroundColor: AppColors.catRevisoes,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Registrar'),
            )
          : null,
      body: TabBarView(
        controller: _tab,
        children: [_historico(), _programar()],
      ),
    );
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
        _CartaoProximaRevisao(),
        const SizedBox(height: 14),
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

  // ─────────────────────────── Programar ───────────────────────────

  Widget _programar() {
    final itens = [...(ref.watch(programacaoProvider).value ?? const [])]
      ..sort((a, b) {
        if (a.feito != b.feito) return a.feito ? 1 : -1;
        return b.criadoEm.compareTo(a.criadoEm);
      });

    void adicionar() {
      final t = _novoItem.text.trim();
      if (t.isEmpty) return;
      ref.read(programacaoProvider.notifier).salvar(ItemProgramado(
            id: novoId(),
            criadoEm: DateTime.now(),
            descricao: t,
          ));
      _novoItem.clear();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _novoItem,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => adicionar(),
                decoration: const InputDecoration(
                    hintText: 'O que verificar/trocar na próxima?'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: adicionar,
              style: IconButton.styleFrom(
                  backgroundColor: AppColors.catRevisoes,
                  foregroundColor: Colors.white),
              icon: const Icon(Icons.add),
            ),
          ]),
        ),
        Expanded(
          child: itens.isEmpty
              ? const EstadoVazio(
                  icone: Icons.checklist,
                  titulo: 'Sua lista está vazia',
                  subtitulo:
                      'Anote itens para verificar na próxima revisão. Marque '
                      'conforme forem resolvidos.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  children: itens
                      .map((it) => _LinhaProgramado(
                            item: it,
                            onToggle: () => ref
                                .read(programacaoProvider.notifier)
                                .salvar(it.copyWith(feito: !it.feito)),
                            onExcluir: () => ref
                                .read(programacaoProvider.notifier)
                                .remover(it.id),
                          ))
                      .toList(),
                ),
        ),
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

    final odoAtual = ultimoOdometro(abastecimentos);
    final comOdo = revisoes.where((r) => r.odometro != null).toList()
      ..sort((a, b) => a.odometro!.compareTo(b.odometro!));
    final baseOdo = comOdo.isNotEmpty ? comOdo.last.odometro! : odoAtual;

    Widget wrap(Widget child) => Card(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        );

    if (v == null || baseOdo == null) {
      return wrap(const Row(children: [
        Icon(Icons.event_repeat, color: AppColors.catRevisoes),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Cadastre o carro (intervalo de revisão) e registre abastecimentos '
            'para o app estimar a próxima revisão.',
            style: TextStyle(color: AppColors.dim, fontSize: 13),
          ),
        ),
      ]));
    }

    final alvoKm = baseOdo + v.revisaoIntervaloKm;
    final faltamKm = odoAtual != null ? alvoKm - odoAtual : v.revisaoIntervaloKm;
    final ritmo = kmPorMesEstimado(abastecimentos);
    String? previsao;
    if (ritmo != null && ritmo > 0 && faltamKm > 0) {
      final meses = faltamKm / ritmo;
      final dias = (meses * 30).round();
      final data = DateTime.now().add(Duration(days: dias));
      previsao = '≈ ${dataLonga(data)}';
    }
    final vencida = faltamKm <= 0;

    return wrap(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(vencida ? Icons.warning_amber_rounded : Icons.event_repeat,
              color: vencida ? AppColors.warn : AppColors.catRevisoes),
          const SizedBox(width: 10),
          Text(vencida ? 'Revisão vencida' : 'Próxima revisão',
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _mini('Alvo', km(alvoKm))),
          Expanded(
            child: _mini(vencida ? 'Passou' : 'Faltam',
                km(faltamKm.abs())),
          ),
          Expanded(child: _mini('Previsão', previsao ?? '—')),
        ]),
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

class _LinhaProgramado extends StatelessWidget {
  final ItemProgramado item;
  final VoidCallback onToggle;
  final VoidCallback onExcluir;
  const _LinhaProgramado(
      {required this.item, required this.onToggle, required this.onExcluir});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onToggle,
      leading: Icon(
        item.feito ? Icons.check_circle : Icons.radio_button_unchecked,
        color: item.feito ? AppColors.ok : AppColors.dim,
      ),
      title: Text(
        item.descricao,
        style: TextStyle(
          color: item.feito ? AppColors.dim2 : AppColors.text,
          decoration: item.feito ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 18, color: AppColors.dim2),
        onPressed: onExcluir,
      ),
    );
  }
}
