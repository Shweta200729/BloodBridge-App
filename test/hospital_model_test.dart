import 'package:blood_bridge/core/models/hospital_model.dart';
import 'package:blood_bridge/core/services/hospital_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HospitalModel Unit Tests', () {
    test('Default values and field assignments', () {
      const hospital = HospitalModel(
        id: 'hosp_01',
        name: 'Apollo Hospital',
        address: '12 Health Blvd',
        city: 'Chennai',
        phone: '+91 44 1234 5678',
        latitude: 13.0827,
        longitude: 80.2707,
        isVerified: true,
        isSampleData: false,
        operatingHours: '24/7',
        notes: 'Emergency trauma center',
      );

      expect(hospital.id, 'hosp_01');
      expect(hospital.name, 'Apollo Hospital');
      expect(hospital.address, '12 Health Blvd');
      expect(hospital.city, 'Chennai');
      expect(hospital.type, HospitalType.hospital);
      expect(hospital.phone, '+91 44 1234 5678');
      expect(hospital.hasCoordinates, isTrue);
      expect(hospital.hasPhone, isTrue);
      expect(hospital.hasAddress, isTrue);
      expect(hospital.isVerified, isTrue);
      expect(hospital.isSampleData, isFalse);
    });

    test('Handling of missing optional fields', () {
      const hospital = HospitalModel(
        id: 'hosp_minimal',
        name: 'Community Clinic',
        address: 'Sector 4',
        city: 'Pune',
      );

      expect(hospital.phone, isNull);
      expect(hospital.latitude, isNull);
      expect(hospital.longitude, isNull);
      expect(hospital.operatingHours, isNull);
      expect(hospital.notes, isNull);
      expect(hospital.hasCoordinates, isFalse);
      expect(hospital.hasPhone, isFalse);
      expect(hospital.hasAddress, isTrue);
      expect(hospital.isVerified, isFalse);
      expect(hospital.isSampleData, isFalse);
    });

    test('Coordinate validation logic (bounds checking)', () {
      const validHospital = HospitalModel(
        id: 'h1',
        name: 'Valid Coordinates',
        address: 'Center St',
        city: 'Delhi',
        latitude: 28.6139,
        longitude: 77.2090,
      );
      expect(validHospital.hasCoordinates, isTrue);

      const missingLat = HospitalModel(
        id: 'h2',
        name: 'Missing Lat',
        address: 'Center St',
        city: 'Delhi',
        longitude: 77.2090,
      );
      expect(missingLat.hasCoordinates, isFalse);

      const invalidLat = HospitalModel(
        id: 'h3',
        name: 'Invalid Lat',
        address: 'Center St',
        city: 'Delhi',
        latitude: 120.0, // Out of [-90, 90]
        longitude: 77.2090,
      );
      expect(invalidLat.hasCoordinates, isFalse);

      const invalidLng = HospitalModel(
        id: 'h4',
        name: 'Invalid Lng',
        address: 'Center St',
        city: 'Delhi',
        latitude: 28.6139,
        longitude: 200.0, // Out of [-180, 180]
      );
      expect(invalidLng.hasCoordinates, isFalse);
    });

    test('HospitalType enum parsing and labels', () {
      expect(HospitalType.fromString('hospital'), HospitalType.hospital);
      expect(HospitalType.fromString('bloodbank'), HospitalType.bloodBank);
      expect(HospitalType.fromString('blood_bank'), HospitalType.bloodBank);
      expect(HospitalType.fromString('blood bank'), HospitalType.bloodBank);
      expect(HospitalType.fromString('clinic'), HospitalType.clinic);
      expect(HospitalType.fromString('unknown_type'), HospitalType.hospital);

      expect(HospitalType.hospital.label, 'Hospital');
      expect(HospitalType.bloodBank.label, 'Blood Bank');
      expect(HospitalType.clinic.label, 'Clinic');
    });

    test('toMap and fromMap serialization roundtrip', () {
      const original = HospitalModel(
        id: 'test_blood_bank',
        name: 'Rotary Blood Bank',
        address: 'Plot 5, Tughlakabad',
        city: 'New Delhi',
        type: HospitalType.bloodBank,
        phone: '+91 11 2995 5678',
        latitude: 28.5100,
        longitude: 77.2600,
        isVerified: true,
        isSampleData: false,
        operatingHours: '9 AM - 6 PM',
        notes: 'Donor screening required',
      );

      final map = original.toMap();
      expect(map['name'], 'Rotary Blood Bank');
      expect(map['address'], 'Plot 5, Tughlakabad');
      expect(map['city'], 'New Delhi');
      expect(map['type'], 'bloodBank');
      expect(map['phone'], '+91 11 2995 5678');
      expect(map['latitude'], 28.5100);
      expect(map['longitude'], 77.2600);
      expect(map['isVerified'], isTrue);
      expect(map['isSampleData'], isFalse);

      final restored = HospitalModel.fromMap(map, id: 'test_blood_bank');
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.address, original.address);
      expect(restored.city, original.city);
      expect(restored.type, HospitalType.bloodBank);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.isVerified, isTrue);
      expect(restored.isSampleData, isFalse);
    });

    test('matchesQuery searches across name, city, and address', () {
      const facility = HospitalModel(
        id: 'f1',
        name: 'St. Jude Children Hospital',
        address: '501 Danny Thomas Place',
        city: 'Memphis',
      );

      // Matches name
      expect(facility.matchesQuery('jude'), isTrue);
      expect(facility.matchesQuery('ST. JUDE'), isTrue);

      // Matches city
      expect(facility.matchesQuery('memphis'), isTrue);

      // Matches address
      expect(facility.matchesQuery('danny thomas'), isTrue);

      // Non-match
      expect(facility.matchesQuery('seattle'), isFalse);

      // Empty query matches everything
      expect(facility.matchesQuery(''), isTrue);
      expect(facility.matchesQuery('   '), isTrue);
    });

    test('copyWith produces modified copy without mutating original', () {
      const original = HospitalModel(
        id: 'orig',
        name: 'Original Name',
        address: 'Orig Address',
        city: 'Orig City',
        isVerified: false,
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        isVerified: true,
      );

      expect(original.name, 'Original Name');
      expect(original.isVerified, false);
      expect(updated.name, 'Updated Name');
      expect(updated.isVerified, true);
      expect(updated.city, 'Orig City');
    });

    test('distanceTo and formattedDistanceTo accurately calculate and format distance', () {
      const facility = HospitalModel(
        id: 'delhi_aiims',
        name: 'AIIMS New Delhi',
        address: 'Ansari Nagar East',
        city: 'New Delhi',
        latitude: 28.5672,
        longitude: 77.2100,
      );

      // Distance to nearby point (e.g. 28.5702, 77.2078 ~ 400 meters)
      final distKm = facility.distanceTo(28.5702, 77.2078);
      expect(distKm, isNotNull);
      expect(distKm!, lessThan(2.0));

      final formattedShort = facility.formattedDistanceTo(28.5702, 77.2078);
      expect(formattedShort, contains('m away'));

      // Distance to Bangalore (~1700 km)
      final distFar = facility.distanceTo(12.9716, 77.5946);
      expect(distFar, isNotNull);
      expect(distFar!, greaterThan(1000.0));

      final formattedFar = facility.formattedDistanceTo(12.9716, 77.5946);
      expect(formattedFar, contains('km away'));

      // Facility without coordinates returns null
      const noCoords = HospitalModel(
        id: 'no_coords',
        name: 'No Coords Clinic',
        address: 'Main Rd',
        city: 'Pune',
      );
      expect(noCoords.distanceTo(28.5, 77.2), isNull);
      expect(noCoords.formattedDistanceTo(28.5, 77.2), isNull);
    });
  });

  group('HospitalService Real Facilities Data Integrity Tests', () {
    test('All real hospital facilities have verified attributes and coordinates', () {
      final facilities = HospitalService.realHospitalFacilities;
      expect(facilities, isNotEmpty);
      expect(facilities.length, greaterThanOrEqualTo(10));

      for (final f in facilities) {
        expect(f.isVerified, isTrue,
            reason: '${f.name} should be verified');
        expect(f.hasCoordinates, isTrue,
            reason: '${f.name} must have valid coordinates');
        expect(f.hasPhone, isTrue,
            reason: '${f.name} must have phone contact');
        expect(f.hasAddress, isTrue,
            reason: '${f.name} must have address');
        expect(f.city.isNotEmpty, isTrue,
            reason: '${f.name} must have a city');
      }
    });
  });
}
