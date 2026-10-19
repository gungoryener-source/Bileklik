import 'package:flutter/material.dart';

import '../../device/transport.dart';
import '../app_shell.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final live = c.live;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Bugün', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        _DeviceCard(),
        if (c.error != null) ...[
          const SizedBox(height: 12),
          Text(c.error!, style: const TextStyle(color: AppColors.heart)),
        ],
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            MetricTile(
                label: 'Adım',
                value: live?.steps.toString(),
                unit: '/ 10000',
                color: AppColors.steps,
                icon: Icons.directions_walk),
            MetricTile(
                label: 'Kalp atış hızı',
                value: _orDash(live?.heartRate),
                unit: 'bpm',
                color: AppColors.heart,
                icon: Icons.favorite),
            MetricTile(
                label: 'Kan oksijeni',
                value: _orDash(live?.spo2),
                unit: '%',
                color: AppColors.oxygen,
                icon: Icons.water_drop),
            MetricTile(
                label: 'Bilek ısısı',
                value: live?.temperatureC.toStringAsFixed(1),
                unit: '°C',
                color: AppColors.temperature,
                icon: Icons.thermostat),
            MetricTile(
                label: 'Kalori',
                value: live?.calories.toStringAsFixed(0),
                unit: 'kcal',
                color: AppColors.temperature,
                icon: Icons.local_fire_department),
            MetricTile(
                label: 'Mesafe',
                value: live?.distanceKm.toStringAsFixed(2),
                unit: 'km',
                color: AppColors.steps,
                icon: Icons.straighten),
          ],
        ),
      ],
    );
  }

  /// Cihaz 0 gönderdiğinde ölçüm yok demektir.
  static String? _orDash(int? v) => v == null || v == 0 ? null : v.toString();
}

class _DeviceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final connecting = c.connection == DeviceConnectionState.connecting;
    final subtitle = switch (c.connection) {
      DeviceConnectionState.connected =>
        'Bağlı · Pil %${c.battery?.percent ?? '--'}',
      DeviceConnectionState.connecting => 'Bağlanıyor…',
      DeviceConnectionState.disconnected => 'Bağlı değil',
    };
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.watch,
            color: c.isConnected ? AppColors.accent : AppColors.muted),
        title: Text(c.deviceName),
        subtitle: Text(subtitle),
        trailing: FilledButton.tonal(
          onPressed: connecting
              ? null
              : (c.isConnected ? c.disconnect : c.connect),
          child: Text(c.isConnected ? 'Ayır' : 'Bağlan'),
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String label;
  final String? value;
  final String unit;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted)),
              ),
            ]),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(value ?? '--',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
