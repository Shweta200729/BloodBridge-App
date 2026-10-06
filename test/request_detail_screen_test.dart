import 'package:blood_bridge/core/models/donor_response_model.dart';
import 'package:blood_bridge/core/models/emergency_request_model.dart';
import 'package:blood_bridge/core/services/auth_service.dart';
import 'package:blood_bridge/core/services/emergency_request_service.dart';
import 'package:blood_bridge/features/emergency_requests/presentation/request_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUser extends Fake implements User {
  final String _uid;
  FakeUser([this._uid = 'hospital-uid-123']);

  @override
  String get uid => _uid;
}

void main() {
  final mockRequest = EmergencyRequestModel(
    id: 'req-1',
    requesterUid: 'hospital-uid-123',
    bloodGroup: 'A+',
    units: 2,
    hospitalName: 'aldel hospital',
    city: 'palghar',
    urgency: UrgencyLevel.urgent,
    status: RequestStatus.open,
    patientCaseId: 'KREYVS',
    createdAt: DateTime.now(),
  );

  testWidgets('RequestDetailScreen renders for hospital requester',
      (tester) async {
    final mockUser = FakeUser('hospital-uid-123');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(mockUser)),
          requestDetailProvider('req-1').overrideWith((ref) => Stream.value(mockRequest)),
          requestResponsesProvider('req-1').overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: RequestDetailScreen(requestId: 'req-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Request Details'), findsOneWidget);
    expect(find.text('aldel hospital'), findsOneWidget);
    expect(find.text('Volunteer Donor Queue'), findsOneWidget);
    expect(find.text('Mark as Fulfilled'), findsOneWidget);
    expect(find.text('Cancel SOS Request'), findsOneWidget);
  });

  testWidgets('RequestDetailScreen renders immediately with initialRequest even before stream emits',
      (tester) async {
    final mockUser = FakeUser('hospital-uid-123');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(mockUser)),
          // Stream provider that does not emit immediately
          requestDetailProvider('req-1').overrideWith((ref) => const Stream.empty()),
          requestResponsesProvider('req-1').overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          home: RequestDetailScreen(
            requestId: 'req-1',
            initialRequest: mockRequest,
          ),
        ),
      ),
    );

    await tester.pump();

    // With initialRequest, UI renders instantly without blank/loading screen!
    expect(find.text('Request Details'), findsOneWidget);
    expect(find.text('aldel hospital'), findsOneWidget);
    expect(find.text('Volunteer Donor Queue'), findsOneWidget);
  });

  testWidgets('RequestDetailScreen renders donor in queue with Select Donor button for hospital',
      (tester) async {
    final mockUser = FakeUser('hospital-uid-123');
    const mockResponse = DonorResponseModel(
      id: 'req-1_donor-1',
      requestId: 'req-1',
      donorUid: 'donor-1',
      donorName: 'Rahul Sharma',
      donorBloodGroup: 'A+',
      status: DonorResponseStatus.active,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(mockUser)),
          requestDetailProvider('req-1').overrideWith((ref) => Stream.value(mockRequest)),
          requestResponsesProvider('req-1').overrideWith((ref) => Stream.value([mockResponse])),
        ],
        child: const MaterialApp(
          home: RequestDetailScreen(requestId: 'req-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rahul Sharma'), findsOneWidget);
    expect(find.text('Select Donor'), findsOneWidget);
  });

  testWidgets('RequestDetailScreen renders instantly using selectedEmergencyRequestProvider without streams',
      (tester) async {
    final mockUser = FakeUser('hospital-uid-123');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(mockUser)),
          selectedEmergencyRequestProvider.overrideWith((ref) => mockRequest),
          requestDetailProvider('req-1').overrideWith((ref) => const Stream.empty()),
          requestResponsesProvider('req-1').overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: RequestDetailScreen(requestId: 'req-1'),
        ),
      ),
    );

    await tester.pump();

    // Renders on frame 0 using selectedEmergencyRequestProvider!
    expect(find.text('Request Details'), findsOneWidget);
    expect(find.text('aldel hospital'), findsOneWidget);
    expect(find.text('Volunteer Donor Queue'), findsOneWidget);
  });
}
