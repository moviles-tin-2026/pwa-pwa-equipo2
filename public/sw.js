const CACHE_NAME = 'pymesync-v1';
const ASSETS = [
  '/',
  '/index.html',
  '/css/inicio.css',
  '/css/inventario.css',
  '/css/ventas.css',
  '/css/estadisticos.css',
  '/css/ajustes.css',
  '/js/inicio.js',
  '/js/inventario.js',
  '/js/ventas.js',
  '/js/estadisticos.js',
  '/js/ajustes.js',
  '/paginas/inventario.html',
  '/paginas/ventas.html',
  '/paginas/estadisticos.html',
  '/paginas/ajustes.html',
  '/manifest.json',
  '/icono.png'
];

// Instalar el Service Worker y guardar archivos en caché
self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS);
    })
  );
});

// Responder con la caché o buscar en la red
self.addEventListener('fetch', (e) => {
  e.respondWith(
    caches.match(e.request).then((response) => {
      return response || fetch(e.request);
    })
  );
});