import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../models/category_model.dart';
import '../../widgets/custom_bottom_bar.dart';

// Customer Category Screen
class CustomerCategoryScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final bool? isRental;
  const CustomerCategoryScreen({super.key, this.initialCategory, this.isRental});

  @override
  ConsumerState<CustomerCategoryScreen> createState() => _CustomerCategoryScreenState();
}

class _CustomerCategoryScreenState extends ConsumerState<CustomerCategoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider(widget.isRental == false ? CategoryType.shop : CategoryType.rental));

    return Scaffold(
      backgroundColor: AppColors.primary,
      drawer: _buildDrawer(context, ref),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  categoriesAsync.when(
                    data: (categories) => _buildCategoryFilter(categories),
                    loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                    error: (e, s) => const SizedBox(height: 60, child: Center(child: Text('Error loading categories'))),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildItemsGrid(ref, gender: 'Women'),
                        _buildItemsGrid(ref, gender: 'Men'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(List<Category> categories) {
    final allCategories = ['All', ...categories.map((c) => c.name)];
    
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final cat = allCategories[index];
          final isActive = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(cat),
              selected: isActive,
              onSelected: (val) {
                if (val) setState(() => _selectedCategory = cat);
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsGrid(WidgetRef ref, {required String gender}) {
    final itemsAsync = ref.watch(itemsProvider((
      isRental: widget.isRental,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      gender: gender,
    )));

    return itemsAsync.when(
      data: (items) {
        final filteredItems = items.where((item) {
          if (_searchQuery.isEmpty) return true;
          return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 50, color: Colors.grey[300]),
                const SizedBox(height: 10),
                const Text('No items match your search.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.6,
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            return GestureDetector(
              onTap: () => context.push(RouteName.customerItemDetails, extra: item),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              image: item.imageUrl.startsWith('assets/')
                                  ? AssetImage(item.imageUrl) as ImageProvider
                                  : NetworkImage(item.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.isRental ? AppColors.gold : AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.isRental ? 'RENT' : 'SALE',
                              style: const TextStyle(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Consumer(
                            builder: (context, ref, child) {
                              final userFavs = ref.watch(userFavoritesProvider);
                              final isFavorite = userFavs.maybeWhen(
                                data: (favIds) => favIds.contains(item.id),
                                orElse: () => false,
                              );
                              return IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.white,
                                  size: 18,
                                ),
                                onPressed: () {
                                  ref.read(favoriteToggleProvider.notifier).toggleFavorite(item.id, isFavorite);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('₱ ${item.price}', style: const TextStyle(fontSize: 9, color: AppColors.primary)),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/logo.png'),
                ),
                SizedBox(height: 10),
                Text(
                  'HAJA Rentals',
                  style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () => context.go(RouteName.customerHome),
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text('My Orders'),
            onTap: () => context.go(RouteName.customerTrackOrders),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Favorites'),
            onTap: () {
              Navigator.pop(context);
              context.push(RouteName.customerFavorites);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () => context.go(RouteName.customerProfile),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(authProvider.notifier).logout();
              context.go(RouteName.landing);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteName.customerHome);
                      }
                    },
                  ),
                  Text(
                    'Browse ${widget.isRental == true ? 'Rentals' : widget.isRental == false ? 'Shop' : 'Items'}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final unreadCount = ref.watch(totalNotificationCountProvider);
                      return IconButton(
                        onPressed: () => context.push(RouteName.customerNotifications),
                        icon: Badge(
                          label: Text(unreadCount.toString()),
                          isLabelVisible: unreadCount > 0,
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.notifications_none, color: AppColors.white),
                        ),
                      );
                    },
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(), 
                      icon: const Icon(Icons.menu, color: AppColors.white)
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Search Bar (Single Oblong)
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search for items...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: AppColors.gold, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: AppColors.primary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.gold,
        indicatorWeight: 3,
        labelColor: AppColors.white,
        unselectedLabelColor: Colors.white60,
        indicatorPadding: EdgeInsets.zero,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
        tabs: const [
          Tab(text: 'Women'),
          Tab(text: 'Men'),
        ],
      ),
    );
  }
}
