import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final abastecimentos = ref.watch(abastecimentosProvider).value ?? const [];
    final odo = ultimoOdometro(abastecimentos);
    final agora = DateTime.now();
    final kmMes = kmRodadosNoMes(abastecimentos, agora.year, agora.month);

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
                      Text('Apelido, marca/modelo, placa e tanque',
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

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onEditar,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_car_filled,
                        color: AppColors.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.titulo,
                            style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (v.marca.isNotEmpty || v.modelo.isNotEmpty)
                              '${v.marca} ${v.modelo}'.trim(),
                            if (v.ano != null) '${v.ano}',
                            v.combustivel.rotulo,
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: const TextStyle(
                              color: AppColors.dim, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (v.placa.trim().isNotEmpty) _PlacaChip(placa: v.placa),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      rotulo: 'Odômetro',
                      valor: odo != null ? km(odo) : '—',
                    ),
                  ),
                  Container(width: 1, height: 34, color: AppColors.line),
                  Expanded(
                    child: _MiniStat(
                      rotulo: 'Este mês',
                      valor: kmMes > 0 ? km(kmMes) : '—',
                    ),
                  ),
                  Container(width: 1, height: 34, color: AppColors.line),
                  Expanded(
                    child: _MiniStat(
                      rotulo: 'FIPE',
                      valor: v.fipeValor != null ? moeda(v.fipeValor!) : '—',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class _MiniStat extends StatelessWidget {
  final String rotulo;
  final String valor;
  const _MiniStat({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(rotulo,
            style: const TextStyle(color: AppColors.dim2, fontSize: 11.5)),
      ],
    );
  }
}
