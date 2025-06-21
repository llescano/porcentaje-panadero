import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // Importar para TextInputFormatter
import 'package:intl/intl.dart'; // Importar NumberFormat
import 'package:collection/collection.dart'; // Importar para firstWhereOrNull
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../models/ingredient.dart'; // Importar para MeasurementUnit
import '../services/recipe_service.dart';
import '../services/baker_percentage_service.dart';
import '../widgets/custom_app_bar.dart'; // Importar CustomAppBar
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
  List<RecipeIngredient> _originalRecipeIngredients =
      []; // Store original quantities
  List<RecipeIngredient> _displayRecipeIngredients =
      []; // Store scaled quantities for display
  bool _isLoading = false;
  double _totalHydration = 0.0;
  double _totalDoughWeight = 0.0;
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, FocusNode> _quantityFocusNodes = {};
  late TextEditingController _totalDoughWeightController;
  late FocusNode _totalDoughWeightFocusNode;

  @override
  void initState() {
    super.initState();
    _totalDoughWeightController = TextEditingController();
    _totalDoughWeightFocusNode = FocusNode();
    _totalDoughWeightFocusNode.addListener(() {
      if (_totalDoughWeightFocusNode.hasFocus) {
        // Seleccionar todo el texto al ganar el foco
        _totalDoughWeightController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _totalDoughWeightController.text.length,
        );
      } else {
        _onTotalDoughWeightChanged(
          _totalDoughWeightController.text,
          fromFocusLoss: true,
        );
      }
    });
    _loadRecipeDetails();
  }

  @override
  void dispose() {
    _quantityControllers.forEach((key, controller) => controller.dispose());
    _quantityFocusNodes.forEach((key, focusNode) => focusNode.dispose());
    _totalDoughWeightController.dispose();
    _totalDoughWeightFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecipeDetails() async {
    setState(() {
      _isLoading = true;
    });
    final recipeService = Provider.of<RecipeService>(context, listen: false);
    _recipe = await recipeService.getRecipeById(widget.recipeId);
    if (_recipe != null) {
      _originalRecipeIngredients = await recipeService.getRecipeIngredients(
        _recipe!.id,
      );
      // Initialize _displayRecipeIngredients as a copy of _originalRecipeIngredients
      _displayRecipeIngredients = List.from(_originalRecipeIngredients);

      for (var ri in _displayRecipeIngredients) {
        // Iterate over display ingredients for controllers
        _quantityControllers[ri.id!] = TextEditingController(
          text: _formatNumber(ri.quantity),
        );
        _quantityFocusNodes[ri.id!] = FocusNode();
        _quantityFocusNodes[ri.id!]?.addListener(() {
          if (_quantityFocusNodes[ri.id!]!.hasFocus) {
            // Seleccionar todo el texto al ganar el foco
            _quantityControllers[ri.id!]?.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _quantityControllers[ri.id!]!.text.length,
            );
          } else {
            _onIngredientQuantityChanged(
              ri.id!,
              _quantityControllers[ri.id!]!.text,
              fromFocusLoss: true,
            );
          }
        });
      }
      _calculateTotalHydration(); // This calculation should use _displayRecipeIngredients
      // If there's a saved lastTotalDoughWeight, use it to scale _displayRecipeIngredients
      if (_recipe!.lastTotalDoughWeight != null &&
          _recipe!.lastTotalDoughWeight! > 0) {
        final bakerPercentageService = Provider.of<BakerPercentageService>(
          context,
          listen: false,
        );
        _totalDoughWeight = _recipe!.lastTotalDoughWeight!;
        // Apply scaling to _displayRecipeIngredients, but *not* to _originalRecipeIngredients
        _displayRecipeIngredients = bakerPercentageService
            .recalculateRecipeBasedOnTotalDoughWeight(
              _originalRecipeIngredients, // Scale from original
              _totalDoughWeight,
            );
        // Ensure quantity controllers are updated for the scaled values
        for (var ri in _displayRecipeIngredients) {
          _quantityControllers[ri.id!]?.text = _formatNumber(ri.quantity);
        }
      } else {
        // If no saved value, calculate from original ingredients
        final bakerPercentageService = Provider.of<BakerPercentageService>(
          context,
          listen: false,
        );
        _totalDoughWeight = bakerPercentageService.calculateTotalDoughWeight(
          _originalRecipeIngredients,
        ); // Calculate from original
      }

      _totalDoughWeightController.text = _formatNumber(_totalDoughWeight);
    }
    setState(() {
      _isLoading = false;
    });
  }

  String _formatNumber(double value) {
    if (value < 1.0) {
      return NumberFormat('0.00', 'es_ES').format(value); // Muestra siempre dos decimales si es menor que 1
    } else {
      return NumberFormat('###0', 'es_ES').format(value); // Redondea y muestra como entero si es 1 o mayor
    }
  }

  void _calculateTotalHydration() {
    final bakerPercentageService = Provider.of<BakerPercentageService>(
      context,
      listen: false,
    );
    _totalHydration = bakerPercentageService.calculateTotalHydration(
      _displayRecipeIngredients, // Use display ingredients for hydration calculation
    );
  }

  void _calculateTotalDoughWeight() {
    final bakerPercentageService = Provider.of<BakerPercentageService>(
      context,
      listen: false,
    );
    _totalDoughWeight = bakerPercentageService.calculateTotalDoughWeight(
      _displayRecipeIngredients, // Use display ingredients for total dough weight calculation
    );
  }

  void _onIngredientQuantityChanged(
    String recipeIngredientId,
    String newQuantityText, {
    bool fromFocusLoss = false,
  }) async {
    final bakerPercentageService = Provider.of<BakerPercentageService>(
      context,
      listen: false,
    );

    final double? newQuantity = double.tryParse(newQuantityText);
    if (newQuantity == null || newQuantity < 0) {
      return; // Si la cantidad no es válida, no hacer nada
    }

    setState(() {
      // Encontrar el ingrediente original para calcular el factor de escala relativo a su cantidad base
      final RecipeIngredient? originalIngredient = _originalRecipeIngredients
          .firstWhereOrNull((ri) => ri.id == recipeIngredientId);

      if (originalIngredient == null || originalIngredient.quantity == 0) {
        // Caso especial: El ingrediente original no se encuentra o su cantidad base es cero.
        // No podemos escalar proporcionalmente toda la receta a partir de esta base.
        // En su lugar, actualizamos directamente la cantidad de este ingrediente en _displayRecipeIngredients
        // y luego recalculamos todos los totales y porcentajes basados en esta lista actualizada.
        final int displayIndex = _displayRecipeIngredients.indexWhere(
          (ri) => ri.id == recipeIngredientId,
        );
        if (displayIndex != -1) {
          _displayRecipeIngredients[displayIndex] =
              _displayRecipeIngredients[displayIndex].copyWith(
                quantity: newQuantity,
              );
        }
        // Recalcular _totalDoughWeight y _totalHydration desde la lista _displayRecipeIngredients directamente
        _totalDoughWeight = bakerPercentageService.calculateTotalDoughWeight(
          _displayRecipeIngredients,
        );
        _totalHydration = bakerPercentageService.calculateTotalHydration(
          _displayRecipeIngredients,
        );
        // Recalcular porcentajes panaderos para la lista de visualización
        _displayRecipeIngredients = bakerPercentageService
            .calculateBakerPercentages(_displayRecipeIngredients);
      } else {
        // Caso general: El ingrediente original tiene una cantidad positiva, podemos escalar proporcionalmente.
        // Calcular el factor de escala basado en la nueva cantidad y la cantidad original del ingrediente.
        final double scaleFactor = newQuantity / originalIngredient.quantity;

        // Calcular el peso total de la masa de la receta original
        final double originalTotalDoughWeight = bakerPercentageService
            .calculateTotalDoughWeight(_originalRecipeIngredients);

        // Calcular el nuevo peso total de la masa para toda la receta basado en este factor de escala
        double newTotalDoughWeight = originalTotalDoughWeight * scaleFactor;

        // Asegurarse de que newTotalDoughWeight no sea negativo; si lo es, establecer a 0 para prevenir problemas.
        if (newTotalDoughWeight < 0) newTotalDoughWeight = 0;

        // Recalcular _displayRecipeIngredients escalando _originalRecipeIngredients a este nuevo peso total de masa.
        // Esto asegura que todos los ingredientes se escalen proporcionalmente desde la base original.
        _displayRecipeIngredients = bakerPercentageService
            .recalculateRecipeBasedOnTotalDoughWeight(
              _originalRecipeIngredients, // Siempre escalar desde la base original, inmutable
              newTotalDoughWeight,
            );

        // Actualizar _totalDoughWeight y _totalHydration desde la lista _displayRecipeIngredients recién escalada
        _totalDoughWeight = bakerPercentageService.calculateTotalDoughWeight(
          _displayRecipeIngredients,
        );
        _totalHydration = bakerPercentageService.calculateTotalHydration(
          _displayRecipeIngredients,
        );
      }

      // Asegurarse de que el controlador de peso total de la masa se actualice si no tiene el foco
      if (!_totalDoughWeightFocusNode.hasFocus) {
        _totalDoughWeightController.text = _formatNumber(_totalDoughWeight);
      }

      // Actualizar todos los controladores de cantidad con los nuevos valores escalados
      for (var ri in _displayRecipeIngredients) {
        // Solo actualizar si no es el campo actualmente enfocado, o si es un evento de pérdida de foco
        if (ri.id! != recipeIngredientId || fromFocusLoss) {
          _quantityControllers[ri.id!]?.text = _formatNumber(ri.quantity);
        }
      }
    });

    // Guardar el nuevo lastTotalDoughWeight en la receta y en la base de datos.
    // _originalRecipeIngredients siempre se pasan para guardar las cantidades originales.
    if (_recipe != null && _totalDoughWeight > 0) {
      _recipe = _recipe!.copyWith(lastTotalDoughWeight: _totalDoughWeight);
      final recipeService = Provider.of<RecipeService>(context, listen: false);
      await recipeService.updateRecipe(
        _recipe!,
        _originalRecipeIngredients, // Siempre pasar ingredientes originales para guardar
      );
    }
  }

  void _onTotalDoughWeightChanged(
    String newTotalDoughWeightText, {
    bool fromFocusLoss = false,
  }) {
    final bakerPercentageService = Provider.of<BakerPercentageService>(
      context,
      listen: false,
    );

    final double? newTotalDoughWeight = double.tryParse(
      newTotalDoughWeightText,
    );
    if (newTotalDoughWeight == null || newTotalDoughWeight <= 0) {
      return;
    }

    setState(() {
      _totalDoughWeight = newTotalDoughWeight; // Update the total dough weight
      // Recalculate display ingredients based on original and new total dough weight
      _displayRecipeIngredients = bakerPercentageService
          .recalculateRecipeBasedOnTotalDoughWeight(
            _originalRecipeIngredients, // Scale from original
            _totalDoughWeight,
          );
      for (var ri in _displayRecipeIngredients) {
        _quantityControllers[ri.id!]?.text = _formatNumber(ri.quantity);
      }
      _calculateTotalHydration();
      _calculateTotalDoughWeight(); // This will use _displayRecipeIngredients for accurate calculation

      if (fromFocusLoss) {
        _totalDoughWeightController.text = _formatNumber(_totalDoughWeight);
      }

      // Save the new lastTotalDoughWeight in the recipe and update the recipe in the database
      if (_recipe != null && _totalDoughWeight > 0) {
        _recipe = _recipe!.copyWith(lastTotalDoughWeight: _totalDoughWeight);
        final recipeService = Provider.of<RecipeService>(
          context,
          listen: false,
        );
        recipeService.updateRecipe(
          _recipe!,
          _originalRecipeIngredients, // Pass original ingredients for saving
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title:
            '${_recipe?.name ?? 'Detalle de Receta'} - Hidratación: ${_formatBakerPercentageForDisplay(_totalHydration)}%',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (_recipe != null) {
                await Navigator.of(context).pushNamed(
                  '/recipe/edit',
                  arguments: _recipe!.id,
                ); // Pass recipe ID instead of object
              }
              _loadRecipeDetails();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Peso Total de la Masa:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _totalDoughWeightController,
                                focusNode: _totalDoughWeightFocusNode,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.end,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color:
                                      Theme.of(context)
                                          .colorScheme
                                          .onSurface, // Apply onSurface color
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  suffixText: ' g',
                                ),
                                onChanged:
                                    (value) =>
                                        _onTotalDoughWeightChanged(value),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'), // Allow decimals
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Ingredientes:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10.0),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          _displayRecipeIngredients
                              .length, // Use display ingredients for the list
                      itemBuilder: (context, index) {
                        final recipeIngredient =
                            _displayRecipeIngredients[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            title: Text(
                              recipeIngredient.ingredient?.name ??
                                  'Ingrediente Desconocido',
                            ),
                            subtitle: Text(
                              '${_formatNumber(recipeIngredient.quantity)} ${recipeIngredient.unit.label} (${_formatBakerPercentageForDisplay(recipeIngredient.bakerPercentage)}%)',
                            ),
                            // Add functionality to edit individual ingredient quantity
                            trailing: SizedBox(
                              width: 100, // Adjust width as needed
                              child: TextField(
                                controller:
                                    _quantityControllers[recipeIngredient.id!],
                                focusNode:
                                    _quantityFocusNodes[recipeIngredient.id!],
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textAlign: TextAlign.end,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  suffixText:
                                      ' g', // This will always be 'g' because we convert everything to grams for display in this field.
                                ),
                                onChanged:
                                    (value) => _onIngredientQuantityChanged(
                                      recipeIngredient.id!,
                                      value,
                                    ),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }

  String _formatBakerPercentageForDisplay(double percentage) {
    if (percentage == 0.0) {
      return '0';
    }
    
    // Algoritmo de rangos de magnitud para determinar decimales dinámicamente
    int decimals;
    if (percentage >= 100) {
      decimals = 0; // Valores grandes: sin decimales (ej: 150)
    } else if (percentage >= 10) {
      decimals = 1; // Valores medianos: 1 decimal (ej: 15.5)
    } else if (percentage >= 1) {
      decimals = 2; // Valores pequeños: 2 decimales (ej: 2.75)
    } else {
      decimals = 3; // Valores muy pequeños: 3 decimales (ej: 0.125)
    }
    
    return percentage.toStringAsFixed(decimals);
  }
}
