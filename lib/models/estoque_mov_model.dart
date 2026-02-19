class EstoqueMovModel {
  static const tipoEntrada = "entrada";
  static const tipoVenda = "venda";
  static const tipoCancelamento = "cancelamento";
  static const tipoAjusteEntrada = "ajuste_entrada";
  static const tipoAjusteSaida = "ajuste_saida";

  final String id;
  final String etiquetaId;
  final String? produtoNome;
  final String tipo;
  final num quantidade;
  final String? motivo;
  final DateTime createdAt;
  final DateTime updatedAt;

  EstoqueMovModel({
    required this.id,
    required this.etiquetaId,
    required this.tipo,
    required this.quantidade,
    required this.createdAt,
    required this.updatedAt,
    this.produtoNome,
    this.motivo,
  });
}