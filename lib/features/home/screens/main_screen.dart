import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../courses/screens/explore_screen.dart';
import '../../fursa/screens/fursa_screen.dart';
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

  // MUST match navbar order exactly:
  // 0=Nyumbani  1=Tafuta  2=Zana  3=Fursa  4=Akaunti
  final List<Widget> _screens = const [
    HomeScreen(),    // 0
    ExploreScreen(), // 1
    ZanaScreen(),    // 2
    FursaScreen(),   // 3
    ProfileScreen(), // 4
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 90;
    return Scaffold(
      extendBody: true,
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: MediaQuery.of(context).padding.copyWith(
            bottom: bottomPadding,
          ),
        ),
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Glassmorphism bar
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildNavTab(index: 0, icon: Icons.home_outlined),
                        ),
                        Expanded(
                          child: _buildNavTab(index: 1, icon: Icons.explore_outlined),
                        ),
                        // Placeholder space for raised Zana FAB
                        const SizedBox(width: 72),
                        Expanded(
                          child: _buildNavTab(index: 3, icon: Icons.lightbulb_outline),
                        ),
                        Expanded(
                          child: _buildNavTab(index: 4, icon: Icons.person_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Raised Zana FAB — outside ClipRRect so it is never clipped
              Positioned(
                top: -18,
                child: _buildZanaButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZanaButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = 2);
      },
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE87722),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE87722).withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.construction, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab({required int index, required IconData icon}) {
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
              icon,
              color: isSelected
                  ? const Color(0xFFE87722)
                  : Colors.white.withValues(alpha: 0.75),
              size: 24,
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: isSelected ? 6 : 0,
              height: isSelected ? 6 : 0,
              decoration: const BoxDecoration(
                color: Color(0xFFE87722),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
