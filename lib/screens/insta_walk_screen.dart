import 'package:flutter/material.dart';

import '../features/insta_walk/widgets/insta_walk_container.dart';

class InstaWalkScreen extends StatelessWidget {
  const InstaWalkScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF243746),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Insta Walk',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: 30,
          ),
          child: InstaWalkContainer(
            fullScreen: true,
          ),
        ),
      ),
    );
  }
}
