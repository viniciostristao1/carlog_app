import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_config.dart';
import '../../l10n/strings.dart';
import '../../services/auth_service.dart';
import '../../services/backup_service.dart';
import '../../services/notifications.dart';
import '../../services/prefs.dart';
import '../../services/repositories.dart';
import '../../theme/app_colors.dart';

class ConfigScreen extends ConsumerWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.configuracoes)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _tituloSecao(t.secaoIdioma),
          const SizedBox(height: 8),
          const _IdiomaCard(),
          const SizedBox(height: 24),
          _tituloSecao(t.secaoAparencia),
          const SizedBox(height: 8),
          const _TemaCard(),
          const SizedBox(height: 12),
          const _FonteCard(),
          const SizedBox(height: 24),
          _tituloSecao(t.secaoConta),
          const SizedBox(height: 8),
          if (kFirebaseConfigured)
            const _ContaCard()
          else
            const _NuvemEmBreve(),
          const SizedBox(height: 24),
          _tituloSecao(t.secaoBackup),
          const SizedBox(height: 8),
          const _BackupCard(),
          const SizedBox(height: 24),
          _tituloSecao(t.secaoNotificacoes),
          const SizedBox(height: 8),
          const _NotificacoesCard(),
          const SizedBox(height: 24),
          _tituloSecao(t.secaoSobre),
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
                    child: Icon(Icons.directions_car_filled,
                        color: AppColors.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CarLog',
                            style: TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('${t.appTagline} · v0.42.0',
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
            style: TextStyle(
                color: AppColors.dim,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      );
}

/// Backup manual: exportar tudo para um arquivo e importar de volta (mescla por
/// id, sem apagar nada). Rede de segurança além da nuvem.
class _BackupCard extends ConsumerWidget {
  const _BackupCard();

  /// Recarrega todos os stores após importar (e, se logado, dispara o envio pra
  /// nuvem via os listeners do syncProvider).
  void _recarregar(WidgetRef ref) {
    ref.invalidate(veiculosProvider);
    ref.invalidate(veiculoSelIdProvider);
    ref.invalidate(abastecimentosProvider);
    ref.invalidate(mediasProvider);
    ref.invalidate(revisoesProvider);
    ref.invalidate(programacaoProvider);
    ref.invalidate(lembretesProvider);
    ref.invalidate(calibragemProvider);
  }

  Future<void> _exportar(BuildContext context, WidgetRef ref) async {
    // Captura o messenger ANTES do await (o context não é usado depois).
    final messenger = ScaffoldMessenger.of(context);
    final t = ref.read(stringsProvider);
    try {
      await BackupService().exportar();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.backupFalhou)));
    }
  }

  Future<void> _importar(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final t = ref.read(stringsProvider);
    try {
      final n = await BackupService().importar();
      if (n == null) return; // usuário cancelou o seletor de arquivo
      _recarregar(ref);
      messenger.showSnackBar(SnackBar(content: Text(t.backupImportadoN(n))));
    } on FormatException {
      messenger.showSnackBar(SnackBar(content: Text(t.backupInvalido)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(t.backupFalhou)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.backupResumo,
                style: TextStyle(color: AppColors.dim, fontSize: 13)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _exportar(context, ref),
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: Text(t.exportarBackup),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _importar(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: BorderSide(color: AppColors.lineStrong),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: Text(t.importarBackup),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NuvemEmBreve extends ConsumerWidget {
  const _NuvemEmBreve();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: AppColors.dim),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.dadosNesteAparelho,
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    t.nuvemEmBreve,
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
    final t = ref.watch(stringsProvider);
    final auth = ref.watch(authStateProvider);
    final user = auth.asData?.value;

    if (user == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.entrarSincronizar,
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
                            SnackBar(
                                content: Text(t.naoConsegiuEntrar)));
                      }
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: Text(t.entrarComGoogle),
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
                  ? Icon(Icons.person, color: AppColors.accent)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName ?? t.conectado,
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  if (user.email != null)
                    Text(user.email!,
                        style: TextStyle(
                            color: AppColors.dim, fontSize: 12.5)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              child: Text(t.sair),
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
    final t = ref.watch(stringsProvider);
    final ativas = ref.watch(notifAtivasProvider).value ?? false;

    Future<void> alternar(bool ligar) async {
      if (ligar) {
        final ok = await ref.read(notificationsServiceProvider).pedirPermissao();
        if (!ok) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.permissaoNegada)));
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
        title: Text(t.avisarVencimentos,
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
        subtitle: Text(
          t.avisarVencimentosSub,
          style: TextStyle(color: AppColors.dim, fontSize: 12.5),
        ),
      ),
    );
  }
}

/// Seletor de tema: dropdown com seta (expande para as amostras).
class _TemaCard extends ConsumerWidget {
  const _TemaCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final atual = ref.watch(temaProvider).value ?? TemaApp.terracota;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          collapsedIconColor: AppColors.dim,
          iconColor: AppColors.accent,
          title: Text(s.tema,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          subtitle: Text(s.nomeTema(atual.index),
              style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                for (final tval in TemaApp.values) ...[
                  Expanded(
                    child: _TemaSwatch(
                      tema: tval,
                      nome: s.nomeTema(tval.index),
                      selecionado: tval == atual,
                      onTap: () =>
                          ref.read(temaProvider.notifier).definir(tval),
                    ),
                  ),
                  if (tval != TemaApp.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TemaSwatch extends StatelessWidget {
  final TemaApp tema;
  final String nome;
  final bool selecionado;
  final VoidCallback onTap;
  const _TemaSwatch({
    required this.tema,
    required this.nome,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentDoTema(tema);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.fundoDoTema(tema),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selecionado ? accent : AppColors.line,
                  width: selecionado ? 2.5 : 1,
                ),
              ),
              child: Center(
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: selecionado ? AppColors.text : AppColors.dim,
                  fontSize: 11.5,
                  fontWeight:
                      selecionado ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Seletor de tamanho de fonte: dropdown com seta.
class _FonteCard extends ConsumerWidget {
  const _FonteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final atual = ref.watch(fonteProvider).value ?? TamanhoFonte.normal;
    final nomes = {
      TamanhoFonte.menor: s.fonteMenor,
      TamanhoFonte.normal: s.fonteNormal,
      TamanhoFonte.maior: s.fonteMaior,
      TamanhoFonte.maximo: s.fonteMax,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          collapsedIconColor: AppColors.dim,
          iconColor: AppColors.accent,
          title: Text(s.tamanhoFonte,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          subtitle: Text('${nomes[atual]} · ${s.valeAppInteiro}',
              style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                for (final tf in TamanhoFonte.values) ...[
                  Expanded(
                    child: _FonteOpcao(
                      nome: nomes[tf]!,
                      fator: tf.fator,
                      selecionado: tf == atual,
                      onTap: () => ref.read(fonteProvider.notifier).definir(tf),
                    ),
                  ),
                  if (tf != TamanhoFonte.values.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FonteOpcao extends StatelessWidget {
  final String nome;
  final double fator;
  final bool selecionado;
  final VoidCallback onTap;
  const _FonteOpcao({
    required this.nome,
    required this.fator,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selecionado
              ? AppColors.accent.withValues(alpha: 0.16)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selecionado ? AppColors.accent : AppColors.line),
        ),
        child: Column(
          children: [
            // "A" numa prévia do tamanho relativo — a escala NÃO usa o
            // MediaQuery global (senão todas ficariam iguais).
            Text('A',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                    color: selecionado ? AppColors.text : AppColors.dim,
                    fontSize: 15 * fator,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(nome,
                textScaler: TextScaler.noScaling,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: selecionado ? AppColors.text : AppColors.dim2,
                    fontSize: 11,
                    fontWeight:
                        selecionado ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

/// Seletor de idioma: dropdown com seta.
class _IdiomaCard extends ConsumerWidget {
  const _IdiomaCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atual = ref.watch(idiomaProvider).value ?? Idioma.pt;
    final t = ref.watch(stringsProvider);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
          collapsedIconColor: AppColors.dim,
          iconColor: AppColors.accent,
          title: Text(t.secaoIdioma,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          subtitle: Text(atual.nomeNativo,
              style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
          children: [
            for (final i in Idioma.values)
              InkWell(
                onTap: () => ref.read(idiomaProvider.notifier).definir(i),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        i == atual
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: i == atual ? AppColors.accent : AppColors.dim2,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(i.nomeNativo,
                          style: TextStyle(
                              color: AppColors.text,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
