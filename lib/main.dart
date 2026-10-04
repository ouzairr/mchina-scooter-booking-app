import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:async'; 
import 'package:geolocator/geolocator.dart'; 
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'payment.dart';
import 'safety.dart';
import 'support.dart';
import 'api_service.dart';
import 'profile_setup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


void main() {
  runApp(const MchinaApp());
}

class MchinaApp extends StatelessWidget {
  const MchinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mchina',
      theme: ThemeData(primarySwatch: Colors.yellow),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool hasSavedPaymentMethod = false;
  GoogleMapController? _mapController;
  BitmapDescriptor? customIcon;
  String _timerText = "00:00"; // Class-level variable
  String _userName = '';
  int _secondsElapsed = 0; 
  final bool _isLoggedIn = false;     // To help calculate distance
  bool isLoading = true;
  bool showWelcome = false; // Controls the Welcome Slider
  int _currentPage = 0;      // Tracks which slide we are on
  final PageController _pageController = PageController();
  Timer? _rideTimer;
  double _currentCost = 0.0;
  bool hasPaymentMethod = false;
  bool isRiding = false;      // Make sure you have this too
  String currentScooter = "";
  LatLng? _userPosition;
  BitmapDescriptor? _customIcon;
Set<Marker> _markers = {
  Marker(
    markerId: const MarkerId('scooter1'),
    position: const LatLng(33.5273, -5.1067), // Near the Lion Statue
    infoWindow: const InfoWindow(title: 'Mchina #001', snippet: '🔋 92% • 1.00 DH/min'),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
  ),
  Marker(
    markerId: const MarkerId('scooter2'),
    position: const LatLng(33.5250, -5.1040), // Near the Market
    infoWindow: const InfoWindow(title: 'Mchina #002', snippet: '🪫 8% • MAINTENANCE REQUIRED'),
    // Changing this to RED to indicate an issue
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),

  ),
};
Future<void> _loadUserName() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _userName = prefs.getString('user_name') ?? '';
  });
}
void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text("Scan Scooter QR"),
            actions: [
              // Test shortcut to start a ride without a QR code (debug builds only)
              if (kDebugMode)
              IconButton(
              icon: const Icon(Icons.bug_report), 
              onPressed: () {
                Navigator.pop(context); // Close the scanner
                _startRide("MCHINA_TEST_001"); // Manually trigger the ride!
              },
            )
            ],
          ),
          body: MobileScanner(
            onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String code = barcode.rawValue ?? "";
              
              // Only start if it's one of OUR scooters
              if (code.contains("SCOOTER")) { 
                Navigator.pop(context);
                _startRide(code);
              } else {
                // Tell the user it's the wrong QR code
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid Mchina QR Code!"))
                );
              }
            }
          },
          ),
        ),
      ),
    );
  }

  // The Bottom Sheet (The "UI")
  void _showBookingSheet(LatLng position, String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        // ... (Insert the Container code from the previous message here)
        // Use _getWalkingTime(position) inside the Text widget
      ),
    );
  }
  
  // Show a final receipt summary
void _showSignIn() {
  bool isPhoneValid = false;
  bool isSendingSms = false;
  String phoneNumber = '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Welcome back!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Enter your phone number to sign in.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 25),
              IntlPhoneField(
                initialCountryCode: 'MA',
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onChanged: (phone) {
                  setModalState(() {
                    isPhoneValid = phone.number.length == 9;
                    phoneNumber = phone.completeNumber;
                  });
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (isPhoneValid && !isSendingSms) ? () async {
                    setModalState(() => isSendingSms = true);
                    try {
                      final result = await ApiService.sendOTP(phoneNumber, isLogin: true);
                      if (result['error'] == 'account_not_found') {
                        setModalState(() => isSendingSms = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No account found. Please create one first.")),
                        );
                        return;
                      }
                      if (mounted) {
                        Navigator.pop(context);
                        _showOTPVerification(phoneNumber, result['dev_code']);
                      }
                    } catch (e) {
                      setModalState(() => isSendingSms = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPhoneValid ? Colors.yellow[700] : Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: isSendingSms
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text("SIGN IN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    ),
  );
}


  // 2. THIS IS THE START RIDE FUNCTION (Make sure it's outside!)
  void _startRide(String scooterID) {
  setState(() {
    isRiding = true;
    currentScooter = scooterID;
    _secondsElapsed = 0;
    _currentCost = 0.0;
  });

  _rideTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  setState(() {
    _secondsElapsed++;
    // Format the seconds into MM:SS
    int minutes = _secondsElapsed ~/ 60;
    int seconds = _secondsElapsed % 60;
    _timerText = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    
    // Update cost
    _currentCost = _secondsElapsed * (1.0 / 60); // 1 DH per minute
  });
});
}
void _stopRide() async {
  _rideTimer?.cancel();
  final int duration = _secondsElapsed;
  final double cost = _currentCost;
  final String scooter = currentScooter ?? 'Unknown';
  final String finalTimer = _timerText;

  setState(() {
    isRiding = false;
    currentScooter = "";
    _secondsElapsed = 0;
    _currentCost = 0.0;
    _timerText = "00:00";
  });

  // Save ride to backend and get ride ID
  String? rideId;
  try {
    final token = await ApiService.getToken();
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/rides'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'scooter_id': scooter,
        'duration_seconds': duration,
        'distance_km': 0.0,
        'cost': cost,
        'rating': null,
      }),
    );
    final data = jsonDecode(response.body);
    rideId = data['id'];
  } catch (e) {
    debugPrint('Error saving ride: $e');
  }

  // Show rating popup
  if (mounted) {
    _showRatingPopup(rideId, scooter, finalTimer, cost);
  }
}

