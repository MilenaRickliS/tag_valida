import '../models/printer_config_model.dart';
import 'elgin_l42_network_service.dart';

class PrinterAppService {
  Future<void> imprimirEtiquetaCompacta({
    required PrinterConfigModel printer,
    required String produto,
    required String validade,
    required String lote,
    required String quantidade,
    required String qrData,
  }) async {
    if (!printer.isValida) {
      throw Exception('Configuração da impressora inválida.');
    }

    if (!printer.isNetwork) {
      throw Exception('Tipo de conexão ainda não suportado.');
    }

    if (printer.modelo.trim().toLowerCase() != 'elgin l42 pro') {
      throw Exception('Modelo de impressora não suportado ainda.');
    }

    if (printer.tamanhoEtiqueta != '60x40') {
      throw Exception('Tamanho de etiqueta não suportado ainda.');
    }

    final service = ElginL42NetworkService(
      ip: printer.ip,
      port: printer.porta,
    );

    final connected = await service.testConnection();
    if (!connected) {
      throw Exception(
        'Não foi possível conectar na impressora ${printer.ip}:${printer.porta}',
      );
    }

    await service.printEtiqueta60x40Compacta(
      produto: produto,
      validade: validade,
      lote: lote,
      quantidade: quantidade,
      qrData: qrData,
    );
  }
}