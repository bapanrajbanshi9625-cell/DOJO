import 'package:flutter/material.dart';

class InstaWalkContainer extends StatelessWidget {
  final VoidCallback? onWalkerFound;

  const InstaWalkContainer({
    super.key,
    this.onWalkerFound,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        8,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE45D32),
              Color(0xFFC84A24),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),

                const SizedBox(width: 13),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Insta Walk',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Find a walker right now',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Text(
              'We search for an online and available walker within 3 km.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  onWalkerFound?.call();
                },
                icon: const Icon(
                  Icons.search_rounded,
                ),
                label: const Text(
                  'Find a Walker',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor:
                      const Color(0xFFE45D32),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
