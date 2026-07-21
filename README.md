# login_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Error de oclusión de capas visuales
Este error es porque el ListTile está envuelto dentro de un ColoredBox opaco. Como las animaciones de ink splash y los efectos visuales del ListTile se pintan sobre el widget Material ancestro más cercano, la capa del ColoredBox queda posicionada por encima, bloqueando y ocultando la renderización de esos efectos.