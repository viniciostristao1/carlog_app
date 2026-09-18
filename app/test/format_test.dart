import 'package:carlog/util/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resumo (10 primeiras letras p/ os chips do histórico)', () {
    test('texto curto fica inteiro', () {
      expect(resumo('ÓLEO 15W40'), 'ÓLEO 15W40');
      expect(resumo('10 letras!'), '10 letras!');
    });

    test('texto longo corta nas 10 primeiras letras com reticências', () {
      expect(resumo('FILTRO OLEO VECTRA'), 'FILTRO OLE…');
      expect(resumo('PALHETA LIMPADOR 21"'), 'PALHETA LI…');
    });

    test('não deixa espaço sobrando antes das reticências', () {
      expect(resumo('OLEO MOTOR 15W40'), 'OLEO MOTOR…');
    });

    test('espaços nas pontas não contam', () {
      expect(resumo('  OLEO MOTOR  ', max: 10), 'OLEO MOTOR');
      expect(resumo(' OLEO MOTOR VALVOLINE ', max: 4), 'OLEO…');
    });
  });
}
