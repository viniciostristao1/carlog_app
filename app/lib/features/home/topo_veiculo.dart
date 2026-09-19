import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/veiculo.dart';
import '../../services/prefs.dart';
import '../../theme/app_colors.dart';
import '../../util/consumo.dart';
import '../../util/format.dart';

/// Dados já calculados do topo da home, compartilhados pelos 3 modos de
/// exibição (painel, grade e progresso). Os callbacks abrem as telas de cada
/// indicador.
class DadosTopo {
  final Veiculo veiculo;
  final double? odo;
  final double kmMes;
  final double gastoMes;
  final DateTime? ultimaCalib;
  final PrevisaoRevisao prev;
  final ProgressoRevisao progresso;
  final DateTime agora;
  final double escala;
  final double? consumo; // km/L médio (ResumoConsumo.mediaGeral)
  final int alertas; // lembretes vencidos não lidos (badge)
  final VoidCallback onAbastecimento;
  final VoidCallback onConsumo;
  final VoidCallback onFipe;
  final VoidCallback onCalibragem;
  final VoidCallback onRevisoes;
  final VoidCallback onLembretes;
  final VoidCallback onEditarVeiculo;

  const DadosTopo({
    required this.veiculo,
    required this.odo,
    required this.kmMes,
    required this.gastoMes,
    required this.ultimaCalib,
    required this.prev,
    required this.progresso,
    required this.agora,
    required this.escala,
    required this.consumo,
    required this.alertas,
    required this.onAbastecimento,
    required this.onConsumo,
    required this.onFipe,
    required this.onCalibragem,
    required this.onRevisoes,
    required this.onLembretes,
    required this.onEditarVeiculo,
  });

  /// Dias desde a última calibragem (null = nunca registrada).
  int? get diasCalib =>
      ultimaCalib == null ? null : agora.difference(ultimaCalib!).inDays;
}

/// Botão único do modo de exibição (fica na AppBar, à esquerda da engrenagem):
/// mostra o ícone do modo atual e, a cada toque, alterna para o próximo
/// (painel → grade → progresso). A escolha fica salva no aparelho.
class TopoModoBotao extends ConsumerWidget {
  const TopoModoBotao({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final atual = ref.watch(modoTopoProvider).value ?? ModoTopo.painel;
    final (icone, nome) = switch (atual) {
      ModoTopo.painel => (Icons.space_dashboard_outlined, t.modoPainel),
      ModoTopo.grade => (Icons.grid_view_rounded, t.modoGrade),
      ModoTopo.progresso => (Icons.linear_scale, t.modoProgresso),
      ModoTopo.racing => (Icons.speed_outlined, t.modoRacing),
      ModoTopo.lista => (Icons.format_list_bulleted, t.modoLista),
      ModoTopo.teclas => (Icons.keyboard_alt_outlined, t.modoTeclas),
    };
    return IconButton(
      tooltip: '${t.modoExibicao}: $nome',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Icon(icone, key: ValueKey(atual), color: AppColors.accent),
      ),
      onPressed: () {
        final proximo =
            ModoTopo.values[(atual.index + 1) % ModoTopo.values.length];
        ref.read(modoTopoProvider.notifier).definir(proximo);
      },
    );
  }
}

