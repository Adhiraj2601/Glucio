import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucio/data/models/user_preferences.dart';
import 'package:glucio/data/repositories/product_repository.dart';
import 'package:glucio/features/log/presentation/providers/daily_tracker_providers.dart';
import 'package:glucio/features/preferences/presentation/preferences_screen.dart';
import 'package:glucio/features/preferences/presentation/widgets/preference_importance_selector.dart';

void main() {
  group('PreferencesScreen Widget Tests', () {
    testWidgets('renders all preference categories, criteria, and importance selector',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final initialPrefs = UserPreferences.defaults();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPreferencesProvider.overrideWith(() => _MockUserPreferencesNotifier(initialPrefs)),
            dailyLimitProvider.overrideWith(() => _MockDailyLimitNotifier(25.0)),
          ],
          child: const MaterialApp(
            home: PreferencesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header & Top Banner
      expect(find.text('Personal Preferences'), findsOneWidget);
      expect(find.text('Personalized Food Alerts'), findsOneWidget);

      // Check Category Filter Chips
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.textContaining('Allergens'), findsWidgets);
      expect(find.textContaining('Dietary Restrictions'), findsWidgets);
      expect(find.textContaining('Nutritional Priorities'), findsWidgets);

      // Check specific criteria items
      expect(find.text('Milk & Dairy'), findsOneWidget);
      expect(find.text('Gluten / Wheat'), findsOneWidget);
      expect(find.text('Vegetarian'), findsOneWidget);
      expect(find.text('Vegan'), findsOneWidget);
      expect(find.text('Palm Oil Free'), findsOneWidget);
      expect(find.text('Low Sugar (WHO 25g)'), findsOneWidget);
      expect(find.textContaining('WHO Limit: 25g/day'), findsOneWidget);

      // Verify PreferenceImportanceSelector is present
      expect(find.byType(PreferenceImportanceSelector), findsWidgets);
    });

    testWidgets('filters list when category filter chip is tapped',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final initialPrefs = UserPreferences.defaults();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPreferencesProvider.overrideWith(() => _MockUserPreferencesNotifier(initialPrefs)),
            dailyLimitProvider.overrideWith(() => _MockDailyLimitNotifier(25.0)),
          ],
          child: const MaterialApp(
            home: PreferencesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Dietary Restrictions' filter chip
      final dietChip = find.textContaining('Dietary Restrictions (3)');
      expect(dietChip, findsOneWidget);
      await tester.tap(dietChip);
      await tester.pumpAndSettle();

      // In filtered view, diet items exist but allergen items are hidden
      expect(find.text('Vegetarian'), findsOneWidget);
      expect(find.text('Vegan'), findsOneWidget);
      expect(find.text('Palm Oil Free'), findsOneWidget);
      expect(find.text('Milk & Dairy'), findsNothing);
      expect(find.text('Gluten / Wheat'), findsNothing);
    });

    testWidgets('tapping importance updates criterion state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = _MockUserPreferencesNotifier(UserPreferences.defaults());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPreferencesProvider.overrideWith(() => notifier),
            dailyLimitProvider.overrideWith(() => _MockDailyLimitNotifier(25.0)),
          ],
          child: const MaterialApp(
            home: PreferencesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Gluten is initially Not important
      expect(notifier.getImportance('allergen_gluten'), PreferenceImportance.notImportant);

      // Find the Gluten criterion row and tap 'Mandatory'
      // There are multiple 'Mandatory' buttons on screen; find the one near Gluten
      final mandatoryButtons = find.text('Mandatory');
      expect(mandatoryButtons, findsWidgets);

      // Tap the second Mandatory button (for Gluten / Wheat)
      await tester.tap(mandatoryButtons.at(1));
      await tester.pumpAndSettle();

      // Verify the notifier received the update
      expect(notifier.getImportance('allergen_gluten'), PreferenceImportance.mandatory);
    });

    testWidgets('reset button opens confirmation dialog and restores defaults',
        (WidgetTester tester) async {
      final defaults = UserPreferences.defaults();
      final modified = defaults.copyWith(
        criteria: Map<String, PreferenceCriterion>.from(defaults.criteria)
          ..['allergen_peanuts'] = defaults.criteria['allergen_peanuts']!.copyWith(
            importance: PreferenceImportance.mandatory,
          ),
      );
      final notifier = _MockUserPreferencesNotifier(modified);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPreferencesProvider.overrideWith(() => notifier),
            dailyLimitProvider.overrideWith(() => _MockDailyLimitNotifier(25.0)),
          ],
          child: const MaterialApp(
            home: PreferencesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(notifier.getImportance('allergen_peanuts'), PreferenceImportance.mandatory);

      // Tap reset icon in AppBar
      final resetBtn = find.byTooltip('Reset to Defaults');
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Reset Preferences?'), findsOneWidget);

      // Tap 'Reset All' button in dialog
      await tester.tap(find.text('Reset All'));
      await tester.pumpAndSettle();

      // Peanuts is reset back to Not important
      expect(notifier.getImportance('allergen_peanuts'), PreferenceImportance.notImportant);
    });
  });
}

class _MockUserPreferencesNotifier extends UserPreferencesNotifier {
  final UserPreferences _initial;
  _MockUserPreferencesNotifier(this._initial);

  @override
  Future<UserPreferences> build() async => _initial;

  @override
  Future<void> updateCriterion(String id, PreferenceImportance importance) async {
    final current = state.value ?? _initial;
    final existing = current.getCriterion(id);
    if (existing == null) return;
    final updated = existing.copyWith(
      importance: importance,
      updatedAt: DateTime.now(),
    );
    final newMap = Map<String, PreferenceCriterion>.from(current.criteria)..[id] = updated;
    state = AsyncData(current.copyWith(criteria: newMap));
  }

  @override
  Future<void> resetToDefaults() async {
    state = AsyncData(UserPreferences.defaults());
  }

  PreferenceImportance getImportance(String id) =>
      state.value?.getCriterion(id)?.importance ?? PreferenceImportance.notImportant;
}

class _MockDailyLimitNotifier extends DailyLimitNotifier {
  final double _initial;
  _MockDailyLimitNotifier(this._initial);

  @override
  Future<double> build() async => _initial;

  @override
  Future<void> updateLimit(double newLimit) async {
    state = AsyncData(newLimit);
  }
}
