import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/community.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';

/// Gruplarda görünen adı sorar ve kaydeder; vazgeçilirse false.
Future<bool> showDisplayNameDialog(BuildContext context) async {
  final service = CommunityScope.of(context);
  final l = context.l10n;
  final saved = await showCamDialog<bool>(
    context: context,
    builder: (_) => TextEntryDialog<bool>(
      title: l.communityDisplayName,
      label: l.communityDisplayNameLabel,
      hint: l.communityDisplayNameHint,
      helper: l.communityDisplayNameNote,
      action: l.profileSave,
      maxLength: 40,
      initial: service.displayName,
      submit: (name) async {
        await service.setDisplayName(name);
        return (true, null);
      },
    ),
  );
  return saved ?? false;
}

/// Ad henüz yazılmadıysa önce sorar (gruptakiler kişiyi adıyla görsün).
/// Vazgeçilirse false.
Future<bool> _ensureDisplayName(BuildContext context) async {
  if (CommunityScope.of(context).displayName.isNotEmpty) return true;
  return showDisplayNameDialog(context);
}

/// Grup adı sorar ve grubu oluşturur; vazgeçilirse null.
Future<CareGroup?> showCreateGroupDialog(BuildContext context) async {
  if (!await _ensureDisplayName(context) || !context.mounted) return null;
  final service = CommunityScope.of(context);
  final l = context.l10n;
  return showCamDialog<CareGroup>(
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
Future<CareGroup?> showJoinWithCodeDialog(BuildContext context) async {
  if (!await _ensureDisplayName(context) || !context.mounted) return null;
  final service = CommunityScope.of(context);
  final l = context.l10n;
  return showCamDialog<CareGroup>(
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

/// Davet edilecek kişinin adını sorar, daveti gönderir ve katılma kodunu
/// gösterir.
Future<void> showInviteDialog(BuildContext context, CareGroup group) async {
  final service = CommunityScope.of(context);
  final l = context.l10n;
  final sent = await showCamDialog<(String, String)>(
    context: context,
    builder: (_) => TextEntryDialog<(String, String)>(
      title: l.communityInvite,
      label: l.communityInviteName,
      action: l.communityInviteSend,
      maxLength: 40,
      submit: (name) async {
        // Portalda kişiye özel kod döner; sahte sunucuda grup kodu.
        final code = await service.invite(group.id, name);
        return ((name.trim(), code), null);
      },
    ),
  );
  if (sent == null || !context.mounted) return;
  await showCamDialog<void>(
    context: context,
    builder: (_) => InviteCodeDialog(code: sent.$2, name: sent.$1),
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
          onPressed: () => SharePlus.instance.share(
            ShareParams(text: l.communityShareCodeText(code)),
          ),
          icon: const Icon(Icons.ios_share, size: 18),
          label: Text(l.communityShareCode),
        ),
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
    this.helper,
    this.initial,
    this.maxLength,
    this.code = false,
    this.minLength = 6,
  });

  final String title, label, action;
  final String? hint;

  /// Alanın altındaki kısa açıklama.
  final String? helper;

  /// Alanın ilk değeri.
  final String? initial;
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
  late final _text = TextEditingController(text: widget.initial);
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
    final l = context.l10n;
    T? result;
    String? error;
    try {
      (result, error) = await widget.submit(_text.text);
    } on Exception {
      // Portala ulaşılamadı; pencere açık kalır, yeniden denenebilir.
      error = l.connServerError;
    }
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
          helperText: widget.helper,
          helperMaxLines: 3,
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

/// Topluluk ekranı açıkken grupları sunucudan yeniler: açılışta, uygulama
/// öne gelince ve [interval] aralıkla. Böylece öteki telefonda katılan ya da
/// paylaşımını değiştiren kişi birkaç saniye içinde görünür. Hatalar
/// sessizce geçilir; ulaşılamıyorsa ekran `CommunityService.unreachable`
/// ile uyarır.
class CommunityAutoRefresh extends StatefulWidget {
  const CommunityAutoRefresh({
    super.key,
    required this.child,
    this.interval = const Duration(seconds: 15),
  });

  final Widget child;
  final Duration interval;

  @override
  State<CommunityAutoRefresh> createState() => _CommunityAutoRefreshState();
}

class _CommunityAutoRefreshState extends State<CommunityAutoRefresh>
    with WidgetsBindingObserver {
  Timer? _timer;
  CommunityService? _service;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(widget.interval, (_) => _refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = CommunityScope.of(context);
    if (!identical(s, _service)) {
      _service = s;
      _refresh();
    }
  }

  void _refresh() => unawaited(
    _service?.refresh().catchError((Object _) {}) ?? Future.value(),
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
