import 'package:blood_bridge/core/constants/app_strings.dart';
import 'package:blood_bridge/core/models/emergency_request_model.dart';
import 'package:blood_bridge/core/models/user_model.dart';
import 'package:blood_bridge/core/services/auth_service.dart';
import 'package:blood_bridge/core/services/emergency_request_service.dart';
import 'package:blood_bridge/core/services/messaging_service.dart';
import 'package:blood_bridge/core/widgets/blood_request_card.dart';
import 'package:blood_bridge/features/emergency_requests/presentation/request_list_screen.dart';
import 'package:blood_bridge/features/home/presentation/home_screen.dart';
import 'package:blood_bridge/features/navigation/presentation/main_navigation_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class FakeStatefulNavigationShell extends StatefulWidget
    implements StatefulNavigationShell {
  final int _currentIndex;
  const FakeStatefulNavigationShell([this._currentIndex = 0, Key? key])
      : super(key: key);

  @override
  int get currentIndex => _currentIndex;

  @override
  void goBranch(int index, {bool initialLocation = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  State<StatefulWidget> createState() => _FakeStatefulNavigationShellState();
}

class _FakeStatefulNavigationShellState
    extends State<FakeStatefulNavigationShell> {
  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  const hospitalUser = UserModel(
    uid: 'hospital-aldel-123',
    fullName: 'aldel hospital',
    email: 'aldel@hospital.org',
    city: 'palghar',
    phone: '9876543210',
    userType: 'hospital',
    hospitalName: 'aldel hospital',
  );

  const donorUser = UserModel(
    uid: 'donor-123',
    fullName: 'Jane Donor',
    email: 'jane@donor.org',
    city: 'Mumbai',
    phone: '9876543211',
    userType: 'donor',
    bloodGroup: 'O+',
  );

  final myHospitalRequest = EmergencyRequestModel(
    id: 'req-aldel-1',
    requesterUid: 'hospital-aldel-123',
    bloodGroup: 'A+',
    units: 2,
    hospitalName: 'aldel hospital',
    city: 'palghar',
    urgency: UrgencyLevel.urgent,
    status: RequestStatus.open,
    patientCaseId: 'KREYVS',
    createdAt: DateTime.now(),
  );

  final otherHospitalRequest = EmergencyRequestModel(
    id: 'req-shweta-2',
    requesterUid: 'hospital-other-456',
    bloodGroup: 'A-',
    units: 2,
    hospitalName: 'shweta hospital',
    city: 'Mumbai',
    urgency: UrgencyLevel.critical,
    status: RequestStatus.open,
    patientCaseId: 'WIBIUC',
    createdAt: DateTime.now(),
  );

  testWidgets(
      'RequestListScreen for hospital ONLY shows its own SOS request and Manage Queue button',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider
              .overrideWith((ref) => Stream.value(hospitalUser)),
          // Hospital requests stream has ONLY aldel hospital's request
          myRequestsProvider
              .overrideWith((ref) => Stream.value([myHospitalRequest])),
          // Open requests stream has both
          openRequestsProvider(null).overrideWith(
              (ref) => Stream.value([myHospitalRequest, otherHospitalRequest])),
        ],
        child: const MaterialApp(
          home: RequestListScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify hospital broadcast title
    expect(find.text('My SOS Broadcasts'), findsOneWidget);

    // Verify ONLY aldel hospital is displayed in cards, NOT other hospital
    expect(find.widgetWithText(BloodRequestCard, 'aldel hospital'), findsOneWidget);
    expect(find.widgetWithText(BloodRequestCard, 'shweta hospital'), findsNothing);

    // Verify button says "Manage Queue", NOT "Respond"
    expect(find.text('Manage Queue'), findsOneWidget);
    expect(find.text('Respond'), findsNothing);
  });

  testWidgets(
      'HomeScreen for hospital displays hospital-specific overview and only their own broadcasts',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider
              .overrideWith((ref) => Stream.value(hospitalUser)),
          myRequestsProvider
              .overrideWith((ref) => Stream.value([myHospitalRequest])),
          openRequestsProvider(null).overrideWith(
              (ref) => Stream.value([myHospitalRequest, otherHospitalRequest])),
          myNotificationsProvider('hospital-aldel-123')
              .overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify hospital action button
    expect(find.text('BROADCAST HOSPITAL SOS REQUEST'), findsOneWidget);

    // Verify hospital stats and section title
    expect(find.text('Active Broadcasts'), findsOneWidget);
    expect(find.text('Your Active SOS Broadcasts'), findsOneWidget);

    // Verify donor-specific "My Donations" is NOT displayed
    expect(find.text('My Donations'), findsNothing);

    // Verify only aldel hospital card is displayed with Manage Queue
    expect(find.widgetWithText(BloodRequestCard, 'aldel hospital'), findsOneWidget);
    expect(find.widgetWithText(BloodRequestCard, 'shweta hospital'), findsNothing);
    expect(find.text('Manage Queue'), findsOneWidget);
    expect(find.text('Respond'), findsNothing);
  });

  testWidgets(
      'MainNavigationShell shows Donors and hides Hospitals for Hospital accounts',
      (tester) async {
    const fakeShell = FakeStatefulNavigationShell(0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider
              .overrideWith((ref) => Stream.value(hospitalUser)),
        ],
        child: const MaterialApp(
          home: MainNavigationShell(navigationShell: fakeShell),
        ),
      ),
    );

    await tester.pump();

    // Verify 4 tabs are shown for hospital (Home, Emergency, Donors, Profile)
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Emergency'), findsOneWidget);
    expect(find.text('Donors'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Hospitals tab MUST NOT be in hospital nav bar
    expect(find.text('Hospitals'), findsNothing);
  });

  testWidgets(
      'MainNavigationShell shows Hospitals and hides Donors for Donor accounts',
      (tester) async {
    const fakeShell = FakeStatefulNavigationShell(0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider
              .overrideWith((ref) => Stream.value(donorUser)),
        ],
        child: const MaterialApp(
          home: MainNavigationShell(navigationShell: fakeShell),
        ),
      ),
    );

    await tester.pump();

    // Verify 4 tabs are shown for donor (Home, Requests, Hospitals, Profile)
    expect(find.text(AppStrings.navHome), findsOneWidget);
    expect(find.text(AppStrings.navRequests), findsOneWidget);
    expect(find.text(AppStrings.navHospitals), findsOneWidget);
    expect(find.text(AppStrings.navProfile), findsOneWidget);

    // Donors tab MUST NOT be in donor nav bar
    expect(find.text(AppStrings.navDonors), findsNothing);
  });
}
