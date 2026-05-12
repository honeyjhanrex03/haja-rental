import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/env.dart';

class EmailService {
  final Dio _dio = Dio();
  final String _apiKey = Env.brevoApiKey;
  final String _apiUrl = 'https://api.brevo.com/v3/smtp/email';


  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  Future<bool> sendEmail({
    required String toEmail,
    required String toName,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      debugPrint('📧 EMAIL LOG: Attempting to send to $toEmail');
      final response = await _dio.post(
        _apiUrl,
        options: Options(
          headers: {
            'api-key': _apiKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true,
        ),
        data: {
          'sender': {'name': 'HAJA Rental', 'email': 'honeyambaic@gmail.com'},
          'to': [
            {'email': toEmail, 'name': toName}
          ],
          'subject': subject,
          'htmlContent': htmlContent,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ EMAIL SUCCESS: Sent to $toEmail');
        return true;
      } else {
        debugPrint('❌ EMAIL ERROR [Status ${response.statusCode}]: ${response.data}');
        debugPrint('💡 HINT: Check if hajarentals.official@gmail.com is a VERIFIED SENDER in your Brevo dashboard.');
        return false;
      }
    } catch (e) {
      debugPrint('⚠️ EMAIL CRITICAL ERROR: $e');
      if (e is DioException) {
        debugPrint('⚠️ DIO DATA: ${e.response?.data}');
        if (e.toString().contains('XMLHttpRequest')) {
          debugPrint('⚠️ WEB ALERT: This looks like a CORS error. Browser is blocking direct email sending.');
        }
      }
      return false;
    }
  }

  // Professional Welcome Email Template
  String getWelcomeTemplate(String name) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; }
        .header { background-color: #1A1A1A; color: #ffffff; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { padding: 30px; background-color: #ffffff; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #888; }
        .button { display: inline-block; padding: 12px 25px; background-color: #D4AF37; color: #ffffff; text-decoration: none; border-radius: 5px; font-weight: bold; margin-top: 20px; }
        h1 { margin: 0; font-size: 24px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Welcome to HAJA Rental</h1>
        </div>
        <div class="content">
          <h2>Hi $name,</h2>
          <p>Thank you for joining HAJA Rental! We are thrilled to have you as part of our exclusive fashion community.</p>
          <p>At HAJA, we believe everyone deserves to look their best. Start exploring our premium collection of outfits for your next big event.</p>
          <center>
            <a href="#" class="button">Explore Collection</a>
          </center>
          <p>If you have any questions, our support team is always here to help.</p>
          <p>Best regards,<br>The HAJA Team</p>
        </div>
        <div class="footer">
          &copy; 2026 HAJA Rental. All rights reserved.
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  // Professional Order Confirmation Template
  String getOrderConfirmationTemplate(String name, String itemName, String totalPrice, String date) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; }
        .header { background-color: #1A1A1A; color: #ffffff; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { padding: 30px; background-color: #ffffff; }
        .order-box { background-color: #f9f9f9; padding: 20px; border-radius: 5px; margin-top: 20px; border-left: 5px solid #D4AF37; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #888; }
        h1 { margin: 0; font-size: 24px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Order Confirmed</h1>
        </div>
        <div class="content">
          <h2>Hello $name,</h2>
          <p>Good news! Your rental order has been successfully placed. Our team is now preparing your item for pickup/delivery.</p>
          
          <div class="order-box">
            <strong>Order Summary:</strong><br>
            Item: $itemName<br>
            Total Payment: $totalPrice<br>
            Date: $date
          </div>

          <p>You can track your order status directly in the app.</p>
          <p>Thank you for choosing HAJA Rental for your fashion needs.</p>
          <p>Best regards,<br>The HAJA Team</p>
        </div>
        <div class="footer">
          &copy; 2026 HAJA Rental. Panabo City, Davao Del Norte.
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  // Professional Promotion Template
  String getPromotionTemplate(String name, String discountCode, String discountAmount) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; }
        .header { background-color: #D4AF37; color: #ffffff; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { padding: 30px; background-color: #ffffff; text-align: center; }
        .promo-code { display: block; font-size: 32px; font-weight: bold; color: #1A1A1A; margin: 20px 0; border: 2px dashed #D4AF37; padding: 15px; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #888; }
        h1 { margin: 0; font-size: 28px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Exclusive Offer for You!</h1>
        </div>
        <div class="content">
          <h2>Hi $name,</h2>
          <p>We have a special treat for you. Get ready for your next event with a special discount on your next rental.</p>
          
          <p>Use this code at checkout to get:</p>
          <div class="promo-code">$discountAmount OFF</div>
          <p><strong>Code: $discountCode</strong></p>

          <p>This offer is valid for a limited time only. Don't miss out!</p>
          <p>Stay Stylish,<br>The HAJA Team</p>
        </div>
        <div class="footer">
          &copy; 2026 HAJA Rental. Style is everything.
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  // Professional Status Update Template
  String getStatusUpdateTemplate(String name, String itemName, String newStatus, String message) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; }
        .header { background-color: #1A1A1A; color: #ffffff; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { padding: 30px; background-color: #ffffff; }
        .status-badge { display: inline-block; padding: 5px 15px; background-color: #D4AF37; color: #ffffff; border-radius: 20px; font-weight: bold; font-size: 14px; margin: 10px 0; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #888; }
        h1 { margin: 0; font-size: 24px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Order Update</h1>
        </div>
        <div class="content">
          <h2>Hi $name,</h2>
          <p>Your order for <strong>$itemName</strong> has a new update:</p>
          
          <div class="status-badge">$newStatus</div>
          
          <p>$message</p>

          <p>You can check the full details of your order in the HAJA app.</p>
          <p>Thank you for your patience!<br>The HAJA Team</p>
        </div>
        <div class="footer">
          &copy; 2026 HAJA Rental. Style on the move.
        </div>
      </div>
    </body>
    </html>
    ''';
  }
}
