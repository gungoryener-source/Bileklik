import 'package:flutter/material.dart';

import '../../app_info.dart';
import '../../l10n/l10n.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import 'privacy_screen.dart';

/// Uygulama hakkında: amaç, tıbbi uyarı, gizlilik ve lisanslar.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    return CamScaffold(
      appBar: AppBar(title: Text(l.profileMenuAbout)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colors.glow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.monitor_heart,
                  size: 44,
                  color: colors.accent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.appTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l.aboutVersion(appVersion),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.muted),
            ),
            const SizedBox(height: 24),
            Text(l.aboutDescription),
            const SizedBox(height: 16),
            _Note(
              icon: Icons.medical_information_outlined,
              text: l.aboutMedical,
            ),
            const SizedBox(height: 12),
            _Note(icon: Icons.lock_outline, text: l.aboutPrivacy),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(l.privacyTitle),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: l.appTitle,
                applicationVersion: appVersion,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(l.aboutLicenses),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.colors.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.colors.muted),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
