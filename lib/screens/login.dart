import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();

  bool _lembrar = true;
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString("remember_email");
    final remember = prefs.getBool("remember_enabled") ?? true;

    setState(() {
      _lembrar = remember;
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _email.text = savedEmail;
      }
    });
  }

  Future<void> _saveRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("remember_enabled", _lembrar);
    if (_lembrar) {
      await prefs.setString("remember_email", _email.text.trim());
    } else {
      await prefs.remove("remember_email");
    }
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().signIn(
            _email.text.trim(),
            _senha.text,
          );

      await _saveRememberedEmail();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao entrar: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetSenha() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informe seu e-mail para recuperar a senha.")),
      );
      return;
    }

    try {
      await context.read<AuthProvider>().sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enviamos um link de recuperação para seu e-mail.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao enviar e-mail: $e")),
      );
    }
  }

  InputDecoration _decoration({
    required String label,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
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
        borderSide: const BorderSide(color: Colors.red),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }


  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7ED),
      appBar: AppBar(
        title: const Text("Login", style: TextStyle(fontWeight: FontWeight.w600),),
        backgroundColor: const Color(0xFFFDF7ED),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo1.png',
                  height: 90,
                ),

                const SizedBox(height: 16),
                Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            "Login",
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),

                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _decoration(
                              label: "E-mail",
                              prefixIcon: Icon(Icons.email_outlined),
                              
                            ),
                            validator: (v) {
                              final s = (v ?? "").trim();
                              if (s.isEmpty) return "Informe o e-mail";
                              if (!s.contains("@")) return "E-mail inválido";
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _senha,
                            obscureText: _obscure,
                            decoration: _decoration(
                              label: "Senha",
                              prefixIcon: const Icon(Icons.lock_outline),
                             
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                              ),
                            ),
                            validator: (v) {
                              if ((v ?? "").isEmpty) return "Informe a senha";
                              if ((v ?? "").length < 6) return "Senha deve ter no mínimo 6 caracteres";
                              return null;
                            },
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              
                              Row(
                                children: [
                                  Checkbox(
                                    value: _lembrar,
                                    activeColor: const Color(0xFFC29500), 
                                    checkColor: Colors.black,
                                    onChanged: (v) => setState(() => _lembrar = v ?? true),
                                  ),
                                  const Text(
                                    "Lembrar de mim",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                             
                              TextButton(
                                onPressed: _loading ? null : _resetSenha,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "Esqueci minha senha",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontStyle: FontStyle.italic,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),



                          const SizedBox(height: 8),

                          ElevatedButton(
                            onPressed: _loading ? null : _entrar,
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
                                : const Text("Entrar", style: TextStyle(fontWeight: FontWeight.w600),),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => Navigator.pushNamed(context, '/cadastro'),
                                child: const Text("Ainda não possui cadastro? Cadastre-se.",
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
            ]
          ),
          ),
        ),
      ),
    );
  }
}
