import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();

  final nome = TextEditingController();
  final razao = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();
  final cnpj = TextEditingController();
  final cep = TextEditingController();
  final rua = TextEditingController();
  final numero = TextEditingController();
  final bairro = TextEditingController();
  final complemento = TextEditingController();
  final cidade = TextEditingController();
  final estado = TextEditingController();
  final telefone = TextEditingController();
  final responsavel = TextEditingController();
  final logo = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    nome.dispose();
    razao.dispose();
    email.dispose();
    senha.dispose();
    cnpj.dispose();
    cep.dispose();
    rua.dispose();
    numero.dispose();
    bairro.dispose();
    complemento.dispose();
    cidade.dispose();
    estado.dispose();
    telefone.dispose();
    responsavel.dispose();
    logo.dispose();
    super.dispose();
  }

  String? _req(String? v, String label, {int min = 1}) {
    final s = (v ?? "").trim();
    if (s.isEmpty) return "Informe $label";
    if (s.length < min) return "$label muito curto";
    return null;
  }

  Future<void> _cadastrar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().register(
            nome: nome.text.trim(),
            razao: razao.text.trim(),
            email: email.text.trim(),
            senha: senha.text,
            cnpj: cnpj.text.trim(),
            cep: cep.text.trim(),
            rua: rua.text.trim(),
            numero: numero.text.trim(),
            bairro: bairro.text.trim(),
            complemento: complemento.text.trim(),
            cidade: cidade.text.trim(),
            estado: estado.text.trim(),
            telefone: telefone.text.trim(),
            responsavel: responsavel.text.trim(),
            logo: logo.text.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cadastro realizado!")),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao cadastrar: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field({
    required TextEditingController c,
    required String label,
    TextInputType? type,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.black54,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFC29500),
            fontWeight: FontWeight.w600,
          ),

          filled: true,
          fillColor: Colors.white.withOpacity(0.85),

          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.black.withOpacity(0.15),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFC29500), 
              width: 1.8,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
        ),

        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7ED),
      appBar: AppBar(
        title: const Text("Cadastro", style: TextStyle(fontWeight: FontWeight.w600),),
        backgroundColor: const Color(0xFFFDF7ED),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field(
                        c: nome,
                        label: "Nome (fantasia)",
                        validator: (v) => _req(v, "o nome"),
                        prefixIcon: const Icon(Icons.storefront_outlined),
                      ),
                      _field(
                        c: razao,
                        label: "Razão social",
                        validator: (v) => _req(v, "a razão social"),
                        prefixIcon: const Icon(Icons.business_outlined),
                      ),
                      _field(
                        c: email,
                        label: "E-mail",
                        type: TextInputType.emailAddress,
                        validator: (v) {
                          final s = (v ?? "").trim();
                          if (s.isEmpty) return "Informe o e-mail";
                          if (!s.contains("@")) return "E-mail inválido";
                          return null;
                        },
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      _field(
                        c: senha,
                        label: "Senha",
                        obscure: _obscure,
                        validator: (v) {
                          if ((v ?? "").isEmpty) return "Informe a senha";
                          if ((v ?? "").length < 6) return "Senha deve ter no mínimo 6 caracteres";
                          return null;
                        },
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),

                      const Divider(height: 24),

                      _field(
                        c: cnpj,
                        label: "CNPJ",
                        type: TextInputType.number,
                        validator: (v) => _req(v, "o CNPJ", min: 11),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      _field(
                        c: telefone,
                        label: "Telefone",
                        type: TextInputType.phone,
                        validator: (v) => _req(v, "o telefone", min: 8),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      _field(
                        c: responsavel,
                        label: "Responsável",
                        validator: (v) => _req(v, "o responsável"),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),

                      const Divider(height: 24),

                      _field(
                        c: cep,
                        label: "CEP",
                        type: TextInputType.number,
                        validator: (v) => _req(v, "o CEP", min: 8),
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                      _field(
                        c: rua,
                        label: "Rua",
                        validator: (v) => _req(v, "a rua"),
                        prefixIcon: const Icon(Icons.signpost_outlined),
                      ),
                      _field(
                        c: numero,
                        label: "Número",
                        type: TextInputType.number,
                        validator: (v) => _req(v, "o número"),
                        prefixIcon: const Icon(Icons.tag_outlined),
                      ),
                      _field(
                        c: bairro,
                        label: "Bairro",
                        validator: (v) => _req(v, "o bairro"),
                        prefixIcon: const Icon(Icons.map_outlined),
                      ),
                      _field(
                        c: complemento,
                        label: "Complemento (opcional)",
                        validator: (_) => null,
                        prefixIcon: const Icon(Icons.add_location_alt_outlined),
                      ),
                      _field(
                        c: cidade,
                        label: "Cidade",
                        validator: (v) => _req(v, "a cidade"),
                        prefixIcon: const Icon(Icons.location_city_outlined),
                      ),
                      _field(
                        c: estado,
                        label: "Estado (UF)",
                        validator: (v) => _req(v, "o estado/UF", min: 2),
                        prefixIcon: const Icon(Icons.flag_outlined),
                      ),
                      _field(
                        c: logo,
                        label: "Logo (URL ou caminho) (opcional)",
                        validator: (_) => null,
                        prefixIcon: const Icon(Icons.image_outlined),
                      ),

                      const SizedBox(height: 8),

                      ElevatedButton(
                        onPressed: _loading ? null : _cadastrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:const Color(0xFFC29500),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                        ),

                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text("Cadastrar", style: TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                           onPressed: _loading
                                ? null
                                : () => Navigator.pushNamed(context, '/login'),
                            child: const Text(
                              "Já possui conta? Faça login.",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,               
                                decoration: TextDecoration.underline, 
                                
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
      ),
    );
  }
}
