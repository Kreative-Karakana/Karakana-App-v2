import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  // ── Floating pill ────────────────────────────────────────────────────────────

  Widget _buildFloatingNavBar() {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
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
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                ),
              ),
              Expanded(
                child: _buildNavTab(
                  index: 1,
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                ),
              ),
              Expanded(
                child: _buildNavTab(
                  index: 2,
                  icon: Icons.construction_outlined,
                  activeIcon: Icons.construction_rounded,
                ),
              ),
              Expanded(
                child: _buildNavTab(
                  index: 3,
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
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : Colors.grey[500],
              size: 24,
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 6 : 0,
              height: isSelected ? 6 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
