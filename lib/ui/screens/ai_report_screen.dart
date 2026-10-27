import 'package:flutter/material.dart';

import '../../data/ai_report.dart';
import '../../data/aggregate.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/menu_group.dart';

/// İlerleme ekranındaki giriş kartı.
class AiReportCard extends StatelessWidget {
  const AiReportCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return Pressable(
      semanticLabel: l.aiReportTitle,
      onTap: onTap,
      child: GlassCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colors.glow,
              foregroundColor: colors.accent,
              child: const Icon(Icons.auto_awesome),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l.aiReportTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      _DemoChip(label: l.premiumBadge),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.aiReportCardText,
                    style: TextStyle(color: colors.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.muted),
          ],
        ),
      ),
    );
  }
}

/// Yapay zeka raporu: önce ayrı açık rıza, sonra haftanın raporu.
class AiReportScreen extends StatefulWidget {
  const AiReportScreen({
    super.key,
    required this.day,
    this.service = const DemoAiReportService(),
    this.now,
  });

  /// Raporu yazılacak haftanın herhangi bir günü.
  final DateTime day;
  final AiReportService service;

  /// Rızanın zamanı (testte sabit).
  final DateTime Function()? now;

  @override
  State<AiReportScreen> createState() => _AiReportScreenState();
}

class _AiReportScreenState extends State<AiReportScreen> {
  AiReport? _report;
  var _busy = false;
  var _tried = false;

  AiReportInput _input(BuildContext context) {
    final device = DeviceScope.of(context);
    final p = device.profile;
    return AiReportInput.of(
      device.store,
      widget.day,
      age: p?.age,
      isMale: p?.isMale,
    );
  }

  Future<void> _generate() async {
    final input = _input(context);
    final l = context.l10n;
    setState(() => _busy = true);
    final r = await widget.service.generate(input, l);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _tried = true;
      _report = r;
    });
  }

  Future<void> _revoke() async {
    final settings = SettingsScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    await settings.setAiConsent(null);
    if (!mounted) return;
    setState(() {
      _report = null;
      _tried = false;
    });
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.aiRevoked)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = SettingsScope.of(context);
    final consent = settings.aiConsentAt;
    return CamScaffold(
      appBar: AppBar(
        title: Text(l.aiReportTitle),
        actions: [
          if (consent != null)
            PopupMenuButton<void>(
              tooltip: l.aiRevoke,
              itemBuilder: (_) => [
                PopupMenuItem(onTap: _revoke, child: Text(l.aiRevoke)),
              ],
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: consent == null
            ? _ConsentView(
                onAccept: () =>
                    settings.setAiConsent((widget.now ?? DateTime.now)()),
                onDecline: () => Navigator.of(context).maybePop(),
              )
            : _reportView(context, consent),
      ),
    );
  }

  Widget _reportView(BuildContext context, DateTime consent) {
    final l = context.l10n;
    final colors = context.colors;
    final week = PeriodRange.of(Period.week, widget.day);
    final r = _report;
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const ValueKey('report'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Text(
                l.aiWeek(
                  dayMonth(week.start),
                  dayMonth(week.end.subtract(const Duration(days: 1))),
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                l.aiConsentGiven(longDate(consent)),
                style: TextStyle(color: colors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (_busy)
                GlassCard(
                  child: Row(
                    children: [
                      const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(l.aiGenerating)),
                    ],
                  ),
                )
              else if (r == null && _tried)
                GlassCard(
                  child: Text(l.aiEmpty, style: TextStyle(color: colors.muted)),
                )
              else if (r != null)
                ..._sections(context, r),
              const SizedBox(height: 16),
              _Notice(icon: Icons.health_and_safety, text: l.aiDisclaimer),
              const SizedBox(height: 12),
              _DataUsed(input: _input(context)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: GlowButton(
            icon: Icons.auto_awesome,
            label: r == null ? l.aiGenerate : l.aiRegenerate,
            loading: _busy,
            onTap: _busy ? null : _generate,
          ),
        ),
      ],
    );
  }

  List<Widget> _sections(BuildContext context, AiReport r) {
    final l = context.l10n;
    final colors = context.colors;
    return [
      if (r.demo) ...[
        _Notice(icon: Icons.science_outlined, text: l.aiDemoNote),
        const SizedBox(height: 12),
      ],
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.aiSummaryTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(r.summary, style: const TextStyle(fontSize: 16, height: 1.4)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _Section(
        title: l.aiWinsTitle,
        icon: Icons.check_circle,
        color: colors.accent,
        items: r.wins,
      ),
      const SizedBox(height: 12),
      _Section(
        title: l.aiWatchTitle,
        icon: Icons.visibility,
        color: colors.auroraPink,
        items: r.watch,
      ),
      const SizedBox(height: 12),
      _Section(
        title: l.aiTipsTitle,
        icon: Icons.lightbulb,
        color: colors.auroraCyan,
        items: r.tips,
      ),
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(l.aiNothing, style: TextStyle(color: colors.muted))
          else
            for (final t in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(t, style: const TextStyle(height: 1.4)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// Raporun dayandığı, sunucuya gidecek özet.
class _DataUsed extends StatelessWidget {
  const _DataUsed({required this.input});

  final AiReportInput input;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.data_object, color: colors.muted),
          title: Text(l.aiDataTitle),
          subtitle: Text(
            l.aiDataNote,
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(
                width: double.infinity,
                child: SelectableText(
                  input.toPrettyJson(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: colors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.glow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Ayrı açık rıza: ne gider, ne gitmez, nereye gider, sınırlar, geri alma.
class _ConsentView extends StatefulWidget {
  const _ConsentView({required this.onAccept, required this.onDecline});

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  State<_ConsentView> createState() => _ConsentViewState();
}

class _ConsentViewState extends State<_ConsentView> {
  var _agreed = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    Widget box(String text) => GlassCard(child: Text(text));
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const ValueKey('consent'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colors.glow,
                    foregroundColor: colors.accent,
                    child: const Icon(Icons.auto_awesome, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      l.aiConsentTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l.aiConsentIntro, style: const TextStyle(height: 1.4)),
              MenuHeader(l.aiConsentSentTitle),
              box(l.aiConsentSent),
              MenuHeader(l.aiConsentNotSentTitle),
              box(l.aiConsentNotSent),
              const SizedBox(height: 16),
              _Notice(icon: Icons.public, text: l.aiConsentAbroad),
              const SizedBox(height: 12),
              _Notice(icon: Icons.health_and_safety, text: l.aiConsentLimits),
              const SizedBox(height: 12),
              _Notice(icon: Icons.undo, text: l.aiConsentRevoke),
              const SizedBox(height: 12),
              CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                title: Text(
                  l.aiConsentCheck,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: GlowButton(
            label: l.aiConsentAccept,
            onTap: _agreed ? widget.onAccept : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: widget.onDecline,
              child: Text(l.aiConsentDecline),
            ),
          ),
        ),
      ],
    );
  }
}
