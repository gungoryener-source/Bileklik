import 'package:flutter/material.dart';

import '../../data/community.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/menu_group.dart';
import '../widgets/cam/cam.dart';
import 'connections_screen.dart';

/// Süren bir bağlantının ayrıntısı: kim, ne paylaşılıyor, ne zamana kadar.
/// Bağlantı buradan kaldırılır (rıza geri alınır).
class ConnectionDetailScreen extends StatelessWidget {
  const ConnectionDetailScreen({super.key, required this.connectionId});
  final String connectionId;

  @override
  Widget build(BuildContext context) {
    final service = ConnectionScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final c = service.connections
        .where((c) => c.id == connectionId)
        .firstOrNull;
    // Kaldırıldıysa sayfa kapanırken boş çizilir.
    if (c == null) return const CamScaffold();
    final offer = c.offer;

    Future<void> disconnect() async {
      final ok = await showCamDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.connDisconnect),
          content: Text(l.connDisconnectConfirm(isolate(offer.name))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.actionCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.danger,
                foregroundColor: colors.onAccent,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.connDisconnect),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      final navigator = Navigator.of(context);
      await service.disconnect(c.id);
      navigator.pop();
    }

    return CamScaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.glow,
                  foregroundColor: colors.accent,
                  child: Icon(offer.kind.icon, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isolate(offer.name),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${offer.kind.label} · ${isolate(offer.organization)}',
                        style: TextStyle(color: colors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${l.connSince(longDate(c.since))}\n'
              '${l.connUntil(longDate(c.until))}',
              style: TextStyle(color: colors.muted),
            ),
            MenuHeader(l.connPurpose),
            Text(isolate(offer.purpose)),
            MenuHeader(l.connShared),
            MenuGroup(
              children: [
                for (final s in ShareScope.values.where(c.scopes.contains))
                  ListTile(
                    minTileHeight: 56,
                    leading: Icon(s.icon, color: s.color),
                    title: Text(s.label),
                    trailing: Icon(Icons.check, color: colors.accent),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
              child: Text(
                l.connRights,
                style: TextStyle(color: colors.muted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.danger,
                side: BorderSide(color: colors.outline),
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: disconnect,
              icon: const Icon(Icons.link_off),
              label: Text(l.connDisconnect),
            ),
          ],
        ),
      ),
    );
  }
}
