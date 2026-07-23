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

messaging.onBackgroundMessage((message) => {
  const notification = message.notification || {};
  return self.registration.showNotification(
    notification.title || 'Neue Benachrichtigung',
    {
      body: notification.body || '',
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
      data: {url: notificationUrl(message.data)},
    },
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(openNotification(event.notification.data.url));
});

function notificationUrl(data) {
  const url = new URL('/activity', self.location.origin);
  if (data && data.runId) url.searchParams.set('runId', data.runId);
  return url.toString();
}

async function openNotification(url) {
  const windows = await clients.matchAll({type: 'window', includeUncontrolled: true});
  const existing = windows.find((window) => window.url.startsWith(self.location.origin));
  if (!existing) return clients.openWindow(url);
  await existing.navigate(url);
  return existing.focus();
}
