import 'package:carlog/models/abastecimento.dart';
import 'package:carlog/models/revisao.dart';
import 'package:carlog/models/veiculo.dart';
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

  group('preverRevisao', () {
    test('alvo = última revisão + intervalo do CADASTRO (não infere do histórico)',
        () {
      const v = Veiculo(id: 'v', apelido: 'x'); // intervalo do cadastro = 10000
      final revs = [
        Revisao(id: 'r1', data: DateTime(2024, 11, 5), odometro: 80161),
        Revisao(id: 'r2', data: DateTime(2025, 8, 14), odometro: 100500),
      ];
      final ab = [
        _ab('a1', DateTime(2025, 11, 20), 105557, 40),
        _ab('a2', DateTime(2026, 2, 9), 110570, 40),
      ];
      final p = preverRevisao(v, ab, revs);
      // 100500 (última revisão) + 10000 (cadastro) = 110500; km atual = 110570.
      expect(p.alvoKm, closeTo(110500, 1));
      expect(p.faltamKm, closeTo(110500 - 110570, 1));
    });

    test('data = última revisão + tempo para rodar 1 intervalo (ritmo 12 meses)',
        () {
      final agora = DateTime.now();
      const v = Veiculo(id: 'v', apelido: 'x'); // intervalo do cadastro = 10000
      final revs = [
        Revisao(
            id: 'r',
            data: agora.subtract(const Duration(days: 10)),
            odometro: 13000),
      ];
      final ab = [
        _ab('a', agora.subtract(const Duration(days: 100)), 10000, 40),
      ];
      final p = preverRevisao(v, ab, revs);
      // ritmo = (13000-10000)/90 ≈ 33,33 km/dia → 10000/33,33 ≈ 300 dias após a
      // revisão (agora-10) → ≈ agora + 290 dias.
      expect(p.alvoKm, closeTo(23000, 1));
      expect(p.data, isNotNull);
      expect(p.data!.difference(agora).inDays, inInclusiveRange(285, 295));
    });

    test('sem leituras não estima', () {
      const v = Veiculo(id: 'v', apelido: 'x');
      expect(preverRevisao(v, const [], const []).alvoKm, isNull);
    });
  });

  group('progressoRevisao', () {
    test('metade do intervalo percorrido (base 40k, alvo 50k, atual 45k)', () {
      const v = Veiculo(id: 'v', apelido: 'x'); // intervalo 10000
      final revs = [
        Revisao(id: 'r', data: DateTime(2026, 1, 10), odometro: 40000),
      ];
      final ab = [
        _ab('a', DateTime(2026, 3, 1), 45000, 40),
      ];
      final p = progressoRevisao(v, ab, revs);
      expect(p.baseKm, closeTo(40000, 1));
      expect(p.alvoKm, closeTo(50000, 1));
      expect(p.atualKm, closeTo(45000, 1));
      expect(p.fracao, closeTo(0.5, 1e-9));
      expect(p.faltamKm, closeTo(5000, 1));
    });

    test('passou do alvo: fração trava em 1', () {
      const v = Veiculo(id: 'v', apelido: 'x');
      final revs = [
        Revisao(id: 'r', data: DateTime(2026, 1, 10), odometro: 40000),
      ];
      final ab = [
        _ab('a', DateTime(2026, 3, 1), 52000, 40),
      ];
      final p = progressoRevisao(v, ab, revs);
      expect(p.fracao, 1.0);
      expect(p.faltamKm, closeTo(-2000, 1));
    });

    test('sem intervalo ou sem leitura → vazio', () {
      const semIntervalo = Veiculo(id: 'v', apelido: 'x', revisaoIntervaloKm: 0);
      final revs = [
        Revisao(id: 'r', data: DateTime(2026, 1, 10), odometro: 40000),
      ];
      expect(progressoRevisao(semIntervalo, const [], revs).fracao, isNull);
      const v = Veiculo(id: 'v', apelido: 'x');
      expect(progressoRevisao(v, const [], const []).fracao, isNull);
    });
  });

  group('sugestaoOdometro', () {
    test('sem ritmo (1 leitura) não sugere — não repete o último odômetro', () {
      final ab = [_ab('1', DateTime(2026, 9, 10), 45000, 40)];
      expect(sugestaoOdometro(ab, const []), isNull);
    });

    test('último + ritmo (km/dia) × dias desde a última leitura', () {
      final agora = DateTime.now();
      final ab = [
        _ab('1', agora.subtract(const Duration(days: 30)), 44000, 40),
        _ab('2', agora.subtract(const Duration(days: 10)), 45000, 40),
      ];
      // ritmo = 1000 km / 20 dias = 50 km/dia; 10 dias após a última → 45.500.
      expect(sugestaoOdometro(ab, const []), 45500);
    });

    test('leitura de hoje projeta 1 dia de rodagem (não repete o valor)', () {
      final agora = DateTime.now();
      final ab = [
        _ab('1', agora.subtract(const Duration(days: 30)), 44000, 40),
        _ab('2', agora, 45000, 40),
      ];
      final r = sugestaoOdometro(ab, const []);
      expect(r, isNotNull);
      expect(r, greaterThan(45000));
      expect(r, lessThanOrEqualTo(45034));
    });

    test('leitura de revisão conta como base do ritmo', () {
      final agora = DateTime.now();
      final ab = [
        _ab('1', agora.subtract(const Duration(days: 20)), 50000, 40),
      ];
      final revs = [
        Revisao(
            id: 'r',
            data: agora.subtract(const Duration(days: 10)),
            odometro: 51000),
      ];
      // ritmo = 1000/10 = 100 km/dia; 10 dias após a revisão → 52.000.
      expect(sugestaoOdometro(ab, revs), 52000);
    });
  });
}
