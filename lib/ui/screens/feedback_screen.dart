import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_info.dart';
import '../../data/feedback.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';

/// Profil > Geri bildirim: hata, öneri ya da başka bir konu.
///
/// Kimlik ve sağlık verisi gönderilmez; sürüm, platform ve dil yalnızca
/// kullanıcı izin verirse eklenir.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _text = TextEditingController();
  var _topic = FeedbackTopic.bug;
  var _withDetails = true;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String _platform() => kIsWeb ? 'web' : defaultTargetPlatform.name;

  Future<void> _send() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    setState(() => _sending = true);
    try {
      await FeedbackScope.of(context).send(
        _topic,
        _text.text,
        context: _withDetails
            ? FeedbackContext(
                appVersion: appVersion,
                platform: _platform(),
                locale: locale,
              )
            : null,
      );
      HapticFeedback.lightImpact();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.feedbackThanks)));
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.connServerError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final canSend = _text.text.trim().isNotEmpty && !_sending;
    return CamScaffold(
      appBar: AppBar(title: Text(l.profileMenuFeedback)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l.feedbackIntro, style: TextStyle(color: colors.muted)),
            const SizedBox(height: 20),
            SegmentedButton<FeedbackTopic>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: FeedbackTopic.bug,
                  label: Text(l.feedbackTopicBug),
                ),
                ButtonSegment(
                  value: FeedbackTopic.idea,
                  label: Text(l.feedbackTopicIdea),
                ),
                ButtonSegment(
                  value: FeedbackTopic.other,
                  label: Text(l.feedbackTopicOther),
                ),
              ],
              selected: {_topic},
              onSelectionChanged: _sending
                  ? null
                  : (s) => setState(() => _topic = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              enabled: !_sending,
              minLines: 5,
              maxLines: 10,
              maxLength: FeedbackService.maxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.feedbackMessageLabel,
                hintText: l.feedbackMessageHint,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _withDetails,
              onChanged: _sending
                  ? null
                  : (v) => setState(() => _withDetails = v),
              title: Text(l.feedbackIncludeDetails),
              subtitle: Text(
                l.feedbackDetailsValue(appVersion, _platform()),
                style: TextStyle(color: colors.muted),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 18, color: colors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.feedbackPrivacy,
                    style: TextStyle(color: colors.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GlowButton(
              label: l.feedbackSend,
              icon: Icons.send,
              loading: _sending,
              onTap: canSend ? _send : null,
            ),
          ],
        ),
      ),
    );
  }
}
