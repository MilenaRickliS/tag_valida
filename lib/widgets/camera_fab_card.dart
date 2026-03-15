// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class CameraFabCard extends StatefulWidget {
  final VoidCallback onTap;
  final double? width;
  final double height;

  const CameraFabCard({
    super.key,
    required this.onTap,
    this.width,
    this.height = 96,
  });

  @override
  State<CameraFabCard> createState() => _CameraFabCardState();
}

class _CameraFabCardState extends State<CameraFabCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scale = _pressed ? 0.98 : (_hovered ? 1.02 : 1.0);
    final translateY = _hovered ? -3.0 : 0.0;

    final cardColor = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    final borderColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.28)
        : const Color(0xFF40916C).withOpacity(0.22);

    final titleColor = isDark
        ? Colors.white
        : Colors.black87;

    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.72)
        : Colors.black54;

    final chevronColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.85)
        : Colors.black54;

    final iconGradient = isDark
        ? const [
            Color(0xFFF2D57E),
            Color(0xFFD4AF37),
            Color(0xFFB8922E),
          ]
        : const [
            Color(0xFF74C69D),
            Color(0xFF40916C),
          ];

    final shadow1 = Colors.black.withOpacity(isDark ? 0.22 : 0.06);
    final shadow2 = Colors.black.withOpacity(isDark ? 0.38 : 0.12);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..translate(0.0, translateY)
            ..scale(scale),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: shadow1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: shadow2,
                  blurRadius: _hovered ? 36 : 30,
                  offset: Offset(0, _hovered ? 18 : 15),
                ),
              ],
            ),
            child: Material(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: borderColor,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: iconGradient,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? const Color(0xFFD4AF37).withOpacity(0.22)
                                  : const Color(0xFF40916C).withOpacity(0.20),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Checar validade",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Use a câmera para analisar o produto",
                              style: TextStyle(
                                fontSize: 12.5,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 28,
                        color: chevronColor,
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