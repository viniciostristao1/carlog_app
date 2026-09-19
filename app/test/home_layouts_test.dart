import 'package:carlog/features/home/layouts_home.dart';
import 'package:carlog/features/home/topo_veiculo.dart';
import 'package:carlog/l10n/strings.dart';
import 'package:carlog/models/veiculo.dart';
import 'package:carlog/theme/app_colors.dart';
import 'package:carlog/util/consumo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Os 3 layouts novos da home (Racing, Lista e Teclas) não podem estourar em
/// nenhum tema nem com a fonte no máximo (1,3×). Estes testes montam cada um
/// com dados falsos e cobram que nenhuma exceção de layout apareça.
void main() {
  DadosTopo dados({double? consumo = 11.4}) => DadosTopo(
        veiculo: const Veiculo(
          id: 'v',
          apelido: 'Corsa',
          marca: 'GM - Chevrolet',
          modelo: 'Corsa Hat. Maxx 1.4 8V',
          ano: 2012,
          placa: 'ITI999',
          fipeValor: 32818,
        ),
        odo: 169211,
        kmMes: 695,
        gastoMes: 414.55,
        ultimaCalib: DateTime.now().subtract(const Duration(days: 11)),
        prev: const PrevisaoRevisao(
            alvoKm: 176710, faltamKm: 7499, mediaKmMes12: 1200),
        progresso: const ProgressoRevisao(
            baseKm: 166710,
            alvoKm: 176710,
            atualKm: 169211,
            fracao: .25,
            faltamKm: 7499),
        agora: DateTime.now(),
        escala: 1,
        consumo: consumo,
        alertas: 2,
        onAbastecimento: () {},
        onConsumo: () {},
        onFipe: () {},
        onCalibragem: () {},
        onRevisoes: () {},
        onLembretes: () {},
        onEditarVeiculo: () {},
      );

  Future<void> monta(WidgetTester tester, Widget w, {double fonte = 1.0}) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: fonte,
        maxScaleFactor: fonte,
        child: child!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: w)),
    ));
  }

  final layouts = <String, Widget Function()>{
    'Racing': () => LayoutRacing(d: dados(), t: const AppStrings(Idioma.pt)),
    'Lista': () => LayoutLista(d: dados(), t: const AppStrings(Idioma.pt)),
    'Teclas': () => LayoutTeclas(d: dados(), t: const AppStrings(Idioma.pt)),
  };

  layouts.forEach((nome, build) {
    testWidgets('$nome renderiza sem estouro (fonte normal)', (t) async {
      await monta(t, build());
      expect(t.takeException(), isNull);
      expect(find.text('Abastecimento'), findsWidgets);
    });

    testWidgets('$nome renderiza sem estouro (fonte 1,3×)', (t) async {
      await monta(t, build(), fonte: 1.3);
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('Racing mostra o odômetro e a falta p/ revisão', (t) async {
    await monta(t, LayoutRacing(d: dados(), t: const AppStrings(Idioma.pt)));
    expect(find.textContaining('169.211'), findsOneWidget);
    expect(find.textContaining('7.499'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // badge de lembretes no anel
  });

  testWidgets('Lista mostra os resumos (consumo, FIPE e lembretes)', (t) async {
    await monta(t, LayoutLista(d: dados(), t: const AppStrings(Idioma.pt)));
    expect(find.textContaining('11,4'), findsOneWidget);
    expect(find.textContaining('32.818'), findsOneWidget);
    expect(find.text('2 vencidos'), findsOneWidget);
  });

  testWidgets('Lista sem consumo mostraria travessão (não quebra)', (t) async {
    await monta(t,
        LayoutLista(d: dados(consumo: null), t: const AppStrings(Idioma.pt)));
    expect(t.takeException(), isNull);
  });

  testWidgets('layouts no tema Daylight (claro) não estouram', (t) async {
    AppColors.aplicarTema(TemaApp.daylight);
    addTearDown(() => AppColors.aplicarTema(TemaApp.terracota));
    for (final build in layouts.values) {
      await monta(t, build());
      expect(t.takeException(), isNull);
    }
  });
}
