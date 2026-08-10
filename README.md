# 🐱☕ Coffee Cat - Sistema de Inventario

Aplicación móvil y web desarrollada en **Flutter** para la gestión e inventario de la cafetería **Coffee Cat**.

## 📌 Estado Actual del Proyecto

Actualmente, la interfaz base del módulo de inicio de sesión e inventario se encuentra construida, pero existen algunos **detalles técnicos y de diseño visual** que se están corrigiendo en las vistas principales.

## ⚠️ Registro de Errores y Ajustes Pendientes
### 🌐 1. Despliegue y Entorno (Web / Hosting)
- [ ] **Sin publicación en la web:** El proyecto actualmente **solo corre en entorno local**. No se ha montado ni desplegado la página en un servidor o hosting web (como Firebase Hosting, Vercel o GitHub Pages) para su acceso remoto.



## 📱 2. Interfaz y Diseño Responsivo
 ### Desbordamiento horizontal (RenderFlex)
 - []  Algunos elementos colocados dentro de un Row ocupan más espacio que el ancho disponible de la pantalla. Flutter indica desbordamientos de 334 píxeles y 44 píxeles hacia la derecha, lo cual puede provocar que textos, botones u otros componentes queden fuera de la vista. Se debe ajustar el diseño utilizando elementos como Expanded, Flexible, Wrap o un desplazamiento horizontal para adaptarlo a diferentes tamaños de pantalla.



## Error de oclusión de capas visuales
Este error es porque el ListTile está envuelto dentro de un ColoredBox opaco. Como las animaciones de ink splash y los efectos visuales del ListTile se pintan sobre el widget Material ancestro más cercano, la capa del ColoredBox queda posicionada por encima, bloqueando y ocultando la renderización de esos efectos.


## Primera advertencia de UI
Ocurre porque hay un widget ListTile renderizado fuera de un ancestro Material. Al no encontrar la capa gráfica adecuada, Flutter no puede proyectar el efecto visual de toque (ink splash) o el color de fondo.

## Segunda advertencia de UI
Es exactamente la misma excepción que la anterior, pero disparada dentro de una lista o bucle (por ejemplo, al renderizar 24 elementos de un ListView sin envolverlos en un Material).

## Error de conexión con Firebase
La aplicación intentó comunicarse con el servidor de Firestore, pero la conexión UDP rápida (QUIC) se interrumpió abruptamente porque el servidor o el navegador cerraron la sesión. Suele pasar por inestabilidad en la red, firewall o microcortes de internet.

## Tercera advertencia de UI
Mismo problema de diseño en el ListTile, esta vez registrado en otro momento del ciclo de vida o renderizado de la pantalla (6 repeticiones).

## Cuarta advertencia de UI
Una nueva instancia de la misma excepción de UI, provocada por la reconstrucción (rebuild) del widget con la falta del ancestro Material.