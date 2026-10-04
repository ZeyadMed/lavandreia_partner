import 'package:flutter/material.dart';

/// نوع مركبة الدليفري، نفس VehicleType في أبلكيشن الدليفري
/// [speedKmh] متوسط سرعته جوه المدينة، عشان نحسب الوقت المتوقع لوصوله
enum VehicleKind {
  car(
    apiName: 'Car',
    labelKey: 'vehicle_car',
    icon: Icons.directions_car_rounded,
    speedKmh: 25,
  ),
  motorcycle(
    apiName: 'Motorcycle',
    labelKey: 'vehicle_motorcycle',
    icon: Icons.two_wheeler_rounded,
    speedKmh: 30,
  ),
  scooter(
    apiName: 'Scooter',
    labelKey: 'vehicle_scooter',
    icon: Icons.electric_scooter_rounded,
    speedKmh: 30,
  ),
  van(
    apiName: 'Van',
    labelKey: 'vehicle_van',
    icon: Icons.airport_shuttle_rounded,
    speedKmh: 22,
  ),

  /// نوع مش معروف، بيتعرض باسمه زي ما جه من السيرفر
  other(
    apiName: '',
    labelKey: '',
    icon: Icons.delivery_dining_rounded,
    speedKmh: 25,
  );

  final String apiName;
  final String labelKey;
  final IconData icon;
  final double speedKmh;

  const VehicleKind({
    required this.apiName,
    required this.labelKey,
    required this.icon,
    required this.speedKmh,
  });

  /// أبلكيشن الدليفري بيبعت "car" في التسجيل و "Car" في تعديل البروفايل
  static VehicleKind fromApi(String value) {
    final name = value.trim().toLowerCase();
    for (final kind in values) {
      if (kind != other && kind.apiName.toLowerCase() == name) return kind;
    }
    return other;
  }
}
