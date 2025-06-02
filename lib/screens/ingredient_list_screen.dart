import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';
import '../widgets/navigation_drawer.dart';
import 'ingredient_detail_screen.dart';

class IngredientListScreen extends StatefulWidget {
  const IngredientListScreen({super.key});

  @override
  State<IngredientListScreen> createState() => _IngredientListScreenState();
}

class _IngredientListScreenState extends State<IngredientListScreen> {
  final IngredientService _ingredientService = IngredientService();
  List<Ingredient> _ingredients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);
    try {
      final ingredients = await _ingredientService.getActiveIngredients();
      setState(() {
        _ingredients = ingredients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ingredientes: $e')),
        );
      }
    }
  }

  Future<void> _deleteIngredient(Ingredient ingredient) async {
    try {
      await _ingredientService.deleteIngredient(ingredient.id);
      _loadIngredients();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingrediente eliminado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar ingrediente: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alacena'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIngredients,
          ),
        ],
      ),
      drawer: const AppNavigationDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ingredients.isEmpty
              ? _buildEmptyState()
              : _buildIngredientList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/ingredient/add');
          if (result == true) {
            _loadIngredients();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay ingredientes en la alacena',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer ingrediente para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/ingredient/add');
              if (result == true) {
                _loadIngredients();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar Ingrediente'),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = _ingredients[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.grain,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              ingredient.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ingredient.description != null && ingredient.description!.isNotEmpty)
                  Text(ingredient.description!),
                const SizedBox(height: 4),
                Text(
                  'Categoría: ${ingredient.category.label} • Unidad: ${ingredient.defaultUnit.label}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    final result = await Navigator.pushNamed(
                      context,
                      '/ingredient/edit',
                      arguments: ingredient,
                    );
                    if (result == true) {
                      _loadIngredients();
                    }
                    break;
                  case 'delete':
                    _showDeleteDialog(ingredient);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IngredientDetailScreen(ingredient: ingredient),
                ),
              );
              if (result == true) {
                _loadIngredients();
              }
            },
          ),
        );
      },
    );
  }

  void _showDeleteDialog(Ingredient ingredient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ingrediente'),
        content: Text('¿Estás seguro de que quieres eliminar "${ingredient.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteIngredient(ingredient);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}