import 'package:carlog/features/revisoes/itens_sugeridos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('peças novas de direção/suspensão aparecem na busca', () {
    expect(sugestoesPara('ponteira').map((e) => e.nome),
        contains('Ponteira de direção'));
    expect(sugestoesPara('barra axial').map((e) => e.nome),
        contains('Barra axial'));
    expect(sugestoesPara('articulação').map((e) => e.nome),
        contains('Articulação da direção'));
    expect(sugestoesPara('bucha').map((e) => e.nome),
        contains('Bucha da barra estabilizadora'));
  });

  test('peças de embreagem aparecem na busca', () {
    final r = sugestoesPara('embreagem').map((e) => e.nome).toList();
    expect(r, contains('Rolamento de embreagem'));
    expect(r, contains('Disco de embreagem'));
    expect(r, contains('Platô de embreagem'));
  });
}
