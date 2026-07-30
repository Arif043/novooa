import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

void configureFirestoreWebCache(FirebaseFirestore firestore) {
  if (!kIsWeb) return;
  firestore.settings = const Settings(
    persistenceEnabled: true,
    webPersistentTabManager: WebPersistentMultipleTabManager(),
  );
}
