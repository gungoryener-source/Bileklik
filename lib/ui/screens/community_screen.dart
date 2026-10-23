import 'package:flutter/material.dart';

import '../../data/community.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../theme.dart';
import '../widgets/menu_group.dart';
import '../widgets/cam/cam.dart';
import 'community_dialogs.dart';
import 'community_messages_screen.dart';
import 'group_screen.dart';

/// Sağlık topluluğu: kullanıcının kurduğu ve katıldığı aile grupları.
///
/// Davetler ve katılım bildirimleri sağ üstteki Mesajlar'da. Her grupta ne
/// paylaşılacağını kullanıcı grup sayfasında tek tek seçer (açık rıza).
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CommunityScope.of(context);
    final l = context.l10n;
    final unread = service.unreadCount;

    void openGroup(CareGroup g) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => GroupScreen(groupId: g.id)));

    Future<void> create() async {
      final g = await showCreateGroupDialog(context);
      if (g != null && context.mounted) openGroup(g);
    }

    Future<void> join() async {
      final g = await showJoinWithCodeDialog(context);
      if (g == null || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l.communityJoinedMessage(g.name))),
        );
    }

    return CamScaffold(
      appBar: AppBar(
        title: Text(l.profileMenuCommunity),
        actions: [
          IconButton(
            tooltip: l.communityMessages,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CommunityMessagesScreen(),
              ),
            ),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _PrivacyNote(text: l.communityPrivacyNote),
                  MenuHeader(l.communityMyGroups),
                  if (service.myGroups.isEmpty)
                    _Empty(text: l.communityMyGroupsEmpty)
                  else
                    MenuGroup(
                      children: [
                        for (final g in service.myGroups)
                          _GroupTile(group: g, onTap: () => openGroup(g)),
                      ],
                    ),
                  MenuHeader(l.communityJoinedGroups),
                  MenuGroup(
                    children: [
                      for (final g in service.joinedGroups)
                        _GroupTile(group: g, onTap: () => openGroup(g)),
                      MenuTile(
                        icon: Icons.pin_outlined,
                        title: l.communityJoinWithCode,
                        subtitle: service.joinedGroups.isEmpty
                            ? l.communityJoinedEmpty
                            : null,
                        onTap: join,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: GlowButton(
                  onTap: create,
                  icon: Icons.group_add,
                  label: l.communityCreateGroup,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.glow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: colors.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: colors.text)),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        children: [
          Icon(Icons.diversity_3, size: 40, color: colors.muted),
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

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.onTap});
  final CareGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final owner = group.members.where((m) => m.isOwner).firstOrNull;
    final count = l.communityMemberCount(group.memberCount);
    return ListTile(
      minTileHeight: 72,
      contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 12),
      leading: GroupAvatar(name: group.name),
      title: Text(
        group.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        group.ownedByMe || owner == null || owner.name.isEmpty
            ? count
            : '${l.communityOwnerName(owner.name)} · $count',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.muted),
      ),
      trailing: Icon(Icons.chevron_right, color: colors.muted),
      onTap: onTap,
    );
  }
}

/// Grubun simgesi: adın baş harfi, vurgu renginde halka içinde.
class GroupAvatar extends StatelessWidget {
  const GroupAvatar({super.key, required this.name, this.size = 44});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initial = name.trim().isEmpty
        ? null
        : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.glow, shape: BoxShape.circle),
      child: initial == null
          ? Icon(Icons.diversity_3, color: colors.accent, size: size * 0.5)
          : Text(
              initial,
              style: TextStyle(
                color: colors.accent,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.42,
              ),
            ),
    );
  }
}
