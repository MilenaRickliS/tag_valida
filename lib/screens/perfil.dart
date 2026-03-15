// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart'; 
import '../widgets/menu.dart';
import '../models/user.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class _EditarPerfilModal extends StatefulWidget {
  const _EditarPerfilModal();

  @override
  State<_EditarPerfilModal> createState() => _EditarPerfilModalState();
}

class _EditarPerfilModalState extends State<_EditarPerfilModal> {

  final _formKey = GlobalKey<FormState>();
  final FocusNode _numeroFocus = FocusNode();

  final _phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _cepMask = MaskTextInputFormatter(
    mask: '##.###-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final RegExp _lettersAccentsAndNumbers = RegExp(r"^[A-Za-zÀ-ÿ0-9çÇ ]+$");
  final RegExp _lettersAccentsOnly = RegExp(r"^[A-Za-zÀ-ÿçÇ ]+$");
  final RegExp _onlyDigits = RegExp(r"^[0-9]+$");


  late final TextEditingController nome;
  late final TextEditingController razao;
  late final TextEditingController telefone;
  late final TextEditingController responsavel;

  late final TextEditingController cep;
  late final TextEditingController rua;
  late final TextEditingController numero;
  late final TextEditingController bairro;
  late final TextEditingController complemento;
  late final TextEditingController cidade;
  late final TextEditingController estado;

  bool _saving = false;

  bool _cepLoading = false;
  String _lastCepFetched = "";

  String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user!;

    nome = TextEditingController(text: u.nome);
    razao = TextEditingController(text: u.razao);

 
    telefone = TextEditingController(text: _formatPhoneFromDigits(u.telefone));
    responsavel = TextEditingController(text: u.responsavel);

    cep = TextEditingController(text: _formatCepFromDigits(u.cep));
    rua = TextEditingController(text: u.rua);
    numero = TextEditingController(text: u.numero);
    bairro = TextEditingController(text: u.bairro);
    complemento = TextEditingController(text: u.complemento);
    cidade = TextEditingController(text: u.cidade);
    estado = TextEditingController(text: u.estado);
  }

  @override
  void dispose() {
    _numeroFocus.dispose();
    nome.dispose();
    razao.dispose();
    telefone.dispose();
    responsavel.dispose();
    cep.dispose();
    rua.dispose();
    numero.dispose();
    bairro.dispose();
    complemento.dispose();
    cidade.dispose();
    estado.dispose();
    super.dispose();
  }



  String? _vNome(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Nome não pode ser vazio.";
    if (!_lettersAccentsAndNumbers.hasMatch(s)) {
      return "Nome só pode conter letras, acentos, ç e números.";
    }
    return null;
  }

  String? _vRazao(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Razão social não pode ser vazia.";
    if (!_lettersAccentsAndNumbers.hasMatch(s)) {
      return "Razão social só pode conter letras, acentos, ç e números.";
    }
    return null;
  }

  String? _vTelefone(String? _) {
    final digits = _digits(telefone.text);
    if (digits.isEmpty) return "Telefone não pode ser vazio.";
    if (digits.length != 11) return "Telefone inválido. Use: (xx) xxxxx-xxxx";
    return null;
  }


  String? _vResponsavel(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Responsável não pode ser vazio.";
    if (!_lettersAccentsOnly.hasMatch(s)) {
      return "Responsável só pode conter letras, acentos e ç.";
    }
    return null;
  }

  String? _vCep(String? _) {
    final digits = _digits(cep.text);
    if (digits.isEmpty) return "CEP não pode ser vazio.";
    if (digits.length != 8) return "CEP inválido. Use: xx.xxx-xxx";
    return null;
  }

  String? _vRua(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Rua não pode ser vazia.";
    if (!_lettersAccentsAndNumbers.hasMatch(s)) {
      return "Rua só pode conter letras, acentos, ç e números.";
    }
    return null;
  }

  String? _vNumero(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Número não pode ser vazio.";
    if (!_onlyDigits.hasMatch(s)) return "Número deve conter apenas números.";
    return null;
  }

  String? _vBairro(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Bairro não pode ser vazio.";
    return null;
  }

  String? _vCidade(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Cidade não pode ser vazia.";
    if (!_lettersAccentsOnly.hasMatch(s)) {
      return "Cidade só pode conter letras, acentos e ç.";
    }
    return null;
  }

  String? _vEstado(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return "Estado não pode ser vazio.";
    if (!_lettersAccentsOnly.hasMatch(s)) {
      return "Estado só pode conter letras, acentos e ç.";
    }
    if (s.length != 2) return "UF deve ter 2 letras.";
    return null;
  }

