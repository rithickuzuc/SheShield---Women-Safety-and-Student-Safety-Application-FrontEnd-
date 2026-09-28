import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheshield/main.dart';

void main() {
  testWidgets('shows the SheShield login screen', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const SheShieldApp());
    await tester.pumpAndSettle();

    expect(find.text('SheShield'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    await tester.ensureVisible(find.text('Create Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Join SheShield'), findsOneWidget);
    expect(find.text('Emergency contact'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
  });

  testWidgets('restores dashboard and logout clears the protected route', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'test-token',
      'user_id': '3',
      'user_name': 'priya',
      'user_email': 'priya@gmail.com',
      'emergency_contact_name': 'kavi',
      'emergency_contact_phone': '6369569637',
    });
    await tester.pumpWidget(const SheShieldApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome, priya'), findsOneWidget);
    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(find.text('You are safe'), findsOneWidget);
    expect(find.text('kavi'), findsOneWidget);

    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Welcome, priya'), findsNothing);
  });

  testWidgets('SMS shows an error when emergency phone is missing', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'test-token',
      'user_id': '3',
      'user_name': 'priya',
      'user_email': 'priya@gmail.com',
      'emergency_contact_name': 'kavi',
      'emergency_contact_phone': '',
    });
    await tester.pumpWidget(const SheShieldApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Send SMS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send SMS'));
    await tester.pump();

    expect(
      find.text('Emergency contact phone number is not available.'),
      findsOneWidget,
    );
  });
}
