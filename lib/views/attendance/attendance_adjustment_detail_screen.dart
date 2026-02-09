import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../constants/constant.dart';
import '../../models/attendance_adjustment_model.dart';
import '../../utils/file_helper.dart';
import '../../widgets/custom_alert_dialog.dart';
import '../../widgets/horizontal_approver_flow.dart';

class AttendanceAdjustmentDetailScreen extends StatefulWidget {
  final AttendanceMissing selectedAttendance;
  final String adjustmentType;
  final List<Approver> approvers;

  const AttendanceAdjustmentDetailScreen({
    super.key,
    required this.selectedAttendance,
    required this.adjustmentType,
    required this.approvers,
  });

  @override
  State<AttendanceAdjustmentDetailScreen> createState() =>
      _AttendanceAdjustmentDetailScreenState();
}

class _AttendanceAdjustmentDetailScreenState
    extends State<AttendanceAdjustmentDetailScreen> {
  final TextEditingController _reasonController = TextEditingController();
  String? _attachedFileName;
  XFile? documentPhoto;
  final ImagePicker _picker = ImagePicker();

  // ✅ File size limit constant
  static const int maxFileSizeInBytes = 5 * 1024 * 1024; // 5MB

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
        title: const Text('Adjustment Request'),
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
                    Text(
                      "${widget.selectedAttendance.dayOfWeek} ${widget.selectedAttendance.formattedDate}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                widget.adjustmentType,
                style: TextStyle(color: primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeInfo(
                  'Check In',
                  FileHelper().formatTime(widget.selectedAttendance.checkedIn),
                  Icons.login,
                  Colors.green,
                ),
                _buildTimeInfo(
                  'Check Out',
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
              const Text(
                'Reason *',
                style: TextStyle(
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
              hintText:
                  'Please provide a detailed reason for your adjustment request...',
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
              const Text(
                'Attachment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                'Optional',
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
                      'Upload Photo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to select photo from camera or gallery',
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
              const Text(
                'Approvers',
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
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitRequest : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey[300],
          elevation: 0,
        ),
        child: const Text(
          'Submit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                        CircularProgressIndicator(),
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
                      const Text(
                        "Select Photo Source",
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
                    title: const Text(
                      "Camera",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      "Take a new photo",
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
                    title: const Text(
                      "Gallery",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      "Choose from photos",
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
                      title: const Text(
                        "Remove Photo",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        "Clear selected photo",
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => documentPhoto = null);
                        _showSnackBar(
                          "Photo removed",
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
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Request'),
            content: Text(
              'Submit adjustment request for ${widget.selectedAttendance.formattedDate}?\n'
              'Type: ${widget.adjustmentType}\n\n'
              'Reason: ${_reasonController.text.trim()}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: primary),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) =>
                const Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pop(context); // Close loading dialog

    // Show success dialog
    if (mounted) {
      await CustomAlertDialog.show(
        context,
        title: 'Success',
        message:
            'Your attendance adjustment request has been submitted successfully',
        icon: Icons.check_circle,
        iconColor: Colors.green,
        primaryButtonText: 'OK',
        onPrimaryPressed: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(true); // Return success to main screen
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