void _showRatingPopup(String? rideId, String scooter, String duration, double cost) {
  int selectedRating = 0;

  showModalBottomSheet(
    context: context,
    isDismissible: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Icon(Icons.electric_scooter, size: 60, color: Colors.orange),
              const SizedBox(height: 12),
              const Text("How was your ride?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(scooter, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedRating = index + 1),
                    child: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.yellow[700],
                      size: 45,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                selectedRating == 0 ? "Tap to rate" :
                selectedRating == 1 ? "😞 Poor" :
                selectedRating == 2 ? "😐 Fair" :
                selectedRating == 3 ? "🙂 Good" :
                selectedRating == 4 ? "😊 Great" : "🤩 Excellent!",
                style: TextStyle(
                  color: selectedRating == 0 ? Colors.grey : Colors.yellow[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              // Ride summary mini
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(Icons.timer, duration, "Duration"),
                    _buildSummaryItem(Icons.attach_money, "${cost.toStringAsFixed(2)} DH", "Cost"),
                    _buildSummaryItem(Icons.electric_scooter, scooter.replaceAll('MCHINA_', ''), "Scooter"),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    // Save rating to backend
                    if (selectedRating > 0 && rideId != null) {
                      try {
                        final token = await ApiService.getToken();
                        await http.patch(
                          Uri.parse('${ApiService.baseUrl}/rides/$rideId/rating'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer $token',
                          },
                          body: jsonEncode({'rating': selectedRating}),
                        );
                      } catch (e) {
                        debugPrint('Error saving rating: $e');
                      }
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    selectedRating == 0 ? "SKIP" : "SUBMIT RATING",
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildSummaryItem(IconData icon, String value, String label) {
  return Column(
    children: [
      Icon(icon, color: Colors.orange, size: 22),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );
}
  
  @override
  void initState() {
    super.initState();
    _startIntro();
    _loadCustomIcon();
    _determinePosition();
    _loadUserName();
    _checkPaymentMethod();
    Future.delayed(const Duration(seconds: 3), () {
    if (mounted && _userPosition == null) {
      debugPrint("📍 GPS took too long, using default location (Ifrane)");
      setState(() {
        _userPosition = const LatLng(33.5273, -5.1067); // AUI Coordinates
      });
    }
  });
  }
  Future<void> _checkPaymentMethod() async {
  try {
    final token = await ApiService.getToken();
    if (token == null) return;
    final payment = await ApiService.getPayment();
    if (payment != null && mounted) {
      setState(() => hasPaymentMethod = true);
    }
  } catch (e) {
    debugPrint('Error checking payment: $e');
  }
}
  Future<void> _determinePosition() async {
  try {
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // 2. Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // 3. Get position WITHOUT blocking the UI (using a timeout)
    // We use a 5-second timeout so the app doesn't hang forever
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    ).timeout(const Duration(seconds: 5));

    if (mounted) {
      setState(() {
        _userPosition = LatLng(position.latitude, position.longitude);
      });
    }
  } catch (e) {
    // If it fails or times out, just print the error and move on
    debugPrint("📍 MCHINA GPS Error: $e");
  }
}
void _showPhoneLogin() {
  bool isPhoneValid = false;
  bool isSendingSms = false;
  String phoneNumber = '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("What's your number?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("We'll send a code to verify your account.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 25),
              AbsorbPointer(
                absorbing: isSendingSms,
                child: IntlPhoneField(
                  initialCountryCode: 'MA',
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onChanged: (phone) {
                    setModalState(() {
                      isPhoneValid = phone.number.length == 9;
                      phoneNumber = phone.completeNumber; // e.g. +212612345678
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (isPhoneValid && !isSendingSms) ? () async {
                    setModalState(() => isSendingSms = true);
                    try {
                      final result = await ApiService.sendOTP(phoneNumber, isLogin: false);
                      debugPrint('DEBUG RESULT: $result');
if (result['error'] == 'account_exists') {
  setModalState(() => isSendingSms = false);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Account Already Exists"),
      content: const Text("This number already has an account. Please sign in instead."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);  // close dialog
            Navigator.pop(context);  // close bottom sheet
            _showSignIn();  // open sign in flow
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[700]),
          child: const Text("Sign In", style: TextStyle(color: Colors.black)),
        ),
      ],
    ),
  );
  return;
}
if (mounted) {
  Navigator.pop(context);
  _showOTPVerification(phoneNumber, result['dev_code']);
}
                    } catch (e) {
                      setModalState(() => isSendingSms = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPhoneValid ? Colors.yellow[700] : Colors.grey[300],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: isSendingSms
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text("NEXT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    ),
  );
}

  // --- FUNCTION 2: OTP VERIFICATION ---
void _showOTPVerification(String phoneNumber, String? devCode) {
  int secondsRemaining = 30;
  bool canResend = false;
  List<String> otpDigits = ['', '', '', ''];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        Future.delayed(Duration.zero, () {
          Timer.periodic(const Duration(seconds: 1), (timer) {
            if (secondsRemaining > 0) {
              setModalState(() => secondsRemaining--);
            } else {
              setModalState(() => canResend = true);
              timer.cancel();
            }
          });
        });

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Verify Number", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Enter the 4-digit code sent to your phone.", style: TextStyle(color: Colors.grey)),

              if (devCode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text("Dev code: $devCode",
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => SizedBox(
                  width: 55,
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    onChanged: (value) {
                      otpDigits[index] = value;
                      if (value.length == 1 && index < 3) FocusScope.of(context).nextFocus();
                    },
                    decoration: InputDecoration(
                      counterText: "",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 25),

              canResend
                ? TextButton(
                    onPressed: () {
                      setModalState(() { secondsRemaining = 30; canResend = false; });
                      ApiService.sendOTP(phoneNumber);
                    },
                    child: const Text("Resend Code", style: TextStyle(color: Colors.blue)),
                  )
                : Text("Resend code in ${secondsRemaining}s", style: const TextStyle(color: Colors.grey)),

              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    final code = otpDigits.join();
                    if (code.length < 4) return;
                    try {
                      final result = await ApiService.verifyOTP(phoneNumber, code);
                      if (result['token'] != null) {
                        await ApiService.saveToken(result['token']);
                        final user = result['user'];
                        final isNewUser = user['name'] == null;
                        if (mounted) {
                          Navigator.pop(context);
                          if (isNewUser) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileSetupScreen(
                                  onComplete: () {
                                    Navigator.pop(context);
                                    _loadUserName();
                                    setState(() => showWelcome = false);
                                  },
                                ),
                              ),
                            );
                          } else {
                             final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('user_name', user['name'] ?? '');
                            _loadUserName();
                             setState(() => showWelcome = false);
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['error'] ?? 'Invalid code')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("VERIFY & START",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    ),
  );
}
Future<void> _goToUserLocation() async {
  try {
    // 1. Check if location services are even turned on
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("Location services are disabled.");
      return;
    }

    // 2. Handle Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("Permission denied by user.");
        return; 
      }
    }

    // 3. Get Position (The line that usually causes the 'suspension')
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        17.5,
      ),
    );
  } catch (e) {
    debugPrint("Error getting location: $e"); // This stops the red error crash
  }
}

  // logic for the intro timer
  void _startIntro() async {
  await _loadCustomIcon();
  await Future.delayed(const Duration(seconds: 3));
  if (mounted) {
    final token = await ApiService.getToken();
    if (token != null) {
      // Already logged in — skip welcome screen
      setState(() {
        isLoading = false;
        showWelcome = false;
      });
    } else {
      setState(() {
        isLoading = false;
        showWelcome = true;
      });
    }
  }
}
  Widget _buildDrawerItem(IconData icon, String title, {bool isNew = false,VoidCallback? onTap}) {
  return ListTile(
    leading: Icon(icon, color: Colors.black87),
    title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    trailing: isNew ? Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
      child: const Text("NEW", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    ) : null,
    onTap: onTap,
  );
  
}
void _showAddPaymentSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        // This is crucial: it pushes the sheet up when the keyboard appears
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
        left: 24, right: 24, top: 20
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 25),
          const Text("Add Payment Method", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          _buildPaymentField(label: "Card Number", hint: "0000 0000 0000 0000", icon: Icons.credit_card, maxLength: 19,additionalFormatters: [CardNumberFormatter()],),
          const SizedBox(height: 15),
          
          Row(
            children: [
              Expanded(child: _buildPaymentField(label: "Expiry", hint: "MM/YY", maxLength: 5, additionalFormatters: [CardExpirationFormatter()],)),
              const SizedBox(width: 19),
              Expanded(child: _buildPaymentField(label: "CVV", hint: "123", isPassword: true, maxLength: 3, )),
            ],
          ),
          
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3134),
                minimumSize: const Size(double.infinity, 50),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  
              ),
              onPressed: () async {
  // Extract last4 from card number field
  // For now we'll use a simple approach
  setState(() => hasPaymentMethod = true);
  
  try {
    await ApiService.addPayment('4242', 'visa'); // Replace with actual last4
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Payment method added successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    debugPrint('Error saving card: $e');
  }
},
              
              child: const Text("Save Card", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    ),
  );
}

// Helper for clean fields
Widget _buildPaymentField({
  required String label, 
  required String hint, 
  IconData? icon, 
  bool isPassword = false,
  int? maxLength,
  List<TextInputFormatter>? additionalFormatters,
  }) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
      TextField(
        obscureText: isPassword,
        keyboardType: TextInputType.number,
        maxLength: maxLength,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly, // Only allows 0-9
          ...?additionalFormatters,
        ],
        decoration: InputDecoration(
          counterText: "",
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: Colors.orange) : null,
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFB74D))),
        ),
      ),
    ],
  );
}
void _startReservation() {
  // TODO: Implement reservation logic
  debugPrint("Reservation started!");
}
// 1. Update the function signature to accept location and name
void _showScooterDetails(LatLng bikePos, String title, int batteryLevel) { // Added batteryLevel
  String walkingTime = "Calculating...";
  bool isLowBattery = batteryLevel < 10; // Logic for the maintenance state
  
  if (_userPosition != null) {
    double distanceInMeters = Geolocator.distanceBetween(
      _userPosition!.latitude, _userPosition!.longitude,
      bikePos.latitude, bikePos.longitude,
    );
    int mins = (distanceInMeters / 80).round();
    walkingTime = mins <= 1 ? "1 min" : "$mins min";
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        height: 380,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                      top: -55,
                      left: 10,
                      bottom: -70,
                      child: Opacity(
                        opacity: isLowBattery ? 0.6 : 1.0, 
                        child: Image.asset(
                          'assets/motorr.png',
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20, right: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D3134), 
                              borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text(
                              isLowBattery ? "OUT OF SERVICE" : "1.00 DH/min", 
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 15),
                          
                          // --- Battery Row ---
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLowBattery ? Icons.battery_alert : Icons.battery_charging_full, 
                                color: isLowBattery ? Colors.red : const Color(0xFF00D1A0), 
                                size: 20
                              ),
                              Text(
                                " $batteryLevel%", 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16, 
                                  color: isLowBattery ? Colors.red : Colors.black
                                )
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_walk, color: Colors.grey, size: 20),
                              Text(" $walkingTime", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Reserve Button ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Change color to Grey if low battery
                    backgroundColor: isLowBattery ? Colors.grey[400] : const Color(0xFFFFB74D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  // Disable onPressed by passing null if battery is low
                  onPressed: isLowBattery ? null : () {
                    Navigator.pop(context);
                    if (hasPaymentMethod) {
                      _openQRScanner(); 
                    } else {
                      _showPaymentRequiredDialog(context);
                    }
                  },
                  child: Text(
                    isLowBattery ? "MAINTENANCE REQUIRED" : "RESERVE NOW", 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
  // logic for loading the image
  Future<void> _loadCustomIcon() async {
    try {
      final BitmapDescriptor icon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(80, 70)),
        'assets/marker.png',
      );
      if (mounted) {
      setState(() {
        customIcon = icon;
        
        // --- THIS PART IS THE KEY ---
        // We recreate the markers list with the new icon immediately
        _markers = {
          Marker(
            markerId: const MarkerId('scooter1'),
            position: const LatLng(33.5273, -5.1067),
            // infoWindow: const InfoWindow(title: 'Mchina #001', snippet: '🔋 85% Battery'),
            icon: icon, // Use the icon we just loaded
            onTap:() {
              // Pass the specific position and ID to the detail function
              _showScooterDetails(const LatLng(33.5273, -5.1067), 'MCHINA #001',92);
            },
          ),
          Marker(
            markerId: const MarkerId('scooter2'),
            position: const LatLng(33.5250, -5.1040),
            icon: icon, // Use the icon we just loaded
            onTap:() {
              _showScooterDetails(const LatLng(33.5290, -5.1080), "MCHINA #002",8);
            },
          ),
        };
      });
    }
  } catch (e) {
      debugPrint("Error loading icon: $e");
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // AppBar only appears when loading is finished
      appBar: null,
      
      drawer: (isLoading || showWelcome) ? null : 
      Drawer(
  child: Column( // This is the ONLY main container
    children: [
      // 1. CUSTOM CENTERED HEADER
      Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 60, bottom: 20),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFEEEEEE),
              child: Icon(Icons.person, color: Colors.grey, size: 45),
            ),
            const SizedBox(height: 16),
            Text(
              _userName.isNotEmpty ? _userName : 'My Profile',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              "My account", 
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Color(0xFF004D40), size: 18),
                SizedBox(width: 4),
                Text("5.00 Rating", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
      const Divider(height: 1),

      // 2. DRAWER ITEMS (The "Meat" of the menu)
      _buildDrawerItem(
        Icons.payment, 
        "Payment",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentScreen(
            hasCardSaved: hasPaymentMethod,
            onCardAdded: () => setState(() => hasPaymentMethod = true),
          )));
        },
      ),
      _buildDrawerItem(Icons.local_offer_outlined, "Promotions", isNew: true),
      _buildDrawerItem(
        Icons.history, 
        "My Rides",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RideHistoryScreen()));
        },
      ),
      _buildDrawerItem(
        Icons.shield_outlined, 
        "Safety",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SafetyScreen()));
        },
      ),
      _buildDrawerItem(
        Icons.help_outline, 
        "Support",
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen()));
        },
      ),

      // 3. THE LOGOUT AT THE BOTTOM
      const Spacer(), // This correctly pushes the logout to the bottom
      const Divider(),
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        onTap: () {
          Navigator.pop(context);
          _handleLogout();
        },
      ),
      const SizedBox(height: 20),
    ],
  ),
),
      body: Stack(
  children: [
    // LAYER 1: THE MAP
    GoogleMap(
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (controller) => _mapController = controller,
      initialCameraPosition: const CameraPosition(
        target: LatLng(33.5273, -5.1067),
        zoom: 14,
      ),
      markers: _markers,
    ),

    // LAYER: TOP NAV BAR (Search + Menu)
    // LAYER: TOP NAV BAR (Menu Button + Search Bar)
if (!isLoading && !showWelcome && !isRiding) // Hide when riding for a cleaner look
            Positioned(
              top: 50,
              left: 15,
              right: 15,
              child: Row(
                children: [
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.yellow[700],
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                        ),
                        child: const Icon(Icons.menu, color: Colors.black, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Where to?",
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Icon(Icons.mic, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // LAYER: ACTIVE RIDE DASHBOARD
          // Inside your Stack, replace the 'if (isRiding)' block:
              if (isRiding)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15)],
                    ),
                    child: Column(
                      children: [
                        Text("Riding $currentScooter", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(
                          "${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
                        ),
                        Text("${_currentCost.toStringAsFixed(2)} DH", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                            onPressed: _stopRide,
                            child: const Text("END RIDE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          // LAYER: LOCATE ME BUTTON
          if (!isLoading && !showWelcome && !isRiding)
            Positioned(
              bottom: 110,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.black),
                onPressed: () => _goToUserLocation(),
              ),
            ),

          // LAYER: INTRO & WELCOME (Keep your existing if(isLoading) and if(showWelcome) logic here)
          // ... (After the Locate Me Button)

          // LAYER 2: THE WELCOME SLIDER (Restored your original logic)
          if (!isLoading && showWelcome)
            Container(
              color: const Color(0xFF26A69A),
              width: double.infinity,
              height: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (int page) => setState(() => _currentPage = page),
                      children: [
                        _buildSlide('assets/welcome.png', "WELCOME TO MCHINA!", "Your urban transportation experience has never been as practical, fast, and economical."),
                        _buildSlide('assets/student_safe.png', "DRIVE SAFELY", "Always wear a helmet and follow local traffic rules."),
                        _buildSlide('assets/parking_city.png', "EASY PARKING", "Park in designated areas to keep the city clean."),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 12 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.yellow[700] : Colors.white54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () => _showPhoneLogin(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text("CREATE AN ACCOUNT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () =>_showSignIn(),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        children: [
                          TextSpan(text: "Already have an account? "),
                          TextSpan(text: "Sign in", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

          // LAYER 3: THE LOGO INTRO (Restored your original logic)
          if (isLoading)
            Container(
              color: Colors.yellow[700],
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Image.asset('assets/app_logo.png', width: 220, height: 220),
              ),
            ),
        ], // End of Stack children
      ), // End of Stack
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: (isLoading || showWelcome || isRiding) 
          ? null 
          : FloatingActionButton.extended(
                    onPressed: () {
                  if (hasPaymentMethod) {
                    _openQRScanner();
                  } else {
                    // Logic for first-time users or those without a card
                    _showPaymentRequiredDialog(context);
                  }
              },
              label: const Text("SCAN TO RIDE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
              backgroundColor: Colors.yellow[700],
            ),
    );
  }
void _handleLogout() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Log Out"),
      content: const Text("Are you sure you want to log out of your Mchina account?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            // 1. Close the dialog first
            Navigator.pop(context);

            // 2. Cancel any active ride timer
            _rideTimer?.cancel();
            ApiService.clearToken();
            // 3. Navigate to a FRESH MapScreen and remove ALL previous routes
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
              (route) => false, // Removes everything from the stack
            );
          },
          child: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
  void _showPaymentRequiredDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Payment Required", style: TextStyle(fontWeight: FontWeight.bold)),
      content: const Text("To unlock a scooter, please add a payment method first. You won't be charged until your ride starts."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Later", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close the dialog
            _showAddPaymentSheet(context); // Open your payment input sheet
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow[700],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("Add Card", style: TextStyle(color: Colors.black)),
        ),
      ],
    ),
  );
}
  Widget _buildSlide(String imagePath, String title, String description) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(imagePath, height: 380, fit: BoxFit.contain,),
      const SizedBox(height: 20),
      Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
        child: Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    ],
  );
}
} 
class MyBackend {
  Future<bool> verifyCard(String cardNumber) async {
    // Simulate a 1.5-second network delay
    await Future.delayed(const Duration(milliseconds: 1500));
    return true; // Always return true for now
  }
}

