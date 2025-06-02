import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../services/recipe_service.dart';
import '../services/baker_percentage_service.dart';
import 'recipe_form_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  static const routeName = '/recipe-detail';
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Recipe? _recipe;
  List<RecipeIngredient> _recipeIngredients = [];
  bool _isLoading = false;
  double _totalHydration = 0.0;
  final TextEditingController _scaleFactorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecipeDetails();
  }

  Future<void> _loadRecipeDetails() async {
    setState(() {
      _isLoading = true;
    });
    final recipeService = Provider.of<RecipeService>(context, listen: false);
    _recipe = await recipeService.getRecipeById(widget.recipeId);
    if (_recipe != null) {
      _recipeIngredients = await recipeService.getRecipeIngredients(_recipe!.id);
      _calculateTotalHydration();
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _calculateTotalHydration() {
    final bakerPercentageService = Provider.of<BakerPercentageService>(context, listen: false);
    _totalHydration = bakerPercentageService.calculateTotalHydration(_recipeIngredients);
  }

  void _calculateScaledRecipe() {
    if (_scaleFactorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un factor de escalado.')),
      );
      return;
    }
    final double scaleFactor = double.parse(_scaleFactorController.text);
    final bakerPercentageService = Provider.of<BakerPercentageService>(context, listen: false);

    final scaledIngredients = bakerPercentageService.scaleRecipe(
      _recipeIngredients,
      scaleFactor,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Receta Escalada'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: scaledIngredients.map((ri) {
              return ListTile(
                title: Text(ri.ingredient?.name ?? 'Ingrediente desconocido'),
                subtitle: Text('Cantidad: ${ri.quantity.toStringAsFixed(2)} - Porcentaje: ${ri.bakerPercentage.toStringAsFixed(2)}%'),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_recipe?.name ?? 'Detalle de Receta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (_recipe != null) {
                await Navigator.of(context).pushNamed(
                  '/recipe/edit', // Usar la ruta directa
                  arguments: _recipe, // Pasar el objeto Recipe completo
                );
              }
              _loadRecipeDetails(); // Recargar después de editar
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipe == null
              ? const Center(child: Text('Receta no encontrada.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recipe!.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _recipe!.description ?? '',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Divider(height: 30),
                      Text(
                        'Ingredientes:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      if (_recipeIngredients.isEmpty)
                        const Text('No hay ingredientes en esta receta.')
                      else
                        ..._recipeIngredients.map((ri) {
                          return ListTile(
                            title: Text(ri.ingredient?.name ?? 'Ingrediente desconocido'),
                            subtitle: Text('Cantidad: ${ri.quantity.toStringAsFixed(2)} - Porcentaje: ${ri.bakerPercentage.toStringAsFixed(2)}%'),
                          );
                        }),
                      const SizedBox(height: 10),
                      Card(
                        margin: const EdgeInsets.only(top: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Hidratación:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${_totalHydration.toStringAsFixed(2)}%',
                                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 30),
                      Text(
                        'Escalar Receta:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _scaleFactorController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Factor de Escalado (ej. 2.0 para duplicar)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _calculateScaledRecipe,
                        child: const Text('Calcular Receta Escalada'),
                      ),
                    ],
                  ),
                ),
    );
  }
}