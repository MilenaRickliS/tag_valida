class PrinterConfigModel {
  final String id;
  final String uid;

  final String nome;
  final String modelo;

  final String tipoConexao;

  final String ip;
  final int porta;


  final String tamanhoEtiqueta;

  final bool ativo;
  final bool padrao;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PrinterConfigModel({
    required this.id,
    required this.uid,
    required this.nome,
    required this.modelo,
    required this.tipoConexao,
    required this.ip,
    required this.porta,
    required this.tamanhoEtiqueta,
    required this.ativo,
    required this.padrao,
    this.createdAt,
    this.updatedAt,
  });

  factory PrinterConfigModel.empty(String uid) {
    final now = DateTime.now();

    return PrinterConfigModel(
      id: '',
      uid: uid,
      nome: 'Impressora principal',
      modelo: 'Elgin L42 Pro',
      tipoConexao: 'network',
      ip: '',
      porta: 9100,
      tamanhoEtiqueta: '60x40',
      ativo: true,
      padrao: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  PrinterConfigModel copyWith({
    String? id,
    String? uid,
    String? nome,
    String? modelo,
    String? tipoConexao,
    String? ip,
    int? porta,
    String? tamanhoEtiqueta,
    bool? ativo,
    bool? padrao,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrinterConfigModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      modelo: modelo ?? this.modelo,
      tipoConexao: tipoConexao ?? this.tipoConexao,
      ip: ip ?? this.ip,
      porta: porta ?? this.porta,
      tamanhoEtiqueta: tamanhoEtiqueta ?? this.tamanhoEtiqueta,
      ativo: ativo ?? this.ativo,
      padrao: padrao ?? this.padrao,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'nome': nome,
      'modelo': modelo,
      'tipoConexao': tipoConexao,
      'ip': ip,
      'porta': porta,
      'tamanhoEtiqueta': tamanhoEtiqueta,
      'ativo': ativo ? 1 : 0,
      'padrao': padrao ? 1 : 0,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory PrinterConfigModel.fromMap(Map<String, dynamic> map) {
    return PrinterConfigModel(
      id: (map['id'] ?? '').toString(),
      uid: (map['uid'] ?? '').toString(),
      nome: (map['nome'] ?? '').toString(),
      modelo: (map['modelo'] ?? '').toString(),
      tipoConexao: (map['tipoConexao'] ?? 'network').toString(),
      ip: (map['ip'] ?? '').toString(),
      porta: map['porta'] is int
          ? map['porta'] as int
          : int.tryParse(map['porta']?.toString() ?? '9100') ?? 9100,
      tamanhoEtiqueta: (map['tamanhoEtiqueta'] ?? '60x40').toString(),
      ativo: _toBool(map['ativo'], defaultValue: true),
      padrao: _toBool(map['padrao'], defaultValue: true),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    final text = value.toString().toLowerCase().trim();
    if (text == '1' || text == 'true') return true;
    if (text == '0' || text == 'false') return false;
    return defaultValue;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    final parsedInt = int.tryParse(value.toString());
    if (parsedInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(parsedInt);
    }
    return DateTime.tryParse(value.toString());
  }

  bool get isNetwork =>
      tipoConexao.toLowerCase().trim() == 'network';

  bool get isUsb =>
      tipoConexao.toLowerCase().trim() == 'usb';

  bool get isBluetooth =>
      tipoConexao.toLowerCase().trim() == 'bluetooth';

  bool get isValida {
    if (nome.trim().isEmpty) return false;
    if (modelo.trim().isEmpty) return false;
    if (tipoConexao.trim().isEmpty) return false;

    if (isNetwork) {
      if (ip.trim().isEmpty) return false;
      if (porta <= 0) return false;
    }

    return true;
  }

  @override
  String toString() {
    return 'PrinterConfigModel('
        'id: $id, '
        'uid: $uid, '
        'nome: $nome, '
        'modelo: $modelo, '
        'tipoConexao: $tipoConexao, '
        'ip: $ip, '
        'porta: $porta, '
        'tamanhoEtiqueta: $tamanhoEtiqueta, '
        'ativo: $ativo, '
        'padrao: $padrao'
        ')';
  }
}