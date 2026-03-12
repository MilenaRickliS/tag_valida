import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ElginL42NetworkService {
  final String ip;
  final int port;
  final Duration timeout;

  ElginL42NetworkService({
    required this.ip,
    this.port = 9100,
    this.timeout = const Duration(seconds: 5),
  });

  Future<void> sendRaw(String command) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: timeout);

      final normalized = command
              .replaceAll('\r\n', '\n')
              .replaceAll('\r', '\n')
              .split('\n')
              .map((line) => line.trimRight())
              .where((line) => line.isNotEmpty)
              .join('\r\n') +
          '\r\n';

      socket.add(ascii.encode(normalized));
      await socket.flush();
      await Future.delayed(const Duration(milliseconds: 400));
    } finally {
      await socket?.flush();
      await socket?.close();
      socket?.destroy();
    }
  }

  Future<bool> testConnection() async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: timeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      await socket?.close();
      socket?.destroy();
    }
  }

  Future<void> avancarEtiqueta() async {
    const tspl = '''
SIZE 60 mm,40 mm
GAP 2 mm,0 mm
DIRECTION 1
REFERENCE 0,0
CLS
PRINT 1,1
''';

    await sendRaw(tspl);
  }

  Future<void> printTeste() async {
    const tspl = '''
SIZE 60 mm,40 mm
GAP 2 mm,0 mm
DIRECTION 1
REFERENCE 0,0
CLS
TEXT 20,30,"3",0,1,1,"TESTE TAGVALIDA"
TEXT 20,70,"2",0,1,1,"ELGIN L42 PRO OK"
PRINT 1,1
''';

    await sendRaw(tspl);
  }

  Future<void> printEtiqueta60x40Compacta({
    required String produto,
    required String validade,
    required String lote,
    required String quantidade,
    required String qrData,
  }) async {
    final safeProduto = _clean(produto, max: 22);
    final safeValidade = _clean(validade, max: 18);
    final safeLote = _clean(lote, max: 18);
    final safeQuantidade = _clean(quantidade, max: 10);
    final safeQr = _cleanQr(qrData);

    final tspl = '''
SIZE 60 mm,40 mm
GAP 2 mm,0 mm
DIRECTION 1
REFERENCE 0,0
CLS
TEXT 32,18,"3",0,1,1,"$safeProduto"
TEXT 32,95,"2",0,1,1,"Val: $safeValidade"
TEXT 32,120,"2",0,1,1,"Lote: $safeLote"
TEXT 32,145,"2",0,1,1,"Qtd: $safeQuantidade"
QRCODE 320,22,L,3,A,0,"$safeQr"
PRINT 1,1
''';

    await sendRaw(tspl);
  }

  String _clean(String value, {int max = 30}) {
    var text = value
        .replaceAll('"', "'")
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .trim();

    if (text.length > max) {
      text = text.substring(0, max);
    }
    return text;
  }

  String _cleanQr(String value) {
    return value
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .trim();
  }
}