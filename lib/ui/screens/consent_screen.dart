import 'package:flutter/material.dart';

import '../../data/community.dart';
import '../../data/connections.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/menu_group.dart';
import 'connections_screen.dart';

/// KVKK açık rıza ekranı: kim, hangi amaçla, hangi verileri, ne kadar süre
/// istiyor. Hiçbir veri önceden seçili değildir; kullanıcı türleri seçer ve
/// rıza kutusunu işaretler. Onaylanınca bağlantıyla geri döner.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, required this.offer});
  final ConnectionOffer offer;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final _selected = <ShareScope>{};
  var _agreed = false;
  var _busy = false;

  ConnectionOffer get offer => widget.offer;

  // Sabit sırayla; sunucunun gönderdiği sıra önemli değil.
  List<ShareScope> get _requested =>
      ShareScope.values.where(offer.requested.contains).toList();

  Future<void> _connect() async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final c = await ConnectionScope.of(context).connect(offer, {..._selected});
    if (mounted) navigator.pop(c);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final until = DateTime.now().add(offer.duration);
    final allSelected = _selected.length == offer.requested.length;
    final canConnect = _selected.isNotEmpty && _agreed && !_busy;

    return Scaffold(
      appBar: AppBar(title: Text(l.connConsentTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                            Text(isolate(offer.name), style: text.titleLarge),
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
                  MenuHeader(l.connPurpose),
                  _Box(child: Text(isolate(offer.purpose))),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: MenuHeader(l.connRequested)),
                      TextButton(
                        onPressed: allSelected
                            ? null
                            : () => setState(
                                () => _selected.addAll(offer.requested),
                              ),
                        child: Text(l.connSelectAll),
                      ),
                    ],
                  ),
                  MenuGroup(
                    children: [
                      for (final s in _requested)
                        CheckboxListTile(
                          contentPadding: const EdgeInsetsDirectional.only(
                            start: 16,
                            end: 8,
                          ),
                          secondary: Icon(s.icon, color: s.color),
                          title: Text(s.label),
                          value: _selected.contains(s),
                          onChanged: (on) => setState(
                            () => on == true
                                ? _selected.add(s)
                                : _selected.remove(s),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 0),
                    child: Text(
                      l.connRequestedNote,
                      style: TextStyle(color: colors.muted, fontSize: 13),
                    ),
                  ),
                  MenuHeader(l.connDuration),
                  _Box(
                    child: Text(
                      l.connDurationText(
                        longDate(until),
                        offer.duration.inDays,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 4,
                    ),
                    child: Text(
                      l.connRights,
                      style: TextStyle(color: colors.muted, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    title: Text(
                      l.connAgree(isolate(offer.name)),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: canConnect ? _connect : null,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.connConfirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.colors.outline),
    ),
    child: child,
  );
}
