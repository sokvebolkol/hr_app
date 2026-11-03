List<Language> languageList = [Language(), Khmer()];

class Language {
  String get code => "EN";
  String get login => "Login";
  String get logout => "Logout";
  String get selectLanguage => "Select Language";
  String get language => "Language";
  String get landingScreen => "Landing Screen";
  String get dashboard => "Dashboard";
  String get cancel => "Cancel";
  String get logging => "Logging in...";
  String get staffId => "Staff ID";
  String get password => "Password";
  String get forgotPassword => "Forgot Password?";
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
  String get logoutConfirmation => "Are you sure you want to logout?";
  String get yes => "Yes";
  String get no => "No";
  String get ok => "OK";
  String get technicalDetails => "Technical Details";
  String get notifications => "Notification";
  String get serverExperiencingIssues =>
      "The server is currently experiencing issues. Please try again later.";
  String get noInternetConnection =>
      "No internet connection. Please check your network settings.";
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
  String get loginWithMicrosoft => "Sign in with Microsoft";
  String get microsoftLoginFailed =>
      "Microsoft sign-in failed. Please try again.";
  String get orDivider => "or continue with";
  String get pleaseCreateStrongPassword =>
      "Please create a strong password that you haven\'t used before.";

  String get passwordChangeRequired => "Password Change Required";
  String get validationError => "Validation Error";
  String get validationErrorOccurred => "Validation error occurred.";
  String get changePasswordNow => "Change Password Now";
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
  String get whatsNew => "What's New";
  String get requiredUpdate => "Required Update";

  // Check for update (user initiated)
  // Announcement feed (Microsoft Teams)
  String get announcement => "Announcement";
  String get openInTeams => "Open in Teams";
  String get allChannels => "All Channels";
  String get unread => "Unread";
  String get noAnnouncements => "No announcements yet";
  String get noAnnouncementsSubtitle =>
      "There are no announcements right now. New posts from your teams will appear here.";
  String get noChannelAnnouncements => "No announcements in this channel";
  String get noChannelAnnouncementsSubtitle =>
      "This channel has no announcements yet. Try another channel or view all channels.";
  String get showAllChannels => "Show All Channels";
  String get noContent => "This message has no content.";
  String get attachments => "Attachments";
  String get markAsRead => "Mark as read";
  String get markAsUnread => "Mark as unread";
  String get imageMessage => "[Image]";
  String get selectChannel => "Select channel";
  String get searchChannel => "Search channel";
  String get noChannelFound => "No channel found";
  String get loadingAnnouncements => "Loading announcements...";
  String get channels => "channels";
  String get read => "Read";
  String get markAsReadHint => "Remove it from your unread count";
  String get markAsUnreadHint => "Keep it highlighted to read later";
  String get openInTeamsHint => "View the full post in Microsoft Teams";
  String get imageViewInTeams => "Image, tap to view in Microsoft Teams";
  String get important => "IMPORTANT";
  String get edited => "edited";
  String get unknownSender => "Unknown";
  String get noAccess => "No Access";
  String get linkNotAvailable => "This link is not available.";
  String get couldNotOpenTeams =>
      "Could not open Microsoft Teams. Please try again.";

  // Request to join a team (announcements)
  String get requestToJoin => "Request to join";
  String get requestToJoinHint => "Ask the team owners to add you";
  String get notTeamMemberTitle => "You are not a member of this team";
  String get notTeamMemberBody => "You can read this post in the app. To open it in Microsoft Teams, ask a team owner to add you.";
  String get joinRequestNoteHint => "Message to the team owners (optional)";
  String get sendJoinRequest => "Send request";
  String get joinRequestPending => "Your request was sent. Waiting for a team owner to answer.";
  String get joinRequestApproved => "Approved. You will be added to the team in a few minutes.";
  String get joinRequestRejected => "Your last request was declined.";
  String get joinRequestExpired => "Your last request expired without an answer.";
  String get joinRequestFailed => "You could not be added automatically. Please contact IT or a team owner.";
  String get viewPostInApp => "View post in the app";
  String get joinRequests => "Join requests";
  String get noJoinRequests => "No join requests waiting";
  String get declineReasonHint => "Reason, shown to the requester (optional)";
  String joinRequestsWaiting(int count) =>
      count == 1 ? "1 request to join is waiting" : "$count requests to join are waiting";

