import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';

class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({super.key});

  @override
  State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _busquedaController = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _mostrarDialogoAgregar() async {
    final nombreController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String rolSeleccionado = 'vendedor';

    final crear = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar Empleado'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña temporal',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: rolSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                    DropdownMenuItem(value: 'vendedor', child: Text('Vendedor')),
                  ],
                  onChanged: (v) => setDialogState(() => rolSeleccionado = v ?? 'vendedor'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff362419),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (crear != true || !mounted) return;

    if (nombreController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos (contraseña mín. 6 caracteres)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _authService.crearEmpleado(
        email: emailController.text.trim(),
        password: passwordController.text,
        nombre: nombreController.text.trim(),
        rol: rolSeleccionado,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empleado creado. Inicia sesión nuevamente.'),
          backgroundColor: Color(0xff362419),
        ),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editarEmpleado(UsuarioModel empleado) async {
    String rol = empleado.rol;
    final nombreController = TextEditingController(text: empleado.nombre);

    final guardar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Editar: ${empleado.nombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: rol,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                  DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                  DropdownMenuItem(value: 'vendedor', child: Text('Vendedor')),
                ],
                onChanged: (v) => setDialogState(() => rol = v ?? empleado.rol),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (guardar != true || !mounted) return;

    try {
      await _authService.actualizarEmpleado(
        empleado.uid,
        nombre: nombreController.text.trim(),
        rol: rol,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empleado actualizado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleActivo(UsuarioModel empleado) async {
    if (empleado.uid == _authService.usuarioActual?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes desactivar tu propia cuenta'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _authService.actualizarEmpleado(
        empleado.uid,
        activo: !empleado.activo,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width < 1024;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff362419),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _mostrarDialogoAgregar,
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Agregar Empleado'),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeader(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff362419),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _mostrarDialogoAgregar,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Agregar Empleado'),
                    ),
                  ],
                ),
          const SizedBox(height: 16),
          TextField(
            controller: _busquedaController,
            onChanged: (v) => setState(() => _filtro = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o correo...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<UsuarioModel>>(
              stream: _authService.streamUsuarios(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xff362419)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var empleados = snapshot.data ?? [];
                if (_filtro.isNotEmpty) {
                  empleados = empleados
                      .where((e) =>
                          e.nombre.toLowerCase().contains(_filtro) ||
                          e.email.toLowerCase().contains(_filtro))
                      .toList();
                }

                if (empleados.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay empleados registrados',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                if (isMobile || isTablet) {
                  return ListView.separated(
                    itemCount: empleados.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildEmpleadoCard(empleados[index]),
                  );
                }

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xff362419).withValues(alpha: 0.08),
                      ),
                      columns: const [
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Correo')),
                        DataColumn(label: Text('Rol')),
                        DataColumn(label: Text('Estado')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: empleados.map((e) => _buildDataRow(e)).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '👥 Empleados',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xff362419),
          ),
        ),
        Text(
          'Coffee Cat - Gestión de personal',
          style: TextStyle(color: Color(0xff55453A), fontSize: 12),
        ),
      ],
    );
  }

  DataRow _buildDataRow(UsuarioModel empleado) {
    return DataRow(
      cells: [
        DataCell(Text(empleado.nombre)),
        DataCell(Text(empleado.email)),
        DataCell(_rolChip(empleado.rol)),
        DataCell(
          Switch(
            value: empleado.activo,
            activeThumbColor: const Color(0xff362419),
            onChanged: (_) => _toggleActivo(empleado),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xff362419)),
            onPressed: () => _editarEmpleado(empleado),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpleadoCard(UsuarioModel empleado) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xff362419).withValues(alpha: 0.1),
                  child: Text(
                    empleado.nombre.isNotEmpty
                        ? empleado.nombre[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Color(0xff362419)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empleado.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        empleado.email,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _rolChip(empleado.rol),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      empleado.activo ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        color: empleado.activo ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: empleado.activo,
                      activeThumbColor: const Color(0xff362419),
                      onChanged: (_) => _toggleActivo(empleado),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xff362419)),
                  onPressed: () => _editarEmpleado(empleado),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rolChip(String rol) {
    Color color;
    switch (rol) {
      case 'admin':
        color = const Color(0xff362419);
        break;
      case 'supervisor':
        color = const Color(0xff55453A);
        break;
      default:
        color = const Color(0xff7A6A5E);
    }

    return Chip(
      label: Text(
        rol == 'admin'
            ? 'Admin'
            : rol == 'supervisor'
                ? 'Supervisor'
                : 'Vendedor',
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }
}
