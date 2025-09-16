// Firebase Service Helper - Manages Firebase Analytics, Crashlytics, and Messaging for PlayWaves app
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  // Firebase service instances - lazy initialization
  FirebaseAnalytics? _analytics;
  FirebaseAnalytics get _analyticsInstance =>
      _analytics ??= FirebaseAnalytics.instance;

  FirebaseCrashlytics? _crashlytics;
  FirebaseCrashlytics get _crashlyticsInstance =>
      _crashlytics ??= FirebaseCrashlytics.instance;

  FirebaseMessaging? _messaging;
  FirebaseMessaging get _messagingInstance =>
      _messaging ??= FirebaseMessaging.instance;

  // Initialize all Firebase services
  Future<void> initializeAllServices() async {
    try {
      // Analytics initialization
      await _analyticsInstance.setAnalyticsCollectionEnabled(true);
      await _analyticsInstance.setUserProperty(
        name: 'app_version',
        value: '1.0.0',
      );
      await _analyticsInstance.setUserProperty(
        name: 'platform',
        value: 'mobile',
      );
      print('✅ Firebase Analytics initialized');

      // Performance monitoring
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
      print('✅ Firebase Performance Monitoring initialized');

      // Cloud Messaging
      await _messagingInstance.setAutoInitEnabled(true);

      // Request notification permissions
      NotificationSettings settings = await _messagingInstance
          .requestPermission(alert: true, badge: true, sound: true);

      print('✅ Firebase Cloud Messaging initialized');
      print(
        '📢 Notification permission status: ${settings.authorizationStatus}',
      );

      // Get FCM token
      final token = await _messagingInstance.getToken();
      if (token != null) {
        print('📱 FCM Token: $token');
      }

      print('🎉 All Firebase services initialized successfully!');
    } catch (e) {
      print('❌ Error initializing Firebase services: $e');
      await _crashlyticsInstance.recordError(e, StackTrace.current);
    }
  }

  // Analytics Methods
  Future<void> logEvent(
    String eventName, {
    Map<String, Object?>? parameters,
  }) async {
    await _analyticsInstance.logEvent(
      name: eventName,
      parameters: parameters?.cast<String, Object>(),
    );
  }

  Future<void> setUserProperty(String name, String value) async {
    await _analyticsInstance.setUserProperty(name: name, value: value);
  }

  Future<void> setUserId(String userId) async {
    await _analyticsInstance.setUserId(id: userId);
  }

  // Crashlytics Methods
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    await _crashlyticsInstance.recordError(
      exception,
      stackTrace,
      reason: reason,
    );
  }

  Future<void> log(String message) async {
    await _crashlyticsInstance.log(message);
  }

  Future<void> setCustomKey(String key, Object value) async {
    await _crashlyticsInstance.setCustomKey(key, value);
  }

  Future<void> setUserIdentifier(String identifier) async {
    await _crashlyticsInstance.setUserIdentifier(identifier);
  }

  // Messaging Methods
  Future<String?> getToken() async {
    return await _messagingInstance.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messagingInstance.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messagingInstance.unsubscribeFromTopic(topic);
  }

  // Convenience methods for common analytics events
  Future<void> logSongPlayed(
    String songId,
    String songName,
    String artist,
  ) async {
    await logEvent(
      'song_played',
      parameters: {'song_id': songId, 'song_name': songName, 'artist': artist},
    );
  }

  Future<void> logPlaylistCreated(String playlistName, int songCount) async {
    await logEvent(
      'playlist_created',
      parameters: {'playlist_name': playlistName, 'song_count': songCount},
    );
  }

  Future<void> logThemeChanged(String themeName, String themeType) async {
    await logEvent(
      'theme_changed',
      parameters: {'theme_name': themeName, 'theme_type': themeType},
    );
  }

  Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', parameters: {'screen_name': screenName});
  }

  Future<void> logUserLogin(String method) async {
    await logEvent('login', parameters: {'method': method});
  }

  Future<void> logSearch(String query, String searchType) async {
    await logEvent(
      'search',
      parameters: {'query': query, 'search_type': searchType},
    );
  }
}