  String get checkForUpdate => "Check for Update";
  String get checkingForUpdate => "Checking for update...";
  String get newVersionReady => "Update Available";
  String get isAvailableToInstall => "is available to install.";
  String get later => "Later";
  String get youAreUpToDate => "You're up to date";
  String get usingLatestVersion =>
      "You are using the latest version of the app.";
  String get couldNotCheckForUpdate =>
      "Could not check for updates. Please check your connection and try again.";
  String get currentVersion => "Current version";

  // Device integrity (root / jailbreak detection)
  String get deviceNotSecure => "Device Security Warning";
  String get deviceNotSecureWarning =>
      "This device appears to be rooted or jailbroken, which may put your "
      "account and company data at risk.\n\nYou can continue using the app, "
      "but please contact the HR department if you did not make these changes "
      "to your device.";
  String get iUnderstand => "I Understand";
  String get menu => "Menu";
  String get errorLoadingDashboard => "Error Loading Dashboard";
  String get todaysAttendance => "Today's Attendance";
  String get viewDetails => "Details >";
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
  String get leaveApproved => "Leave Approved";
  String get leaveRejected => "Leave Rejected";
  String get attendanceApproved => "Attendance Approved";
  String get attendanceRejected => "Attendance Rejected";
  String get rejected => "Rejected";
  String get approve => "Approve";
  String get reject => "Reject";
  String get selectMonth => "Select Month";
  String get twelveMonthsAvailable => "12 previous months available";
  String get goodMorning => "Good morning!";
  String get goodAfternoon => "Good afternoon!";
  String get goodEvening => "Good evening!";

  // Leave Types
  String get annualLeave => "Annual Leave";
  String get sickLeave => "Sick Leave";
  String get maternityLeave => "Maternity Leave";
  String get specialLeave => "Special Leave";

  // Leave Duration
  String get halfDay => "Half Day";
  String get fullDay => "Full Day";
  String get morning => "Morning";
  String get afternoon => "Afternoon";

  // Approval Levels

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
  String get attendance => " Attendance";
  String get workingDays => "working days";
  String get lastMonth => "Last Month";
  String get threeMonths => "3 Months";
  String get custom => "Custom";
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
  String get camera => "Camera";
  String get gallery => "Gallery";
  String get openSettings => "Open Settings";

  // Menu Screen
  String get myProfile => "My Profile";
  String get changePassword => "Change Password";
  String get version => "Version";
  String get loggingOut => "Logging out...";
  String get loggedOutSuccessfully => "Logged out successfully";
  String get loggedOutLocally => "Logged out locally";
  String get networkErrorLoggedOut => "Network error. Logged out locally.";

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
  String get error => "Error";
  String get failedToLoadNotifications => "Failed to load notifications";
  String get unknownErrorOccurred => "Unknown error occurred";
  String get tryAgain => "Try Again";
  String get allCaughtUp => "All Caught Up! 🎉";
  String get noNewLeaveRequests => "No new leave requests to review";

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
  String get requestLimit => "Request Limit";
  String get requestsRemaining => "requests remaining";
  String get requestsUsed => "requests used";

  // Dashboard Functions
  String get clockInOut => "Clock In | Out";
  String get attendanceLogs => "Attendance Logs";
  String get attendanceRequests => "Attendance Requests";
  String get requestAdjustment => "Attendance Requests";

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
  String get clockIn => "Clock In";
  String get clockOut => "Clock Out";
  String get status => "Status";
  String get historyRequests => "History Requests";
  String get holidays => "Holidays";
  String get memo => "Memo";
  String get more => "More";
  String get leaveHistory => "Leave History";
  String get requestFailed => "Failed to submit request";
  String get adjustmentType => "Adjustment Type";
  String get reason => "Reason";
  String get attachment => "Attachment";
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
  String get change => "Change";
  String get approvers => "Approvers";
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
  String get leaveRequest => "Leave Request";
  String get loadingLeaveRequestData => "Loading leave request data...";
  String get leaveType => "Leave Type";
  String get selectLeaveType => "Select leave type";
  String get pleaseSelectLeaveType => "Please select leave type";
  String get leaveDate => "Leave Date";
  String get pleaseSelectLeaveDate => "Please select leave date";
  String maternityLeaveExceedsLimit(int maxDays, int selectedDays) =>
      "Maternity leave cannot exceed $maxDays days, including weekends and holidays. Your selected range is $selectedDays days.";
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
  String get totalRequests => "Total Requests";
  String get annualLeaveUsed => "Annual Leave";
  String get pending => "Pending";
  String get leaveBalance => "Leave Balance";
  String get leaveUsedByYearly => "Leave Used by Year";
  String get used => "Used";
  String get balance => "Balance";
  String get selectYear => "Select Year";
  String get loadingLeaveBalance => "Loading leave balance...";
  String get errorLoadingLeaveBalance => "Error loading leave balance";
  String get remainingLeaveBalance => "Leave Balance";
  String get usedLeave => "Used";
  String get dayAvailableText => "day available";
  String get accountInactiveLoggingOut =>
      "Your account is inactive. Logging out...";
  String get updateAvailable => "Update Required";
  String get viewRequestedHistory => "Requested History";

