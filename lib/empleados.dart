import 'package:flutter/material.dart';

class EmpleadosPage extends StatelessWidget {
  const EmpleadosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('👥 Empleados', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xff362419))),
                  const Text('Coffee Cat - Gestión de personal', style: TextStyle(color: Color(0xff55453A), fontSize: 12)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff362419), foregroundColor: Colors.white),
                onPressed: () {},
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Agregar Empleado'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people, size: 80, color: const Color(0xff362419)),
                    const SizedBox(height: 16),
                    const Text('Gestión de Empleados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff362419))),
                    const Text('Próximamente', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}