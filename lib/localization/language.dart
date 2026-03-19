List<Language> languageList = [Language(), Khmer()];

class Language {
  String get code => "EN";
  String get login => "Login";
  String get logout => "Logout";
  String get deleteMyAccount => "Delete My Account";
  String get removeAccount => "Delete Account";
  String get msgRemoveAccount =>
      "Would you really like to delete your account?";
  String get register => "Register";
  String get selectLanguage => "Select Language";
  String get language => "Language";
  String get cancel => "Cancel";
  String get logging => "Logging in...";
  String get staffId => "Staff ID";
  String get password => "Password";
  String get forgotPassword => "Forgot Password?";
  String get noAccount => "Don't have an account?";
  String get createAccount => "Create Account";
  String get enterStaffId => "Enter Staff ID";
  String get enterPassword => "Enter Password";
  String get invalidCredentials => "Invalid Staff ID or Password";
  String get networkError => "Network error. Please try again later.";
  String get unknownError => "An unknown error occurred. Please try again.";
  String get welcome => "Welcome";
  String get staffId4digits => "Staff ID must be 4 digits";
  String get passwordTooShort => "Password must be at least 6 characters";
  String get loginSuccess => "Login successful!";
  String get loginFailed => "Login failed. Please check your credentials.";
  String get loading => "Loading...";
  String get pleaseWait => "Please wait...";
  String get home => "Home";
  String get settings => "Settings";
  String get profile => "Profile";
  String get updateProfile => "Update Profile";
  String get saveChanges => "Save Changes";
  String get changesSaved => "Changes saved successfully!";
  String get errorSavingChanges => "Error saving changes. Please try again.";
  String get logoutConfirmation => "Are you sure you want to logout?";
  String get yes => "Yes";
  String get no => "No";
  String get ok => "OK";
  String get technicalDetails => "Technical Details";
  String get cancelOperation => "Cancel Operation";
  String get operationCancelled => "Operation cancelled.";
  String get deleteAccount => "Delete Account";
  String get accountDeleted => "Your account has been deleted.";
  String get errorDeletingAccount =>
      "Error deleting account. Please try again.";
  String get notifications => "Notification";
  String get enableNotifications => "Enable Notification";
  String get disableNotifications => "Disable Notification";
  String get notificationsEnabled => "Notification enabled.";
  String get notificationsDisabled => "Notification disabled.";
  String get serverExperiencingIssues =>
      "The server is currently experiencing issues. Please try again later.";
  String get technicalIssueDetails =>
      "If the problem persists, please contact support with the following details:";
  String get noInternetConnection =>
      "No internet connection. Please check your network settings.";
  String get timeoutError => "The request timed out. Please try again.";
  String get unknownErrorDetails =>
      "An unknown error occurred. Please try again.";
  String get unexpectedError =>
      "An unexpected error occurred. Please try again.";
  String get dataError => "Data error. Please try again.";
  String get invalidResponseFromServer =>
      "Invalid response from server. Please try again.";
  String get connectionTimeout =>
      "Connection timed out. Please check your internet connection.";
  String get missingInformation =>
      "Missing information. Please fill all fields.";
  String get pleaseEnterBothStaffIdAndPassword =>
      "Please enter both Staff ID and Password.";
  String get copyrightText => "© 2024 Chokchey HR. All rights reserved.";
  String get pleaseCreateStrongPassword =>
      "Please create a strong password that you haven\'t used before.";

  String get passwordChangeRequired => "Password Change Required";
  String get authenticationFailed => "Authentication Failed";
  String get validationError => "Validation Error";
  String get validationErrorOccurred => "Validation error occurred.";
  String get pleaseCheckYourInput => "Please check your input and try again.";
  String get serverError => "Server Error";
  String get createStrongPasswordHint =>
      "Please create a strong password that you haven't used before.";
  String get changePasswordNow => "Change Password Now";
  String get securityPasswordChangeMessage =>
      "For security reasons, you need to change your password before continuing.";
  String get resetYourPassword => "Reset your password";
  String get enterStaffIdAndEmail =>
      "Please enter your Staff ID with Company Email to receive an OTP";
  String get forgotPasswordScreen => "Forgot Password";
  String get email => "Email";
  String get sending => "Sending...";
  String get getOTP => "Get OTP";
  String get backToLogin => "Back to Login";
  String get userIdMust4Digits => "User ID must be 4 digits.";
  String get pleaseEnterValidEmail => "Please enter a valid email address.";
  String get userIdOrEmailNotFound => "User ID or Email not found.";
  String get networkErrorTryAgain => "Network error. Please try again.";
  String get otpVerification => "OTP Verification";
  String get enterOTP => "Enter OTP";
  String get weSentCodeToEmail => "We sent a code to your email";
  String get otpExpiresIn => "OTP expires in";
  String get otpExpiredRequestNew => "OTP expired. Please request a new one.";
  String get sixDigitOTP => "6-digit OTP";
  String get pleaseEnter6DigitOTP => "Please enter the 6-digit OTP.";
  String get invalidOTPOrExpired => "Invalid OTP or expired. Please try again.";
  String get verifyAndContinue => "Verify & Continue";
  String get resendOTP => "Resend OTP";
  String get otpResent => "OTP resent!";

  // CEO Dashboard
  String get information => "Information";
  String get doYouWantToExit => "Do you want to exit?";
  String get yourAccountIsInactiveLoggingOut =>
      "Your account is inactive. Logging out...";
  String get updateRequired => "Update Required";
  String get aNewVersion => "A new version";
  String get isAvailableAndMustBeInstalled =>
      "is available and must be installed to continue using the app";
  String get updateNow => "Update Now";
  String get menu => "Menu";
  String get errorLoadingDashboard => "Error Loading Dashboard";
  String get todaysAttendance => "Today's Attendance";
  String get viewDetails => "View Details >";
  String get late => "Late";
  String get leave => "Leave";
  String get absent => "Absent";
  String get present => "Present";
  String get chokcheyTeam => "CHOKCHEY Team";
  String get staffAttendances => "Staff Attendances";
  String get pendingApproval => "Pending Approval";
  String get approvalHistory => "Approval History";
  String get filterByMonth => "Filter by Month:";
  String get noPendingRequests => "No Pending Requests";
  String get allLeaveRequestsAreUpToDate => "All leave requests are up to date";
  String get noRequestsFoundFor => "No requests found for";
  String get approved => "Approved";
  String get rejected => "Rejected";
  String get selectMonth => "Select Month";
  String get twelveMonthsAvailable => "12 previous months available";
  String get goodMorning => "Good morning!";
  String get goodAfternoon => "Good afternoon!";
  String get goodEvening => "Good evening!";

  // Leave Types
  String get annualLeave => "Annual Leave";
  String get sickLeave => "Sick Leave";
  String get unpaidLeave => "Unpaid Leave";
  String get maternityLeave => "Maternity Leave";
  String get specialLeave => "Special Leave";

  // Leave Duration
  String get halfDay => "Half Day";
  String get fullDay => "Full Day";
  String get morning => "Morning";
  String get afternoon => "Afternoon";

  // Approval Levels
  String get firstApprover => "First Approver";
  String get secondApprover => "Second Approver";

  // Staff Attendance Screen
  String get today => "Today";
  String get staffAttendance => "Staff Attendance";
  String get overallSummary => "Overall Summary";
  String get deptBranch => "Dept / Branch";
  String get noDepartmentsFound => "No departments found";
  String get selectDateRange => "Select Date Range";
  String get chooseYourDesiredDateRange => "Choose your desired date range";
  String get startDate => "Start Date";
  String get endDate => "End Date";
  String get thisMonth => "This Month";
  String get lastMonth => "Last Month";
  String get last7Days => "Last 7 Days";
  String get last30Days => "Last 30 Days";
  String get apply => "Apply";
  String get errorLoadingData => "Error Loading Data";
  String get retry => "Retry";