  // Manager Leave History Screen
  String get myRequest => "My Request";
  String get userApprovers => "Approvers";
  String get attendanceAdjustments => "Attendance Adjustments";
  String get staffMember => "Staff Member";
  String get name => "Name";
  String get office => "Office";

  // Notification Screens
  String get loadingLeaveStatusUpdates => "Loading leave status updates...";
  String get viewLeaveDetails => "View Leave Details";
  String get noNewLeaveStatusUpdates =>
      "No new leave status updates.\nYour leave requests are being processed!";
  String get details => "Details";
  String get personal => "Personal";
  String get staff => "Staff";
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
  String get fromDate => "From Date";
  String get toDate => "To Date";
  String get appliedOn => "Applied On";
  String get pinchToZoom => "Pinch to zoom • Double tap to zoom in/out";
  String get type => "Type";
  String get remark => "Remark";
  String get tapToView => "Tap to view";
  String get viewAll => "View All";
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

  // Adjustment Approval Detail
  String get adjustmentDetail => "Adjustment Detail";
  String get employeeInformation => "Employee Information";
  String get processed => "PROCESSED";

  // Leave action buttons / confirm dialog
  String get rejecting => "Rejecting...";
  String get approving => "Approving...";
  String get confirmYourDecision => "Confirm your decision";
  String get approvalRemarkOptional => "Approval Remark (Optional)";
  String get rejectionRemarkRequired => "Rejection Remark (Required)";
  String get addNoteForApproval => "Add a note for approval...";
  String get addReasonForRejection => "Add a reason for rejection...";
  String get actionFailed => "Action failed";
  String get approveAttendance => "Approve Attendance";
  String get rejectAttendance => "Reject Attendance";
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
  String get selectLanguage => "ជ្រើសរើសភាសា";

  @override
  String get language => "ភាសា";

  @override
  String get landingScreen => "ទំព័រចាប់ផ្តើម";

  @override
  String get dashboard => "ទំព័រដើម";

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
  String get profile => "ប្រូហ្វាល់";
  @override
  String get logoutConfirmation => "តើអ្នកប្រាកដថាចង់ចាកចេញមែនទេ?";
  @override
  String get yes => "បាទ/ចាស";
  @override
  String get no => "ទេ";
  String get ok => "យល់ព្រម";
  String get technicalDetails => "ព័ត៌មានបច្ចេកទេស";
  @override
  String get notifications => "ការជូនដំណឹង";
  @override
  String get serverExperiencingIssues =>
      "ម៉ាស៊ីនមេកំពុងមានបញ្ហា សូមព្យាយាមម្តងទៀតនៅពេលក្រោយ";
  @override
  String get noInternetConnection =>
      "មិនមានការតភ្ជាប់អ៊ីនធឺណិត សូមពិនិត្យការកំណត់បណ្តាញរបស់អ្នក";

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
  String get validationError => "កំហុសក្នុងការផ្ទៀងផ្ទាត់";
  @override
  String get validationErrorOccurred => "មានកំហុសក្នុងការផ្ទៀងផ្ទាត់";
  @override
  String get changePasswordNow => "ផ្លាស់ប្តូរពាក្យសម្ងាត់ឥឡូវនេះ";
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
  String get whatsNew => "កំណែថ្មីៗ";
  @override
  String get requiredUpdate => "ការធ្វើបច្ចុប្បន្នភាពចាំបាច់";

