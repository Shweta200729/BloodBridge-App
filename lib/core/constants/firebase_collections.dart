class FirebaseCollections {
  FirebaseCollections._();

  static const String users = 'users';
  static const String donors = 'donors';
  static const String emergencyRequests = 'emergency_requests';
  static const String donorResponses = 'responses'; // subcollection under emergency_requests
  static const String hospitals = 'hospitals';
  static const String bloodBanks = 'blood_banks';
  static const String donations = 'donations';
  static const String notifications = 'notifications';

  // Storage Folders
  static const String profileImages = 'profile_images';
  static const String medicalDocs = 'medical_docs';
  static const String hospitalLogos = 'hospital_logos';
}

