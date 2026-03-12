// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/printer_config_model.dart';
import '../providers/printer_config_provider.dart';
import '../services/elgin_l42_network_service.dart';
import '../widgets/menu.dart';

class ConfiguracoesImpressoraScreen extends StatefulWidget {
  const ConfiguracoesImpressoraScreen({super.key});

  @override
  State<ConfiguracoesImpressoraScreen> createState() =>
      _ConfiguracoesImpressoraScreenState();
}

class _ConfiguracoesImpressoraScreenState
    extends State<ConfiguracoesImpressoraScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _modeloCtrl;
  late final TextEditingController _ipCtrl;
  late final TextEditingController _portaCtrl;

  bool _ativo = true;
  bool _padrao = true;
  String _tipoConexao = 'network';
  String _tamanhoEtiqueta = '60x40';
  

  bool _testing = false;
  bool _saving = false;
  bool _testingPrint = false;
  bool _testingAdvance = false;

  bool? _ultimoTesteOk;
  String? _statusMsg;

  static const _bg = Color(0xFFFDF7ED);
  static const _card = Colors.white;
  static const _text = Color(0xFF2B2B2B);
  static const _accent = Color(0xFFED7227);
  static const _green = Color(0xFF2E7D32);
  static const _red = Color(0xFFC62828);

  @override
  void initState() {
    super.initState();

    _nomeCtrl = TextEditingController(text: 'Impressora principal');
    _modeloCtrl = TextEditingController(text: 'Elgin L42 Pro');
    _ipCtrl = TextEditingController();
    _portaCtrl = TextEditingController(text: '9100');

    _nomeCtrl.addListener(() => setState(() {}));
    _modeloCtrl.addListener(() => setState(() {}));
    _ipCtrl.addListener(() => setState(() {}));
    _portaCtrl.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final provider = context.read<PrinterConfigProvider>();
      await provider.load(uid);

      final current = provider.defaultPrinter;
      if (current != null && mounted) {
        _fill(current);
      }
    });
  }

  void _fill(PrinterConfigModel model) {
    _nomeCtrl.text = model.nome;
    _modeloCtrl.text = model.modelo;
    _ipCtrl.text = model.ip;
    _portaCtrl.text = model.porta.toString();
    _ativo = model.ativo;
    _padrao = model.padrao;
    _tipoConexao = model.tipoConexao;
    _tamanhoEtiqueta = model.tamanhoEtiqueta;
    setState(() {});
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _modeloCtrl.dispose();
    _ipCtrl.dispose();
    _portaCtrl.dispose();
    super.dispose();
  }

  Future<ElginL42NetworkService> _buildService() async {
    return ElginL42NetworkService(
      ip: _ipCtrl.text.trim(),
      port: int.tryParse(_portaCtrl.text.trim()) ?? 9100,
    );
  }

  Future<void> _testarConexao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _testing = true;
      _statusMsg = null;
    });

    try {
      final service = await _buildService();
      final ok = await service.testConnection();

      if (!ok) {
        throw Exception('Não foi possível conectar à impressora.');
      }

      setState(() {
        _ultimoTesteOk = true;
        _statusMsg = 'Conexão estabelecida com sucesso.';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Conexão OK com a impressora.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _ultimoTesteOk = false;
        _statusMsg = 'Falha ao conectar à impressora.';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro no teste: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _imprimirTeste() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _testingPrint = true;
      _statusMsg = null;
    });

    try {
      final service = await _buildService();
      final ok = await service.testConnection();

      if (!ok) {
        throw Exception('Não foi possível conectar à impressora.');
      }

      await service.printTeste();

      setState(() {
        _ultimoTesteOk = true;
        _statusMsg = 'Etiqueta de teste enviada com sucesso.';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Etiqueta de teste enviada para impressão.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _ultimoTesteOk = false;
        _statusMsg = 'Erro ao enviar etiqueta de teste.';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao imprimir teste: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _testingPrint = false);
    }
  }

  Future<void> _avancarEtiqueta() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _testingAdvance = true;
    _statusMsg = null;
  });

  try {
    final service = await _buildService();
    final ok = await service.testConnection();

    if (!ok) {
      throw Exception('Não foi possível conectar à impressora.');
    }

    await service.avancarEtiqueta();

    setState(() {
      _ultimoTesteOk = true;
      _statusMsg = 'Comando de avanço enviado com sucesso.';
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Comando de avanço enviado para a impressora.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  } catch (e) {
    setState(() {
      _ultimoTesteOk = false;
      _statusMsg = 'Erro ao avançar etiqueta.';
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro ao avançar etiqueta: $e'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  } finally {
    if (mounted) setState(() => _testingAdvance = false);
  }
}

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final uid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Usuário não autenticado.');
      }

      final provider = context.read<PrinterConfigProvider>();
      final current = provider.defaultPrinter;

      final model = (current ?? PrinterConfigModel.empty(uid)).copyWith(
        nome: _nomeCtrl.text.trim(),
        modelo: _modeloCtrl.text.trim(),
        tipoConexao: _tipoConexao,
        ip: _ipCtrl.text.trim(),
        porta: int.tryParse(_portaCtrl.text.trim()) ?? 9100,
        tamanhoEtiqueta: _tamanhoEtiqueta,
        ativo: _ativo,
        padrao: _padrao,
        updatedAt: DateTime.now(),
      );

      await provider.save(model);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configuração da impressora salva com sucesso.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: Colors.black54) : null,
      filled: true,
      fillColor: const Color(0xFFFFFBF5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrinterConfigProvider>();
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;
    final isWide = w >= 880;

    final statusColor = _ultimoTesteOk == null
        ? Colors.black54
        : (_ultimoTesteOk! ? _green : _red);

    final statusBg = _ultimoTesteOk == null
        ? Colors.grey.withOpacity(0.10)
        : (_ultimoTesteOk!
            ? _green.withOpacity(0.10)
            : _red.withOpacity(0.10));

    final statusBorder = _ultimoTesteOk == null
        ? Colors.grey.withOpacity(0.18)
        : (_ultimoTesteOk!
            ? _green.withOpacity(0.20)
            : _red.withOpacity(0.20));

    final statusTitle = _ultimoTesteOk == null
        ? 'Conexão não testada'
        : (_ultimoTesteOk! ? 'Conectada' : 'Sem conexão');

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7ED),
        elevation: 0,
        toolbarHeight: compact ? 160 : 100,
        centerTitle: true,
        title: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo6.png', height: 78),
                  const SizedBox(height: 10),
                  const TopMenu(),
                ],
              )
            : Row(
                children: [
                  Image.asset('assets/logo6.png', height: 92),
                  const Spacer(),
                  const TopMenu(),
                ],
              ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withOpacity(0.07)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Configuração da impressora",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Configure a impressora de etiquetas da produção, teste a conexão em rede e envie uma etiqueta de teste para validar o funcionamento.",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.60),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),

                    if (provider.error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.withOpacity(0.18)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                provider.error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: statusBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.82),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _ultimoTesteOk == null
                                  ? Icons.print_outlined
                                  : (_ultimoTesteOk!
                                      ? Icons.wifi_tethering_rounded
                                      : Icons.wifi_off_rounded),
                              color: statusColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusTitle,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _statusMsg ??
                                      'Use os botões abaixo para testar a rede e validar a impressão da etiqueta.',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.65),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          _StatusPill(
                            label: _ultimoTesteOk == null
                                ? 'Pendente'
                                : (_ultimoTesteOk! ? 'Online' : 'Offline'),
                            color: statusColor,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _buildConfigCard(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: _buildResumoCard(statusColor),
                          ),
                        ],
                      )
                    else ...[
                      _buildConfigCard(),
                      const SizedBox(height: 16),
                      _buildResumoCard(statusColor),
                    ],

                    const SizedBox(height: 18),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: isWide ? 220 : double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _testing ? null : _testarConexao,
                            icon: _testing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(Icons.wifi_tethering_rounded),
                            label: const Text("Testar conexão"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF4D58D),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: isWide ? 240 : double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _testingPrint ? null : _imprimirTeste,
                            icon: _testingPrint
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(Icons.print_outlined),
                            label: const Text("Imprimir etiqueta teste"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFED7227),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            width: isWide ? 210 : double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _testingAdvance ? null : _avancarEtiqueta,
                              icon: _testingAdvance
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Icon(Icons.skip_next_rounded),
                              label: const Text("Avançar etiqueta"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDCEBFF),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(
                          width: isWide ? 180 : double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _salvar,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text("Salvar"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF88BE8E),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune_rounded, color: _text),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Dados da impressora",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nomeCtrl,
            decoration: _inputDecoration(
              label: 'Nome da impressora',
              icon: Icons.drive_file_rename_outline,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _modeloCtrl,
            decoration: _inputDecoration(
              label: 'Modelo',
              icon: Icons.print_outlined,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Informe o modelo' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _tipoConexao,
            decoration: _inputDecoration(
              label: 'Tipo de conexão',
              icon: Icons.settings_ethernet_rounded,
            ),
            items: const [
              DropdownMenuItem(
                value: 'network',
                child: Text('Rede'),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _tipoConexao = v);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 7,
                child: TextFormField(
                  controller: _ipCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    label: 'IP da impressora',
                    hint: 'Ex.: 192.168.0.120',
                    icon: Icons.language_rounded,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o IP' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _portaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    label: 'Porta',
                    icon: Icons.numbers_rounded,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe a porta';
                    final p = int.tryParse(v.trim());
                    if (p == null || p <= 0) return 'Inválida';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _tamanhoEtiqueta,
            decoration: _inputDecoration(
              label: 'Tamanho da etiqueta',
              icon: Icons.straighten_rounded,
            ),
            items: const [
              DropdownMenuItem(
                value: '60x40',
                child: Text('60x40 mm'),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _tamanhoEtiqueta = v);
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _ativo,
            onChanged: (v) => setState(() => _ativo = v),
            title: const Text(
              'Impressora ativa',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'Permite utilizar esta configuração nas impressões.',
              style: TextStyle(color: Colors.black.withOpacity(0.58)),
            ),
            activeColor: _accent,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _padrao,
            onChanged: (v) => setState(() => _padrao = v),
            title: const Text(
              'Definir como padrão',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'Usar esta impressora automaticamente nas etiquetas.',
              style: TextStyle(color: Colors.black.withOpacity(0.58)),
            ),
            activeColor: _accent,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildResumoCard(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.router_rounded, color: statusColor),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Resumo rápido",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ResumoLinha(
            label: "Modelo",
            value: _modeloCtrl.text.trim().isEmpty ? "-" : _modeloCtrl.text.trim(),
          ),
          _ResumoLinha(
            label: "Conexão",
            value: _tipoConexao == 'network' ? 'Rede' : _tipoConexao,
          ),
          _ResumoLinha(
            label: "IP",
            value: _ipCtrl.text.trim().isEmpty ? "-" : _ipCtrl.text.trim(),
          ),
          _ResumoLinha(
            label: "Porta",
            value: _portaCtrl.text.trim().isEmpty ? "-" : _portaCtrl.text.trim(),
          ),
          _ResumoLinha(
            label: "Etiqueta",
            value: _tamanhoEtiqueta,
          ),
          _ResumoLinha(
            label: "Status",
            value: _ativo ? 'Ativa' : 'Inativa',
            valueColor: _ativo ? _green : _red,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Dicas",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "• Conecte a Elgin L42 Pro e o tablet na mesma rede.\n"
                  "• A porta padrão normalmente é 9100.\n"
                  "• Use “Testar conexão” antes de salvar.\n"
                  "• Use “Imprimir etiqueta teste” para validar a impressão real.",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.62),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ResumoLinha extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ResumoLinha({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.black.withOpacity(0.52),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: valueColor ?? _ConfiguracoesImpressoraScreenState._text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}