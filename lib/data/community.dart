import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Bir grupla paylaşılabilen veri türleri.
///
/// Portala aktarımda her biri FHIR R4 Consent kaynağındaki
/// `provision.class` (Observation kategorisi / LOINC) karşılığı olacak.
enum ShareScope {
  heartRate,
  spo2,
  sleep,
  activity,
  ecg,
  bloodPressure,
  stress,
  temperature,
}

/// Kullanıcının bir gruba verdiği paylaşım izni (açık rıza).
///
/// KVKK gereği varsayılan boştur: kullanıcı türleri tek tek açar ve
/// izni istediği an geri alır. `grantedAt` iznin son değiştiği an.
@immutable
class ShareConsent {
  const ShareConsent({this.scopes = const {}, this.grantedAt});

  final Set<ShareScope> scopes;
  final DateTime? grantedAt;

  bool get isEmpty => scopes.isEmpty;
}

/// Grup üyesi. `shares`, bu üyenin grupla paylaştığı veri türleri.
@immutable
class GroupMember {
  const GroupMember({
    required this.id,
    required this.name,
    this.isMe = false,
    this.isOwner = false,
    this.pending = false,
    this.shares = const {},
  });

  final String id;
  final String name;
  final bool isMe;
  final bool isOwner;

  /// Davet gönderildi, henüz katılmadı.
  final bool pending;
  final Set<ShareScope> shares;

  GroupMember copyWith({bool? pending, Set<ShareScope>? shares}) => GroupMember(
    id: id,
    name: name,
    isMe: isMe,
    isOwner: isOwner,
    pending: pending ?? this.pending,
    shares: shares ?? this.shares,
  );
}

/// Aile ya da bakım grubu. Kullanıcı ya sahibidir ya da davetle katılmıştır.
@immutable
class CareGroup {
  const CareGroup({
    required this.id,
    required this.name,
    required this.ownedByMe,
    required this.inviteCode,
    required this.members,
    this.myConsent = const ShareConsent(),
  });

  final String id;
  final String name;
  final bool ownedByMe;

  /// Gruba katılmak için paylaşılan 6 karakterlik kod.
  final String inviteCode;
  final List<GroupMember> members;

  /// Kullanıcının bu grupla ne paylaştığı.
  final ShareConsent myConsent;

  /// Katılmış üyeler (davet bekleyenler hariç).
  int get memberCount => members.where((m) => !m.pending).length;

  CareGroup copyWith({List<GroupMember>? members, ShareConsent? myConsent}) =>
      CareGroup(
        id: id,
        name: name,
        ownedByMe: ownedByMe,
        inviteCode: inviteCode,
        members: members ?? this.members,
        myConsent: myConsent ?? this.myConsent,
      );
}

enum CommunityMessageKind {
  /// Biri kullanıcıyı grubuna davet etti; kabul ya da ret bekler.
  invite,

  /// Davet edilen kişi kullanıcının grubuna katıldı.
  memberJoined,
}

@immutable
class CommunityMessage {
  const CommunityMessage({
    required this.id,
    required this.kind,
    required this.from,
    required this.groupName,
    required this.time,
    this.groupId,
    this.answered = false,
  });

  final String id;
  final CommunityMessageKind kind;
  final String from;
  final String groupName;
  final String? groupId;
  final DateTime time;

  /// Davet yanıtlandı (kabul ya da ret).
  final bool answered;
}

/// Sağlık topluluğu sunucusu: portal adresi varsa `PortalCommunityService`
/// (`portal.dart`), yoksa [FakeCommunityServer].
abstract class CommunityService extends ChangeNotifier {
  List<CareGroup> get myGroups;
  List<CareGroup> get joinedGroups;

  /// En yeni ilk.
  List<CommunityMessage> get messages;
  int get unreadCount;

  CareGroup? group(String id);

  /// Sunucudan yeniden okur (sahte sunucuda bir şey yapmaz).
  Future<void> refresh() async {}

  Future<CareGroup> createGroup(String name);

