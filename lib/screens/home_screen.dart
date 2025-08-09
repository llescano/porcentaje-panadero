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
            'Recetas de panadería con porcentajes precisos',
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
                icon: Icon(Icons.receipt_long, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: 'Crear Receta',
                onTap: () => Navigator.pushNamed(context, '/recipe/add'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icon(Icons.inventory_2, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: 'Agregar Ingrediente',
                onTap: () => Navigator.pushNamed(context, '/ingredient/add'),
              ),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildActionCard(
    BuildContext context, {
    required Widget icon,
    required String title,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 40,
                child: icon,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
                title: 'Mis Recetas',
                onTap: () => Navigator.pushNamed(context, '/recipes'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icon(Icons.inventory_2, size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: 'Mi Alacena',
                onTap: () => Navigator.pushNamed(context, '/ingredients'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
