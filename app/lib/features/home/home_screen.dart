import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/veiculo.dart';
import '../../services/prefs.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';
import '../../util/consumo.dart';
import '../../util/format.dart';
import '../../widgets/botao_redondo.dart';
import '../abastecimento/abastecimento_screen.dart';
import '../calibragem/calibragem_screen.dart';
import '../config/config_screen.dart';
import '../fipe/fipe_screen.dart';
import '../lembretes/lembretes_screen.dart';
import '../media/media_screen.dart';
import '../revisoes/revisoes_screen.dart';
import '../veiculo/veiculo_form_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _abrir(BuildContext context, Widget tela) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final veiculo = ref.watch(veiculoSelecionadoProvider);
    final t = ref.watch(stringsProvider);
    // Com fonte maior, dá mais altura aos botões p/ o rótulo não estourar.
    final escala = ref.watch(fonteProvider).value?.fator ?? 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CarLog'),
        actions: [
          IconButton(
            tooltip: t.configuracoes,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _abrir(context, const ConfigScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _CabecalhoVeiculo(
              veiculo: veiculo,
              onEditar: () =>
                  _abrir(context, VeiculoFormScreen(veiculo: veiculo)),
            ),
            const _OutrosCarros(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                t.oQueRegistrar,
                style: TextStyle(
                  color: AppColors.dim,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 20,
              crossAxisSpacing: 8,
              childAspectRatio: (0.82 / escala).clamp(0.6, 0.82),
              children: [
                BotaoRedondo(
                  icone: Icons.local_gas_station,
                  rotulo: t.catAbastecimento,
                  cor: AppColors.catAbastecimento,
                  onTap: () => _abrir(context, const AbastecimentoScreen()),
                ),
                BotaoRedondo(
                  icone: Icons.speed,
                  rotulo: t.catConsumo,
                  cor: AppColors.catConsumo,
                  onTap: () => _abrir(context, const MediaScreen()),
                ),
                BotaoRedondo(
                  icone: Icons.build_circle_outlined,
                  rotulo: t.catRevisoes,
                  cor: AppColors.catRevisoes,
                  onTap: () => _abrir(context, const RevisoesScreen()),
                ),
                BotaoRedondo(
                  icone: Icons.request_quote_outlined,
                  rotulo: t.catFipe,
                  cor: AppColors.catFipe,
                  onTap: () => _abrir(context, const FipeScreen()),
                ),
                BotaoRedondo(
                  icone: Icons.tire_repair,
                  rotulo: t.catCalibragem,
                  cor: AppColors.catCalibragem,
                  onTap: () => _abrir(context, const CalibragemScreen()),
                ),
                BotaoRedondo(
                  icone: Icons.event_available_outlined,
                  rotulo: t.catLembretes,
                  cor: AppColors.catLembretes,
                  onTap: () => _abrir(context, const LembretesScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CabecalhoVeiculo extends ConsumerWidget {
  final Veiculo? veiculo;
  final VoidCallback onEditar;
  const _CabecalhoVeiculo({required this.veiculo, required this.onEditar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final v = veiculo;
    if (v == null) {
      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onEditar,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.directions_car_filled,
                    color: AppColors.accent, size: 34),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.cadastrarMeuCarro,
                          style: TextStyle(
                              color: AppColors.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(t.busquePelaFipe,
                          style:
                              TextStyle(color: AppColors.dim, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.dim),
              ],
            ),
          ),
        ),
      );
    }

    final abastecimentos = ref.watch(abastecimentosDoVeiculoProvider);
    final revisoes = ref.watch(revisoesDoVeiculoProvider);
    final calibragens = ref.watch(calibragemDoVeiculoProvider);
    final agora = DateTime.now();

    final odo = ultimoOdometro(abastecimentos);
    final kmMes = kmRodadosNoMes(abastecimentos, agora.year, agora.month);
    final gastoMes = abastecimentos
        .where((a) => a.data.year == agora.year && a.data.month == agora.month)
        .fold<double>(0, (s, a) => s + a.total);
    final ultimaCalib = calibragens.isEmpty
        ? null
        : (calibragens.map((c) => c.data).reduce((a, b) => a.isAfter(b) ? a : b));
    final prev = preverRevisao(v, abastecimentos, revisoes);
    // Fonte maior → tiles mais altos, para o valor/rótulo não estourarem.
    final escala = ref.watch(fonteProvider).value?.fator ?? 1.0;
    // No tema claro (Madeira), inverte a caixa do carro: fundo bege mais escuro
    // e os tiles de info em bege mais claro (pedido do usuário — melhora a
    // leitura). Nos temas escuros mantém o padrão.
    final claro = AppColors.brilho == Brightness.light;
    final corCard = claro ? AppColors.surface2 : AppColors.surface;
    final corTile = claro ? AppColors.surface : AppColors.surface2;

    // Título em duas linhas (marca em cima, modelo abaixo — cabe o modelo
    // completo). O apelido e o resto (ano/combustível) descem para a linha extra.
    final marca = v.marca.trim();
    final modelo = v.modelo.trim();
    final infoExtra = [
      if (v.apelido.trim().isNotEmpty) v.apelido.trim(),
      if (v.ano != null) '${v.ano}',
      t.rotuloCombustivel(v.combustivel),
    ].where((s) => s.isNotEmpty).join(' · ');

    void abrir(Widget tela) => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => tela));

    final stats = <_Stat>[
      _Stat(Icons.speed, AppColors.accent, t.statOdometro,
          odo != null ? km(odo) : '—',
          onTap: () => abrir(const AbastecimentoScreen())),
      _Stat(Icons.calendar_month, AppColors.catConsumo, t.statKmMes,
          kmMes > 0 ? km(kmMes) : '—',
          onTap: () => abrir(const MediaScreen())),
      _Stat(Icons.local_gas_station, AppColors.catAbastecimento,
          t.statCombustivelMes, gastoMes > 0 ? moeda(gastoMes) : '—',
          onTap: () => abrir(const AbastecimentoScreen())),
      _Stat(Icons.request_quote_outlined, AppColors.catFipe, t.statFipe,
          v.fipeValor != null ? moeda(v.fipeValor!) : '—',
          onTap: () => abrir(const FipeScreen())),
      _Stat(Icons.tire_repair, AppColors.catCalibragem, t.statCalibragem,
          ultimaCalib != null ? dataCurta(ultimaCalib) : '—',
          onTap: () => abrir(const CalibragemScreen())),
      _Stat(Icons.build_circle_outlined, AppColors.catRevisoes, t.statPrevRevisao,
          prev.vencida ? '' : _fmtPrevisao(prev),
          alerta: prev.vencida,
          onTap: () => abrir(const RevisoesScreen())),
    ];

    return Card(
      color: corCard,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (marca.isEmpty && modelo.isEmpty)
                        Text(v.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppColors.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w700))
                      else ...[
                        if (marca.isNotEmpty)
                          Text(marca,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppColors.dim,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2)),
                        if (modelo.isNotEmpty)
                          Text(modelo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1)),
                      ],
                      if (infoExtra.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(infoExtra,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppColors.dim, fontSize: 12.5)),
                        ),
                    ],
                  ),
                ),
                if (v.placa.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: _PlacaChip(placa: v.placa, fundo: corTile),
                  ),
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 20, color: AppColors.dim),
                  onPressed: onEditar,
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: (1.35 / escala).clamp(1.0, 1.35),
              children:
                  stats.map((s) => _StatTile(stat: s, fundo: corTile)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Formata a previsão da próxima revisão (data, senão km-alvo). O caso
  /// "vencida" é tratado à parte no tile — vira um símbolo de atenção.
  String _fmtPrevisao(PrevisaoRevisao p) {
    if (p.data != null) return dataCurta(p.data!);
    if (p.alvoKm != null) return km(p.alvoKm!);
    return '—';
  }
}

