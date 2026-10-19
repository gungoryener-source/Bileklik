import 'package:flutter/material.dart';

import '../../app_info.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../theme.dart';
import 'about_screen.dart';
import 'device_screen.dart';
import 'general_settings_screen.dart';
import 'personal_info_screen.dart';

/// Profil sekmesi: kişisel bilgiler, cihaz, ayarlar ve uygulama menüsü.
///
/// Paylaşım, araştırma kurumu ve üçüncü taraf bölümleri ROADMAP 9-11'de
/// gelecek; şimdilik "Yakında" olarak görünür.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final p = c.profile;
    final battery = c.battery?.percent;

    void open(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => screen));

    void soon() {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.comingSoonMessage)));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 16),
          child: Text(
            l.profileTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        _Group(
          children: [
            _MenuTile(
              icon: Icons.person,
              large: true,
              title: l.personalInfoTitle,
              subtitle: p == null
                  ? l.profileMenuPersonalEmpty
                  : l.profileMenuPersonalSummary(p.age, p.heightCm, p.weightKg),
              onTap: () => open(const PersonalInfoScreen()),
            ),
          ],
        ),
        _Header(l.profileSectionSettings),
        _Group(
          children: [
            _MenuTile(
              icon: Icons.watch,
              title: l.profileMenuDevice,
              subtitle: c.isConnected
                  ? l.profileMenuDeviceConnected(battery ?? 0)
                  : l.profileMenuDeviceNone,
              onTap: () => open(const DeviceScreen()),
            ),
            _MenuTile(
              icon: Icons.tune,
              title: l.profileMenuGeneral,
              subtitle: l.profileMenuGeneralSubtitle,
              onTap: () => open(const GeneralSettingsScreen()),
            ),
          ],
        ),
        _Header(l.profileSectionSharing),
        _Group(
          children: [
            _MenuTile(
              icon: Icons.family_restroom,
              title: l.profileMenuSharing,
              soon: true,
              onTap: soon,
            ),
            _MenuTile(
              icon: Icons.biotech,
              title: l.profileMenuResearch,
              soon: true,
              onTap: soon,
            ),
            _MenuTile(
              icon: Icons.sync_alt,
              title: l.profileMenuThirdParty,
              soon: true,
              onTap: soon,
            ),
          ],
        ),
        _Header(l.profileSectionApp),
        _Group(
          children: [
            _MenuTile(
              icon: Icons.info_outline,
              title: l.profileMenuAbout,
              onTap: () => open(const AboutScreen()),
            ),
            _MenuTile(
              icon: Icons.chat_bubble_outline,
              title: l.profileMenuFeedback,
              soon: true,
              onTap: soon,
            ),
            _MenuTile(
              icon: Icons.verified_outlined,
              title: l.profileMenuVersion,
              value: appVersion,
            ),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(4, 24, 4, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: context.colors.muted, fontWeight: FontWeight.w600),
    ),
  );
}

/// Kenarlı kart içinde, aralarında ince çizgi olan satırlar.
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: context.colors.outline),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              indent: 72,
              endIndent: 16,
              color: context.colors.outline,
            ),
          children[i],
        ],
      ],
    ),
  );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.soon = false,
    this.large = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Sağda (Arapçada solda) gösterilen değer; varsa ok çizilmez.
  final String? value;
  final VoidCallback? onTap;
  final bool soon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = large ? 48.0 : 40.0;
    final Widget? trailing = value != null
        ? Text(value!, style: TextStyle(color: colors.muted))
        : soon
        ? _SoonChip()
        : onTap != null
        ? Icon(Icons.chevron_right, color: colors.muted)
        : null;
    return ListTile(
      minTileHeight: large ? 76 : 60,
      contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 12),
      leading: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: large ? colors.glow : colors.surfaceHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: large ? 26 : 22,
          color: large ? colors.accent : colors.text,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: large ? FontWeight.w600 : FontWeight.w500,
          fontSize: large ? 17 : 15,
          color: soon ? colors.muted : colors.text,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: TextStyle(color: colors.muted)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _SoonChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: context.colors.surfaceHigh,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      context.l10n.comingSoon,
      style: TextStyle(color: context.colors.muted, fontSize: 12),
    ),
  );
}
