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

// Die Web-App kommt von der Runtime selbst; ein Klick öffnet deshalb deren
// Herkunft (oder holt ein offenes Fenster nach vorn). Vor `messaging()`
// registriert, damit dieser Handler vor dem des SDK läuft.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const origin = self.location.origin;
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windows) => {
      const open = windows.find((client) => client.url.startsWith(origin));
      return open ? open.focus() : clients.openWindow(`${origin}/`);
    }),
  );
});

const messaging = firebase.messaging();
