import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:cropcure/config/sms_config.dart';

class SMSService {
  /// Send OTP to phone number
  static Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      // Format phone number to Philippine format if needed
      String formattedNumber = _formatPhoneNumber(phoneNumber);

      final response = await http.post(
        Uri.parse(SMSConfig.otpEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'apikey': SMSConfig.semaphoreApiKey,
          'number': formattedNumber,
          'message':
              'Your ${SMSConfig.senderName} verification code is: {otp}. Please use it within ${SMSConfig.otpValidityMinutes} minutes.',
          'sendername': SMSConfig.senderName,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('SMS API Response: $data'); // Debug logging
        if (data is List && data.isNotEmpty) {
          final responseData = data[0];
          log(
            'OTP Code type: ${responseData['code'].runtimeType}',
          ); // Debug logging
          return {
            'success': true,
            'message_id': responseData['message_id'],
            'otp_code':
                responseData['code']?.toString() ??
                '', // Convert int to string safely
            'status': responseData['status'],
            'message': 'OTP sent successfully',
          };
        }
      }

      log('SMS API Error: ${response.statusCode} - ${response.body}');
      return {
        'success': false,
        'message': 'Failed to send OTP. Please try again.',
      };
    } catch (e) {
      log('SMS Service Error: $e');
      return {
        'success': false,
        'message': 'Error sending OTP: ${e.toString()}',
      };
    }
  }

  /// Send regular SMS message
  static Future<Map<String, dynamic>> sendSMS(
    String phoneNumber,
    String message,
  ) async {
    try {
      String formattedNumber = _formatPhoneNumber(phoneNumber);

      final response = await http.post(
        Uri.parse(SMSConfig.messagesEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'apikey': SMSConfig.semaphoreApiKey,
          'number': formattedNumber,
          'message': message,
          'sendername': SMSConfig.senderName,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          return {
            'success': true,
            'message_id': data[0]['message_id'],
            'status': data[0]['status'],
            'message': 'SMS sent successfully',
          };
        }
      }

      return {
        'success': false,
        'message': 'Failed to send SMS. Please try again.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error sending SMS: ${e.toString()}',
      };
    }
  }

  /// Format phone number to Philippine format
  static String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If it starts with 0, replace with 63
    if (cleaned.startsWith('0')) {
      cleaned = '63${cleaned.substring(1)}';
    }

    // If it doesn't start with 63, add it
    if (!cleaned.startsWith('63')) {
      cleaned = '63$cleaned';
    }

    return cleaned;
  }

  /// Validate Philippine phone number
  static bool isValidPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it's a valid Philippine mobile number
    // Should be 10-11 digits starting with 9, or 11-12 digits starting with 63
    if (cleaned.startsWith('63')) {
      return cleaned.length == 12 && cleaned.substring(2).startsWith('9');
    } else if (cleaned.startsWith('0')) {
      return cleaned.length == 11 && cleaned.substring(1).startsWith('9');
    } else if (cleaned.startsWith('9')) {
      return cleaned.length == 10;
    }

    return false;
  }

  /// Generate a random 6-digit OTP
  static String generateOTP() {
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString();
  }
}
