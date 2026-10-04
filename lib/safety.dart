import 'package:flutter/material.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Safety Guide", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Riding Rules at AUI", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Follow these guidelines to ensure a safe experience for everyone on campus.", 
              style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 25),
            
            _buildSafetyCard(
              Icons.health_and_safety, 
              "Wear a Helmet", 
              "Protect yourself. We strongly recommend wearing a helmet during every ride.",
              Colors.orange
            ),
            _buildSafetyCard(
              Icons.person_off_rounded, 
              "No Passengers", 
              "Mchina scooters are strictly for one rider only. Double riding is dangerous.",
              Colors.blue
            ),
            _buildSafetyCard(
              Icons.no_drinks, 
              "Ride Sober", 
              "Never ride under the influence of alcohol or medication that causes drowsiness.",
              Colors.red
            ),
            _buildSafetyCard(
              Icons.speed_rounded, 
              "Respect Speed Limits", 
              "Stay below 20km/h and be extra cautious near pedestrian crossings.",
              Colors.green
            ),
            
            const SizedBox(height: 40),
            
            // Emergency Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Column(
                children: [
                  const Text("Emergency Assistance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                  const SizedBox(height: 10),
                  const Text("In case of an accident or security concern on campus:", textAlign: TextAlign.center),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Simulated call to AUI Security
                      },
                      icon: const Icon(Icons.phone, color: Colors.white),
                      label: const Text("CALL CAMPUS SECURITY"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard(IconData icon, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.black54, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}