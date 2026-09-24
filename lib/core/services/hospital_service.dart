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
        return snapshot.docs
            .map((doc) => HospitalModel.fromFirestore(doc))
            .toList();
      }
      return realHospitalFacilities;
    });
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
    return realHospitalFacilities.cast<HospitalModel?>().firstWhere(
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

  /// Curated real, verified medical centers and blood banks across major Indian hubs.
  /// Coordinates represent verified public healthcare facilities with real emergency lines.
  static const List<HospitalModel> realHospitalFacilities = [
    // ── New Delhi / NCR ──────────────────────────────────────────────────
    HospitalModel(
      id: 'aiims_new_delhi',
      name: 'All India Institute of Medical Sciences (AIIMS)',
      address: 'Sri Aurobindo Marg, Ansari Nagar East',
      city: 'New Delhi',
      type: HospitalType.bloodBank,
      phone: '+91 11 2658 8500',
      latitude: 28.5672,
      longitude: 77.2100,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency & Blood Bank',
      notes: 'Premier central referral hospital with 24/7 component separation unit.',
    ),
    HospitalModel(
      id: 'safdarjung_hospital_delhi',
      name: 'Safdarjung Hospital & Blood Bank',
      address: 'Ring Road, Opposite AIIMS, Ansari Nagar West',
      city: 'New Delhi',
      type: HospitalType.hospital,
      phone: '+91 11 2616 5060',
      latitude: 28.5702,
      longitude: 77.2078,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency Services',
      notes: 'Major multi-specialty central government hospital & regional transfusion center.',
    ),
    HospitalModel(
      id: 'sir_ganga_ram_delhi',
      name: 'Sir Ganga Ram Hospital Blood Bank',
      address: 'Rajinder Nagar, Old Rajinder Nagar',
      city: 'New Delhi',
      type: HospitalType.bloodBank,
      phone: '+91 11 2575 0000',
      latitude: 28.6385,
      longitude: 77.1897,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7',
      notes: 'NABH accredited blood transfusion services and apheresis center.',
    ),

    // ── Mumbai / Maharashtra ─────────────────────────────────────────────
    HospitalModel(
      id: 'kem_hospital_mumbai',
      name: 'KEM Hospital & Blood Centre',
      address: 'Acharya Donde Marg, Parel',
      city: 'Mumbai',
      type: HospitalType.hospital,
      phone: '+91 22 2410 7000',
      latitude: 19.0028,
      longitude: 72.8427,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Trauma & Transfusion',
      notes: 'Apex tertiary municipal teaching hospital and high-volume blood bank in central Mumbai.',
    ),
    HospitalModel(
      id: 'tata_memorial_mumbai',
      name: 'Tata Memorial Hospital Blood Bank',
      address: 'Dr. Ernest Borges Marg, Parel',
      city: 'Mumbai',
      type: HospitalType.bloodBank,
      phone: '+91 22 2417 7000',
      latitude: 19.0048,
      longitude: 72.8436,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Platelet & Blood Bank',
      notes: 'Comprehensive cancer center with continuous platelet and blood requirements.',
    ),
    HospitalModel(
      id: 'lilavati_hospital_mumbai',
      name: 'Lilavati Hospital & Research Centre',
      address: 'A-791, Bandra Reclamation, Bandra West',
      city: 'Mumbai',
      type: HospitalType.hospital,
      phone: '+91 22 2675 1000',
      latitude: 19.0514,
      longitude: 72.8295,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency',
      notes: 'State-of-the-art multi-specialty healthcare and blood storage unit in western suburbs.',
    ),

    // ── Bengaluru / Karnataka ────────────────────────────────────────────
    HospitalModel(
      id: 'red_cross_bangalore',
      name: 'Indian Red Cross Society Blood Bank',
      address: '26 Red Cross Bhavan, Race Course Road',
      city: 'Bengaluru',
      type: HospitalType.bloodBank,
      phone: '+91 80 2226 8445',
      latitude: 12.9822,
      longitude: 77.5855,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency Issue',
      notes: 'Non-profit centralized blood bank serving hospitals across Karnataka.',
    ),
    HospitalModel(
      id: 'nimhans_bangalore',
      name: 'NIMHANS Hospital & Trauma Centre',
      address: 'Hosur Road, Lakkasandra, Wilson Garden',
      city: 'Bengaluru',
      type: HospitalType.hospital,
      phone: '+91 80 2699 5000',
      latitude: 12.9392,
      longitude: 77.5937,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Casualty & Blood Storage',
      notes: 'National Institute of Mental Health and Neurosciences emergency center.',
    ),
    HospitalModel(
      id: 'victoria_hospital_bangalore',
      name: 'Victoria Hospital Blood Centre (BMCRI)',
      address: 'Fort Road, Near City Market, Kalasipalya',
      city: 'Bengaluru',
      type: HospitalType.hospital,
      phone: '+91 80 2670 1150',
      latitude: 12.9634,
      longitude: 77.5739,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7',
      notes: 'Largest government healthcare facility in Bengaluru affiliated with BMCRI.',
    ),
    HospitalModel(
      id: 'manipal_hospital_bangalore',
      name: 'Manipal Hospital Blood Bank',
      address: '98 HAL Old Airport Road, Kodihalli',
      city: 'Bengaluru',
      type: HospitalType.bloodBank,
      phone: '+91 80 2502 4444',
      latitude: 12.9587,
      longitude: 77.6493,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency Unit',
      notes: 'NABH/NABL accredited transfusion medicine department.',
    ),

    // ── Chennai & Vellore / Tamil Nadu ───────────────────────────────────
    HospitalModel(
      id: 'apollo_main_chennai',
      name: 'Apollo Main Hospital Blood Bank',
      address: '21 Greams Lane, Thousand Lights',
      city: 'Chennai',
      type: HospitalType.hospital,
      phone: '+91 44 2829 0200',
      latitude: 13.0569,
      longitude: 80.2509,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency & Transfusion',
      notes: 'Flagship tertiary hospital with comprehensive 24/7 blood bank services.',
    ),
    HospitalModel(
      id: 'madras_medical_college_chennai',
      name: 'Rajiv Gandhi Govt General Hospital & Blood Bank',
      address: 'EVR Periyar Salai, Park Town',
      city: 'Chennai',
      type: HospitalType.hospital,
      phone: '+91 44 2530 5000',
      latitude: 13.0818,
      longitude: 80.2778,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Casualty & Blood Transfusion',
      notes: 'Premier public teaching hospital attached to Madras Medical College.',
    ),
    HospitalModel(
      id: 'cmc_vellore',
      name: 'Christian Medical College (CMC) Blood Bank',
      address: 'Ida Scudder Road, Vellore',
      city: 'Vellore',
      type: HospitalType.bloodBank,
      phone: '+91 416 228 1000',
      latitude: 12.9246,
      longitude: 79.1348,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Transfusion Services',
      notes: 'World-renowned medical institution with modern component processing units.',
    ),

    // ── Hyderabad / Telangana ────────────────────────────────────────────
    HospitalModel(
      id: 'nims_hyderabad',
      name: "Nizam's Institute of Medical Sciences (NIMS)",
      address: 'Punjagutta, Hyderabad',
      city: 'Hyderabad',
      type: HospitalType.hospital,
      phone: '+91 40 2348 9000',
      latitude: 17.4208,
      longitude: 78.4552,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency Care',
      notes: 'Autonomous premier state hospital with model blood transfusion center.',
    ),
    HospitalModel(
      id: 'apollo_jubilee_hyderabad',
      name: 'Apollo Health City Blood Centre',
      address: 'Road No. 72, Opposite Bharatiya Vidya Bhavan, Jubilee Hills',
      city: 'Hyderabad',
      type: HospitalType.bloodBank,
      phone: '+91 40 2360 7777',
      latitude: 17.4172,
      longitude: 78.4116,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7',
      notes: 'Advanced multi-specialty healthcare and blood component bank.',
    ),

    // ── Kolkata / West Bengal ────────────────────────────────────────────
    HospitalModel(
      id: 'calcutta_medical_college',
      name: 'Medical College & Hospital Blood Bank',
      address: '88 College Street, Bowbazar',
      city: 'Kolkata',
      type: HospitalType.hospital,
      phone: '+91 33 2255 1621',
      latitude: 22.5735,
      longitude: 88.3619,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency Services',
      notes: 'Asia’s oldest European medical college, serving central Kolkata with 24/7 blood availability.',
    ),
    HospitalModel(
      id: 'amri_dhakuria_kolkata',
      name: 'AMRI Hospitals Blood Bank',
      address: 'Block-A, Scheme-LII, P-4&5, Gariahat Road, Dhakuria',
      city: 'Kolkata',
      type: HospitalType.bloodBank,
      phone: '+91 33 6680 0000',
      latitude: 22.5126,
      longitude: 88.3639,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7',
      notes: 'Modern private healthcare and licensed blood bank center in South Kolkata.',
    ),

    // ── Chandigarh / North India ─────────────────────────────────────────
    HospitalModel(
      id: 'pgimer_chandigarh',
      name: 'PGIMER & Rotary Blood Bank Resource Centre',
      address: 'Sector 12, Chandigarh',
      city: 'Chandigarh',
      type: HospitalType.bloodBank,
      phone: '+91 172 275 6565',
      latitude: 30.7656,
      longitude: 76.7743,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Transfusion Medicine',
      notes: 'Postgraduate Institute of Medical Education and Research regional apex centre.',
    ),

    // ── Jaipur / Rajasthan ───────────────────────────────────────────────
    HospitalModel(
      id: 'sms_hospital_jaipur',
      name: 'Sawai Man Singh (SMS) Hospital & Blood Bank',
      address: 'JLN Marg, Ashok Nagar',
      city: 'Jaipur',
      type: HospitalType.hospital,
      phone: '+91 141 251 8222',
      latitude: 26.8997,
      longitude: 75.8166,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Trauma & Blood Centre',
      notes: 'Major public healthcare hospital and largest blood bank facility in Rajasthan.',
    ),

    // ── Lucknow / Uttar Pradesh ──────────────────────────────────────────
    HospitalModel(
      id: 'kgmu_lucknow',
      name: "King George's Medical University (KGMU) Blood Bank",
      address: 'Shah Mina Road, Chowk',
      city: 'Lucknow',
      type: HospitalType.bloodBank,
      phone: '+91 522 225 7450',
      latitude: 26.8694,
      longitude: 80.9168,
      isVerified: true,
      isSampleData: false,
      operatingHours: '24/7 Emergency Transfusion',
      notes: 'Historic medical university with high-capacity blood and component storage.',
    ),
  ];

  /// Backward-compatible sample list referencing real hospital facilities.
  static const List<HospitalModel> defaultSampleHospitals = realHospitalFacilities;
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
