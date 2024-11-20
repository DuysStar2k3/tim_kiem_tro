import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/room_controller.dart';

class FeaturedRoomsPage extends StatelessWidget {
  const FeaturedRoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phòng trọ đề cử'),
      ),
      body: Consumer<RoomController>(
        builder: (context, controller, child) {
          final approvedRooms = controller.rooms
              .where((room) => room.isApproved)
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: approvedRooms.length,
            itemBuilder: (context, index) {
              final room = approvedRooms[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    if (room.images.isNotEmpty)
                      Image.network(
                        room.images.first,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  room.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.star_border,
                                  color: Colors.amber,
                                ),
                                onPressed: () {
                                  // TODO: Thêm logic đề cử phòng sau khi cập nhật RoomModel
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Địa chỉ: ${room.address}'),
                          Text(
                            'Giá: ${room.price.toStringAsFixed(0)} VNĐ/tháng',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 