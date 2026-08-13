import 'package:carlog/models/abastecimento.dart';
import 'package:carlog/util/consumo.dart';
import 'package:flutter_test/flutter_test.dart';

Abastecimento _ab(String id, DateTime data, double odo, double litros,
        {bool cheio = true, double preco = 5.0}) =>
    Abastecimento(
      id: id,
      data: data,
      odometro: odo,
      litros: litros,
      precoLitro: preco,
      tanqueCheio: cheio,
    );

void main() {
  group('calcularConsumo', () {
    test('sem dados suficientes não produz média', () {
      expect(calcularConsumo([]).temMedia, isFalse);
      final um = [_ab('1', DateTime(2026, 1, 1), 1000, 40)];
      expect(calcularConsumo(um).temMedia, isFalse);
    });

    test('dois tanques cheios: km/L = distância / litros do 2º', () {
      final lista = [
        _ab('1', DateTime(2026, 1, 1), 1000, 40),
        _ab('2', DateTime(2026, 1, 10), 1400, 40), // 400 km / 40 L = 10 km/L
      ];
      final r = calcularConsumo(lista);
      expect(r.temMedia, isTrue);
      expect(r.trechos.length, 1);
      expect(r.mediaGeral, closeTo(10.0, 1e-9));
    });

    test('abastecimento parcial no meio soma litros no trecho', () {
      final lista = [
        _ab('1', DateTime(2026, 1, 1), 1000, 40),
        _ab('2', DateTime(2026, 1, 5), 1200, 10, cheio: false), // parcial
        _ab('3', DateTime(2026, 1, 10), 1400, 30), // cheio
        // trecho 1000->1400 = 400 km, litros = 10 + 30 = 40 => 10 km/L
      ];
      final r = calcularConsumo(lista);
      expect(r.trechos.length, 1);
      expect(r.trechos.first.litros, closeTo(40, 1e-9));
      expect(r.mediaGeral, closeTo(10.0, 1e-9));
    });
  });

  group('kmRodadosNoMes', () {
    test('usa a leitura anterior ao mês como base', () {
      final lista = [
        _ab('1', DateTime(2026, 5, 28), 10000, 40),
        _ab('2', DateTime(2026, 6, 15), 10600, 40),
        _ab('3', DateTime(2026, 6, 28), 10900, 40),
      ];
      // junho: base = 10000 (maio), max = 10900 => 900 km
      expect(kmRodadosNoMes(lista, 2026, 6), closeTo(900, 1e-9));
    });
  });

  group('ritmoKmPorDia e previsaoData (previsão da próxima revisão)', () {
    test('ritmo usa todo o histórico quando a janela recente é vazia', () {
      final lista = [
        _ab('1', DateTime(2026, 1, 1), 1000, 40),
        _ab('2', DateTime(2026, 1, 11), 1400, 40), // 400 km em 10 dias
      ];
      expect(ritmoKmPorDia(lista), closeTo(40.0, 1e-9)); // 40 km/dia
    });

    test('previsaoData soma os dias corretos', () {
      final d = previsaoData(400, 40); // 400 km a 40 km/dia = 10 dias
      expect(d, isNotNull);
      final dias = d!.difference(DateTime.now()).inDays;
      expect(dias, inInclusiveRange(9, 10));
    });

    test('previsaoData nula sem ritmo ou já vencido', () {
      expect(previsaoData(100, null), isNull);
      expect(previsaoData(0, 40), isNull);
      expect(previsaoData(-50, 40), isNull);
    });
  });
}
