// Mocks generated by Mockito 5.4.5 from annotations
// in hiker_connect/test/models/photo_dart_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:cloud_firestore/cloud_firestore.dart' as _i2;
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart'
    as _i5;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i3;

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

class _FakeDocumentReference_0<T1 extends Object?> extends _i1.SmartFake
    implements _i2.DocumentReference<T1> {
  _FakeDocumentReference_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeSnapshotMetadata_1 extends _i1.SmartFake
    implements _i2.SnapshotMetadata {
  _FakeSnapshotMetadata_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeFirebaseFirestore_2 extends _i1.SmartFake
    implements _i2.FirebaseFirestore {
  _FakeFirebaseFirestore_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeCollectionReference_3<T1 extends Object?> extends _i1.SmartFake
    implements _i2.CollectionReference<T1> {
  _FakeCollectionReference_3(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeDocumentSnapshot_4<T1 extends Object?> extends _i1.SmartFake
    implements _i2.DocumentSnapshot<T1> {
  _FakeDocumentSnapshot_4(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [DocumentSnapshot].
///
/// See the documentation for Mockito's code generation for more information.
class MockDocumentSnapshot<T extends Object?> extends _i1.Mock
    implements _i2.DocumentSnapshot<T> {
  MockDocumentSnapshot() {
    _i1.throwOnMissingStub(this);
  }

  @override
  String get id => (super.noSuchMethod(
        Invocation.getter(#id),
        returnValue: _i3.dummyValue<String>(
          this,
          Invocation.getter(#id),
        ),
      ) as String);

  @override
  _i2.DocumentReference<T> get reference => (super.noSuchMethod(
        Invocation.getter(#reference),
        returnValue: _FakeDocumentReference_0<T>(
          this,
          Invocation.getter(#reference),
        ),
      ) as _i2.DocumentReference<T>);

  @override
  _i2.SnapshotMetadata get metadata => (super.noSuchMethod(
        Invocation.getter(#metadata),
        returnValue: _FakeSnapshotMetadata_1(
          this,
          Invocation.getter(#metadata),
        ),
      ) as _i2.SnapshotMetadata);

  @override
  bool get exists => (super.noSuchMethod(
        Invocation.getter(#exists),
        returnValue: false,
      ) as bool);

  @override
  dynamic get(Object? field) => super.noSuchMethod(Invocation.method(
        #get,
        [field],
      ));

  @override
  dynamic operator [](Object? field) => super.noSuchMethod(Invocation.method(
        #[],
        [field],
      ));
}

/// A class which mocks [DocumentReference].
///
/// See the documentation for Mockito's code generation for more information.
// ignore: must_be_immutable
class MockDocumentReference<T extends Object?> extends _i1.Mock
    implements _i2.DocumentReference<T> {
  MockDocumentReference() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.FirebaseFirestore get firestore => (super.noSuchMethod(
        Invocation.getter(#firestore),
        returnValue: _FakeFirebaseFirestore_2(
          this,
          Invocation.getter(#firestore),
        ),
      ) as _i2.FirebaseFirestore);

  @override
  String get id => (super.noSuchMethod(
        Invocation.getter(#id),
        returnValue: _i3.dummyValue<String>(
          this,
          Invocation.getter(#id),
        ),
      ) as String);

  @override
  _i2.CollectionReference<T> get parent => (super.noSuchMethod(
        Invocation.getter(#parent),
        returnValue: _FakeCollectionReference_3<T>(
          this,
          Invocation.getter(#parent),
        ),
      ) as _i2.CollectionReference<T>);

  @override
  String get path => (super.noSuchMethod(
        Invocation.getter(#path),
        returnValue: _i3.dummyValue<String>(
          this,
          Invocation.getter(#path),
        ),
      ) as String);

  @override
  _i2.CollectionReference<Map<String, dynamic>> collection(
          String? collectionPath) =>
      (super.noSuchMethod(
        Invocation.method(
          #collection,
          [collectionPath],
        ),
        returnValue: _FakeCollectionReference_3<Map<String, dynamic>>(
          this,
          Invocation.method(
            #collection,
            [collectionPath],
          ),
        ),
      ) as _i2.CollectionReference<Map<String, dynamic>>);

  @override
  _i4.Future<void> delete() => (super.noSuchMethod(
        Invocation.method(
          #delete,
          [],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> update(Map<Object, Object?>? data) => (super.noSuchMethod(
        Invocation.method(
          #update,
          [data],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<_i2.DocumentSnapshot<T>> get([_i5.GetOptions? options]) =>
      (super.noSuchMethod(
        Invocation.method(
          #get,
          [options],
        ),
        returnValue: _i4.Future<_i2.DocumentSnapshot<T>>.value(
            _FakeDocumentSnapshot_4<T>(
          this,
          Invocation.method(
            #get,
            [options],
          ),
        )),
      ) as _i4.Future<_i2.DocumentSnapshot<T>>);

  @override
  _i4.Stream<_i2.DocumentSnapshot<T>> snapshots({
    bool? includeMetadataChanges = false,
    _i5.ListenSource? source = _i5.ListenSource.defaultSource,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #snapshots,
          [],
          {
            #includeMetadataChanges: includeMetadataChanges,
            #source: source,
          },
        ),
        returnValue: _i4.Stream<_i2.DocumentSnapshot<T>>.empty(),
      ) as _i4.Stream<_i2.DocumentSnapshot<T>>);

  @override
  _i4.Future<void> set(
    T? data, [
    _i5.SetOptions? options,
  ]) =>
      (super.noSuchMethod(
        Invocation.method(
          #set,
          [
            data,
            options,
          ],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i2.DocumentReference<R> withConverter<R>({
    required _i2.FromFirestore<R>? fromFirestore,
    required _i2.ToFirestore<R>? toFirestore,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #withConverter,
          [],
          {
            #fromFirestore: fromFirestore,
            #toFirestore: toFirestore,
          },
        ),
        returnValue: _FakeDocumentReference_0<R>(
          this,
          Invocation.method(
            #withConverter,
            [],
            {
              #fromFirestore: fromFirestore,
              #toFirestore: toFirestore,
            },
          ),
        ),
      ) as _i2.DocumentReference<R>);
}
