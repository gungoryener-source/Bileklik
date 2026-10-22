import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../device/protocol/exercise.dart';
import '../device/protocol/history.dart';
import 'health_store.dart';
import 'models.dart';

/// Ölçümleri telefondaki SQLite veritabanında saklar; uygulama kapanınca
/// veri kaybolmaz, artan senkron kaldığı yerden devam eder.
///
/// Ekranlar depoyu eşzamanlı okuduğu için kayıtlar açılışta belleğe
/// yüklenir. Yeni kayıtlar önce belleğe girer, sonra sırayla diske yazılır.
/// Veritabanı uygulamanın kendi alanındadır (iOS dosya koruması, Android
/// uygulama alanı). Ek şifreleme (SQLCipher) KVKK değerlendirmesiyle
/// birlikte ele alınacak.
class SqliteHealthStore extends MemoryHealthStore {
  SqliteHealthStore._(this._db);

  final Database _db;
  Future<void> _queue = Future.value();
  var _loading = false;

  static const fileName = 'bileklik.db';
  static const schemaVersion = 1;

  /// Veritabanını açar (yoksa oluşturur) ve kayıtları belleğe yükler.
  /// Testler [factory] olarak FFI fabrikasını verir.
  static Future<SqliteHealthStore> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final f = factory ?? databaseFactory;
    final file = path ?? p.join(await f.getDatabasesPath(), fileName);
    final db = await f.openDatabase(
      file,
      options: OpenDatabaseOptions(version: schemaVersion, onCreate: _create),
    );
    final store = SqliteHealthStore._(db);
    await store._load();
    return store;
  }

  static Future<void> _create(Database db, int version) async {
    final b = db.batch()
      ..execute('''
        CREATE TABLE measurements (
          type TEXT NOT NULL,
          time INTEGER NOT NULL,
          value REAL NOT NULL,
          PRIMARY KEY (type, time, value)
        )''')
      ..execute('''
        CREATE TABLE sleep (
          start INTEGER PRIMARY KEY,
          stages BLOB NOT NULL
        )''')
      ..execute('''
        CREATE TABLE workouts (
          start INTEGER PRIMARY KEY,
          sport TEXT,
          duration_s INTEGER NOT NULL,
          steps INTEGER NOT NULL,
          distance_km REAL NOT NULL,
          calories REAL NOT NULL,
          avg_hr INTEGER NOT NULL,
          pace_s INTEGER
        )''')
      ..execute('''
        CREATE TABLE ecg (
          start INTEGER PRIMARY KEY,
          sample_rate INTEGER NOT NULL,
          samples BLOB NOT NULL,
          avg_hr INTEGER,
          min_hr INTEGER,
          max_hr INTEGER,
          sdnn REAL,
          beats INTEGER NOT NULL
        )''');
    await b.commit(noResult: true);
  }

  static int _ms(DateTime t) => t.millisecondsSinceEpoch;
  static DateTime _time(Object? ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms! as int);

  Future<void> _load() async {
    final types = MetricType.values.asNameMap();
    final sports = SportType.values.asNameMap();
    final m = await _db.query('measurements', orderBy: 'time');
    final s = await _db.query('sleep');
    final w = await _db.query('workouts');
    final e = await _db.query('ecg');
    _loading = true;
    try {
      addMeasurements([
        for (final r in m)
          // Sonraki bir sürümün eklediği tür bu sürümde bilinmiyorsa atlanır.
          if (types[r['type']] case final type?)
            Measurement(
              type,
              _time(r['time']),
              (r['value']! as num).toDouble(),
            ),
      ]);
      addSleep([
        for (final r in s)
          SleepSession(_time(r['start']), [
            for (final i in r['stages']! as Uint8List) SleepStage.values[i],
          ]),
      ]);
      addWorkouts([
        for (final r in w)
          Workout(
            type: sports[r['sport']],
            start: _time(r['start']),
            duration: Duration(seconds: r['duration_s']! as int),
            steps: r['steps']! as int,
            distanceKm: (r['distance_km']! as num).toDouble(),
            calories: (r['calories']! as num).toDouble(),
            averageHeartRate: r['avg_hr']! as int,
            pace: r['pace_s'] == null
                ? null
                : Duration(seconds: r['pace_s']! as int),
          ),
      ]);
      for (final r in e) {
        final bytes = r['samples']! as Uint8List;
        addEcg(
          EcgRecording(
            start: _time(r['start']),
            sampleRate: r['sample_rate']! as int,
            samples: Int32List.view(
              Uint8List.fromList(bytes).buffer,
              0,
              bytes.length ~/ 4,
            ),
            averageHeartRate: r['avg_hr'] as int?,
            minHeartRate: r['min_hr'] as int?,
            maxHeartRate: r['max_hr'] as int?,
            sdnn: (r['sdnn'] as num?)?.toDouble(),
            beats: r['beats']! as int,
          ),
        );
      }
    } finally {
      _loading = false;
    }
  }

  @override
  @protected
  void onAdded({
    List<Measurement> measurements = const [],
    List<SleepSession> sleep = const [],
    List<Workout> workouts = const [],
    List<EcgRecording> ecg = const [],
  }) {
    if (_loading) return;
    final b = _db.batch();
    for (final m in measurements) {
      b.insert('measurements', {
        'type': m.type.name,
        'time': _ms(m.time),
        'value': m.value,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final s in sleep) {
      b.insert('sleep', {
        'start': _ms(s.start),
        'stages': Uint8List.fromList([for (final x in s.minutes) x.index]),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final w in workouts) {
      b.insert('workouts', {
        'start': _ms(w.start),
        'sport': w.type?.name,
        'duration_s': w.duration.inSeconds,
        'steps': w.steps,
        'distance_km': w.distanceKm,
        'calories': w.calories,
        'avg_hr': w.averageHeartRate,
        'pace_s': w.pace?.inSeconds,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final r in ecg) {
      b.insert('ecg', {
        'start': _ms(r.start),
        'sample_rate': r.sampleRate,
        'samples': Int32List.fromList(r.samples).buffer.asUint8List(),
        'avg_hr': r.averageHeartRate,
        'min_hr': r.minHeartRate,
        'max_hr': r.maxHeartRate,
        'sdnn': r.sdnn,
        'beats': r.beats,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    // Yazmalar sırayla gider; biri hata verirse sonrakiler yine denenir.
    _write(b, 'ölçümler veritabanına yazılırken');
  }

  @override
  void onRemoved(List<Measurement> measurements) {
    final b = _db.batch();
    for (final m in measurements) {
      b.delete(
        'measurements',
        where: 'type = ? AND time = ? AND value = ?',
        whereArgs: [m.type.name, _ms(m.time), m.value],
      );
    }
    _write(b, 'ölçümler veritabanından silinirken');
  }

  void _write(Batch b, String what) {
    _queue = _queue
        .then((_) async {
          await b.commit(noResult: true);
        })
        .catchError(
          (Object e, StackTrace s) => FlutterError.reportError(
            FlutterErrorDetails(
              exception: e,
              stack: s,
              library: 'bileklik',
              context: ErrorDescription(what),
            ),
          ),
        );
  }

  /// Bekleyen yazmalar diske ulaşınca tamamlanır.
  Future<void> flush() => _queue;

  Future<void> close() async {
    await flush();
    await _db.close();
  }
}
