// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get aboutDescription =>
      'Bileklik, JCV8 EKG bilekliğinizin ölçümlerini telefonunuzda gösterir.';

  @override
  String get aboutLicenses => 'Açık kaynak lisansları';

  @override
  String get aboutMedical =>
      'Bu uygulama tıbbi cihaz değildir; teşhis ve tedavi için hekiminize danışın. Tansiyon değerleri tahminidir.';

  @override
  String get aboutPrivacy =>
      'Ölçümleriniz yalnızca bu telefonda tutulur. Paylaşım geldiğinde kimin neyi göreceğine siz karar vereceksiniz (KVKK).';

  @override
  String aboutVersion(Object version) {
    return 'Sürüm $version';
  }

  @override
  String get actionCancel => 'Vazgeç';

  @override
  String get actionClose => 'Kapat';

  @override
  String get appTitle => 'Bileklik';

  @override
  String get autoMeasureAllDay => 'Tüm gün';

  @override
  String get autoMeasureConnect => 'Bağlan';

  @override
  String get autoMeasureDays => 'Günler';

  @override
  String get autoMeasureEnd => 'Bitiş';

  @override
  String get autoMeasureEveryDay => 'Her gün';

  @override
  String autoMeasureEveryHours(int hours) {
    return '$hours saatte bir';
  }

  @override
  String autoMeasureEveryMinutes(int minutes) {
    return '$minutes dakikada bir';
  }

  @override
  String get autoMeasureHours => 'Ölçüm saatleri';

  @override
  String get autoMeasureInterval => 'Ölçüm aralığı';

  @override
  String get autoMeasureIntro =>
      'Bileklik seçtiğiniz saatlerde kendiliğinden ölçer. Her ölçüm 1 dakika sürer; aralık kısaldıkça pil daha çabuk biter.';

  @override
  String get autoMeasureLoadFailed => 'Bileklik ayarları okunamadı.';

  @override
  String autoMeasureNextDay(String time) {
    return '$time (ertesi gün)';
  }

  @override
  String get autoMeasureNoDays => 'En az bir gün seçili kalmalı.';

  @override
  String get autoMeasureNotConnected =>
      'Ayarları görmek ve değiştirmek için bilekliği bağlayın.';

  @override
  String get autoMeasureOff => 'Kapalı';

  @override
  String get autoMeasureRetry => 'Tekrar dene';

  @override
  String get autoMeasureSameTime => 'Başlangıç ve bitiş aynı olamaz.';

  @override
  String get autoMeasureSaveFailed =>
      'Ayar bilekliğe yazılamadı. Tekrar deneyin.';

  @override
  String get autoMeasureSleepNote =>
      'Uykudayken bileklik nabzı 5 dakikada bir ölçer.';

  @override
  String get autoMeasureStart => 'Başlangıç';

  @override
  String get autoMeasureTitle => 'Otomatik ölçüm';

  @override
  String autoMeasureTurnOn(String name) {
    return '$name otomatik ölçümü';
  }

  @override
  String get bandAnxious => 'Kaygılı';

  @override
  String get bandCalm => 'Sakin';

  @override
  String get bandGood => 'İyi';

  @override
  String get bandGreat => 'Harika';

  @override
  String get bandLow => 'Düşük';

  @override
  String get bandMild => 'Hafif';

  @override
  String get bandNormal => 'Normal';

  @override
  String get bandTense => 'Gergin';

  @override
  String get clock12 => '12 saat (ÖÖ/ÖS)';

  @override
  String get clock24 => '24 saat';

  @override
  String get clockSystem => 'Dile göre';

  @override
  String get clockTitle => 'Saat biçimi';

  @override
  String get comingSoon => 'Yakında';

  @override
  String get comingSoonMessage => 'Bu bölüm sonraki bir sürümde gelecek.';

  @override
  String get communityAccept => 'Katıl';

  @override
  String get communityAnswered => 'Yanıtlandı';

  @override
  String get communityCodeCopied => 'Kod kopyalandı';

  @override
  String get communityCodeInvalid => 'Bu kodla bir grup bulunamadı.';

  @override
  String get communityCodeLabel => 'Grup kodu';

  @override
  String communityConsentSince(Object date) {
    return 'İzin tarihi: $date';
  }

  @override
  String get communityCopyCode => 'Kodu kopyala';

  @override
  String get communityCreate => 'Oluştur';

  @override
  String get communityCreateGroup => 'Yeni grup oluştur';

  @override
  String get communityDecline => 'Reddet';

  @override
  String get communityDelete => 'Grubu sil';

  @override
  String communityDeleteConfirm(Object group) {
    return '\"$group\" silinir ve gruptaki tüm paylaşımlar sona erer.';
  }

  @override
  String get communityGroupName => 'Grup adı';

  @override
  String get communityGroupNameHint => 'Örn. Ailem';

  @override
  String get communityInvite => 'Üye davet et';

  @override
  String communityInviteCodeBody(Object name) {
    return 'Bu kodu $name ile paylaşın. Uygulamada Sağlık topluluğu > Kodla katıl ile gruba katılabilir.';
  }

  @override
  String get communityInviteCodeTitle => 'Davet kodu';

  @override
  String get communityInviteName => 'Davet edilecek kişinin adı';

  @override
  String get communityInviteSend => 'Davet et';

  @override
  String get communityJoinWithCode => 'Kodla katıl';

  @override
  String get communityJoinedEmpty =>
      'Bir davetle ya da grup koduyla katılabilirsiniz.';

  @override
  String get communityJoinedGroups => 'Katıldığım gruplar';

  @override
  String communityJoinedMessage(Object group) {
    return '\"$group\" grubuna katıldınız.';
  }

  @override
  String get communityLeave => 'Gruptan ayrıl';

  @override
  String communityLeaveConfirm(Object group) {
    return '\"$group\" grubundan ayrılınca paylaştığınız veriler üyelere artık görünmez.';
  }

  @override
  String communityMemberCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count üye',
      one: '1 üye',
    );
    return '$_temp0';
  }

  @override
  String get communityMembers => 'Üyeler';

  @override
  String get communityMessages => 'Mesajlar';

  @override
  String get communityMessagesEmpty => 'Henüz mesaj yok.';

  @override
  String communityMsgInvite(Object name, Object group) {
    return '$name sizi \"$group\" grubuna davet etti.';
  }

  @override
  String communityMsgJoined(Object name, Object group) {
    return '$name, \"$group\" grubuna katıldı.';
  }

  @override
  String get communityMyGroups => 'Gruplarım';

  @override
  String get communityMyGroupsEmpty =>
      'Henüz bir grubunuz yok. Bir grup oluşturup ailenizi davet edin.';

  @override
  String get communityMyShareNote =>
      'Yalnızca bu grubun üyeleri görür. Siz açmadıkça hiçbir veri paylaşılmaz.';

  @override
  String get communityMyShareTitle => 'Bu grupla paylaştıklarınız';

  @override
  String get communityOwner => 'Grup sahibi';

  @override
  String communityOwnerName(Object name) {
    return 'Grup sahibi: $name';
  }

  @override
  String get communityPending => 'Davet bekleniyor';

  @override
  String get communityPrivacyNote =>
      'Sağlık verileriniz yalnızca seçtiğiniz gruplarla ve seçtiğiniz türlerde paylaşılır. İzninizi istediğiniz an geri alabilirsiniz.';

  @override
  String get communityRemoveMember => 'Gruptan çıkar';

  @override
  String communityShares(Object types) {
    return 'Paylaşıyor: $types';
  }

  @override
  String get communitySharesNothing => 'Henüz bir şey paylaşmıyor';

  @override
  String get communityYou => 'Siz';

  @override
  String get connActive => 'Bağlantılarım';

  @override
  String connAgree(Object name) {
    return 'Bu bilgileri okudum. Seçtiğim verilerin yukarıdaki amaçla $name ile paylaşılmasına açıkça rıza veriyorum.';
  }

  @override
  String get connCodeInvalid => 'Bu kod geçersiz ya da süresi dolmuş.';

  @override
  String get connConfirm => 'Onayla ve bağlan';

  @override
  String connConnected(Object name) {
    return '$name ile bağlantı kuruldu.';
  }

  @override
  String get connConsentTitle => 'Açık rıza';

  @override
  String get connDisconnect => 'Bağlantıyı kaldır';

  @override
  String connDisconnectConfirm(Object name) {
    return '$name artık yeni verilerinizi göremez. Daha önce paylaşılanların silinmesini kurumdan isteyebilirsiniz.';
  }

  @override
  String get connDuration => 'Süre';

  @override
  String connDurationText(Object date, Object days) {
    return '$date tarihine kadar ($days gün). Süre bitince paylaşım kendiliğinden durur; daha önce de kaldırabilirsiniz.';
  }

  @override
  String get connEmpty => 'Henüz bir bağlantınız yok.';

  @override
  String get connEnterCode => 'Davet kodu gir';

  @override
  String get connIntro =>
      'Hekiminiz ya da katıldığınız bir araştırma size davet kodu verir. Kodu girince kimin, hangi verileri, ne kadar süre istediğini görür ve siz karar verirsiniz.';

  @override
  String get connKindClinician => 'Hekim';

  @override
  String get connKindResearch => 'Araştırma kurumu';

  @override
  String get connPurpose => 'Amaç';

  @override
  String get connRequested => 'İstenen veriler';

  @override
  String get connRequestedNote =>
      'Paylaşmak istediklerinizi seçin. Seçmedikleriniz paylaşılmaz.';

  @override
  String get connRights =>
      'Verileriniz KVKK kapsamında işlenir. Verilerinize erişme, düzeltilmesini ya da silinmesini isteme hakkınız vardır.';

  @override
  String get connScan => 'QR kodu tara';

  @override
  String get connScanSoon =>
      'Kamerayla tarama yakında. Şimdilik QR kodun altındaki kodu girin.';

  @override
  String get connSelectAll => 'Tümünü seç';

  @override
  String get connShared => 'Paylaşılan veriler';

  @override
  String connSharedCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count veri türü',
      one: '1 veri türü',
    );
    return '$_temp0';
  }

  @override
  String connSince(Object date) {
    return 'Başlangıç: $date';
  }

  @override
  String connUntil(Object date) {
    return 'Bitiş: $date';
  }

  @override
  String get continueButton => 'Devam';

  @override
  String get deviceAddress => 'Adres';

  @override
  String get deviceBattery => 'Pil';

  @override
  String deviceBatteryValue(Object value) {
    return '%$value';
  }

  @override
  String get deviceConnected => 'Bağlı';

  @override
  String get deviceDisconnect => 'Bağlantıyı kes';

  @override
  String get deviceDisconnected => 'Bağlı değil';

  @override
  String get deviceLastSync => 'Son eşitleme';

  @override
  String get devicePairNew => 'Başka bileklik eşleştir';

  @override
  String get deviceSectionSettings => 'Bileklik ayarları';

  @override
  String get deviceStatus => 'Durum';

  @override
  String durationHours(Object h) {
    return '$h sa';
  }

  @override
  String durationHoursMinutes(Object h, Object m) {
    return '$h sa $m dk';
  }

  @override
  String durationMinutes(Object m) {
    return '$m dk';
  }

  @override
  String ecgAverageBpm(Object bpm) {
    return '$bpm bpm ortalama';
  }

  @override
  String get ecgAverageHeartRate => 'Ortalama nabız';

  @override
  String get ecgBeats => 'Atım sayısı';

  @override
  String get ecgBpm => 'bpm';

  @override
  String get ecgCancel => 'Ölçümü iptal et';

  @override
  String get ecgConnectFirst => 'Önce Ana Sayfa\'dan bilekliği bağlayın.';

  @override
  String ecgDetailTitle(Object date, Object time) {
    return 'EKG · $date $time';
  }

  @override
  String get ecgDisclaimer =>
      'Bu ölçüm tıbbi tanı yerine geçmez. Göğüs ağrısı, nefes darlığı ya da bayılma hissi varsa hemen 112\'yi arayın.';

  @override
  String get ecgHowToSteps =>
      '1. Bilekliği bileğinize sıkıca takın.\n2. Oturun, kolunuzu masaya koyun.\n3. Diğer elinizin parmağını bilekliğin üstündeki elektroda hafifçe dokundurun.\n4. 30 saniye boyunca hareket etmeyin ve konuşmayın.';

  @override
  String get ecgHowToTitle => 'Nasıl ölçülür';

  @override
  String get ecgKeepStill =>
      'Parmağınızı elektrottan kaldırmayın ve hareket etmeyin.';

  @override
  String get ecgMeasuringTitle => 'EKG ölçülüyor';

  @override
  String get ecgMs => 'ms';

  @override
  String get ecgNoHeartRate => 'Nabız hesaplanamadı';

  @override
  String get ecgNoRecords => 'Henüz EKG kaydı yok.';

  @override
  String get ecgRange => 'Aralık';

  @override
  String ecgRangeValue(Object min, Object max) {
    return '$min-$max';
  }

  @override
  String ecgRecordHeader(Object seconds, Object perRow) {
    return 'Kayıt ($seconds sn, satır başına $perRow sn)';
  }

  @override
  String ecgRecordSubtitle(Object when, Object seconds) {
    return '$when · $seconds sn';
  }

  @override
  String get ecgRecordsTitle => 'Kayıtlar';

  @override
  String get ecgSdnn => 'Değişkenlik (SDNN)';

  @override
  String ecgSecondsLeft(Object seconds) {
    return '$seconds sn';
  }

  @override
  String get ecgStartButton => '30 saniyelik ölçüm başlat';

  @override
  String get ecgTitle => 'EKG';

  @override
  String get exerciseConnectFirst => 'Önce Ana Sayfa\'dan bilekliği bağlayın.';

  @override
  String get exerciseConnectHint =>
      'Geçmiş egzersizleri görmek için bilekliği bağlayın.';

  @override
  String exerciseCount(int count) {
    return '$count egzersiz';
  }

  @override
  String get exerciseEmpty => 'Henüz egzersiz kaydı yok.';

  @override
  String exerciseInProgress(Object sport) {
    return '$sport sürüyor';
  }

  @override
  String get exerciseLast30Days => 'Son 30 gün';

  @override
  String exercisePausedAt(Object time) {
    return 'Duraklatıldı · $time';
  }

  @override
  String get exerciseStart => 'Egzersiz başlat';

  @override
  String get exerciseThisWeek => 'Bu hafta';

  @override
  String get healthBloodPressure => 'Tansiyon';

  @override
  String healthBloodPressureSubtitle(Object details) {
    return 'Tahmini · $details';
  }

  @override
  String get healthConnectHint =>
      'Verileri görmek için Ana Sayfa\'dan bilekliği bağlayın.';

  @override
  String get healthEcg => 'EKG';

  @override
  String healthEcgLast(Object time) {
    return 'Son ölçüm · $time';
  }

  @override
  String get healthEcgPrompt => '30 saniyelik ölçüm yapın';

  @override
  String healthLastSync(Object time) {
    return 'Son güncelleme $time';
  }

  @override
  String get healthNoMeasurement => 'Ölçüm yok';

  @override
  String get healthNoRecord => 'Kayıt yok';

  @override
  String get healthSleep => 'Uyku';

  @override
  String healthSleepLastNight(Object start, Object end) {
    return 'Dün gece · $start - $end';
  }

  @override
  String healthStepsToday(Object goal) {
    return 'Bugün · hedef $goal';
  }

  @override
  String get healthSyncTooltip => 'Bileklikten güncelle';

  @override
  String get healthSyncing => 'Bileklikten veriler alınıyor…';

  @override
  String homeActiveGoal(Object minutes) {
    return 'Hedef $minutes dk';
  }

  @override
  String get homeActiveTime => 'Aktif süre';

  @override
  String get homeAverageStress => 'Ortalama stres';

  @override
  String homeAverageStressBand(Object band) {
    return 'Ortalama stres · $band';
  }

  @override
  String homeAverageValue(Object value) {
    return 'Ort. $value';
  }

  @override
  String get homeBalance => 'Denge';

  @override
  String get homeBloodOxygen => 'Kan oksijeni';

  @override
  String homeBpm(Object value) {
    return '$value bpm';
  }

  @override
  String get homeCalories => 'Kalori';

  @override
  String homeChartNoData(Object title) {
    return '$title: ölçüm yok';
  }

  @override
  String homeChartSemantics(Object title, Object min, Object max, Object unit) {
    return '$title: en düşük $min, en yüksek $max $unit';
  }

  @override
  String get homeConnectTooltip => 'Bilekliğe bağlan';

  @override
  String get homeConnected => 'Bağlı';

  @override
  String homeConnectedBattery(Object percent) {
    return 'Bağlı · %$percent';
  }

  @override
  String get homeConnecting => 'Bağlanıyor…';

  @override
  String get homeDaySummary => 'Günün özeti';

  @override
  String homeDeepSleep(Object duration) {
    return 'Derin uyku $duration';
  }

  @override
  String get homeDisconnectTooltip => 'Bağlantıyı kes';

  @override
  String get homeEcg => 'EKG';

  @override
  String homeEcgSubtitle(Object bpm, Object seconds) {
    return '$bpm bpm · $seconds sn';
  }

  @override
  String homeEcgSubtitleNoHr(Object seconds) {
    return '$seconds sn';
  }

  @override
  String get homeGoodAfternoon => 'İyi günler';

  @override
  String get homeGoodEvening => 'İyi akşamlar';

  @override
  String get homeGoodMorning => 'Günaydın';

  @override
  String get homeHeartRateHint =>
      'Kalp atış hızınızı görmek için bilekliği gün boyu takın.';

  @override
  String get homeHeartRateLabel => 'Kalp atış hızı';

  @override
  String get homeHeroEmpty => 'Nabzınızı görmek için bilekliği bağlayın.';

  @override
  String homeHeroSemantics(Object value) {
    return 'Nabız $value bpm';
  }

  @override
  String get homeHourlyStressSemantics => 'Saatlik stres sütunları';

  @override
  String get homeHrvLabel => 'Kalp atış hızı değişkenliği';

  @override
  String get homeKcal => 'kcal';

  @override
  String homeKm(Object value) {
    return '$value km';
  }

  @override
  String homeLastMeasured(Object time) {
    return 'Son ölçüm $time';
  }

  @override
  String get homeListSeparator => ', ';

  @override
  String get homeLive => 'Canlı';

  @override
  String get homeMeasureNow => 'Şimdi ölç';

  @override
  String homeMs(Object value) {
    return '$value ms';
  }

  @override
  String get homeNextDay => 'Sonraki gün';

  @override
  String get homeNoRecord => 'Kayıt yok';

  @override
  String get homeNoSleepLastNight => 'Dün gece uyku ölçülmedi';

  @override
  String get homeNoSleepPastHint =>
      'Bilekliğin takılı olduğu günlerin özeti burada görünür.';

  @override
  String get homeNoSleepStages => 'Uyku evresi yok';

  @override
  String get homeNoSleepThisDay => 'Bu gün için uyku kaydı yok';

  @override
  String get homeNoSleepTonightHint =>
      'Bilekliği bu gece takın; sabah uyku ve toparlanma özetiniz burada olacak.';

  @override
  String get homeNotConnected => 'Bağlı değil';

  @override
  String homePercent(Object value) {
    return '%$value';
  }

  @override
  String get homePickDay => 'Gün seçin';

  @override
  String get homePrevDay => 'Önceki gün';

  @override
  String get homeQuickActions => 'Hızlı işlemler';

  @override
  String get homeQuickHeartRate => 'Nabız ölç';

  @override
  String get homeQuickSync => 'Senkronize';

  @override
  String homeRange(Object min, Object max) {
    return '$min-$max';
  }

  @override
  String get homeRecovery => 'Toparlanma';

  @override
  String homeRestingHr(Object value) {
    return 'Dinlenik nabız $value bpm';
  }

  @override
  String get homeSleep => 'Uyku';

  @override
  String homeSleepStageItem(Object stage, Object duration) {
    return '$stage $duration';
  }

  @override
  String homeSleepStagesSemantics(Object stages) {
    return 'Uyku evreleri: $stages';
  }

  @override
  String homeSleptHrvBandSummary(Object duration, Object hrv, Object band) {
    return '$duration uyudunuz, gece HRV ortalamanız $hrv ms ($band).';
  }

  @override
  String homeSleptHrvSummary(Object duration, Object hrv) {
    return '$duration uyudunuz, gece HRV ortalamanız $hrv ms.';
  }

  @override
  String homeSleptSummary(Object duration) {
    return '$duration uyudunuz.';
  }

  @override
  String get homeSpo2Hint =>
      'Kan oksijeninizi görmek için bilekliği gün boyu takın.';

  @override
  String get homeStartWorkout => 'Egzersize başla';

  @override
  String homeStepGoal(Object goal) {
    return 'Hedef $goal adım';
  }

  @override
  String homeStepGoalProgress(Object percent, Object goal) {
    return '%$percent · hedef $goal';
  }

  @override
  String homeStepGoalSemantics(Object steps, Object goal, Object percent) {
    return 'Adım hedefi: $steps / $goal, yüzde $percent';
  }

  @override
  String get homeSteps => 'Adım';

  @override
  String get homeStressHint =>
      'Stres ve HRV, bileklik takılıyken gün içinde ölçülür.';

  @override
  String get homeStressLevel => 'Stres düzeyi';

  @override
  String get homeStressLoad => 'Stres yükü';

  @override
  String get homeSyncing => 'Senkronize ediliyor…';

  @override
  String get homeTimeline => 'Zaman çizelgesi';

  @override
  String get homeTimelineEmpty =>
      'Egzersiz, EKG ve uyku kayıtlarınız burada saat sırasıyla görünür.';

  @override
  String get homeTimelineSubtitle => 'Günün kayıtları';

  @override
  String get homeToday => 'Bugün';

  @override
  String homeWeekdayDate(Object weekday, Object date) {
    return '$weekday, $date';
  }

  @override
  String get homeWokeUp => 'Uyandınız';

  @override
  String homeWokeUpSubtitle(Object duration, Object time) {
    return '$duration uyku · $time yatış';
  }

  @override
  String homeWorkoutSubtitle(Object duration, Object kcal) {
    return '$duration · $kcal kcal';
  }

  @override
  String get homeYesterday => 'Dün';

  @override
  String get hpActivity => 'Adım, mesafe ve kalori';

  @override
  String get hpAuto =>
      'Bileklik eşitlendikçe yeni veriler kendiliğinden aktarılır.';

  @override
  String get hpChooseTypes => 'Aktarılacak veriler';

  @override
  String hpConnect(Object platform) {
    return '$platform ile bağlan';
  }

  @override
  String get hpConnected => 'Bağlı';

  @override
  String hpDenied(Object platform) {
    return 'İzin verilmedi. $platform ayarlarından izin verebilirsiniz.';
  }

  @override
  String get hpDisconnect => 'Aktarımı durdur';

  @override
  String hpDisconnectNote(Object platform) {
    return 'Daha önce yazılan veriler $platform içinde kalır; silmek için $platform ayarlarını kullanın.';
  }

  @override
  String get hpExportNow => 'Şimdi aktar';

  @override
  String hpExported(Object records) {
    return '$records aktarıldı';
  }

  @override
  String get hpHrv => 'Kalp atış hızı değişkenliği (HRV)';

  @override
  String hpIntro(Object platform) {
    return 'Bileklik verileriniz $platform uygulamasına yazılır; telefonunuzdaki diğer sağlık uygulamaları da görebilir. Hangi türlerin aktarılacağını siz seçersiniz.';
  }

  @override
  String hpLastExport(Object time, Object records) {
    return 'Son aktarım: $time · $records';
  }

  @override
  String get hpNever => 'Henüz aktarılmadı';

  @override
  String get hpNotExported =>
      'Tansiyon tahmini olduğu için aktarılmaz. EKG kayıtlarını sağlık platformları dışarıdan kabul etmez.';

  @override
  String get hpNothingNew => 'Aktarılacak yeni kayıt yok';

  @override
  String hpPermissionNote(Object platform) {
    return 'Devam edince $platform izin penceresi açılır; orada da tek tek seçebilirsiniz.';
  }

  @override
  String hpRecords(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kayıt',
      zero: 'kayıt yok',
    );
    return '$_temp0';
  }

  @override
  String get hpTitle => 'Sağlık uygulaması';

  @override
  String hpUnavailable(Object platform) {
    return '$platform bu telefonda yok. Google Play\'den yükleyebilirsiniz.';
  }

  @override
  String get hpWorkouts => 'Egzersizler';

  @override
  String get issueBusy => 'Bileklik şu an başka bir egzersizde ya da ölçümde.';

  @override
  String get issueFailed =>
      'Bileklikle iletişim kurulamadı. Yakında ve açık olduğundan emin olun.';

  @override
  String get issueNoEcgSignal =>
      'EKG verisi alınamadı. Bilekliği takıp parmağınızı elektroda dokundurun.';

  @override
  String get issueNoSpotSignal =>
      'Ölçüm alınamadı. Bilekliği biraz sıkılaştırıp tekrar deneyin.';

  @override
  String get languagePickHint =>
      'Daha sonra Profil ekranından değiştirebilirsiniz.';

  @override
  String get languagePickTitle => 'Dilinizi seçin';

  @override
  String get languageSystem => 'Telefonun dili';

  @override
  String get languageTitle => 'Dil';

  @override
  String get liveCancel => 'Vazgeç';

  @override
  String get liveConfirmBody => 'Egzersiz kaydedilip özet gösterilecek.';

  @override
  String get liveConfirmTitle => 'Egzersizi bitir';

  @override
  String get liveContinue => 'Devam et';

  @override
  String get liveFinish => 'Bitir';

  @override
  String liveInactiveBody(int minutes, int steps) {
    return 'Son $minutes dakikada $steps adımdan az attınız. Egzersizi bitirmek ister misiniz?';
  }

  @override
  String get liveInactiveTitle => 'Hareketsiz görünüyorsunuz';

  @override
  String get livePause => 'Duraklat';

  @override
  String get livePaused => 'Duraklatıldı';

  @override
  String get measureEcg => 'EKG';

  @override
  String get measureEcgHint => 'Parmağınızı elektroda dokundurarak';

  @override
  String get measureHeartRate => 'Nabız';

  @override
  String get measureSheetTitle => 'Ne ölçmek istersiniz?';

  @override
  String get measureSpo2 => 'Kan oksijeni (SpO2)';

  @override
  String measureTakes(Object seconds) {
    return 'Yaklaşık $seconds saniye sürer';
  }

  @override
  String get metricCalories => 'Kalori';

  @override
  String metricDetailAbove(Object value) {
    return '> $value';
  }

  @override
  String get metricDetailBands => 'Aralıklar';

  @override
  String get metricDetailBpEstimate =>
      'Bileklik tansiyonu tahmini olarak hesaplar. Tanı ve tedavi için onaylı bir tansiyon aleti kullanın.';

  @override
  String get metricDetailDailyAverage => 'Günlük ortalama';

  @override
  String get metricDetailNext => 'Sonraki';

  @override
  String get metricDetailNoData => 'Bu dönem için kayıt yok';

  @override
  String get metricDetailPrevious => 'Önceki';

  @override
  String get metricDetailTotal => 'Toplam';

  @override
  String metricDetailWeekRange(Object start, Object end) {
    return '$start - $end';
  }

  @override
  String get metricDiastolic => 'Tansiyon (küçük)';

  @override
  String get metricDistance => 'Mesafe';

  @override
  String get metricHeartRate => 'Kalp Atış Hızı';

  @override
  String get metricHrv => 'Kalp Atış Hızı Değişkenliği';

  @override
  String get metricRespiratoryRate => 'Solunum Hızı';

  @override
  String get metricSpo2 => 'Kan Oksijen Doygunluğu';

  @override
  String get metricSteps => 'Adım';

  @override
  String get metricStress => 'Stres';

  @override
  String get metricSystolic => 'Tansiyon (büyük)';

  @override
  String get metricTemperature => 'Vücut Isısı';

  @override
  String get navExercise => 'Egzersiz';

  @override
  String get navHealth => 'Sağlık';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navProfile => 'Profil';

  @override
  String get navSemantics => 'Ana menü';

  @override
  String get noValue => '--';

  @override
  String get pairCode => 'Adresle eşleştir';

  @override
  String get pairCodeHint =>
      'Kutudaki ya da bilekliğin arkasındaki QR kodunun altında yazan adresi girin.';

  @override
  String get pairCodeInvalid => 'Adres 12 karakterdir, ör. A1:B2:C3:D4:E5:F6';

  @override
  String get pairCodeLabel => 'Cihaz adresi';

  @override
  String get pairCodeNotFound => 'Bu adreste bir bileklik bulunamadı.';

  @override
  String get pairConnect => 'Bağlan';

  @override
  String get pairConnected => 'Bileklik bağlandı.';

  @override
  String get pairFound => 'Bulunan bileklikler';

  @override
  String get pairNoneFound =>
      'Bileklik bulunamadı. Şarjlı ve yakında olduğundan emin olup tekrar deneyin.';

  @override
  String get pairNote =>
      'Bilekliği şarj edin ve telefonun yakınında tutun. Bluetooth açık olmalı.';

  @override
  String get pairScan => 'Aramayı başlat';

  @override
  String get pairScanning => 'Aranıyor…';

  @override
  String pairSignal(Object rssi) {
    return 'Sinyal $rssi';
  }

  @override
  String get pairSubtitle =>
      'Bilekliğinizi bağlayın, ölçümleriniz telefonunuza gelsin.';

  @override
  String get pairTitle => 'Bileklik eşleştirme';

  @override
  String get periodDay => 'Gün';

  @override
  String get periodMonth => 'Ay';

  @override
  String get periodWeek => 'Hafta';

  @override
  String get personalInfoTitle => 'Kişisel bilgiler';

  @override
  String get profileAge => 'Yaş';

  @override
  String get profileConnectFirst =>
      'Bilgileri kaydetmek için önce bilekliği bağlayın.';

  @override
  String profileDevice(Object mac) {
    return 'Cihaz: $mac';
  }

  @override
  String get profileFemale => 'Kadın';

  @override
  String get profileHeight => 'Boy';

  @override
  String get profileMale => 'Erkek';

  @override
  String get profileMenuAbout => 'Hakkında';

  @override
  String get profileMenuCommunity => 'Sağlık topluluğu';

  @override
  String get profileMenuCommunitySubtitle =>
      'Aile grupları ve paylaşım izinleri';

  @override
  String get profileMenuDevice => 'Cihaz';

  @override
  String profileMenuDeviceConnected(Object battery) {
    return 'Bağlı · pil %$battery';
  }

  @override
  String get profileMenuDeviceNone => 'Bileklik bağlı değil';

  @override
  String get profileMenuFeedback => 'Geri bildirim';

  @override
  String get profileMenuGeneral => 'Genel ayarlar';

  @override
  String get profileMenuGeneralSubtitle => 'Dil, saat biçimi, birimler';

  @override
  String get profileMenuPersonalEmpty => 'Yaş, boy ve kilonuzu girin';

  @override
  String profileMenuPersonalSummary(Object age, Object height, Object weight) {
    return '$age yaş · $height cm · $weight kg';
  }

  @override
  String get profileMenuResearch => 'Hekim ve araştırma kurumu';

  @override
  String get profileMenuResearchSubtitle => 'Davet koduyla veri paylaşımı';

  @override
  String get profileMenuThirdParty => 'Health Connect ve Apple Health';

  @override
  String get profileMenuThirdPartySubtitle =>
      'Verileri telefonun sağlık uygulamasına aktar';

  @override
  String get profileMenuVersion => 'Uygulama sürümü';

  @override
  String profileRangeError(Object min, Object max) {
    return '$min ile $max arasında olmalı';
  }

  @override
  String get profileSave => 'Kaydet';

  @override
  String get profileSaved => 'Bilgiler bilekliğe kaydedildi';

  @override
  String get profileSectionApp => 'Uygulama';

  @override
  String get profileSectionSettings => 'Ayarlar';

  @override
  String get profileSectionSharing => 'Paylaşım ve bağlantılar';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileUnitCm => 'cm';

  @override
  String get profileUnitKg => 'kg';

  @override
  String get profileUnitYears => 'yıl';

  @override
  String get profileWeight => 'Kilo';

  @override
  String get reminderAddMedication => 'İlaç saati ekle';

  @override
  String get reminderAddWater => 'Su saati ekle';

  @override
  String get reminderAlarm => 'Çalar saat';

  @override
  String reminderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hatırlatıcı',
      one: '1 hatırlatıcı',
      zero: 'Hatırlatıcı yok',
    );
    return '$_temp0';
  }

  @override
  String reminderCountSedentary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hatırlatıcı ve hareketsizlik uyarısı',
      one: '1 hatırlatıcı ve hareketsizlik uyarısı',
      zero: 'Yalnızca hareketsizlik uyarısı',
    );
    return '$_temp0';
  }

  @override
  String get reminderDelete => 'Sil';

  @override
  String get reminderDuplicate =>
      'Bu saatte aynı türde bir hatırlatıcı zaten var.';

  @override
  String get reminderEdit => 'Hatırlatıcıyı düzenle';

  @override
  String get reminderEmptyMedication =>
      'İlaç saatlerinizi ekleyin; bileklik o saatte titrer.';

  @override
  String get reminderEmptyWater =>
      'Gün içinde su içmeyi hatırlatması için saat ekleyin.';

  @override
  String get reminderLabel => 'İlaç adı (isteğe bağlı)';

  @override
  String get reminderLabelHint => 'ör. Sabah ilacı';

  @override
  String get reminderMedication => 'İlaç';

  @override
  String get reminderNewMedication => 'Yeni ilaç hatırlatıcısı';

  @override
  String get reminderNewWater => 'Yeni su hatırlatıcısı';

  @override
  String get reminderSave => 'Kaydet';

  @override
  String get reminderTime => 'Saat';

  @override
  String get reminderWater => 'Su';

  @override
  String get reminderWeekdays => 'Hafta içi';

  @override
  String get reminderWeekend => 'Hafta sonu';

  @override
  String remindersFull(int max) {
    return 'Bileklik en fazla $max hatırlatıcı tutabilir.';
  }

  @override
  String get remindersIntro =>
      'Hatırlatma saati gelince bileklik titrer; telefona bildirim gelmez.';

  @override
  String get remindersLoadFailed => 'Hatırlatıcılar bileklikten okunamadı.';

  @override
  String get remindersNotConnected =>
      'Hatırlatıcıları görmek ve değiştirmek için bilekliği bağlayın.';

  @override
  String get remindersSaveFailed =>
      'Hatırlatıcı bilekliğe yazılamadı. Tekrar deneyin.';

  @override
  String get remindersTitle => 'Hatırlatıcılar';

  @override
  String sedentaryHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours saat',
      one: '1 saat',
    );
    return '$_temp0';
  }

  @override
  String sedentaryHoursMinutes(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String get sedentaryInterval => 'Hareketsiz kalma süresi';

  @override
  String sedentaryMinutes(int minutes) {
    return '$minutes dakika';
  }

  @override
  String sedentaryNote(int steps) {
    return 'Bu sürede $steps adımdan az atarsanız uyarı gelir. Uykuda uyarı gelmez.';
  }

  @override
  String sedentarySubtitle(String time) {
    return '$time boyunca kıpırdamazsanız bileklik titrer.';
  }

  @override
  String get sedentaryTitle => 'Hareketsizlik uyarısı';

  @override
  String get shareActivity => 'Aktivite ve adım';

  @override
  String get shareBloodPressure => 'Tansiyon (tahmini)';

  @override
  String get shareEcg => 'EKG kayıtları';

  @override
  String get shareHeartRate => 'Nabız';

  @override
  String get shareSleep => 'Uyku';

  @override
  String get shareSpo2 => 'Kan oksijeni (SpO2)';

  @override
  String get shareStress => 'Stres ve HRV';

  @override
  String get shareTemperature => 'Vücut ısısı';

  @override
  String get sleepAwake => 'Uyanık';

  @override
  String get sleepDeep => 'Derin';

  @override
  String get sleepDuration => 'Uyku süresi';

  @override
  String get sleepEmpty => 'Henüz uyku kaydı yok';

  @override
  String get sleepLast7Nights => 'Son 7 gece';

  @override
  String get sleepLight => 'Hafif';

  @override
  String get sleepNextNight => 'Sonraki gece';

  @override
  String sleepPercent(Object value) {
    return '%$value';
  }

  @override
  String get sleepPreviousNight => 'Önceki gece';

  @override
  String get sleepRem => 'REM';

  @override
  String sleepTimeRange(Object start, Object end) {
    return '$start - $end';
  }

  @override
  String get sleepTitle => 'Uyku';

  @override
  String sleepWeekBarHint(Object day, Object duration) {
    return '$day: $duration';
  }

  @override
  String get sportAerobics => 'Aerobik';

  @override
  String get sportBadminton => 'Badminton';

  @override
  String get sportBasketball => 'Basketbol';

  @override
  String get sportCricket => 'Kriket';

  @override
  String get sportCycling => 'Bisiklet';

  @override
  String get sportDance => 'Dans';

  @override
  String get sportFootball => 'Futbol';

  @override
  String get sportHiking => 'Doğa yürüyüşü';

  @override
  String get sportMeditation => 'Meditasyon';

  @override
  String get sportPingPong => 'Masa tenisi';

  @override
  String get sportRopeJump => 'İp atlama';

  @override
  String get sportRun => 'Koşu';

  @override
  String get sportSitUps => 'Mekik';

  @override
  String get sportTennis => 'Tenis';

  @override
  String get sportUnknown => 'Egzersiz';

  @override
  String get sportVolleyball => 'Voleybol';

  @override
  String get sportWalk => 'Yürüyüş';

  @override
  String get sportWorkout => 'Antrenman';

  @override
  String get sportYoga => 'Yoga';

  @override
  String get spotAgain => 'Tekrar ölç';

  @override
  String get spotDone => 'Bitti';

  @override
  String get spotKeepStill =>
      'Bilekliği bileğinize oturtun, kolunuzu bir yere dayayıp hareket etmeyin.';

  @override
  String get spotLowSpo2 =>
      'Değer düşük. Dinlenip tekrar ölçün; düşük kalırsa hekiminize danışın.';

  @override
  String get spotMeasuring => 'Ölçülüyor…';

  @override
  String get spotMoving => 'Hareket algılandı. Kolunuzu sabit tutun.';

  @override
  String get spotNote => 'Bileklik ölçümü tıbbi cihaz yerine geçmez.';

  @override
  String get spotOffWrist =>
      'Bileklik bileğinizde görünmüyor. Takıp sıkıca oturtun.';

  @override
  String spotSaved(Object time) {
    return '$time ölçümü kaydedildi';
  }

  @override
  String get statAverage => 'Ortalama';

  @override
  String get statAvgHeartRate => 'Ortalama nabız';

  @override
  String get statDuration => 'Süre';

  @override
  String get statMax => 'En yüksek';

  @override
  String get statMin => 'En düşük';

  @override
  String get statPace => 'Tempo';

  @override
  String statPercent(Object value) {
    return '%$value';
  }

  @override
  String get unitPerMinute => '/dk';

  @override
  String get unitSteps => 'adım';

  @override
  String get unitsImperial => 'ABD (mil, °F)';

  @override
  String get unitsMetric => 'Metrik (km, °C)';

  @override
  String get unitsTitle => 'Birimler';

  @override
  String get wearDetectionFailed =>
      'Takma algılama ayarı bilekliğe yazılamadı.';

  @override
  String get wearDetectionSubtitle =>
      'Ölçüm sırasında bileklik çıkarılırsa ya da kolunuz hareket ederse uyarır.';

  @override
  String get wearDetectionTitle => 'Takma algılama';

  @override
  String get workoutCongrats => 'Tebrikler, egzersiz kaydedildi';

  @override
  String workoutTimeRange(Object day, Object start, Object end) {
    return '$day · $start - $end';
  }
}
