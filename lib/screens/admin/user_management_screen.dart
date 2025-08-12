import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_shop/providers/auth_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _editingUserId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showAddOrEditUserDialog({Map<String, dynamic>? user}) {
    _nameController.text = user?['name'] ?? '';
    _phoneController.text = user?['phone'] ?? '';
    _addressController.text = user?['address'] ?? '';
    _editingUserId = user != null ? user['id'] : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_editingUserId == null ? 'Thêm người dùng' : 'Sửa người dùng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'SĐT',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _addressController.text.isEmpty) {
                Fluttertoast.showToast(msg: 'Vui lòng điền đầy đủ thông tin!');
                return;
              }
              final userData = {
                'name': _nameController.text,
                'phone': _phoneController.text,
                'address': _addressController.text,
              };
              try {
                if (_editingUserId == null) {
                  await FirebaseFirestore.instance.collection('users').add(userData);
                  Fluttertoast.showToast(msg: 'Thêm người dùng thành công!');
                } else {
                  await FirebaseFirestore.instance.collection('users').doc(_editingUserId).update(userData);
                  Fluttertoast.showToast(msg: 'Cập nhật người dùng thành công!');
                }
                Navigator.pop(context);
                _clearFields();
              } catch (e) {
                Fluttertoast.showToast(msg: 'Lỗi: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A9BD4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_editingUserId == null ? 'Thêm' : 'Lưu'),
          ),
        ],
      ),
    );
  }

  void _clearFields() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _editingUserId = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<AuthProvider>(context).isDarkMode;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm người dùng...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF5A9BD4)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _showAddOrEditUserDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A9BD4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                child: const Text('Thêm người dùng mới'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF5A9BD4)));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }
              final users = snapshot.data?.docs ?? [];
              final filteredUsers = _searchController.text.isEmpty
                  ? users
                  : users.where((user) {
                      final userData = user.data() as Map<String, dynamic>;
                      return (userData['name'] ?? '').toLowerCase().contains(_searchController.text.toLowerCase()) ||
                          (userData['email'] ?? '').toLowerCase().contains(_searchController.text.toLowerCase()) ||
                          (userData['phone'] ?? '').toLowerCase().contains(_searchController.text.toLowerCase());
                    }).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index].data() as Map<String, dynamic>;
                  final userId = filteredUsers[index].id;

                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    shadowColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      title: Text(
                        user['name'] ?? 'Chưa có tên',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${user['email'] ?? 'Chưa cập nhật'}'),
                          Text('SĐT: ${user['phone'] ?? 'Chưa cập nhật'}'),
                          Text('Địa chỉ: ${user['address'] ?? 'Chưa cập nhật'}'),
                          Text('Vai trò: ${user['role'] ?? 'user'}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF5A9BD4)),
                            onPressed: () => _showAddOrEditUserDialog(user: {
                              'id': userId,
                              'name': user['name'],
                              'phone': user['phone'],
                              'address': user['address'],
                            }),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Color(0xFFD32F2F)),
                            onPressed: () async {
                              try {
                                await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                                Fluttertoast.showToast(msg: 'Xóa người dùng thành công!');
                              } catch (e) {
                                Fluttertoast.showToast(msg: 'Lỗi: $e');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}