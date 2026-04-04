import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Akaunti - Coming Soon'),
      ),
    );
  }
}
