import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../constants/constant.dart';
import '../../../repositories/leave_request_repository.dart';
import '../../../models/leave_type_model.dart';
import '../../../models/approver_model.dart';
import '../../../localization/language.dart';
import '../../../localization/language_logic.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final LeaveRequestRepository _repository = LeaveRequestRepository();
  Language language = Language();

  // ✅ File size limit constant
  static const int maxFileSizeInBytes = 5 * 1024 * 1024; // 5MB

  // Backend data
  List<LeaveTypeModel> leaveTypes = [];
  List<ApproverModel> approvers = [];
  List<String> holidays = [];
  String userId = '';
  bool isLoading = true;
  String? errorMessage;

  // Form fields
  LeaveTypeModel? selectedLeaveType;
  DateTimeRange? leaveDateRange;
  String leaveFor = 'Full Day';
  String halfDaySession = 'Morning';
  String reason = '';
  String? approver;
  String? documentSupport;
  XFile? documentPhoto;

  // Submission state
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeLanguage();
    _fetchLeaveRequestData();
  }

  Future<void> _initializeLanguage() async {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    if (mounted) {
      setState(() {
        language = languageLogic.language;
      });
    }
  }

  Future<void> _fetchLeaveRequestData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final data = await _repository.getLeaveRequestData();

      setState(() {
        leaveTypes = data.leaveTypes;
        approvers = data.approvers;
        holidays = data.holidays;
        userId = data.userId;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  List<ApproverModel> get sortedApprovers {
    final sorted = [...approvers];
    sorted.sort((a, b) => a.approvalLevel.compareTo(b.approvalLevel));
    return sorted;
  }

  double get totalLeaveDays {
    if (leaveDateRange != null) {
      // Calculate working days excluding weekends and holidays
      int workingDays = 0;
      DateTime current = leaveDateRange!.start;

      while (current.isBefore(
        leaveDateRange!.end.add(const Duration(days: 1)),
      )) {
        // Skip weekends (Saturday = 6, Sunday = 7)
        if (current.weekday != DateTime.saturday &&
            current.weekday != DateTime.sunday) {
          // Skip holidays
          String dateString = current.toIso8601String().split('T')[0];
          if (!holidays.contains(dateString)) {
            workingDays++;
          }
        }
        current = current.add(const Duration(days: 1));
      }

      if (leaveFor == 'Half Day') {
        if (workingDays == 1) return 0.5;
        if (workingDays == 2) return 1.5; // 0.5 (first) + 1.0 (second)
        // For >2 days: 0.5 (first) + full for days 2..n
        return 0.5 + (workingDays - 1);
      }
      return workingDays.toDouble();
    }
    return 0;
  }

  String get leaveDateLabel {
    if (leaveDateRange == null) return language.selectDateRange;
    final start = DateFormat('yyyy-MM-dd').format(leaveDateRange!.start);
    final end = DateFormat('yyyy-MM-dd').format(leaveDateRange!.end);
    return start == end ? start : '$start to $end';
  }

  // FIXED: Updated helper function to format approvers correctly
  List<Map<String, dynamic>> get formattedApprovers {
    final uniqueApprovers = <String, ApproverModel>{};

    // Remove duplicates based on approverId
    for (var approver in sortedApprovers) {
      uniqueApprovers[approver.approverId.toString()] = approver;
    }

    final result =
        uniqueApprovers.values.map((approver) {
          return {
            "eid": approver.approverId.toString(),
            "applev": approver.approvalLevel,
            "prio": approver.approvalLevel,
          };
        }).toList();

    // Debug: Print formatted approvers
    print('=== DEBUG: FORMATTED APPROVERS ===');
    print('Number of formatted approvers: ${result.length}');
    for (var approver in result) {
      print('Formatted: ${approver}');
    }
    print('=== END FORMATTED DEBUG ===');

    return result;
  }

  // Add helper function to convert leave_for to integer
  int get leaveForValue {
    return leaveFor == 'Full Day' ? 1 : 0; // 1 for Full Day, 0 for Half Day
  }

  // Updated submit function with better debugging
  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if document is required but not provided
    if ((selectedLeaveType?.requiresDocument ?? false) &&
        documentPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(language.documentSupportRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate file if provided
    if (documentPhoto != null) {
      final file = File(documentPhoto!.path);

      // Check if file exists
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(language.selectedFileNotExist),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate file type
      if (!_repository.isValidImageFile(file)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(language.pleaseSelectValidImageFile),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate file size
      if (!await _repository.isValidFileSize(file)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(language.fileSizeTooLarge),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      setState(() {
        isSubmitting = true;
      });

      // Format dates
      final fromDate = DateFormat('yyyy-MM-dd').format(leaveDateRange!.start);
      final toDate = DateFormat('yyyy-MM-dd').format(leaveDateRange!.end);

      // Prepare file for upload
      File? fileToUpload;
      if (documentPhoto != null) {
        fileToUpload = File(documentPhoto!.path);
      }
      // Submit leave request with file
      final response = await _repository.submitLeaveRequest(
        leaveType: selectedLeaveType!.leaid,
        fromDate: fromDate,
        toDate: toDate,
        reason: reason.trim(),
        leaveFor: leaveForValue,
        halfDaySession: halfDaySession,
        totalLeave: totalLeaveDays,
        approvers: formattedApprovers,
        file: fileToUpload,
      );

      if (response.success && mounted) {
        // Show simple success dialog
        await _showSuccessDialog(response.message);
      } else if (mounted) {
        // Handle failed response from backend (success: false)
        await _showErrorDialog(response.message);
      }
    } catch (e) {
      if (mounted) {
        // Extract the actual error message from the exception
        String errorMessage = e.toString();

        // Remove "Exception: " prefix if present
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        // Remove "Error submitting leave request: " prefix if present
        if (errorMessage.startsWith('Error submitting leave request: ')) {
          errorMessage = errorMessage.substring(33);
        }

        // Show the cleaned error message
        await _showErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // Simple success dialog with backend message and OK button
  Future<void> _showSuccessDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),

              // Success Title
              Text(
                language.success,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(true); // Return to home/dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  language.ok,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Simple error dialog
  Future<void> _showErrorDialog(String errorMessage) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),

              // Error Title
              Text(
                language.requestFailed,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Error Message
              Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      language.cancel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _submitLeaveRequest();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      language.retry,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ✅ Image picker with progressive compression
  Future<void> _pickAndValidateImage(ImageSource source) async {
    try {
      // Check camera permission before proceeding (only for camera, not photos)
      // iOS 14+ uses PHPicker for photos which doesn't require explicit permissions
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.status;

        // If camera permission is permanently denied, show settings guidance
        if (cameraStatus.isPermanentlyDenied) {
          _showSettingsGuidanceDialog('Camera');
          return;
        }
      }
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(language.processingImage),
                      ],
                    ),
                  ),
                ),
              ),
        );
      }

      final picker = ImagePicker();
      XFile? pickedFile;
      int? finalFileSize;
      int imageQuality = 85;
      int maxDimension = 1920;

      // Progressive compression strategy
      while (imageQuality >= 50 && maxDimension >= 1024) {
        pickedFile = await picker.pickImage(
          source: source,
          maxWidth: maxDimension.toDouble(),
          maxHeight: maxDimension.toDouble(),
          imageQuality: imageQuality,
        );

        if (pickedFile == null) {
          if (mounted) Navigator.pop(context);
          return;
        }

        final file = File(pickedFile.path);
        finalFileSize = await file.length();

        print(
          '📁 Attempt with quality $imageQuality, dimension $maxDimension: ${(finalFileSize / 1024 / 1024).toStringAsFixed(2)} MB',
        );

        if (finalFileSize <= maxFileSizeInBytes) {
          print(
            '✅ File size acceptable: ${(finalFileSize / 1024 / 1024).toStringAsFixed(2)} MB',
          );
          break;
        }

        if (imageQuality > 50) {
          imageQuality -= 15;
        } else if (maxDimension > 1024) {
          maxDimension = (maxDimension * 0.8).toInt();
          imageQuality = 85;
        } else {
          break;
        }
      }

      if (pickedFile == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final file = File(pickedFile.path);
      finalFileSize = await file.length();

      if (finalFileSize > maxFileSizeInBytes) {
        if (mounted) Navigator.pop(context);
        _showSnackBar(
          "${language.fileTooLarge} (${(finalFileSize / 1024 / 1024).toStringAsFixed(1)} MB). ${language.maxSize}",
          Colors.red,
          Icons.error_outline,
        );
        return;
      }

      if (mounted) {
        Navigator.pop(context);
        setState(() => documentPhoto = pickedFile);

        final sizeInKB = (finalFileSize / 1024).toStringAsFixed(0);
        final sizeInMB = (finalFileSize / 1024 / 1024).toStringAsFixed(1);

        _showSnackBar(
          "${language.photoSelected} (${finalFileSize > 1024 * 1024 ? '$sizeInMB MB' : '$sizeInKB KB'})",
          Colors.green,
          Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

        // Handle camera permission errors specifically
        if (source == ImageSource.camera) {
          final cameraStatus = await Permission.camera.status;

          if (cameraStatus.isPermanentlyDenied) {
            _showSettingsGuidanceDialog('Camera');
            return;
          } else if (cameraStatus.isDenied) {
            _showSnackBar(
              'Camera access is needed to use this feature. Please try again and allow access.',
              Colors.orange,
              Icons.warning_amber,
            );
            return;
          }
        }

        // Other errors (network, file issues, etc.)
        _showSnackBar(
          "Error: ${e.toString()}",
          Colors.red,
          Icons.error_outline,
        );
      }
      print('❌ Error picking image: $e');
    }
  }

  // ✅ Add this helper method for consistent snackbars:
  void _showSnackBar(String message, Color backgroundColor, IconData icon) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ✅ Settings guidance dialog for permanently denied permissions
  void _showSettingsGuidanceDialog(String permissionType) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('$permissionType Access Required'),
            content: Text(
              'This feature requires $permissionType access. You have previously denied this permission.\n\nTo enable it, please go to Settings > CHOKCHEY and allow $permissionType access.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Not Now'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  // ✅ Replace the _showImagePicker method with this improved version:
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        language.selectPhotoSource,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.blue),
                    ),
                    title: Text(
                      language.camera,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      language.takeANewPhoto,
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndValidateImage(ImageSource.camera);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Colors.green,
                      ),
                    ),
                    title: Text(
                      language.gallery,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      language.chooseFromPhotos,
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndValidateImage(ImageSource.gallery);
                    },
                  ),
                  if (documentPhoto != null) ...[
                    const Divider(),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.red),
                      ),
                      title: Text(
                        language.removePhoto,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        language.clearSelectedPhoto,
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => documentPhoto = null);
                        _showSnackBar(
                          language.photoRemoved,
                          Colors.orange,
                          Icons.delete,
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Max file size: 5MB\nImages will be compressed to fit",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.leaveRequest),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primary),
                    SizedBox(height: 16),
                    Text(language.loadingLeaveRequestData),
                  ],
                ),
              )
              : errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      language.errorLoadingData,
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchLeaveRequestData,
                      child: Text(language.retry),
                    ),
                  ],
                ),
              )
              : SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    final horizontalPadding = isWide ? 80.0 : 18.0;
                    final cardPadding = isWide ? 32.0 : 18.0;
                    final fontSizeLabel = isWide ? 18.0 : 15.0;
                    final imageSize = isWide ? 80.0 : 48.0;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 18,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: cardPadding,
                                  vertical: cardPadding + 6,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Leave Type
                                    Row(
                                      children: [
                                        Icon(Icons.category, color: primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          language.leaveType,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: fontSizeLabel,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: selectedLeaveType?.leaid,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                        hintText: language.selectLeaveType,
                                      ),
                                      isExpanded: true,
                                      items:
                                          leaveTypes.map((leaveType) {
                                            return DropdownMenuItem(
                                              value: leaveType.leaid,
                                              child: Text(
                                                leaveType.ltyp,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (leaid) {
                                        setState(() {
                                          selectedLeaveType = leaveTypes
                                              .firstWhere(
                                                (type) => type.leaid == leaid,
                                              );
                                          // Clear document photo if new leave type doesn't require document
                                          if (!(selectedLeaveType
                                                  ?.requiresDocument ??
                                              false)) {
                                            documentPhoto = null;
                                          }
                                        });
                                      },
                                      validator:
                                          (val) =>
                                              val == null
                                                  ? language
                                                      .pleaseSelectLeaveType
                                                  : null,
                                    ),
                                    SizedBox(height: isWide ? 24 : 18),

                                    // Leave Date Range
                                    Row(
                                      children: [
                                        Icon(Icons.date_range, color: primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          language.leaveDate,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: fontSizeLabel,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () async {
                                        final picked =
                                            await showDateRangePicker(
                                              context: context,
                                              firstDate: DateTime.now()
                                                  .subtract(
                                                    const Duration(days: 365),
                                                  ),
                                              lastDate: DateTime.now().add(
                                                const Duration(days: 365),
                                              ),
                                              initialDateRange: leaveDateRange,
                                            );
                                        if (picked != null) {
                                          setState(
                                            () => leaveDateRange = picked,
                                          );
                                        }
                                      },
                                      child: AbsorbPointer(
                                        child: TextFormField(
                                          readOnly: true,
                                          decoration: InputDecoration(
                                            hintText: language.selectDateRange,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                            suffixIcon: const Icon(
                                              Icons.calendar_today,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: isWide ? 16 : 10,
                                                ),
                                          ),
                                          controller: TextEditingController(
                                            text: leaveDateLabel,
                                          ),
                                          validator:
                                              (_) =>
                                                  leaveDateRange == null
                                                      ? language
                                                          .pleaseSelectLeaveDate
                                                      : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Total Leave Days - Updated calculation
                                    if (leaveDateRange != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calculate,
                                              color: primary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "Total Leave: ",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: secondary,
                                                fontSize: fontSizeLabel,
                                              ),
                                            ),
                                            Chip(
                                              backgroundColor: primary
                                                  .withOpacity(0.1),
                                              label: Text(
                                                "${totalLeaveDays % 1 == 0 ? totalLeaveDays.toInt() : totalLeaveDays} ${totalLeaveDays > 1 ? language.days : language.day}",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: primary,
                                                  fontSize: isWide ? 18 : 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Leave For
                                    Row(
                                      children: [
                                        Icon(Icons.timelapse, color: primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          language.leaveFor,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: fontSizeLabel,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: RadioListTile<String>(
                                            title: Text(language.fullDay),
                                            value: 'Full Day',
                                            groupValue: leaveFor,
                                            onChanged:
                                                (val) => setState(
                                                  () => leaveFor = val!,
                                                ),
                                          ),
                                        ),
                                        Expanded(
                                          child: RadioListTile<String>(
                                            title: Text(language.halfDay),
                                            value: 'Half Day',
                                            groupValue: leaveFor,
                                            onChanged:
                                                (val) => setState(
                                                  () => leaveFor = val!,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Half Day Session
                                    if (leaveFor == 'Half Day') ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.wb_sunny, color: primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            language.leaveNote,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: fontSizeLabel,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: RadioListTile<String>(
                                              title: Text(language.morning),
                                              value: 'Morning',
                                              groupValue: halfDaySession,
                                              onChanged:
                                                  (val) => setState(
                                                    () => halfDaySession = val!,
                                                  ),
                                            ),
                                          ),
                                          Expanded(
                                            child: RadioListTile<String>(
                                              title: Text(language.afternoon),
                                              value: 'Afternoon',
                                              groupValue: halfDaySession,
                                              onChanged:
                                                  (val) => setState(
                                                    () => halfDaySession = val!,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    SizedBox(height: isWide ? 24 : 18),

                                    // Reason
                                    Row(
                                      children: [
                                        Icon(Icons.edit_note, color: primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          language.reason,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: fontSizeLabel,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        hintText: language.enterYourReason,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: isWide ? 16 : 10,
                                        ),
                                      ),
                                      onChanged: (val) => reason = val,
                                      validator:
                                          (val) =>
                                              val == null || val.isEmpty
                                                  ? language.pleaseEnterReason
                                                  : null,
                                    ),
                                    SizedBox(height: isWide ? 24 : 18),

                                    // Document Support
                                    if (selectedLeaveType?.requiresDocument ??
                                        false) ...[
                                      SizedBox(height: isWide ? 24 : 18),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.attach_file,
                                            color: primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            language.documentSupport,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: fontSizeLabel,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (selectedLeaveType?.fileUrl !=
                                              null)
                                            TextButton.icon(
                                              icon: const Icon(
                                                Icons.visibility,
                                              ),
                                              label: Text(language.viewSample),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (context) => AlertDialog(
                                                        title: Text(
                                                          language
                                                              .sampleDocument,
                                                        ),
                                                        content: Image.network(
                                                          selectedLeaveType!
                                                              .fileUrl!,
                                                          fit: BoxFit.contain,
                                                          width:
                                                              isWide
                                                                  ? 350
                                                                  : 250,
                                                          height:
                                                              isWide
                                                                  ? 400
                                                                  : 300,
                                                          errorBuilder: (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons.error,
                                                                  size: 64,
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                                SizedBox(
                                                                  height: 8,
                                                                ),
                                                                Text(
                                                                  language
                                                                      .failedToLoadSampleDocument,
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                    ),
                                                            child: Text(
                                                              language.close,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                                documentPhoto == null
                                                    ? Text(
                                                      language.noPhotoSelected,
                                                      style: TextStyle(
                                                        color: Colors.black54,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        fontSize:
                                                            isWide ? 16 : 14,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    )
                                                    : Row(
                                                      children: [
                                                        Image.file(
                                                          File(
                                                            documentPhoto!.path,
                                                          ),
                                                          width: imageSize,
                                                          height: imageSize,
                                                          fit: BoxFit.cover,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          language
                                                              .photoSelected,
                                                          style: TextStyle(
                                                            color: Colors.green,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize:
                                                                isWide
                                                                    ? 16
                                                                    : 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                          ),
                                          TextButton.icon(
                                            icon: const Icon(Icons.upload_file),
                                            label: Text(language.uploadPhoto),
                                            onPressed: () => _showImagePicker(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // Approvers - Updated to use backend data
                                    if (approvers.isNotEmpty)
                                      Card(
                                        color: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: isWide ? 18 : 14,
                                            horizontal: isWide ? 18 : 12,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.supervisor_account,
                                                    color: primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    language.approvers,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize:
                                                          isWide ? 19 : 17,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              ...sortedApprovers.asMap().entries.map(
                                                (entry) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 8,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        backgroundColor: primary
                                                            .withOpacity(0.15),
                                                        radius:
                                                            isWide ? 22 : 18,
                                                        child: Text(
                                                          (entry.key + 1)
                                                              .toString(),
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    secondary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              entry.value.dname,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    isWide
                                                                        ? 18
                                                                        : 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    Colors
                                                                        .black87,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              entry
                                                                  .value
                                                                  .approverLevelName,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    isWide
                                                                        ? 15
                                                                        : 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color:
                                                                    Colors
                                                                        .black54,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    SizedBox(height: isWide ? 32 : 18),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isWide ? 32 : 18),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isWide ? 20 : 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: isWide ? 20 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  elevation: 1,
                                ),
                                icon:
                                    isSubmitting
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Icon(Icons.send),
                                label: Text(
                                  isSubmitting
                                      ? language.submitting
                                      : language.submit,
                                ),
                                onPressed:
                                    isSubmitting ? null : _submitLeaveRequest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
