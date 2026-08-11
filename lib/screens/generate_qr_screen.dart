import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase Initialization
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f2f5),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Bottom Sheet ko open karne ke liye
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => const MyQRCodeSheet(),
            );
          },
          child: const Text('Show QR Code Sheet'),
        ),
      ),
    );
  }
}

class MyQRCodeSheet extends StatelessWidget {
  const MyQRCodeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: StreamBuilder<DocumentSnapshot>(
        // Firestore se data fetch karne ka stream (Apne collection aur document ka naam dein)
        stream: FirebaseFirestore.instance
            .collection('qr_codes')
            .doc('user_qr')
            .snapshots(),
        builder: (context, snapshot) {
          // Default fallback data jab tak firebase se data load ho raha hai
          String qrData = 'ABC123';

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            qrData = data['code'] ?? 'ABC123'; // Firestore field name 'code'
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 20),
                  const Text(
                    'My QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xfff8fafc),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xffcbd5e1),
                  ),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 120,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              
              // Firebase se aaya hua dynamic text yahan show hoga
              snapshot.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator()
                  : Text(
                      qrData,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

              const SizedBox(height: 12),
              const Text(
                "Use your smartphone's camera or a QR code reader app to scan the QR code above.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xff6b7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
