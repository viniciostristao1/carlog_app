import '../models/abastecimento.dart';

/// Um trecho de consumo "tanque cheio → tanque cheio". A distância é a diferença
/// de odômetro entre dois abastecimentos completos; os litros são tudo que foi
/// abastecido no intervalo (inclui abastecimentos parciais no meio).
class TrechoConsumo {
  final DateTime dataInicio;
  final DateTime dataFim;
  final double distancia; // km
  final double litros;
  final double custo; // R$ gastos no intervalo

  const TrechoConsumo({
    required this.dataInicio,
    required this.dataFim,
    required this.distancia,
    required this.litros,
    required this.custo,
  });

  double get kmPorLitro => litros > 0 ? distancia / litros : 0;
  double get custoPorKm => distancia > 0 ? custo / distancia : 0;
}

/// Resultado consolidado do consumo a partir do histórico de abastecimentos.
class ResumoConsumo {
  final List<TrechoConsumo> trechos; // mais recente primeiro
  final double? mediaGeral; // km/L ponderada (distância/litros do total)
  final double? melhor; // melhor km/L de um trecho
  final double? pior; // pior km/L de um trecho
  final double totalLitros;
  final double totalGasto;

  const ResumoConsumo({
    required this.trechos,
    required this.mediaGeral,
    required this.melhor,
    required this.pior,
    required this.totalLitros,
    required this.totalGasto,
  });

  bool get temMedia => mediaGeral != null;
  static const vazio = ResumoConsumo(
    trechos: [],
    mediaGeral: null,
    melhor: null,
    pior: null,
    totalLitros: 0,
    totalGasto: 0,
  );
}

/// Calcula os trechos full-to-full e as agregações. Precisa de ao menos dois
/// abastecimentos de tanque cheio, com odômetro crescente, para haver média.
ResumoConsumo calcularConsumo(List<Abastecimento> abastecimentos) {
  // Ordena por odômetro (cronologia física do carro).
  final ordenados = [...abastecimentos]
    ..sort((a, b) => a.odometro.compareTo(b.odometro));

  final trechos = <TrechoConsumo>[];
  int? iAnteriorCheio;
  double litrosAcumulados = 0;
  double custoAcumulado = 0;

  for (var j = 0; j < ordenados.length; j++) {
    final atual = ordenados[j];
    if (iAnteriorCheio != null) {
      litrosAcumulados += atual.litros;
      custoAcumulado += atual.total;
    }
    if (atual.tanqueCheio) {
      if (iAnteriorCheio != null) {
        final anterior = ordenados[iAnteriorCheio];
        final dist = atual.odometro - anterior.odometro;
        if (dist > 0 && litrosAcumulados > 0) {
          trechos.add(TrechoConsumo(
            dataInicio: anterior.data,
            dataFim: atual.data,
            distancia: dist,
            litros: litrosAcumulados,
            custo: custoAcumulado,
          ));
        }
      }
      iAnteriorCheio = j;
      litrosAcumulados = 0;
      custoAcumulado = 0;
    }
  }

  if (trechos.isEmpty) {
    return ResumoConsumo.vazio;
  }

  final distTotal = trechos.fold<double>(0, (s, t) => s + t.distancia);
  final litrosTotal = trechos.fold<double>(0, (s, t) => s + t.litros);
  final gastoTotal = trechos.fold<double>(0, (s, t) => s + t.custo);
  final kmls = trechos.map((t) => t.kmPorLitro).toList()..sort();

  trechos.sort((a, b) => b.dataFim.compareTo(a.dataFim)); // recente primeiro

  return ResumoConsumo(
    trechos: trechos,
    mediaGeral: litrosTotal > 0 ? distTotal / litrosTotal : null,
    melhor: kmls.last,
    pior: kmls.first,
    totalLitros: litrosTotal,
    totalGasto: gastoTotal,
  );
}

/// Km rodados num mês, a partir das leituras de odômetro dos abastecimentos.
/// Usa a última leitura antes do mês como base; se não houver, usa a menor
/// leitura do próprio mês.
double kmRodadosNoMes(List<Abastecimento> abastecimentos, int ano, int mes) {
  final inicio = DateTime(ano, mes);
  final fim = DateTime(ano, mes + 1);
  final ordenados = [...abastecimentos]..sort((a, b) => a.data.compareTo(b.data));

  double? base; // último odômetro antes do mês
  double? maxNoMes;
  double? minNoMes;
  for (final a in ordenados) {
    if (a.data.isBefore(inicio)) {
      base = a.odometro;
    } else if (a.data.isBefore(fim)) {
      maxNoMes = (maxNoMes == null || a.odometro > maxNoMes)
          ? a.odometro
          : maxNoMes;
      minNoMes = (minNoMes == null || a.odometro < minNoMes)
          ? a.odometro
          : minNoMes;
    }
  }
  if (maxNoMes == null) return 0;
  final origem = base ?? minNoMes!;
  final km = maxNoMes - origem;
  return km > 0 ? km : 0;
}

/// Ritmo médio de rodagem (km por mês), estimado pelo intervalo entre a primeira
/// e a última leitura de odômetro. Usado para estimar quando cai a próxima revisão.
double? kmPorMesEstimado(List<Abastecimento> abastecimentos) {
  if (abastecimentos.length < 2) return null;
  final ordenados = [...abastecimentos]
    ..sort((a, b) => a.data.compareTo(b.data));
  final distancia = ordenados.last.odometro - ordenados.first.odometro;
  final dias = ordenados.last.data.difference(ordenados.first.data).inDays;
  if (distancia <= 0 || dias <= 0) return null;
  return distancia / dias * 30.0;
}

/// Odômetro mais recente conhecido (maior leitura registrada).
double? ultimoOdometro(List<Abastecimento> abastecimentos) {
  if (abastecimentos.isEmpty) return null;
  return abastecimentos.map((a) => a.odometro).reduce((a, b) => a > b ? a : b);
}
