# Error Handling - Quick Reference

## 1. Check Internet Connection

```dart
// Simple check
bool hasInternet = await NetworkChecker.hasConnection();

// Throw exception if no connection (use before API calls)
await NetworkChecker.checkConnectivity();

// Check specific server
bool canReach = await NetworkChecker.canReachHost('your-api.com');

// Get connection type
String type = await NetworkChecker.getConnectionType(); // "WiFi", "Mobile Data"
```

## 2. In Your Repository

```dart
class YourRepository extends BaseRepository {
  Future<Data> fetchData(String token) async {
    // This handles: connection check, HTTP errors, timeout, exceptions
    final response = await makeApiCallWithTimeout(
      () => http.get(
        Uri.parse('$baseUrl/endpoint'),
        headers: {'Authorization': 'Bearer $token'},
      ),
      timeout: Duration(seconds: 30),
      errorContext: 'fetching data',
    );
    
    return Data.fromJson(jsonDecode(response.body));
  }
}
```

## 3. In Your Screen/View

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  
  try {
    final data = await repository.getData();
    if (!mounted) return;
    setState(() {
      _data = data;
      _isLoading = false;
    });
  } catch (error) {
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    // Show error with retry
    await ErrorDisplayService.showError(
      context,
      error: error,
      onRetry: _loadData,
    );
  }
}
```

## 4. Before Upload/Download

```dart
Future<void> _uploadFile(File file) async {
  // Check connection first
  final hasConnection = await NetworkChecker.hasConnection();
  if (!hasConnection) {
    if (!mounted) return;
    await ErrorDisplayService.showNetworkError(
      context,
      onRetry: () => _uploadFile(file),
    );
    return;
  }
  
  // Proceed with upload...
}
```

## 5. Common Scenarios

### Show Network Error
```dart
await ErrorDisplayService.showNetworkError(
  context,
  onRetry: () => _loadData(),
);
```

### Show Server Error
```dart
await ErrorDisplayService.showServerError(
  context,
  onRetry: () => _submitForm(),
);
```

### Show Success
```dart
await ErrorDisplayService.showSuccess(
  context,
  title: 'Success',
  message: 'Data saved successfully',
);
```

### Show Confirmation
```dart
final confirmed = await ErrorDisplayService.showConfirmation(
  context,
  title: 'Delete Item',
  message: 'Are you sure?',
  confirmText: 'Delete',
  type: DialogType.warning,
);

if (confirmed) {
  // Proceed with delete
}
```

### Session Expired
```dart
await ErrorDisplayService.showSessionExpiredError(
  context,
  onLogin: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  },
);
```

## 6. Listen to Connectivity Changes

```dart
@override
void initState() {
  super.initState();
  
  NetworkChecker.onConnectivityChanged.listen((result) {
    if (!result.contains(ConnectivityResult.none)) {
      // Connection restored
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection restored')),
      );
    }
  });
}
```

## 7. Custom Error Messages

```dart
await ErrorDisplayService.showError(
  context,
  error: error,
  customTitle: 'Upload Failed',
  customMessage: 'Unable to upload the file. Please try again.',
  onRetry: () => _uploadFile(),
);
```

## Error Types & When to Use

- `NetworkException` - No internet
- `ServerException` - Server down (5xx)
- `UnauthorizedException` - Session expired (401, 403)
- `TimeoutException` - Request timeout
- `ValidationException` - Form validation
- `NotFoundException` - Resource not found (404)
- `DataParseException` - JSON parsing error