// Create the instance at the top of your file or inside your State class
final myBackend = MyBackend();
// Formats 0000000000000000 into 0000 0000 0000 0000



// Formats 1226 into 12/26
class CardExpirationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('/', '');
    String formatted = "";
    
    for (int i = 0; i < text.length; i++) {
      formatted += text[i];
      if ((i + 1) == 2 && text.length > 2) {
        formatted += '/';
      }
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    String enteredData = newValue.text.replaceAll(' ', ''); 
    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < enteredData.length; i++) {
      buffer.write(enteredData[i]);
      int index = i + 1;
      if (index % 4 == 0 && index != enteredData.length) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.toString().length),
    );
  }
}
  class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});
  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<dynamic> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/rides'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body);
      setState(() {
        _rides = data is List ? data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Rides", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _rides.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.electric_scooter, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No rides yet!", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text("Your ride history will appear here.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rides.length,
              itemBuilder: (context, index) {
                final ride = _rides[index];
                final duration = ride['duration_seconds'] ?? 0;
                final minutes = duration ~/ 60;
                final seconds = duration % 60;
                final cost = double.tryParse(ride['cost'].toString()) ?? 0.0;
                final date = ride['ended_at'] != null
                  ? DateTime.parse(ride['ended_at']).toLocal()
                  : null;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.yellow[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.electric_scooter, color: Colors.black),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride['scooter_id'] ?? 'Unknown Scooter',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date != null
                                ? "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2,'0')}"
                                : "Unknown date",
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${minutes}m ${seconds}s",
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${cost.toStringAsFixed(2)} DH",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

