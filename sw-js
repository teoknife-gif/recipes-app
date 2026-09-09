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

// Tapping the notification should jump straight to the specific
// conversation it was about, not just open the app root. If a tab is
// already open we focus it and tell the page (via postMessage) which
// conversation to open — the app is a single-page app, so navigating the
// tab's actual URL would force a full reload instead of just switching
// screens. If nothing is open, a fresh tab is opened at that URL, and
// the app reads the ?open=... query string itself on boot.
self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var url = (event.notification.data && event.notification.data.url) || './';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (clientList) {
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if ('focus' in client) {
          client.postMessage({ type: 'navigate', url: url });
          return client.focus();
        }
      }
      if (self.clients.openWindow) return self.clients.openWindow(url);
    })
  );
});
