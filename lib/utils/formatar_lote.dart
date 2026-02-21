enum LoteFormato {
  dataHora,   
  prefixoL,   
  original,  
  compacto,   
}

String formatarLote(
  String lote, {
  LoteFormato formato = LoteFormato.dataHora,
}) {
  final original = lote.trim();

  var digits = original.toUpperCase().replaceAll(RegExp(r'[^0-9]'), '');

  if (digits.length == 14) {

    digits = digits.substring(2);
  }

  if (digits.length != 12) {
    return original; 
  }

  final yy = digits.substring(0, 2);
  final mm = digits.substring(2, 4);
  final dd = digits.substring(4, 6);
  final hh = digits.substring(6, 8);
  final mi = digits.substring(8, 10);
  final ss = digits.substring(10, 12);

  switch (formato) {
    case LoteFormato.dataHora:
      return "$dd/$mm/$yy $hh:$mi:$ss";

    case LoteFormato.prefixoL:
      return "L$digits";

    case LoteFormato.original:
      return original;

    case LoteFormato.compacto:
      return digits;
  }
}