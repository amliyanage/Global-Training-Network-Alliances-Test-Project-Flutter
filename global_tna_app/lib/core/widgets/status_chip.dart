import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color foreground;
  final IconData icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.foreground,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: foreground.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}
