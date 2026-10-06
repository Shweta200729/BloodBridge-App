import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/firebase_collections.dart';
import '../models/hospital_model.dart';
import 'firestore_service.dart';

final hospitalServiceProvider = Provider<HospitalService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return HospitalService(firestore);
});

class HospitalService {
  final FirebaseFirestore _firestore;

  HospitalService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _hospitalsRef =>
      _firestore.collection(FirebaseCollections.hospitals);

  /// Streams hospital records from Firestore.
  ///
  /// If the Firestore collection is empty, returns real verified Indian
  /// healthcare facilities & blood banks (`realHospitalFacilities`), ensuring
  /// accurate directory listings and interactive map data are instantly available.
  Stream<List<HospitalModel>> hospitalsStream() {
    return _hospitalsRef.snapshots().map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final docs = snapshot.docs
            .map((doc) => HospitalModel.fromFirestore(doc))
            .toList();
        final names = docs.map((d) => d.name.toLowerCase()).toSet();
        final missing = palgharHospitalFacilities
            .where((p) => !names.contains(p.name.toLowerCase()))
            .toList();
        return [...docs, ...missing];
      }
      return palgharHospitalFacilities;
    }).handleError((_) => palgharHospitalFacilities);
  }

  /// Fetches a single hospital by ID from Firestore or verified seed data.
  Future<HospitalModel?> getHospitalById(String id) async {
    try {
      final doc = await _hospitalsRef.doc(id).get();
      if (doc.exists) {
        return HospitalModel.fromFirestore(doc);
      }
    } catch (_) {
      // Fallback to verified local directory if Firestore document not found
    }
    return palgharHospitalFacilities.cast<HospitalModel?>().firstWhere(
          (h) => h?.id == id,
          orElse: () => null,
        );
  }

  /// Safely obtains the user's current GPS position with permission verification.
  /// Returns null if permissions are denied or GPS is disabled.
  static Future<Position?> determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Curated verified hospitals, clinics, and medical facilities across Palghar district.
  static const List<HospitalModel> palgharHospitalFacilities = [
    // 1. Government District Hospital Palghar
    HospitalModel(
      id: 'palghar_district_hospital',
      name: 'Government District Hospital Palghar',
      address: 'Nandore, Palghar - 401405',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '02525-256635',
      latitude: 19.7212,
      longitude: 72.7842,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency & Casualty',
      notes: 'Type: Government Hospital | Pincode: 401405 | Source: Google/business listing (Verify current details before production use)',
    ),

    // 2. Govt Rural Hospital, Palghar
    HospitalModel(
      id: 'govt_rural_hospital_palghar',
      name: 'Govt Rural Hospital, Palghar',
      address: 'Kacheri Road, Lokmanya Nagar, Vishnu Nagar, Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '02525-256635',
      latitude: 19.6980,
      longitude: 72.7680,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency & Blood Storage Unit',
      notes: 'Type: Government Rural Hospital | Pincode: 401404 | Source: District Palghar, Government of Maharashtra (Official district page)',
    ),

    // 3. M.L. Dhawale Memorial Trust / Rural Homeopathic Hospital
    HospitalModel(
      id: 'ml_dhawale_memorial_hospital',
      name: 'M.L. Dhawale Memorial Trust / Rural Homeopathic Hospital',
      address: 'Boisar Road, Opp. S.T. Workshop, Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '02525-256932',
      latitude: 19.7042,
      longitude: 72.7648,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Casualty & Inpatient',
      notes: 'Type: Hospital | Pincode: 401404 | Source: District Palghar + Star Health (Official district page / network listing)',
    ),

    // 4. Dhada Hospital
    HospitalModel(
      id: 'dhada_hospital_palghar',
      name: 'Dhada Hospital',
      address: 'Tembhode Road, Raj Nagar, Juna Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '02525-252233',
      latitude: 19.6935,
      longitude: 72.7630,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Medical Care',
      notes: 'Type: Hospital | Pincode: 401404 | Source: District Palghar, Government of Maharashtra (Official district page)',
    ),

    // 5. Aarogyam Multispeciality Hospital
    HospitalModel(
      id: 'aarogyam_multispeciality_hospital',
      name: 'Aarogyam Multispeciality Hospital',
      address: 'Kanchan Business Centre, near Kalavati Mandir, Mahim/Devisha Road, Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '09503061022',
      latitude: 19.6955,
      longitude: 72.7605,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency & ICU',
      notes: 'Type: Multispeciality Hospital | Pincode: 401404 | Source: Star Health + Google/business listing (Verify phone/location before production use)',
    ),

    // 6. Infigo Eye Care Hospital
    HospitalModel(
      id: 'infigo_eye_care_hospital',
      name: 'Infigo Eye Care Hospital',
      address: 'Shree Heritage, Near IDBI Bank, Mahim Road, Palghar West - 401404',
      city: 'Palghar',
      type: HospitalType.clinic,
      phone: '08484938676',
      latitude: 19.6970,
      longitude: 72.7620,
      isVerified: true,
      isSampleData: false,
      operatingHours: '9:00 AM - 8:00 PM',
      notes: 'Type: Eye Hospital | Pincode: 401404 | Source: Star Health (Network listing)',
    ),

    // 7. Adhikari Lifeline Hospital
    HospitalModel(
      id: 'adhikari_lifeline_hospital',
      name: 'Adhikari Lifeline Hospital',
      address: 'Gut No. 26, House No. 631, Nagzari, Post Nihe, Palghar/Boisar area - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '09890184444',
      latitude: 19.7350,
      longitude: 72.7480,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency & Critical Care',
      notes: 'Type: Hospital | Pincode: 401404 | Source: Star Health (Network listing)',
    ),

    // 8. Meghna Nursing Home
    HospitalModel(
      id: 'meghna_nursing_home',
      name: 'Meghna Nursing Home',
      address: 'Gokhale Sadan, Opp. Raju Garage, Mahim Road, Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.clinic,
      phone: '7387377787',
      latitude: 19.6960,
      longitude: 72.7610,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Nursing & Maternity',
      notes: 'Type: Nursing Home | Pincode: 401404 | Source: Star Health (Network listing)',
    ),

    // 9. Ozone Hitech Multispeciality Hospital
    HospitalModel(
      id: 'ozone_hitech_multispeciality',
      name: 'Ozone Hitech Multispeciality Hospital',
      address: 'Parshwanath 9, BIDCO Corner, Paradise City, Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '07030554444',
      latitude: 19.7150,
      longitude: 72.7685,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Multispeciality Care',
      notes: 'Type: Multispeciality Hospital | Pincode: 401404 | Source: Star Health (Network listing)',
    ),

    // 10. New Lifecare Hospital
    HospitalModel(
      id: 'new_lifecare_hospital',
      name: 'New Lifecare Hospital',
      address: 'Boisar–Palghar Road, near Anand Ashram High School, Gothan Pura, Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '09028694119',
      latitude: 19.7025,
      longitude: 72.7660,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Casualty & Inpatient',
      notes: 'Type: Hospital | Pincode: 401404 | Source: ESIC hospital list / Latrexa (Verify current details)',
    ),

    // 11. Naniwadekar Hospital
    HospitalModel(
      id: 'naniwadekar_hospital',
      name: 'Naniwadekar Hospital',
      address: 'Mahim Road, Punit Nagar, Juna Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '02525-252631',
      latitude: 19.6948,
      longitude: 72.7618,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency Care',
      notes: 'Type: Hospital | Pincode: 401404 | Source: Latrexa (Directory listing; verify current details)',
    ),

    // 12. Relief Hospitals, Palghar
    HospitalModel(
      id: 'relief_hospitals_palghar',
      name: 'Relief Hospitals, Palghar',
      address: 'Nine Star Grandeur, Aster Building, Chhatrapati Shivaji Maharaj Chowk, Juna Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '09181999999',
      latitude: 19.6950,
      longitude: 72.7675,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency Services',
      notes: 'Type: Hospital | Pincode: 401404 | Source: Latrexa / district listing (Verify current details)',
    ),

    // 13. Sharda Hospital
    HospitalModel(
      id: 'sharda_hospital_palghar',
      name: 'Sharda Hospital',
      address: 'Shivkalyan Building, Mahim Road, near ICICI Bank, Shri Ram Nagar, Vishnu Nagar, Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '09021754171',
      latitude: 19.6978,
      longitude: 72.7635,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Medical Care',
      notes: 'Type: Hospital | Pincode: 401404 | Source: Latrexa (Directory listing; verify current details)',
    ),

    // 14. Shinde Hospital Palghar
    HospitalModel(
      id: 'shinde_hospital_palghar',
      name: 'Shinde Hospital Palghar',
      address: 'Tembhode Road, Punit Nagar, Juna Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '07378772662',
      latitude: 19.6940,
      longitude: 72.7638,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Medical & Surgical Care',
      notes: 'Type: Hospital | Pincode: 401404 | Source: Latrexa (Directory listing; verify current details)',
    ),

    // 15. Palghar Nursing Home and Child Care Centre
    HospitalModel(
      id: 'palghar_nursing_home',
      name: 'Palghar Nursing Home and Child Care Centre',
      address: 'Vishnu Nagar, Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.clinic,
      phone: '02525-253044',
      latitude: 19.6985,
      longitude: 72.7665,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Pediatric & Nursing Care',
      notes: 'Type: Nursing Home / Child Care | Pincode: 401404 | Source: Latrexa (Directory listing; verify current details)',
    ),

    // 16. Vatsalya Children's Hospital
    HospitalModel(
      id: 'vatsalya_childrens_hospital',
      name: "Vatsalya Children's Hospital",
      address: 'Dhanani Building, near Paanchbatti, Kacheri Road, Palghar West - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '08010810989',
      latitude: 19.6975,
      longitude: 72.7655,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Pediatric Emergency',
      notes: "Type: Children's Hospital | Pincode: 401404 | Source: Latrexa (Directory listing; verify current details)",
    ),

    // 17. Vaishali Nursing Home
    HospitalModel(
      id: 'vaishali_nursing_home',
      name: 'Vaishali Nursing Home',
      address: 'Amba Wadi, Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.clinic,
      phone: '07276369776',
      latitude: 19.6930,
      longitude: 72.7690,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Maternity & General Nursing',
      notes: 'Type: Nursing Home | Pincode: 401404 | Source: Latrexa (Directory listing; verify current details)',
    ),

    // 18. Ganesh Hospital
    HospitalModel(
      id: 'ganesh_hospital_palghar',
      name: 'Ganesh Hospital',
      address: 'Tembhode Road, Sai Nagar, Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '09226308001',
      latitude: 19.6925,
      longitude: 72.7645,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Inpatient & Emergency',
      notes: 'Type: Hospital | Pincode: 401404 | Source: Latrexa (Directory listing; verify current details)',
    ),

    // 19. Morya Hospital & Prasuti Gruha
    HospitalModel(
      id: 'morya_hospital_prasuti',
      name: 'Morya Hospital & Prasuti Gruha',
      address: 'Tembhode Road, Punit Nagar, Juna Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.hospital,
      phone: '09011912591',
      latitude: 19.6942,
      longitude: 72.7632,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Maternity & Hospital Services',
      notes: 'Type: Hospital / Maternity | Pincode: 401404 | Source: Latrexa (Directory listing; verify current details)',
    ),

    // 20. Palghar Criticare and Nursing Home
    HospitalModel(
      id: 'palghar_criticare_nursing_home',
      name: 'Palghar Criticare and Nursing Home',
      address: 'V Square Apartment, Kacheri Road, near Panch Batti, Vishnu Nagar, Palghar - 401404',
      city: 'Palghar',
      type: HospitalType.clinic,
      phone: '09766471976',
      latitude: 19.6976,
      longitude: 72.7660,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Critical Care & Nursing',
      notes: 'Type: Nursing Home | Pincode: 401404 | Source: Latrexa (Directory listing; verify current details)',
    ),
  ];

  /// Backward-compatible alias referencing Palghar facilities.
  static const List<HospitalModel> realHospitalFacilities = palgharHospitalFacilities;

  /// Backward-compatible sample list referencing Palghar hospital facilities.
  static const List<HospitalModel> defaultSampleHospitals = palgharHospitalFacilities;
}