  Future<void> _buscarCep(String rawCepDigits) async {
    if (rawCepDigits.length != 8) return;
    if (rawCepDigits == _lastCepFetched) return;

    setState(() => _cepLoading = true);

    try {
      final url = Uri.parse("https://viacep.com.br/ws/$rawCepDigits/json/");
      final res = await http.get(url);

      if (res.statusCode != 200) {
        throw Exception("Falha ao consultar CEP.");
      }

      final data = json.decode(res.body) as Map<String, dynamic>;
      if (data['erro'] == true) {
        throw Exception("CEP não encontrado.");
      }

      rua.text = (data['logradouro'] ?? '').toString();
      bairro.text = (data['bairro'] ?? '').toString();
      cidade.text = (data['localidade'] ?? '').toString();
      estado.text = (data['uf'] ?? '').toString();

      _lastCepFetched = rawCepDigits;

      if (mounted) FocusScope.of(context).requestFocus(_numeroFocus);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro no CEP: $e")),
      );
    } finally {
      if (mounted) setState(() => _cepLoading = false);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateProfile(
        nome: nome.text.trim(),
        razao: razao.text.trim(),
        telefone: _digits(telefone.text),
        responsavel: responsavel.text.trim(),
        cep: _digits(cep.text),
        rua: rua.text.trim(),
        numero: numero.text.trim(),
        bairro: bairro.text.trim(),
        complemento: complemento.text.trim(),
        cidade: cidade.text.trim(),
        estado: estado.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dados atualizados!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFFDF7ED);
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final muted = isDark ? const Color(0xFFD6D6D6) : const Color(0xFF6B6B6B);
    final brand = isDark ? const Color(0xFFD4AF37) : const Color(0xFFED7227);
    final border = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.06);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                    ? Colors.white.withOpacity(0.14)
                    : Colors.black.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),

        
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: brand.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Icon(Icons.edit_rounded, color: brand),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Editar dados",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Atualize as informações da empresa",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: text),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _sectionTitle("Dados principais", brand, text),
                          _field(
                            c: nome,
                            label: "Nome (fantasia)",
                            validator: _vNome,
                            prefixIcon: const Icon(Icons.storefront_outlined),
                            isDark: isDark,
                            textColor: text,
                            borderColor: border,
                          ),
                          _field(
                            c: razao,
                            label: "Razão social",
                            validator: _vRazao,
                            prefixIcon: const Icon(Icons.business_outlined),
                            isDark: isDark,
                            textColor: text,
                            borderColor: border,
                          ),
                          _field(
                            c: telefone,
                            label: "Telefone",
                            type: TextInputType.phone,
                            validator: _vTelefone,
                            inputFormatters: [_phoneMask],
                            prefixIcon: const Icon(Icons.phone_outlined),
                            isDark: isDark,
                            textColor: text,
                            borderColor: border,
                          ),
                          _field(
                            c: responsavel,
                            label: "Responsável",
                            validator: _vResponsavel,
                            prefixIcon: const Icon(Icons.person_outline),
                            isDark: isDark,
                            textColor: text,
                            borderColor: border,
                          ),

                          const SizedBox(height: 4),
                          Divider(height: 18, color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.06),),
                          const SizedBox(height: 2),

                          _sectionTitle("Endereço", brand, text),
                          _field(
                            c: cep,
                            label: "CEP",
                            type: TextInputType.number,
                            validator: _vCep,
                            inputFormatters: [_cepMask],
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            suffixIcon: _cepLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : IconButton(
                                    tooltip: "Buscar CEP",
                                    onPressed: () => _buscarCep(_cepMask.getUnmaskedText()),
                                    icon: Icon(Icons.search, color: text),
                                  ),
                            onChanged: (_) {
                              final digits = _cepMask.getUnmaskedText();
                              if (digits.length == 8) _buscarCep(digits);
                            },
                            isDark: isDark,
                            textColor: text,
                            borderColor: border,
                          ),
                          _field(
                            c: rua,
                            label: "Rua",
                            validator: _vRua,
                            prefixIcon: const Icon(Icons.signpost_outlined),
                            isDark: isDark,
                            textColor: text,
                            borderColor: border,
                          ),
                          _field(
                            c: numero,
                            label: "Número",
                            type: TextInputType.number,
                            validator: _vNumero,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            prefixIcon: const Icon(Icons.tag_outlined),
                            focusNode: _numeroFocus,
                            isDark: isDark,
                            textColor: text,
                            borderColor: border,
                          ),
                          _field(
                            c: bairro,
                            label: "Bairro",
                            validator: _vBairro,
                            prefixIcon: const Icon(Icons.map_outlined),
                            isDark: isDark,
                            textColor: text,
                            borderColor: border,
                          ),
                          _field(
                            c: complemento,
                            label: "Complemento (opcional)",
                            validator: (_) => null,
                            prefixIcon: const Icon(Icons.add_location_alt_outlined),
                            isDark: isDark,
                            textColor: text,
                            borderColor: border,
                          ),
                          _field(
                            c: cidade,
                            label: "Cidade",
                            validator: _vCidade,
                            prefixIcon: const Icon(Icons.location_city_outlined),
                            isDark: isDark,
                            textColor: text,
                            borderColor: border,
                          ),
                          _field(
                            c: estado,
                            label: "Estado (UF)",
                            validator: _vEstado,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÀ-ÿçÇ]")),
                              LengthLimitingTextInputFormatter(2),
                            ],
                            prefixIcon: const Icon(Icons.flag_outlined),
                            onChanged: (v) {
                              final up = v.toUpperCase();
                              if (up != v) {
                                estado.value = estado.value.copyWith(
                                  text: up,
                                  selection: TextSelection.collapsed(offset: up.length),
                                );
                              }
                            },
                            isDark: isDark,
                            textColor: text,
                            borderColor: border,
                          ),

                          const SizedBox(height: 10),

                        
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _saving ? null : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: text,
                                    side: BorderSide(color: border, width: 1.4),
                                    backgroundColor:
                                      isDark ? const Color(0xFF1A1A1A) : null,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text("Cancelar", style: TextStyle(fontWeight: FontWeight.w900)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: brand,
                                    foregroundColor: isDark ? Colors.black : Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: _saving
                                      ? SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white,),
                                        )
                                      : const Text("Salvar", style: TextStyle(fontWeight: FontWeight.w900)),
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
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t, Color brand, Color text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: brand,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            t,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    FocusNode? focusNode,
    required TextEditingController c,
    required String label,
    TextInputType? type,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    required bool isDark,
    required Color textColor,
    required Color borderColor,
  }) {
    final fill = isDark ? const Color(0xFF161616) : const Color(0xFFFAF7F1);
    final prefixColor = isDark ? const Color(0xFFD4AF37) : textColor;
    final labelColor =
        isDark ? const Color(0xFFD6D6D6) : textColor.withOpacity(0.6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        inputFormatters: inputFormatters,
        focusNode: focusNode,
        onChanged: onChanged,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.w700),
          floatingLabelStyle: TextStyle(
            color: isDark ? const Color(0xFFD4AF37) : textColor,
            fontWeight: FontWeight.w900,
          ),
          filled: true,
          fillColor: fill,
          prefixIcon: prefixIcon != null
                      ? IconTheme(
                          data: IconThemeData(color: prefixColor),
                          child: prefixIcon,
                        )
                      : null,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide( color: isDark ? const Color(0xFFD4AF37) : textColor, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
        validator: validator,
      ),
    );
  }

  
  String _formatCepFromDigits(String s) {
    final d = s.replaceAll(RegExp(r'\D'), '');
    if (d.length != 8) return s;
    _cepMask.clear();
    return _cepMask.maskText(d);
  }

  String _formatPhoneFromDigits(String s) {
    final d = s.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return s;
    _phoneMask.clear();
    return _phoneMask.maskText(d);
  }
}

