// Mocks generated by Mockito 5.4.5 from annotations
// in workout_tracker/test/workout_recording_page_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:mockito/mockito.dart' as _i1;
import 'package:workout_tracker/models/workout.dart' as _i5;
import 'package:workout_tracker/models/workout_plan.dart' as _i3;
import 'package:workout_tracker/services/workout_service.dart' as _i2;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

/// A class which mocks [WorkoutService].
///
/// See the documentation for Mockito's code generation for more information.
class MockWorkoutService extends _i1.Mock implements _i2.WorkoutService {
  MockWorkoutService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  List<_i3.WorkoutPlan> getWorkoutPlans() => (super.noSuchMethod(
        Invocation.method(
          #getWorkoutPlans,
          [],
        ),
        returnValue: <_i3.WorkoutPlan>[],
      ) as List<_i3.WorkoutPlan>);

  @override
  _i4.Future<bool> downloadWorkoutPlan(String? url) => (super.noSuchMethod(
        Invocation.method(
          #downloadWorkoutPlan,
          [url],
        ),
        returnValue: _i4.Future<bool>.value(false),
      ) as _i4.Future<bool>);

  @override
  List<_i5.Workout> getWorkouts() => (super.noSuchMethod(
        Invocation.method(
          #getWorkouts,
          [],
        ),
        returnValue: <_i5.Workout>[],
      ) as List<_i5.Workout>);

  @override
  List<_i5.Workout> getRecentWorkouts(int? days) => (super.noSuchMethod(
        Invocation.method(
          #getRecentWorkouts,
          [days],
        ),
        returnValue: <_i5.Workout>[],
      ) as List<_i5.Workout>);

  @override
  _i4.Future<void> saveWorkout(_i5.Workout? workout) => (super.noSuchMethod(
        Invocation.method(
          #saveWorkout,
          [workout],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> deleteWorkout(int? index) => (super.noSuchMethod(
        Invocation.method(
          #deleteWorkout,
          [index],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> clearAll() => (super.noSuchMethod(
        Invocation.method(
          #clearAll,
          [],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);
}
