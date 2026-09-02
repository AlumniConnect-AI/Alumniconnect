import 'package:flutter/material.dart';
import '../../widgets/shimmer_box.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: const [
          ShimmerBox(height: 60, width: double.infinity),
          SizedBox(height: 20),
          ShimmerBox(height: 100, width: double.infinity),
          SizedBox(height: 20),
          ShimmerBox(height: 100, width: double.infinity),
        ],
      ),
    );
  }
}