  // Profile Screen
  String get employeeId => "Employee ID";
  String get employeeCard => "Employee Card";
  String get fullName => "Full Name";
  String get department => "Department";
  String get branch => "Branch";
  String get employmentType => "Employment Type";
  String get contractType => "Contract Type";
  String get monthlySalary => "Monthly Salary";
  String get joinedDate => "Joined Date";
  String get gender => "Gender";
  String get position => "Position";
  String get pleaseChooseOne => "Please choose one";
  String get camera => "Camera";
  String get gallery => "Gallery";
  String get permissionRequired => "Permission Required";
  String get cameraPermissionRequired => "Camera Permission Required";
  String get photosPermissionRequired => "Photos Permission Required";
  String get pleaseEnablePermission =>
      "Please enable permission in app settings to use this feature.";
  String get openSettings => "Open Settings";
  String get cameraPermissionDenied => "Camera permission denied";
  String get photoLibraryPermissionDenied => "Photo library permission denied";
  String get noImageSelected => "No image selected";
  String get errorSelectingImage => "Error selecting image";

  // Menu Screen
  String get myProfile => "My Profile";
  String get changePassword => "Change Password";
  String get version => "Version";
  String get loggingOut => "Logging out...";
  String get loggedOutSuccessfully => "Logged out successfully";
  String get loggedOutLocally => "Logged out locally";
  String get networkErrorLoggedOut => "Network error. Logged out locally.";
  String get unableToRetrieveUserInfo => "Unable to retrieve user information";

  // Notification Screen
  String get markAllAsRead => "Mark all as read";
  String get refresh => "Refresh";
  String get markingAllAsRead => "Marking all as read...";
  String get allNotificationsMarkedAsRead => "All notifications marked as read";
  String get failedToMarkAllAsRead => "Failed to mark all as read";
  String get refreshingNotifications => "Refreshing notifications...";
  String get loadingLeaveRequests => "Loading leave requests...";
  String get openingLeaveRequest => "Opening leave request...";
  String get failedToMarkNotificationAsRead =>
      "Failed to mark notification as read";
  String get noInformationAvailable => "No information available";
  String get error => "Error";
  String get failedToLoadNotifications => "Failed to load notifications";
  String get unknownErrorOccurred => "Unknown error occurred";
  String get tryAgain => "Try Again";
  String get allCaughtUp => "All Caught Up! 🎉";
  String get noNewLeaveRequests => "No new leave requests to review";
  String get newLabel => "NEW";

  String get all => "All";
  String get noApprovedLeavesFound => "No approved leaves found";
  String get noRejectedLeavesFound => "No rejected leaves found";
  String get tryChangingTheFilter => "Try changing the filter";
  String get january => "January";
  String get february => "February";
  String get march => "March";
  String get april => "April";
  String get may => "May";
  String get june => "June";
  String get july => "July";
  String get august => "August";
  String get september => "September";
  String get october => "October";
  String get november => "November";
  String get december => "December";

  // Attendance Adjustment
  String get adjustmentRequest => "Adjustment Request";
  String get selectDateForAdjustment => "Select date for adjustment *";
  String get noAttendanceRecordsFound => "No attendance records found";
  String get request => "Request";
  String get monthlyRequestLimit => "Monthly Request Limit";
  String get missedScan => "Missed scan";
  String get leaveEarly => "Leave early";
  String get lateScan => "Late scan";
  String get noCheckOut => "No Check-Out";
  String get requestLimit => "Request Limit";
  String get requestsRemaining => "requests remaining";
  String get requestsUsed => "requests used";
  String get cannotRequestMore => "Cannot request more this month";
  String get attendanceAdjustment => "Attendance Adjustment";

  // Dashboard Functions
  String get clockInOut => "Clock In | Out";
  String get attendanceLogs => "Attendance Logs";
  String get attendanceRequests => "Attendance Requests";

  // Attendance Report Screen
  String get attendanceReport => "Attendance Report";
  String get monthlySummary => "Monthly Summary";
  String get yourAttendanceOverview => "Your attendance overview";
  String get days => "Days";
  String get period => "Period";
  String get errorLoadingReport => "Error Loading Report";
  String get noAttendanceDataFound => "No attendance data found";
  String get records => "records";
  String get date => "Date";
  String get fingerIn => "Finger In";
  String get fingerOut => "Finger Out";
  String get clockIn => "Clock In";
  String get clockOut => "Clock Out";
  String get status => "Status";
  String get notAvailable => "N/A";
  String get historyRequests => "History Requests";
  String get holidays => "Holidays";
  String get memo => "Memo";
  String get more => "More";
  String get leaveHistory => "Leave History";
  String get attendanceAdjustmentsHistory => "Adjustment History";
  String get attendances => "Attendances";
  String get myLeaveRequest => "My Leave Request";
  String get noLeaveRequestsFound => "No leave requests found";
  String get recentlyLeaveRequest => "Recently Leave Request";
  String get requestSubmitted => "Request submitted successfully";
  String get requestFailed => "Failed to submit request";
  String get pleaseProvideReason =>
      "Please provide a reason for the adjustment request";
  String get confirmAdjustmentRequest => "Confirm Adjustment Request";
  String get reviewRequestDetails =>
      "Please review your request details before submitting";
  String get adjustmentType => "Adjustment Type";
  String get reason => "Reason";
  String get attachment => "Attachment";
  String get photoAttached => "Photo attached";
  String get submittingRequest => "Submitting Request";
  String get pleaseWaitProcessing =>
      "Please wait while we process your adjustment request";
  String get submitRequest => "Submit Request";

  // Additional UI strings for attendance adjustment detail screen
  String get checkIn => "Check In";
  String get checkOut => "Check Out";
  String get reasonRequired => "Reason *";
  String get provideDetailedReason =>
      "Please provide a detailed reason for your adjustment request...";
  String get optional => "Optional";
  String get uploadPhoto => "Upload Photo";
  String get tapToSelectPhoto => "Tap to select photo from camera or gallery";
  String get photoSelected => "Photo selected";
  String get readyToSubmit => "Ready to submit";
  String get change => "Change";
  String get approvers => "Approvers";
  String get noApproversAssigned => "No approvers assigned";
  String get selectPhotoSource => "Select Photo Source";
  String get takeNewPhoto => "Take a new photo";
  String get chooseFromGallery => "Choose from gallery";
  String get takeFromPhoto => "Take from photo";
  String get removePhoto => "Remove Photo";
  String get clearSelectedPhoto => "Clear selected photo";
  String get photoRemoved => "Photo removed";

  // Attendance Clock screen strings
  String get attendanceClock => "Attendance Clock";
  String get selectBranch => "Select Branch";
  String get noBranchesHaveCoordinateData =>
      "No branches have coordinate data available";
  String get noCoordinatesAvailable => "No coordinates available";
  String get refreshLocation => "Refresh Location";
  String get alreadyScannedFingerprint =>
      "You have already scanned your fingerprint on the machine";
  String get processing => "Processing...";
  String get todayAttendance => "Today's Attendance";
  String get somethingWentWrong => "Something went wrong";
  String get success => "Success!";

  // Leave Request screen strings
  String get leaveRequest => "Leave Requests";
  String get loadingLeaveRequestData => "Loading leave request data...";
  String get leaveType => "Leave Type";
  String get selectLeaveType => "Select leave type";
  String get pleaseSelectLeaveType => "Please select leave type";
  String get leaveDate => "Leave Date";
  String get pleaseSelectLeaveDate => "Please select leave date";
  String get totalLeave => "Total Leave";
  String get day => "day";
  String get leaveFor => "Leave For";
  String get leaveNote => "Leave Note";
  String get enterYourReason => "Enter your reason";
  String get pleaseEnterReason => "Please enter reason";
  String get documentSupport => "Document Support";
  String get viewSample => "View Sample";
  String get sampleDocument => "Sample Document";
  String get failedToLoadSampleDocument => "Failed to load sample document";
  String get close => "Close";
  String get noPhotoSelected => "No photo selected";
  String get submit => "Submit";
  String get submitting => "Submitting...";
  String get takeANewPhoto => "Take a new photo";
  String get chooseFromPhotos => "Choose from photos";
  String get processingImage => "Processing image...";
  String get documentSupportRequired =>
      "Document support is required for this leave type";
  String get selectedFileNotExist =>
      "Selected file does not exist. Please select again.";
  String get pleaseSelectValidImageFile =>
      "Please select a valid image file (JPG, JPEG, PNG, PDF)";
  String get fileSizeTooLarge => "File size must be less than 5MB";
  String get fileTooLarge => "File too large";
  String get maxSize => "Max: 5MB\nPlease choose a smaller image.";
  String get calendar => "Calendar";
  String get total => "Total";
  String get totalUsed => "Total Used";
  String get annualLeaveUsed => "Annual Leave";
  String get pending => "Pending";
  String get leaveBalance => "Leave Balance";
  String get annualLeaveSummary => "Annual Leave Summary";
  String get leaveUsedByYearly => "Leave Used by Year";
  String get used => "Used";
  String get balance => "Balance";
  String get entitlement => "Entitlement";
  String get leaveBalanceDetails => "Leave Balance Details";
  String get selectYear => "Select Year";
  String get loadingLeaveBalance => "Loading leave balance...";
  String get errorLoadingLeaveBalance => "Error loading leave balance";
  String get daysUsed => "days used";
  String get leaveRequestStatistics => "Leave Request Statistics";
  String get remainingLeaveBalance => "Remaining Leave Balance";
  String get usedLeave => "Used Leave";
  String get availableLeave => "Available Leave";
  String get accountInactiveLoggingOut =>
      "Your account is inactive. Logging out...";
  String get updateAvailable => "Update Required";
  String get viewRequestedHistory => "Requested History";

