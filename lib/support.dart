import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            const Text("How can we help?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // 1. FAQ Section
            const Text("Frequently Asked Questions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 10),
            _buildFAQTile("How do I start a ride?", "Find a scooter on the map, tap it, and scan the QR code located on the handlebars."),
            _buildFAQTile("Where can I park?", "Please park in designated Mchina zones or near AUI residential buildings, ensuring you don't block paths."),
            _buildFAQTile("Payment Issues", "If your card is declined, ensure you have sufficient funds or try re-adding the card in the Payment tab."),
            
            const SizedBox(height: 30),
            
            // 2. Report Issue Section
            const Text("Report a Problem", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildSupportAction(
              Icons.report_problem_outlined, 
              "Report Scooter Issue", 
              "Damaged scooter, flat tire, or low battery.",
              () => _showReportDialog(context)
            ),
            _buildSupportAction(
              Icons.history, 
              "Trip Discrepancy", 
              "Issues with a past ride or pricing.",
              () {} 
            ),

            const SizedBox(height: 30),

            // 3. Contact Section
            const Center(
              child: Column(
                children: [
                  Text("Still need help?", style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 5),
                  Text("support@mchina.aui.ma", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(answer, style: const TextStyle(color: Colors.black54)),
        ),
      ],
    );
  }

  Widget _buildSupportAction(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[100],
        child: Icon(icon, color: Colors.black),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report Issue"),
        content: const Text("Thank you for your report. Our technicians have been notified and will check this scooter shortly."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }
}