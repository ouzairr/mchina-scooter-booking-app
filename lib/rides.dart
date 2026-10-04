import 'package:flutter/material.dart';

// 1. The Data Model (Great for your documentation!)
class Ride {
  final String date;
  final String time;
  final String duration;
  final double cost;
  final String distance;

  Ride({
    required this.date,
    required this.time,
    required this.duration,
    required this.cost,
    required this.distance,
  });
}

class RideHistoryScreen extends StatelessWidget {
  // Mock data for your presentation
  final List<Ride> rides = [
    Ride(date: "Mar 14, 2026", time: "14:20", duration: "12 min", cost: 12.00, distance: "2.4 km"),
    Ride(date: "Mar 12, 2026", time: "09:15", duration: "8 min", cost: 8.00, distance: "1.1 km"),
    Ride(date: "Mar 10, 2026", time: "18:45", duration: "25 min", cost: 25.00, distance: "5.2 km"),
  ];

  RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("My Rides", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rides.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildRideCard(rides[index]);
        },
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Map Thumbnail Placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.map_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          // Ride Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${ride.date} • ${ride.time}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text("${ride.duration} • ${ride.distance}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          // Cost
          Text(
            "${ride.cost.toStringAsFixed(2)} DH",
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2D3134)),
          ),
        ],
      ),
    );
  }
}