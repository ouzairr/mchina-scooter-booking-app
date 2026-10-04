import 'package:google_maps_flutter/google_maps_flutter.dart';

class Scooter {
  final String id;
  final LatLng position;
  final int batteryLevel;
  final String status; // 'available', 'maintenance', 'reserved'
  final double pricePerMin;

  Scooter({
    required this.id,
    required this.position,
    required this.batteryLevel,
    required this.status,
    this.pricePerMin = 1.0,
  });

  // This factory constructor will be a lifesaver when you connect your backend.
  // It converts a JSON Map (from your API) into a Scooter object.
  factory Scooter.fromJson(Map<String, dynamic> json) {
    return Scooter(
      id: json['id'],
      position: LatLng(json['lat'], json['lng']),
      batteryLevel: json['battery'],
      status: json['status'],
      pricePerMin: json['price']?.toDouble() ?? 1.0,
    );
  }
}