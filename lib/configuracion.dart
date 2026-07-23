import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚙️ Configuración', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff362419))),
          const Text('Coffee Cat - Ajustes del sistema', style: TextStyle(color: Color(0xff55453A), fontSize: 12)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person, color: Color(0xff362419), size: 28),
                          title: const Text('Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(user?.email ?? 'No disponible'),
                        ),
                        const Divider(),
                        SwitchListTile(
                          secondary: const Icon(Icons.notifications, color: Color(0xff362419)),
                          title: const Text('Notificaciones'),
                          subtitle: const Text('Recibir alertas de bajo stock'),
                          value: true,
                          onChanged: (value) {},
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.palette, color: Color(0xff362419)),
                          title: const Text('Tema'),
                          subtitle: const Text('Personalizar apariencia'),
                          trailing: const Text('Claro'),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info, color: Color(0xff362419)),
                          title: const Text('Acerca de'),
                          subtitle: const Text('Coffee Cat v1.0.0'),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}