# Error Handling System

This document explains the enhanced error handling system implemented in the HR Chokchey Mobile App.

## Overview

The error handling system provides user-friendly error messages and helps diagnose common issues like network connectivity and server problems.

## Components

### 1. Custom Exceptions (`lib/utils/exceptions.dart`)

Custom exception classes for different error types:

- **NetworkException**: No internet connection
  - Message: "No internet connection. Please access google.com to check your connection."
  
- **ServerException**: Server-side errors (500, 502, 503, etc.)
  - Message: "Server error. Access endpoint: server-checking to verify server status."
  
- **TimeoutException**: Request timeout
- **AuthenticationException**: Authentication/authorization errors
- **DataParseException**: JSON parsing errors
- **ValidationException**: Input validation errors
- **AppException**: General application errors

### 2. Error Handler (`lib/utils/error_handler.dart`)

Centralized error handling utilities:

- `handleHttpResponse()`: Analyzes HTTP responses and throws appropriate exceptions
- `getUserFriendlyMessage()`: Converts exceptions to user-friendly messages
- `isNetworkError()`: Checks if error is network-related
- `isServerError()`: Checks if error is server-related
- `requiresReauth()`: Checks if user needs to re-authenticate

### 3. Network Checker (`lib/utils/network_checker.dart`)

Internet connectivity checker:

- `hasConnection()`: Checks connection by looking up google.com
- `hasConnectionAdvanced()`: Checks multiple DNS servers for better reliability

### 4. HTTP Service (`lib/services/http_service.dart`)

Wrapper around HTTP requests with built-in error handling:

- Checks internet connection before making requests
- Checks server status via `server-checking` endpoint
- Automatically handles common errors
- Provides GET, POST, PUT, DELETE methods with consistent error handling

### 5. Error Dialog Widget (`lib/widgets/error_dialog.dart`)

Enhanced UI for displaying errors:

- **Dialog mode**: For critical errors that need user attention
  - Shows icon based on error type
  - Provides helpful suggestions
  - Includes retry button
  
- **Snackbar mode**: For less critical errors
  - Quick notification at bottom of screen
  - Auto-dismisses after duration
  - Optional retry action

## Usage Examples

### In Repository Layer

```dart
import '../services/http_service.dart';
import '../utils/exceptions.dart';

Future<Data> fetchData() async {
  try {
    // Use HttpService with automatic error handling
    final response = await HttpService.get(
      url: '${baseUrl}endpoint',
      headers: {'Authorization': 'Bearer $token'},
    );
    
    return Data.fromJson(json.decode(response.body));
  } on NetworkException {
    rethrow; // Let ViewModel handle it
  } on ServerException {
    rethrow;
  } catch (e) {
    throw AppException(message: 'Failed to fetch data: $e');
  }
}
```

### In ViewModel Layer

```dart
import '../utils/error_handler.dart';

Future<void> loadData() async {
  try {
    _setLoading(true);
    final data = await repository.fetchData();
    // Process data...
    _setLoading(false);
  } catch (e) {
    // Convert to user-friendly message
    _setError(ErrorHandler.getUserFriendlyMessage(e));
    _setLoading(false);
  }
}
```

### In View Layer

#### Option 1: Show Dialog (for critical errors)

```dart
import '../../widgets/error_dialog.dart';

if (viewModel.errorMessage != null) {
  ErrorDialog.show(
    context: context,
    error: viewModel.errorMessage,
    onRetry: () {
      viewModel.refresh();
    },
  );
}
```

#### Option 2: Show Snackbar (for less critical errors)

```dart
import '../../widgets/error_dialog.dart';

if (viewModel.errorMessage != null) {
  ErrorDialog.showSnackbar(
    context: context,
    error: viewModel.errorMessage,
    onRetry: () => viewModel.retry(),
  );
}
```

## Error Flow

```
1. User Action
   ↓
2. ViewModel calls Repository
   ↓
3. Repository uses HttpService
   ↓
4. HttpService checks:
   - Internet connection (via NetworkChecker)
   - Server status (via server-checking endpoint)
   - Makes HTTP request
   ↓
5. If error occurs:
   - Throws specific exception
   ↓
6. Repository catches and rethrows/wraps error
   ↓
7. ViewModel catches error:
   - Uses ErrorHandler.getUserFriendlyMessage()
   - Sets error state
   ↓
8. View displays error:
   - Shows ErrorDialog or Snackbar
   - Provides retry option
```

## Error Messages

### Network Errors
- **User sees**: "No internet connection. Please access google.com to check your connection."
- **Suggestions**:
  - Check WiFi/Mobile data
  - Access google.com to verify connection
  - Restart device if needed

### Server Errors
- **User sees**: "Server error. Access endpoint: server-checking to verify server status."
- **Suggestions**:
  - Wait a moment and try again
  - Access server-checking endpoint
  - Contact support if issue persists

### Authentication Errors
- **User sees**: "Session expired. Please login again."
- **Action**: Redirects to login screen

## Testing Network/Server Errors

### Test Network Error
1. Turn off WiFi and mobile data
2. Try to load dashboard
3. Should see network error dialog with suggestions

### Test Server Error
1. Ensure server is down or unreachable
2. Try to load dashboard
3. Should see server error dialog with suggestions

## Configuration

### Timeouts
```dart
// In http_service.dart
static const Duration _timeout = Duration(seconds: 30);
static const Duration _serverCheckTimeout = Duration(seconds: 5);
```

### Server Check Endpoint
The system checks server health via:
```
GET {baseUrl}server-checking
```

Expected response:
```json
{
  "success": true
}
```

## Best Practices

1. **Always use HttpService** instead of raw http package
2. **Catch specific exceptions** before general catch
3. **Use ErrorHandler.getUserFriendlyMessage()** in ViewModels
4. **Provide retry option** when showing errors
5. **Don't show technical errors** to users
6. **Log detailed errors** for debugging

## Future Improvements

- [ ] Add error logging service
- [ ] Track error frequency/patterns
- [ ] Add offline mode support
- [ ] Implement exponential backoff for retries
- [ ] Add error reporting to backend
