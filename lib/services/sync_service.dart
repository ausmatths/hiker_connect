import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_data.dart';
import 'dart:developer' as developer;

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box<EventData> _eventsBox;
  final Box<Map<dynamic, dynamic>> _syncQueueBox;

  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    required Box<EventData> eventsBox,
    required Box<Map<dynamic, dynamic>> syncQueueBox,
  })  : _eventsBox = eventsBox,
        _syncQueueBox = syncQueueBox;

  // Initialize the sync service
  Future<void> initialize() async {
    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        // Connected to network, attempt sync
        syncPendingChanges();
      }
    });

    // Initial sync attempt
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      await syncPendingChanges();
    }
  }

  // Queue an operation for sync
  Future<void> queueOperation({
    required String type, // 'create', 'update', 'delete'
    required String id,
    EventData? data,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await _syncQueueBox.put('$type-$id-$timestamp', {
      'type': type,
      'id': id,
      'timestamp': timestamp,
      'data': data?.toMap(),
    });

    // Try to sync immediately if online
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      await syncPendingChanges();
    }
  }

  // Sync pending changes to Firestore
  Future<void> syncPendingChanges() async {
    if (_isSyncing) return;

    _isSyncing = true;
    developer.log('Starting sync process', name: 'SyncService');

    try {
      final operations = _syncQueueBox.values.toList()
        ..sort((a, b) => a['timestamp'] - b['timestamp']);

      for (final operation in operations) {
        final type = operation['type'] as String;
        final id = operation['id'] as String;

        switch (type) {
          case 'create':
          case 'update':
            final data = Map<String, dynamic>.from(operation['data'] as Map);
            await _firestore.collection('events').doc(id).set(data);
            break;

          case 'delete':
            await _firestore.collection('events').doc(id).delete();
            break;
        }

        // Remove from queue after successful sync
        await _syncQueueBox.delete(operation['key']);
        developer.log('Synced operation: $type for id: $id', name: 'SyncService');
      }
    } catch (e) {
      developer.log('Error syncing changes: $e', name: 'SyncService');
    } finally {
      _isSyncing = false;
    }
  }

  // Fetch latest events from Firestore
  Future<void> fetchRemoteEvents() async {
    try {
      final snapshot = await _firestore.collection('events')
          .orderBy('eventDate')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        final event = EventData.fromMap(data);
        await _eventsBox.put(doc.id, event);
      }

      developer.log('Fetched ${snapshot.docs.length} events from Firestore', name: 'SyncService');
    } catch (e) {
      developer.log('Error fetching remote events: $e', name: 'SyncService');
    }
  }

  // Dispose
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}