class PerfilScreen extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onLogout;

  const PerfilScreen({
    super.key,
    this.onEdit,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);
  

    final bg = theme.scaffoldBackgroundColor;

    if (user == null) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
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
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                compact ? 14 : 20,
                14,
                compact ? 14 : 20,
                22,
              ),
              children: [
                _HeaderCard(
                  user: user,
                  compact: compact,
                  onEdit: onEdit ?? () => _defaultEdit(context),
                  onLogout: onLogout ?? () => _defaultLogout(context),
                ),
                const SizedBox(height: 14),

                
                _InfoCard(
                  title: "Contato",
                  icon: Icons.call_rounded,
                  rows: [
                    _InfoRow(label: "E-mail", value: user.email),
                    _InfoRow(label: "Telefone", value: user.telefone),
                    _InfoRow(label: "Responsável", value: user.responsavel),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: "Empresa",
                  icon: Icons.storefront_rounded,
                  rows: [
                    _InfoRow(label: "CNPJ", value: user.cnpj),
                    _InfoRow(label: "CEP", value: user.cep),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: "Endereço",
                  icon: Icons.location_on_rounded,
                  rows: [
                    _InfoRow(label: "Rua", value: user.rua),
                    _InfoRow(label: "Número", value: user.numero),
                    _InfoRow(label: "Bairro", value: user.bairro),
                    _InfoRow(label: "Complemento", value: user.complemento),
                    _InfoRow(
                      label: "Cidade/UF",
                      value: "${user.cidade} - ${user.estado}",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _defaultEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditarPerfilModal(),
    );
  }

  void _defaultLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dialogBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF2B2B2B);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Sair",
                style: TextStyle(fontWeight: FontWeight.w900, color: titleColor,),
              ),
            ),
          ],
        ),
        content: Text(
          "Deseja sair da sua conta agora?",
          style: TextStyle(
            color: isDark ? const Color(0xFFD6D6D6) : const Color(0xFF2B2B2B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700,)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              Navigator.pop(context);

              try {
                await context.read<AuthProvider>().logout();

               
              } catch (_) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Erro ao sair. Tente novamente.")),
                );
              }
            },
            child: const Text("Sair"),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final UserModel user;
  final bool compact;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  const _HeaderCard({
    required this.user,
    required this.compact,
    required this.onEdit,
    required this.onLogout,
  });

  static const _brand = Color(0xFFED7227);
  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final muted = isDark ? const Color(0xFFD6D6D6) : const Color(0xFF6B6B6B);
    final border = isDark
        ? _gold.withOpacity(0.16)
        : Colors.black.withOpacity(0.06);
    final shadow = Colors.black.withOpacity(isDark ? 0.28 : 0.06);

    final avatar = _buildAvatar(isDark);

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 10),
            color: shadow,
          ),
        ],
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              avatar,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.razao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: muted.withOpacity(0.95),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _Pill(
                          icon: Icons.badge_rounded,
                          text: _maskCnpj(user.cnpj),
                        ),
                        _Pill(
                          icon: Icons.place_rounded,
                          text: "${user.cidade}/${user.estado}",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 12),
                _HeaderButtons(
                  onEdit: onEdit,
                  onLogout: onLogout,
                ),
              ],
            ],
          ),
          if (compact) ...[
            const SizedBox(height: 14),
            _HeaderButtons(onEdit: onEdit, onLogout: onLogout),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
  
    final logo = user.logo.trim();

    Widget child;
    if (logo.isEmpty) {
      child = _InitialsAvatar(text: user.nome);
    } else if (logo.startsWith("http")) {
      child = ClipOval(
        child: Image.network(
          logo,
          width: 78,
          height: 78,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialsAvatar(text: user.nome),
        ),
      );
    } else if (logo.startsWith("assets/")) {
      child = ClipOval(
        child: Image.asset(
          logo,
          width: 78,
          height: 78,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialsAvatar(text: user.nome),
        ),
      );
    } else {
     
      child = _InitialsAvatar(text: user.nome);
    }

    return Container(
      width: 86,
      height: 86,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
           colors: isDark
              ? [
                  _gold.withOpacity(0.95),
                  _gold.withOpacity(0.35),
                ]
              : [
                  _brand.withOpacity(0.95),
                  _brand.withOpacity(0.35),
                ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            width: 2,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }

  String _maskCnpj(String cnpj) {
    final digits = cnpj.replaceAll(RegExp(r"\D"), "");
    if (digits.length != 14) return cnpj;
    return "${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}";
  
  }
}

class _HeaderButtons extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  const _HeaderButtons({required this.onEdit, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final outlineColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.35)
        : Colors.black.withOpacity(0.12);
    final editIconColor = isDark
        ? const Color(0xFFD4AF37)
        : Colors.black;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: onEdit,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor,
            side: BorderSide(color: outlineColor, width: 1.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : null,
          ),
          icon: Icon(Icons.edit_rounded, size: 18, color: editIconColor,),
          label: Text(
            "Editar",
            style: TextStyle(fontWeight: FontWeight.w900, color: textColor,),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white,),
          label: const Text(
            "Logout",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final border = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.06);
    final iconBg = isDark
        ? const Color(0xFF2A2A2A)
        : Colors.black.withOpacity(0.05);
    final iconColor = isDark
        ? const Color(0xFFD4AF37)
        : text;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(height: 14,  color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final v = value.trim().isEmpty ? "-" : value.trim();

    final text = isDark ? Colors.white : const Color(0xFF2B2B2B);
    final muted = isDark ? const Color(0xFFD6D6D6) : const Color(0xFF6B6B6B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: muted.withOpacity(0.95),
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
     final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark
        ? const Color(0xFF2A2A2A)
        : Colors.black.withOpacity(0.05);
    final border = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.16)
        : Colors.black.withOpacity(0.06);
    final color = isDark
        ? const Color(0xFFD4AF37)
        : const Color(0xFF2B2B2B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String text;
  const _InitialsAvatar({required this.text});

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return "U";
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final a = parts.first.substring(0, 1).toUpperCase();
    final b = parts.last.substring(0, 1).toUpperCase();
    return "$a$b";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark
        ? const Color(0xFF2A2A2A)
        : Colors.black.withOpacity(0.06);
    final color = isDark
        ? const Color(0xFFD4AF37)
        : const Color(0xFF2B2B2B);

    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
      ),
      child: Center(
        child: Text(
          _initials(text),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ),
    );
  }
}
