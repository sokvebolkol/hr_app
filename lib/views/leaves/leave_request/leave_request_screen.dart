import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../constants/constant.dart';
import '../../../localization/language.dart';
import '../../../localization/language_logic.dart';
import '../../../viewmodels/leave_request_viewmodel.dart';

class LeaveRequestScreen extends StatelessWidget {
  const LeaveRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LeaveRequestViewModel(),
      child: const _LeaveRequestBody(),
    );
  }
}

class _LeaveRequestBody extends StatefulWidget {
  const _LeaveRequestBody();

  @override
  State<_LeaveRequestBody> createState() => _LeaveRequestBodyState();
}

class _LeaveRequestBodyState extends State<_LeaveRequestBody> {
  final _formKey = GlobalKey<FormState>();
  Language language = Language();

  // Pure UI state — not part of business logic
  double _height = 100;

  // File size limit constant
  static const int maxFileSizeInBytes = 5 * 1024 * 1024; // 5 MB

  @override
  void initState() {
    super.initState();
    _initializeLanguage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveRequestViewModel>().fetchLeaveRequestData();
    });
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

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submitLeaveRequest() async {
    final vm = context.read<LeaveRequestViewModel>();

    if (!_formKey.currentState!.validate()) return;

    // Document required but not provided
    if ((vm.selectedLeaveType?.requiresDocument ?? false) &&
        vm.documentPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(language.documentSupportRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate file if provided
    if (vm.documentPhoto != null) {
      final file = File(vm.documentPhoto!.path);

      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(language.selectedFileNotExist),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!vm.isValidImageFile(file)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(language.pleaseSelectValidImageFile),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!await vm.isValidFileSize(file)) {
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
      final response = await vm.submitLeaveRequest();
      if (!mounted) return;

      if (response.success) {
        await _showSuccessDialog(response.message);
      } else {
        await _showErrorDialog(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      if (errorMessage.startsWith('Error submitting leave request: ')) {
        errorMessage = errorMessage.substring(33);
      }
      await _showErrorDialog(errorMessage);
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

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickAndValidateImage(ImageSource source) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final vm = context.read<LeaveRequestViewModel>();

    try {
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.status;
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
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

        if (finalFileSize <= maxFileSizeInBytes) break;

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
          messenger: scaffoldMessenger,
        );
        return;
      }

      if (mounted) {
        Navigator.pop(context);
        vm.setDocumentPhoto(pickedFile);

        final sizeInKB = (finalFileSize / 1024).toStringAsFixed(0);
        final sizeInMB = (finalFileSize / 1024 / 1024).toStringAsFixed(1);

        _showSnackBar(
          "${language.photoSelected} (${finalFileSize > 1024 * 1024 ? '$sizeInMB MB' : '$sizeInKB KB'})",
          Colors.green,
          Icons.check_circle,
          messenger: scaffoldMessenger,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

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
              messenger: scaffoldMessenger,
            );
            return;
          }
        }

        _showSnackBar(
          "Error: ${e.toString()}",
          Colors.red,
          Icons.error_outline,
          messenger: scaffoldMessenger,
        );
      }
    }
  }

  void _showSnackBar(
    String message,
    Color backgroundColor,
    IconData icon, {
    ScaffoldMessengerState? messenger,
  }) {
    final sm = messenger ?? (mounted ? ScaffoldMessenger.of(context) : null);
    if (sm == null) return;

    sm.showSnackBar(
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
                child: Text(language.no),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
                child: Text(language.openSettings),
              ),
            ],
          ),
    );
  }

  void _showImagePicker() {
    final vm = context.read<LeaveRequestViewModel>();

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
                        style: const TextStyle(
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      language.takeANewPhoto,
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
                      language.gallery,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      language.chooseFromPhotos,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndValidateImage(ImageSource.gallery);
                    },
                  ),
                  if (vm.documentPhoto != null) ...[
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
                        vm.setDocumentPhoto(null);
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaveRequestViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(language.leaveRequest),
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body:
              vm.isLoading
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: primary),
                        const SizedBox(height: 16),
                        Text(language.loadingLeaveRequestData),
                      ],
                    ),
                  )
                  : vm.errorMessage != null
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
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vm.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: vm.fetchLeaveRequestData,
                          child: Text(language.retry),
                        ),
                      ],
                    ),
                  )
                  : _buildForm(context, vm),
        );
      },
    );
  }

  Widget _buildForm(BuildContext context, LeaveRequestViewModel vm) {
    return SafeArea(
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
                            value: vm.selectedLeaveType?.leaid,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              hintText: language.selectLeaveType,
                            ),
                            isExpanded: true,
                            items:
                                vm.leaveTypes.map((leaveType) {
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
                            onChanged:
                                (leaid) => vm.setSelectedLeaveType(leaid),
                            validator:
                                (val) =>
                                    val == null
                                        ? language.pleaseSelectLeaveType
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
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                                initialDateRange: vm.leaveDateRange,
                              );
                              if (picked != null) {
                                vm.setLeaveDateRange(picked);
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  hintText: language.selectDateRange,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  suffixIcon: const Icon(Icons.calendar_today),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: isWide ? 16 : 10,
                                  ),
                                ),
                                controller: TextEditingController(
                                  text: vm.leaveDateLabel,
                                ),
                                validator:
                                    (_) =>
                                        vm.leaveDateRange == null
                                            ? language.pleaseSelectLeaveDate
                                            : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Total Leave Days
                          if (vm.leaveDateRange != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
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
                                    backgroundColor: primary.withOpacity(0.1),
                                    label: Text(
                                      "${vm.totalLeaveDays % 1 == 0 ? vm.totalLeaveDays.toInt() : vm.totalLeaveDays} ${vm.totalLeaveDays > 1 ? language.days : language.day}",
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
                                  groupValue: vm.leaveFor,
                                  onChanged: (val) => vm.setLeaveFor(val!),
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text(language.halfDay),
                                  value: 'Half Day',
                                  groupValue: vm.leaveFor,
                                  onChanged: (val) => vm.setLeaveFor(val!),
                                ),
                              ),
                            ],
                          ),

                          // Half Day Session
                          if (vm.leaveFor == 'Half Day') ...[
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
                                    groupValue: vm.halfDaySession,
                                    onChanged:
                                        (val) => vm.setHalfDaySession(val!),
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: Text(language.afternoon),
                                    value: 'Afternoon',
                                    groupValue: vm.halfDaySession,
                                    onChanged:
                                        (val) => vm.setHalfDaySession(val!),
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
                          GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _height += details.delta.dy;
                                if (_height < 80) _height = 80;
                                if (_height > 300) _height = 300;
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: _height,
                                  child: TextFormField(
                                    maxLines: null,
                                    textAlignVertical: TextAlignVertical.top,
                                    expands: true,
                                    keyboardType: TextInputType.multiline,
                                    decoration: InputDecoration(
                                      hintText: language.enterYourReason,
                                      alignLabelWithHint: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: isWide ? 16 : 10,
                                      ),
                                    ),
                                    onChanged: vm.setReason,
                                    validator:
                                        (val) =>
                                            val == null || val.isEmpty
                                                ? language.pleaseEnterReason
                                                : null,
                                  ),
                                ),
                                const Center(
                                  child: Icon(
                                    Icons.drag_handle,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isWide ? 24 : 18),

                          // Document Support
                          if (vm.selectedLeaveType?.requiresDocument ??
                              false) ...[
                            SizedBox(height: isWide ? 24 : 18),
                            Row(
                              children: [
                                Icon(Icons.attach_file, color: primary),
                                const SizedBox(width: 8),
                                Text(
                                  language.documentSupport,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: fontSizeLabel,
                                  ),
                                ),
                                const Spacer(),
                                if (vm.selectedLeaveType?.fileUrl != null)
                                  TextButton.icon(
                                    icon: const Icon(Icons.visibility),
                                    label: Text(language.viewSample),
                                    onPressed: () {
                                      final imageUrl =
                                          vm.selectedLeaveType!.fileUrl!;
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          fullscreenDialog: true,
                                          builder:
                                              (context) => Scaffold(
                                                backgroundColor: Colors.white,
                                                appBar: AppBar(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor:
                                                      Colors.black87,
                                                  elevation: 0,
                                                  title: Text(
                                                    language.sampleDocument,
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                body: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    InteractiveViewer(
                                                      minScale: 0.5,
                                                      maxScale: 5.0,
                                                      child: Center(
                                                        child: Image.network(
                                                          imageUrl,
                                                          fit: BoxFit.contain,
                                                          loadingBuilder: (
                                                            context,
                                                            child,
                                                            loadingProgress,
                                                          ) {
                                                            if (loadingProgress ==
                                                                null)
                                                              return child;
                                                            return Center(
                                                              child: CircularProgressIndicator(
                                                                color: primary,
                                                                value:
                                                                    loadingProgress.expectedTotalBytes !=
                                                                            null
                                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                                            loadingProgress.expectedTotalBytes!
                                                                        : null,
                                                              ),
                                                            );
                                                          },
                                                          errorBuilder: (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .broken_image_outlined,
                                                                  size: 80,
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                ),
                                                                const SizedBox(
                                                                  height: 16,
                                                                ),
                                                                Text(
                                                                  language
                                                                      .failedToLoadSampleDocument,
                                                                  style: const TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .black54,
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      bottom: 24,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade200,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                        child: const Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.pinch,
                                                              color:
                                                                  Colors
                                                                      .black54,
                                                              size: 18,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Pinch to zoom',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .black54,
                                                                fontSize: 13,
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
                                      vm.documentPhoto == null
                                          ? Text(
                                            language.noPhotoSelected,
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontStyle: FontStyle.italic,
                                              fontSize: isWide ? 16 : 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          )
                                          : Row(
                                            children: [
                                              Image.file(
                                                File(vm.documentPhoto!.path),
                                                width: imageSize,
                                                height: imageSize,
                                                fit: BoxFit.cover,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                language.photoSelected,
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: isWide ? 16 : 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(language.uploadPhoto),
                                  onPressed: _showImagePicker,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Approvers
                          if (vm.approvers.isNotEmpty)
                            Card(
                              color: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: isWide ? 18 : 14,
                                  horizontal: isWide ? 18 : 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            fontWeight: FontWeight.w700,
                                            fontSize: isWide ? 19 : 17,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ...vm.sortedApprovers.asMap().entries.map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: primary
                                                  .withOpacity(0.15),
                                              radius: isWide ? 22 : 18,
                                              child: Text(
                                                (entry.key + 1).toString(),
                                                style: const TextStyle(
                                                  color: secondary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    entry.value.dname,
                                                    style: TextStyle(
                                                      fontSize:
                                                          isWide ? 18 : 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    entry
                                                        .value
                                                        .approverLevelName,
                                                    style: TextStyle(
                                                      fontSize:
                                                          isWide ? 15 : 13,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Colors.black54,
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
                          vm.isSubmitting
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
                        vm.isSubmitting ? language.submitting : language.submit,
                      ),
                      onPressed: vm.isSubmitting ? null : _submitLeaveRequest,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
