import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/constant.dart';
import '../../models/attendance_adjustment_model.dart';
import '../../repositories/attendance_repository.dart';
import '../../utils/file_helper.dart';
import '../../widgets/custom_alert_dialog.dart';
import '../../widgets/horizontal_approver_flow.dart';
import '../../widgets/date_section.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';

class RequestAttendanceAdjustmentScreen extends StatefulWidget {
  final AttendanceMissing selectedAttendance;
  final String adjustmentType;
  final List<Approver> approvers;

  const RequestAttendanceAdjustmentScreen({
    super.key,
    required this.selectedAttendance,
    required this.adjustmentType,
    required this.approvers,
  });

  @override
  State<RequestAttendanceAdjustmentScreen> createState() =>
      _RequestAttendanceAdjustmentScreenState();
}

class _RequestAttendanceAdjustmentScreenState
    extends State<RequestAttendanceAdjustmentScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  XFile? documentPhoto;
  Language language = Language();

  // ✅ File size limit constant
  static const int maxFileSizeInBytes = 5 * 1024 * 1024; // 5MB

  @override
  void initState() {
    super.initState();
    _initializeLanguage();
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

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(language.adjustmentRequest),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildDateCard(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildReasonSection(),
                  const SizedBox(height: 16),
                  _buildAttachmentSection(),
                  const SizedBox(height: 16),
                  _buildApproversSection(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(.04),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: primary, size: 20),
                    const SizedBox(width: 6),
                    DateSection(
                      date:
                          DateTime.tryParse(widget.selectedAttendance.date) ??
                          DateTime.now(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  widget.adjustmentType,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeInfo(
                  language.checkIn,
                  FileHelper().formatTime(widget.selectedAttendance.checkedIn),
                  Icons.login,
                  Colors.green,
                ),
                _buildTimeInfo(
                  language.checkOut,
                  FileHelper().formatTime(widget.selectedAttendance.checkedOut),
                  Icons.logout,
                  Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: primary, size: 24),
              const SizedBox(width: 12),
              Text(
                language.reasonRequired,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: language.provideDetailedReason,
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primary, width: 1),
              ),
            ),
            style: const TextStyle(fontSize: 16),
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, color: primary, size: 24),
              const SizedBox(width: 12),
              Text(
                language.attachment,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                language.optional,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (documentPhoto == null) ...[
            GestureDetector(
              onTap: _showImagePicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 30,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      language.uploadPhoto,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      language.tapToSelectPhoto,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Photo selected',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ready to submit',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showImagePicker,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Change'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(documentPhoto!.path),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApproversSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: primary, size: 24),
              const SizedBox(width: 12),
              Text(
                language.approvers,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (widget.approvers.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No approvers assigned',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            )
          else
            VerticalApproverFlow(
              approvers:
                  widget.approvers
                      .map(
                        (approver) => ApproverData(
                          name: approver.dname,
                          level: approver.approvalLevel,
                        ),
                      )
                      .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _reasonController.text.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow:
            canSubmit
                ? [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                : null,
      ),
      child: ElevatedButton.icon(
        onPressed: canSubmit ? _submitRequest : null,
        icon: Icon(
          Icons.send_rounded,
          size: 20,
          color: canSubmit ? Colors.white : Colors.grey[500],
        ),
        label: Text(
          language.submitRequest,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: canSubmit ? Colors.white : Colors.grey[500],
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? primary : Colors.grey[300],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canSubmit ? 4 : 0,
          disabledBackgroundColor: Colors.grey[300],
          animationDuration: const Duration(milliseconds: 200),
        ),
      ),
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
              (context) => const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SpinKitFadingCircle(color: primary),
                        SizedBox(height: 16),
                        Text("Processing image..."),
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

      // Progressive compression strategy with iOS error handling
      while (imageQuality >= 50 && maxDimension >= 1024) {
        try {
          pickedFile = await picker.pickImage(
            source: source,
            maxWidth: maxDimension.toDouble(),
            maxHeight: maxDimension.toDouble(),
            imageQuality: imageQuality,
            // Add iOS specific options to handle iCloud and format issues
            requestFullMetadata: false, // Reduces iOS conflicts
          );

          if (pickedFile == null) {
            if (mounted) Navigator.pop(context);
            return;
          }

          // Verify file exists and is accessible before proceeding
          final file = File(pickedFile.path);

          // Check if file exists (important for iOS iCloud images)
          if (!await file.exists()) {
            // Retry with different quality settings for iCloud images
            if (imageQuality > 50) {
              imageQuality -= 15;
              continue;
            } else {
              throw Exception(
                'Selected image is not available. Please ensure the image is downloaded from iCloud.',
              );
            }
          }

          finalFileSize = await file.length();

          if (finalFileSize <= maxFileSizeInBytes) {
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
        } catch (compressionError) {
          // If it's an iOS format error, try with different settings
          if (compressionError.toString().contains('invalid_image') ||
              compressionError.toString().contains(
                'Cannot load representation',
              )) {
            // Try fallback approach with minimal processing
            try {
              pickedFile = await picker.pickImage(
                source: source,
                imageQuality: 100, // Use original quality
                requestFullMetadata: false,
              );

              if (pickedFile != null) {
                final file = File(pickedFile.path);
                if (await file.exists()) {
                  finalFileSize = await file.length();

                  // Accept the image even if it's larger, we'll handle it
                  if (finalFileSize <= maxFileSizeInBytes * 2) {
                    // Allow up to 10MB as fallback
                    print('✅ Fallback image selection successful');
                    break;
                  }
                }
              }
              // ignore: empty_catches
            } catch (fallbackError) {}
          }

          // If all attempts fail, break and handle error
          if (imageQuality <= 50 && maxDimension <= 1024) {
            rethrow;
          }

          // Try next iteration with lower quality
          if (imageQuality > 50) {
            imageQuality -= 15;
          } else if (maxDimension > 1024) {
            maxDimension = (maxDimension * 0.8).toInt();
            imageQuality = 85;
          } else {
            rethrow;
          }
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
          "File too large (${(finalFileSize / 1024 / 1024).toStringAsFixed(1)} MB). Max: 5MB\nPlease choose a smaller image.",
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
          "Photo selected (${finalFileSize > 1024 * 1024 ? '$sizeInMB MB' : '$sizeInKB KB'})",
          Colors.green,
          Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

        // Handle specific iOS image picker errors
        String errorMessage;
        if (e.toString().contains('invalid_image') ||
            e.toString().contains('Cannot load representation')) {
          errorMessage =
              'Unable to load the selected image.\n\n'
              'This often happens with:\n'
              '• Images stored in iCloud that aren\'t fully downloaded\n'
              '• Certain image formats or sources\n\n'
              'Try:\n'
              '• Selecting a different image\n'
              '• Using the camera instead\n'
              '• Ensuring iCloud images are downloaded';
        } else if (e.toString().contains('Selected image is not available')) {
          errorMessage =
              'The selected image isn\'t available on this device.\n\n'
              'Please ensure iCloud images are fully downloaded or select a different image.';
        } else if (source == ImageSource.camera) {
          // Handle camera permission errors specifically
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
          } else {
            errorMessage = 'Camera error: ${e.toString()}';
          }
        } else {
          // Other errors
          errorMessage = 'Error selecting image: ${e.toString()}';
        }

        _showSnackBar(errorMessage, Colors.red, Icons.error_outline);
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
                      language.takeNewPhoto,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      language.takeNewPhoto,
                      style: const TextStyle(fontSize: 12),
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
                      language.chooseFromGallery,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      language.takeFromPhoto,
                      style: const TextStyle(fontSize: 12),
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
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        language.clearSelectedPhoto,
                        style: const TextStyle(fontSize: 12),
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
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _submitRequest() async {
    if (_reasonController.text.trim().isEmpty) {
      _showSnackBar(
        'Please provide a reason for the adjustment request',
        Colors.red,
        Icons.error_outline,
      );
      return;
    }

    // Show professional confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Icon(
                      Icons.assignment_turned_in_rounded,
                      size: 32,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  const Text(
                    'Confirm Request',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please review your request details before submitting',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Request details card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.selectedAttendance.formattedDate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: primary),
                            const SizedBox(width: 8),
                            Text(
                              'Adjustment Type',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.adjustmentType,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.edit_note, size: 16, color: primary),
                            const SizedBox(width: 8),
                            Text(
                              'Reason',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _reasonController.text.trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        if (documentPhoto != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.attach_file, size: 16, color: primary),
                              const SizedBox(width: 8),
                              Text(
                                'Attachment',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Photo attached',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (confirmed != true) return;

    // Show professional loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const SpinKitFadingCircle(color: primary),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Submitting Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait while we process your adjustment request',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
      );
    }

    try {
      // Format approvers list with approver_id and priority
      final approvers =
          widget.approvers
              .map(
                (approver) => {
                  'approver_id': approver.approverId,
                  'priority': approver.approvalLevel,
                },
              )
              .toList();

      // Call the API
      final response = await _attendanceRepository.submitAdjustmentRequest(
        dateScan: widget.selectedAttendance.formattedDate,
        adjustType: widget.adjustmentType,
        reason: _reasonController.text.trim(),
        approvers: approvers,
        attachmentImage: documentPhoto,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Check if the response indicates success
      final success = response['success'] ?? false;
      final message =
          response['message'] ??
          (success
              ? 'Request submitted successfully'
              : 'Failed to submit request');

      if (success) {
        // Show success dialog
        await CustomAlertDialog.show(
          context,
          title: 'Success',
          message: message,
          icon: Icons.check_circle,
          iconColor: Colors.green,
          primaryButtonText: 'OK',
          onPrimaryPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(true); // Return success to main screen
          },
        );
      } else {
        // Show error dialog
        await CustomAlertDialog.show(
          context,
          title: 'Error',
          message: message,
          icon: Icons.error,
          iconColor: Colors.red,
          primaryButtonText: 'OK',
          onPrimaryPressed: () {
            Navigator.of(context).pop();
          },
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Extract meaningful error message
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      // Show error dialog
      await CustomAlertDialog.show(
        context,
        title: 'Error',
        message: errorMessage,
        icon: Icons.error,
        iconColor: Colors.red,
        primaryButtonText: 'OK',
        onPrimaryPressed: () {
          Navigator.of(context).pop();
        },
      );
    }
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
