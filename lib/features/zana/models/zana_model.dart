import 'package:flutter/material.dart';

enum ZanaStatus { live, comingSoon, beta }

class ZanaTool {
  final String id;
  final String name;
  final String fullName;
  final String nameSwahili;
  final String description;
  final String descriptionSwahili;
  final ZanaStatus status;
  final List<Color> gradient;
  final IconData icon;
  final String route;

  const ZanaTool({
    required this.id,
    required this.name,
    required this.fullName,
    required this.nameSwahili,
    required this.description,
    required this.descriptionSwahili,
    required this.status,
    required this.gradient,
    required this.icon,
    required this.route,
  });
}

class ZanaData {
  static const List<ZanaTool> tools = [
    ZanaTool(
      id: 'pos',
      name: 'POS',
      fullName: 'Point of Sale',
      nameSwahili: 'Mfumo wa Mauzo',
      description: 'Manage your business sales and accounting easily.',
      descriptionSwahili:
          'Simamia mauzo na hesabu za biashara yako kwa urahisi.',
      status: ZanaStatus.live,
      gradient: [Color(0xFF1A2E5A), Color(0xFF2D4A8A)],
      icon: Icons.point_of_sale_outlined,
      route: '/zana/pos',
    ),
    ZanaTool(
      id: 'biz-manager',
      name: 'Business Manager',
      fullName: 'Business Manager',
      nameSwahili: 'Msimamizi wa Biashara',
      description: 'Tools to manage your business operations.',
      descriptionSwahili: 'Zana za kusimamia operesheni za biashara yako.',
      status: ZanaStatus.live,
      gradient: [Color(0xFF2E5A1A), Color(0xFF3A8A2D)],
      icon: Icons.business_center_outlined,
      route: '/zana/biz-manager',
    ),
    ZanaTool(
      id: 'insurance',
      name: 'Insurance',
      fullName: 'Business Insurance',
      nameSwahili: 'Bima ya Biashara',
      description: 'Insurance tailored for small Tanzanian entrepreneurs.',
      descriptionSwahili:
          'Bima zilizoundwa kwa wajasiriamali wadogo Tanzania.',
      status: ZanaStatus.live,
      gradient: [Color(0xFF5A1A1A), Color(0xFF8A2D2D)],
      icon: Icons.security_outlined,
      route: '/zana/insurance',
    ),
    ZanaTool(
      id: 'vicoba',
      name: 'e-VICOBA',
      fullName: 'Digital Group Savings',
      nameSwahili: 'Akiba ya Kikundi',
      description: 'Community savings groups (VICOBA) digitized.',
      descriptionSwahili:
          'Vikundi vya Kuweka na Kukopa kwa njia ya kidijitali.',
      status: ZanaStatus.comingSoon,
      gradient: [Color(0xFFE65100), Color(0xFFFF8F00)],
      icon: Icons.savings_outlined,
      route: '/zana/vicoba',
    ),
  ];
}
