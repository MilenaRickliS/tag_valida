import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  static const _dbName = 'tag_valida.db';
  static const _dbVersion = 11;

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
        controlaLote INTEGER NOT NULL DEFAULT 0,
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

      lote TEXT,

      camposCustomValoresJson TEXT NOT NULL,

      status TEXT NOT NULL,

     
      quantidade REAL NOT NULL DEFAULT 1,
      quantidadeRestante REAL NOT NULL DEFAULT 1,
      statusEstoque TEXT NOT NULL DEFAULT 'ativo', 
      soldAtMs INTEGER,                             

      createdAt INTEGER,
      updatedAt INTEGER,

      PRIMARY KEY (uid, id)
    );
  ''');

    await db.execute('''
      CREATE TABLE etiquetas_templates (
        id TEXT NOT NULL,
        uid TEXT NOT NULL,

        tipoId TEXT NOT NULL,
        tipoNome TEXT NOT NULL,

        produtoNome TEXT NOT NULL,

        categoriaId TEXT NOT NULL,
        categoriaNome TEXT NOT NULL,

        setorId TEXT NOT NULL,
        setorNome TEXT NOT NULL,

        camposCustomValoresJson TEXT NOT NULL,

        quantidadePadrao REAL NOT NULL DEFAULT 1,

        createdAt INTEGER,
        updatedAt INTEGER,

        PRIMARY KEY (uid, id)
      );
    ''');

    await db.execute('CREATE INDEX idx_tpl_uid_updated ON etiquetas_templates(uid, updatedAt);');
    await db.execute('CREATE INDEX idx_tpl_uid_produto ON etiquetas_templates(uid, produtoNome);');
    await db.execute('CREATE INDEX idx_tpl_uid_tipo ON etiquetas_templates(uid, tipoId);');
    await db.execute('CREATE INDEX idx_tpl_uid_categoria ON etiquetas_templates(uid, categoriaId);');
    await db.execute('CREATE INDEX idx_tpl_uid_setor ON etiquetas_templates(uid, setorId);');
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
    await db.execute('CREATE INDEX idx_etq_uid_statusEstoque ON etiquetas(uid, statusEstoque);');
    await db.execute('CREATE INDEX idx_etq_uid_lote ON etiquetas(uid, lote);');

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


    await db.execute('''
      CREATE TABLE estoque_mov (
        id TEXT NOT NULL,
        uid TEXT NOT NULL,

        etiquetaId TEXT NOT NULL,
        tipo TEXT NOT NULL,             
        quantidade REAL NOT NULL,        
        motivo TEXT,
        produtoNome TEXT,  
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,

        PRIMARY KEY (uid, id)
      );
    ''');

    await db.execute('CREATE INDEX idx_mov_uid_created ON estoque_mov(uid, createdAt);');
    await db.execute('CREATE INDEX idx_mov_uid_etiqueta ON estoque_mov(uid, etiquetaId);');
    await db.execute('CREATE INDEX idx_mov_uid_tipo ON estoque_mov(uid, tipo);');

    await db.execute('''
      CREATE TABLE printer_configs (
        id TEXT NOT NULL PRIMARY KEY,
        uid TEXT NOT NULL,
        nome TEXT NOT NULL,
        modelo TEXT NOT NULL,
        tipoConexao TEXT NOT NULL,
        ip TEXT,
        porta INTEGER NOT NULL DEFAULT 9100,
        tamanhoEtiqueta TEXT NOT NULL DEFAULT '60x40',
        ativo INTEGER NOT NULL DEFAULT 1,
        padrao INTEGER NOT NULL DEFAULT 1,
        createdAt INTEGER,
        updatedAt INTEGER
      )
    ''');

    await db.execute('CREATE INDEX idx_printer_configs_uid ON printer_configs(uid)');
  
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
    if (oldVersion < 6) {
      final cols = await db.rawQuery("PRAGMA table_info(etiquetas)");
      bool hasCol(String name) => cols.any((c) => (c["name"]?.toString() == name));

      if (!hasCol("quantidade")) {
        await db.execute("ALTER TABLE etiquetas ADD COLUMN quantidade REAL NOT NULL DEFAULT 1;");
      }
      if (!hasCol("quantidadeRestante")) {
        await db.execute("ALTER TABLE etiquetas ADD COLUMN quantidadeRestante REAL NOT NULL DEFAULT 1;");
      }
      if (!hasCol("statusEstoque")) {
        await db.execute("ALTER TABLE etiquetas ADD COLUMN statusEstoque TEXT NOT NULL DEFAULT 'ativo';");
      }
      if (!hasCol("soldAtMs")) {
        await db.execute("ALTER TABLE etiquetas ADD COLUMN soldAtMs INTEGER;");
      }

      await db.execute('CREATE INDEX IF NOT EXISTS idx_etq_uid_statusEstoque ON etiquetas(uid, statusEstoque);');
    }
    if (oldVersion < 7) {
     
      await db.execute('''
        CREATE TABLE IF NOT EXISTS estoque_mov (
          id TEXT NOT NULL,
          uid TEXT NOT NULL,
          etiquetaId TEXT NOT NULL,
          tipo TEXT NOT NULL,
          quantidade REAL NOT NULL,
          motivo TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          PRIMARY KEY (uid, id)
        );
      ''');

     
      final cols = await db.rawQuery("PRAGMA table_info(estoque_mov)");
      bool hasCol(String name) =>
          cols.any((c) => (c["name"]?.toString() == name));

      if (!hasCol("produtoNome")) {
        await db.execute("ALTER TABLE estoque_mov ADD COLUMN produtoNome TEXT;");
      }

      await db.execute('CREATE INDEX IF NOT EXISTS idx_mov_uid_created ON estoque_mov(uid, createdAt);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_mov_uid_etiqueta ON estoque_mov(uid, etiquetaId);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_mov_uid_tipo ON estoque_mov(uid, tipo);');
    }
    if (oldVersion < 8) {
      final cols = await db.rawQuery("PRAGMA table_info(estoque_mov)");
      final hasProdutoNome = cols.any((c) => c["name"] == "produtoNome");
      if (!hasProdutoNome) {
        await db.execute("ALTER TABLE estoque_mov ADD COLUMN produtoNome TEXT;");
      }
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS etiquetas_templates (
          id TEXT NOT NULL,
          uid TEXT NOT NULL,

          tipoId TEXT NOT NULL,
          tipoNome TEXT NOT NULL,

          produtoNome TEXT NOT NULL,

          categoriaId TEXT NOT NULL,
          categoriaNome TEXT NOT NULL,

          setorId TEXT NOT NULL,
          setorNome TEXT NOT NULL,

          camposCustomValoresJson TEXT NOT NULL,

          quantidadePadrao REAL NOT NULL DEFAULT 1,

          createdAt INTEGER,
          updatedAt INTEGER,

          PRIMARY KEY (uid, id)
        );
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_tpl_uid_updated ON etiquetas_templates(uid, updatedAt);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tpl_uid_produto ON etiquetas_templates(uid, produtoNome);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tpl_uid_tipo ON etiquetas_templates(uid, tipoId);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tpl_uid_categoria ON etiquetas_templates(uid, categoriaId);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tpl_uid_setor ON etiquetas_templates(uid, setorId);');
    }
    if (oldVersion < 10) {
    
      final colsTipo = await db.rawQuery("PRAGMA table_info(tipos_etiqueta)");
      bool hasTipoCol(String name) => colsTipo.any((c) => (c["name"]?.toString() == name));

      if (!hasTipoCol("controlaLote")) {
        await db.execute("ALTER TABLE tipos_etiqueta ADD COLUMN controlaLote INTEGER NOT NULL DEFAULT 0;");
      }

     
      final colsEtq = await db.rawQuery("PRAGMA table_info(etiquetas)");
      bool hasEtqCol(String name) => colsEtq.any((c) => (c["name"]?.toString() == name));

      if (!hasEtqCol("lote")) {
        await db.execute("ALTER TABLE etiquetas ADD COLUMN lote TEXT;");
      }

      await db.execute('CREATE INDEX IF NOT EXISTS idx_etq_uid_lote ON etiquetas(uid, lote);');
    }
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE printer_configs (
          id TEXT NOT NULL PRIMARY KEY,
          uid TEXT NOT NULL,
          nome TEXT NOT NULL,
          modelo TEXT NOT NULL,
          tipoConexao TEXT NOT NULL,
          ip TEXT,
          porta INTEGER NOT NULL DEFAULT 9100,
          tamanhoEtiqueta TEXT NOT NULL DEFAULT '60x40',
          ativo INTEGER NOT NULL DEFAULT 1,
          padrao INTEGER NOT NULL DEFAULT 1,
          createdAt INTEGER,
          updatedAt INTEGER
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_printer_configs_uid ON printer_configs(uid)',
      );
    }
  }
}