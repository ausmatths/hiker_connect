// Mocks generated by Mockito 5.4.5 from annotations
// in hiker_connect/test/common/initialization_screen_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;
import 'dart:ui' as _i7;

import 'package:hiker_connect/models/event_data.dart' as _i3;
import 'package:hiker_connect/models/event_filter.dart' as _i6;
import 'package:hiker_connect/models/events_view_type.dart' as _i4;
import 'package:hiker_connect/providers/events_provider.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;

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

/// A class which mocks [EventsProvider].
///
/// See the documentation for Mockito's code generation for more information.
class MockEventsProvider extends _i1.Mock implements _i2.EventsProvider {
  MockEventsProvider() {
    _i1.throwOnMissingStub(this);
  }

  @override
  bool get hasMoreEvents => (super.noSuchMethod(
        Invocation.getter(#hasMoreEvents),
        returnValue: false,
      ) as bool);

  @override
  bool get isLoadingMore => (super.noSuchMethod(
        Invocation.getter(#isLoadingMore),
        returnValue: false,
      ) as bool);

  @override
  List<_i3.EventData> get events => (super.noSuchMethod(
        Invocation.getter(#events),
        returnValue: <_i3.EventData>[],
      ) as List<_i3.EventData>);

  @override
  List<_i3.EventData> get allEvents => (super.noSuchMethod(
        Invocation.getter(#allEvents),
        returnValue: <_i3.EventData>[],
      ) as List<_i3.EventData>);

  @override
  List<_i3.EventData> get pastEvents => (super.noSuchMethod(
        Invocation.getter(#pastEvents),
        returnValue: <_i3.EventData>[],
      ) as List<_i3.EventData>);

  @override
  List<_i3.EventData> get currentEvents => (super.noSuchMethod(
        Invocation.getter(#currentEvents),
        returnValue: <_i3.EventData>[],
      ) as List<_i3.EventData>);

  @override
  List<_i3.EventData> get futureEvents => (super.noSuchMethod(
        Invocation.getter(#futureEvents),
        returnValue: <_i3.EventData>[],
      ) as List<_i3.EventData>);

  @override
  List<_i3.EventData> get favoriteEvents => (super.noSuchMethod(
        Invocation.getter(#favoriteEvents),
        returnValue: <_i3.EventData>[],
      ) as List<_i3.EventData>);

  @override
  bool get isLoading => (super.noSuchMethod(
        Invocation.getter(#isLoading),
        returnValue: false,
      ) as bool);

  @override
  bool get isUsingLocalData => (super.noSuchMethod(
        Invocation.getter(#isUsingLocalData),
        returnValue: false,
      ) as bool);

  @override
  bool get isAuthenticated => (super.noSuchMethod(
        Invocation.getter(#isAuthenticated),
        returnValue: false,
      ) as bool);

  @override
  bool get initialized => (super.noSuchMethod(
        Invocation.getter(#initialized),
        returnValue: false,
      ) as bool);

  @override
  _i4.EventsViewType get currentViewType => (super.noSuchMethod(
        Invocation.getter(#currentViewType),
        returnValue: _i4.EventsViewType.list,
      ) as _i4.EventsViewType);

  @override
  bool get hasListeners => (super.noSuchMethod(
        Invocation.getter(#hasListeners),
        returnValue: false,
      ) as bool);

  @override
  _i5.Future<void> initialize() => (super.noSuchMethod(
        Invocation.method(
          #initialize,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<bool> createEvent(_i3.EventData? event) => (super.noSuchMethod(
        Invocation.method(
          #createEvent,
          [event],
        ),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);

  @override
  _i5.Future<void> fetchEvents({bool? loadMore = false}) => (super.noSuchMethod(
        Invocation.method(
          #fetchEvents,
          [],
          {#loadMore: loadMore},
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> fetchEventsByTimePeriod(
    bool? includePast,
    bool? includeCurrent,
    bool? includeFuture,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #fetchEventsByTimePeriod,
          [
            includePast,
            includeCurrent,
            includeFuture,
          ],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> fetchNearbyEvents({
    required double? latitude,
    required double? longitude,
    required double? radiusInKm,
    String? keyword,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #fetchNearbyEvents,
          [],
          {
            #latitude: latitude,
            #longitude: longitude,
            #radiusInKm: radiusInKm,
            #keyword: keyword,
          },
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> searchEvents(String? query) => (super.noSuchMethod(
        Invocation.method(
          #searchEvents,
          [query],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> applyFilter(_i6.EventFilter? filter) => (super.noSuchMethod(
        Invocation.method(
          #applyFilter,
          [filter],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  void clearFilters() => super.noSuchMethod(
        Invocation.method(
          #clearFilters,
          [],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void setViewType(_i4.EventsViewType? viewType) => super.noSuchMethod(
        Invocation.method(
          #setViewType,
          [viewType],
        ),
        returnValueForMissingStub: null,
      );

  @override
  double sqrt(double? x) => (super.noSuchMethod(
        Invocation.method(
          #sqrt,
          [x],
        ),
        returnValue: 0.0,
      ) as double);

  @override
  _i5.Future<_i3.EventData?> getEventDetails(String? eventId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getEventDetails,
          [eventId],
        ),
        returnValue: _i5.Future<_i3.EventData?>.value(),
      ) as _i5.Future<_i3.EventData?>);

  @override
  _i5.Future<bool> signIn() => (super.noSuchMethod(
        Invocation.method(
          #signIn,
          [],
        ),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);

  @override
  _i5.Future<void> signOut() => (super.noSuchMethod(
        Invocation.method(
          #signOut,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  bool isFavorite(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #isFavorite,
          [eventId],
        ),
        returnValue: false,
      ) as bool);

  @override
  _i5.Future<void> toggleFavorite(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #toggleFavorite,
          [eventId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> addToFavorites(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #addToFavorites,
          [eventId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> removeFromFavorites(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #removeFromFavorites,
          [eventId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  List<String> getAllCategories() => (super.noSuchMethod(
        Invocation.method(
          #getAllCategories,
          [],
        ),
        returnValue: <String>[],
      ) as List<String>);

  @override
  List<int> getAllDifficultyLevels() => (super.noSuchMethod(
        Invocation.method(
          #getAllDifficultyLevels,
          [],
        ),
        returnValue: <int>[],
      ) as List<int>);

  @override
  _i5.Future<bool> registerForEvent(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #registerForEvent,
          [eventId],
        ),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);

  @override
  _i5.Future<bool> unregisterFromEvent(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #unregisterFromEvent,
          [eventId],
        ),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);

  @override
  bool isRegisteredForEvent(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #isRegisteredForEvent,
          [eventId],
        ),
        returnValue: false,
      ) as bool);

  @override
  void refresh() => super.noSuchMethod(
        Invocation.method(
          #refresh,
          [],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void dispose() => super.noSuchMethod(
        Invocation.method(
          #dispose,
          [],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void addListener(_i7.VoidCallback? listener) => super.noSuchMethod(
        Invocation.method(
          #addListener,
          [listener],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void removeListener(_i7.VoidCallback? listener) => super.noSuchMethod(
        Invocation.method(
          #removeListener,
          [listener],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void notifyListeners() => super.noSuchMethod(
        Invocation.method(
          #notifyListeners,
          [],
        ),
        returnValueForMissingStub: null,
      );
}