  // Manager Leave History Screen
  String get myRequest => "My Request";
  String get userApprovers => "Approvers";
  String get myStaffRequest => "My Staff Request";
  String get attendanceAdjustments => "Attendance Adjustments";
  String get errorLoadingLeaveHistory => "Error loading leave history";
  String get noStaffLeaveRequestsFound => "No staff leave requests found";
  String get leaveRequestsWillAppearHere => "Leave requests will appear here";
  String get filterMyRequests => "Filter My Requests";
  String get filterStaffRequests => "Filter Staff Requests";
  String get staffMember => "Staff Member";

  // Notification Screens
  String get loadingLeaveStatusUpdates => "Loading leave status updates...";
  String get viewLeaveDetails => "View Leave Details";
  String get noNewLeaveStatusUpdates =>
      "No new leave status updates.\nYour leave requests are being processed!";
  String get details => "Details";
  String get personal => "Personal";
  String get noLeaveUpdates => "No leave updates";
  String get noLeaveStatusUpdatesAvailable =>
      "No leave status updates available";
  String get noLeaveRequestsEmpty => "No leave requests";
  String get noNotificationsAvailable => "No notifications";
  String get noNewNotificationsAvailable => "No new notifications available";

  // Leave Detail / Attendance Detail Screens
  String get applied => "Applied";
  String get employee => "Employee";
  String get adjustDateTime => "Adjust Date/Time";
  String get viewFullScreen => "View Full Screen";
  String get enterMessageOptional => "Enter your message (optional)...";
  String get followUp => "Follow Up";
  String get loadingDocument => "Loading document...";
  String get cancelRequest => "Cancel Request";
  String get duration => "Duration";
  String get from => "From";
  String get to => "To";
  String get type => "Type";
  String get remark => "Remark";
  String get tapToView => "Tap to view";
  String get failedToLoadDocument => "Failed to load document";
  String get leaveInformation => "Leave Information";
  String get adjustmentInformation => "Adjustment Information";
  String get leaveDetail => "Leave Detail";
  String get attendanceRequest => "Attendance Request";
  String get documentExpected => "Document Expected";
  String get areYouSureToCancel =>
      "Are you sure you want to cancel this leave request? This action cannot be undone.";
  String get yesCancelRequest => "Yes, Cancel";
  String get send => "Send";
  String get leaveRequestCancelledSuccessfully =>
      "Leave request cancelled successfully";
  String get failedToCancelLeaveRequest =>
      "Failed to cancel leave request. Please try again.";
  String get failedToSendFollowUp =>
      "Failed to send follow-up. Please try again.";

  // Dashboard
  String get pendingLeave => "Pending Leave";
  String get pendingAdjustment => "Pending Adjustment";
  String get noPendingLeaveRequests => "No pending leave requests";
  String get noPendingAdjustmentRequests => "No pending adjustment requests";

  // Welcome Screen
  String get welcomeBack => "Welcome back!";
  String get accessYourHRTools =>
      "Access your HR tools, requests \n and updates in one place";
  String get joinAsEmployee => "Join as Employee";
  String get signInToYourAccount => "Sign in to your account";
  String get newEmployeeRegisterHere => "New Employee? Register here";
  String get trustedPlatform => "Trusted Platform";
  String get employeesCount => "200+ Employees";

  // Adjustment Approval Detail
  String get adjustmentDetail => "Adjustment Detail";
  String get employeeInformation => "Employee Information";
  String get processed => "PROCESSED";
  String get adjustmentDate => "Adjustment Date";
  String get requestedOn => "Requested On";

  // Misc
  String get done => "Done";
  String get continueToLogin => "Continue to Login";

  // Employee Registration Screen
  String get enterStaffIdToContinue =>
      "Please enter your Staff ID to continue.";
  String get invalidStaffId => "Invalid Staff ID";
  String get staffIdNotFound => "Staff ID Not Found";
  String get staffIdNotFoundMsg =>
      "The Staff ID you entered does not exist in our system. Please check and try again.";
  String get unauthorized => "Unauthorized";
  String get invalidCredentialsContactHR =>
      "Invalid credentials. Please contact your manager or HR.";
  String get pleaseCheckStaffId => "Please check your Staff ID and try again.";
  String get creatingAccount => "Creating Account...";
  String get enterCodeOrStaffId => "Enter Code or Staff ID";
  String get followStepsToGetCode =>
      "Please follow the following steps to get the code to login";
  String get contactManagerToRegister =>
      "Contact your manager or HR to register your Staff ID";
  String get registrationForNewEmployees =>
      "Registration is for new employees only";
  String get staffIdOrCode => "Staff ID or Code";
  String get pleaseEnterStaffIdOrCode => "Please enter your Staff ID or Code";
  String get staffIdOrCode4Digits =>
      "Staff ID or Code must be exactly 4 digits";
}

class Khmer implements Language {
  @override
  String get code => "KH";

  @override
  String get login => "ចូលប្រើប្រាស់";

  @override
  String get logout => "ចាកចេញ";

  @override
  String get deleteMyAccount => "ធ្វើការលុបគណនី";

  @override
  String get removeAccount => "ធ្វើការលុបគណនី";

  @override
  String get msgRemoveAccount => "តើអ្នកចង់លុបគណនីរបស់អ្នកមែនទេ?";

  @override
  String get register => "ចុះឈ្មោះ";

  @override
  String get selectLanguage => "ជ្រើសរើសភាសា";

  @override
  String get language => "ភាសា";

  @override
  String get cancel => "បោះបង់";

  @override
  String get logging => "កំពុងចូល...";

  @override
  String get staffId => "លេខសម្គាល់បុគ្គលិក";

  @override
  String get password => "ពាក្យសម្ងាត់";

  @override
  String get forgotPassword => "ភ្លេចពាក្យសម្ងាត់?";

  @override
  String get noAccount => "មិនមានគណនីទេ?";

  @override
  String get createAccount => "បង្កើតគណនី";

  @override
  String get enterStaffId => "លេខសម្គាល់បុគ្គលិករបស់អ្នក";

