# Configuration Files

This directory contains centralized configuration files for the CropCure app.

## Files

### `gemini_config.dart`
Centralized configuration for Gemini AI API integration.

**Features:**
- Single source of truth for API keys
- Model configurations for different tasks
- Rate limiting settings
- Free tier limits reference
- Helper methods for dynamic configuration

**Usage:**
```dart
import 'package:cropcure/config/gemini_config.dart';

// Get API key
final apiKey = GeminiConfig.apiKey;

// Get model for specific task
final model = GeminiConfig.getModelForTask('image');

// Get cooldown period
final cooldown = GeminiConfig.getCooldownForTask('text');

// Check if configuration is valid
if (GeminiConfig.isValid()) {
  // Proceed with API calls
}
```

### `sms_config.dart`
Configuration for SMS service integration with Semaphore API.

**Features:**
- API key management
- Sender name configuration
- OTP settings
- Rate limiting information

## Security Notes

1. **Never commit API keys to version control**
2. **Use environment variables in production**
3. **Rotate API keys regularly**
4. **Monitor API usage and costs**

## Environment Setup

For production deployment, consider using environment variables:

```dart
// Example for production
static const String apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
```

## Rate Limiting

The configuration includes built-in rate limiting to respect free tier limits:

- **Image requests**: 6-second cooldown
- **Text requests**: 4-second cooldown
- **General requests**: 6-second cooldown

## Model Selection

The configuration automatically selects the best model for each task:

- **Image analysis**: `gemini-2.5-flash-lite`
- **Text processing**: `gemini-2.5-flash-lite`
- **Complex analysis**: `gemini-2.5-flash`
