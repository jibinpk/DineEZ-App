// Utility class for form validations

class Validators {
  /// Validates an email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Simple regex pattern for email validation
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }
  
  /// Validates a password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }
  
  /// Validates a name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }
  
  /// Validates a phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Simple regex for numeric values only
    final phoneRegex = RegExp(r'^\d+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid phone number (digits only)';
    }
    
    if (value.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    return null;
  }
  
  /// Validates required fields
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }
  
  /// Validates credit card number
  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Credit card number is required';
    }
    
    // Remove spaces and dashes
    final cleanedValue = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check if all characters are digits
    if (!RegExp(r'^\d+$').hasMatch(cleanedValue)) {
      return 'Enter a valid credit card number';
    }
    
    // Check length (most cards are between 13-19 digits)
    if (cleanedValue.length < 13 || cleanedValue.length > 19) {
      return 'Credit card number should be 13-19 digits';
    }
    
    // Luhn algorithm check
    int sum = 0;
    bool alternate = false;
    for (int i = cleanedValue.length - 1; i >= 0; i--) {
      int n = int.parse(cleanedValue[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    
    if (sum % 10 != 0) {
      return 'Enter a valid credit card number';
    }
    
    return null;
  }
  
  /// Validates CVV
  static String? validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    
    // CVV is typically 3-4 digits
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'Enter a valid CVV';
    }
    
    return null;
  }
  
  /// Validates expiry date in MM/YY format
  static String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    
    // Check format (MM/YY)
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Enter date in MM/YY format';
    }
    
    final parts = value.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    final year = int.tryParse(parts[1]) ?? 0;
    
    // Check month is valid
    if (month < 1 || month > 12) {
      return 'Enter a valid month (01-12)';
    }
    
    // Check against current date
    final now = DateTime.now();
    final currentYear = now.year % 100; // Get last 2 digits of year
    final currentMonth = now.month;
    
    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return 'Card has expired';
    }
    
    return null;
  }
} 