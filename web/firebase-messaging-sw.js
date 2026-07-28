self.addEventListener('notificationclick', (event) => {
  const link = event.notification.data?.FCM_MSG?.fcmOptions?.link;
  if (!link) return;
  event.stopImmediatePropagation();
  event.notification.close();
  event.waitUntil(openNotification(link));
});

importScripts('https://www.gstatic.com/firebasejs/12.6.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.6.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCqT815piSitiqbdyIt_r5V57p0_95tGaI',
  appId: '1:7059834940:web:cff5f7365b77064424db39',
  messagingSenderId: '7059834940',
  projectId: 'syscat-90bff',
  authDomain: 'syscat-90bff.firebaseapp.com',
  storageBucket: 'syscat-90bff.firebasestorage.app',
  measurementId: 'G-DF770ES1H5',
});

const messaging = firebase.messaging();

async function openNotification(link) {
  const url = new URL(link, self.location.origin);
  if (url.origin !== self.location.origin) return;
  const windows = await clients.matchAll({type: 'window', includeUncontrolled: true});
  const existing = windows.find((window) => window.url.startsWith(self.location.origin));
  if (!existing) return clients.openWindow(url.href);
  await existing.navigate(url.href);
  return existing.focus();
}
