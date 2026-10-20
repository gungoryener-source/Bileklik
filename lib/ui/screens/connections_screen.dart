import 'package:flutter/material.dart';

import '../../data/connections.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/menu_group.dart';
import '../widgets/cam/cam.dart';
import 'community_dialogs.dart';
import 'connection_detail_screen.dart';
import 'consent_screen.dart';

/// Hekim ve araştırma kurumu bağlantıları: davet kodu girme, süren
/// paylaşımlar. Kamerayla QR okuma ROADMAP 17'de; şimdilik QR'ın altındaki
/// kod elle girilir.
class ConnectionsScreen extends StatelessWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ConnectionScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final list = service.connections;

    Future<void> enterCode() async {
      final offer = await showCamDialog<ConnectionOffer>(
        context: context,
        builder: (_) => TextEntryDialog<ConnectionOffer>(
          title: l.connEnterCode,
          label: l.communityInviteCodeTitle,
          action: l.continueButton,
          maxLength: 10,
          code: true,
          submit: (code) async {
            final o = await service.lookup(code);
            return (o, o == null ? l.connCodeInvalid : null);
          },
        ),
      );
      if (offer == null || !context.mounted) return;
      final connected = await Navigator.of(context).push<DataConnection>(
        MaterialPageRoute(builder: (_) => ConsentScreen(offer: offer)),
      );
      if (connected == null || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l.connConnected(isolate(connected.offer.name))),
          ),
        );
    }

    Future<void> scan() async {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.connScanSoon)));
      await enterCode();
    }

    return CamScaffold(
      appBar: AppBar(title: Text(l.profileMenuResearch)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  Text(l.connIntro, style: TextStyle(color: colors.muted)),
                  MenuHeader(l.connActive),
                  if (list.isEmpty)
                    _Empty(text: l.connEmpty)
                  else
                    MenuGroup(
                      children: [
                        for (final c in list)
                          _ConnectionTile(
                            connection: c,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ConnectionDetailScreen(connectionId: c.id),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  GlowButton(
                    onTap: enterCode,
                    icon: Icons.pin_outlined,
                    label: l.connEnterCode,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: BorderSide(color: colors.outline),
                    ),
                    onPressed: scan,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(l.connScan),
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

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        children: [
          Icon(Icons.link_off, size: 40, color: colors.muted),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

/// Bağlantı türünün simgesi ve adı.
extension ConnectionKindLook on ConnectionKind {
  IconData get icon => switch (this) {
    ConnectionKind.clinician => Icons.medical_services_outlined,
    ConnectionKind.research => Icons.biotech_outlined,
  };

  String get label => switch (this) {
    ConnectionKind.clinician => currentL10n.connKindClinician,
    ConnectionKind.research => currentL10n.connKindResearch,
  };
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({required this.connection, required this.onTap});
  final DataConnection connection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final c = connection;
    return ListTile(
      minTileHeight: 76,
      contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 12),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: colors.glow,
        foregroundColor: colors.accent,
        child: Icon(c.offer.kind.icon),
      ),
      title: Text(
        isolate(c.offer.name),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${c.offer.kind.label} · ${l.connSharedCount(c.scopes.length)}\n'
        '${l.connUntil(longDate(c.until))}',
        style: TextStyle(color: colors.muted),
      ),
      isThreeLine: true,
      trailing: Icon(Icons.chevron_right, color: colors.muted),
      onTap: onTap,
    );
  }
}
