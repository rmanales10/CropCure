# SMS Verification Flow

## Registration Process with SMS Verification

```
1. User Registration Form
   ├── Full Name (required)
   ├── Email (required)
   ├── Phone Number (required) - NEW
   ├── Password (required)
   ├── Confirm Password (required)
   └── Terms & Privacy Agreement (required)

2. Phone Number Validation
   ├── Check if valid Philippine mobile number
   ├── Format: 09XXXXXXXXX, 9XXXXXXXXX, or 639XXXXXXXXX
   └── Auto-format to international format (639XXXXXXXXX)

3. Navigate to OTP Verification Screen
   ├── Display phone number for confirmation
   ├── Send OTP via Semaphore API
   └── Show 6-digit OTP input fields

4. OTP Verification Process
   ├── User enters 6-digit OTP
   ├── Auto-focus between input fields
   ├── Real-time validation
   └── 5-minute countdown timer

5. OTP Validation
   ├── Compare entered OTP with received OTP
   ├── If valid: Proceed to account creation
   └── If invalid: Show error message

6. Account Creation
   ├── Create Firebase user account
   ├── Store user data in Firestore
   ├── Mark phone as verified
   ├── Send email verification
   └── Redirect to login page

7. Resend OTP (if needed)
   ├── Maximum 3 attempts
   ├── Reset timer after each resend
   └── Show attempt counter
```

## SMS Service Integration

```
Semaphore API Integration:
├── API Key Configuration
├── Sender Name: "ABESO"
├── OTP Endpoint: /api/v4/otp
├── Message Format: "Your ABESO verification code is: {otp}. Please use it within 5 minutes."
└── Error Handling & Rate Limiting
```

## Security Features

```
Security Measures:
├── Phone Number Validation
├── OTP Expiration (5 minutes)
├── Maximum Resend Attempts (3)
├── Secure API Key Storage
├── Input Sanitization
└── Error Message Security
```

## File Structure

```
lib/
├── services/
│   └── sms_service.dart          # SMS API integration
├── config/
│   └── sms_config.dart           # Configuration settings
└── user/onboarding_login/auth_screen/
    ├── signup.dart               # Updated registration form
    ├── otp_verification.dart     # OTP verification screen
    └── auth_service.dart         # Updated auth service
```

## API Endpoints Used

```
Semaphore API Endpoints:
├── POST /api/v4/otp              # Send OTP (no rate limit)
├── POST /api/v4/messages         # Send regular SMS (120/min)
├── GET /api/v4/account           # Account info (2/min)
└── GET /api/v4/messages          # Retrieve messages (30/min)
```

## Error Handling

```
Error Scenarios:
├── Invalid Phone Number
├── API Key Issues
├── Network Connectivity
├── Invalid OTP Code
├── Expired OTP
├── Maximum Resend Attempts
└── Firebase Registration Errors
```