/// Modo 1 — Painel digital: 6 números em 2 colunas, com divisórias finas.
class TopoPainel extends ConsumerWidget {
  final DadosTopo d;
  const TopoPainel({super.key, required this.d});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final calib =
        d.diasCalib == null ? '—' : '${n0(d.diasCalib!)} ${t.unidadeDias}';
    // No painel, a previsão mostra a DATA provável (como nos tiles); "faltam
    // km" fica só no modo com a barra de progresso.
    final revisao = d.prev.vencida
        ? t.vencida
        : (d.prev.data != null ? dataCurta(d.prev.data!) : '—');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lineStrong),
      ),
      child: Column(
        children: [
          _linha(
            _item(Icons.speed, AppColors.accent,
                d.odo != null ? km(d.odo!) : '—', t.statOdometro,
                d.onAbastecimento),
            _item(Icons.calendar_month, AppColors.catConsumo,
                d.kmMes > 0 ? km(d.kmMes) : '—', t.statKmMes, d.onConsumo),
          ),
          _divisoria(),
          _linha(
            _item(Icons.local_gas_station, AppColors.catAbastecimento,
                d.gastoMes > 0 ? moeda(d.gastoMes) : '—',
                t.statCombustivelMes, d.onAbastecimento),
            _item(Icons.request_quote_outlined, AppColors.catFipe,
                d.veiculo.fipeValor != null ? moeda(d.veiculo.fipeValor!) : '—',
                t.statFipe, d.onFipe),
          ),
          _divisoria(),
          _linha(
            _item(Icons.tire_repair, AppColors.catCalibragem, calib,
                t.statCalibragem, d.onCalibragem),
            _item(Icons.build_circle_outlined, AppColors.catRevisoes, revisao,
                t.statPrevRevisao, d.onRevisoes,
                alerta: d.prev.vencida),
          ),
        ],
      ),
    );
  }

  Widget _divisoria() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: AppColors.line, height: 1));

  Widget _linha(Widget a, Widget b) => Row(
        children: [
          Expanded(child: a),
          Container(width: 1, height: 40, color: AppColors.line),
          Expanded(child: b),
        ],
      );

  Widget _item(IconData icone, Color cor, String valor, String rotulo,
          VoidCallback onTap,
          {bool alerta = false}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            children: [
              Icon(alerta ? Icons.warning_amber_rounded : icone,
                  size: 16,
                  color: AppColors.leg(alerta ? AppColors.warn : cor)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(valor,
                          style: TextStyle(
                              color: AppColors.text,
                              fontSize: 18,
                              height: 1.05,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])),
                    ),
                    const SizedBox(height: 2),
                    Text(rotulo.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.dim2,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// Modo 2 — Grade: tiles com o fundo na cor da categoria (como os botões).
class TopoGrade extends ConsumerWidget {
  final DadosTopo d;
  const TopoGrade({super.key, required this.d});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final prevValor = d.prev.vencida
        ? ''
        : d.prev.data != null
            ? dataCurta(d.prev.data!)
            : (d.prev.faltamKm != null && d.prev.faltamKm! > 0)
                ? t.faltamKm(km(d.prev.faltamKm!))
                : '—';

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 10,
      childAspectRatio: (1.35 / d.escala).clamp(1.0, 1.35),
      children: [
        _tile(Icons.speed, AppColors.accent, d.odo != null ? km(d.odo!) : '—',
            t.statOdometro, d.onAbastecimento),
        _tile(Icons.calendar_month, AppColors.catConsumo,
            d.kmMes > 0 ? km(d.kmMes) : '—', t.statKmMes, d.onConsumo),
        _tile(Icons.local_gas_station, AppColors.catAbastecimento,
            d.gastoMes > 0 ? moeda(d.gastoMes) : '—', t.statCombustivelMes,
            d.onAbastecimento),
        _tile(Icons.request_quote_outlined, AppColors.catFipe,
            d.veiculo.fipeValor != null ? moeda(d.veiculo.fipeValor!) : '—',
            t.statFipe, d.onFipe),
        _tile(Icons.tire_repair, AppColors.catCalibragem,
            d.ultimaCalib != null ? dataCurta(d.ultimaCalib!) : '—',
            t.statCalibragem, d.onCalibragem),
        _tile(Icons.build_circle_outlined, AppColors.catRevisoes, prevValor,
            t.statPrevRevisao, d.onRevisoes,
            alerta: d.prev.vencida),
      ],
    );
  }

  Widget _tile(IconData icone, Color cor, String valor, String rotulo,
          VoidCallback onTap,
          {bool alerta = false}) =>
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cor.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(alerta ? Icons.warning_amber_rounded : icone,
                    color: AppColors.leg(alerta ? AppColors.warn : cor),
                    size: 16),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(valor,
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ),
                Text(rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.dim, fontSize: 10.5)),
              ],
            ),
          ),
        ),
      );
}

/// Modo 3 — Progresso: barra da próxima revisão + chips dos demais.
class TopoProgresso extends ConsumerWidget {
  final DadosTopo d;
  const TopoProgresso({super.key, required this.d});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final p = d.progresso;
    final temBarra = p.fracao != null && p.alvoKm != null && p.atualKm != null;
    final corBarra =
        AppColors.leg(d.prev.vencida ? AppColors.warn : AppColors.catRevisoes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(t.statPrevRevisao.toUpperCase(),
                  style: TextStyle(
                      color: AppColors.dim2,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
            ),
            Text(
              d.prev.vencida
                  ? t.vencida
                  : (p.faltamKm != null
                      ? t.faltamKm(km(p.faltamKm!))
                      : '—'),
              style: TextStyle(
                  color: AppColors.leg(
                      d.prev.vencida ? AppColors.warn : AppColors.catRevisoes),
                  fontSize: 12,
                  fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: temBarra ? p.fracao : 0,
            minHeight: 10,
            backgroundColor: AppColors.surface2,
            color: corBarra,
          ),
        ),
        const SizedBox(height: 6),
        if (temBarra)
          Row(
            children: [
              Text(km(p.atualKm!),
                  style: TextStyle(color: AppColors.dim, fontSize: 11)),
              const Spacer(),
              Text('${t.meta} ${km(p.alvoKm!)}',
                  style: TextStyle(color: AppColors.dim, fontSize: 11)),
            ],
          ),
        const SizedBox(height: 14),
        Divider(color: AppColors.line, height: 1),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(Icons.speed, AppColors.accent,
                d.odo != null ? km(d.odo!) : '—', d.onAbastecimento),
            _chip(Icons.calendar_month, AppColors.catConsumo,
                d.kmMes > 0 ? km(d.kmMes) : '—', d.onConsumo),
            _chip(Icons.local_gas_station, AppColors.catAbastecimento,
                d.gastoMes > 0 ? moeda(d.gastoMes) : '—', d.onAbastecimento),
            _chip(Icons.request_quote_outlined, AppColors.catFipe,
                d.veiculo.fipeValor != null ? moeda(d.veiculo.fipeValor!) : '—',
                d.onFipe),
            _chip(Icons.tire_repair, AppColors.catCalibragem,
                d.ultimaCalib != null ? dataCurta(d.ultimaCalib!) : '—',
                d.onCalibragem),
          ],
        ),
      ],
    );
  }

  Widget _chip(IconData icone, Color cor, String texto, VoidCallback onTap) =>
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 13, color: AppColors.leg(cor)),
                const SizedBox(width: 5),
                Text(texto,
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}
