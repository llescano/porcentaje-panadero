import 'package:flutter/material.dart';

class AppNavigationDrawer extends StatelessWidget {
  const AppNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.bakery_dining,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Porcentaje Panadero',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Calculadora de recetas',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Recetas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/recipes');
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Alacena'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/ingredients');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Acerca de'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Porcentaje Panadero',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.bakery_dining,
        size: 48,
      ),
      children: const [
        Text(
          'Aplicación para calcular porcentajes panaderos, '
          'escalar recetas y gestionar ingredientes.',
        ),
        SizedBox(height: 16),
        Text(
          'Desarrollado para panaderos y entusiastas de la repostería.',
        ),
      ],
    );
  }
}
