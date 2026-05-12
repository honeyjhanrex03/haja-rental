import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_router.dart';
import '../../providers/database_provider.dart';
import '../../widgets/custom_bottom_bar.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Favorites', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteName.customerHome);
            }
          },
        ),
      ),
      body: ref.watch(favoriteItemsProvider).when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    'Your Favorites List is Empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  const Text('Save items you love here!', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => context.go(RouteName.customerDiscover),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: const Text('Start Exploring', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.7,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => context.push(RouteName.customerItemDetails, extra: item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: item.imageUrl.startsWith('assets/')
                                ? AssetImage(item.imageUrl) as ImageProvider
                                : NetworkImage(item.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('₱ ${item.price}', style: const TextStyle(color: AppColors.primary)),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }
}
