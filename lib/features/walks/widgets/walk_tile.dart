import 'package:flutter/material.dart';

import '../models/walk_model.dart';

class WalkTile extends StatelessWidget {
  final WalkModel walk;

  const WalkTile({
    super.key,
    required this.walk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 7,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE45D32)
                  .withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pets_rounded,
              size: 19,
              color: Color(0xFFE45D32),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  walk.dogName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172337),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Walker: ${walk.walkerName}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Text(
            walk.status,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2E9B67),
            ),
          ),
        ],
      ),
    );
  }
}
