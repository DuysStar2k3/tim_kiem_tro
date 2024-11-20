import 'package:flutter/material.dart';
import 'room_card.dart';

class RoomListView extends StatelessWidget {
  const RoomListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return const RoomCard();
      },
    );
  }
} 