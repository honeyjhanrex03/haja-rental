import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/app_widgets.dart';

class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends ConsumerState<AdminUserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await ref.read(adminProvider.notifier).fetchAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) AppAlert.showError(context, 'Failed to load users: $e');
    }
  }

  void _showEditDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'] ?? 'customer';
    final nameController = TextEditingController(text: user['full_name']);
    final contactController = TextEditingController(text: user['contact_number']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: contactController,
              decoration: const InputDecoration(labelText: 'Contact Number'),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: ['customer', 'seller', 'admin'].map((role) => 
                DropdownMenuItem(value: role, child: Text(role.toUpperCase()))
              ).toList(),
              onChanged: (val) => selectedRole = val!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(adminProvider.notifier).updateUser(user['id'], {
                'full_name': nameController.text,
                'contact_number': contactController.text,
                'role': selectedRole,
              });
              if (context.mounted) {
                Navigator.pop(context);
                _loadUsers();
                AppAlert.showSuccess(context, 'User updated successfully');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User Profile'),
        content: Text('Are you sure you want to delete ${user['full_name']}\'s profile data? This will not delete their authentication account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(adminProvider.notifier).deleteUserProfile(user['id']);
              if (context.mounted) {
                Navigator.pop(context);
                _loadUsers();
                AppAlert.showSuccess(context, 'Profile deleted');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('User Management', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
        : RefreshIndicator(
            onRefresh: _loadUsers,
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final role = user['role'] ?? 'customer';
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                      child: user['avatar_url'] == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                    ),
                    title: Text(user['full_name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['username'] ?? 'No Email'),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: role == 'admin' ? Colors.purple[100] : role == 'seller' ? Colors.blue[100] : Colors.green[100],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: role == 'admin' ? Colors.purple : role == 'seller' ? Colors.blue : Colors.green)),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: () => _showEditDialog(user)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _showDeleteDialog(user)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }
}
