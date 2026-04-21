import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../courses/screens/explore_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../zana/screens/zana_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Pill geometry constants
  static const double _pillHeight = 64.0;
  static const double _fabSize = 60.0;
  // Total height above safe area:
  // - 4px top margin for FAB to extend above pill
  // - 30px (half FAB)  → FAB top at y=4, center at y=34
  // - pill top = 104 - 8 - 64 = 32  → FAB center is 2px into pill ≈ "sitting on pill edge"
  // - 8px bottom margin between pill and safe area
  static const double _navTotalHeight = 104.0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    ZanaScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildFloatingNavBar(context),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: _navTotalHeight,
        child: Stack(
          children: [
            // ── Notched pill ──────────────────────────────────────────────
            Positioned(
              bottom: 8,
              left: 16,
              right: 16,
              height: _pillHeight,
              child: CustomPaint(
                painter: _NotchedPillPainter(color: AppColors.primaryDark),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildNavTab(
                        index: 0,
                        label: 'Nyumbani',
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildNavTab(
                        index: 1,
                        label: 'Tafuta',
                        icon: Icons.explore_outlined,
                        activeIcon: Icons.explore_rounded,
                      ),
                    ),
                    // Gap for Zana FAB
                    const SizedBox(width: _fabSize + 8),
                    Expanded(
                      child: _buildNavTab(
                        index: 3,
                        label: 'Akaunti',
                        icon: Icons.person_outlined,
                        activeIcon: Icons.person_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Raised Zana FAB ───────────────────────────────────────────
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: Center(child: _buildZanaFab()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.45),
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZanaFab() {
    final isActive = _currentIndex == 2;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _fabSize,
        height: _fabSize,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.ctaGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isActive ? 0.55 : 0.30),
              blurRadius: isActive ? 18 : 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          isActive ? Icons.construction_rounded : Icons.construction_outlined,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

// ── Notched pill painter ─────────────────────────────────────────────────────

class _NotchedPillPainter extends CustomPainter {
  final Color color;

  _NotchedPillPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // FAB center sits ~2px below the pill's top edge (see layout constants).
    // Notch radius = FAB_radius(30) + 2px visual gap = 32.
    const notchRadius = 32.0;
    const notchOffsetY = 2.0;
    final cornerRadius = size.height / 2;

    final pillPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(cornerRadius),
      ));

    final notchPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, notchOffsetY),
        radius: notchRadius,
      ));

    final finalPath =
        Path.combine(PathOperation.difference, pillPath, notchPath);

    // Elevation shadow
    canvas.drawShadow(finalPath, Colors.black, 8, false);

    // Pill fill
    canvas.drawPath(finalPath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _NotchedPillPainter old) =>
      old.color != color;
}
