import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/room_controller.dart';
import './room_card.dart';

class RoomListView extends StatelessWidget {
  const RoomListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final approvedRooms = controller.rooms
            .where((room) => room.isApproved)
            .toList();

        if (approvedRooms.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('Không có phòng trọ nào'),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: approvedRooms.length,
          itemBuilder: (context, index) {
            return RoomCard(room: approvedRooms[index]);
          },
        );
      },
    );
  }
} 