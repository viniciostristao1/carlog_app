import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';
import '../../widgets/botao_redondo.dart';
import '../../widgets/placa_mercosul.dart';
import 'topo_veiculo.dart';

/// Layouts completos da home — modos **Racing**, **Lista** e **Teclas**,
/// escolhidos no botão de modo ao lado da engrenagem. Todos usam as cores do
/// TEMA atual (`AppColors`), então funcionam em qualquer tema; a diferença está
/// na distribuição e nos atalhos.
///
/// Recebem [DadosTopo] + [AppStrings] prontos (sem Riverpod) para poderem ser
/// testados com dados falsos.

/// Categoria -> (ícone, rótulo, cor, abrir). O badge de lembretes é à parte.
List<(IconData, String, Color, VoidCallback)> _categorias(
        DadosTopo d, AppStrings t) =>
    [
      (
        Icons.local_gas_station,
        t.catAbastecimento,
        AppColors.catAbastecimento,
        d.onAbastecimento
      ),
      (Icons.speed, t.catConsumo, AppColors.catConsumo, d.onConsumo),
      (
        Icons.build_circle_outlined,
        t.catRevisoes,
        AppColors.catRevisoes,
        d.onRevisoes
      ),
      (
        Icons.request_quote_outlined,
        t.catFipe,
        AppColors.catFipe,
        d.onFipe
      ),
      (Icons.tire_repair, t.catCalibragem, AppColors.catCalibragem,
          d.onCalibragem),
      (
        Icons.event_available_outlined,
        t.catLembretes,
        AppColors.catLembretes,
        d.onLembretes
      ),
    ];

Widget _rotulo(String txt) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(children: [
        Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
                color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(txt.toUpperCase(),
            style: TextStyle(
                color: AppColors.dim,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: .4)),
      ]),
    );

/// Fileira(s) de 3 colunas iguais (sem GridView: a altura acompanha o conteúdo,
/// então fonte maior não estoura).
Widget _grade3(List<Widget> itens) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        for (var i = 0; i < itens.length; i += 3) ...[
          if (i > 0) const SizedBox(height: 14),
          Row(children: [
            for (var j = 0; j < 3; j++) ...[
              if (j > 0) const SizedBox(width: 10),
              Expanded(
                  child: i + j < itens.length
                      ? itens[i + j]
                      : const SizedBox.shrink()),
            ],
          ]),
        ],
      ]),
    );

/// Cartão do veículo enxuto (marca/modelo/apelido + placa), usado nos layouts
/// novos — toque abre a edição do veículo.
class _CarroCompacto extends StatelessWidget {
  final DadosTopo d;
  final AppStrings t;
  const _CarroCompacto({required this.d, required this.t});

  @override
  Widget build(BuildContext context) {
    final v = d.veiculo;
    final marca = v.marca.trim();
    final modelo = v.modelo.trim();
    final anoCombustivel = [
      if (v.ano != null) '${v.ano}',
      t.rotuloCombustivel(v.combustivel),
    ].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        onTap: d.onEditarVeiculo,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (marca.isEmpty && modelo.isEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(v.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700)),
                          ),
                          if (anoCombustivel.isNotEmpty)
                            Text(anoCombustivel,
                                style: TextStyle(
                                    color: AppColors.dim,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600)),
                        ],
                      )
                    else ...[
                      Row(children: [
                        Expanded(
                          child: Text(marca,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: AppColors.dim,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (anoCombustivel.isNotEmpty)
                          Text(anoCombustivel,
                              style: TextStyle(
                                  color: AppColors.dim,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                      ]),
                      Text(modelo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppColors.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                    ],
                    if (v.apelido.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(v.apelido.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppColors.dim, fontSize: 12)),
                      ),
                  ]),
            ),
            if (v.placa.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: PlacaMercosul(placa: v.placa),
              ),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── Modo Racing ─────────────────────────

/// Odômetro gigante com a barra da próxima revisão + atalhos em círculos com
/// anel (destaque esportivo).
class LayoutRacing extends StatelessWidget {
  final DadosTopo d;
  final AppStrings t;
  const LayoutRacing({super.key, required this.d, required this.t});

  @override
  Widget build(BuildContext context) {
    final p = d.progresso;
    final temBarra = p.fracao != null && p.alvoKm != null;
    final vencida = d.prev.vencida;
    final corBarra = AppColors.leg(vencida ? AppColors.warn : AppColors.accent);
    final revisao = vencida
        ? t.vencida
        : (p.faltamKm != null ? t.faltamKm(km(p.faltamKm!)) : '—');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.statOdometro.toUpperCase(),
              style: TextStyle(
                  color: AppColors.dim2,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(d.odo != null ? km(d.odo!) : '—',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: temBarra ? p.fracao : 0,
              minHeight: 9,
              backgroundColor: AppColors.surface2,
              color: corBarra,
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Text(t.statPrevRevisao.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.dim2,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
            ),
            const SizedBox(width: 8),
            Text(revisao,
                style: TextStyle(
                    color: AppColors.leg(
                        vencida ? AppColors.warn : AppColors.catRevisoes),
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ]),
        ]),
      ),
      _rotulo(t.atalhos),
      _grade3([
        for (final c in _categorias(d, t))
          BotaoRedondo(
            icone: c.$1,
            rotulo: c.$2,
            cor: AppColors.leg(c.$3),
            tamanho: 68,
            anel: true,
            badge: c.$1 == Icons.event_available_outlined ? d.alertas : 0,
            onTap: c.$4,
          ),
      ]),
      const SizedBox(height: 16),
    ]);
  }
}