class _Stat {
  final IconData icone;
  final Color cor;
  final String rotulo;
  final String valor;
  final VoidCallback? onTap;

  /// Quando true, o tile mostra um símbolo de atenção centralizado no lugar do
  /// valor (ex.: revisão vencida) em vez de escrever "Vencida".
  final bool alerta;
  const _Stat(this.icone, this.cor, this.rotulo, this.valor,
      {this.onTap, this.alerta = false});
}

class _StatTile extends StatelessWidget {
  final _Stat stat;
  final Color fundo;
  const _StatTile({required this.stat, required this.fundo});

  @override
  Widget build(BuildContext context) {
    // Revisão vencida: em vez de escrever "Vencida", mostra o símbolo de
    // atenção centralizado (mais direto e cabe no tile).
    final conteudo = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: stat.alerta
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.leg(AppColors.warn), size: 24),
                const SizedBox(height: 4),
                Text(stat.rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppColors.dim2, fontSize: 10.5)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(stat.icone, color: AppColors.leg(stat.cor), size: 16),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(stat.valor,
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ),
                Text(stat.rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: AppColors.dim2, fontSize: 10.5)),
              ],
            ),
    );
    if (stat.onTap == null) return conteudo;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: stat.onTap,
        borderRadius: BorderRadius.circular(12),
        child: conteudo,
      ),
    );
  }
}

