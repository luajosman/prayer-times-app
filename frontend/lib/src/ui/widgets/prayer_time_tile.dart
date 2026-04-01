import 'package:flutter/material.dart';

class PrayerTimeTile extends StatelessWidget {
  const PrayerTimeTile({
    super.key,
    required this.title,
    required this.time,
    required this.isNext,
  });

  final String title;
  final String time;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNext
              ? const Color(0xFFFFD166).withOpacity(0.85)
              : Colors.white.withOpacity(0.1),
        ),
        color: isNext
            ? const Color(0xFFFFD166).withOpacity(0.18)
            : Colors.white.withOpacity(0.05),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            offset: const Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isNext
                  ? const Color(0xFFFFD166).withOpacity(0.95)
                  : Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              isNext ? Icons.schedule_rounded : Icons.mosque_rounded,
              color: isNext ? const Color(0xFF2E3A52) : Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: isNext ? const Color(0xFFFFD166) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