  // Announcement feed (Microsoft Teams)
  @override
  String get announcement => "សេចក្តីជូនដំណឹង";
  @override
  String get openInTeams => "បើកក្នុង Teams";
  @override
  String get allChannels => "ឆានែលទាំងអស់";
  @override
  String get unread => "មិនទាន់អាន";
  @override
  String get noAnnouncements => "មិនទាន់មានសេចក្តីជូនដំណឹង";
  @override
  String get noAnnouncementsSubtitle =>
      "បច្ចុប្បន្នមិនទាន់មានសេចក្តីជូនដំណឹងទេ។ ការផ្សាយថ្មីៗពីក្រុមរបស់អ្នកនឹងបង្ហាញនៅទីនេះ។";
  @override
  String get noChannelAnnouncements => "មិនមានសេចក្តីជូនដំណឹងក្នុងឆានែលនេះទេ";
  @override
  String get noChannelAnnouncementsSubtitle =>
      "ឆានែលនេះមិនទាន់មានសេចក្តីជូនដំណឹងទេ។ សូមសាកល្បងឆានែលផ្សេង ឬមើលឆានែលទាំងអស់។";
  @override
  String get showAllChannels => "បង្ហាញឆានែលទាំងអស់";
  @override
  String get noContent => "សារនេះគ្មានមាតិកាទេ។";
  @override
  String get attachments => "ឯកសារភ្ជាប់";
  @override
  String get markAsRead => "សម្គាល់ថាបានអាន";
  @override
  String get markAsUnread => "សម្គាល់ថាមិនទាន់អាន";
  @override
  String get imageMessage => "[រូបភាព]";
  @override
  String get selectChannel => "ជ្រើសរើសឆានែល";
  @override
  String get searchChannel => "ស្វែងរកឆានែល";
  @override
  String get noChannelFound => "រកមិនឃើញឆានែល";
  @override
  String get loadingAnnouncements => "កំពុងផ្ទុកសេចក្តីជូនដំណឹង...";
  @override
  String get channels => "ឆានែល";
  @override
  String get read => "បានអាន";
  @override
  String get markAsReadHint => "ដកចេញពីចំនួនមិនទាន់អាន";
  @override
  String get markAsUnreadHint => "រក្សាទុកជាមិនទាន់អាន ដើម្បីអានពេលក្រោយ";
  @override
  String get openInTeamsHint => "មើលសារពេញលេញក្នុង Microsoft Teams";
  @override
  String get imageViewInTeams => "រូបភាព ចុចដើម្បីមើលក្នុង Microsoft Teams";
  @override
  String get important => "សំខាន់";
  @override
  String get edited => "បានកែ";
  @override
  String get unknownSender => "មិនស្គាល់";
  @override
  String get noAccess => "គ្មានសិទ្ធិចូលប្រើ";
  @override
  String get linkNotAvailable => "តំណនេះមិនអាចប្រើបានទេ។";
  @override
  String get couldNotOpenTeams =>
      "មិនអាចបើក Microsoft Teams បានទេ។ សូមព្យាយាមម្តងទៀត។";

  // Request to join a team (announcements)
  @override
  String get requestToJoin => "ស្នើសុំចូលរួម";
  @override
  String get requestToJoinHint => "ស្នើម្ចាស់ក្រុមឱ្យបន្ថែមអ្នក";
  @override
  String get notTeamMemberTitle => "អ្នកមិនទាន់ជាសមាជិកក្រុមនេះទេ";
  @override
  String get notTeamMemberBody => "អ្នកអាចអានសារនេះក្នុងកម្មវិធី។ ដើម្បីបើកក្នុង Microsoft Teams សូមស្នើម្ចាស់ក្រុមឱ្យបន្ថែមអ្នក។";
  @override
  String get joinRequestNoteHint => "សារទៅម្ចាស់ក្រុម (ជម្រើស)";
  @override
  String get sendJoinRequest => "ផ្ញើសំណើ";
  @override
  String get joinRequestPending => "សំណើរបស់អ្នកត្រូវបានផ្ញើ។ កំពុងរង់ចាំម្ចាស់ក្រុមឆ្លើយតប។";
  @override
  String get joinRequestApproved => "បានអនុម័ត។ អ្នកនឹងត្រូវបានបន្ថែមទៅក្រុមក្នុងរយៈពេលប៉ុន្មាននាទីទៀត។";
  @override
  String get joinRequestRejected => "សំណើចុងក្រោយរបស់អ្នកត្រូវបានបដិសេធ។";
  @override
  String get joinRequestExpired => "សំណើចុងក្រោយរបស់អ្នកបានផុតកំណត់ ដោយគ្មានការឆ្លើយតប។";
  @override
  String get joinRequestFailed => "មិនអាចបន្ថែមអ្នកដោយស្វ័យប្រវត្តិបានទេ។ សូមទាក់ទង IT ឬម្ចាស់ក្រុម។";
  @override
  String get viewPostInApp => "មើលសារក្នុងកម្មវិធី";
  @override
  String get joinRequests => "សំណើចូលរួម";
  @override
  String get noJoinRequests => "មិនមានសំណើចូលរួមកំពុងរង់ចាំទេ";
  @override
  String get declineReasonHint => "មូលហេតុ បង្ហាញទៅអ្នកស្នើសុំ (ជម្រើស)";
  @override
  String joinRequestsWaiting(int count) => "សំណើចូលរួម $count កំពុងរង់ចាំ";

