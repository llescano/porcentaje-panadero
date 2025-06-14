import 'package:flutter/material.dart';
import '../widgets/navigation_drawer.dart';
import '../widgets/custom_app_bar.dart'; // Importar CustomAppBar

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Porcentaje Panadero',
      ), // Usar CustomAppBar
      drawer: const AppNavigationDrawer(),
      body: const HomeContent(),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            '¡Bienvenido!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Gestiona tus recetas de panadería con porcentajes precisos',
            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildExploreSection(context),
          const SizedBox(height: 40),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: _buildAddIcon(context, Icons.receipt_long),
                title: 'Nueva Receta',
                subtitle: 'Crear una nueva receta',
                onTap: () => Navigator.pushNamed(context, '/recipe/add'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                icon: _buildAddIcon(context, Icons.inventory_2),
                title: 'Nuevo Ingrediente',
                subtitle: 'Agregar a la alacena',
                onTap: () => Navigator.pushNamed(context, '/ingredient/add'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddIcon(BuildContext context, IconData baseIcon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(baseIcon, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface, // Fondo blanco o color de superficie del tema
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_circle_rounded, // Usar un icono de círculo lleno
              size: 24, // Aumentar ligeramente el tamaño
              color: Theme.of(context).colorScheme.primary, // Color principal del tema
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required Widget icon, // Cambiar a Widget para aceptar el Stack
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              icon, // Usar el widget de icono directamente
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface, // Asegurar consistencia de color
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explorar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icon(Icons.receipt_long, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: 'Recetas',
                subtitle: 'Ver todas las recetas guardadas',
                onTap: () => Navigator.pushNamed(context, '/recipes'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icon(Icons.inventory_2, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: 'Alacena',
                subtitle: 'Gestionar ingredientes',
                onTap: () => Navigator.pushNamed(context, '/ingredients'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
