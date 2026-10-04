import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class PaymentScreen extends StatelessWidget {
  final bool hasCardSaved;
  final VoidCallback onCardAdded;

  const PaymentScreen({super.key, required this.hasCardSaved, required this.onCardAdded});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Payment Methods", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // DYNAMIC CARD DISPLAY
            if (hasCardSaved) 
              _buildSavedCard("**** **** **** 4091") // Example last 4 digits
            else 
              _buildEmptyState(context),

            const SizedBox(height: 30),
            const Text("Promotions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildPromoAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedCard(String number) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card, color: Colors.orange),
          const SizedBox(width: 15),
          Text(number, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const Spacer(),
          const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  // Add 'BuildContext context' inside the parentheses
Widget _buildEmptyState(BuildContext context) { 
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("No payment methods added yet.", style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 10),
      ElevatedButton.icon(
        onPressed: () => _showAddCardSheet(context),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("Add Card", style: TextStyle(color: Colors.black)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[700]),
      ),
    ],
  );
}

void _showAddCardSheet(BuildContext context) {
  final cardController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24, right: 24, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 20),
          const Text("Add Payment Method", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text("Card Number", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          TextField(
  controller: cardController,
  keyboardType: TextInputType.number,
  maxLength: 19,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    CardNumberInputFormatter(),
  ],
  decoration: const InputDecoration(
    hintText: "0000 0000 0000 0000",
    counterText: "",
    prefixIcon: Icon(Icons.credit_card, color: Colors.orange),
    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
  ),
),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Expiry", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    TextField(
  controller: expiryController,
  keyboardType: TextInputType.number,
  maxLength: 5,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    ExpiryDateInputFormatter(),
  ],
  decoration: const InputDecoration(
    hintText: "MM/YY",
    counterText: "",
    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
  ),
),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CVV", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    TextField(
  controller: cvvController,
  keyboardType: TextInputType.number,
  maxLength: 3,
  obscureText: true,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(3),
  ],
  decoration: const InputDecoration(
    hintText: "123",
    counterText: "",
    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
  ),
),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3134),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final cardNumber = cardController.text.replaceAll(' ', '');
                if (cardNumber.length < 16) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a valid card number")),
                  );
                  return;
                }
                final last4 = cardNumber.substring(cardNumber.length - 4);
                onCardAdded();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Card ending in $last4 added successfully!"), backgroundColor: Colors.green),
                );
              },
              child: const Text("Save Card", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPromoAction() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.local_offer, color: Colors.green),
      title: const Text("Add Promo Code"),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () { /* Future Promo Logic */ },
    );
  }
}
  class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(' ', '');
    if (digits.length > 16) digits = digits.substring(0, 16);
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 4 == 0 && i + 1 != digits.length) buffer.write(' ');
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.toString().length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll('/', '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      formatted += digits[i];
      if (i == 1 && digits.length > 2) formatted += '/';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

