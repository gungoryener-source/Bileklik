import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_info.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../widgets/menu_group.dart';
import '../widgets/cam/cam.dart';
import 'about_screen.dart';
import 'community_screen.dart';
import 'connections_screen.dart';
import 'device_screen.dart';
import 'fhir_export_screen.dart';
import 'general_settings_screen.dart';
import 'health_platform_screen.dart';
import 'personal_info_screen.dart';

/// Profil sekmesi: kişisel bilgiler, cihaz, ayarlar ve uygulama menüsü.
///
/// Geri bildirim henüz yok; "Yakında" olarak görünür.
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
      padding: EdgeInsets.fromLTRB(16, 20, 16, GlassNavBar.clearance(context)),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 16),
          child: Text(
            l.profileTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        MenuGroup(
          children: [
            MenuTile(
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
        MenuHeader(l.profileSectionSettings),
        MenuGroup(
          children: [
            MenuTile(
              icon: Icons.watch,
              title: l.profileMenuDevice,
              subtitle: c.isConnected
                  ? l.profileMenuDeviceConnected(battery ?? 0)
                  : l.profileMenuDeviceNone,
              onTap: () => open(const DeviceScreen()),
            ),
            MenuTile(
              icon: Icons.tune,
              title: l.profileMenuGeneral,
              subtitle: l.profileMenuGeneralSubtitle,
              onTap: () => open(const GeneralSettingsScreen()),
            ),
          ],
        ),
        MenuHeader(l.profileSectionSharing),
        MenuGroup(
          children: [
            MenuTile(
              icon: Icons.family_restroom,
              title: l.profileMenuCommunity,
              subtitle: l.profileMenuCommunitySubtitle,
              badge: CommunityScope.of(context).unreadCount,
              onTap: () => open(const CommunityScreen()),
            ),
            MenuTile(
              icon: Icons.biotech,
              title: l.profileMenuResearch,
              subtitle: l.profileMenuResearchSubtitle,
              onTap: () {
                // Portaldaysa liste açılırken yenilenir; hata ekranı bozmaz.
                unawaited(
                  ConnectionScope.of(
                    context,
                  ).refresh().catchError((Object _) {}),
                );
                open(const ConnectionsScreen());
              },
            ),
            MenuTile(
              icon: Icons.sync_alt,
              title: l.profileMenuThirdParty,
              subtitle: l.profileMenuThirdPartySubtitle,
              onTap: () => open(const HealthPlatformScreen()),
            ),
            MenuTile(
              icon: Icons.ios_share,
              title: l.profileMenuExport,
              subtitle: l.profileMenuExportSubtitle,
              onTap: () => open(const FhirExportScreen()),
            ),
          ],
        ),
        MenuHeader(l.profileSectionApp),
        MenuGroup(
          children: [
            MenuTile(
              icon: Icons.info_outline,
              title: l.profileMenuAbout,
              onTap: () => open(const AboutScreen()),
            ),
            MenuTile(
              icon: Icons.chat_bubble_outline,
              title: l.profileMenuFeedback,
              soon: true,
              onTap: soon,
            ),
            MenuTile(
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
