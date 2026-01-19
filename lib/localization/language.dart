List<Language> languageList = [Language(), Khmer()];

class Language {
  String get code => "EN";
  String get login => "Log In";
  String get logout => "Logout";
  String get deleteMyAccount => "Delete My Account";
  String get removeAccount => "Delete Account";
  String get msgRemoveAccount =>
      "Would you really like to delete your account?";
  String get register => " Register";
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
  String get notifications => "Notifications";
  String get enableNotifications => "Enable Notifications";
  String get disableNotifications => "Disable Notifications";
  String get notificationsEnabled => "Notifications enabled.";
  String get notificationsDisabled => "Notifications disabled.";
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
      "is available and must be installed to continue using the app.";
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
  String get noNewLeaveRequests =>
      "No new leave requests to review.\nYour team is all set!";
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
  String get noNewLeaveRequests =>
      "មិនមានសំណើច្បាប់ថ្មីសម្រាប់ពិនិត្យ។\nក្រុមរបស់អ្នករួចរាល់ហើយ!";
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
}
