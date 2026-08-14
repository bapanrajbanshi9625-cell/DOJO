import 'package:flutter/material.dart';

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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: WalksHeader(),
            ),

            SliverToBoxAdapter(
              child: InstaWalkContainer(
                onWalkerFound: () {
                  setState(() {});
                },
              ),
            ),

            const SliverToBoxAdapter(
              child: ThisWeekSection(),
            ),

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

            const SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          ],
        ),
      ),
    );
  }
}
