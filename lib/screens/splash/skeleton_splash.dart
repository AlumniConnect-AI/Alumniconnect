import 'package:flutter/material.dart';
import '../../widgets/shimmer_box.dart';

class SkeletonSplash extends StatelessWidget {
  const SkeletonSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            ShimmerBox(height: 100, width: 100, radius: 50),
            SizedBox(height: 20),
            ShimmerBox(height: 20, width: 160),
          ],
        ),
      ),
    );
  }
}
