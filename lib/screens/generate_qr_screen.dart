import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const GenerateQRCodeScreen(),
    );
  }
}

// ======================================================
// GENERATE QR CODE SCREEN
// ======================================================

class GenerateQRCodeScreen extends StatefulWidget {
  const GenerateQRCodeScreen({super.key});

  @override
  State<GenerateQRCodeScreen> createState() =>
      _GenerateQRCodeScreenState();
}

class _GenerateQRCodeScreenState
    extends State<GenerateQRCodeScreen> {
  final TextEditingController textController =
      TextEditingController(
    text: 'ABC123',
  );

  bool addLogo = true;
  bool customColor = false;
  bool isSaving = false;

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> saveAndOpenQR() async {
    final String qrData = textController.text.trim();

    if (qrData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter URL or text'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('qr_codes')
          .doc('user_qr')
          .set({
        'code': qrData,
        'scanned': false,
        'addLogo': addLogo,
        'customColor': customColor,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      openMyQRCode();

    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR save failed: $e'),
        ),
      );
    }
  }

  void openMyQRCode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return const MyQRCodeSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f2f5),
      body: Center(
        child: Container(
          width: 360,
          height: 720,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff6366f1),
                Color(0xff3b82f6),
              ],
            ),
            borderRadius: BorderRadius.circular(40),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Text(
                        'QR Code Studio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 75,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    30,
                    24,
                    30,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Generate New QR',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff111827),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Enter Website URL or Text',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff4b5563),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: textController,
                          decoration: InputDecoration(
                            hintText:
                                'e.g., www.mywebsite.com/menu',
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(
                                color: Color(0xffd1d5db),
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(
                                color: Color(0xff6366f1),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xfff8fafc),
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    const Color(0xffe5e7eb),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Live QR Preview\nWill Appear Here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      Color(0xff9ca3af),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Customize',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff4b5563),
                          ),
                        ),
                        CheckboxListTile(
                          value: addLogo,
                          onChanged: (value) {
                            setState(() {
                              addLogo = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity:
                              ListTileControlAffinity.leading,
                          activeColor:
                              const Color(0xff6366f1),
                          title: const Text(
                            'Add Brand Logo',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff6b7280),
                            ),
                          ),
                        ),
                        CheckboxListTile(
                          value: customColor,
                          onChanged: (value) {
                            setState(() {
                              customColor =
                                  value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity:
                              ListTileControlAffinity.leading,
                          activeColor:
                              const Color(0xff6366f1),
                          title: const Text(
                            'Custom Color Theme',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff6b7280),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                isSaving
                                    ? null
                                    : saveAndOpenQR,
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xff6366f1),
                              foregroundColor:
                                  Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Generate QR Code',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          'My Saved Codes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff111827),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _historyItem(
                          Icons.contact_page,
                          'Digital Business Card',
                          'Generated on Oct 25',
                        ),
                        const SizedBox(height: 10),
                        _historyItem(
                          Icons.shopping_cart,
                          'Product A5 Promo',
                          'Generated on Oct 24',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyItem(
    IconData icon,
    String title,
    String date,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff9fafb),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xffe0e7ff),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xff6366f1),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff111827),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xff6b7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================
// MY QR CODE BOTTOM SHEET
// ======================================================

class MyQRCodeSheet extends StatelessWidget {
  const MyQRCodeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('qr_codes')
          .doc('user_qr')
          .snapshots(),
      builder: (context, snapshot) {
        String qrData = 'ABC123';

        if (snapshot.hasData &&
            snapshot.data!.exists) {
          final data =
              snapshot.data!.data()
                  as Map<String, dynamic>;
          qrData =
              data['code'] ?? 'ABC123';
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 30),
                  const Text(
                    'My QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1f2937),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xff4b5563),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color:
                      const Color(0xfff8fafc),
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        const Color(0xffcbd5e1),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code_2,
                    size: 120,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                qrData,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff111827),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Text(
                  "Use your smartphone's camera or a QR code reader app to scan the QR code above.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff6b7280),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

// ======================================================
// NEW: GENERATE QR BUTTON WIDGET (होम स्क्रीन के लिए)
// ======================================================

class GenerateQRButton extends StatelessWidget {
  const GenerateQRButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFFF4511E),
      foregroundColor: Colors.white,
      elevation: 8,
      onPressed: () {
        // जब यूजर होम स्क्रीन पर इस बटन पर क्लिक करेगा, 
        // तो यह सीधे GenerateQRCodeScreen पर ले जाएगा 
        // (या अगर आप स्टूडियो के बजाय सीधे बॉटम शीट खोलना चाहते हैं, तो यहाँ बदल सकते हैं)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GenerateQRCodeScreen(),
          ),
        );
      },
      icon: const Icon(Icons.qr_code_2),
      label: const Text(
        'Generate QR Code',
        style: TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
