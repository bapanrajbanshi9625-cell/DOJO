import 'package:flutter/material.dart';

import '../../screens/custom_app_bar.dart';

import '../insta_walk/widgets/insta_walk_container.dart';
import 'widgets/walks_header.dart';

class WalksScreen extends StatefulWidget {
  const WalksScreen({super.key});

  @override
  State<WalksScreen> createState() => _WalksScreenState();
}

class _WalksScreenState extends State<WalksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      // ========================================================
      // DOJO WALK APP BAR
      // ========================================================

      appBar: const CustomAppBar(),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ==================================================
            // WALKS HEADER
            // ==================================================

            const SliverToBoxAdapter(
              child: WalksHeader(),
            ),

            // ==================================================
            // INSTA WALK
            // NEW LOCATION
            // ==================================================

            const SliverToBoxAdapter(
              child: InstaWalkContainer(),
            ),

            // ==================================================
            // BOTTOM SPACE
            // ==================================================

            const SliverToBoxAdapter(
              child: SizedBox(
                height: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
