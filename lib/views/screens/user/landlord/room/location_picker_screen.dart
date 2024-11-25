import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../theme/app_colors.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = latLng;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('selected_location'),
            position: latLng,
          ),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 15),
      );

      _getAddressFromLatLng(latLng);
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí'),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
              child: const Text('Xong'),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(21.0285, 105.8542), // Hà Nội
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            onTap: _handleMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm địa điểm',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(8),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: _searchLocation,
              ),
            ),
          ),
          // Current location button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
        ),
      );
    });
    _getAddressFromLatLng(location);
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);

        setState(() {
          _selectedLocation = latLng;
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('selected_location'),
              position: latLng,
            ),
          );
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy địa điểm')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi tìm kiếm địa điểm')),
        );
      }
      debugPrint('Error searching location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        
        // Thêm số nhà và tên đường
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
            address += '${place.subThoroughfare} ';
          }
          address += place.thoroughfare!;
        }

        // Thêm phường/xã (sử dụng subLocality thay vì subAdministrativeArea)
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          String ward = place.subLocality!;
          if (!ward.toLowerCase().contains('phường') && 
              !ward.toLowerCase().contains('xã')) {
            if (ward.contains('Phường') || ward.contains('phường')) {
              address += ward;
            } else if (ward.contains('Xã') || ward.contains('xã')) {
              address += ward;
            } else {
              address += 'Phường $ward';
            }
          } else {
            address += ward;
          }
        }

        // Thêm quận/huyện (sử dụng subAdministrativeArea thay vì locality)
        if (place.subAdministrativeArea != null && 
            place.subAdministrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          String district = place.subAdministrativeArea!;
          if (!district.toLowerCase().contains('quận') && 
              !district.toLowerCase().contains('huyện')) {
            if (district.contains('Quận') || district.contains('quận')) {
              address += district;
            } else if (district.contains('Huyện') || district.contains('huyện')) {
              address += district;
            } else {
              address += 'Quận $district';
            }
          } else {
            address += district;
          }
        }

        // Thêm tỉnh/thành phố
        if (place.administrativeArea != null && 
            place.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          String city = place.administrativeArea!;
          if (!city.toLowerCase().contains('thành phố') && 
              !city.toLowerCase().contains('tỉnh')) {
            if (city.toLowerCase().contains('hà nội')) {
              address += 'Thành phố Hà Nội';
            } else if (city.toLowerCase().contains('hồ chí minh')) {
              address += 'Thành phố Hồ Chí Minh';
            } else if (city.toLowerCase().contains('đà nẵng')) {
              address += 'Thành phố Đà Nẵng';
            } else if (city.toLowerCase().contains('hải phòng')) {
              address += 'Thành phố Hải Phòng';
            } else if (city.toLowerCase().contains('cần thơ')) {
              address += 'Thành phố Cần Thơ';
            } else {
              address += 'Tỉnh $city';
            }
          } else {
            address += city;
          }
        }

        // Thêm quốc gia
        address += ', Việt Nam';

        setState(() {
          _searchController.text = address;
        });

        // Log để debug
        debugPrint('Detailed address components:');
        debugPrint('subThoroughfare (số nhà): ${place.subThoroughfare}');
        debugPrint('thoroughfare (đường): ${place.thoroughfare}');
        debugPrint('subLocality (phường/xã): ${place.subLocality}');
        debugPrint('subAdministrativeArea (quận/huyện): ${place.subAdministrativeArea}');
        debugPrint('administrativeArea (tỉnh/thành): ${place.administrativeArea}');
        debugPrint('Final address: $address');
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lấy thông tin địa chỉ'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
