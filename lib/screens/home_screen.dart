import 'package:flutter/material.dart';
import 'package:porcentaje_panadero/theme/text_styles.dart';
import 'package:porcentaje_panadero/widgets/gradient_border_container.dart';
import 'package:porcentaje_panadero/theme/colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // El AppBar ahora se configura globalmente desde el BakeryTheme
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bakery Warm'),
      ),
      body: const HomeContent(),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'Bienvenido a Bakery Warm',
            style: BakeryTextStyles.h1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tu asistente para recetas de panadería perfectas.',
            style: BakeryTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildQuickActions(context),
          const SizedBox(height: 40),
          _buildExploreSection(context),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acciones Rápidas', style: BakeryTextStyles.h2),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                iconData: Icons.add_chart,
                title: 'Crear Receta',
                onTap: () => Navigator.pushNamed(context, '/recipe/add'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                iconData: Icons.kitchen_outlined,
                title: 'Agregar Ingrediente',
                onTap: () => Navigator.pushNamed(context, '/ingredient/add'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExploreSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Explorar', style: BakeryTextStyles.h2),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                iconData: Icons.menu_book_outlined,
                title: 'Mis Recetas',
                onTap: () => Navigator.pushNamed(context, '/recipes'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                iconData: Icons.inventory_2_outlined,
                title: 'Mi Alacena',
                onTap: () => Navigator.pushNamed(context, '/ingredients'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData iconData,
    required String title,
    required VoidCallback onTap,
  }) {
    return GradientBorderContainer(
      onTap: onTap,
      innerPadding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 40,
            color: BakeryColors.carameloSuave,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: BakeryTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