  @override
  String get enterPassword => "ពាក្យសម្ងាត់របស់អ្នក";
  @override
  String get invalidCredentials =>
      "លេខសម្គាល់បុគ្គលិក ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ";
  @override
  String get networkError => "មានបញ្ហាបណ្ដាញ សូមព្យាយាមម្តងទៀតនៅពេលក្រោយ";
  @override
  String get unknownError => "មានបញ្ហាមិនស្គាល់ សូមព្យាយាមម្តងទៀត";
  @override
  String get welcome => "សូមស្វាគមន៍";
  @override
  String get staffId4digits => "លេខសម្គាល់បុគ្គលិកត្រូវតែមាន ៤ ខ្ទង់";
  @override
  String get passwordTooShort =>
      "ពាក្យសម្ងាត់ត្រូវតែមានអក្សរយ៉ាងហោចណាស់ ៦ តួអក្សរ";
  @override
  String get loginSuccess => "ចូលប្រើប្រាស់ដោយជោគជ័យ!";
  @override
  String get loginFailed => "ការចូលប្រើប្រាស់បរាជ័យ";
  @override
  String get loading => "កំពុងផ្ទុក...";
  @override
  String get pleaseWait => "សូមរង់ចាំ...";
  @override
  String get home => "ទំព័រដើម";
  @override
  String get settings => "ការកំណត់";
  @override
  String get profile => "ប្រវត្តិរូប";
  @override
  String get updateProfile => "ធ្វើបច្ចុប្បន្នភាពប្រវត្តិរូប";
  @override
  String get saveChanges => "រក្សាទុកការផ្លាស់ប្តូរ";
  @override
  String get changesSaved => "ការផ្លាស់ប្តូរត្រូវបានរក្សាទុកដោយជោគជ័យ!";
  @override
  String get errorSavingChanges =>
      "មានបញ្ហាក្នុងការរក្សាទុកការផ្លាស់ប្តូរ សូមព្យាយាមម្តងទៀត";
  @override
  String get logoutConfirmation => "តើអ្នកប្រាកដថាចង់ចាកចេញមែនទេ?";
  @override
  String get yes => "បាទ/ចាស";
  @override
  String get no => "ទេ";
  String get ok => "យល់ព្រម";
  String get technicalDetails => "ព័ត៌មានបច្ចេកទេស";
  @override
  String get cancelOperation => "បោះបង់ប្រតិបត្តិការ";
  @override
  String get operationCancelled => "ប្រតិបត្តិការត្រូវបានបោះបង់";
  @override
  String get deleteAccount => "លុបគណនី";
  @override
  String get accountDeleted => "គណនីរបស់អ្នកត្រូវបានលុប";
  @override
  String get errorDeletingAccount =>
      "មានបញ្ហាក្នុងការលុបគណនី សូមព្យាយាមម្តងទៀត";
  @override
  String get notifications => "ការជូនដំណឹង";
  @override
  String get enableNotifications => "បើកការជូនដំណឹង";
  @override
  String get disableNotifications => "បិទ  ការជូនដំណឹង";
  @override
  String get notificationsEnabled => "ការជូនដំណឹងត្រូវបានបើក";
  @override
  String get notificationsDisabled => "ការជូនដំណឹងត្រូវបានបិទ";
  @override
  String get serverExperiencingIssues =>
      "ម៉ាស៊ីនមេកំពុងមានបញ្ហា សូមព្យាយាមម្តងទៀតនៅពេលក្រោយ";
  @override
  String get technicalIssueDetails =>
      "បើបញ្ហានេះនៅតែមាន សូមទាក់ទងការគាំទ្រជាមួយព័ត៌មានដូចខាងក្រោម៖";
  @override
  String get noInternetConnection =>
      "មិនមានការតភ្ជាប់អ៊ីនធឺណិត សូមពិនិត្យការកំណត់បណ្តាញរបស់អ្នក";
  @override
  String get timeoutError => "ការស្នើសុំបានផុតកំណត់ សូមព្យាយាមម្តងទៀត";
  @override
  String get unknownErrorDetails => "មានបញ្ហាមិនស្គាល់ សូមព្យាយាមម្តងទៀត";

  @override
  String get unexpectedError => "មានបញ្ហាមិនស្គាល់ សូមព្យាយាមម្តងទៀត";
  @override
  String get dataError => "មានបញ្ហាទិន្នន័យ សូមព្យាយាមម្តងទៀត";
  @override
  String get invalidResponseFromServer =>
      "ការឆ្លើយតបពីម៉ាស៊ីនមេមិនត្រឹម្រូវ សូមព្យាយាមម្តងទៀត";
  @override
  String get missingInformation => "ព័ត៌មានខ្វះ សូមបំពេញវាលទាំងអស់";
  @override
  String get pleaseEnterBothStaffIdAndPassword =>
      "សូមបញ្ចូលលេខសម្គាល់បុគ្គលិក និងពាក្យសម្ងាត់ទាំងពីរ";
  @override
  String get copyrightText => "© 2024 Chokchey HR. រក្សាសិទ្ធិគ្រប់យ៉ាង";
  @override
  String get pleaseCreateStrongPassword =>
      "សូមបង្កើតពាក្យសម្ងាត់ដែលមានភាពរឹងមាំ ដែលអ្នកមិនបានប្រើមុន";
  @override
  String get passwordChangeRequired => "តម្រូវការផ្លាស់ប្តូរពាក្យសម្ងាត់";
  @override
  String get authenticationFailed => "ការផ្ទៀងផ្ទាត់បរាជ័យ";
  @override
  String get validationError => "កំហុសក្នុងការផ្ទៀងផ្ទាត់";
  @override
  String get validationErrorOccurred => "មានកំហុសក្នុងការផ្ទៀងផ្ទាត់";
  @override
  String get pleaseCheckYourInput =>
      "សូមពិនិត្យការបញ្ចូលរបស់អ្នក ហើយព្យាយាមម្តងទៀត";
  @override
  String get serverError => "កំហុសម៉ាស៊ីនមេ";
  @override
  String get createStrongPasswordHint =>
      "សូមបង្កើតពាក្យសម្ងាត់ដែលមានភាពរឹងមាំ ដែលអ្នកមិនបានប្រើមុន";
  @override
  String get changePasswordNow => "ផ្លាស់ប្តូរពាក្យសម្ងាត់ឥឡូវនេះ";
  @override
  String get securityPasswordChangeMessage =>
      "សម្រាប់ហេតុផលសុវត្ថិភាព អ្នកត្រូវតែផ្លាស់ប្តូរពាក្យសម្ងាត់របស់អ្នក មុនពេលបន្ត";
  @override
  String get resetYourPassword => "កំណត់ពាក្យសម្ងាត់ឡើងវិញ";
  @override
  String get enterStaffIdAndEmail =>
      "សូមបញ្ចូលលេខសម្គាល់បុគ្គលិក និងអ៊ីមែលក្រុមហ៊ុន ដើម្បីទទួលបាន OTP";
  @override
  String get forgotPasswordScreen => "ភ្លេចពាក្យសម្ងាត់";
  @override
  String get email => "អ៊ីមែល";
  @override
  String get sending => "កំពុងផ្ញើ...";
  @override
  String get getOTP => "ទទួល OTP";
  @override
  String get backToLogin => "ត្រឡប់ក្រោយ";
  @override
  String get userIdMust4Digits => "លេខសម្គាល់បុគ្គលិកត្រូវតែមាន ៤ ខ្ទង់";
  @override
  String get pleaseEnterValidEmail => "សូមបញ្ចូលអ៊ីមែលត្រឹមត្រូវ";
  @override
  String get userIdOrEmailNotFound => "មិនមានលេខសម្គាល់បុគ្គលិក ឬអ៊ីមែលនេះទេ";
  @override
  String get networkErrorTryAgain => "មានបញ្ហាបណ្តាញ សូមព្យាយាមម្តងទៀត";
  @override
  String get otpVerification => "ការផ្ទៀងផ្ទាត់ OTP";
  @override
  String get enterOTP => "បញ្ចូល OTP";
  @override
  String get weSentCodeToEmail => "យើងបានផ្ញើលេខកូដទៅអ៊ីមែលរបស់អ្នក";
  @override
  String get otpExpiresIn => "OTP ផុតកំណត់ក្នុងរយៈពេល";
  @override
  String get otpExpiredRequestNew => "OTP ផុតកំណត់។ សូមស្នើសុំថ្មី។";
  @override
  String get sixDigitOTP => "OTP ៦ ខ្ទង់";
  @override
  String get pleaseEnter6DigitOTP => "សូមបញ្ចូល OTP ៦ ខ្ទង់។";
  @override
  String get invalidOTPOrExpired =>
      "OTP មិនត្រឹមត្រូវ ឬផុតកំណត់។ សូមព្យាយាមម្តងទៀត។";
  @override
  String get verifyAndContinue => "ផ្ទៀងផ្ទាត់ និងបន្ត";
  @override
  String get resendOTP => "ផ្ញើ OTP ម្តងទៀត";
  @override
  String get otpResent => "OTP ត្រូវបានផ្ញើម្តងទៀត!";

