import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importar provider
import '../providers/theme_provider.dart'; // Importar ThemeProvider
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';
import '../widgets/navigation_drawer.dart';
import '../widgets/custom_app_bar.dart'; // Importar CustomAppBar
import 'ingredient_detail_screen.dart';

enum IngredientFilter {
  active,
  inactive,
  all,
}

class IngredientListScreen extends StatefulWidget {
  const IngredientListScreen({super.key});

  @override
  State<IngredientListScreen> createState() => _IngredientListScreenState();
}

class _IngredientListScreenState extends State<IngredientListScreen> {
  final IngredientService _ingredientService = IngredientService();
  List<Ingredient> _allIngredients = []; // Almacenar todos los ingredientes
  List<Ingredient> _filteredIngredients = []; // Almacenar ingredientes filtrados
  bool _isLoading = true;
  IngredientFilter _currentFilter = IngredientFilter.active; // Estado del filtro

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);
    try {
      final ingredients = await _ingredientService.getAllIngredients(); // Obtener todos los ingredientes
      setState(() {
        _allIngredients = ingredients;
        _applyFilter(); // Aplicar el filtro inicial
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

  void _applyFilter() {
    setState(() {
      switch (_currentFilter) {
        case IngredientFilter.active:
          _filteredIngredients = _allIngredients.where((i) => i.isActive).toList();
          break;
        case IngredientFilter.inactive:
          _filteredIngredients = _allIngredients.where((i) => !i.isActive).toList();
          break;
        case IngredientFilter.all:
          _filteredIngredients = _allIngredients;
          break;
      }
    });
  }

  Future<void> _toggleIngredientStatus(Ingredient ingredient) async {
    setState(() => _isLoading = true);
    try {
      final updatedIngredient = ingredient.copyWith(isActive: !ingredient.isActive);
      await _ingredientService.updateIngredient(updatedIngredient);
      _loadIngredients();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedIngredient.isActive
                  ? 'Ingrediente habilitado'
                  : 'Ingrediente deshabilitado',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar ingrediente: $e')),
        );
      }
    }
  }

  Future<void> _deleteIngredient(Ingredient ingredient) async {
    try {
      await _ingredientService.deleteIngredient(ingredient.id);
      _loadIngredients();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ingrediente eliminado')));
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
    return Consumer<ThemeProvider>(
      // Envolver con Consumer
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: CustomAppBar(
            title: 'Alacena',
            showBackButton: true, // Habilitar el botón de retroceso
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadIngredients,
              ),
            ],
          ),
          drawer: const AppNavigationDrawer(),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SegmentedButton<IngredientFilter>(
                  segments: const <ButtonSegment<IngredientFilter>>[
                    ButtonSegment<IngredientFilter>(
                      value: IngredientFilter.active,
                      label: Text('Activos'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                    ButtonSegment<IngredientFilter>(
                      value: IngredientFilter.inactive,
                      label: Text('Inactivos'),
                      icon: Icon(Icons.cancel_outlined),
                    ),
                    ButtonSegment<IngredientFilter>(
                      value: IngredientFilter.all,
                      label: Text('Todos'),
                      icon: Icon(Icons.list),
                    ),
                  ],
                  selected: <IngredientFilter>{_currentFilter},
                  onSelectionChanged: (Set<IngredientFilter> newSelection) {
                    setState(() {
                      _currentFilter = newSelection.first;
                      _applyFilter();
                    });
                  },
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredIngredients.isEmpty
                        ? _buildEmptyState()
                        : _buildIngredientList(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/ingredient/add',
              );
              if (result == true) {
                _loadIngredients();
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay ingredientes en la alacena',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega tu primer ingrediente para comenzar',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/ingredient/add',
                  );
                  if (result == true) {
                    _loadIngredients();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar Ingrediente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredIngredients.length, // Usar _filteredIngredients
      itemBuilder: (context, index) {
        final ingredient = _filteredIngredients[index]; // Usar _filteredIngredients
        return Opacity(
          opacity: ingredient.isActive ? 1.0 : 0.6, // Aplicar opacidad
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 8),
            child: Builder(
              builder: (BuildContext innerContext) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      innerContext,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.1),
                    child: Icon(
                      Icons.grain,
                      color: Theme.of(innerContext).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    ingredient.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(innerContext).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ingredient.description != null &&
                          ingredient.description!.isNotEmpty)
                        Text(
                          ingredient.description!,
                          style: TextStyle(
                            color: Theme.of(innerContext).colorScheme.onSurface,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Categoría: ${ingredient.category.label} • Unidad: ${ingredient.defaultUnit.label}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(innerContext).colorScheme.onSurface,
                        ),
                      ),
                      if (!ingredient.isActive) // Indicador de inactivo en la lista
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'INACTIVO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(innerContext).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          final result = await Navigator.pushNamed(
                            innerContext,
                            '/ingredient/edit',
                            arguments: ingredient,
                          );
                          if (result == true) {
                            _loadIngredients();
                          }
                          break;
                        case 'toggle_status':
                          _toggleIngredientStatus(ingredient);
                          break;
                        case 'delete':
                          _showDeleteDialog(innerContext, ingredient);
                          break;
                      }
                    },
                    itemBuilder:
                        (innerContext) => [
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
                          PopupMenuItem(
                            value: 'toggle_status',
                            child: Row(
                              children: [
                                Icon(
                                  ingredient.isActive
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  ingredient.isActive
                                      ? 'Deshabilitar'
                                      : 'Habilitar',
                                ),
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
                      innerContext,
                      MaterialPageRoute(
                        builder:
                            (innerContext) =>
                                IngredientDetailScreen(ingredient: ingredient),
                      ),
                    );
                    if (result == true) {
                      _loadIngredients();
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, Ingredient ingredient) { // Añadir BuildContext
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar Ingrediente'),
            content: Text(
              '¿Estás seguro de que quieres eliminar "${ingredient.name}"?',
            ),
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
