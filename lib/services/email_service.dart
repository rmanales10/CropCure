import 'dart:developer';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // Gmail SMTP Configuration
  static const String _smtpHost = 'smtp.gmail.com';
  static const int _smtpPort = 587;
  static const String _smtpUsername = 'cropcureofficial@gmail.com';
  static const String _smtpPassword = 'ceqo zfwe gqla jdvs';

  // Send welcome email after successful account creation
  static Future<bool> sendWelcomeEmail({
    required String recipientEmail,
    required String recipientName,
  }) async {
    try {
      // Create SMTP server
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ssl: false,
        allowInsecure: false,
      );

      // Create email message with HTML content
      final message =
          Message()
            ..from = Address(_smtpUsername, 'CropCure')
            ..recipients.add(recipientEmail)
            ..subject = 'Welcome to CropCure - Account Created Successfully!'
            ..html = _buildWelcomeEmailHTML(recipientName);

      // Send email
      final sendReport = await send(message, smtpServer);

      // Check if email was sent successfully
      if (sendReport.toString().contains('Message accepted')) {
        log('Welcome email sent successfully to $recipientEmail');
        return true;
      } else {
        log('Email send report: $sendReport');
        return false;
      }
    } catch (e) {
      log('Error sending welcome email: $e');
      return false;
    }
  }

  // Build HTML email template
  static String _buildWelcomeEmailHTML(String recipientName) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
      background-color: #f4f4f4;
    }
    .container {
      background-color: #ffffff;
      padding: 30px;
      border-radius: 10px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .header {
      text-align: center;
      margin-bottom: 30px;
    }
    .logo {
      max-width: 150px;
      height: auto;
      margin-bottom: 20px;
    }
    h1 {
      color: #0f8113;
      margin-bottom: 10px;
    }
    .content {
      margin: 20px 0;
    }
    .greeting {
      font-size: 18px;
      font-weight: bold;
      color: #0f8113;
      margin-bottom: 15px;
    }
    .message {
      margin-bottom: 20px;
      color: #555;
    }
    .features {
      background-color: #f0f9f0;
      padding: 20px;
      border-radius: 8px;
      margin: 20px 0;
      border-left: 4px solid #0f8113;
    }
    .features ul {
      list-style-type: none;
      padding-left: 0;
    }
    .features li {
      padding: 8px 0;
      padding-left: 25px;
      position: relative;
    }
    .features li:before {
      content: "✓";
      position: absolute;
      left: 0;
      color: #0f8113;
      font-weight: bold;
      font-size: 18px;
    }
    .footer {
      margin-top: 30px;
      padding-top: 20px;
      border-top: 1px solid #ddd;
      text-align: center;
      color: #888;
      font-size: 12px;
    }
    .button {
      display: inline-block;
      padding: 12px 30px;
      background-color: #0f8113;
      color: #ffffff !important;
      text-decoration: none;
      border-radius: 5px;
      margin: 20px 0;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <div class="container">
      <div class="header">
      <h1>Welcome to CropCure! 🌱</h1>
    </div>
    
    <div class="content">
      <div class="greeting">
        Hello $recipientName! 👋
      </div>
      
      <div class="message">
        We're thrilled to have you join the CropCure family! Your account has been successfully created.
      </div>
      
      <div class="message">
        CropCure is your trusted companion for plant disease detection and care. With our AI-powered technology, you can:
      </div>
      
      <div class="features">
        <ul>
          <li>Scan and identify plant diseases instantly</li>
          <li>Get personalized treatment recommendations</li>
          <li>Track your plant health over time</li>
          <li>Access expert care tips and tutorials</li>
          <li>Connect with our AI chatbot for plant care advice</li>
        </ul>
      </div>
      
      <div class="message">
        Start by scanning your first plant and let us help you keep your green friends healthy!
      </div>
      
      <div style="text-align: center;">
        <p>Thank you for choosing CropCure!</p>
        <p>Happy gardening! 🌱</p>
      </div>
    </div>
    
    <div class="footer">
      <p>This is an automated message from CropCure.</p>
      <p>If you have any questions, feel free to reach out to us.</p>
      <p>&copy; ${DateTime.now().year} CropCure. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
''';
  }
}
