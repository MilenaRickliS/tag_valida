// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../widgets/menu.dart';

class AjudaScreen extends StatelessWidget {
  const AjudaScreen({super.key});

  static const _bg = Color(0xFFFDF7ED);
  static const _text = Color(0xFF2B2B2B);
  static const _muted = Color(0xFF6B6B6B);
  static const _card = Colors.white;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 835;

    final faqs = <_FaqItem>[
      _FaqItem(
        question: "Como faço para criar uma nova etiqueta?",
        answer:
            "Vá em **Criar Etiqueta**, selecione o **Tipo**, **Setor** e **Categoria** (se houver), preencha os campos (ex: produto, lote, datas) e toque em **Salvar**. Depois você pode **visualizar** e **imprimir**.",
      ),
      _FaqItem(
        question: "Para que servem as etiquetas diárias?",
        answer:
            "As **etiquetas diárias** ajudam a padronizar e acelerar a rotina: você salva modelos prontos para itens que você faz todo dia e gera várias etiquetas rapidamente, evitando digitar tudo sempre.",
      ),
      _FaqItem(
        question: "Como adicionar as etiquetas no meu estoque?",
        answer:
            "Ao **Salvar** uma etiqueta, ela pode ser registrada no seu controle. Depois, use a tela de **Estoque** para filtrar por **Setor/Categoria** e acompanhar **quantidade**, **alertas** e **vencimentos**.",
      ),
      _FaqItem(
        question: "Como excluir as etiquetas do meu estoque?",
        answer:
            "Abra a etiqueta no **Estoque** e escolha **Excluir** (ou Remover do estoque). Se você quiser manter o histórico, pode usar **Baixa/Movimentação** em vez de excluir.",
      ),
      _FaqItem(
        question: "Como reimprimir etiquetas?",
        answer:
            "Abra a etiqueta, toque em **Visualizar** e depois em **Imprimir/Reimprimir**. Se existir QR Code, ele será gerado novamente automaticamente com os mesmos dados.",
      ),
      _FaqItem(
        question: "Como atualizar a data de um grupo de etiquetas?",
        answer:
            "Use a opção de **Edição em lote** (quando disponível): selecione várias etiquetas e escolha **Atualizar validade/fabricação**. Se ainda não tiver essa função, posso te montar esse fluxo com seleção múltipla.",
      ),
    ];

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
        child: LayoutBuilder(
          builder: (context, c) {
            final maxW = c.maxWidth;

          
            int crossAxisCount = 3;
            if (maxW < 980) crossAxisCount = 2;
            if (maxW < 560) crossAxisCount = 1;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 16 : 28,
                vertical: 18,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                   
                      Center(
                        child: Column(
                          children: const [
                            Text(
                              "Precisa de ajuda?",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: _text,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Principais dúvidas com relação ao app",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      GridView.builder(
                        itemCount: faqs.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: crossAxisCount == 1 ? 3.4 : 2.9,
                        ),
                        itemBuilder: (context, i) {
                          final item = faqs[i];
                          return _HelpCard(
                            title: item.question,
                            onTap: () => _openAnswer(context, item),
                          );
                        },
                      ),

                      const SizedBox(height: 22),

                    
                      const Text(
                        "Contato Suporte",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 14,
                        runSpacing: 10,
                        children: const [
                          _ContactPill(
                            icon: Icons.phone_rounded,
                            text: "(42) 99999-0000",
                          ),
                          _ContactPill(
                            icon: Icons.email_rounded,
                            text: "suporte@gmail.com",
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                    
                      const Text(
                        "Tutoriais e Documentação",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 10),


                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openAnswer(BuildContext context, _FaqItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF428E2E).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.question,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _text,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.answer,
                  style: const TextStyle(
                    fontSize: 14.2,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF428E2E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Entendi",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HelpCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _HelpCard({
    required this.title,
    required this.onTap,
  });

  static const _text = Color(0xFF2B2B2B);
  static const _bg = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, 6),
                color: Colors.black.withOpacity(0.06),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.4,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactPill({
    required this.icon,
    required this.text,
  });

  static const _textColor = Color(0xFF2B2B2B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.2,
              fontWeight: FontWeight.w800,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}