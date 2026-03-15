// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class HomeMenuCardV2 extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const HomeMenuCardV2({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark
        ? const Color(0xFF1E1E1E).withOpacity(0.96)
        : Colors.white.withOpacity(0.94);

    final innerIconBg = isDark
        ? const Color(0xFF2A2A2A)
        : Colors.white;

    final titleColor = isDark
        ? Colors.white
        : (theme.textTheme.bodyLarge?.color ?? Colors.black87);

    final subtitleColor = isDark
        ? const Color(0xFFD8D8D8)
        : Colors.black.withOpacity(0.62);

    final borderColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.18)
        : Colors.black.withOpacity(0.08);

    final chevronColor = isDark
        ? const Color(0xFFD4AF37).withOpacity(0.85)
        : Colors.black.withOpacity(0.35);

    final iconColor = isDark
        ? const Color(0xFFD4AF37)
        : Colors.black87;

    final shadow1 = Colors.black.withOpacity(isDark ? 0.22 : 0.06);
    final shadow2 = Colors.black.withOpacity(isDark ? 0.38 : 0.12);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: shadow1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: shadow2,
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: innerIconBg,
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          color: subtitleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 26,
                    color: chevronColor,
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