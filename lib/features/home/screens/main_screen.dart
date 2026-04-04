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

  List<_NavItem> get _navItems => const [
        _NavItem(
          label: 'Nyumbani',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          index: 0,
        ),
        _NavItem(
          label: 'Tafuta',
          icon: Icons.explore_outlined,
          activeIcon: Icons.explore_rounded,
          index: 1,
        ),
        _NavItem(
          label: 'Zana',
          icon: Icons.construction_outlined,
          activeIcon: Icons.construction_rounded,
          index: 2,
        ),
        _NavItem(
          label: 'Akaunti',
          icon: Icons.person_outlined,
          activeIcon: Icons.person_rounded,
          index: 3,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navItems
                  .map((item) => _buildNavItem(item))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item) {
    final isSelected = _currentIndex == item.index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = item.index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 32,
            decoration: BoxDecoration(
              color:
                  isSelected ? AppColors.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSelected ? item.activeIcon : item.icon,
              color:
                  isSelected ? AppColors.primary : AppColors.textHint,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color:
                  isSelected ? AppColors.primary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int index;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.index,
  });
}
