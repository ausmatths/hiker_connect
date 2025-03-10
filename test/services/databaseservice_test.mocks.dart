// Mocks generated by Mockito 5.4.5 from annotations
// in hiker_connect/test/services/databaseservice_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;
import 'dart:io' as _i10;

import 'package:hiker_connect/models/event_data.dart' as _i7;
import 'package:hiker_connect/models/event_filter.dart' as _i9;
import 'package:hiker_connect/models/photo_data.dart' as _i3;
import 'package:hiker_connect/models/trail_data.dart' as _i6;
import 'package:hiker_connect/services/databaseservice.dart' as _i4;
import 'package:hive/hive.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i8;

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

class _FakeBox_0<E> extends _i1.SmartFake implements _i2.Box<E> {
  _FakeBox_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakePhotoData_1 extends _i1.SmartFake implements _i3.PhotoData {
  _FakePhotoData_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [DatabaseService].
///
/// See the documentation for Mockito's code generation for more information.
class MockDatabaseService extends _i1.Mock implements _i4.DatabaseService {
  MockDatabaseService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i5.Future<_i2.Box<_i6.TrailData>> getTrailBox() => (super.noSuchMethod(
        Invocation.method(
          #getTrailBox,
          [],
        ),
        returnValue:
            _i5.Future<_i2.Box<_i6.TrailData>>.value(_FakeBox_0<_i6.TrailData>(
          this,
          Invocation.method(
            #getTrailBox,
            [],
          ),
        )),
      ) as _i5.Future<_i2.Box<_i6.TrailData>>);

  @override
  _i5.Future<_i2.Box<_i7.EventData>> getEventBox() => (super.noSuchMethod(
        Invocation.method(
          #getEventBox,
          [],
        ),
        returnValue:
            _i5.Future<_i2.Box<_i7.EventData>>.value(_FakeBox_0<_i7.EventData>(
          this,
          Invocation.method(
            #getEventBox,
            [],
          ),
        )),
      ) as _i5.Future<_i2.Box<_i7.EventData>>);

  @override
  _i5.Future<_i2.Box<String>> getFavoritesBox() => (super.noSuchMethod(
        Invocation.method(
          #getFavoritesBox,
          [],
        ),
        returnValue: _i5.Future<_i2.Box<String>>.value(_FakeBox_0<String>(
          this,
          Invocation.method(
            #getFavoritesBox,
            [],
          ),
        )),
      ) as _i5.Future<_i2.Box<String>>);

  @override
  _i5.Future<_i2.Box<_i3.PhotoData>> getPhotoBox() => (super.noSuchMethod(
        Invocation.method(
          #getPhotoBox,
          [],
        ),
        returnValue:
            _i5.Future<_i2.Box<_i3.PhotoData>>.value(_FakeBox_0<_i3.PhotoData>(
          this,
          Invocation.method(
            #getPhotoBox,
            [],
          ),
        )),
      ) as _i5.Future<_i2.Box<_i3.PhotoData>>);

  @override
  _i5.Future<void> init() => (super.noSuchMethod(
        Invocation.method(
          #init,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<List<_i7.EventData>> getAllEvents() => (super.noSuchMethod(
        Invocation.method(
          #getAllEvents,
          [],
        ),
        returnValue: _i5.Future<List<_i7.EventData>>.value(<_i7.EventData>[]),
      ) as _i5.Future<List<_i7.EventData>>);

  @override
  _i5.Future<int> insertTrails(_i6.TrailData? trail) => (super.noSuchMethod(
        Invocation.method(
          #insertTrails,
          [trail],
        ),
        returnValue: _i5.Future<int>.value(0),
      ) as _i5.Future<int>);

  @override
  _i5.Future<List<_i6.TrailData>> getTrails() => (super.noSuchMethod(
        Invocation.method(
          #getTrails,
          [],
        ),
        returnValue: _i5.Future<List<_i6.TrailData>>.value(<_i6.TrailData>[]),
      ) as _i5.Future<List<_i6.TrailData>>);

  @override
  _i5.Future<void> updateTrail(
    String? trailName,
    _i6.TrailData? trail,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateTrail,
          [
            trailName,
            trail,
          ],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<_i6.TrailData?> getTrailByName(String? name) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTrailByName,
          [name],
        ),
        returnValue: _i5.Future<_i6.TrailData?>.value(),
      ) as _i5.Future<_i6.TrailData?>);

  @override
  _i5.Future<void> syncTrailToFirestore(_i6.TrailData? trail) =>
      (super.noSuchMethod(
        Invocation.method(
          #syncTrailToFirestore,
          [trail],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<List<_i6.TrailData>> getTrailsFromFirestore() =>
      (super.noSuchMethod(
        Invocation.method(
          #getTrailsFromFirestore,
          [],
        ),
        returnValue: _i5.Future<List<_i6.TrailData>>.value(<_i6.TrailData>[]),
      ) as _i5.Future<List<_i6.TrailData>>);

  @override
  _i5.Future<_i6.TrailData?> getTrailByNameFromFirestore(String? name) =>
      (super.noSuchMethod(
        Invocation.method(
          #getTrailByNameFromFirestore,
          [name],
        ),
        returnValue: _i5.Future<_i6.TrailData?>.value(),
      ) as _i5.Future<_i6.TrailData?>);

  @override
  _i5.Future<void> deleteTrail(int? trailId) => (super.noSuchMethod(
        Invocation.method(
          #deleteTrail,
          [trailId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> deleteTrailFromFirestore(int? trailId) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteTrailFromFirestore,
          [trailId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<List<_i7.EventData>> getAllEventsFromBox() => (super.noSuchMethod(
        Invocation.method(
          #getAllEventsFromBox,
          [],
        ),
        returnValue: _i5.Future<List<_i7.EventData>>.value(<_i7.EventData>[]),
      ) as _i5.Future<List<_i7.EventData>>);

  @override
  _i5.Future<String> createEvent(_i7.EventData? event) => (super.noSuchMethod(
        Invocation.method(
          #createEvent,
          [event],
        ),
        returnValue: _i5.Future<String>.value(_i8.dummyValue<String>(
          this,
          Invocation.method(
            #createEvent,
            [event],
          ),
        )),
      ) as _i5.Future<String>);

  @override
  _i5.Future<_i7.EventData?> getEvent(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #getEvent,
          [eventId],
        ),
        returnValue: _i5.Future<_i7.EventData?>.value(),
      ) as _i5.Future<_i7.EventData?>);

  @override
  _i5.Future<void> updateEvent(_i7.EventData? event) => (super.noSuchMethod(
        Invocation.method(
          #updateEvent,
          [event],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> deleteEvent(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #deleteEvent,
          [eventId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<List<String>> getUserFavoriteEvents() => (super.noSuchMethod(
        Invocation.method(
          #getUserFavoriteEvents,
          [],
        ),
        returnValue: _i5.Future<List<String>>.value(<String>[]),
      ) as _i5.Future<List<String>>);

  @override
  _i5.Future<void> addEventToFavorites(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #addEventToFavorites,
          [eventId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> removeEventFromFavorites(String? eventId) =>
      (super.noSuchMethod(
        Invocation.method(
          #removeEventFromFavorites,
          [eventId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<List<_i7.EventData>> getEventsByFilter(_i9.EventFilter? filter) =>
      (super.noSuchMethod(
        Invocation.method(
          #getEventsByFilter,
          [filter],
        ),
        returnValue: _i5.Future<List<_i7.EventData>>.value(<_i7.EventData>[]),
      ) as _i5.Future<List<_i7.EventData>>);

  @override
  _i5.Future<_i3.PhotoData> uploadPhoto(
    _i10.File? file, {
    String? caption,
    String? trailId,
    String? eventId,
    bool? generateThumbnail = true,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #uploadPhoto,
          [file],
          {
            #caption: caption,
            #trailId: trailId,
            #eventId: eventId,
            #generateThumbnail: generateThumbnail,
          },
        ),
        returnValue: _i5.Future<_i3.PhotoData>.value(_FakePhotoData_1(
          this,
          Invocation.method(
            #uploadPhoto,
            [file],
            {
              #caption: caption,
              #trailId: trailId,
              #eventId: eventId,
              #generateThumbnail: generateThumbnail,
            },
          ),
        )),
      ) as _i5.Future<_i3.PhotoData>);

  @override
  _i5.Future<List<_i3.PhotoData>> getPhotosForTrail(String? trailId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getPhotosForTrail,
          [trailId],
        ),
        returnValue: _i5.Future<List<_i3.PhotoData>>.value(<_i3.PhotoData>[]),
      ) as _i5.Future<List<_i3.PhotoData>>);

  @override
  _i5.Future<List<_i3.PhotoData>> getPhotosForEvent(String? eventId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getPhotosForEvent,
          [eventId],
        ),
        returnValue: _i5.Future<List<_i3.PhotoData>>.value(<_i3.PhotoData>[]),
      ) as _i5.Future<List<_i3.PhotoData>>);

  @override
  _i5.Future<List<_i3.PhotoData>> getUserPhotos(
    String? userId, {
    int? limit = 20,
    _i3.PhotoData? lastPhoto,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #getUserPhotos,
          [userId],
          {
            #limit: limit,
            #lastPhoto: lastPhoto,
          },
        ),
        returnValue: _i5.Future<List<_i3.PhotoData>>.value(<_i3.PhotoData>[]),
      ) as _i5.Future<List<_i3.PhotoData>>);

  @override
  _i5.Future<bool> deletePhoto(String? photoId) => (super.noSuchMethod(
        Invocation.method(
          #deletePhoto,
          [photoId],
        ),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);

  @override
  _i5.Future<void> deletePhotosForTrail(String? trailId) => (super.noSuchMethod(
        Invocation.method(
          #deletePhotosForTrail,
          [trailId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> deletePhotosForEvent(String? eventId) => (super.noSuchMethod(
        Invocation.method(
          #deletePhotosForEvent,
          [eventId],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<bool> updatePhotoMetadata(
    String? photoId, {
    String? caption,
    String? trailId,
    String? eventId,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #updatePhotoMetadata,
          [photoId],
          {
            #caption: caption,
            #trailId: trailId,
            #eventId: eventId,
          },
        ),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);

  @override
  _i5.Future<bool> updatePhotoCaption(
    String? photoId,
    String? caption,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #updatePhotoCaption,
          [
            photoId,
            caption,
          ],
        ),
        returnValue: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);

  @override
  _i5.Future<_i3.PhotoData?> getPhotoById(String? photoId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getPhotoById,
          [photoId],
        ),
        returnValue: _i5.Future<_i3.PhotoData?>.value(),
      ) as _i5.Future<_i3.PhotoData?>);

  @override
  _i5.Future<void> ensurePhotoIndexExists() => (super.noSuchMethod(
        Invocation.method(
          #ensurePhotoIndexExists,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> recoverUnsyncedPhotos() => (super.noSuchMethod(
        Invocation.method(
          #recoverUnsyncedPhotos,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
}