  /// Bir kişiyi davet eder; üye "davet bekleniyor" olarak eklenir. Davet
  /// edilenin katılmak için gireceği kodu döner (portalda kişiye özel).
  Future<String> invite(String groupId, String name);
  Future<void> removeMember(String groupId, String memberId);

  /// Kullanıcının bu grupla paylaştığı türleri günceller.
  Future<void> setConsent(String groupId, Set<ShareScope> scopes);

  /// Kodla katılır; kod geçersizse null.
  Future<CareGroup?> joinWithCode(String code);
  Future<void> answerInvite(String messageId, {required bool accept});

  /// Sahibiyse grubu siler, üyeyse gruptan ayrılır. Paylaşım izni de biter.
  Future<void> leave(String groupId);
  void markAllRead();
}

/// Bellekte çalışan sahte sunucu. Davet edilen kişiler [acceptDelay] sonra
/// kendiliğinden katılır; böylece demo ve testlerde akış görülür.
class FakeCommunityServer extends CommunityService {
  FakeCommunityServer({
    this.latency = const Duration(milliseconds: 400),
    this.acceptDelay = const Duration(seconds: 4),
    Random? random,
    DateTime Function()? clock,
    bool seed = true,
  }) : _random = random ?? Random(),
       _now = clock ?? DateTime.now {
    if (seed) _seed();
  }

  final Duration latency;

  /// null ise davetliler kendiliğinden katılmaz.
  final Duration? acceptDelay;
  final Random _random;
  final DateTime Function() _now;

  final _mine = <CareGroup>[];
  final _joined = <CareGroup>[];
  final _messages = <CommunityMessage>[];

  /// Sunucuda bekleyen, başkalarına ait gruplar (kodla katılınabilir).
  final _others = <String, CareGroup>{};
  final _timers = <Timer>[];
  var _read = 0;
  var _ids = 0;

  /// Demoda kodla katılmak için kullanılabilen grup kodu.
  static const demoCode = 'KAYA24';

  void _seed() {
    final now = _now();
    final elif = CareGroup(
      id: 'g-elif',
      name: 'Elif',
      ownedByMe: false,
      inviteCode: 'ELIF7Q',
      members: const [
        GroupMember(
          id: 'm-elif',
          name: 'Elif',
          isOwner: true,
          shares: {ShareScope.heartRate, ShareScope.sleep, ShareScope.activity},
        ),
      ],
    );
    _others[elif.inviteCode] = elif;
    _others[demoCode] = const CareGroup(
      id: 'g-kaya',
      name: 'Kaya ailesi',
      ownedByMe: false,
      inviteCode: demoCode,
      members: [
        GroupMember(
          id: 'm-ahmet',
          name: 'Ahmet',
          isOwner: true,
          shares: {ShareScope.heartRate, ShareScope.bloodPressure},
        ),
        GroupMember(id: 'm-zeynep', name: 'Zeynep', shares: {ShareScope.sleep}),
      ],
    );
    _messages.add(
      CommunityMessage(
        id: 'msg-elif',
        kind: CommunityMessageKind.invite,
        from: 'Elif',
        groupName: elif.name,
        groupId: elif.id,
        time: now.subtract(const Duration(hours: 3)),
      ),
    );
  }

  @override
  List<CareGroup> get myGroups => List.unmodifiable(_mine);
  @override
  List<CareGroup> get joinedGroups => List.unmodifiable(_joined);
  @override
  List<CommunityMessage> get messages => List.unmodifiable(
    _messages.toList()..sort((a, b) => b.time.compareTo(a.time)),
  );
  @override
  int get unreadCount => max(0, _messages.length - _read);

  @override
  CareGroup? group(String id) {
    for (final g in [..._mine, ..._joined]) {
      if (g.id == id) return g;
    }
    return null;
  }

  Future<void> _wait() =>
      latency == Duration.zero ? Future.value() : Future.delayed(latency);

  String _id(String prefix) => '$prefix-${++_ids}';

  String _code() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  static const _me = GroupMember(id: 'me', name: '', isMe: true);

  void _replace(String id, CareGroup Function(CareGroup) update) {
    for (final list in [_mine, _joined]) {
      final i = list.indexWhere((g) => g.id == id);
      if (i >= 0) list[i] = update(list[i]);
    }
  }

