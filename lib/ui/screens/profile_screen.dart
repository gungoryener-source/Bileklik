import 'package:flutter/material.dart';

import '../../device/protocol/commands.dart';
import '../app_shell.dart';
import '../theme.dart';

/// Kişisel bilgiler. Kaydedilen değerler 0x02 komutuyla bilekliğe yazılır;
/// cihaz kalori ve mesafeyi bu bilgilerle hesaplar.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  bool _isMale = true;
  PersonalInfo? _loaded;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = DeviceScope.of(context).profile;
    if (p != null && !identical(p, _loaded)) {
      _loaded = p;
      _isMale = p.isMale;
      _age.text = '${p.age}';
      _height.text = '${p.heightCm}';
      _weight.text = '${p.weightKg}';
    }
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  String? _range(String? v, int min, int max) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < min || n > max) return '$min ile $max arasında olmalı';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final c = DeviceScope.of(context);
    await c.saveProfile(PersonalInfo(
      isMale: _isMale,
      age: int.parse(_age.text),
      heightCm: int.parse(_height.text),
      weightKg: int.parse(_weight.text),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(c.error ?? 'Bilgiler bilekliğe kaydedildi')));
  }

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Profil', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            c.profile?.mac != null
                ? 'Cihaz: ${c.profile!.mac}'
                : 'Bilgileri kaydetmek için önce bilekliği bağlayın.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Kadın')),
              ButtonSegment(value: true, label: Text('Erkek')),
            ],
            selected: {_isMale},
            onSelectionChanged: (s) => setState(() => _isMale = s.first),
          ),
          const SizedBox(height: 16),
          _field(_age, 'Yaş', 'yıl', (v) => _range(v, 5, 120)),
          _field(_height, 'Boy', 'cm', (v) => _range(v, 80, 250)),
          _field(_weight, 'Kilo', 'kg', (v) => _range(v, 20, 250)),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: c.isConnected ? _save : null,
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String suffix,
      String? Function(String?) validator) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
            labelText: label,
            suffixText: suffix,
            border: const OutlineInputBorder()),
        validator: validator,
      ),
    );
  }
}
