import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _photoUrlController;
  late TextEditingController _bioController;
  late TextEditingController _addressController;
  late TextEditingController _birthDateController;
  String? _gender;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData ?? {};
    _nameController = TextEditingController(text: userData['name'] ?? '');
    _phoneController = TextEditingController(text: userData['phone'] ?? '');
    _photoUrlController = TextEditingController(text: userData['photoURL'] ?? '');
    _bioController = TextEditingController(text: userData['bio'] ?? '');
    _addressController = TextEditingController(text: userData['address'] ?? '');
    _birthDateController = TextEditingController(
      text: userData['birthDate'] != null
          ? (userData['birthDate'] as Timestamp).toDate().toIso8601String().split('T')[0]
          : '',
    );
    _gender = userData['gender'] ?? 'Khác';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _photoUrlController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chức năng chọn ảnh chỉ hỗ trợ trên mobile!')),
      );
      return;
    }
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (await file.exists()) {
          setState(() {
            _selectedImage = file;
            _photoUrlController.text = file.path; // Cập nhật TextField với đường dẫn
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File ảnh không tồn tại!')),
          );
        }
      }
    } catch (e) {
      print('Lỗi chọn ảnh: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
      );
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
    if (picked != null) {
      setState(() {
        _birthDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = authProvider.isDarkMode;
    final userData = authProvider.userData ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDarkMode ? const Color(0xFF0F3460) : Colors.blue[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [Colors.white, Colors.grey[100]!],
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
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (userData['photoURL'] != null &&
                                    userData['photoURL'].isNotEmpty &&
                                    File(userData['photoURL']).existsSync())
                                ? FileImage(File(userData['photoURL']))
                                : null,
                        child: (_selectedImage == null &&
                                (userData['photoURL'] == null ||
                                    userData['photoURL'].isEmpty ||
                                    !File(userData['photoURL']).existsSync()))
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
                          ),
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
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
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
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
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
                  controller: _photoUrlController,
                  decoration: InputDecoration(
                    labelText: 'URL ảnh đại diện',
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[850] : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.image, color: Colors.blue),
                  ),
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !Uri.parse(value).isAbsolute)
                      return 'URL không hợp lệ';
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
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
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
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
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
                    ),
                  ),
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
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
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  items: ['Nam', 'Nữ', 'Khác'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _gender = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          String photoUrl = _selectedImage?.path ?? _photoUrlController.text;
                          if (_selectedImage != null && !File(photoUrl).existsSync()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đường dẫn ảnh không hợp lệ!')),
                            );
                            return;
                          }
                          await authProvider.updateProfile(authProvider.user!.uid,
                              name: _nameController.text,
                              phone: _phoneController.text,
                              photoUrl: photoUrl,
                              bio: _bioController.text,
                              address: _addressController.text,
                              birthDate: _birthDateController.text.isNotEmpty
                                  ? DateTime.parse(_birthDateController.text)
                                  : null,
                              gender: _gender);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cập nhật thành công!')),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          print('Lỗi cập nhật: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? const Color(0xFF1E90FF) : Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Lưu', style: TextStyle(fontSize: 18)),
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