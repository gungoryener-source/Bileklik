import 'package:flutter/material.dart';

import '../../data/community.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';

/// Topluluk mesajları: grup davetleri (katıl / reddet) ve katılım bildirimleri.
/// Sayfa açılınca mesajlar okunmuş sayılır.
class CommunityMessagesScreen extends StatefulWidget {
  const CommunityMessagesScreen({super.key});

  @override
  State<CommunityMessagesScreen> createState() =>
      _CommunityMessagesScreenState();
}

class _CommunityMessagesScreenState extends State<CommunityMessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) CommunityScope.of(context).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = CommunityScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final messages = service.messages;
    return CamScaffold(
      appBar: AppBar(title: Text(l.communityMessages)),
      body: SafeArea(
        top: false,
        child: messages.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mail_outline, size: 48, color: colors.muted),
                      const SizedBox(height: 12),
                      Text(
                        l.communityMessagesEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.muted),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _MessageCard(messages[i]),
              ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard(this.m);
  final CommunityMessage m;

  @override
  Widget build(BuildContext context) {
    final service = CommunityScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final invite = m.kind == CommunityMessageKind.invite;
    final text = invite
        ? l.communityMsgInvite(m.from, m.groupName)
        : l.communityMsgJoined(m.from, m.groupName);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colors.glow,
                foregroundColor: colors.accent,
                child: Icon(invite ? Icons.group_add : Icons.how_to_reg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      whenText(m.time, DateTime.now()),
                      style: TextStyle(color: colors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (invite) ...[
            const SizedBox(height: 10),
            if (m.answered)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 52),
                child: Text(
                  l.communityAnswered,
                  style: TextStyle(color: colors.muted),
                ),
              )
            else
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton(
                      onPressed: () =>
                          service.answerInvite(m.id, accept: false),
                      child: Text(l.communityDecline),
                    ),
                    FilledButton(
                      onPressed: () => service.answerInvite(m.id, accept: true),
                      child: Text(l.communityAccept),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
