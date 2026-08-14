import 'package:flutter/material.dart';

class WalksHeader extends StatelessWidget {
  const WalksHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Walks',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172337),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Book a walk and manage your walks',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
