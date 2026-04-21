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

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    ZanaScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body extends behind the floating pill — Flutter auto-adjusts
      // MediaQuery.padding.bottom for all child screens so content
      // knows how much to inset from the bottom.
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
      floatingActionButton: _buildZanaFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ── Floating pill ────────────────────────────────────────────────────────────

  Widget _buildFloatingNavBar() {
    return Container(
      // Outer container is fully transparent — only the inner pill has color.
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E), // solid dark pill — no blur/transparency
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
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
              // Center gap for the Zana FAB (56px FAB + breathing room)
              const SizedBox(width: 72),
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
    );
  }

  // ── Tab item ─────────────────────────────────────────────────────────────────

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

  // ── Zana FAB ─────────────────────────────────────────────────────────────────

  Widget _buildZanaFab() {
    final isActive = _currentIndex == 2;
    return FloatingActionButton(
      backgroundColor: AppColors.primary,
      elevation: 6,
      onPressed: () => setState(() => _currentIndex = 2),
      child: Icon(
        isActive ? Icons.construction_rounded : Icons.construction_outlined,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
