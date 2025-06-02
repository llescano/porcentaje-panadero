import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'recipe_form_screen.dart';
import 'recipe_calculator_screen.dart';

class RecipeListScreen extends StatefulWidget {
  static const routeName = '/recipes';

  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  late Future<List<Recipe>> _recipesFuture;
  final RecipeService _recipeService = RecipeService();

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  void _loadRecipes() {
    _recipesFuture = _recipeService.getRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas'),
        actions: [],
      ),
      body: FutureBuilder<List<Recipe>>(
        future: _recipesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay recetas. ¡Crea una nueva!'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final recipe = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(recipe.name),
                    subtitle: Text(recipe.description ?? ''),
                    leading: const Icon(Icons.cake),
                    onTap: () async {
                      await Navigator.of(context).pushNamed(
                        '/recipe/detail', // Navegar a la pantalla de detalle
                        arguments: recipe,
                      );
                      setState(() {
                        _loadRecipes(); // Recargar recetas por si se modificó algo
                      });
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green), // Botón de edición
                          onPressed: () async {
                            await Navigator.of(context).pushNamed(
                              '/recipe/edit',
                              arguments: recipe,
                            );
                            setState(() {
                              _loadRecipes(); // Recargar recetas después de editar
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.calculate, color: Colors.blue),
                          onPressed: () async {
                            await Navigator.of(context).pushNamed(
                              RecipeCalculatorScreen.routeName,
                              arguments: recipe,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirmar eliminación'),
                                content: Text('¿Estás seguro de que quieres eliminar la receta "${recipe.name}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _recipeService.deleteRecipe(recipe.id);
                              setState(() {
                                _loadRecipes(); // Recargar la lista después de eliminar
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Receta "${recipe.name}" eliminada.')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).pushNamed('/recipe/add');
          setState(() {
            _loadRecipes(); // Recargar recetas después de añadir una nueva
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}