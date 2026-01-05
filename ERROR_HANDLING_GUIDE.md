# Error Handling Implementation Guide

## Overview
This project now includes a comprehensive error handling system that provides user-friendly error messages for different scenarios including network issues, server errors, and general exceptions.

## Components Created

### 1. Exception Classes (`lib/utils/exceptions.dart`)
Custom exception types for different error scenarios:
- `NetworkException` - No internet connection
- `ServerException` - Server errors (5xx)
- `ClientException` - Client errors (4xx)
- `UnauthorizedException` - Auth errors (401, 403)
- `TimeoutException` - Request timeouts
- `DataParseException` - JSON parsing errors
- `ValidationException` - Validation failures
- `NotFoundException` - Resource not found (404)

### 2. Network Checker (`lib/utils/network_checker.dart`)
Utility to check internet connectivity before making API calls.

### 3. Error Handler (`lib/utils/error_handler.dart`)
Centralized error processing that:
- Handles HTTP responses and throws appropriate exceptions
- Converts exceptions to user-friendly messages
- Logs errors for debugging

### 4. HTTP Service (`lib/services/http_service.dart`)
Wrapper around http package with built-in:
- Automatic network checking
- Error handling
- Timeout management
- Support for GET, POST, PUT, DELETE

### 5. Error UI Widgets (`lib/widgets/error_dialog.dart`)
Reusable components:
- `ErrorDialog` - Full-screen error dialog with retry option
- `ErrorSnackBar` - Bottom snackbar for non-critical errors

## Usage Examples

### In Repository Layer

```dart
import '../services/http_service.dart';
import '../utils/exceptions.dart';
import '../utils/error_handler.dart';

class MyRepository {
  Future<Data> fetchData() async {
    try {
      final response = await HttpService.get(
        url: 'https://api.example.com/data',
        headers: {'Authorization': 'Bearer $token'},
      );
      
      final data = json.decode(response.body);
      return Data.fromJson(data);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      rethrow; // Let ViewModel handle it
    }
  }
}
```

### In ViewModel Layer

```dart
import '../utils/error_handler.dart';

class MyViewModel extends ChangeNotifier {
  String? _errorMessage;
  bool _isLoading = false;
  
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  
  Future<void> loadData() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      final data = await _repository.fetchData();
      // Update state with data
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      _errorMessage = ErrorHandler.getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### In UI Layer - Option 1: Error Dialog

```dart
import '../widgets/error_dialog.dart';

class MyView extends StatelessWidget {
  Future<void> _loadData() async {
    final viewModel = context.read<MyViewModel>();
    await viewModel.loadData();
    
    if (mounted && viewModel.errorMessage != null) {
      ErrorDialog.show(
        context,
        message: viewModel.errorMessage!,
        onRetry: _loadData,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<MyViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return CircularProgressIndicator();
        }
        
        if (viewModel.errorMessage != null) {
          return ErrorStateWidget(
            message: viewModel.errorMessage!,
            onRetry: _loadData,
          );
        }
        
        return DataWidget(data: viewModel.data);
      },
    );
  }
}
```

### In UI Layer - Option 2: Error SnackBar

```dart
import '../widgets/error_dialog.dart';

Future<void> _loadData() async {
  final viewModel = context.read<MyViewModel>();
  await viewModel.loadData();
  
  if (mounted && viewModel.errorMessage != null) {
    ErrorSnackBar.show(
      context,
      message: viewModel.errorMessage!,
      duration: Duration(seconds: 5),
      onRetry: _loadData,
    );
  }
}
```

## Error Messages Users Will See

### Network Errors
- ✅ "No internet connection. Please check your network and try again."
- ✅ "Unable to connect to server. Please check your internet connection."
- ✅ "Request timeout. Please try again."

### Authentication Errors
- ✅ "Session expired. Please login again."
- ✅ "You do not have permission to access this resource."

### Server Errors
- ✅ "Server error occurred. Please try again later."

### Data Errors
- ✅ "Invalid data received. Please try again."
- ✅ "Failed to process data. Please try again."

### Other Errors
- ✅ "An unexpected error occurred. Please try again."

## Migration Guide

To update your existing repositories:

1. **Replace `http.get/post/put/delete` with `HttpService`**:
   ```dart
   // Before
   final response = await http.get(Uri.parse(url), headers: headers);
   
   // After
   final response = await HttpService.get(url: url, headers: headers);
   ```

2. **Use specific exceptions instead of generic Exception**:
   ```dart
   // Before
   throw Exception('User not found');
   
   // After
   throw UnauthorizedException(message: 'Session expired');
   ```

3. **Add error logging**:
   ```dart
   // Before
   catch (e) {
     print('Error: $e');
     rethrow;
   }
   
   // After
   catch (e, stackTrace) {
     ErrorHandler.logError(e, stackTrace);
     rethrow;
   }
   ```

4. **Update ViewModel error handling**:
   ```dart
   // Before
   _errorMessage = e.toString();
   
   // After
   _errorMessage = ErrorHandler.getErrorMessage(e);
   ```

5. **Update UI to show errors**:
   - Use `ErrorDialog` for critical errors
   - Use `ErrorSnackBar` for non-critical errors
   - Provide retry functionality

## Benefits

✅ **User-Friendly Messages** - Clear, actionable error messages
✅ **Consistent Handling** - Same pattern across the app
✅ **Better Debugging** - Structured error logging
✅ **Network Awareness** - Automatic connectivity checking
✅ **Type Safety** - Specific exception types
✅ **Maintainability** - Centralized error logic
✅ **Better UX** - Retry options for users

## Next Steps

1. Update all repositories to use `HttpService`
2. Replace generic exceptions with specific types
3. Update all ViewModels to use `ErrorHandler.getErrorMessage()`
4. Add error UI widgets to all views
5. Test different error scenarios
6. (Optional) Integrate crash reporting service like Firebase Crashlytics

## Testing Different Error Scenarios

```dart
// Test no internet
await NetworkChecker.checkConnectivity(); // Throws NetworkException

// Test timeout
HttpService.get(url: slowEndpoint); // Throws TimeoutException after 30s

// Test 401/403
HttpService.get(url: unauthorizedEndpoint); // Throws UnauthorizedException

// Test 5xx
HttpService.get(url: serverErrorEndpoint); // Throws ServerException
```
