import 'package:flutter/material.dart';

import '../../data/community.dart';
import '../../data/location_share.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/cam_map.dart';
import 'community_screen.dart';

/// Konum paylaşımı: kendi paylaşımım (kimlere, son gönderim, durdur) ve
/// konumunu benimle paylaşan tanıdıklar haritada.
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key, this.now});

  /// Testler için "şimdi".
  final DateTime? now;

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? _map;

  /// Kişilere verilen renkler, sırayla.
  static const _palette = [
    DataColors.oxygen,
    DataColors.steps,
    DataColors.temperature,
    DataColors.stress,
    DataColors.heart,
  ];

  Future<void> _choose() async {
    final service = CommunityScope.of(context);
    await showCamSheet<void>(
      context: context,
      builder: (_) => _ShareSheet(service: service),
    );
  }

  void _focus(SharedLocation loc) => _map?.animateCamera(
    CameraUpdate.newLatLngZoom(LatLng(loc.latitude, loc.longitude), 14),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = CommunityScope.of(context);
    final now = widget.now ?? DateTime.now();
    final shared = service.sharedWithMe;
    final mine = service.myLocation;
    final markers = [
      for (final (i, s) in shared.indexed)
        CamMapMarker(
          id: s.member.id,
          point: LatLng(s.location.latitude, s.location.longitude),
          label: s.member.name,
          snippet: l.locationUpdated(whenText(s.location.time, now)),
          color: _palette[i % _palette.length],
        ),
      if (mine != null)
        CamMapMarker(
          id: 'me',
          point: LatLng(mine.latitude, mine.longitude),
          label: l.locationMe,
          snippet: l.locationLastSent(whenText(mine.time, now)),
          color: context.colors.accent,
        ),
    ];
    final first = shared.isNotEmpty ? shared.first.location : mine;
    final center = first == null
        ? CamMap.fallbackCenter
        : LatLng(first.latitude, first.longitude);
    return CamScaffold(
      appBar: AppBar(title: Text(l.locationTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _MyShareCard(service: service, now: now, onChoose: _choose),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(CamRadius.card),
              child: SizedBox(
                height: 300,
                child: CamMap(
                  center: center,
                  zoom: 11,
                  markers: markers,
                  onCreated: (c) => _map = c,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.locationSharedWithMe,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (shared.isEmpty)
              GlassCard(
                child: Text(
                  l.locationNoneShared,
                  style: TextStyle(color: context.colors.muted),
                ),
              ),
            for (final (i, s) in shared.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GroupAvatar(name: s.member.name, size: 40),
                        PositionedDirectional(
                          end: -2,
                          bottom: -2,
                          child: Icon(
                            Icons.location_on,
                            size: 18,
                            color: _palette[i % _palette.length],
                          ),
                        ),
                      ],
                    ),
                    title: Text(s.member.name),
                    subtitle: Text(
                      '${s.group.name} · '
                      '${l.locationUpdated(whenText(s.location.time, now))}',
                    ),
                    trailing: Icon(
                      Icons.my_location,
                      color: context.colors.muted,
                    ),
                    onTap: () => _focus(s.location),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              l.locationNote,
              style: TextStyle(color: context.colors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kendi paylaşımımın durumu ve düğmeleri.
class _MyShareCard extends StatelessWidget {
  const _MyShareCard({
    required this.service,
    required this.now,
    required this.onChoose,
  });

  final CommunityService service;
  final DateTime now;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final on = service.sharingLocation;
    final hasGroups = [
      ...service.myGroups,
      ...service.joinedGroups,
    ].any((g) => g.members.any((m) => !m.isMe && !m.pending));
    final mine = service.myLocation;
    final problem = service.locationProblem;
    return GlassCard(
      tint: on ? camTint(c.heroTintStart, c.heroTintEnd) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                on ? Icons.share_location : Icons.location_off_outlined,
                color: on ? c.accent : c.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  on ? l.locationBanner : l.locationOff,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (on) ...[
            const SizedBox(height: 8),
            Text(l.locationViewers(service.locationViewers.join(', '))),
            const SizedBox(height: 4),
            Text(
              problem != null
                  ? _problemText(l, problem)
                  : mine == null
                  ? l.locationWaiting
                  : l.locationLastSent(whenText(mine.time, now)),
              style: TextStyle(
                color: problem != null ? c.danger : c.muted,
                fontSize: 13,
              ),
            ),
          ],
          if (!hasGroups && !on) ...[
            const SizedBox(height: 8),
            Text(
              l.locationNeedsGroup,
              style: TextStyle(color: c.muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: hasGroups ? onChoose : null,
                icon: Icon(on ? Icons.group : Icons.share_location),
                label: Text(on ? l.locationChoose : l.locationStart),
              ),
              if (on)
                OutlinedButton.icon(
                  onPressed: service.stopLocationSharing,
                  icon: const Icon(Icons.location_off),
                  label: Text(l.locationStop),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _problemText(AppLocalizations l, LocationProblem p) => switch (p) {
  LocationProblem.serviceOff => l.locationProblemServiceOff,
  LocationProblem.denied => l.locationProblemDenied,
  LocationProblem.deniedForever => l.locationProblemDeniedForever,
  LocationProblem.failed => l.locationProblemFailed,
};

/// Konumu görecek kişileri grup grup seçme; "Tüm grup" hepsini açar.
class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.service});
  final CommunityService service;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  late final Map<String, Set<String>> _picked = {
    for (final e in widget.service.locationShares.entries) e.key: {...e.value},
  };

  List<GroupMember> _others(CareGroup g) => [
    for (final m in g.members)
      if (!m.isMe && !m.pending) m,
  ];

  Future<void> _save() async {
    final s = widget.service;
    for (final g in [...s.myGroups, ...s.joinedGroups]) {
      await s.setLocationShare(g.id, _picked[g.id] ?? const {});
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final groups = [...widget.service.myGroups, ...widget.service.joinedGroups];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.locationSheetTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final g in groups) ...[
                  _groupHeader(g),
                  if (_others(g).isEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 16,
                        bottom: 8,
                      ),
                      child: Text(
                        l.locationNoMembers,
                        style: TextStyle(color: context.colors.muted),
                      ),
                    ),
                  for (final m in _others(g))
                    CheckboxListTile(
                      contentPadding: const EdgeInsetsDirectional.only(
                        start: 16,
                      ),
                      value: _picked[g.id]?.contains(m.id) ?? false,
                      title: Text(m.name),
                      secondary: GroupAvatar(name: m.name, size: 36),
                      onChanged: (v) => setState(() {
                        final set = _picked.putIfAbsent(g.id, () => {});
                        v == true ? set.add(m.id) : set.remove(m.id);
                      }),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlowButton(onTap: _save, icon: Icons.check, label: l.locationSave),
        ],
      ),
    );
  }

  Widget _groupHeader(CareGroup g) {
    final others = _others(g);
    final picked = _picked[g.id] ?? const {};
    final all = others.isNotEmpty && others.every((m) => picked.contains(m.id));
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(context.l10n.locationWholeGroup),
      value: all,
      onChanged: others.isEmpty
          ? null
          : (v) => setState(
              () => _picked[g.id] = v ? {for (final m in others) m.id} : {},
            ),
    );
  }
}

/// Paylaşım açıkken tüm sekmelerin üstünde görünen ince şerit.
class LocationSharingBanner extends StatelessWidget {
  const LocationSharingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CommunityScope.of(context);
    if (!service.sharingLocation) return const SizedBox.shrink();
    final c = context.colors;
    final l = context.l10n;
    return Material(
      color: c.accent.withValues(alpha: 0.18),
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const LocationScreen())),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.share_location, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.locationBanner,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: c.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
