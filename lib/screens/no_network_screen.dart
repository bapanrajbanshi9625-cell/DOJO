import 'package:flutter/material.dart';

class NoNetworkScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const NoNetworkScreen({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF7F1),
              Color(0xFFFFFDFC),
              Color(0xFFF5F7FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ==================================================
              // OFFLINE ICON
              // ==================================================

              Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.88),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF26A21)
                          .withOpacity(0.10),
                      blurRadius: 45,
                      spreadRadius: 5,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 25,
                      right: 30,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFE3D1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 30,
                      left: 28,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFE8DA),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 105,
                      color: Color(0xFFF26A21),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 42),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF22252A),
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // DESCRIPTION
              // ==================================================

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 35),
                child: Text(
                  'It looks like you’re offline right now.\n'
                  'Please check your internet connection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.6,
                    color: Color(0xFF777C84),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // ==================================================
              // RETRY BUTTON
              // ==================================================

              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 21,
                ),
                label: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor:
                      Colors.black.withOpacity(0.20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // ORANGE ACCENT
              // ==================================================

              Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFF26A21),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
