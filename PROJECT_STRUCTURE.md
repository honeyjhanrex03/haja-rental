# HAJA Rentals & Apparel - Flutter App

A fully responsive Flutter application built from Figma designs using MCP integration. The app supports three user roles: Customers, Sellers, and Admins.

## Project Structure

```
lib/
├── config/
│   ├── app_colors.dart          # Design color palette
│   ├── app_sizes.dart           # Responsive breakpoints & sizes
│   ├── app_theme.dart           # Material theme configuration
│   └── app_router.dart          # Go Router navigation setup
│
├── providers/
│   └── auth_provider.dart       # Authentication state (Riverpod)
│
├── widgets/
│   └── app_widgets.dart         # Reusable components (buttons, inputs, etc.)
│
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart
│   │   ├── welcome_screen.dart
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── customer/
│   │   └── home_screen.dart
│   ├── seller/
│   │   ├── seller_home_screen.dart
│   │   └── add_listing_screen.dart
│   └── admin/
│       └── admin_dashboard_screen.dart
│
├── main.dart                    # App entry point
└── assets/
    ├── images/                  # Product images, logos
    └── icons/                   # App icons
```

## Features Implemented

### ✅ Completed
- **Project Setup**: Flutter project with Riverpod, Go Router, and Supabase
- **Responsive Design**: Mobile, Tablet, and Desktop breakpoints
- **Design System**: Colors, typography, sizing, and theme
- **Reusable Widgets**: Buttons, inputs, dropdown, social auth buttons
- **Authentication Screens**:
  - Splash screen with 3-second delay
  - Role selection (Customer/Seller/Admin)
  - Login screen with email/password + social auth
  - Sign-up screen with validation
- **Dashboard Screens**:
  - Customer home with location header and product browsing
  - Seller dashboard with quick actions
  - Add listing form with dropdowns, file upload, size selection
  - Admin dashboard with stats and management options
- **Navigation**: Complete routing with Go Router
- **State Management**: Riverpod for auth state
- **No Mock Data**: Ready for Supabase integration

## Responsive Breakpoints

- **Mobile**: < 600px (single column layouts)
- **Tablet**: 600px - 1024px (2-column layouts)
- **Desktop**: > 1024px (multi-column layouts)

## Design Tokens from Figma

### Colors
- **Primary**: #1d1d1d (Dark charcoal)
- **White**: #FFFFFF
- **Text Light**: #C4C0C0
- **Input Background**: rgba(184, 175, 175, 0.3)

### Typography
- **Headlines**: Inter Semi Bold / Black
- **Body**: Inter Regular
- **Labels**: Inter Black

### Spacing
- Radius: 32px - 49px rounded corners
- Padding/Margin: 4, 8, 16, 24, 32, 48

## Next Steps: Supabase Integration

1. **Authentication**:
   - Connect `login()` and `signUp()` in `auth_provider.dart` to Supabase Auth
   - Add session check in `checkAuthStatus()`
   - Implement role-based redirects

2. **Database**:
   - Create tables: `users`, `products`, `orders`, `order_items`
   - Implement CRUD operations for products
   - Set up row-level security (RLS)

3. **Storage**:
   - Upload product images to Supabase Storage
   - Download images for product listings

4. **Real Features**:
   - Product listing/search
   - Shopping cart
   - Order management
   - Product inventory

## Running the App

```bash
# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Run on web
flutter run -d chrome

# Build APK
flutter build apk --release

# Build web
flutter build web
```

## API Integration Points (TODO)

- `lib/providers/auth_provider.dart`: Replace TODO comments with Supabase calls
- `lib/screens/auth/login_screen.dart`: Add error handling
- `lib/screens/seller/add_listing_screen.dart`: Implement image upload
- `lib/screens/seller/seller_home_screen.dart`: Fetch seller's products

## Notes

- All screens are fully responsive
- No hardcoded sizes - uses LayoutBuilder and MediaQuery
- Theme is centralized for easy customization
- Ready for Brevo email notifications integration
- Assets folder structure created for images and icons
