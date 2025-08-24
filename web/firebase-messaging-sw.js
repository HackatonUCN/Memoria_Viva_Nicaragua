// Firebase Messaging Service Worker
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Configuración de Firebase
firebase.initializeApp({
  apiKey: 'AIzaSyDur8DRKynakTkjm84npwU0XkkcrUlZ2Rc',
  authDomain: 'memoriavivanicaragua.firebaseapp.com',
  projectId: 'memoriavivanicaragua',
  storageBucket: 'memoriavivanicaragua.firebasestorage.app',
  messagingSenderId: '126169056537',
  appId: '1:126169056537:web:87ce1d2652df4408043188',
  measurementId: 'G-GL485448RS'
});

const messaging = firebase.messaging();

// Manejar mensajes en segundo plano
messaging.onBackgroundMessage((payload) => {
  console.log('Mensaje recibido en segundo plano:', payload);

  const notificationTitle = payload.notification?.title || 'Memoria Viva Nicaragua';
  const notificationOptions = {
    body: payload.notification?.body || 'Nuevo mensaje',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Manejar clics en notificaciones
self.addEventListener('notificationclick', (event) => {
  console.log('Notificación clickeada:', event);
  
  event.notification.close();
  
  // Abrir la aplicación cuando se hace clic en la notificación
  event.waitUntil(
    clients.openWindow('/')
  );
});


