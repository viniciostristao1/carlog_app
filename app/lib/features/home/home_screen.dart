import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/abastecimento.dart';
import '../../models/revisao.dart';
import '../../models/veiculo.dart';
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
    final veiculo = ref.watch(veiculoProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CarLog'),
        actions: [
          IconButton(
            tooltip: 'Configurações',
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
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                'O que você quer registrar?',
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
              childAspectRatio: 0.82,
              children: [
                BotaoRedondo(
                  icone: Icons.local_gas_station,
                  rotulo: 'Abastecimento',
                  cor: AppColors.catAbastecimento,
                  onTap: () => _abrir(context, const AbastecimentoScreen()),
                ),
                BotaoRedondo(
                  icone: Icons.speed,
                  rotulo: 'Consumo / Média',
                  cor: AppColors.catConsumo,
                  onTap: () => _abrir(context, const MediaScreen()),
                ),
                BotaoRedondo(
                  icone: Icons.build_circle_outlined,
                  rotulo: 'Revisões',
                  cor: AppColors.catRevisoes,
                  onTap: () => _abrir(context, const RevisoesScreen()),
                ),
                BotaoRedondo(
                  icone: Icons.request_quote_outlined,
                  rotulo: 'Minha FIPE',
                  cor: AppColors.catFipe,
                  onTap: () => _abrir(context, const FipeScreen()),
                ),
                BotaoRedondo(
                  icone: Icons.tire_repair,
                  rotulo: 'Calibragem',
                  cor: AppColors.catCalibragem,
                  onTap: () => _abrir(context, const CalibragemScreen()),
                ),
                BotaoRedondo(
                  icone: Icons.event_available_outlined,
                  rotulo: 'Lembretes',
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
    final v = veiculo;
    if (v == null) {
      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onEditar,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.directions_car_filled,
                    color: AppColors.accent, size: 34),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cadastrar meu carro',
                          style: TextStyle(
                              color: AppColors.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Busque pela tabela FIPE (marca, modelo, ano)',
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

    final abastecimentos = ref.watch(abastecimentosProvider).value ?? const [];
    final revisoes = ref.watch(revisoesProvider).value ?? const [];
    final calibragens = ref.watch(calibragemProvider).value ?? const [];
    final agora = DateTime.now();

    final odo = ultimoOdometro(abastecimentos);
    final kmMes = kmRodadosNoMes(abastecimentos, agora.year, agora.month);
    final gastoMes = abastecimentos
        .where((a) => a.data.year == agora.year && a.data.month == agora.month)
        .fold<double>(0, (s, a) => s + a.total);
    final ultimaCalib = calibragens.isEmpty
        ? null
        : (calibragens.map((c) => c.data).reduce((a, b) => a.isAfter(b) ? a : b));

    // subtítulo só quando há apelido (evita repetir marca/modelo do título)
    final temApelido = v.apelido.trim().isNotEmpty;
    final subInfo = [
      if (v.marca.isNotEmpty || v.modelo.isNotEmpty)
        '${v.marca} ${v.modelo}'.trim(),
      if (v.ano != null) '${v.ano}',
      v.combustivel.rotulo,
    ].where((s) => s.isNotEmpty).join(' · ');

    final stats = <_Stat>[
      _Stat(Icons.speed, AppColors.accent, 'Odômetro',
          odo != null ? km(odo) : '—'),
      _Stat(Icons.calendar_month, AppColors.catConsumo, 'Km no mês',
          kmMes > 0 ? km(kmMes) : '—'),
      _Stat(Icons.local_gas_station, AppColors.catAbastecimento,
          'Combustível/mês', gastoMes > 0 ? moeda(gastoMes) : '—'),
      _Stat(Icons.request_quote_outlined, AppColors.catFipe, 'FIPE',
          v.fipeValor != null ? moeda(v.fipeValor!) : '—'),
      _Stat(Icons.tire_repair, AppColors.catCalibragem, 'Calibragem',
          ultimaCalib != null ? dataCurta(ultimaCalib) : '—'),
      _Stat(Icons.build_circle_outlined, AppColors.catRevisoes, 'Prev. revisão',
          _estimativaRevisao(v, abastecimentos, revisoes)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      if (temApelido && subInfo.isNotEmpty)
                        Text(subInfo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.dim, fontSize: 12.5)),
                    ],
                  ),
                ),
                if (v.placa.trim().isNotEmpty) _PlacaChip(placa: v.placa),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
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
              childAspectRatio: 1.35,
              children: stats.map((s) => _StatTile(stat: s)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Estimativa da próxima revisão: a data mais próxima entre a projeção por km
  /// (odômetro + ritmo de rodagem) e a por tempo (última revisão + meses). Cai
  /// para o km-alvo se não houver data.
  String _estimativaRevisao(
      Veiculo v, List<Abastecimento> abastecimentos, List<Revisao> revisoes) {
    final odo = ultimoOdometro(abastecimentos);
    final comOdo = revisoes.where((r) => r.odometro != null).toList()
      ..sort((a, b) => a.odometro!.compareTo(b.odometro!));
    final baseOdo = comOdo.isNotEmpty ? comOdo.last.odometro! : odo;

    DateTime? dataKm;
    if (baseOdo != null && odo != null) {
      final faltam = baseOdo + v.revisaoIntervaloKm - odo;
      dataKm = previsaoData(faltam.toDouble(), ritmoKmPorDia(abastecimentos));
    }

    DateTime? dataTempo;
    if (revisoes.isNotEmpty) {
      final ult = revisoes
          .map((r) => r.data)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      dataTempo =
          DateTime(ult.year, ult.month + v.revisaoIntervaloMeses, ult.day);
    }

    final datas = [dataKm, dataTempo].whereType<DateTime>().toList()..sort();
    if (datas.isNotEmpty) return dataCurta(datas.first);
    if (baseOdo != null) return km(baseOdo + v.revisaoIntervaloKm);
    return '—';
  }
}

class _Stat {
  final IconData icone;
  final Color cor;
  final String rotulo;
  final String valor;
  const _Stat(this.icone, this.cor, this.rotulo, this.valor);
}

class _StatTile extends StatelessWidget {
  final _Stat stat;
  const _StatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stat.icone, color: stat.cor, size: 16),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(stat.valor,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ),
          Text(stat.rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.dim2, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _PlacaChip extends StatelessWidget {
  final String placa;
  const _PlacaChip({required this.placa});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lineStrong),
      ),
      child: Text(
        placa.toUpperCase(),
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
