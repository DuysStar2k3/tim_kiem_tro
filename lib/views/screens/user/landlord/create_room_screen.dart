import 'package:flutter/material.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/room_controller.dart';
import '../../../../models/room_model.dart';
import '../../../../theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

import '../room/location_picker_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _areaController = TextEditingController();
  final _depositController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<String> _images = [];
  bool _isLoading = false;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};

  bool _hasParking = false;
  bool _hasWifi = false;
  bool _hasAC = false;
  bool _hasFridge = false;
  bool _hasWasher = false;
  bool _hasPrivateBathroom = false;
  bool _hasKitchen = false;
  bool _hasFreedom = false;

  String _roomType = 'Phòng trọ';
  String _gender = 'Tất cả';
  int _maxTenants = 1;

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final List<File> _imageFiles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng tin phòng trọ'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thêm ảnh
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  if (_isLoading)
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Đang tải ảnh lên...'),
                        ],
                      ),
                    )
                  else if (_images.isEmpty && _imageFiles.isEmpty)
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.add_photo_alternate, size: 50),
                        onPressed: _pickImages,
                      ),
                    )
                  else
                    ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length + _imageFiles.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _images.length + _imageFiles.length) {
                          return Center(
                            child: IconButton(
                              icon: const Icon(Icons.add_photo_alternate),
                              onPressed: _pickImages,
                            ),
                          );
                        }

                        if (index < _images.length) {
                          // Hiển thị ảnh đã upload
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _images[index],
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _removeImage(index),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Hiển thị ảnh đang chờ upload
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _imageFiles[index - _images.length],
                                    width: 180,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const Positioned(
                                top: 8,
                                right: 8,
                                child: CircularProgressIndicator(),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 24),
            const Text(
              'Thông tin cơ bản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Loại phòng
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Loại phòng',
                border: OutlineInputBorder(),
              ),
              value: _roomType,
              items: ['Phòng trọ', 'Chung cư mini', 'CCMN', 'Nhà nguyên căn']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _roomType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Tiêu đề
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Địa chỉ và nút chọn vị trí
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập địa chỉ';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _pickLocation,
                  icon: const Icon(Icons.location_on),
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
// Thêm phần hiển thị bản đồ sau khi chọn vị trí
            if (_selectedLocation != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Vị trí đã chọn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation!,
                          zoom: 15,
                        ),
                        markers: _markers,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        onMapCreated: (controller) {
                          controller.animateCamera(
                            CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
                          );
                        },
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit_location),
                            onPressed: _pickLocation,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Giá và diện tích
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Giá thuê (VNĐ/tháng)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập giá thuê';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Giá thuê không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Diện tích (m²)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập diện tích';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Diện tích không hợp lệ';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Đặt cọc và số điện thoại
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _depositController,
                    decoration: const InputDecoration(
                      labelText: 'Tiền cọc (VNĐ)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Đối tượng cho thuê
            const Text(
              'Đối tượng cho thuê',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Giới tính và số người ở
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Giới tính',
                      border: OutlineInputBorder(),
                    ),
                    value: _gender,
                    items: ['Tất cả', 'Nam', 'Nữ']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Số người ở tối đa',
                      border: OutlineInputBorder(),
                    ),
                    value: _maxTenants,
                    items: List.generate(6, (index) => index + 1)
                        .map((num) => DropdownMenuItem(
                              value: num,
                              child: Text('$num người'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _maxTenants = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tiện ích
            const Text(
              'Tiện ích',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildUtilityChip('Gửi xe', Icons.motorcycle, _hasParking,
                    (val) => setState(() => _hasParking = val!)),
                _buildUtilityChip('WiFi', Icons.wifi, _hasWifi,
                    (val) => setState(() => _hasWifi = val!)),
                _buildUtilityChip('Điều hòa', Icons.ac_unit, _hasAC,
                    (val) => setState(() => _hasAC = val!)),
                _buildUtilityChip('Tủ lạnh', Icons.kitchen, _hasFridge,
                    (val) => setState(() => _hasFridge = val!)),
                _buildUtilityChip('Máy giặt', Icons.local_laundry_service,
                    _hasWasher, (val) => setState(() => _hasWasher = val!)),
                _buildUtilityChip('WC riêng', Icons.wc, _hasPrivateBathroom,
                    (val) => setState(() => _hasPrivateBathroom = val!)),
                _buildUtilityChip('Bếp', Icons.restaurant, _hasKitchen,
                    (val) => setState(() => _hasKitchen = val!)),
                _buildUtilityChip('Tự do', Icons.lock_open, _hasFreedom,
                    (val) => setState(() => _hasFreedom = val!)),
              ],
            ),
            const SizedBox(height: 24),

            // Mô tả
            const Text(
              'Mô tả chi tiết',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Mô tả chi tiết về phòng trọ...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mô tả';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Nút đăng tin
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Đăng tin'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityChip(
      String label, IconData icon, bool value, Function(bool?) onChanged) {
    return FilterChip(
      selected: value,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: value ? Colors.white : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: value ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      onSelected: onChanged,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70, // Nén ảnh để giảm dung lượng
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _imageFiles.addAll(pickedFiles.map((xFile) => File(xFile.path)));
        });

        // Upload ảnh lên Firebase Storage
        for (File imageFile in _imageFiles) {
          String fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
          Reference ref = _storage.ref().child('rooms').child(fileName);

          try {
            setState(() {
              _isLoading = true;
            });

            // Upload file
            await ref.putFile(imageFile);

            // Lấy URL download
            String downloadUrl = await ref.getDownloadURL();

            setState(() {
              _images.add(downloadUrl);
            });
          } catch (e) {
            debugPrint('Error uploading image: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi khi tải ảnh lên: $e')),
              );
            }
          } finally {
            setState(() {
              _isLoading = false;
            });
          }
        }

        // Clear file list sau khi đã upload xong
        _imageFiles.clear();
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
        );
      }
    }
  }

  void _removeImage(int index) async {
    try {
      // Xóa ảnh khỏi Storage
      String imageUrl = _images[index];
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      setState(() {
        _images.removeAt(index);
      });
    } catch (e) {
      debugPrint('Error removing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa ảnh: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Kiểm tra người dùng đã đăng nhập
      final currentUser = context.read<AuthController>().currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng đăng nhập để đăng tin')),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final roomController = context.read<RoomController>();
        final room = RoomModel(
          id: '',
          title: _titleController.text,
          address: _addressController.text,
          price: double.parse(_priceController.text),
          description: _descriptionController.text,
          images: _images,
          landlordId: currentUser.id,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          roomType: _roomType,
          area: double.tryParse(_areaController.text) ?? 0,
          deposit: double.tryParse(_depositController.text) ?? 0,
          phone: _phoneController.text,
          gender: _gender,
          maxTenants: _maxTenants,
          hasParking: _hasParking,
          hasWifi: _hasWifi,
          hasAC: _hasAC,
          hasFridge: _hasFridge,
          hasWasher: _hasWasher,
          hasPrivateBathroom: _hasPrivateBathroom,
          hasKitchen: _hasKitchen,
          hasFreedom: _hasFreedom,
        );

        await roomController.createRoom(room);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Đăng tin thành công, chờ admin duyệt')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    // Xóa các ảnh tạm nếu có
    for (File file in _imageFiles) {
      file
          .delete()
          // ignore: invalid_return_type_for_catch_error
          .catchError((e) => debugPrint('Error deleting temp file: $e'));
    }
    _titleController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _areaController.dispose();
    _depositController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('selected_location'),
            position: result,
          ),
        );
      });

      // Lấy địa chỉ từ tọa độ
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          result.latitude,
          result.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = '';

          // Thêm số nhà và tên đường
          if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            if (place.subThoroughfare != null &&
                place.subThoroughfare!.isNotEmpty) {
              address += '${place.subThoroughfare} ';
            }
            address += place.thoroughfare!;
          }

          // Thêm phường/xã (sử dụng subLocality)
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

          // Thêm quận/huyện (sử dụng subAdministrativeArea)
          if (place.subAdministrativeArea != null &&
              place.subAdministrativeArea!.isNotEmpty) {
            if (address.isNotEmpty) address += ', ';
            String district = place.subAdministrativeArea!;
            if (!district.toLowerCase().contains('quận') &&
                !district.toLowerCase().contains('huyện')) {
              if (district.contains('Quận') || district.contains('quận')) {
                address += district;
              } else if (district.contains('Huyện') ||
                  district.contains('huyện')) {
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

          _addressController.text = address;

          // Log để debug
          debugPrint('Detailed address components:');
          debugPrint('subThoroughfare (số nhà): ${place.subThoroughfare}');
          debugPrint('thoroughfare (đường): ${place.thoroughfare}');
          debugPrint('subLocality (phường/xã): ${place.subLocality}');
          debugPrint(
              'subAdministrativeArea (quận/huyện): ${place.subAdministrativeArea}');
          debugPrint(
              'administrativeArea (tỉnh/thành): ${place.administrativeArea}');
          debugPrint('Final address: $address');
        }
      } catch (e) {
        debugPrint('Error getting address: $e');
      }
    }
  }
}
