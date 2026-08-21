import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressão do "sumiço dos botões redondos" (v0.13.0): a linha de "outros
/// carros" na Home usa `Row(crossAxisAlignment: stretch, [Expanded, …])` dentro
/// de um `ListView`. Sem `IntrinsicHeight`, o stretch pede ALTURA INFINITA (o
/// eixo vertical do ListView é ilimitado) → erro de layout em runtime que
/// quebrava tudo abaixo na lista. Estes testes travam o padrão certo.
///
/// Espelha a estrutura de `_OutrosCarros` (Row de meio-cards de igual altura).
Widget _linhaMeioCards({required bool comIntrinsicHeight}) {
  const row = Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: SizedBox(height: 40, child: Text('A'))),
      SizedBox(width: 10),
      Expanded(child: SizedBox(height: 60, child: Text('B'))),
    ],
  );
  final linha = comIntrinsicHeight ? const IntrinsicHeight(child: row) : row;
  return MaterialApp(
    home: Scaffold(
      body: ListView(children: [linha, const Text('botões redondos aqui')]),
    ),
  );
}

void main() {
  testWidgets(
      'Row stretch em ListView SEM IntrinsicHeight estoura (documenta o bug)',
      (tester) async {
    await tester.pumpWidget(_linhaMeioCards(comIntrinsicHeight: false));
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('Row stretch em ListView COM IntrinsicHeight rende sem erro',
      (tester) async {
    await tester.pumpWidget(_linhaMeioCards(comIntrinsicHeight: true));
    expect(tester.takeException(), isNull);
    // O conteúdo abaixo (os botões redondos, na Home) continua presente.
    expect(find.text('botões redondos aqui'), findsOneWidget);
  });
}