class _PlacaChip extends StatelessWidget {
  final String placa;
  final Color fundo;
  const _PlacaChip({required this.placa, required this.fundo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lineStrong),
      ),
      child: Text(
        placa.toUpperCase(),
        style: TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Outros carros (os não-selecionados), logo abaixo do principal: cada um ocupa
/// metade da largura. Tocar troca o carro ativo. O botão "Adicionar" aparece
/// enquanto não bateu o limite (até 3 carros) e ocupa a metade que sobra.
class _OutrosCarros extends ConsumerWidget {
  const _OutrosCarros();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final veiculos = ref.watch(veiculosProvider).value ?? const [];
    // Sem carro algum, o cartão "Cadastrar meu carro" já cobre — nada aqui.
    if (veiculos.isEmpty) return const SizedBox.shrink();
    final selId = ref.watch(veiculoSelecionadoProvider)?.id;
    final t = ref.watch(stringsProvider);
    final outros = veiculos.where((v) => v.id != selId).toList();

    final tiles = <Widget>[
      ...outros.map((v) => _CarroTile(
            titulo: v.titulo,
            placa: v.placa,
            onTap: () =>
                ref.read(veiculoSelIdProvider.notifier).definir(v.id),
          )),
      if (veiculos.length < maxVeiculos)
        _CarroTile.adicionar(
          label: t.adicionarCarro,
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VeiculoFormScreen())),
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();

    // Row de Expanded: 1 tile ocupa a linha toda; 2 tiles, metade cada.
    // IntrinsicHeight dá ao Row uma altura limitada — sem ele, o
    // CrossAxisAlignment.stretch pediria altura infinita dentro do ListView
    // (erro de layout que sumia com os botões abaixo).
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: tiles[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarroTile extends StatelessWidget {
  final String titulo;
  final String placa;
  final String label;
  final bool ehAdicionar;
  final VoidCallback onTap;
  const _CarroTile({
    required this.titulo,
    required this.placa,
    required this.onTap,
  })  : ehAdicionar = false,
        label = '';
  const _CarroTile.adicionar({required this.onTap, required this.label})
      : titulo = '',
        placa = '',
        ehAdicionar = true;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: ehAdicionar ? AppColors.accent : AppColors.line),
          ),
          child: ehAdicionar
              ? Row(children: [
                  Icon(Icons.add, size: 18, color: AppColors.accent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ])
              : Row(children: [
                  Icon(Icons.directions_car_filled,
                      size: 18, color: AppColors.dim),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppColors.text,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700)),
                        if (placa.trim().isNotEmpty)
                          Text(placa.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppColors.dim2,
                                  fontSize: 11,
                                  letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                ]),
        ),
      ),
    );
  }
}
