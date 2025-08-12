import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import '/providers/auth_provider.dart';
import '/widgets/custom_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _addressController;
  late TextEditingController _birthDateController;
  String? _gender;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData ?? {};
    _nameController = TextEditingController(text: userData['name'] ?? '');
    _phoneController = TextEditingController(text: userData['phone'] ?? '');
    _bioController = TextEditingController(text: userData['bio'] ?? '');
    _addressController = TextEditingController(text: userData['address'] ?? '');
    _birthDateController = TextEditingController(
      text: userData['birthDate'] != null
          ? DateFormat('yyyy-MM-dd').format((userData['birthDate'] as Timestamp).toDate())
          : '',
    );
    _gender = userData['gender'] ?? 'Khác';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile; // Cập nhật ảnh ngay lập tức
          print('Image selected: ${_selectedImage?.path}');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
        );
      }
    }
  }

  Future<String?> _convertImageToBase64() async {
    if (_selectedImage == null) {
      print('No image selected for conversion');
      return null;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64String = base64Encode(bytes);
      print('Base64 generated successfully: ${base64String.substring(0, 50)}...');
      return base64String;
    } catch (e) {
      print('Error converting image to base64: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chuyển đổi ảnh: $e')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDateController.text.isNotEmpty
          ? DateTime.parse(_birthDateController.text)
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = authProvider.isDarkMode;
    final userData = authProvider.userData ?? {};
    final photoUrl = userData['photoURL'] ?? '';

    ImageProvider? avatarImage;
    if (_selectedImage != null) {
      avatarImage = FileImage(File(_selectedImage!.path)); // Ưu tiên ảnh vừa chọn
      print('Using selected image for preview: ${_selectedImage!.path}');
    } else if (photoUrl.isNotEmpty) {
      if (photoUrl.contains(RegExp(r'^[A-Za-z0-9+/=]+'))) {
        try {
          avatarImage = MemoryImage(base64Decode(photoUrl));
          print('Using base64 photoUrl for preview: ${photoUrl.substring(0, 50)}...');
        } catch (e) {
          print('Invalid base64: $photoUrl, Error: $e');
          avatarImage = null;
        }
      } else {
        print('Non-base64 skipped: $photoUrl');
        avatarImage = null;
      }
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Chỉnh sửa hồ sơ',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E).withOpacity(0.9)]
                : [Colors.white, Colors.grey[100]!.withOpacity(0.9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: avatarImage,
                        child: (avatarImage == null)
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.blue[700] : Colors.blue[600],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: _pickImage,
                            tooltip: 'Chọn ảnh đại diện',
                          ),
                        ),
                      ),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên',
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[850] : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập tên';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[850] : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.phone, color: Colors.blue),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại';
                    if (!RegExp(r'^\+?0[0-9]{9,10}$').hasMatch(value))
                      return 'Số điện thoại không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Tiểu sử',
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[850] : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.description, color: Colors.blue),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                  maxLength: 150,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ',
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[850] : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.location_on, color: Colors.blue),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthDateController,
                  decoration: InputDecoration(
                    labelText: 'Ngày sinh (YYYY-MM-DD)',
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[850] : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.date_range, color: Colors.blue),
                      onPressed: _selectDate,
                      tooltip: 'Chọn ngày sinh',
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                  keyboardType: TextInputType.datetime,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value))
                      return 'Ngày sinh không hợp lệ (YYYY-MM-DD)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    labelText: 'Giới tính',
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[850] : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.wc, color: Colors.blue),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                  items: ['Nam', 'Nữ', 'Khác'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _gender = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                String? photoUrl;
                                if (_selectedImage != null) {
                                  photoUrl = await _convertImageToBase64();
                                  print('New photoUrl (base64): ${photoUrl?.substring(0, 50) ?? 'null'}...');
                                }
                                print('Final photoUrl: ${photoUrl ?? 'null'}');
                                await authProvider.updateProfile(
                                  authProvider.user!.uid,
                                  name: _nameController.text,
                                  phone: _phoneController.text,
                                  photoUrl: photoUrl,
                                  bio: _bioController.text,
                                  address: _addressController.text,
                                  birthDate: _birthDateController.text.isNotEmpty
                                      ? DateTime.parse(_birthDateController.text)
                                      : null,
                                  gender: _gender,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Cập nhật thành công!')),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi khi cập nhật: $e')),
                                  );
                                }
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: Theme.of(context).textTheme.labelLarge,
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Lưu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}