// ───────────────────────── Modo Lista ─────────────────────────

/// Lista guiada: cada categoria com o resumo do momento no subtítulo.
class LayoutLista extends StatelessWidget {
  final DadosTopo d;
  final AppStrings t;
  const LayoutLista({super.key, required this.d, required this.t});

  String _subRevisao() {
    if (d.prev.vencida) return t.vencida;
    if (d.prev.data != null) return dataCurta(d.prev.data!);
    final f = d.prev.faltamKm;
    if (f != null && f > 0) return t.faltamKm(km(f));
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final v = d.veiculo;
    final linhas = <(IconData, Color, String, String, VoidCallback)>[
      (
        Icons.local_gas_station,
        AppColors.catAbastecimento,
        t.catAbastecimento,
        d.gastoMes > 0 ? moeda(d.gastoMes) : '—',
        d.onAbastecimento
      ),
      (
        Icons.speed,
        AppColors.catConsumo,
        t.catConsumo,
        d.consumo != null ? kmL(d.consumo!) : '—',
        d.onConsumo
      ),
      (
        Icons.build_circle_outlined,
        AppColors.catRevisoes,
        t.catRevisoes,
        _subRevisao(),
        d.onRevisoes
      ),
      (
        Icons.request_quote_outlined,
        AppColors.catFipe,
        t.catFipe,
        v.fipeValor != null ? moeda(v.fipeValor!) : '—',
        d.onFipe
      ),
      (
        Icons.tire_repair,
        AppColors.catCalibragem,
        t.catCalibragem,
        d.ultimaCalib != null ? desdeAte(d.ultimaCalib!) : '—',
        d.onCalibragem
      ),
      (
        Icons.event_available_outlined,
        AppColors.catLembretes,
        t.catLembretes,
        d.alertas > 0 ? t.vencidos(d.alertas) : t.emDia,
        d.onLembretes
      ),
    ];

    return Column(children: [
      _CarroCompacto(d: d, t: t),
      const SizedBox(height: 14),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(children: [
          for (var i = 0; i < linhas.length; i++) ...[
            _linha(linhas[i]),
            if (i < linhas.length - 1)
              Divider(height: 1, thickness: 1, color: AppColors.line),
          ],
        ]),
      ),
      const SizedBox(height: 16),
    ]);
  }

  Widget _linha((IconData, Color, String, String, VoidCallback) l) {
    final cor = AppColors.leg(l.$2);
    return InkWell(
      onTap: l.$5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: cor.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(11)),
            child: Icon(l.$1, color: cor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                  Text(l.$4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.dim, fontSize: 11.5)),
                ]),
          ),
          Icon(Icons.chevron_right, color: AppColors.dim2, size: 19),
        ]),
      ),
    );
  }
}

// ───────────────────────── Modo Teclas ─────────────────────────

/// Painel de "teclas" grandes (fácil de acertar) + resumo do mês.
class LayoutTeclas extends StatelessWidget {
  final DadosTopo d;
  final AppStrings t;
  const LayoutTeclas({super.key, required this.d, required this.t});

  @override
  Widget build(BuildContext context) {
    final revisao = d.prev.vencida
        ? t.vencida
        : (d.prev.data != null
            ? dataCurta(d.prev.data!)
            : (d.prev.faltamKm != null && d.prev.faltamKm! > 0
                ? t.faltamKm(km(d.prev.faltamKm!))
                : '—'));

    return Column(children: [
      _CarroCompacto(d: d, t: t),
      _rotulo(t.atalhos),
      _grade3([
        for (final c in _categorias(d, t))
          _Tecla(
            icone: c.$1,
            rotulo: c.$2,
            cor: AppColors.leg(c.$3),
            badge: c.$1 == Icons.event_available_outlined ? d.alertas : 0,
            onTap: c.$4,
          ),
      ]),
      const SizedBox(height: 14),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(
            child: _Mini(
              icone: Icons.speed,
              cor: AppColors.leg(AppColors.catConsumo),
              valor: d.consumo != null ? kmL(d.consumo!) : '—',
              rotulo: t.catConsumo,
              onTap: d.onConsumo,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Mini(
              icone: Icons.local_gas_station,
              cor: AppColors.leg(AppColors.catAbastecimento),
              valor: d.gastoMes > 0 ? moeda(d.gastoMes) : '—',
              rotulo: t.statCombustivelMes,
              onTap: d.onAbastecimento,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Mini(
              icone: Icons.build_circle_outlined,
              cor: AppColors.leg(AppColors.catRevisoes),
              valor: revisao,
              rotulo: t.statPrevRevisao,
              onTap: d.onRevisoes,
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
    ]);
  }
}

/// Botão estilo "tecla de painel": gradiente sutil, borda e sombra.
class _Tecla extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final Color cor;
  final VoidCallback onTap;
  final int badge;
  const _Tecla({
    required this.icone,
    required this.rotulo,
    required this.cor,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surface2, AppColors.surface]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.lineStrong, width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 6,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icone, color: cor, size: 24),
              const SizedBox(height: 6),
              Text(rotulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.1)),
            ]),
            if (badge > 0)
              Positioned(
                top: -8,
                right: -2,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Cartãozinho de resumo (valor grande + rótulo).
class _Mini extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String valor;
  final String rotulo;
  final VoidCallback onTap;
  const _Mini({
    required this.icone,
    required this.cor,
    required this.valor,
    required this.rotulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.line)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icone, color: cor, size: 19),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(valor,
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800)),
                ),
                Text(rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.dim2,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ]),
        ),
      ),
    );
  }
}
