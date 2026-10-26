import 'package:flutter/material.dart';

import '../../data/community.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/menu_group.dart';
import '../widgets/cam/cam.dart';
import '../widgets/family_alerts.dart';
import 'community_dialogs.dart';
import 'community_screen.dart';

/// Grup sayfası: kullanıcının bu grupla paylaştıkları (izin anahtarları),
/// üyeler ve her üyenin ne paylaştığı. Sahip davet eder ve üye çıkarır;
/// üye gruptan ayrılır.
class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final service = CommunityScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final g = service.group(groupId);
    // Grup silindiyse ya da ayrıldıysa sayfa kapanırken boş çizilir.
    if (g == null) return const CamScaffold();

    final consent = g.myConsent;

    // Portala ulaşılamazsa değişiklik olmaz; bildirim gösterilir.
    Future<void> guarded(Future<void> Function() action) async {
      final messenger = ScaffoldMessenger.of(context);
      final message = l.connServerError;
      try {
        await action();
      } on Exception {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }

    Future<void> toggle(ShareScope s, bool on) => guarded(
      () => service.setConsent(g.id, {
        ...consent.scopes.where((x) => x != s),
        if (on) s,
      }),
    );

    Future<void> leave() async {
      final ok = await showCamDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(g.ownedByMe ? l.communityDelete : l.communityLeave),
          content: Text(
            g.ownedByMe
                ? l.communityDeleteConfirm(g.name)
                : l.communityLeaveConfirm(g.name),
          ),
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
              child: Text(g.ownedByMe ? l.communityDelete : l.communityLeave),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      final navigator = Navigator.of(context);
      var left = false;
      await guarded(() async {
        await service.leave(g.id);
        left = true;
      });
      if (left) navigator.pop();
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
                GroupAvatar(name: g.name, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        l.communityMemberCount(g.memberCount),
                        style: TextStyle(color: colors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            MenuHeader(l.communityMyShareTitle),
            MenuGroup(
              children: [
                for (final s in ShareScope.values)
                  SwitchListTile(
                    contentPadding: const EdgeInsetsDirectional.only(
                      start: 16,
                      end: 12,
                    ),
                    secondary: Icon(s.icon, color: s.color),
                    title: Text(s.label),
                    value: consent.scopes.contains(s),
                    onChanged: (on) => toggle(s, on),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 0),
              child: Text(
                [
                  l.communityMyShareNote,
                  if (consent.grantedAt case final t?)
                    l.communityConsentSince('${dayMonth(t)} ${ltr(hhmm(t))}'),
                ].join('\n'),
                style: TextStyle(color: colors.muted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            MenuGroup(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsetsDirectional.only(
                    start: 16,
                    end: 12,
                  ),
                  secondary: Icon(
                    Icons.notification_important_outlined,
                    color: colors.danger,
                  ),
                  title: Text(l.communityAlertsTitle),
                  subtitle: Text(
                    consent.canAlert
                        ? l.communityAlertsBody
                        : l.communityAlertsNeedScope,
                    style: TextStyle(color: colors.muted, fontSize: 13),
                  ),
                  isThreeLine: true,
                  value: consent.alerts && consent.canAlert,
                  onChanged: consent.canAlert
                      ? (on) => guarded(() => service.setAlerts(g.id, on: on))
                      : null,
                ),
              ],
            ),
            MenuHeader(l.communityMembers),
            MenuGroup(
              children: [
                for (final m in g.members)
                  _MemberTile(
                    member: m,
                    onRemove: g.ownedByMe && !m.isMe
                        ? () => guarded(() => service.removeMember(g.id, m.id))
                        : null,
                  ),
                if (g.ownedByMe) ...[
                  MenuTile(
                    icon: Icons.person_add_alt,
                    title: l.communityInvite,
                    onTap: () => showInviteDialog(context, g),
                  ),
                  // Grup kodu bilinmiyorsa satır gizlenir.
                  if (g.inviteCode.isNotEmpty)
                    MenuTile(
                      icon: Icons.pin_outlined,
                      title: l.communityCodeLabel,
                      value: ltr(g.inviteCode),
                      onTap: () => showCamDialog<void>(
                        context: context,
                        builder: (_) => InviteCodeDialog(code: g.inviteCode),
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.danger,
                side: BorderSide(color: colors.outline),
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: leave,
              icon: Icon(g.ownedByMe ? Icons.delete_outline : Icons.logout),
              label: Text(g.ownedByMe ? l.communityDelete : l.communityLeave),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, this.onRemove});
  final GroupMember member;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final m = member;
    final name = m.isMe
        ? l.communityYou
        : m.name.isEmpty
        ? l.communityUnnamedMember
        : m.name;
    final role = [
      if (m.isOwner) l.communityOwner,
      if (m.pending) l.communityPending,
    ].join(' · ');
    // Kullanıcının kendi paylaşımı yukarıdaki anahtarlarda; boşsa tekrar yazılmaz.
    final shares = m.pending || (m.isMe && m.shares.isEmpty)
        ? null
        : m.shares.isEmpty
        ? l.communitySharesNothing
        : l.communityShares(shareList(m.shares));
    return ListTile(
      minTileHeight: 64,
      contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 4),
      leading: CircleAvatar(
        backgroundColor: m.isMe ? colors.glow : colors.surfaceHigh,
        foregroundColor: m.isMe ? colors.accent : colors.text,
        child: m.pending
            ? Icon(Icons.hourglass_empty, size: 20, color: colors.muted)
            : Text(
                name.characters.firstOrNull?.toUpperCase() ?? '?',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
      title: Text(
        role.isEmpty ? name : '$name · $role',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: m.pending ? colors.muted : colors.text,
        ),
      ),
      subtitle: shares == null && m.alerts.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (shares != null)
                  Text(shares, style: TextStyle(color: colors.muted)),
                for (final a in m.alerts)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 8),
                    child: FamilyAlertLine(name: name, alert: a),
                  ),
              ],
            ),
      trailing: onRemove == null
          ? null
          : PopupMenuButton<void>(
              icon: Icon(Icons.more_vert, color: colors.muted),
              itemBuilder: (_) => [
                PopupMenuItem(
                  onTap: onRemove,
                  child: Text(l.communityRemoveMember),
                ),
              ],
            ),
    );
  }
}
