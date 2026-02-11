import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  static const _dbName = 'tag_valida.db';
  static const _dbVersion = 5;

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

    await db.execute('''
      CREATE TABLE setores (
        id TEXT NOT NULL,
        uid TEXT NOT NULL,
        nome TEXT NOT NULL,
        descricao TEXT,
        ativo INTEGER NOT NULL,
        createdAt INTEGER,
        updatedAt INTEGER,
        PRIMARY KEY (uid, id)
      );
    ''');

    await db.execute('''
      CREATE TABLE tipos_etiqueta (
        id TEXT NOT NULL,
        uid TEXT NOT NULL,
        nome TEXT NOT NULL,
        descricao TEXT,
        usarRegraValidadeCategoria INTEGER NOT NULL,
        camposCustomJson TEXT NOT NULL,
        createdAt INTEGER,
        updatedAt INTEGER,
        PRIMARY KEY (uid, id)
      );
    ''');

    await db.execute('''
      CREATE TABLE etiquetas (
        id TEXT NOT NULL,
        uid TEXT NOT NULL,

        tipoId TEXT NOT NULL,
        tipoNome TEXT NOT NULL,

        produtoNome TEXT NOT NULL,

        categoriaId TEXT NOT NULL,
        categoriaNome TEXT NOT NULL,

        setorId TEXT NOT NULL,
        setorNome TEXT NOT NULL,

        dataFabricacaoMs INTEGER NOT NULL,
        dataValidadeMs INTEGER NOT NULL,

        camposCustomValoresJson TEXT NOT NULL,

        status TEXT NOT NULL,

        createdAt INTEGER,
        updatedAt INTEGER,

        PRIMARY KEY (uid, id)
      );
    ''');

    await db.execute('CREATE INDEX idx_categorias_uid ON categorias(uid);');
    await db.execute('CREATE INDEX idx_categorias_uid_ativo ON categorias(uid, ativo);');
    await db.execute('CREATE INDEX idx_categorias_uid_nome ON categorias(uid, nome);');
    await db.execute('CREATE INDEX idx_setores_uid ON setores(uid);');
    await db.execute('CREATE INDEX idx_setores_uid_ativo ON setores(uid, ativo);');
    await db.execute('CREATE INDEX idx_setores_uid_nome ON setores(uid, nome);');
    await db.execute('CREATE INDEX idx_tipos_uid ON tipos_etiqueta(uid);');
    await db.execute('CREATE INDEX idx_tipos_uid_nome ON tipos_etiqueta(uid, nome);');
    await db.execute('CREATE INDEX idx_etq_uid_created ON etiquetas(uid, createdAt);');
    await db.execute('CREATE INDEX idx_etq_uid_status ON etiquetas(uid, status);');
    await db.execute('CREATE INDEX idx_etq_uid_validade ON etiquetas(uid, dataValidadeMs);');
    await db.execute('CREATE INDEX idx_etq_uid_categoria ON etiquetas(uid, categoriaId);');
    await db.execute('CREATE INDEX idx_etq_uid_setor ON etiquetas(uid, setorId);');
    await db.execute('CREATE INDEX idx_etq_uid_tipo ON etiquetas(uid, tipoId);');
    await db.execute('CREATE INDEX idx_etq_uid_status_validade ON etiquetas(uid, status, dataValidadeMs);');
  
    await db.execute('''
      CREATE TABLE outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        entity TEXT NOT NULL,
        entityId TEXT NOT NULL,
        op TEXT NOT NULL,              -- UPSERT | DELETE
        payloadJson TEXT,              -- JSON do registro (para UPSERT)
        createdAt INTEGER NOT NULL,    -- ms
        tries INTEGER NOT NULL DEFAULT 0,
        lastError TEXT
      );
    ''');

    await db.execute('CREATE INDEX idx_outbox_uid_created ON outbox(uid, createdAt);');
    await db.execute('CREATE INDEX idx_outbox_uid_entity ON outbox(uid, entity);');
  }


  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE setores (
          id TEXT NOT NULL,
          uid TEXT NOT NULL,
          nome TEXT NOT NULL,
          descricao TEXT,
          ativo INTEGER NOT NULL,
          createdAt INTEGER,
          updatedAt INTEGER,
          PRIMARY KEY (uid, id)
        );
      ''');

      await db.execute('CREATE INDEX idx_setores_uid ON setores(uid);');
      await db.execute('CREATE INDEX idx_setores_uid_ativo ON setores(uid, ativo);');
      await db.execute('CREATE INDEX idx_setores_uid_nome ON setores(uid, nome);');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE tipos_etiqueta (
          id TEXT NOT NULL,
          uid TEXT NOT NULL,
          nome TEXT NOT NULL,
          descricao TEXT,
          usarRegraValidadeCategoria INTEGER NOT NULL,
          camposCustomJson TEXT NOT NULL,
          createdAt INTEGER,
          updatedAt INTEGER,
          PRIMARY KEY (uid, id)
        );
      ''');
      await db.execute('CREATE INDEX idx_tipos_uid ON tipos_etiqueta(uid);');
      await db.execute('CREATE INDEX idx_tipos_uid_nome ON tipos_etiqueta(uid, nome);');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE etiquetas (
          id TEXT NOT NULL,
          uid TEXT NOT NULL,

          tipoId TEXT NOT NULL,
          tipoNome TEXT NOT NULL,

          produtoNome TEXT NOT NULL,

          categoriaId TEXT NOT NULL,
          categoriaNome TEXT NOT NULL,

          setorId TEXT NOT NULL,
          setorNome TEXT NOT NULL,

          dataFabricacaoMs INTEGER NOT NULL,
          dataValidadeMs INTEGER NOT NULL,

          camposCustomValoresJson TEXT NOT NULL,

          status TEXT NOT NULL,

          createdAt INTEGER,
          updatedAt INTEGER,

          PRIMARY KEY (uid, id)
        );
      ''');

      await db.execute('CREATE INDEX idx_etq_uid_created ON etiquetas(uid, createdAt);');
      await db.execute('CREATE INDEX idx_etq_uid_status ON etiquetas(uid, status);');
      await db.execute('CREATE INDEX idx_etq_uid_validade ON etiquetas(uid, dataValidadeMs);');
      await db.execute('CREATE INDEX idx_etq_uid_categoria ON etiquetas(uid, categoriaId);');
      await db.execute('CREATE INDEX idx_etq_uid_setor ON etiquetas(uid, setorId);');
      await db.execute('CREATE INDEX idx_etq_uid_tipo ON etiquetas(uid, tipoId);');
      await db.execute('CREATE INDEX idx_etq_uid_status_validade ON etiquetas(uid, status, dataValidadeMs);');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE outbox (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT NOT NULL,
          entity TEXT NOT NULL,
          entityId TEXT NOT NULL,
          op TEXT NOT NULL,
          payloadJson TEXT,
          createdAt INTEGER NOT NULL,
          tries INTEGER NOT NULL DEFAULT 0,
          lastError TEXT
        );
      ''');
      await db.execute('CREATE INDEX idx_outbox_uid_created ON outbox(uid, createdAt);');
      await db.execute('CREATE INDEX idx_outbox_uid_entity ON outbox(uid, entity);');
    }
  }
}