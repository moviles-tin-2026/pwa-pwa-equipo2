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