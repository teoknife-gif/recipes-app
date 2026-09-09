// Service worker for ΣΥΝΤΑΓΕΣ — enables real Web Push notifications.
// This file must be uploaded to GitHub next to index.html (repo root), NOT
// inside a subfolder — a service worker can only control pages at or below
// the URL path it's served from, so it needs to sit at the same level as
// index.html to cover the whole app.

self.addEventListener('install', function () {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim());
});

// A push message arrived from the send-push Edge Function.
self.addEventListener('push', function (event) {
  var data = {};
  try { data = event.data ? event.data.json() : {}; } catch (e) {}
  var title = data.title || 'Νέο μήνυμα';
  var options = {
    body: data.body || '',
    tag: data.tag || undefined,
    // No app icon/logo file exists yet — browsers show their own default
    // notification icon when none is given, which is fine here.
    data: { url: data.url || './' },
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

// Tapping the notification focuses an already-open tab if there is one,
// otherwise opens a new one.
self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var url = (event.notification.data && event.notification.data.url) || './';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if ('focus' in client) return client.focus();
      }
      if (self.clients.openWindow) return self.clients.openWindow(url);
    })
  );
});