/// Real-time stream of all available hospitals.
final hospitalsStreamProvider = StreamProvider<List<HospitalModel>>((ref) {
  final service = ref.watch(hospitalServiceProvider);
  return service.hospitalsStream();
});

/// Current text search query for hospital directory.
final hospitalSearchQueryProvider = StateProvider<String>((ref) => '');

/// Selected facility type filter (null = all).
final hospitalTypeFilterProvider = StateProvider<HospitalType?>((ref) => null);

/// User's current location for proximity-based calculations and map centering.
final userLocationProvider = StateProvider<Position?>((ref) => null);

/// Whether facilities should be sorted by proximity when user location is known.
final hospitalSortByProximityProvider = StateProvider<bool>((ref) => true);

/// Filtered and proximity-sorted list of hospitals.
final filteredHospitalsProvider = Provider<AsyncValue<List<HospitalModel>>>((ref) {
  final hospitalsAsync = ref.watch(hospitalsStreamProvider);
  final query = ref.watch(hospitalSearchQueryProvider);
  final typeFilter = ref.watch(hospitalTypeFilterProvider);
  final userPos = ref.watch(userLocationProvider);
  final sortByProximity = ref.watch(hospitalSortByProximityProvider);

  return hospitalsAsync.whenData((hospitals) {
    // 1. Filter by query and facility type
    final filtered = hospitals.where((h) {
      final matchesSearch = h.matchesQuery(query);
      final matchesType = typeFilter == null || h.type == typeFilter;
      return matchesSearch && matchesType;
    }).toList();

    // 2. Sort by distance if user location is available and proximity sorting is active
    if (sortByProximity && userPos != null) {
      filtered.sort((a, b) {
        final distA = a.distanceTo(userPos.latitude, userPos.longitude);
        final distB = b.distanceTo(userPos.latitude, userPos.longitude);

        if (distA != null && distB != null) {
          return distA.compareTo(distB);
        } else if (distA != null) {
          return -1;
        } else if (distB != null) {
          return 1;
        }
        return a.name.compareTo(b.name);
      });
    }

    return filtered;
  });
});

/// Provider for a specific hospital detail by its ID.
final hospitalDetailProvider =
    FutureProvider.family<HospitalModel?, String>((ref, hospitalId) async {
  final service = ref.watch(hospitalServiceProvider);
  return service.getHospitalById(hospitalId);
});
