import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/lembrete.dart';
import '../util/consumo.dart';
import '../util/format.dart';
import 'repositories.dart';

/// Wrapper do flutter_local_notifications: inicialização (com timezone do
/// aparelho), permissão e agendamento por wall-clock local.
class NotificationsService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _iniciado = false;

  Future<void> init() async {
    if (_iniciado) return;
    tzdata.initializeTimeZones();
    try {
      // Usuário BR: horário de Brasília. (Auto-detecção de fuso = ideia futura.)
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    } catch (_) {
      // fica em UTC se algo falhar
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _iniciado = true;
  }

  /// Pede permissão de notificação (Android 13+) e de alarme exato. Retorna se
  /// pode notificar.
  Future<bool> pedirPermissao() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ok = await android?.requestNotificationsPermission() ?? true;
    try {
      await android?.requestExactAlarmsPermission();
    } catch (_) {}
    return ok;
  }

  static const _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      'carlog_lembretes',
      'Lembretes do carro',
      channelDescription: 'Vencimentos (IPVA, seguro…) e próxima revisão',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> agendar({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime quando,
  }) async {
    await init();
    final data = tz.TZDateTime.from(quando, tz.local);
    if (!data.isAfter(tz.TZDateTime.now(tz.local))) return; // não agenda passado
    try {
      await _plugin.zonedSchedule(id, titulo, corpo, data, _detalhes,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime);
    } catch (_) {
      // sem permissão de alarme exato → agenda inexato (ainda dispara)
      try {
        await _plugin.zonedSchedule(id, titulo, corpo, data, _detalhes,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime);
      } catch (_) {}
    }
  }

  Future<void> cancelarTodas() async {
    await init();
    await _plugin.cancelAll();
  }
}

final notificationsServiceProvider =
    Provider<NotificationsService>((ref) => NotificationsService());

/// Preferência: notificações ligadas? (só vira true depois da permissão).
const _chaveNotif = 'notif_ativas_v1';

final notifAtivasProvider =
    AsyncNotifierProvider<NotifAtivasNotifier, bool>(NotifAtivasNotifier.new);

class NotifAtivasNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_chaveNotif) ?? false;
  }

  Future<void> definir(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chaveNotif, v);
    state = AsyncData(v);
  }
}

/// Reagenda todas as notificações quando os dados (ou o toggle) mudam.
class NotifScheduler {
  NotifScheduler(this.ref);
  final Ref ref;
  Timer? _debounce;

  void agendaReagendamento() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _reagendar);
  }

  void dispose() => _debounce?.cancel();

  int _id(String base, int offset) =>
      (base.hashCode & 0x7fffffff) % 1000000 * 10 + offset;

  DateTime _as9(DateTime d) => DateTime(d.year, d.month, d.day, 9);

  Future<void> _reagendar() async {
    final svc = ref.read(notificationsServiceProvider);
    await svc.cancelarTodas();
    final ativo = ref.read(notifAtivasProvider).value ?? false;
    if (!ativo) return;

    // Lembretes não pagos: no dia e 3 dias antes.
    final lembretes = ref.read(lembretesProvider).value ?? const [];
    for (final l in lembretes.where((e) => !e.pago)) {
      final nome = l.titulo.isNotEmpty ? l.titulo : l.tipo.rotulo;
      await svc.agendar(
        id: _id(l.id, 0),
        titulo: 'CarLog · ${l.tipo.rotulo}',
        corpo: '$nome vence hoje.',
        quando: _as9(l.vencimento),
      );
      await svc.agendar(
        id: _id(l.id, 1),
        titulo: 'CarLog · ${l.tipo.rotulo}',
        corpo: '$nome vence em 3 dias.',
        quando: _as9(l.vencimento.subtract(const Duration(days: 3))),
      );
    }

    // Próxima revisão estimada.
    final v = ref.read(veiculoProvider).value;
    final ab = ref.read(abastecimentosProvider).value ?? const [];
    final revs = ref.read(revisoesProvider).value ?? const [];
    if (v != null) {
      final odo = ultimoOdometro(ab);
      final comOdo = revs.where((r) => r.odometro != null).toList()
        ..sort((a, b) => a.odometro!.compareTo(b.odometro!));
      final base = comOdo.isNotEmpty ? comOdo.last.odometro! : odo;
      final ritmo = kmPorMesEstimado(ab);
      if (base != null && odo != null && ritmo != null && ritmo > 0) {
        final alvo = base + v.revisaoIntervaloKm;
        final faltamKm = alvo - odo;
        if (faltamKm > 0) {
          final dias = (faltamKm / ritmo * 30).round();
          await svc.agendar(
            id: _id(v.id, 2),
            titulo: 'CarLog · Revisão',
            corpo: 'Sua próxima revisão está chegando (~${km(alvo)}).',
            quando: _as9(DateTime.now().add(Duration(days: dias))),
          );
        }
      }
    }
  }
}

/// Liga o agendador aos dados. Instancie com `ref.watch(notifSchedulerProvider)`.
final notifSchedulerProvider = Provider<NotifScheduler>((ref) {
  final s = NotifScheduler(ref);
  ref.onDispose(s.dispose);
  ref.listen(notifAtivasProvider, (_, _) => s.agendaReagendamento(),
      fireImmediately: true);
  ref.listen(lembretesProvider, (_, _) => s.agendaReagendamento());
  ref.listen(veiculoProvider, (_, _) => s.agendaReagendamento());
  ref.listen(abastecimentosProvider, (_, _) => s.agendaReagendamento());
  ref.listen(revisoesProvider, (_, _) => s.agendaReagendamento());
  return s;
});
