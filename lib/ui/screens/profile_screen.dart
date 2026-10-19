import 'package:flutter/material.dart';

import '../../device/protocol/commands.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import 'language_screen.dart';

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
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l.profileTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
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
          FilledButton(
            onPressed: c.isConnected ? _save : null,
            child: Text(l.profileSave),
          ),
          const SizedBox(height: 32),
          Text(
            l.profileAppearance,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          const _ThemePicker(),
          const SizedBox(height: 8),
          const _LanguageRow(),
        ],
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

/// Tema seçimi: telefonun ayarına uy, her zaman açık ya da koyu.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    final l = context.l10n;
    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          icon: const Icon(Icons.brightness_auto),
          label: Text(l.profileThemeSystem),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: const Icon(Icons.light_mode),
          label: Text(l.profileThemeLight),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: const Icon(Icons.dark_mode),
          label: Text(l.profileThemeDark),
        ),
      ],
      selected: {settings.themeMode},
      onSelectionChanged: (s) => settings.setThemeMode(s.first),
    );
  }
}

/// Dil satırı: seçili dili gösterir, dokununca dil seçimini açar.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final code = SettingsScope.of(context).language;
    final current = code == null ? l.languageSystem : languageName(code);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        child: ListTile(
          minTileHeight: 56,
          leading: const Icon(Icons.translate),
          title: Text(l.languageTitle),
          subtitle: Text(current),
          // chevron_right yazı yönüne göre kendiliğinden döner.
          trailing: Icon(Icons.chevron_right, color: context.colors.muted),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const LanguageScreen()),
          ),
        ),
      ),
    );
  }
}
