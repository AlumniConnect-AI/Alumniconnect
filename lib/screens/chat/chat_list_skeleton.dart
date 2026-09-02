import 'package:flutter/material.dart';
import '../../widgets/shimmer_box.dart';

class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const ShimmerBox(height: 48, width: 48, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(height: 14, width: 140),
                    SizedBox(height: 6),
                    ShimmerBox(height: 12, width: double.infinity),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