  // CEO Dashboard
  @override
  String get information => "ព័ត៌មាន";
  @override
  String get doYouWantToExit => "តើអ្នកចង់ចាកចេញមែនទេ?";
  @override
  String get yourAccountIsInactiveLoggingOut =>
      "គណនីរបស់អ្នកមិនសកម្ម។ កំពុងចាកចេញ...";
  @override
  String get updateRequired => "ត្រូវការធ្វើបច្ចុប្បន្នភាព";
  @override
  String get aNewVersion => "កំណែថ្មី";
  @override
  String get isAvailableAndMustBeInstalled =>
      "មានហើយ ហើយត្រូវតែដំឡើងដើម្បីបន្តប្រើកម្មវិធី។";
  @override
  String get updateNow => "ធ្វើបច្ចុប្បន្នភាពឥឡូវនេះ";
  @override
  String get menu => "ម៉ឺនុយ";
  @override
  String get errorLoadingDashboard => "កំហុសក្នុងការផ្ទុកទំព័រដើម";
  @override
  String get retry => "ព្យាយាមម្តងទៀត";
  @override
  String get todaysAttendance => "វត្តមានថ្ងៃនេះ";
  @override
  String get viewDetails => "មើលព័ត៌មានលម្អិត >";
  @override
  String get late => "យឺត";
  @override
  String get leave => "ឈប់សម្រាក";
  @override
  String get absent => "អវត្តមាន";
  @override
  String get present => "វត្តមាន";
  @override
  String get chokcheyTeam => "CHOKCHEY";
  @override
  String get staffAttendances => "វត្តមានបុគ្គលិក";
  @override
  String get pendingApproval => "រង់ចាំការអនុម័ត";
  @override
  String get approvalHistory => "ប្រវត្តិការអនុម័ត";
  @override
  String get filterByMonth => "ច្រោះតាមខែ:";
  @override
  String get noPendingRequests => "មិនមានសំណើរង់ចាំ";
  @override
  String get allLeaveRequestsAreUpToDate =>
      "សំណើច្បាប់ឈប់សម្រាកទាំងអស់បានធ្វើបច្ចុប្បន្នភាព";
  @override
  String get noRequestsFoundFor => "រកមិនឃើញសំណើសម្រាប់";
  @override
  String get approved => "បានអនុម័ត";
  @override
  String get rejected => "បានបដិសេធ";
  @override
  String get selectMonth => "ជ្រើសរើសខែ";
  @override
  String get twelveMonthsAvailable => "មានខែចុងក្រោយចំនួន 12 ខែ";
  @override
  String get goodMorning => "អរុណសួស្តី!";
  @override
  String get goodAfternoon => "ទិវាសួស្តី!";
  @override
  String get goodEvening => "សាយ័ណ្ហសួស្តី!";

  // Leave Types
  @override
  String get annualLeave => "ច្បាប់ឈប់សម្រាកប្រចាំឆ្នាំ";
  @override
  String get sickLeave => "ច្បាប់ឈឺ";
  @override
  String get unpaidLeave => "ច្បាប់គ្មានប្រាក់ខែ";
  @override
  String get maternityLeave => "ច្បាប់សម្រាលកូន";
  @override
  String get specialLeave => "ច្បាប់ពិសេស";

  // Leave Duration
  @override
  String get halfDay => "កន្លះថ្ងៃ";
  @override
  String get fullDay => "មួយថ្ងៃពេញ";
  @override
  String get morning => "ព្រឹក";
  @override
  String get afternoon => "រសៀល";

  // Approval Levels
  @override
  String get firstApprover => "អ្នកអនុម័តទីមួយ";
  @override
  String get secondApprover => "អ្នកអនុម័តទីពីរ";

  // Staff Attendance Screen
  @override
  String get today => "ថ្ងៃនេះ";
  @override
  String get staffAttendance => "វត្តមានបុគ្គលិក";
  @override
  String get overallSummary => "សង្ខេបទូទៅ";
  @override
  String get deptBranch => "នាយកដ្ឋាន / សាខា";
  @override
  String get noDepartmentsFound => "រកមិនឃើញនាយកដ្ឋាន";
  @override
  String get selectDateRange => "ជ្រើសរើសចន្លោះកាលបរិច្ឆេទ";
  @override
  String get chooseYourDesiredDateRange =>
      "ជ្រើសរើសចន្លោះកាលបរិច្ឆេទដែលអ្នកចង់បាន";
  @override
  String get startDate => "កាលបរិច្ឆេទចាប់ផ្តើម";
  @override
  String get endDate => "កាលបរិច្ឆេទបញ្ចប់";
  @override
  String get thisMonth => "ខែនេះ";
  @override
  String get lastMonth => "ខែមុន";
  @override
  String get last7Days => "៧ ថ្ងៃចុងក្រោយ";
  @override
  String get last30Days => "៣០ ថ្ងៃចុងក្រោយ";
  @override
  String get apply => "អនុវត្ត";
  @override
  String get errorLoadingData => "កំហុសក្នុងការផ្ទុកទិន្នន័យ";

  // Profile Screen
  @override
  String get employeeId => "លេខសម្គាល់បុគ្គលិក";
  @override
  String get employeeCard => "កាតបុគ្គលិក";
  @override
  String get fullName => "ឈ្មោះពេញ";
  @override
  String get department => "នាយកដ្ឋាន";
  @override
  String get branch => "សាខា";
  @override
  String get employmentType => "ប្រភេទការងារ";
  @override
  String get contractType => "ប្រភេទកិច្ចសន្យា";
  @override
  String get monthlySalary => "ប្រាក់ខែ";
  @override
  String get joinedDate => "ថ្ងៃចូលបម្រើការងារ";
  @override
  String get gender => "ភេទ";
  @override
  String get position => "តួនាទី";
  @override
  String get pleaseChooseOne => "សូមជ្រើសរើសមួយ";
  @override
  String get camera => "កាមេរ៉ា";
  @override
  String get gallery => "វិចិត្រសាល";
  @override
  String get permissionRequired => "តម្រូវការសិទ្ធិប្រើប្រាស់";
  @override
  String get cameraPermissionRequired => "តម្រូវការសិទ្ធិប្រើកាមេរ៉ា";
  @override
  String get photosPermissionRequired => "តម្រូវការសិទ្ធិប្រើរូបភាព";
  @override
  String get pleaseEnablePermission =>
      "សូមបើកសិទ្ធិនៅក្នុងការកំណត់កម្មវិធីដើម្បីប្រើមុខងារនេះ។";
  @override
  String get openSettings => "បើកការកំណត់";
  @override
  String get cameraPermissionDenied => "សិទ្ធិប្រើកាមេរ៉ាត្រូវបានបដិសេធ";
  @override
  String get photoLibraryPermissionDenied => "សិទ្ធិប្រើរូបភាពត្រូវបានបដិសេធ";
  @override
  String get noImageSelected => "មិនបានជ្រើសរើសរូបភាព";
  @override
  String get errorSelectingImage => "មានបញ្ហាក្នុងការជ្រើសរើសរូបភាព";

