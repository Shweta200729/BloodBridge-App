import 'package:blood_bridge/core/models/donor_response_model.dart';
import 'package:blood_bridge/core/models/emergency_request_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmergencyRequestModel Tests', () {
    test('Valid EmergencyRequestModel passes validation', () {
      final request = EmergencyRequestModel(
        id: 'req123',
        requesterUid: 'user_abc',
        bloodGroup: 'O+',
        units: 2,
        hospitalName: 'City Central Hospital',
        city: 'Metropolis',
        contactPhone: '+1234567890',
        urgency: UrgencyLevel.critical,
        status: RequestStatus.open,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(request.validate(), isNull);
      expect(request.units, 2);
      expect(request.hospitalName, 'City Central Hospital');
      expect(request.city, 'Metropolis');
      expect(request.status.isActive, isTrue);
    });

    test('Validation catches invalid units (< 1 or > 20)', () {
      final zeroUnits = EmergencyRequestModel(
        id: 'req1',
        requesterUid: 'user_abc',
        bloodGroup: 'O+',
        units: 0,
        hospitalName: 'City Central',
        city: 'Metropolis',
        contactPhone: '+1234567890',
        createdAt: DateTime.now(),
      );
      expect(zeroUnits.validate(), contains('between 1 and 20'));

      final tooManyUnits = EmergencyRequestModel(
        id: 'req2',
        requesterUid: 'user_abc',
        bloodGroup: 'O+',
        units: 21,
        hospitalName: 'City Central',
        city: 'Metropolis',
        contactPhone: '+1234567890',
        createdAt: DateTime.now(),
      );
      expect(tooManyUnits.validate(), contains('between 1 and 20'));
    });

    test('Validation catches empty required fields', () {
      final emptyHospital = EmergencyRequestModel(
        id: 'req3',
        requesterUid: 'user_abc',
        bloodGroup: 'O+',
        units: 1,
        hospitalName: '   ',
        city: 'Metropolis',
        contactPhone: '+1234567890',
        createdAt: DateTime.now(),
      );
      expect(emptyHospital.validate(), contains('Hospital name'));

      final emptyCity = EmergencyRequestModel(
        id: 'req4',
        requesterUid: 'user_abc',
        bloodGroup: 'O+',
        units: 1,
        hospitalName: 'City Central',
        city: '',
        contactPhone: '+1234567890',
        createdAt: DateTime.now(),
      );
      expect(emptyCity.validate(), contains('City'));

      final emptyRequester = EmergencyRequestModel(
        id: 'req5',
        requesterUid: '',
        bloodGroup: 'O+',
        units: 1,
        hospitalName: 'City Central',
        city: 'Metropolis',
        contactPhone: '+1234567890',
        createdAt: DateTime.now(),
      );
      expect(emptyRequester.validate(), contains('Requester UID'));
    });

    test('Validation catches invalid blood group', () {
      final invalidBg = EmergencyRequestModel(
        id: 'req6',
        requesterUid: 'user_abc',
        bloodGroup: 'Z+',
        units: 1,
        hospitalName: 'City Central',
        city: 'Metropolis',
        contactPhone: '+1234567890',
        createdAt: DateTime.now(),
      );
      expect(invalidBg.validate(), contains('Invalid blood group'));
    });

    test('RequestStatus enum and helper extensions', () {
      expect(RequestStatus.fromString('open'), RequestStatus.open);
      expect(RequestStatus.fromString('fulfilled'), RequestStatus.fulfilled);
      expect(RequestStatus.fromString('cancelled'), RequestStatus.cancelled);
      expect(RequestStatus.fromString('closed'), RequestStatus.closed);
      expect(RequestStatus.fromString('unknown_val'), RequestStatus.open);

      expect(RequestStatus.open.isActive, isTrue);
      expect(RequestStatus.fulfilled.isActive, isFalse);
      expect(RequestStatus.cancelled.isActive, isFalse);
    });

    test('UrgencyLevel enum and helper extensions', () {
      expect(UrgencyLevel.fromString('CRITICAL'), UrgencyLevel.critical);
      expect(UrgencyLevel.fromString('critical'), UrgencyLevel.critical);
      expect(UrgencyLevel.fromString('urgent'), UrgencyLevel.urgent);
      expect(UrgencyLevel.fromString('high'), UrgencyLevel.high);
      expect(UrgencyLevel.fromString('normal'), UrgencyLevel.normal);
      expect(UrgencyLevel.fromString('unknown_level'), UrgencyLevel.normal);

      expect(UrgencyLevel.critical.label, 'CRITICAL');
      expect(UrgencyLevel.urgent.label, 'URGENT');
      expect(UrgencyLevel.high.label, 'HIGH');
      expect(UrgencyLevel.normal.label, 'NORMAL');
    });

    test('toMap serializes all required fields', () {
      final request = EmergencyRequestModel(
        id: 'req_99',
        requesterUid: 'user_99',
        bloodGroup: 'AB-',
        units: 3,
        hospitalName: 'St. Jude',
        city: 'Denver',
        contactPhone: '+1999888777',
        urgency: UrgencyLevel.high,
        status: RequestStatus.open,
        patientCaseId: 'CASE-440',
      );

      final map = request.toMap();
      expect(map['requesterUid'], 'user_99');
      expect(map['bloodGroup'], 'AB-');
      expect(map['units'], 3);
      expect(map['hospitalName'], 'St. Jude');
      expect(map['city'], 'Denver');
      expect(map['contactPhone'], '+1999888777');
      expect(map['urgency'], 'HIGH');
      expect(map['status'], 'open');
      expect(map['patientCaseId'], 'CASE-440');
    });

    test('fromMap parses document correctly', () {
      final map = {
        'requesterUid': 'user_88',
        'bloodGroup': 'B-',
        'units': 1,
        'hospitalName': 'Grace Hospital',
        'city': 'Seattle',
        'contactPhone': '+1555444333',
        'urgency': 'CRITICAL',
        'status': 'fulfilled',
        'patientCaseId': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 2, 20)),
      };

      final parsed = EmergencyRequestModel.fromMap(map, id: 'doc_88');
      expect(parsed.id, 'doc_88');
      expect(parsed.requesterUid, 'user_88');
      expect(parsed.bloodGroup, 'B-');
      expect(parsed.hospitalName, 'Grace Hospital');
      expect(parsed.urgency, UrgencyLevel.critical);
      expect(parsed.status, RequestStatus.fulfilled);
      expect(parsed.createdAt, DateTime(2026, 2, 20));
    });

    test('copyWith produces updated instance preserving others', () {
      final original = EmergencyRequestModel(
        id: 'orig_1',
        requesterUid: 'user_orig',
        bloodGroup: 'A+',
        units: 2,
        hospitalName: 'General',
        city: 'Austin',
        contactPhone: '+123',
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        status: RequestStatus.fulfilled,
        city: 'Dallas',
      );

      expect(original.status, RequestStatus.open);
      expect(original.city, 'Austin');
      expect(updated.status, RequestStatus.fulfilled);
      expect(updated.city, 'Dallas');
      expect(updated.hospitalName, 'General');
      expect(updated.bloodGroup, 'A+');
    });
  });

  group('DonorResponseModel Tests', () {
    test('buildId produces deterministic ID', () {
      final docId = DonorResponseModel.buildId(
        requestId: 'req_123',
        donorUid: 'donor_456',
      );
      expect(docId, 'req_123_donor_456');
    });

    test('DonorResponseStatus enum parses correctly', () {
      expect(DonorResponseStatus.fromString('active'),
          DonorResponseStatus.active);
      expect(DonorResponseStatus.fromString('withdrawn'),
          DonorResponseStatus.withdrawn);
      expect(DonorResponseStatus.fromString('anything_else'),
          DonorResponseStatus.active);
    });

    test('toMap and toWithdrawMap', () {
      final response = DonorResponseModel(
        id: 'req_1_donor_1',
        requestId: 'req_1',
        donorUid: 'donor_1',
        donorName: 'David Lee',
        donorBloodGroup: 'O-',
        status: DonorResponseStatus.active,
        respondedAt: DateTime(2026, 1, 10),
      );

      final map = response.toMap();
      expect(map['requestId'], 'req_1');
      expect(map['donorUid'], 'donor_1');
      expect(map['donorName'], 'David Lee');
      expect(map['donorBloodGroup'], 'O-');
      expect(map['status'], 'active');

      final withdrawMap = response.toWithdrawMap();
      expect(withdrawMap['status'], 'withdrawn');
    });

    test('fromMap parses correctly', () {
      final map = {
        'requestId': 'req_xyz',
        'donorUid': 'donor_abc',
        'donorName': 'Sarah Connor',
        'donorBloodGroup': 'AB+',
        'status': 'active',
        'respondedAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
      };

      final parsed = DonorResponseModel.fromMap(map, id: 'req_xyz_donor_abc');
      expect(parsed.id, 'req_xyz_donor_abc');
      expect(parsed.requestId, 'req_xyz');
      expect(parsed.donorUid, 'donor_abc');
      expect(parsed.donorBloodGroup, 'AB+');
      expect(parsed.status, DonorResponseStatus.active);
      expect(parsed.respondedAt, DateTime(2026, 3, 1));
    });
  });
}
