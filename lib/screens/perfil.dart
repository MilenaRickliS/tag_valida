// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart'; 
import '../widgets/menu.dart';
import '../models/user.dart';

class PerfilScreen extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onLogout;

  const PerfilScreen({
    super.key,
    this.onEdit,
    this.onLogout,
  });

  static const _bg = Color(0xFFFDF7ED);
  static const card = Colors.white;
  static const text = Color(0xFF2B2B2B);
  static const muted = Color(0xFF6B6B6B);
  static const brand = Color(0xFFED7227);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        toolbarHeight: compact ? 160 : 100,
        centerTitle: true,
        title: compact
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo5.png', height: 78),
                  const SizedBox(height: 10),
                  const TopMenu(),
                ],
              )
            : Row(
                children: [
                  Image.asset('assets/logo5.png', height: 92),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ação editar: conecte na sua tela de edição.")),
    );
  }

  void _defaultLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
            const Expanded(
              child: Text(
                "Sair",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: const Text("Deseja sair da sua conta agora?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(context);
             

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logout: conecte no seu AuthProvider.")),
              );
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

  static const _card = Colors.white;
  static const _text = Color(0xFF2B2B2B);
  static const _muted = Color(0xFF6B6B6B);
  static const _brand = Color(0xFFED7227);

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar();

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.06)),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _text,
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
                        color: _muted.withOpacity(0.95),
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

  Widget _buildAvatar() {
  
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
          colors: [
            _brand.withOpacity(0.95),
            _brand.withOpacity(0.35),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 2),
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

  static const _text = Color(0xFF2B2B2B);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: onEdit,
          style: OutlinedButton.styleFrom(
            foregroundColor: _text,
            side: BorderSide(color: Colors.black.withOpacity(0.12), width: 1.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text(
            "Editar",
            style: TextStyle(fontWeight: FontWeight.w900),
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
          icon: const Icon(Icons.logout_rounded, size: 18),
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

  static const _card = Colors.white;
  static const _text = Color(0xFF2B2B2B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.05),
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
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _text, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Divider(height: 14, color: Colors.black.withOpacity(0.06)),
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

  static const _text = Color(0xFF2B2B2B);
  static const _muted = Color(0xFF6B6B6B);

  @override
  Widget build(BuildContext context) {
    final v = value.trim().isEmpty ? "-" : value.trim();

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
                color: _muted.withOpacity(0.95),
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                color: _text,
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

  static const _text = Color(0xFF2B2B2B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _text),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: _text,
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

  static const _textColor = Color(0xFF2B2B2B);

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
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.06),
      ),
      child: Center(
        child: Text(
          _initials(text),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: _textColor,
          ),
        ),
      ),
    );
  }
}