  // Menu Screen
  @override
  String get myProfile => "ព័ត៌មានរបស់ខ្ញុំ";
  @override
  String get changePassword => "ប្តូរពាក្យសម្ងាត់";
  @override
  String get version => "កំណែ";
  @override
  String get loggingOut => "កំពុងចាកចេញ...";
  @override
  String get loggedOutSuccessfully => "បានចាកចេញដោយជោគជ័យ";
  @override
  String get loggedOutLocally => "បានចាកចេញក្នុងមូលដ្ឋាន";
  @override
  String get connectionTimeout =>
      "អស់ពេលក្នុងការតភ្ជាប់។ បានចាកចេញក្នុងមូលដ្ឋាន។";
  @override
  String get networkErrorLoggedOut => "បញ្ហាបណ្តាញ។ បានចាកចេញក្នុងមូលដ្ឋាន។";
  @override
  String get unableToRetrieveUserInfo => "មិនអាចទទួលបានព័ត៌មានអ្នកប្រើប្រាស់";
  // Notification Screen
  @override
  String get markAllAsRead => "សម្គាល់ទាំងអស់ថាបានអាន";
  @override
  String get refresh => "ផ្ទុកឡើងវិញ";
  @override
  String get markingAllAsRead => "កំពុងសម្គាល់ទាំងអស់ថាបានអាន...";
  @override
  String get allNotificationsMarkedAsRead =>
      "ការជូនដំណឹងទាំងអស់ត្រូវបានសម្គាល់ថាបានអាន";
  @override
  String get failedToMarkAllAsRead => "បរាជ័យក្នុងការសម្គាល់ទាំងអស់ថាបានអាន";
  @override
  String get refreshingNotifications => "កំពុងផ្ទុកការជូនដំណឹងឡើងវិញ...";
  @override
  String get loadingLeaveRequests => "កំពុងផ្ទុកសំណើច្បាប់...";
  @override
  String get openingLeaveRequest => "កំពុងបើកសំណើច្បាប់...";
  @override
  String get failedToMarkNotificationAsRead =>
      "បរាជ័យក្នុងការសម្គាល់ការជូនដំណឹងថាបានអាន";
  @override
  String get noInformationAvailable => "មិនមានពេ័ត៌មាន";
  @override
  String get error => "កំហុស";
  @override
  String get failedToLoadNotifications => "បរាជ័យក្នុងការផ្ទុកការជូនដំណឹង";
  @override
  String get unknownErrorOccurred => "មានកំហុសមិនស្គាល់";
  @override
  String get tryAgain => "ព្យាយាមម្តងទៀត";
  @override
  String get allCaughtUp => "បានធ្វើរួចរាល់! 🎉";
  @override
  String get noNewLeaveRequests => "មិនមានសំណើច្បាប់ថ្មីសម្រាប់ពិនិត្យ។";
  @override
  String get newLabel => "ថ្មី";
  @override
  String get all => "ទាំងអស់";
  @override
  String get noApprovedLeavesFound => "រកមិនឃើញច្បាប់ដែលបានអនុម័ត";
  @override
  String get noRejectedLeavesFound => "រកមិនឃើញច្បាប់ដែលបានបដិសេធ";
  @override
  String get tryChangingTheFilter => "សាកល្បងប្តូរការចរោះ";
  @override
  String get january => "មករា";
  @override
  String get february => "កុម្ភៈ";
  @override
  String get march => "មីនា";
  @override
  String get april => "មេសា";
  @override
  String get may => "ឧសភា";
  @override
  String get june => "មិថុនា";
  @override
  String get july => "កក្កដា";
  @override
  String get august => "សីហា";
  @override
  String get september => "កញ្ញា";
  @override
  String get october => "តុលា";
  @override
  String get november => "វិច្ឆិកា";
  @override
  String get december => "ធ្នូ";

  // Attendance Adjustment
  @override
  String get adjustmentRequest => "ស្នើសុំកែតម្រូវ";
  @override
  String get selectDateForAdjustment => "ជ្រើសរើសកាលបរិច្ឆេទសម្រាប់កែតម្រូវ *";
  @override
  String get noAttendanceRecordsFound => "មិនមានកំណត់ត្រាវត្តមាន";
  @override
  String get request => "ស្នើសុំ";
  @override
  String get monthlyRequestLimit => "កំណត់ការស្នើសុំប្រចាំខែ";
  @override
  String get missedScan => "ខកស្កេន";
  @override
  String get leaveEarly => "ចេញមុន";
  @override
  String get lateScan => "ស្កេនយឺត";
  @override
  String get noCheckOut => "មិនបានចេញ";
  @override
  String get requestLimit => "កំណត់ការស្នើសុំ";
  @override
  String get requestsRemaining => "ការស្នើសុំនៅសល់";
  @override
  String get requestsUsed => "ការស្នើសុំបានប្រើ";
  @override
  String get cannotRequestMore => "មិនអាចស្នើសុំបន្ថែមទៀតខែនេះ";
  @override
  String get attendanceAdjustment => "កែតម្រូវវត្តមាន";

  // Dashboard Functions
  @override
  String get clockInOut => "ចូល | ចេញ";
  @override
  String get attendanceLogs => "កំណត់ត្រាវត្តមាន";
  @override
  String get attendanceRequests => "ស្នើសុំវត្តមាន";

  // Attendance Report Screen
  @override
  String get attendanceReport => "របាយការណ៍វត្តមាន";
  @override
  String get monthlySummary => "សង្ខេបប្រចាំខែ";
  @override
  String get yourAttendanceOverview => "ទិដ្ឋភាពទូទៅវត្តមានរបស់អ្នក";
  @override
  String get days => "ថ្ងៃ";
  @override
  String get period => "រយៈពេល";
  @override
  String get errorLoadingReport => "កំហុសក្នុងការផ្ទុករបាយការណ៍";
  @override
  String get noAttendanceDataFound => "រកមិនឃើញទិន្នន័យវត្តមាន";
  @override
  String get records => "កំណត់ត្រា";
  @override
  String get date => "កាលបរិច្ឆេទ";
  @override
  String get fingerIn => "ចូលម្រាមដៃ";
  @override
  String get fingerOut => "ចេញម្រាមដៃ";
  @override
  String get clockIn => "ចូលការ";
  @override
  String get clockOut => "ចេញការ";
  @override
  String get status => "ស្ថានភាព";
  @override
  String get notAvailable => "គ្មាន";
  @override
  String get historyRequests => "ប្រវត្តិស្នើសុំ";
  @override
  String get holidays => "ថ្ងៃបុណ្យ";
  @override
  String get memo => "សារកំណត់";
  @override
  String get more => "ច្រើនទៀត";
  @override
  String get leaveHistory => "ប្រវត្តិឈប់សម្រាក";
  @override
  String get attendanceAdjustmentsHistory => "ប្រវត្តិកែតម្រូវវត្តមាន";
  @override
  String get attendances => "វត្តមាន";
  @override
  String get myLeaveRequest => "ការស្នើសុំឈប់សម្រាករបស់ខ្ញុំ";
  @override
  String get noLeaveRequestsFound => "រកមិនឃើញសំណើឈប់សម្រាក";
  @override
  String get recentlyLeaveRequest => "ការស្នើសុំឈប់សម្រាកថ្មីៗ";
  @override
  String get requestSubmitted => "ការស្នើសុំត្រូវបានដាក់ស្នើដោយជោគជ័យ";
  @override
  String get requestFailed => "បរាជ័យក្នុងការដាក់ស្នើ";
  @override
  String get pleaseProvideReason => "សូមផ្តល់ហេតុផលសម្រាប់ការស្នើសុំកែតម្រូវ";
  @override
  String get confirmAdjustmentRequest => "បញ្ជាក់ការស្នើសុំកែតម្រូវ";
  @override
  String get reviewRequestDetails =>
      "សូមពិនិត្យលម្អិតការស្នើសុំរបស់អ្នកមុនពេលដាក់ស្នើ";
  @override
  String get adjustmentType => "ប្រភេទកែតម្រូវ";
  @override
  String get reason => "មូលហេតុ";
  @override
  String get attachment => "ឯកសារភ្ជាប់";
  @override
  String get photoAttached => "រូបភាពបានភ្ជាប់";
  @override
  String get submittingRequest => "កំពុងដាក់ស្នើ";
  @override
  String get pleaseWaitProcessing =>
      "សូមរង់ចាំ យើងកំពុងដំណើរការស្នើសុំកែតម្រូវរបស់អ្នក";
  @override
  String get submitRequest => "ដាក់ស្នើ";

