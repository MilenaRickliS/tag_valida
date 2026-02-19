import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../data/local/repos/etiquetas_local_repo.dart';
import '../models/etiqueta_model.dart';
import 'etiqueta_firebase_service.dart';
import 'etiqueta_pdf_service.dart';

Future<void> openEtiquetaPdfFlow(
  BuildContext context, {
  required String uid,
  required String etiquetaId,
}) async {
  final repo = context.read<EtiquetasLocalRepo>();
  final fb = EtiquetaFirebaseService();

  EtiquetaModel? e = await repo.getById(uid: uid, id: etiquetaId);

  e ??= await fb.getById(uid: uid, id: etiquetaId);

  if (e == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Etiqueta não encontrada (offline e online).")),
    );
    return;
  }

  final bytes = await EtiquetaPdfService.generateBytes(e);

  final dir = await getTemporaryDirectory();
  final file = File("${dir.path}/etiqueta_${e.id}.pdf");
  await file.writeAsBytes(bytes, flush: true);

  await OpenFilex.open(file.path);
}