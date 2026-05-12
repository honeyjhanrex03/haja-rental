import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/landing_screen.dart';
import '../screens/auth/login_customer_screen.dart';
import '../screens/auth/signup_customer_screen.dart';
import '../screens/customer/home_screen.dart';
import '../screens/customer/discover_screen.dart';
import '../screens/customer/category_screen.dart';
import '../screens/customer/track_orders_screen.dart';
import '../screens/customer/notifications_screen.dart';
import '../screens/customer/profile_screen.dart';
import '../screens/customer/item_details_screen.dart';
import '../screens/customer/favorites_screen.dart';
import '../models/item_model.dart';
import '../screens/customer/order_confirmation_screen.dart';
import '../screens/customer/add_address_screen.dart';
import '../screens/customer/conversation_list_screen.dart';
import '../screens/customer/direct_chat_screen.dart';
import '../models/chat_models.dart';
import '../screens/seller/seller_home_screen.dart';
import '../screens/seller/add_listing_screen.dart';
import '../screens/seller/view_shop_rentals_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/user_management_screen.dart';
import '../screens/admin/coupon_management_screen.dart';

class RouteName {
  static const splash = '/';
  static const welcome = '/welcome';
  static const welcomeCustomer = '/welcome-customer';
  static const welcomeSeller = '/welcome-seller';
  static const welcomeAdmin = '/welcome-admin';
  static const landing = '/landing';
  static const login = '/login';
  static const signup = '/signup';
  static const customerHome = '/customer/home';
  static const customerDiscover = '/customer/discover';
  static const customerCategory = '/customer/category';
  static const customerTrackOrders = '/customer/track-orders';
  static const customerProfile = '/customer/profile';
  static const customerFavorites = '/customer/favorites';
  static const customerItemDetails = '/customer/item-details';
  static const customerCheckout = '/customer/checkout';
  static const customerAddAddress = '/customer/add-address';
  static const customerNotifications = '/customer/notifications';
  static const customerMessages = '/customer/messages';
  static const customerDirectChat = '/customer/direct-chat';
  static const sellerHome = '/seller/home';
  static const sellerAddListing = '/seller/add-listing';
  static const sellerViewShopRentals = '/seller/view-shop-rentals';
  static const adminDashboard = '/admin/dashboard';
  static const adminUsers = '/admin/users';
  static const adminCoupons = '/admin/coupons';
}

// We use a ChangeNotifier to allow GoRouter to listen to auth changes
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (prev, next) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isAuthPath = state.matchedLocation == RouteName.splash ||
                       state.matchedLocation == RouteName.landing ||
                       state.matchedLocation == RouteName.login ||
                       state.matchedLocation == RouteName.signup;

    if (!isAuthenticated) {
      return isAuthPath ? null : RouteName.splash;
    }

    if (isAuthPath) {
      switch (authState.user?.role) {
        case UserRole.admin: return RouteName.adminDashboard;
        case UserRole.seller: return RouteName.sellerHome;
        case UserRole.customer: return RouteName.customerHome;
        default: return RouteName.customerHome;
      }
    }

    // Role-based protection for already logged in users
    if (!isAuthPath) {
      final role = authState.user?.role;
      final path = state.matchedLocation;
      
      if (role == UserRole.seller && 
          path.startsWith('/customer') && 
          path != RouteName.customerProfile &&
          path != RouteName.customerMessages &&
          path != RouteName.customerDirectChat) {
        return RouteName.sellerHome;
      }
      if (role == UserRole.customer && path.startsWith('/seller')) {
        return RouteName.customerHome;
      }
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);
  
  return GoRouter(
    initialLocation: RouteName.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: RouteName.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: RouteName.welcome, builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: RouteName.landing, builder: (context, state) => const LandingScreen()),
      GoRoute(path: RouteName.login, builder: (context, state) => const LoginCustomerScreen()),
      GoRoute(path: RouteName.signup, builder: (context, state) => const SignupCustomerScreen()),
      
      // Customer Routes
      GoRoute(path: RouteName.customerHome, builder: (context, state) => const CustomerHomeScreen()),
      GoRoute(path: RouteName.customerDiscover, builder: (context, state) => const CustomerDiscoverScreen()),
      GoRoute(
        path: RouteName.customerCategory, 
        builder: (context, state) {
          String? category;
          bool? isRental;
          
          if (state.extra is String) {
            category = state.extra as String;
          } else if (state.extra is Map<String, dynamic>) {
            final extra = state.extra as Map<String, dynamic>;
            category = extra['category'] as String?;
            isRental = extra['isRental'] as bool?;
          }
          
          return CustomerCategoryScreen(initialCategory: category, isRental: isRental);
        }
      ),
      GoRoute(path: RouteName.customerTrackOrders, builder: (context, state) => const TrackOrdersScreen()),
      GoRoute(path: RouteName.customerProfile, builder: (context, state) => const CustomerProfileScreen()),
      GoRoute(path: RouteName.customerFavorites, builder: (context, state) => const FavoritesScreen()),
      GoRoute(
        path: RouteName.customerItemDetails, 
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Item) {
            return CustomerItemDetailsScreen(item: extra);
          } else if (extra is Map) {
            return CustomerItemDetailsScreen(item: Item.fromJson(Map<String, dynamic>.from(extra)));
          }
          return Scaffold(body: Center(child: Text('Error: Expected Item but got ${extra?.runtimeType}')));
        }
      ),
      GoRoute(
        path: RouteName.customerCheckout, 
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Item) {
            return CustomerOrderConfirmationScreen(item: extra);
          } else if (extra is Map) {
            return CustomerOrderConfirmationScreen(item: Item.fromJson(Map<String, dynamic>.from(extra)));
          }
          return Scaffold(body: Center(child: Text('Error: Expected Item for checkout but got ${extra?.runtimeType}')));
        }
      ),
      GoRoute(path: RouteName.customerAddAddress, builder: (context, state) => const AddAddressScreen()),
      GoRoute(path: RouteName.customerNotifications, builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: RouteName.customerMessages, builder: (context, state) => const ConversationListScreen()),
      GoRoute(
        path: RouteName.customerDirectChat, 
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Conversation) {
            return DirectChatScreen(conversation: extra);
          } else if (extra is Map) {
            return DirectChatScreen(conversation: Conversation.fromJson(Map<String, dynamic>.from(extra)));
          }
          return Scaffold(body: Center(child: Text('Error: Expected Conversation but got ${extra?.runtimeType}')));
        }
      ),
      
      // Seller Routes
      GoRoute(path: RouteName.sellerHome, builder: (context, state) => const SellerHomeScreen()),
      GoRoute(
        path: RouteName.sellerAddListing, 
        builder: (context, state) {
          Item? item;
          final extra = state.extra;
          if (extra is Item) {
            item = extra;
          } else if (extra is Map) {
            item = Item.fromJson(Map<String, dynamic>.from(extra));
          }
          return AddListingScreen(itemToEdit: item);
        }
      ),
      GoRoute(
        path: RouteName.sellerViewShopRentals, 
        builder: (context, state) {
          final tabIndex = state.extra as int? ?? 0;
          return ViewShopRentalsScreen(initialTabIndex: tabIndex);
        }
      ),
      
      // Admin Routes
      GoRoute(path: RouteName.adminDashboard, builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: RouteName.adminUsers, builder: (context, state) => const AdminUserManagementScreen()),
      GoRoute(path: RouteName.adminCoupons, builder: (context, state) => const AdminCouponManagementScreen()),
    ],
  );
});
