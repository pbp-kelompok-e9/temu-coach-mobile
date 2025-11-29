import 'package:flutter/material.dart';
import '../models/coach_model.dart';
import '../theme/app_theme.dart';

class CoachCard extends StatelessWidget {
  final Coach coach;
  final VoidCallback? onTap;

  const CoachCard({super.key, required this.coach, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: coach.foto != null && coach.foto!.isNotEmpty
                    ? Image.network(
                        coach.foto!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, st) => Container(
                          width: 72,
                          height: 72,
                          color: AppColors.gray100,
                          child: const Icon(Icons.person, size: 36),
                        ),
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        color: AppColors.gray100,
                        child: const Icon(Icons.person, size: 36),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coach.citizenship,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      coach.prefferedFormation,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatRupiah(coach.ratePerSession),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text('${coach.averageTermAsCoach} yrs', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatRupiah(double value) {
    // simple formatting: no decimals, thousand separator '.'
    final intVal = value.round();
    final s = intVal.toString();
    final buffer = StringBuffer();
    int len = s.length;
    for (int i = 0; i < len; i++) {
      buffer.write(s[i]);
      final pos = len - i - 1;
      if (pos % 3 == 0 && i != len - 1) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }
  
}
