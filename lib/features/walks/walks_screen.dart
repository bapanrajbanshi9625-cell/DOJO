import 'package:flutter/material.dart';

import '../../screens/custom_app_bar.dart';

import 'widgets/walks_header.dart';
import 'widgets/insta_walk_container.dart';
import 'widgets/this_week_section.dart';
import 'widgets/past_weeks_section.dart';

class WalksScreen extends StatefulWidget {
  const WalksScreen({super.key});

  @override
  State<WalksScreen> createState() => _WalksScreenState();
}

class _WalksScreenState extends State<WalksScreen> {
  DateTime selectedPastWeek = DateTime.now()
      .subtract(const Duration(days: 7));

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
            // ==================================================

            SliverToBoxAdapter(
              child: InstaWalkContainer(
                onWalkerFound: () {
                  setState(() {});
                },
              ),
            ),

            // ==================================================
            // THIS WEEK
            // ==================================================

            const SliverToBoxAdapter(
              child: ThisWeekSection(),
            ),

            // ==================================================
            // PAST WEEKS
            // ==================================================

            SliverToBoxAdapter(
              child: PastWeeksSection(
                selectedDate: selectedPastWeek,
                onDateChanged: (date) {
                  setState(() {
                    selectedPastWeek = date;
                  });
                },
              ),
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
