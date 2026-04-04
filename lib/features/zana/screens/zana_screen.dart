import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/zana_model.dart';

class ZanaScreen extends StatelessWidget {
  const ZanaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tools = ZanaData.tools;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text(
              'Zana',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chagua zana za kukuza biashara yako, kuendesha mauzo, na kujiandaa kwa huduma mpya zinazokuja.',
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ...tools.map(
              (tool) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ZanaToolCard(tool: tool),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZanaToolCard extends StatelessWidget {
  final ZanaTool tool;

  const _ZanaToolCard({
    required this.tool,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = tool.status == ZanaStatus.live;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => context.push(tool.route),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tool.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: tool.gradient.last.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        tool.icon,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    _StatusChip(status: tool.status),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  tool.name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tool.nameSwahili,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tool.descriptionSwahili,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      isLive ? 'Open tool' : 'Preview',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
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
}

class _StatusChip extends StatelessWidget {
  final ZanaStatus status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ZanaStatus.live => 'Live',
      ZanaStatus.comingSoon => 'Coming Soon',
      ZanaStatus.beta => 'Beta',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