  // Additional UI strings for attendance adjustment detail screen
  @override
  String get checkIn => "ចូល";
  @override
  String get checkOut => "ចេញ";
  @override
  String get reasonRequired => "មូលហេតុ *";
  @override
  String get provideDetailedReason =>
      "សូមផ្តល់ហេតុផលលម្អិតសម្រាប់កំណែទម្រង់មានវត្តមានរបស់អ្នក...";
  @override
  String get optional => "ជម្រើស";
  @override
  String get uploadPhoto => "ផ្ទុករូបភាព";
  @override
  String get tapToSelectPhoto => "ចុចដើម្បីជ្រើសរើសរូបថតពីកាមេរ៉ា ឬវិចិត្រសាល";
  @override
  String get photoSelected => "រូបថតត្រូវបានជ្រើសរើស";
  @override
  String get readyToSubmit => "រួចរាល់ដាក់ស្នើ";
  @override
  String get change => "ផ្លាស់ប្តូរ";
  @override
  String get approvers => "អ្នកអនុម័ត";
  @override
  String get noApproversAssigned => "មិនមានអ្នកអនុម័ត";
  @override
  String get selectPhotoSource => "ជ្រើសរើសប្រភពរូបភាព";
  @override
  String get takeNewPhoto => "ថតរូបថ្មី";
  @override
  String get chooseFromGallery => "ជ្រើសរើសពីវិចិត្រសាល";
  @override
  String get takeFromPhoto => "ថតពីរូបថត";
  @override
  String get removePhoto => "យករូបភាពចេញ";
  @override
  String get clearSelectedPhoto => "សម្អាតរូបភាពដែលបានជ្រើសរើស";
  @override
  String get photoRemoved => "រូបភាពត្រូវបានយកចេញ";

  // Attendance Clock screen strings
  @override
  String get attendanceClock => "Clock វត្តមាន";
  @override
  String get selectBranch => "ជ្រើសរើសសាខា";
  @override
  String get noBranchesHaveCoordinateData => "គ្មានសាខាមានទិន្នន័យកូអរដោនេ";
  @override
  String get noCoordinatesAvailable => "គ្មានកូអរដោនេ";
  @override
  String get refreshLocation => "ធ្វើឱ្យទីតាំងទាន់សម័យ";
  @override
  String get alreadyScannedFingerprint =>
      "អ្នកបានស្កែនស្នាមម្រាមដៃរបស់អ្នកនៅលើម៉ាស៊ីនហើយ";
  @override
  String get processing => "កំពុងដំណើរការ...";
  @override
  @override
  String get todayAttendance => "វត្តមានថ្ងៃនេះ";
  @override
  String get somethingWentWrong => "មានអ្វីមួយខុស";
  @override
  String get success => "ជោគជ័យ!";

  // Leave Request screen strings
  @override
  String get leaveRequest => "សំណើច្បាប់";
  @override
  String get loadingLeaveRequestData => "កំពុងផ្ទុកទិន្នន័យសំណើច្បាប់...";
  @override
  String get leaveType => "ប្រភេទច្បាប់";
  @override
  String get selectLeaveType => "ជ្រើសរើសប្រភេទច្បាប់";
  @override
  String get pleaseSelectLeaveType => "សូមជ្រើសរើសប្រភេទច្បាប់";
  @override
  String get leaveDate => "កាលបរិច្ឆេទច្បាប់";
  @override
  String get pleaseSelectLeaveDate => "សូមជ្រើសរើសកាលបរិច្ឆេទច្បាប់";
  @override
  String get totalLeave => "ច្បាប់សរុប";
  @override
  String get day => "ថ្ងៃ";
  @override
  String get leaveFor => "ច្បាប់សម្រាប់";
  @override
  String get leaveNote => "កំណត់ចំណាំច្បាប់";
  @override
  String get enterYourReason => "បញ្ចូលមូលហេតុរបស់អ្នក";
  @override
  String get pleaseEnterReason => "សូមបញ្ចូលមូលហេតុ";
  @override
  String get documentSupport => "ឯកសារគាំទ្រ";
  @override
  String get viewSample => "មើលគំរូ";
  @override
  String get sampleDocument => "ឯកសារគំរូ";
  @override
  String get failedToLoadSampleDocument => "បរាជ័យក្នុងការផ្ទុកឯកសារគំរូ";
  @override
  String get close => "បិទ";
  @override
  String get noPhotoSelected => "មិនបានជ្រើសរើសរូបថត";
  @override
  @override
  @override
  @override
  String get submit => "ដាក់ស្នើ";
  @override
  String get submitting => "កំពុងដាក់ស្នើ...";
  @override
  String get takeANewPhoto => "ថតរូបថ្មី";
  @override
  String get chooseFromPhotos => "ជ្រើសរើសពីរូបថត";
  @override
  @override
  String get processingImage => "កំពុងដំណើរការរូបភាព...";
  @override
  String get documentSupportRequired =>
      "ត្រូវការឯកសារគាំទ្រសម្រាប់ប្រភេទច្បាប់នេះ";
  @override
  String get selectedFileNotExist =>
      "ឯកសារដែលបានជ្រើសរើសមិនមាន។ សូមជ្រើសរើសម្តងទៀត។";
  @override
  String get pleaseSelectValidImageFile =>
      "សូមជ្រើសរើសឯកសាររូបភាពត្រឹមត្រូវ (JPG, JPEG, PNG, PDF)";
  @override
  String get fileSizeTooLarge => "ទំហំឯកសារត្រូវតែតិចជាង 5MB";
  @override
  String get fileTooLarge => "ឯកសារធំពេក";
  @override
  String get maxSize => "អតិបរមា: 5MB\nសូមជ្រើសរើសរូបភាពតូចជាងនេះ។";
  @override
  String get calendar => "ប្រតិទិន";
  @override
  String get total => "សរុប";
  @override
  String get totalUsed => "បានប្រើសរុប";
  @override
  String get annualLeaveUsed => "ច្បាប់ប្រចាំឆ្នាំ";
  @override
  String get pending => "កំពុងរង់ចាំ";
  @override
  String get leaveBalance => "សមតុល្យច្បាប់";
  @override
  String get annualLeaveSummary => "សង្ខេបច្បាប់ប្រចាំឆ្នាំ";
  @override
  String get leaveUsedByYearly => "ច្បាប់បានប្រើតាមឆ្នាំ";
  @override
  String get used => "បានប្រើ";
  @override
  String get balance => "នៅសល់";
  @override
  String get entitlement => "សិទ្ធិច្បាប់សរុប";
  @override
  String get leaveBalanceDetails => "ព័ត៌មានលម្អិតសមតុល្យច្បាប់";
  @override
  String get selectYear => "ជ្រើសរើសឆ្នាំ";
  @override
  String get loadingLeaveBalance => "កំពុងផ្ទុកសមតុល្យច្បាប់...";
  @override
  String get errorLoadingLeaveBalance => "មានបញ្ហាក្នុងការផ្ទុកសមតុល្យច្បាប់";
  @override
  String get daysUsed => "ថ្ងៃបានប្រើ";
  @override
  String get leaveRequestStatistics => "ស្ថិតិសំណើច្បាប់";
  @override
  String get remainingLeaveBalance => "សមតុល្យច្បាប់នៅសល់";
  @override
  String get usedLeave => "ច្បាប់បានប្រើ";
  @override
  String get availableLeave => "ច្បាប់នៅសល់";
  @override
  String get accountInactiveLoggingOut =>
      "គណនីរបស់អ្នកមិនសកម្ម។ កំពុងចេញពីប្រព័ន្ធ...";
  @override
  String get updateAvailable => "មានការធ្វើបច្ចុប្បន្នភាព!";
  @override
  String get viewRequestedHistory => "មើលប្រវត្តិស្នើសុំដែលបានស្នើសុំ";

  // Manager Leave History Screen
  @override
  String get myRequest => "ការស្នើសុំរបស់ខ្ញុំ";
  @override
  String get userApprovers => "អ្នកអនុម័ត";
  @override
  String get myStaffRequest => "ការស្នើសុំបុគ្គលិករបស់ខ្ញុំ";
  @override
  String get attendanceAdjustments => "ការកែសម្រួលវត្តមាន";
  @override
  String get errorLoadingLeaveHistory =>
      "មានបញ្ហាក្នុងការផ្ទុកប្រវត្តិឈប់សម្រាក";
  @override
  String get noStaffLeaveRequestsFound => "រកមិនឃើញការស្នើសុំឈប់សម្រាកបុគ្គលិក";
  @override
  String get leaveRequestsWillAppearHere =>
      "ការស្នើសុំឈប់សម្រាកនឹងបង្ហាញនៅទីនេះ";
  @override
  String get filterMyRequests => "ច្រោះការស្នើសុំរបស់ខ្ញុំ";
  @override
  String get filterStaffRequests => "ច្រោះការស្នើសុំបុគ្គលិក";
  @override
  String get staffMember => "បុគ្គលិក";

