import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';
import 'package:tekartik_app_flutter_sembast/sembast.dart';

var _factory = getDatabaseFactory(packageName: 'tekartik_web_kiosk_app');

var _prefsStore = cvStringStoreFactory.store<DbStringRecord>('prefs');
var _prefsGeneralRecord = _prefsStore.castV<DbPrefsGeneral>().record('general');

/// General preferences
class DbPrefsGeneral extends DbStringRecordBase {
  /// true if on
  final on = CvField<bool>('on');

  /// url
  final url = CvField<String>('url');

  @override
  CvFields get fields => [on, url];
}

/// WebKiosk database
class WebKioskDb {
  static const _defaultDbName = 'web_kiosk.db';

  /// Database name
  final String dbName;
  late Database _db;

  /// Constructor
  WebKioskDb({this.dbName = _defaultDbName}) {
    cvAddConstructors([DbPrefsGeneral.new]);
  }

  /// Ready future
  late var ready = () async {
    _db = await _factory.openDatabase(dbName);
  }();

  /// Get general preferences stream
  Stream<DbPrefsGeneral> onGeneral() => _prefsGeneralRecord
      .onRecordSync(_db)
      .map((item) => item ?? DbPrefsGeneral());

  /// Get general preferences
  DbPrefsGeneral getGeneral() =>
      _prefsGeneralRecord.getSync(_db) ?? DbPrefsGeneral();

  /// Set general preferences
  Future<void> setGeneral(DbPrefsGeneral prefs) async {
    await _prefsGeneralRecord.put(_db, prefs);
  }
}

/// Global instance
final globalWebKioskDb = WebKioskDb();
