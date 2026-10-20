import 'package:flutter/material.dart';

import '../../device/protocol/commands.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';

/// Kişisel bilgiler. Kaydedilen değerler 0x02 komutuyla bilekliğe yazılır;
/// cihaz kalori ve mesafeyi bu bilgilerle hesaplar.
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
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
    if (n == null || n < min || n > max) {
      return context.l10n.profileRangeError(min, max);
    }
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final c = DeviceScope.of(context);
    await c.saveProfile(
      PersonalInfo(
        isMale: _isMale,
        age: int.parse(_age.text),
        heightCm: int.parse(_height.text),
        weightKg: int.parse(_weight.text),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(issueText(c) ?? context.l10n.profileSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    return CamScaffold(
      appBar: AppBar(title: Text(l.personalInfoTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              c.profile?.mac != null
                  ? l.profileDevice(c.profile!.mac!)
                  : l.profileConnectFirst,
              style: TextStyle(color: context.colors.muted),
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l.profileFemale)),
                ButtonSegment(value: true, label: Text(l.profileMale)),
              ],
              selected: {_isMale},
              onSelectionChanged: (s) => setState(() => _isMale = s.first),
            ),
            const SizedBox(height: 16),
            _field(
              _age,
              l.profileAge,
              l.profileUnitYears,
              (v) => _range(v, 5, 120),
            ),
            _field(
              _height,
              l.profileHeight,
              l.profileUnitCm,
              (v) => _range(v, 80, 250),
            ),
            _field(
              _weight,
              l.profileWeight,
              l.profileUnitKg,
              (v) => _range(v, 20, 250),
            ),
            const SizedBox(height: 8),
            GlowButton(
              onTap: c.isConnected ? _save : null,
              label: l.profileSave,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String suffix,
    String? Function(String?) validator,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }
}
