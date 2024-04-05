import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:revelationsai/firebase_options.dart';
import 'package:revelationsai/src/app.dart';
import 'package:revelationsai/src/constants/sentry.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const notificationTopics = {'daily-devo', 'daily-query'};

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Initializing Firebase');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((_) async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('Subscribing to topics');
    for (final topic in notificationTopics) {
      debugPrint('Subscribing to topic $topic');
      FirebaseMessaging.instance.subscribeToTopic(topic);
      if (kDebugMode) {
        debugPrint('Subscribing to test topic $topic-test');
        FirebaseMessaging.instance.subscribeToTopic('$topic-test');
      }
    }
  });

  await MobileAds.instance.initialize().then((value) async {
    const testDeviceId =
        String.fromEnvironment('TEST_DEVICE_ID', defaultValue: "");
    if (testDeviceId.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: [testDeviceId],
        ),
      );
    }
  });

  String? initLocation;
  final initMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initMessage != null) {
    debugPrint('Handling a background message ${initMessage.messageId}');
    switch (initMessage.data['task']) {
      case 'daily-devo':
        final id = initMessage.data['id'] ?? '';
        initLocation = '/?redirect=${Uri.encodeComponent('/devotions/$id')}';
        break;
      case "chat-query":
        final query = initMessage.data['query'] ?? '';
        initLocation =
            '/?redirect=${Uri.encodeComponent('/chat?query=$query')}';
        break;
      default:
        break;
    }
  }

  if (!kDebugMode) {
    await SentryFlutter.init(
      (options) {
        options.dsn = RAISentry.dsn;
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0;
      },
      appRunner: () => runApp(
        ProviderScope(
          child: RAIApp(
            initialLocation: initLocation,
          ),
        ),
      ),
    );
  } else {
    debugPrint('Running flutter app in debug mode');
    runApp(
      ProviderScope(
        // observers: [StateLogger()], // Uncomment to enable state logging
        child: RAIApp(
          initialLocation: initLocation,
        ),
      ),
    );
  }
}
