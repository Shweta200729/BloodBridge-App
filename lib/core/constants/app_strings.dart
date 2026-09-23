class AppStrings {
  AppStrings._();

  static const String appName = 'BloodBridge';
  static const String appTagline = 'Connecting Lifesavers with Those in Need';

  // Navigation Labels
  static const String navHome = 'Home';
  static const String navRequests = 'Emergency';
  static const String navDonors = 'Donors';
  static const String navHospitals = 'Hospitals';
  static const String navProfile = 'Profile';

  // Blood Types
  static const List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // Auth Strings
  static const String loginTitle = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to save lives or request emergency blood';
  static const String registerTitle = 'Join BloodBridge';
  static const String registerSubtitle = 'Register as a donor, patient, or medical organization';
  static const String emailLabel = 'Email Address';
  static const String passwordLabel = 'Password';
  static const String fullNameLabel = 'Full Name';
  static const String phoneLabel = 'Phone Number';
  static const String selectBloodType = 'Select Blood Type';
  static const String signInBtn = 'Sign In';
  static const String signUpBtn = 'Create Account';
  static const String dontHaveAccount = "Don't have an account? Sign Up";
  static const String alreadyHaveAccount = 'Already have an account? Sign In';

  // Dashboard Strings
  static const String quickEmergencyRequest = 'Request Emergency Blood';
  static const String activeEmergencyRequests = 'Urgent Blood Requests';
  static const String nearbyDonors = 'Available Donors Nearby';
  static const String bloodBankStock = 'Blood Bank Inventory';

  // General Buttons & Placeholders
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String retry = 'Retry';
  static const String searchPlaceholder = 'Search by location, hospital, or blood type...';
}
