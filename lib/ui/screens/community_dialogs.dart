import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/community.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';

/// Grup adı sorar ve grubu oluşturur; vazgeçilirse null.
Future<CareGroup?> showCreateGroupDialog(BuildContext context) {
  final service = CommunityScope.of(context);
  final l = context.l10n;
  return showDialog<CareGroup>(
    context: context,
    builder: (_) => TextEntryDialog<CareGroup>(
      title: l.communityCreateGroup,
      label: l.communityGroupName,
      hint: l.communityGroupNameHint,
      action: l.communityCreate,
      maxLength: 40,
      submit: (name) async => (await service.createGroup(name), null),
    ),
  );
}

/// Grup kodu sorar ve gruba katılır; kod geçersizse diyalogda hata gösterir.
Future<CareGroup?> showJoinWithCodeDialog(BuildContext context) {
  final service = CommunityScope.of(context);
  final l = context.l10n;
  return showDialog<CareGroup>(
    context: context,
    builder: (_) => TextEntryDialog<CareGroup>(
      title: l.communityJoinWithCode,
      label: l.communityCodeLabel,
      action: l.communityAccept,
      maxLength: 6,
      code: true,
      submit: (code) async {
        final g = await service.joinWithCode(code);
        return (g, g == null ? l.communityCodeInvalid : null);
      },
    ),
  );
}

/// Davet edilecek kişinin adını sorar, daveti gönderir ve grup kodunu gösterir.
Future<void> showInviteDialog(BuildContext context, CareGroup group) async {
  final service = CommunityScope.of(context);
  final l = context.l10n;
  final name = await showDialog<String>(
    context: context,
    builder: (_) => TextEntryDialog<String>(
      title: l.communityInvite,
      label: l.communityInviteName,
      action: l.communityInviteSend,
      maxLength: 40,
      submit: (name) async {
        await service.invite(group.id, name);
        return (name.trim(), null);
      },
    ),
  );
  if (name == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => InviteCodeDialog(code: group.inviteCode, name: name),
  );
}

/// Davet kodunu büyük harflerle ve kopyalama düğmesiyle gösterir.
class InviteCodeDialog extends StatelessWidget {
  const InviteCodeDialog({super.key, required this.code, this.name});
  final String code;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return AlertDialog(
      title: Text(l.communityInviteCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: colors.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SelectableText(
                ltr(code),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          if (name != null) ...[
            const SizedBox(height: 14),
            Text(
              l.communityInviteCodeBody(name!),
              style: TextStyle(color: colors.muted),
            ),
          ],
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l.communityCodeCopied)));
          },
          icon: const Icon(Icons.copy, size: 18),
          label: Text(l.communityCopyCode),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.actionClose),
        ),
      ],
    );
  }
}

/// Tek alanlı form diyaloğu. [submit] sonucu ve hata metnini döndürür;
/// hata varsa diyalog açık kalır.
class TextEntryDialog<T> extends StatefulWidget {
  const TextEntryDialog({
    super.key,
    required this.title,
    required this.label,
    required this.action,
    required this.submit,
    this.hint,
    this.maxLength,
    this.code = false,
    this.minLength = 6,
  });

  final String title, label, action;
  final String? hint;
  final int? maxLength;

  /// Büyük harf, boşluksuz kod alanı.
  final bool code;

  /// Kod alanında en az kaç karakter girilince düğme açılır.
  final int minLength;
  final Future<(T?, String?)> Function(String text) submit;

  @override
  State<TextEntryDialog<T>> createState() => _TextEntryDialogState<T>();
}

class _TextEntryDialogState<T> extends State<TextEntryDialog<T>> {
  final _text = TextEditingController();
  String? _error;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _valid => widget.code
      ? _text.text.trim().length >= widget.minLength
      : _text.text.trim().isNotEmpty;

  Future<void> _go() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    final (result, error) = await widget.submit(_text.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLength: widget.maxLength,
        textCapitalization: widget.code
            ? TextCapitalization.characters
            : TextCapitalization.words,
        inputFormatters: widget.code
            ? [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                _UpperCase(),
              ]
            : null,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _go(),
        style: widget.code
            ? const TextStyle(letterSpacing: 4, fontWeight: FontWeight.w600)
            : null,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.actionCancel),
        ),
        FilledButton(
          onPressed: _valid && !_busy ? _go : null,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.action),
        ),
      ],
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue v) =>
      v.copyWith(text: v.text.toUpperCase());
}
