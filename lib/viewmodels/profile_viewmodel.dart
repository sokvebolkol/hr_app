import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile_model.dart';
import '../repositories/profile_repository.dart';
import '../localization/language_logic.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository = ProfileRepository();
  final LanguageLogic _languageLogic = LanguageLogic();

  // Static callback for profile updates
  static VoidCallback? onProfileUpdated;

  // State variables
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  String? _errorMessage;

  // Getters
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isUploadingImage => _isUploadingImage;
  String? get errorMessage => _errorMessage;
  LanguageLogic get languageLogic => _languageLogic;

  // Computed properties
  String get profileImagePath =>
      _userProfile?.currentProfileImagePath ?? 'assets/images/profile.jpg';
  String get username => _userProfile?.username ?? "Unknown User";
  String get position => _userProfile?.positionName ?? "Unknown Position";
  String get email => _userProfile?.email ?? "";
  String get employeeId => _userProfile?.employeeId ?? "";
  String get employeeCard => _userProfile?.employeeCard ?? "";
  String get fullName => _userProfile?.fullName ?? "";
  String get department => _userProfile?.departmentName ?? "";
  String get branch => _userProfile?.branchFullName ?? "";
  String get monthlySalary => _userProfile?.monthlySalary?.toString() ?? "00";
  String get contract => _userProfile?.contract ?? "";
  String get joinedDate => _userProfile?.formattedJoinedDate ?? "";
  String get employmentType => _userProfile?.employmentType ?? "";
  String get gender => _userProfile?.gender ?? "";
  String get currentLanguage =>
      _languageLogic.language.code == "EN" ? "English" : "ខ្មែរ (Khmer)";

  // Profile items for display
  List<ProfileItem> get profileItems => [
    ProfileItem(icon: Icons.email, label: "Email", value: email),
    ProfileItem(icon: Icons.badge, label: "Employee ID", value: employeeCard),
    // ProfileItem(icon: Icons.person, label: "Full Name", value: fullName),
    // ProfileItem(icon: Icons.wc, label: "Gender", value: gender),
    ProfileItem(icon: Icons.business, label: "Department", value: department),
    ProfileItem(icon: Icons.location_on, label: "Branch", value: branch),
    ProfileItem(
      icon: Icons.work,
      label: "Employment Type",
      value: employmentType,
    ),
    ProfileItem(icon: Icons.type_specimen, label: "Contract Type", value: contract),
    // ProfileItem(icon: Icons.money, label: "Salary", value: monthlySalary),
    ProfileItem(
      icon: Icons.calendar_today,
      label: "Joined Date",
      value: joinedDate,
    ),
    ProfileItem(
      icon: Icons.language,
      label: _languageLogic.language.language,
      value: currentLanguage,
      isClickable: true,
    ),
  ];

  // Initialize profile data
  Future<void> initialize() async {
    await _languageLogic.initialize();
    await fetchUserProfile();
  }

  // Fetch user profile
  Future<void> fetchUserProfile() async {
    try {
      _setLoading(true);
      _setError(null);

      final profile = await _repository.getUserProfile();
      _userProfile = profile;

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Pick and upload image
  Future<String?> pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _setUploadingImage(true);

        final result = await _repository.uploadProfileImage(
          File(pickedFile.path),
        );

        if (result.success) {
          // Update the profile with new image URL
          if (result.profileImageUrl != null) {
            _userProfile = _userProfile?.copyWith(
              profileImageUrl: result.profileImageUrl,
            );
            notifyListeners();

            // Notify other parts of the app that profile was updated
            onProfileUpdated?.call();
          }
          _setUploadingImage(false);
          return result.message;
        } else {
          _setUploadingImage(false);
          return result.message;
        }
      } else {
        return 'No image selected';
      }
    } catch (e) {
      _setUploadingImage(false);
      return 'Error selecting image: $e';
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (e) {
      _setError('Logout failed: $e');
    }
  }

  // Change language
  Future<void> changeLanguage() async {
    try {
      await _languageLogic.toggleLanguage();
      notifyListeners();
    } catch (e) {
      _setError('Failed to change language: $e');
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setUploadingImage(bool uploading) {
    _isUploadingImage = uploading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

class ProfileItem {
  final IconData icon;
  final String label;
  final String value;
  final bool isClickable;

  const ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isClickable = false,
  });
}
