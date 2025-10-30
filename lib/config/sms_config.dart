class SMSConfig {
  // TODO: Replace with your actual Semaphore API key
  // You can get your API key from: https://semaphore.co/account
  static const String semaphoreApiKey = 'c6743576f5f28b8c6d5e429813d8d6ce';

  // Sender name as requested
  static const String senderName = 'ABESO';

  // OTP settings
  static const int otpLength = 6;
  static const int otpValidityMinutes = 5;
  static const int maxResendAttempts = 3;

  // API endpoints
  static const String baseUrl = 'https://api.semaphore.co/api/v4';
  static const String otpEndpoint = '$baseUrl/otp';
  static const String messagesEndpoint = '$baseUrl/messages';
}
