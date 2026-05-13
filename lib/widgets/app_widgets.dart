import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Color? fillColor;
  final Color? labelColor;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.fillColor,
    this.labelColor,
    this.validator,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: TextStyle(
              color: widget.labelColor ?? AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _isObscured,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          style: const TextStyle(color: AppColors.textDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
            filled: true,
            fillColor: widget.fillColor ?? AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading; // ADDED

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false, // ADDED
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: backgroundColor == AppColors.white ? AppColors.primary : AppColors.white, 
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  color: textColor ?? AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? borderColor;
  final Color? textColor;
  final bool isLoading; // ADDED

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.borderColor,
    this.textColor,
    this.isLoading = false, // ADDED
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor ?? AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              )
            : Text(
                text,
                style: TextStyle(
                  color: textColor ?? AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.iconPath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, height: 20, errorBuilder: (c, e, s) => const Icon(Icons.login, size: 20)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: AppColors.textDark, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class TextDivider extends StatelessWidget {
  final String text;
  final Color? textColor;
  final Color? lineColor;

  const TextDivider({super.key, required this.text, this.textColor, this.lineColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: lineColor ?? Colors.grey)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text, style: TextStyle(color: textColor ?? Colors.grey, fontSize: 12)),
        ),
        Expanded(child: Divider(color: lineColor ?? Colors.grey)),
      ],
    );
  }
}

class AppAlert {
  static Future<void> showSuccess(BuildContext context, String message) async {
    await _showAlert(context, message, Icons.check_circle, Colors.green);
  }

  static Future<void> showError(BuildContext context, String message) async {
    await _showAlert(context, message, Icons.error, Colors.red);
  }

  static Future<void> showInfo(BuildContext context, String message) async {
    await _showAlert(context, message, Icons.info_outline, AppColors.gold);
  }

  static Future<bool> showConfirm(BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Proceed',
    String cancelText = 'Cancel',
    IconData icon = Icons.help_outline,
    Color color = AppColors.gold,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 50),
                    ),
                    const SizedBox(height: 25),
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(cancelText, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            child: Text(confirmText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      },
    );
    return result ?? false;
  }

  static Future<void> _showAlert(BuildContext context, String message, IconData icon, Color color) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 50),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      color == Colors.red ? 'Oops!' : 'Success!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textDark.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
class FullImageOverlay extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  const FullImageOverlay({super.key, required this.imageUrls, this.initialIndex = 0});

  @override
  State<FullImageOverlay> createState() => _FullImageOverlayState();

  static void show(BuildContext context, List<String> imageUrls, {int initialIndex = 0}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, _) => FullImageOverlay(imageUrls: imageUrls, initialIndex: initialIndex),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _FullImageOverlayState extends State<FullImageOverlay> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final url = widget.imageUrls[index];
                return Center(
                  child: Hero(
                    tag: index == 0 ? url : 'image_overlay_$index',
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: url.startsWith('assets/') 
                        ? Image.asset(url, fit: BoxFit.contain)
                        : Image.network(
                            url,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                            },
                          ),
                    ),
                  ),
                );
              },
            ),
            // Header with Close and Indicator
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.imageUrls.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.imageUrls.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Container(
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

