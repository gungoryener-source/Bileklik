import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/portal.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';

/// Profil > Portal hesabı: kurtarma kodu, başka telefondaki hesabı geri
/// yükleme ve portaldaki verileri silme (unutulma hakkı). Yalnızca portal
/// adresi verildiyse görünür.
class PortalAccountScreen extends StatefulWidget {
  const PortalAccountScreen({super.key});

  @override
  State<PortalAccountScreen> createState() => _PortalAccountScreenState();
}

class _PortalAccountScreenState extends State<PortalAccountScreen> {
  final _input = TextEditingController();
  Future<String>? _code;
  var _restoring = false;

  PortalAccountService get _service => AccountScope.of(context)!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _code ??= _service.recoveryCode();
  }

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<bool> _confirm(String title, String body, String action) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _renew() async {
    final l = context.l10n;
    if (!await _confirm(
      l.accountRenewConfirmTitle,
      l.accountRenewConfirmBody,
      l.accountRenew,
    )) {
      return;
    }
    setState(() => _code = _service.renewRecoveryCode());
  }

  Future<void> _restore() async {
    final l = context.l10n;
    if (!await _confirm(
      l.accountRestoreConfirm,
      l.accountRestoreInfo,
      l.accountRestoreButton,
    )) {
      return;
    }
    setState(() => _restoring = true);
    try {
      final ok = await _service.recover(_input.text);
      if (!mounted) return;
      if (ok) {
        _input.clear();
        setState(() => _code = _service.recoveryCode());
        _snack(l.accountRestored);
      } else {
        _snack(l.accountRestoreInvalid);
      }
    } on Exception {
      if (mounted) _snack(l.connServerError);
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _erase() async {
    final l = context.l10n;
    if (!await _confirm(
      l.accountEraseConfirmTitle,
      l.accountEraseInfo,
      l.accountEraseButton,
    )) {
      return;
    }
    setState(() => _restoring = true);
    try {
      final count = await _service.eraseData();
      if (mounted) _snack(l.accountErased(count));
    } on Exception {
      if (mounted) _snack(l.connServerError);
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return CamScaffold(
      appBar: AppBar(title: Text(l.accountTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l.accountRecoveryTitle, style: text.titleMedium),
            const SizedBox(height: 8),
            Text(l.accountRecoveryInfo, style: TextStyle(color: colors.muted)),
            const SizedBox(height: 16),
            GlassCard(
              child: FutureBuilder<String>(
                future: _code,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Column(
                      children: [
                        Text(l.connServerError, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: () => setState(
                            () => _code = _service.recoveryCode(),
                          ),
                          child: Text(l.autoMeasureRetry),
                        ),
                      ],
                    );
                  }
                  final code = snap.data;
                  if (code == null) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        // Kod her dilde soldan sağa ve tek satırda okunur.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            code,
                            textDirection: TextDirection.ltr,
                            style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l.accountCopy,
                        icon: const Icon(Icons.copy),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (mounted) _snack(l.accountCodeCopied);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _restoring ? null : _renew,
                child: Text(l.accountRenew),
              ),
            ),
            const SizedBox(height: 24),
            Text(l.accountRestoreTitle, style: text.titleMedium),
            const SizedBox(height: 8),
            Text(l.accountRestoreInfo, style: TextStyle(color: colors.muted)),
            const SizedBox(height: 16),
            TextField(
              controller: _input,
              enabled: !_restoring,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: l.accountRestoreField,
                hintText: 'XXXX-XXXX-XXXX-XXXX',
                hintTextDirection: TextDirection.ltr,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            GlowButton(
              label: l.accountRestoreButton,
              icon: Icons.restore,
              loading: _restoring,
              onTap: _input.text.trim().length >= 16 ? _restore : null,
            ),
            const SizedBox(height: 32),
            Text(l.accountEraseTitle, style: text.titleMedium),
            const SizedBox(height: 8),
            Text(l.accountEraseInfo, style: TextStyle(color: colors.muted)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.danger,
                side: BorderSide(color: colors.outline),
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _restoring ? null : _erase,
              icon: const Icon(Icons.delete_outline),
              label: Text(l.accountEraseTitle),
            ),
          ],
        ),
      ),
    );
  }
}
