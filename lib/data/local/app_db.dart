import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  static const _dbName = 'tag_valida.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get db async {
    final existing = _db;
    if (existing != null) return existing;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);

    final database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    _db = database;
    return database;
  }

  Future<void> _onCreate(Database db, int version) async {
    
    await db.execute('''
      CREATE TABLE categorias (
        id TEXT NOT NULL,
        uid TEXT NOT NULL,
        nome TEXT NOT NULL,
        diasVencimento INTEGER NOT NULL,
        ativo INTEGER NOT NULL,
        createdAt INTEGER,
        updatedAt INTEGER,
        PRIMARY KEY (uid, id)
      );
    ''');

    await db.execute('CREATE INDEX idx_categorias_uid ON categorias(uid);');
    await db.execute('CREATE INDEX idx_categorias_uid_ativo ON categorias(uid, ativo);');
    await db.execute('CREATE INDEX idx_categorias_uid_nome ON categorias(uid, nome);');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    
  }
}