# HAJA Rentals & Apparel 🌸

HAJA is a premium, fully responsive Flutter application designed for the modern fashion rental marketplace. It bridges the gap between style and sustainability by allowing users to rent high-end apparel for any occasion.


## 🚀 Key Features

### 👤 User Roles
- **Customers**: Browse curated collections, book rentals, track orders, and receive expert fashion advice from an **Intelligent AI Smart Stylist**.
- **Sellers**: Manage shop listings, track rental income, upload product images via Cloudinary, and get professional business support from a dedicated AI Assistant.
- **Admins**: Platform-wide analytics, user management, and system monitoring.

### ✨ Advanced Functionality
- **High-Intelligence AI Stylist**: Powered by Groq (Llama 3), the AI is deeply integrated with the shop's live inventory, user favorites, and local trends. It provides personalized style advice and interactive **Product Recommendation Cards** that link directly to checkout.
- **Real-Time Messaging**: Seamless chat between buyers and sellers with instant unread notification synchronization.
- **Smart Notifications**: Intelligent notification badge system and automated email updates via Brevo for all order status transitions.
- **Premium Design System**: A sophisticated, responsive UI optimized for Mobile, Tablet, and Desktop, featuring custom-generated branding assets and a consistent luxury aesthetic.

## 🛠 Tech Stack

- **Frontend**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://pub.dev/packages/flutter_riverpod)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Backend**: [Supabase](https://supabase.com/) (Auth, Database, Real-time)
- **AI Engine**: [Groq Cloud](https://groq.com/)
- **Image Hosting**: [Cloudinary](https://cloudinary.com/)
- **Email Service**: [Brevo](https://www.brevo.com/)

## ⚙️ Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Dart SDK
- Git

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/honeyjhanrex03/haja-rental.git
   cd haja-rental
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   The project uses a protected `env.dart` file for API keys. 
   - Copy `lib/config/env.dart.example` to `lib/config/env.dart`.
   - Fill in your credentials:
     ```dart
     class Env {
       static const String supabaseUrl = 'YOUR_URL';
       static const String supabaseAnonKey = 'YOUR_KEY';
       static const String brevoApiKey = 'YOUR_KEY';
       static const String cloudinaryCloudName = 'YOUR_NAME';
       static const String cloudinaryUploadPreset = 'YOUR_PRESET';
       static const String customerGroqKey = 'YOUR_KEY';
       static const String sellerGroqKey = 'YOUR_KEY';
     }
     ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## 📂 Project Structure

```
lib/
├── config/        # Themes, Router, and Env configurations
├── models/        # Data models for Orders, Products, and Users
├── providers/     # Riverpod state management & services
├── screens/       # UI implementation (Auth, Customer, Seller, Admin)
├── services/      # External API integrations (Email, etc.)
└── widgets/       # Reusable UI components
```

## 🤝 Contributing

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---
*Built with ❤️ by [honeyjhanrex03](https://github.com/honeyjhanrex03)*
