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
  final IconData icon;
  final String route;
  final bool isRecommended;

  const ZanaTool({
    required this.id,
    required this.name,
    required this.fullName,
    required this.nameSwahili,
    required this.description,
    required this.descriptionSwahili,
    required this.status,
    required this.icon,
    required this.route,
    this.isRecommended = false,
  });
}

class ZanaData {
  static const List<ZanaTool> tools = [
    ZanaTool(
      id: 'biz-manager',
      name: 'Business Manager',
      fullName: 'Usimamizi wa Biashara',
      nameSwahili: 'Usimamizi wa Biashara',
      description: 'Manage your business operations and sales easily.',
      descriptionSwahili:
          'Simamia operesheni na mauzo ya biashara yako kwa urahisi.',
      status: ZanaStatus.live,
      icon: Icons.business_center_outlined,
      route: '/zana/biz-manager',
      isRecommended: true,
    ),
    ZanaTool(
      id: 'kikoba',
      name: 'e-KIKOBA',
      fullName: 'Digital Group Savings',
      nameSwahili: 'Akiba ya Kikundi',
      description: 'Community savings groups (KIKOBA) digitized.',
      descriptionSwahili:
          'Vikundi vya Kuweka na Kukopa kwa njia ya kidijitali.',
      status: ZanaStatus.comingSoon,
      icon: Icons.account_balance_outlined,
      route: '/zana/kikoba',
    ),
    ZanaTool(
      id: 'ebooks',
      name: 'eBooks',
      fullName: 'Digital Library',
      nameSwahili: 'Maktaba ya Kidijitali',
      description: 'Business and entrepreneurship eBooks.',
      descriptionSwahili: 'Vitabu vya biashara na ujasiriamali.',
      status: ZanaStatus.live,
      icon: Icons.menu_book_outlined,
      route: '/zana/ebooks',
    ),
    ZanaTool(
      id: 'insurance',
      name: 'Insurance',
      fullName: 'Business Insurance',
      nameSwahili: 'Bima ya Biashara',
      description: 'Insurance tailored for small Tanzanian entrepreneurs.',
      descriptionSwahili: 'Bima zilizoundwa kwa wajasiriamali wadogo Tanzania.',
      status: ZanaStatus.comingSoon,
      icon: Icons.security_outlined,
      route: '/zana/insurance',
    ),
  ];
}
