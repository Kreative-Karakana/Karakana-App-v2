import 'package:flutter/material.dart';

class MobileMoneyProviderOption {
  final String id;
  final String name;
  final Color color;
  final String logoAsset;

  const MobileMoneyProviderOption({
    required this.id,
    required this.name,
    required this.color,
    required this.logoAsset,
  });
}

class MobileMoney {
  static const providers = [
    MobileMoneyProviderOption(
      id: 'mpesa',
      name: 'Vodacom',
      color: Color(0xFFE87722),
      logoAsset: 'mno_logos/mpesa.png',
    ),
    MobileMoneyProviderOption(
      id: 'tigo',
      name: 'Mix by Yas',
      color: Color(0xFF3D1800),
      logoAsset: 'mno_logos/mix_by_yas.png',
    ),
    MobileMoneyProviderOption(
      id: 'airtel',
      name: 'Airtel',
      color: Color(0xFF3D1800),
      logoAsset: 'mno_logos/airtel.png',
    ),
    MobileMoneyProviderOption(
      id: 'halopesa',
      name: 'HaloPesa',
      color: Color(0xFF3D1800),
      logoAsset: 'mno_logos/halopesa.png',
    ),
  ];

  static String normalizePhone(String raw) {
    final phone = raw.trim().replaceAll(' ', '').replaceAll('-', '');
    if (phone.startsWith('255')) return phone;
    if (phone.startsWith('0')) return '255${phone.substring(1)}';
    return '255$phone';
  }

  static bool isValidTanzaniaPhone(String raw) {
    final phone = normalizePhone(raw);
    return RegExp(r'^255\d{9}$').hasMatch(phone);
  }
}
