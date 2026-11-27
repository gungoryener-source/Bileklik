import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/assistant.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../assistant_replies.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';

/// Vita sağlık asistanı: serbest soruları kullanıcının verisiyle yanıtlar.
/// Portal ve yapay zeka rızası varsa yanıt sunucudaki dil modelinden gelir,
/// yoksa telefonda kurallarla hazırlanır.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({
    super.key,
    this.now,
    this.typingDelay = const Duration(milliseconds: 700),
  });

  /// Testler için "şimdi".
  final DateTime? now;

  /// Çevrimdışı yanıt öncesi "yazıyor" süresi.
  final Duration typingDelay;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _messages = <ChatMessage>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  AssistantService? get _remote {
    final consent = SettingsScope.of(context).aiConsentAt;
    return consent == null ? null : PortalAssistantService.instance;
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _typing) return;
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final facts = AssistantFacts.of(
      c.store,
      widget.now ?? DateTime.now(),
      age: c.profile?.age,
    );
    final remote = _remote;
    setState(() {
      _messages.add(ChatMessage(ChatRole.user, text));
      _typing = true;
      _input.clear();
    });
    _toBottom();

    String? reply;
    var fallback = false;
    if (remote != null) reply = await remote.reply(_messages, facts, lang);
    if (reply == null) {
      fallback = remote != null;
      if (widget.typingDelay > Duration.zero) {
        await Future<void>.delayed(widget.typingDelay);
      }
      reply = offlineReply(text, facts, l);
    }
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(ChatRole.assistant, reply!, offline: fallback));
      _typing = false;
    });
    _toBottom();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_scroll.hasClients) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final end = _scroll.position.maxScrollExtent;
    if (reduce) {
      _scroll.jumpTo(end);
    } else {
      _scroll.animateTo(
        end,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final online = _remote != null;
    final suggestions = [
      l.asstSuggestReport,
      l.asstSuggestTraining,
      l.asstSuggestSleep,
      l.asstSuggestHeart,
    ];
    return CamScaffold(
      appBar: AppBar(title: Text(l.asstName), centerTitle: true),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _Header(online: online),
                  for (final m in _messages)
                    m.role == ChatRole.user
                        ? _UserBubble(text: m.text)
                        : _AssistantBubble(text: m.text, offline: m.offline),
                  if (_typing) const _TypingBubble(),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(84),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _Suggestion(
                  text: suggestions[i],
                  onTap: _typing ? null : () => _send(suggestions[i]),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _InputBar(
              controller: _input,
              busy: _typing,
              onSend: () => _send(_input.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slogan şeridi, karşılama ve çalışma kipi.
class _Header extends StatelessWidget {
  const _Header({required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final line = Expanded(
      child: Container(height: 1, color: c.accent.withValues(alpha: 0.45)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              line,
              Flexible(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: c.accent.withValues(alpha: 0.6)),
                    color: HomeSky.inner,
                  ),
                  child: Text(
                    l.asstTagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              line,
            ],
          ),
          const SizedBox(height: 20),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${l.asstHello} '),
                TextSpan(
                  text: l.asstName,
                  style: TextStyle(color: c.accent),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(l.asstIntro, style: const TextStyle(fontSize: 20, height: 1.3)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                online ? Icons.cloud_done_outlined : Icons.phone_android,
                size: 16,
                color: c.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${online ? l.asstOnline : l.asstOffline} ${l.asstNote}',
                  style: TextStyle(color: c.muted, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(start: 48, bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.accent.withValues(alpha: 0.22),
          borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(20),
            topEnd: Radius.circular(20),
            bottomStart: Radius.circular(20),
            bottomEnd: Radius.circular(6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(text, style: const TextStyle(fontSize: 16)),
        ),
      ),
    ),
  );
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.text, this.offline = false});
  final String text;
  final bool offline;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 24, bottom: 12),
    child: GlassCard(
      baseColor: HomeSky.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AssistantLabel(),
          const SizedBox(height: 8),
          SelectableText(
            text,
            style: const TextStyle(fontSize: 16, height: 1.45),
          ),
          if (offline) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.asstFailed,
              style: TextStyle(color: context.colors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    ),
  );
}

class _AssistantLabel extends StatelessWidget {
  const _AssistantLabel();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.auto_awesome, size: 18, color: context.colors.accent),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          context.l10n.asstTitle,
          style: TextStyle(
            color: context.colors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

/// Üç noktalı "yazıyor" göstergesi; hareketi azalt açıkken durağan.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.stop();
    } else if (!_anim.isAnimating) {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 120, bottom: 12),
    child: Semantics(
      label: context.l10n.asstTyping,
      liveRegion: true,
      child: GlassCard(
        baseColor: HomeSky.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AssistantLabel(),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) => Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: Opacity(
                        opacity: _dot(i),
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: context.colors.text,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  double _dot(int i) {
    final t = (_anim.value * 3 - i) % 3;
    return t < 1 ? 0.35 + 0.65 * (1 - (t - 0.5).abs() * 2) : 0.35;
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.text, required this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: GlassCard(
      padding: EdgeInsets.zero,
      baseColor: HomeSky.card,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 1.3),
            ),
          ),
        ),
      ),
    ),
  );
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.busy,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: HomeSky.card,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: c.glassBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                maxLength: 2000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: l.asstInputHint,
                  counterText: '',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(
                    20,
                    14,
                    8,
                    14,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: IconButton.filled(
                tooltip: l.asstSend,
                onPressed: busy ? null : onSend,
                style: IconButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
