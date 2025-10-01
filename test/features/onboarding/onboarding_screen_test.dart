import 'package:algo_playground/data/repositories/profile_repo.dart';
import 'package:algo_playground/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:algo_playground/core/models/user_profile.dart';

class FakeProfileRepo implements ProfileRepositoryBase {
  UserProfile? saved;

  @override
  Future<UserProfile?> getProfile() async => null;

  @override
  Future<void> saveProfile(UserProfile profile) async {
    saved = profile;
  }
}

void main() {
  testWidgets('Onboarding shows validation errors', (tester) async {
    final fakeRepo = FakeProfileRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );

    await tester.tap(find.text('Enter Dashboard'));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Student Number is required'), findsOneWidget);
  });

  testWidgets('Onboarding saves profile when valid', (tester) async {
    final fakeRepo = FakeProfileRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Alice');
    await tester.enterText(find.byType(TextFormField).at(1), '12345');
    await tester.tap(find.text('Enter Dashboard'));
    await tester.pumpAndSettle();

    expect(fakeRepo.saved, isNotNull);
    expect(fakeRepo.saved!.name, 'Alice');
    expect(fakeRepo.saved!.studentNumber, '12345');
  });
}
