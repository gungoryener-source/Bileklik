import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/billing.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/menu_group.dart';

extension PremiumPlanText on PremiumPlan {
  String get label => switch (this) {
    PremiumPlan.monthly => currentL10n.premiumMonthly,
    PremiumPlan.yearly => currentL10n.premiumYearly,
  };
}

/// Mağazanın verdiği fiyat metni; demoda tutar etkin dile göre biçimlenir.
String priceText(BillingProduct p) => NumberFormat.simpleCurrency(
  locale: currentL10n.localeName,
  name: p.currency,
).format(p.price);

/// Dönemli fiyat: "₺149,99 / ay".
String periodPrice(BillingProduct p) => p.plan == PremiumPlan.yearly
    ? currentL10n.premiumPerYear(priceText(p))
    : currentL10n.premiumPerMonth(priceText(p));

/// Premium gerektiren bir ekranı açar: abonelik yoksa önce Premium ekranı;
/// satın alınırsa ekran açılır.
Future<void> openPremium(BuildContext context, WidgetBuilder screen) async {
  final navigator = Navigator.of(context);
  final billing = BillingScope.of(context);
  if (!billing.isPremium(DateTime.now())) {
    final bought = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => const PremiumScreen()),
    );
    if (bought != true) return;
  }
  await navigator.push<void>(MaterialPageRoute(builder: screen));
}

/// Satış ekranı: Premium'un getirdikleri, aylık/yıllık seçimi, satın alma.
/// Satın alınırsa `true` ile kapanır.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  var _plan = PremiumPlan.yearly;
  var _busy = false;

  Future<void> _buy() async {
    final billing = BillingScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final product = billing.products.firstWhere((p) => p.plan == _plan);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      // Küçük ekranda ve büyük yazıda pencere kaydırılabilir kalır.
      isScrollControlled: true,
      builder: (_) => _StoreSheet(product: product),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    await billing.purchase(_plan);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.premiumActive)));
    navigator.pop(true);
  }

  Future<void> _restore() async {
    final billing = BillingScope.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() => _busy = true);
    final s = await billing.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(s == null ? l.premiumRestoreNone : l.premiumRestored),
        ),
      );
    if (s != null) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final billing = BillingScope.of(context);
    final saving = yearlySavingPercent(billing.products);
    Widget benefit(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: colors.accent),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
    return CamScaffold(
      appBar: AppBar(title: Text(l.premiumTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: colors.glow,
                      foregroundColor: colors.accent,
                      child: const Icon(Icons.workspace_premium, size: 40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.premiumSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      children: [
                        benefit(Icons.auto_awesome, l.premiumBenefitReport),
                        benefit(Icons.lightbulb, l.premiumBenefitCoaching),
                        benefit(Icons.favorite_border, l.premiumBenefitFree),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final p in billing.products) ...[
                    _PlanCard(
                      product: p,
                      selected: p.plan == _plan,
                      saving: p.plan == PremiumPlan.yearly && saving > 0
                          ? l.premiumSave(saving)
                          : null,
                      onTap: _busy
                          ? null
                          : () => setState(() => _plan = p.plan),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    l.premiumTerms,
                    style: TextStyle(color: colors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.science_outlined, color: colors.muted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l.premiumDemoNote,
                            style: TextStyle(color: colors.muted, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GlowButton(
                label: l.premiumSubscribe,
                loading: _busy,
                onTap: _busy ? null : _buy,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: _busy ? null : _restore,
                  child: Text(l.premiumRestore),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.product,
    required this.selected,
    required this.saving,
    required this.onTap,
  });

  final BillingProduct product;
  final bool selected;
  final String? saving;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Pressable(
      semanticLabel: '${product.plan.label}, ${periodPrice(product)}',
      selected: selected,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colors.glow : colors.surface,
          borderRadius: BorderRadius.circular(CamRadius.card),
          border: Border.all(
            color: selected ? colors.accent : colors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? colors.accent : colors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.plan.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    periodPrice(product),
                    style: TextStyle(color: colors.muted),
                  ),
                ],
              ),
            ),
            if (saving != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  saving!,
                  style: TextStyle(
                    color: colors.onAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mağazanın onay penceresini taklit eder.
class _StoreSheet extends StatelessWidget {
  const _StoreSheet({required this.product});

  final BillingProduct product;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.storeSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(l.storeSheetItem(product.plan.label)),
            const SizedBox(height: 4),
            Text(
              periodPrice(product),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(l.storeSheetNote, style: TextStyle(color: colors.muted)),
            const SizedBox(height: 16),
            GlowButton(
              label: l.storeConfirm,
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.storeCancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profil > Abonelik: durum, yenileme tarihi, iptal ve geri yükleme.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key, this.now});

  /// Durumun hesaplandığı an (testte sabit).
  final DateTime Function()? now;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  var _busy = false;

  Future<void> _cancel(Subscription s) async {
    final billing = BillingScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.subscriptionCancel),
        content: Text(l.subscriptionCancelConfirm(longDate(s.renewsAt))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.subscriptionKeep),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.subscriptionCancel),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    await billing.cancel();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.subscriptionCancelled)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final billing = BillingScope.of(context);
    final now = (widget.now ?? DateTime.now)();
    final s = billing.subscription;
    final active = s != null && s.activeAt(now);
    return CamScaffold(
      appBar: AppBar(title: Text(l.subscriptionTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            GlassCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.glow,
                    foregroundColor: active ? colors.accent : colors.muted,
                    child: Icon(
                      active ? Icons.workspace_premium : Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active
                              ? l.subscriptionPremium(s.plan.label)
                              : l.subscriptionFree,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          !active
                              ? l.subscriptionFreeText
                              : s.cancelled
                              ? l.subscriptionEnds(longDate(s.renewsAt))
                              : l.subscriptionRenews(longDate(s.renewsAt)),
                          style: TextStyle(color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!active)
              GlowButton(
                icon: Icons.workspace_premium,
                label: l.subscriptionUpgrade,
                onTap: () => Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                ),
              ),
            const SizedBox(height: 8),
            MenuGroup(
              children: [
                if (active && !s.cancelled)
                  MenuTile(
                    icon: Icons.cancel_outlined,
                    title: l.subscriptionCancel,
                    onTap: _busy ? null : () => _cancel(s),
                  ),
                MenuTile(
                  icon: Icons.restore,
                  title: l.premiumRestore,
                  onTap: _busy
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _busy = true);
                          final r = await billing.restore();
                          if (!mounted) return;
                          setState(() => _busy = false);
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  r == null
                                      ? l.premiumRestoreNone
                                      : l.premiumRestored,
                                ),
                              ),
                            );
                        },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
              child: Text(
                l.premiumDemoNote,
                style: TextStyle(color: colors.muted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
