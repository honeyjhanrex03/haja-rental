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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit User',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                
                // Name Field
                _buildDialogField('Full Name', nameController),
                const SizedBox(height: 15),
                
                // Contact Field
                _buildDialogField('Contact Number', contactController),
                const SizedBox(height: 15),
                
                // Role Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: InputBorder.none,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      items: ['customer', 'seller', 'admin'].map((role) => 
                        DropdownMenuItem(value: role, child: Text(role.toUpperCase()))
                      ).toList(),
                      onChanged: (val) => setDialogState(() => selectedRole = val!),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                        child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
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
    final customers = _users.where((u) => (u['role'] ?? 'customer') == 'customer').toList();
    final sellers = _users.where((u) => (u['role'] ?? 'customer') == 'seller').toList();
    final admins = _users.where((u) => (u['role'] ?? 'customer') == 'admin').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: const Text('User Management', style: TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: AppColors.white),
          bottom: const TabBar(
            indicatorColor: AppColors.white,
            labelColor: AppColors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Customers'),
              Tab(text: 'Sellers'),
            ],
          ),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : TabBarView(
              children: [
                _buildUserList(customers),
                _buildUserList(sellers),
              ],
            ),
        // Admin Floating Action: If you have admins, you can see them too
        floatingActionButton: admins.isNotEmpty ? FloatingActionButton.extended(
          onPressed: () => _showAdminsList(admins),
          backgroundColor: Colors.black,
          label: const Text('View Admins', style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
        ) : null,
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> userList) {
    if (userList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text('No users found in this category', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: userList.length,
        itemBuilder: (context, index) {
          final user = userList[index];
          
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
                  Text(user['contact_number'] ?? 'No contact number', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
    );
  }

  void _showAdminsList(List<Map<String, dynamic>> admins) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Platform Administrators', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...admins.map((admin) => ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.admin_panel_settings, color: Colors.white)),
              title: Text(admin['full_name'] ?? 'Admin', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(admin['username'] ?? ''),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(admin);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