  // Notification Screens
  @override
  String get loadingLeaveStatusUpdates => "កំពុងផ្ទុកព័ត៌មានស្ថានភាពច្បាប់...";
  @override
  String get viewLeaveDetails => "មើលព័ត៌មានលម្អិតច្បាប់";
  @override
  String get noNewLeaveStatusUpdates =>
      "គ្មានការអាប់ដេតស្ថានភាពច្បាប់ថ្មី។\nការស្នើសុំឈប់សម្រាករបស់អ្នកកំពុងត្រូវបានដំណើរការ!";
  @override
  String get details => "ព័ត៌មានលម្អិត";
  @override
  String get personal => "ផ្ទាល់ខ្លួន";
  @override
  String get noLeaveUpdates => "គ្មានការអាប់ដេតច្បាប់";
  @override
  String get noLeaveStatusUpdatesAvailable => "គ្មានការអាប់ដេតស្ថានភាពច្បាប់";
  @override
  String get noLeaveRequestsEmpty => "គ្មានការស្នើសុំច្បាប់";
  @override
  String get noNotificationsAvailable => "គ្មានការជូនដំណឹង";
  @override
  String get noNewNotificationsAvailable => "គ្មានការជូនដំណឹងថ្មី";

  // Leave Detail / Attendance Detail Screens
  @override
  String get applied => "បានដាក់ស្នើ";
  @override
  String get employee => "បុគ្គលិក";
  @override
  String get adjustDateTime => "ថ្ងៃ/ម៉ោងកែតម្រូវ";
  @override
  String get viewFullScreen => "មើលពេញអេក្រង់";
  @override
  String get enterMessageOptional => "បញ្ចូលសារបស់អ្នក (ជម្រើស)...";
  @override
  String get followUp => "តាមដានបន្ត";
  @override
  String get loadingDocument => "កំពុងផ្ទុកឯកសារ...";
  @override
  String get cancelRequest => "បោះបង់ការស្នើសុំ";
  @override
  String get duration => "រយៈពេល";
  @override
  String get from => "ចាប់ពី";
  @override
  String get to => "ដល់";
  @override
  String get type => "ប្រភេទ";
  @override
  String get remark => "ចំណាំ";
  @override
  String get tapToView => "ចុចដើម្បីមើល";
  @override
  String get failedToLoadDocument => "មានបញ្ហាក្នុងការផ្ទុកឯកសារ";
  @override
  String get leaveInformation => "ព័ត៌មានច្បាប់";
  @override
  String get adjustmentInformation => "ព័ត៌មានកែសម្រួល";
  @override
  String get leaveDetail => "ព័ត៌មានលម្អិតច្បាប់";
  @override
  String get attendanceRequest => "ការស្នើសុំវត្តមាន";
  @override
  String get documentExpected => "ឯកសារត្រូវបានរំពឹង";
  @override
  String get areYouSureToCancel =>
      "តើអ្នកប្រាកដថាចង់បោះបង់ការស្នើសុំឈប់សម្រាកនេះមែនទេ? សកម្មភាពនេះមិនអាចផ្លាស់ប្ដូរបានទេ។";
  @override
  String get yesCancelRequest => "បាទ/ចាស, បោះបង់";
  @override
  String get send => "ផ្ញើ";
  @override
  String get leaveRequestCancelledSuccessfully =>
      "ការស្នើសុំឈប់សម្រាកត្រូវបានបោះបង់ដោយជោគជ័យ";
  @override
  String get failedToCancelLeaveRequest =>
      "មានបញ្ហាក្នុងការបោះបង់ការស្នើសុំ។ សូមព្យាយាមម្តងទៀត។";
  @override
  String get failedToSendFollowUp =>
      "មានបញ្ហាក្នុងការផ្ញើតាមដាន។ សូមព្យាយាមម្តងទៀត។";

  // Dashboard
  @override
  String get pendingLeave => "ច្បាប់កំពុងរង់ចាំ";
  @override
  String get pendingAdjustment => "ការកែតម្រូវកំពុងរង់ចាំ";
  @override
  String get noPendingLeaveRequests => "គ្មានការស្នើសុំឈប់សម្រាក";
  @override
  String get noPendingAdjustmentRequests => "គ្មានការស្នើសុំកែតម្រូវវេលា";

  // Welcome Screen
  @override
  String get welcomeBack => "សូមស្វាគមន៍!";
  @override
  String get accessYourHRTools =>
      "ចូលប្រើឧបករណ៍ HR របស់អ្នក, \n សំណើ និងការអាប់ដេតទាំងអស់នៅកន្លែងមួយ";
  @override
  String get joinAsEmployee => "ចូលជាបុគ្គលិក";
  @override
  String get signInToYourAccount => "ចូលប្រើប្រាស់គណនីរបស់អ្នក";
  @override
  String get newEmployeeRegisterHere => "បុគ្គលិកថ្មី? ចុះឈ្មោះនៅទីនេះ";
  @override
  String get trustedPlatform => "Platform ដែលទុកចិត្ត";
  @override
  String get employeesCount => "បុគ្គលិក 200+";

  // Adjustment Approval Detail
  @override
  String get adjustmentDetail => "ព័ត៌មានលម្អិតការកែតម្រូវ";
  @override
  String get employeeInformation => "ព័ត៌មានបុគ្គលិក";
  @override
  String get processed => "បានដំណើរការ";
  @override
  String get adjustmentDate => "កាលបរិច្ឆេទកែតម្រូវ";
  @override
  String get requestedOn => "បានស្នើសុំនៅ";

  // Misc
  @override
  String get done => "រួចរាល់";
  @override
  String get continueToLogin => "បន្តទៅចូលប្រើប្រាស់";

  // Employee Registration Screen
  @override
  String get enterStaffIdToContinue => "សូមបញ្ចូលលេខបុគ្គលិករបស់អ្នកដើម្បីបន្ត";
  @override
  String get invalidStaffId => "លេខបុគ្គលិកមិនត្រឹមត្រូវ";
  @override
  String get staffIdNotFound => "រកមិនឃើញលេខបុគ្គលិក";
  @override
  String get staffIdNotFoundMsg =>
      "លេខបុគ្គលិករបស់អ្នកមិនមានក្នុងប្រព័ន្ធ។ សូមពិនិត្យ ហើយព្យាយាមម្ដងទៀត";
  @override
  String get unauthorized => "គ្មានការអនុញ្ញាត";
  @override
  String get invalidCredentialsContactHR =>
      "ព័ត៌មានមិនត្រឹមត្រូវ។ សូមទាក់ទងអ្នកគ្រប់គ្រង ឬ HR";
  @override
  String get pleaseCheckStaffId =>
      "សូមពិនិត្យលេខបុគ្គលិករបស់អ្នក ហើយព្យាយាមម្ដងទៀត";
  @override
  String get creatingAccount => "កំពុងបង្កើតគណនី...";
  @override
  String get enterCodeOrStaffId => "បញ្ចូលកូដ ឬលេខបុគ្គលិក";
  @override
  String get followStepsToGetCode =>
      "សូមអនុវត្តតាមជំហានខាងក្រោមដើម្បីទទួលបានកូដចូល";
  @override
  String get contactManagerToRegister =>
      "ទាក់ទងអ្នកគ្រប់គ្រង ឬ HR ដើម្បីចុះឈ្មោះលេខបុគ្គលិករបស់អ្នក";
  @override
  String get registrationForNewEmployees =>
      "ការចុះឈ្មោះគឺសម្រាប់បុគ្គលិកថ្មីប៉ុណ្ណោះ";
  @override
  String get staffIdOrCode => "លេខបុគ្គលិក ឬកូដ";
  @override
  String get pleaseEnterStaffIdOrCode => "សូមបញ្ចូលលេខបុគ្គលិក ឬកូដរបស់អ្នក";
  @override
  String get staffIdOrCode4Digits => "លេខបុគ្គលិក ឬកូដត្រូវតែមានចំនួន ៤ ខ្ទង់";
}