  // Check for update (user initiated)
  @override
  String get checkForUpdate => "ពិនិត្យបច្ចុប្បន្នភាព";
  @override
  String get checkingForUpdate => "កំពុងពិនិត្យបច្ចុប្បន្នភាព...";
  @override
  String get newVersionReady => "មានបច្ចុប្បន្នភាពថ្មី";
  @override
  String get isAvailableToInstall => "អាចដំឡើងបានហើយ។";
  @override
  String get later => "ពេលក្រោយ";
  @override
  String get youAreUpToDate => "កម្មវិធីទាន់សម័យ";
  @override
  String get usingLatestVersion => "អ្នកកំពុងប្រើកំណែថ្មីបំផុតរបស់កម្មវិធី។";
  @override
  String get couldNotCheckForUpdate =>
      "មិនអាចពិនិត្យបច្ចុប្បន្នភាពបានទេ។ សូមពិនិត្យការតភ្ជាប់ ហើយព្យាយាមម្តងទៀត។";
  @override
  String get currentVersion => "កំណែបច្ចុប្បន្ន";

  // Device integrity (root / jailbreak detection)
  @override
  String get deviceNotSecure => "ការព្រមានសុវត្ថិភាពឧបករណ៍";
  @override
  String get deviceNotSecureWarning =>
      "ឧបករណ៍នេះហាក់ដូចជាត្រូវបាន root ឬ jailbreak ដែលអាចធ្វើឱ្យគណនី "
      "និងទិន្នន័យក្រុមហ៊ុនរបស់អ្នកមានគ្រោះថ្នាក់។\n\nអ្នកអាចបន្តប្រើកម្មវិធីបាន "
      "ប៉ុន្តែសូមទាក់ទងផ្នែកធនធានមនុស្ស ប្រសិនបើអ្នកមិនបានធ្វើការផ្លាស់ប្តូរនេះ។";
  @override
  String get iUnderstand => "ខ្ញុំយល់";
  @override
  String get menu => "ម៉ឺនុយ";
  @override
  String get errorLoadingDashboard => "កំហុសក្នុងការផ្ទុកទំព័រដើម";
  @override
  String get retry => "ព្យាយាមម្តងទៀត";
  @override
  String get todaysAttendance => "វត្តមានថ្ងៃនេះ";
  @override
  String get viewDetails => "ព័ត៌មានលម្អិត >";
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
  String get leaveApproved => "ច្បាប់បានអនុម័ត";
  @override
  String get leaveRejected => "ច្បាប់បានបដិសេធ";
  @override
  String get attendanceApproved => "វត្តមានបានអនុម័ត";
  @override
  String get attendanceRejected => "វត្តមានបានបដិសេធ";
  @override
  String get rejected => "បានបដិសេធ";
  @override
  String get approve => "អនុម័ត";
  @override
  String get reject => "បដិសេធ";
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
  String get attendance => " វត្តមាន";
  @override
  String get workingDays => "ថ្ងៃធ្វើការ";
  @override
  String get lastMonth => "ខែមុន";
  @override
  String get threeMonths => "៣ ខែ";
  @override
  String get custom => "ផ្ទាល់ខ្លួន";
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
  String get camera => "កាមេរ៉ា";
  @override
  String get gallery => "វិចិត្រសាល";
  @override
  String get openSettings => "បើកការកំណត់";

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
  String get requestLimit => "កំណត់ការស្នើសុំ";
  @override
  String get requestsRemaining => "ការស្នើសុំនៅសល់";
  @override
  String get requestsUsed => "ការស្នើសុំបានប្រើ";

