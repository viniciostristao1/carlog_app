import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_config.dart';
import '../../services/auth_service.dart';
import '../../services/notifications.dart';
import '../../theme/app_colors.dart';

class ConfigScreen extends ConsumerWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _tituloSecao('Conta e sincronização'),
          const SizedBox(height: 8),
          if (kFirebaseConfigured)
            const _ContaCard()
          else
            const _NuvemEmBreve(),
          const SizedBox(height: 24),
          _tituloSecao('Notificações'),
          const SizedBox(height: 8),
          const _NotificacoesCard(),
          const SizedBox(height: 24),
          _tituloSecao('Sobre'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_car_filled,
                        color: AppColors.accent),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CarLog',
                            style: TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('O diário do seu carro · v0.6.2',
                            style:
                                TextStyle(color: AppColors.dim, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSecao(String t) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(t,
            style: const TextStyle(
                color: AppColors.dim,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      );
}

class _NuvemEmBreve extends StatelessWidget {
  const _NuvemEmBreve();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: AppColors.dim),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dados salvos neste aparelho',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text(
                    'A sincronização na nuvem com login Google entra numa '
                    'próxima versão. Por enquanto, tudo fica salvo localmente.',
                    style: TextStyle(color: AppColors.dim, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContaCard extends ConsumerWidget {
  const _ContaCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.asData?.value;

    if (user == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Entre para sincronizar seus dados entre aparelhos.',
                  style: TextStyle(color: AppColors.dim, fontSize: 13.5)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    try {
                      await ref
                          .read(authServiceProvider)
                          .signInWithGoogle();
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Não foi possível entrar.')));
                      }
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar com Google'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
              backgroundImage:
                  user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null
                  ? const Icon(Icons.person, color: AppColors.accent)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName ?? 'Conectado',
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  if (user.email != null)
                    Text(user.email!,
                        style: const TextStyle(
                            color: AppColors.dim, fontSize: 12.5)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              child: const Text('Sair'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificacoesCard extends ConsumerWidget {
  const _NotificacoesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ativas = ref.watch(notifAtivasProvider).value ?? false;

    Future<void> alternar(bool ligar) async {
      if (ligar) {
        final ok = await ref.read(notificationsServiceProvider).pedirPermissao();
        if (!ok) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Permissão negada. Ative as notificações do CarLog nos '
                    'ajustes do Android.')));
          }
          return;
        }
      }
      await ref.read(notifAtivasProvider.notifier).definir(ligar);
    }

    return Card(
      child: SwitchListTile(
        value: ativas,
        onChanged: alternar,
        activeThumbColor: AppColors.accent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: const Text('Avisar sobre vencimentos e revisão',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
        subtitle: const Text(
          'Notifica no dia (e 3 dias antes) dos lembretes e quando a próxima '
          'revisão se aproxima.',
          style: TextStyle(color: AppColors.dim, fontSize: 12.5),
        ),
      ),
    );
  }
}