  @override
  Future<CareGroup> createGroup(String name) async {
    await _wait();
    final g = CareGroup(
      id: _id('g'),
      name: name.trim(),
      ownedByMe: true,
      inviteCode: _code(),
      members: [
        GroupMember(id: _me.id, name: _me.name, isMe: true, isOwner: true),
      ],
    );
    _mine.add(g);
    notifyListeners();
    return g;
  }

  @override
  Future<String> invite(String groupId, String name) async {
    await _wait();
    final member = GroupMember(id: _id('m'), name: name.trim(), pending: true);
    _replace(groupId, (g) => g.copyWith(members: [...g.members, member]));
    notifyListeners();
    final code = group(groupId)?.inviteCode ?? '';
    final delay = acceptDelay;
    if (delay == null) return code;
    _timers.add(
      Timer(delay, () {
        final g = group(groupId);
        if (g == null || !g.members.any((m) => m.id == member.id)) return;
        _replace(
          groupId,
          (g) => g.copyWith(
            members: [
              for (final m in g.members)
                m.id == member.id
                    ? m.copyWith(
                        pending: false,
                        shares: {ShareScope.heartRate, ShareScope.activity},
                      )
                    : m,
            ],
          ),
        );
        _messages.add(
          CommunityMessage(
            id: _id('msg'),
            kind: CommunityMessageKind.memberJoined,
            from: member.name,
            groupName: g.name,
            groupId: g.id,
            time: _now(),
          ),
        );
        notifyListeners();
      }),
    );
    return code;
  }

  @override
  Future<void> removeMember(String groupId, String memberId) async {
    await _wait();
    _replace(
      groupId,
      (g) => g.copyWith(
        members: g.members.where((m) => m.id != memberId).toList(),
      ),
    );
    notifyListeners();
  }

  @override
  Future<void> setConsent(String groupId, Set<ShareScope> scopes) async {
    await _wait();
    final consent = ShareConsent(
      scopes: Set.unmodifiable(scopes),
      grantedAt: scopes.isEmpty ? null : _now(),
    );
    _replace(
      groupId,
      (g) => g.copyWith(
        myConsent: consent,
        members: [
          for (final m in g.members) m.isMe ? m.copyWith(shares: scopes) : m,
        ],
      ),
    );
    notifyListeners();
  }

  CareGroup _join(CareGroup g) {
    final joined = g.copyWith(members: [...g.members, _me]);
    _joined.add(joined);
    return joined;
  }

  @override
  Future<CareGroup?> joinWithCode(String code) async {
    await _wait();
    final key = code.trim().toUpperCase();
    final g = _others[key];
    if (g == null) return null;
    final existing = group(g.id);
    if (existing != null) return existing;
    final joined = _join(g);
    // Bu gruba ait bekleyen davet varsa yanıtlanmış sayılır.
    _answer((m) => m.groupId == g.id);
    notifyListeners();
    return joined;
  }

  void _answer(bool Function(CommunityMessage) test) {
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      if (m.kind == CommunityMessageKind.invite && !m.answered && test(m)) {
        _messages[i] = CommunityMessage(
          id: m.id,
          kind: m.kind,
          from: m.from,
          groupName: m.groupName,
          groupId: m.groupId,
          time: m.time,
          answered: true,
        );
      }
    }
  }

  @override
  Future<void> answerInvite(String messageId, {required bool accept}) async {
    await _wait();
    final msg = _messages.firstWhere((m) => m.id == messageId);
    if (accept) {
      final g = _others.values.where((g) => g.id == msg.groupId).firstOrNull;
      if (g != null && group(g.id) == null) _join(g);
    }
    _answer((m) => m.id == messageId);
    notifyListeners();
  }

  @override
  Future<void> leave(String groupId) async {
    await _wait();
    _mine.removeWhere((g) => g.id == groupId);
    _joined.removeWhere((g) => g.id == groupId);
    notifyListeners();
  }

  @override
  void markAllRead() {
    if (_read == _messages.length) return;
    _read = _messages.length;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }
}
