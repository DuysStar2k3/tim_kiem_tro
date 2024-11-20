import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../models/room_model.dart';
import '../../../../theme/app_colors.dart';

class RoomLocationDetailScreen extends StatefulWidget {
  final RoomModel room;

  const RoomLocationDetailScreen({
    super.key,
    required this.room,
  });

  @override
  State<RoomLocationDetailScreen> createState() =>
      _RoomLocationDetailScreenState();
}

class _RoomLocationDetailScreenState extends State<RoomLocationDetailScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers.add(
      Marker(
        markerId: MarkerId(widget.room.id),
        position: LatLng(widget.room.latitude, widget.room.longitude),
        infoWindow: InfoWindow(
          title: widget.room.title,
          snippet: '${widget.room.price.toStringAsFixed(0)} VNĐ/tháng',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vị trí phòng trọ'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.room.latitude, widget.room.longitude),
              zoom: 16,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          // Room info card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.room.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.room.address,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.attach_money,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.room.price.toStringAsFixed(0)} VNĐ/tháng',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Open in Google Maps
                            _openInGoogleMaps();
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('Mở Google Maps'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Get directions
                            _getDirections();
                          },
                          icon: const Icon(Icons.directions),
                          label: const Text('Chỉ đường'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Current location button
          Positioned(
            bottom: 200,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          16,
        ),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  Future<void> _openInGoogleMaps() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${widget.room.latitude},${widget.room.longitude}';
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở Google Maps')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening Google Maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi khi mở Google Maps')),
        );
      }
    }
  }

  Future<void> _getDirections() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final url = 'https://www.google.com/maps/dir/?api=1'
          '&origin=${position.latitude},${position.longitude}'
          '&destination=${widget.room.latitude},${widget.room.longitude}'
          '&travelmode=driving';

      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở chỉ đường')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting directions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy chỉ đường')),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