  // Dashboard Functions
  @override
  String get clockInOut => "ចូល | ចេញ";
  @override
  String get attendanceLogs => "កំណត់ត្រាវត្តមាន";
  @override
  String get attendanceRequests => "ស្នើសុំវត្តមាន";
  @override
  String get requestAdjustment => "ស្នើសុំកែតម្រូវវត្តមាន";

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
  String get clockIn => "ចូល";
  @override
  String get clockOut => "ចេញ";
  @override
  String get status => "ស្ថានភាព";
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
  String get requestFailed => "បរាជ័យក្នុងការដាក់ស្នើ";
  @override
  String get adjustmentType => "ប្រភេទកែតម្រូវ";
  @override
  String get reason => "មូលហេតុ";
  @override
  String get attachment => "ឯកសារភ្ជាប់";
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
  String get change => "ផ្លាស់ប្តូរ";
  @override
  String get approvers => "អ្នកអនុម័ត";
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
  String maternityLeaveExceedsLimit(int maxDays, int selectedDays) =>
      "ច្បាប់សម្រាលកូនមិនអាចលើសពី $maxDays ថ្ងៃ រួមទាំងថ្ងៃឈប់សម្រាក និងចុងសប្តាហ៍។ ចន្លោះពេលដែលអ្នកបានជ្រើសរើសគឺ $selectedDays ថ្ងៃ។";
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
  String get totalRequests => "ចំនួនសំណើសរុប";
  @override
  String get annualLeaveUsed => "ច្បាប់ប្រចាំឆ្នាំ";
  @override
  String get pending => "កំពុងរង់ចាំ";
  @override
  String get leaveBalance => "សមតុល្យច្បាប់";
  @override
  String get leaveUsedByYearly => "ច្បាប់បានប្រើតាមឆ្នាំ";
  @override
  String get used => "បានប្រើ";
  @override
  String get balance => "នៅសល់";
  @override
  String get selectYear => "ជ្រើសរើសឆ្នាំ";
  @override
  String get loadingLeaveBalance => "កំពុងផ្ទុកសមតុល្យច្បាប់...";
  @override
  String get errorLoadingLeaveBalance => "មានបញ្ហាក្នុងការផ្ទុកសមតុល្យច្បាប់";
  @override
  String get remainingLeaveBalance => "សមតុល្យច្បាប់នៅសល់";
  @override
  String get usedLeave => "បានប្រើ";
  @override
  String get dayAvailableText => "ច្បាប់នៅសល់";
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
  String get attendanceAdjustments => "ការកែសម្រួលវត្តមាន";
  @override
  String get staffMember => "បុគ្គលិក";

  @override
  String get name => "ឈ្មោះ";

  @override
  String get office => "ការិយាល័យ";

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
  String get staff => "បុគ្គលិក";
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
  String get fromDate => "ចាប់ពីថ្ងៃ";
  @override
  String get toDate => "ដល់ថ្ងៃ";
  @override
  String get appliedOn => "បានដាក់ស្នើនៅ";
  @override
  String get pinchToZoom => "ទ្រាំម្រាម • ចុចទំងន់ ២ ដើម្បីពង្រីក/បង្រួម";
  @override
  String get type => "ប្រភេទ";
  @override
  String get remark => "ចំណាំ";
  @override
  String get tapToView => "ចុចដើម្បីមើល";
  @override
  String get viewAll => "មើលទាំងអស់";
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

  // Adjustment Approval Detail
  @override
  String get adjustmentDetail => "ព័ត៌មានលម្អិតការកែតម្រូវ";
  @override
  String get employeeInformation => "ព័ត៌មានបុគ្គលិក";
  @override
  String get processed => "បានដំណើរការ";
  @override
  String get rejecting => "កំពុងបដិសេធ...";
  @override
  String get approving => "កំពុងអនុម័ត...";
  @override
  String get confirmYourDecision => "បញ្ជាក់ការសម្រេចចិត្តរបស់អ្នក";
  @override
  String get approvalRemarkOptional => "កំណត់សម្គាល់ការអនុម័ត (ស្រេចចិត្ត)";
  @override
  String get rejectionRemarkRequired => "កំណត់សម្គាល់ការបដិសេធ (ចាំបាច់)";
  @override
  String get addNoteForApproval => "បន្ថែមកំណត់សម្គាល់សម្រាប់ការអនុម័ត...";
  @override
  String get addReasonForRejection => "បន្ថែមមូលហេតុសម្រាប់ការបដិសេធ...";
  @override
  String get actionFailed => "សកម្មភាពបរាជ័យ";
  @override
  String get approveAttendance => "អនុម័តវត្តមាន";
  @override
  String get rejectAttendance => "បដិសេធវត្តមាន";
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
  @override
  String get loginWithMicrosoft => "ចូលដោយ Microsoft";
  @override
  String get microsoftLoginFailed =>
      "ការចូលតាម Microsoft បានបរាជ័យ។ សូមព្យាយាមម្ដងទៀត";
  @override
  String get orDivider => "ឬបន្តដោយ";
}
