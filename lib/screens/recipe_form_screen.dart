import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Importar Uuid
import 'package:collection/collection.dart'; // Importar para firstWhereOrNull
import 'package:intl/intl.dart'; // Importar NumberFormat
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../services/recipe_service.dart';
import '../services/ingredient_service.dart';
import '../services/baker_percentage_service.dart';
import '../models/recipe_ingredient.dart';
import '../widgets/custom_app_bar.dart'; // Importar CustomAppBar

class RecipeFormScreen extends StatefulWidget {
  static const routeName = '/recipe-form';
  final String? recipeId;

  const RecipeFormScreen({super.key, this.recipeId});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<RecipeIngredient> _recipeIngredients = [];
  List<Ingredient> _availableIngredients = [];
  bool _isLoading = false;
  bool _hasChanges = false;

  final RecipeService _recipeService = RecipeService();
  final IngredientService _ingredientService = IngredientService();
  final BakerPercentageService _bakerPercentageService =
      BakerPercentageService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    _availableIngredients = await _ingredientService.getAllIngredients();

    if (widget.recipeId != null) {
      final recipe = await _recipeService.getRecipeById(widget.recipeId!);
      if (recipe != null) {
        _nameController.text = _capitalizeAllWords(recipe.name);
        _descriptionController.text = _capitalizeFirstLetter(
          recipe.description ?? '',
        ); // Manejar descripción nula
        _recipeIngredients.addAll(
          await _recipeService.getRecipeIngredients(widget.recipeId!),
        );
      } else {
        // Si la receta no se encuentra, podríamos mostrar un mensaje o volver atrás
        // Por ahora, simplemente no cargamos datos y el formulario estará vacío
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receta no encontrada para editar.')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text[0].toUpperCase() + text.substring(1);
  }

  String _capitalizeAllWords(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) {
            return '';
          }
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  void _showIngredientFormDialog({RecipeIngredient? ingredientToEdit}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _IngredientFormDialogContent(
          ingredientToEdit: ingredientToEdit,
          availableIngredients: _availableIngredients,
          recipeId: widget.recipeId,
          recipeIngredients:
              _recipeIngredients, // Pasar la lista actual de ingredientes de la receta
          onIngredientSaved: (RecipeIngredient savedIngredient) {
            setState(() {
              if (ingredientToEdit == null) {
                _recipeIngredients.add(savedIngredient);
              } else {
                final index = _recipeIngredients.indexWhere(
                  (ri) => ri.id == ingredientToEdit.id,
                );
                if (index != -1) {
                  _recipeIngredients[index] = savedIngredient;
                }
              }
              // Recalcular porcentajes globalmente después de añadir/editar
              final updatedIngredients = _bakerPercentageService
                  .calculateBakerPercentages(_recipeIngredients);
              _recipeIngredients.clear();
              _recipeIngredients.addAll(updatedIngredients);
              _hasChanges = true;
            });
            Navigator.of(context).pop();
          },
          onCalculateBakerPercentage: _calculateAndSetBakerPercentage,
          convertQuantityToGrams: _convertQuantityToGrams,
        );
      },
    );
  }

  // Método auxiliar para la conversión de cantidad a gramos
  double _convertQuantityToGrams(
    double quantity,
    Ingredient ingredient,
    MeasurementUnit inputUnit,
  ) {
    if (inputUnit == MeasurementUnit.grams) {
      return quantity;
    } else if (inputUnit == ingredient.defaultUnit) {
      if (ingredient.defaultUnit == MeasurementUnit.kilograms) {
        return quantity * 1000.0;
      } else if (ingredient.conversionFactorToGrams != null) {
        return quantity * ingredient.conversionFactorToGrams!;
      }
    }
    // Si no hay una regla de conversión específica o la unidad de entrada no es la por defecto ni gramos,
    // asumimos que la cantidad ya está en gramos o no se puede convertir directamente.
    // Esto podría ser un punto para añadir más lógica de manejo de errores o advertencias.
    return quantity;
  }

  void _removeIngredientFromRecipe(int index) {
    setState(() {
      _recipeIngredients.removeAt(index);
      // Recalcular porcentajes después de eliminar un ingrediente
      final updatedIngredients = _bakerPercentageService
          .calculateBakerPercentages(_recipeIngredients);
      _recipeIngredients.clear();
      _recipeIngredients.addAll(updatedIngredients);
      _hasChanges = true;
    });
  }

  double? _calculateAndSetBakerPercentage({
    required String?
    recipeIngredientIdToTrack, // ID único de la instancia de RecipeIngredient
    required Ingredient? selectedIngredient, // El objeto Ingredient completo
    required String quantityText,
    bool isEditing = false,
    required bool contributesToHydration,
    required MeasurementUnit
    inputUnit, // Nueva propiedad para la unidad de entrada
  }) {
    if (selectedIngredient == null || quantityText.isEmpty) {
      return null; // Devolver nulo si no se puede calcular
    }

    final double? quantity = double.tryParse(quantityText);
    if (quantity == null) {
      return null; // Devolver nulo si la cantidad no es válida
    }

    final List<RecipeIngredient> tempIngredients = List.from(
      _recipeIngredients,
    ); // Copia mutable

    debugPrint(
      'Cantidad ingresada (en _calculateAndSetBakerPercentage): $quantityText',
    ); // Depuración

    // Encontrar y eliminar la instancia actual del ingrediente de la lista temporal si estamos editando
    // Esto es crucial para manejar duplicados y asegurar que el cálculo se haga con la versión más reciente
    if (isEditing && recipeIngredientIdToTrack != null) {
      tempIngredients.removeWhere((ri) => ri.id == recipeIngredientIdToTrack);
    }

    // Crear o actualizar el RecipeIngredient temporal para el cálculo
    final RecipeIngredient currentTempRecipeIngredient = RecipeIngredient(
      id: recipeIngredientIdToTrack, // Usar el ID para el seguimiento
      recipeId: '', // No relevante para el cálculo de porcentaje de panadero
      ingredientId: selectedIngredient.id,
      ingredient: selectedIngredient,
      quantity: _convertQuantityToGrams(
        quantity,
        selectedIngredient,
        inputUnit,
      ), // Convertir a gramos aquí
      bakerPercentage: 0.0, // Se actualizará después del cálculo
      unit: MeasurementUnit.grams, // La unidad interna siempre es gramos
      contributesToHydration: contributesToHydration,
    );

    tempIngredients.add(currentTempRecipeIngredient);

    debugPrint('tempIngredients antes del cálculo:'); // Depuración
    for (var ri in tempIngredients) {
      debugPrint('  - ${ri.ingredient?.name} (ID: ${ri.id}): ${ri.quantity}');
    }

    final calculatedPercentages = _bakerPercentageService
        .calculateBakerPercentages(tempIngredients);

    // Buscar el ingrediente específico por su ID único
    final currentIngredientCalculated = calculatedPercentages.firstWhereOrNull(
      (ri) => ri.id == recipeIngredientIdToTrack,
    );

    // Devolver el porcentaje calculado en lugar de actualizar el controlador directamente
    return currentIngredientCalculated
        ?.bakerPercentage; // Retorna double? en lugar de void
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final newRecipe = Recipe(
      id: widget.recipeId,
      name: _nameController.text,
      description: _descriptionController.text,
    );

    try {
      if (widget.recipeId == null) {
        // Crear nueva receta
        final newRecipeId = const Uuid().v4(); // Generar un nuevo ID
        final newRecipeToSave = Recipe(
          // Crear una nueva instancia de Recipe con el nuevo ID
          id: newRecipeId,
          name: _nameController.text,
          description: _descriptionController.text,
        );
        await _recipeService.addRecipe(
          newRecipeToSave,
          [],
        ); // Guardar receta sin ingredientes inicialmente

        // Calcular porcentajes de panadero antes de guardar
        final updatedIngredientsForSave = _bakerPercentageService
            .calculateBakerPercentages(_recipeIngredients);

        // Asignar el ID de la nueva receta a los ingredientes y guardarlos
        List<RecipeIngredient> ingredientsToSave =
            updatedIngredientsForSave.map((ri) {
              return ri.copyWith(
                recipeId: newRecipeToSave.id,
              ); // Crear nueva instancia con el recipeId correcto
            }).toList();

        await _recipeService.updateRecipe(
          newRecipeToSave,
          ingredientsToSave,
        ); // Actualizar con ingredientes

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receta creada exitosamente!')),
        );
        _hasChanges = false; // Restablecer después de guardar
        
        // Navegar a la pantalla de detalle de la nueva receta
        Navigator.of(context).pushReplacementNamed(
          '/recipe/detail',
          arguments: Recipe(
            id: newRecipeToSave.id,
            name: newRecipeToSave.name,
            description: newRecipeToSave.description,
          ),
        );
        return; // Salir temprano para evitar el pop() al final
      } else {
        // Calcular porcentajes de panadero antes de actualizar
        final updatedIngredientsForSave = _bakerPercentageService
            .calculateBakerPercentages(_recipeIngredients);
        // Actualizar receta existente
        await _recipeService.updateRecipe(newRecipe, updatedIngredientsForSave);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receta actualizada exitosamente!')),
        );
        _hasChanges = false; // Restablecer después de guardar
      }
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar la receta: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTotalHydrationDisplay() {
    final totalHydration = _bakerPercentageService.calculateTotalHydration(
      _recipeIngredients,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Hidratación: ${_formatBakerPercentageForDisplay(totalHydration)}',
        style:
            Theme.of(context)
                .textTheme
                .titleMedium, // Opcional: ajusta el estilo si es necesario
      ),
    );
  }

  // Función auxiliar para formatear el porcentaje panadero en la lista
  String _formatBakerPercentageForDisplay(double percentage) {
    if (percentage == 0.0) {
      return '0%'; // Mostrar 0% si es 0
    }
    
    // Algoritmo de rangos de magnitud para determinar decimales dinámicamente
    int decimals;
    if (percentage >= 100) {
      decimals = 0; // Valores grandes: sin decimales (ej: 150%)
    } else if (percentage >= 10) {
      decimals = 1; // Valores medianos: 1 decimal (ej: 15.5%)
    } else if (percentage >= 1) {
      decimals = 2; // Valores pequeños: 2 decimales (ej: 2.75%)
    } else {
      decimals = 3; // Valores muy pequeños: 3 decimales (ej: 0.125%)
    }
    
    return '${percentage.toStringAsFixed(decimals)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        // Usar CustomAppBar
        title: widget.recipeId == null ? 'Nueva Receta' : 'Editar Receta',
        isForm: true,
        isLoading: _isLoading,
        onSave: _saveRecipe,
      ),
      body: WillPopScope(
        onWillPop: () async {
          if (_hasChanges) {
            final bool? shouldSave = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('¿Guardar cambios?'),
                  content: const Text(
                    'Tienes cambios sin guardar. ¿Quieres guardarlos antes de salir?',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false); // No guardar
                      },
                      child: const Text('Descartar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(null); // Cancelar
                      },
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true); // Guardar
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                );
              },
            );

            if (shouldSave == true) {
              await _saveRecipe();
              return true; // Permitir el pop después de guardar
            } else if (shouldSave == false) {
              return true; // Permitir el pop sin guardar
            } else {
              return false; // Cancelar el pop
            }
          }
          return true; // Permitir el pop si no hay cambios
        },
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la Receta',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa un nombre.';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            final String capitalizedValue = _capitalizeAllWords(
                              value,
                            );
                            if (_nameController.text != capitalizedValue) {
                              _nameController.value = _nameController.value
                                  .copyWith(
                                    text: capitalizedValue,
                                    selection: TextSelection.collapsed(
                                      offset: capitalizedValue.length,
                                    ),
                                  );
                            }
                            setState(() {
                              _hasChanges = true;
                            });
                          },
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                          ),
                          minLines: 1,
                          maxLines: null,
                          onChanged: (value) {
                            final String capitalizedValue =
                                _capitalizeFirstLetter(value);
                            if (_descriptionController.text !=
                                capitalizedValue) {
                              _descriptionController.value =
                                  _descriptionController.value.copyWith(
                                    text: capitalizedValue,
                                    selection: TextSelection.collapsed(
                                      offset: capitalizedValue.length,
                                    ),
                                  );
                            }
                            setState(() {
                              _hasChanges = true;
                            });
                          },
                        ),
                        const SizedBox(height: 5),
                        _buildTotalHydrationDisplay(),
                        const SizedBox(height: 50),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Ingredientes de la Receta:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _recipeIngredients.length,
                            itemBuilder: (context, index) {
                              final recipeIngredient =
                                  _recipeIngredients[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: ListTile(
                                  key: ValueKey(
                                    recipeIngredient.id,
                                  ), // Añadir ValueKey
                                  title: Text(
                                    recipeIngredient.ingredient?.name ??
                                        'Ingrediente Desconocido',
                                  ),
                                  subtitle: Text(
                                    'Cantidad: ${recipeIngredient.quantity.toStringAsFixed(2)} ${recipeIngredient.unit.label} (${_formatBakerPercentageForDisplay(recipeIngredient.bakerPercentage)})',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed:
                                            () => _showIngredientFormDialog(
                                              ingredientToEdit:
                                                  recipeIngredient,
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed:
                                            () => _removeIngredientFromRecipe(
                                              index,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showIngredientFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class _IngredientFormDialogContent extends StatefulWidget {
  final RecipeIngredient? ingredientToEdit;
  final List<Ingredient> availableIngredients;
  final String? recipeId;
  final List<RecipeIngredient>
  recipeIngredients; // Lista actual de ingredientes de la receta
  final Function(RecipeIngredient) onIngredientSaved;
  final double? Function({
    required String? recipeIngredientIdToTrack,
    required Ingredient? selectedIngredient,
    required String quantityText,
    bool isEditing,
    required bool contributesToHydration,
    required MeasurementUnit inputUnit,
  })
  onCalculateBakerPercentage;
  final double Function(double, Ingredient, MeasurementUnit)
  convertQuantityToGrams;

  const _IngredientFormDialogContent({
    super.key,
    this.ingredientToEdit,
    required this.availableIngredients,
    this.recipeId,
    required this.recipeIngredients,
    required this.onIngredientSaved,
    required this.onCalculateBakerPercentage,
    required this.convertQuantityToGrams,
  });

  @override
  State<_IngredientFormDialogContent> createState() =>
      _IngredientFormDialogContentState();
}

class _IngredientFormDialogContentState
    extends State<_IngredientFormDialogContent> {
  late RecipeIngredient _tempRecipeIngredient;
  late TextEditingController _quantityController;
  late TextEditingController _percentageController;
  late MeasurementUnit _selectedInputUnit; // Unidad que el usuario ve y edita
  late Ingredient?
  _currentSelectedIngredient; // Para mantener el ingrediente seleccionado
  late FocusNode _quantityFocusNode; // Añadir FocusNode

  // Función auxiliar para parsear números formateados con comas
  double? _parseFormattedNumber(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    // Eliminar separadores de miles (comas) y reemplazar coma decimal por punto
    final cleanedText = text
        .trim()
        .replaceAll(',', '')
        .replaceAll('.', '')
        .replaceFirst('.', '');
    return double.tryParse(cleanedText);
  }

  // Función auxiliar para formatear la cantidad a mostrar en el TextFormField
  String _formatQuantityForDisplay(double quantity) {
    final formatter = NumberFormat(
      '###0.##',
      'es_ES',
    ); // Cambiado para no tener separador de miles
    if (quantity == quantity.roundToDouble()) {
      // Si es un número entero, no mostrar decimales ni separador de miles
      return NumberFormat('###0', 'es_ES').format(quantity);
    } else {
      // Si tiene decimales, mostrar hasta dos, sin separador de miles
      return formatter.format(quantity);
    }
  }

  // Función auxiliar para formatear el porcentaje panadero
  String _formatBakerPercentageForDisplay(double percentage) {
    if (percentage == 0.0) {
      return ''; // No mostrar nada si es 0
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

  @override
  void initState() {
    super.initState();
    if (widget.ingredientToEdit != null) {
      _tempRecipeIngredient = widget.ingredientToEdit!.copyWith();
      _currentSelectedIngredient = widget.availableIngredients.firstWhereOrNull(
        (ing) => ing.id == _tempRecipeIngredient.ingredientId,
      );
      debugPrint(
        'Editando ingrediente: ${_tempRecipeIngredient.ingredient?.name}',
      );
      debugPrint(
        'displayUnit guardada: ${_tempRecipeIngredient.displayUnit?.label}',
      );
      debugPrint(
        'defaultUnit del ingrediente: ${_currentSelectedIngredient?.defaultUnit.label}',
      );
    } else {
      _tempRecipeIngredient = RecipeIngredient(
        id: const Uuid().v4(),
        recipeId: widget.recipeId ?? '',
        ingredientId: '',
        quantity: 0.0,
        unit: MeasurementUnit.grams, // La unidad interna siempre es gramos
        displayUnit:
            null, // Se establecerá al seleccionar un ingrediente o al guardar
        bakerPercentage: 0.0,
        contributesToHydration: false,
      );
      _currentSelectedIngredient =
          null; // Asegurarse de que sea nulo para nuevos ingredientes
      debugPrint('Añadiendo nuevo ingrediente.');
    }

    // Determinar la unidad de visualización inicial y la cantidad a mostrar
    MeasurementUnit initialDisplayUnit;
    double quantityToShow;

    if (_currentSelectedIngredient != null) {
      // Si estamos editando y hay una displayUnit guardada, usarla
      initialDisplayUnit =
          _tempRecipeIngredient.displayUnit ??
          _currentSelectedIngredient!.defaultUnit;
      // Convertir la cantidad (que está en gramos) a la unidad de visualización
      quantityToShow = _convertGramsToDisplayUnit(
        _tempRecipeIngredient.quantity,
        _currentSelectedIngredient!,
        initialDisplayUnit,
      );
    } else {
      // Si es un nuevo ingrediente o no hay displayUnit guardada, usar gramos por defecto
      initialDisplayUnit = MeasurementUnit.grams;
      quantityToShow =
          _tempRecipeIngredient.quantity; // Cantidad inicial es 0.0
    }

    _selectedInputUnit = initialDisplayUnit;
    _quantityController = TextEditingController(
      text: _formatQuantityForDisplay(quantityToShow),
    );
    _percentageController = TextEditingController(
      text: _formatBakerPercentageForDisplay(
        _tempRecipeIngredient.bakerPercentage,
      ),
    );

    // Inicializar FocusNode y añadir listener
    _quantityFocusNode = FocusNode();
    _quantityFocusNode.addListener(() {
      if (_quantityFocusNode.hasFocus) {
        _quantityController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _quantityController.text.length,
        );
      }
    });

    debugPrint('Unidad de visualización inicial: ${_selectedInputUnit.label}');
    debugPrint('Cantidad a mostrar: ${quantityToShow.toStringAsFixed(2)}');

    // Inicializar el porcentaje si se está editando o si ya hay datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if ((widget.ingredientToEdit != null &&
              _percentageController.text.isEmpty) ||
          (_tempRecipeIngredient.ingredientId.isNotEmpty &&
              _quantityController.text.isNotEmpty &&
              _percentageController.text.isEmpty)) {
        // Usar _parseFormattedNumber para la cantidad al inicializar el cálculo
        final double? quantity = _parseFormattedNumber(
          _quantityController.text,
        );
        final Ingredient? selectedIng = widget.availableIngredients
            .firstWhereOrNull(
              (ing) => ing.id == _tempRecipeIngredient.ingredientId,
            );
        if (quantity != null && selectedIng != null) {
          final double? calculatedPercentage = widget
              .onCalculateBakerPercentage(
                recipeIngredientIdToTrack: _tempRecipeIngredient.id,
                selectedIngredient: selectedIng,
                quantityText: _quantityController.text,
                isEditing: widget.ingredientToEdit != null,
                contributesToHydration:
                    _tempRecipeIngredient.contributesToHydration,
                inputUnit: _selectedInputUnit,
              );
          setState(() {
            _percentageController.text =
                calculatedPercentage != null
                    ? _formatBakerPercentageForDisplay(calculatedPercentage)
                    : '';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _percentageController.dispose();
    _quantityFocusNode.dispose(); // Liberar FocusNode
    super.dispose();
  }

  // Método auxiliar para convertir gramos a la unidad de visualización
  double _convertGramsToDisplayUnit(
    double grams,
    Ingredient ingredient,
    MeasurementUnit displayUnit,
  ) {
    if (displayUnit == MeasurementUnit.grams) {
      return grams;
    } else if (displayUnit == ingredient.defaultUnit) {
      if (ingredient.defaultUnit == MeasurementUnit.kilograms) {
        return grams / 1000.0;
      } else if (ingredient.conversionFactorToGrams != null &&
          ingredient.conversionFactorToGrams! > 0) {
        return grams / ingredient.conversionFactorToGrams!;
      }
    }
    // Si no hay una regla de conversión específica o la unidad de visualización no es la por defecto ni gramos,
    // asumimos que la cantidad ya está en gramos o no se puede convertir directamente.
    return grams;
  }

  @override
  Widget build(BuildContext context) {
    String? selectedIngredientId =
        _tempRecipeIngredient.ingredientId.isNotEmpty
            ? _tempRecipeIngredient.ingredientId
            : null;

    return AlertDialog(
      title: Text(
        widget.ingredientToEdit == null
            ? 'Añadir Ingrediente'
            : 'Editar Ingrediente',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Ingrediente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grain),
              ),
              value: selectedIngredientId,
              items:
                  widget.availableIngredients.map((ingredient) {
                    return DropdownMenuItem(
                      value: ingredient.id,
                      child: Text(ingredient.name),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _tempRecipeIngredient = _tempRecipeIngredient.copyWith(
                    ingredientId: value,
                  );
                  _currentSelectedIngredient = widget.availableIngredients
                      .firstWhereOrNull((ing) => ing.id == value);
                  // Al cambiar el ingrediente, la unidad de visualización por defecto es la defaultUnit del nuevo ingrediente
                  // y la cantidad se resetea o se convierte a esa unidad.
                  if (_currentSelectedIngredient != null) {
                    _selectedInputUnit =
                        _currentSelectedIngredient!.defaultUnit;
                    _quantityController.text = _formatQuantityForDisplay(
                      0.0,
                    ); // Resetear cantidad al cambiar de ingrediente y formatear
                    _percentageController.text = ''; // Resetear porcentaje
                    // Inicializar contributesToHydration con el valor del ingrediente seleccionado
                    _tempRecipeIngredient = _tempRecipeIngredient.copyWith(
                      contributesToHydration:
                          _currentSelectedIngredient!.contributesToHydration,
                    );
                    
                    // Mover el foco al campo de cantidad después de seleccionar el ingrediente
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _quantityFocusNode.requestFocus();
                    });
                  } else {
                    _selectedInputUnit = MeasurementUnit.grams; // Fallback
                    _quantityController.text = _formatQuantityForDisplay(
                      0.0,
                    ); // Formatear también aquí
                    _percentageController.text = '';
                    _tempRecipeIngredient = _tempRecipeIngredient.copyWith(
                      contributesToHydration:
                          false, // Resetear a false si no hay ingrediente seleccionado
                    );
                  }
                  // Recalcular porcentaje si ya hay cantidad
                  if (_currentSelectedIngredient != null &&
                      _quantityController.text.isNotEmpty) {
                    widget.onCalculateBakerPercentage(
                      recipeIngredientIdToTrack: _tempRecipeIngredient.id,
                      selectedIngredient: _currentSelectedIngredient,
                      quantityText: _quantityController.text,
                      isEditing: widget.ingredientToEdit != null,
                      contributesToHydration:
                          _tempRecipeIngredient.contributesToHydration,
                      inputUnit: _selectedInputUnit,
                    );
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            // Nuevo Dropdown para la unidad de visualización
            if (_currentSelectedIngredient != null) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<MeasurementUnit>(
                decoration: const InputDecoration(
                  labelText: 'Unidad de Visualización',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                value: _selectedInputUnit,
                items:
                    <MeasurementUnit>[
                      _currentSelectedIngredient!.defaultUnit,
                      MeasurementUnit.grams,
                    ].toSet().map<DropdownMenuItem<MeasurementUnit>>((
                      MeasurementUnit value,
                    ) {
                      return DropdownMenuItem<MeasurementUnit>(
                        value: value,
                        child: Text(value.label),
                      );
                    }).toList(),
                onChanged: (MeasurementUnit? newValue) {
                  if (newValue != null) {
                    setState(() {
                      // Convertir la cantidad actual a la nueva unidad de visualización
                      final double currentQuantity =
                          double.tryParse(_quantityController.text) ?? 0.0;
                      final double quantityInGrams = widget.convertQuantityToGrams(
                        currentQuantity,
                        _currentSelectedIngredient!,
                        _selectedInputUnit, // Usar la unidad anterior para la conversión a gramos
                      );
                      final double newQuantity = _convertGramsToDisplayUnit(
                        quantityInGrams,
                        _currentSelectedIngredient!,
                        newValue,
                      );
                      _quantityController.text = _formatQuantityForDisplay(
                        newQuantity,
                      );
                      _selectedInputUnit = newValue;

                      // Recalcular porcentaje con la nueva unidad de entrada
                      widget.onCalculateBakerPercentage(
                        recipeIngredientIdToTrack: _tempRecipeIngredient.id,
                        selectedIngredient: _currentSelectedIngredient,
                        quantityText: _quantityController.text,
                        isEditing: widget.ingredientToEdit != null,
                        contributesToHydration:
                            _tempRecipeIngredient.contributesToHydration,
                        inputUnit: _selectedInputUnit,
                      );
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              focusNode:
                  _quantityFocusNode, // Asignar FocusNode al TextFormField
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                final parsedValue = _parseFormattedNumber(value);
                if (parsedValue != null && _currentSelectedIngredient != null) {
                  final double? calculatedPercentage = widget
                      .onCalculateBakerPercentage(
                        recipeIngredientIdToTrack: _tempRecipeIngredient.id,
                        selectedIngredient: _currentSelectedIngredient,
                        quantityText: parsedValue.toString(),
                        isEditing: widget.ingredientToEdit != null,
                        contributesToHydration:
                            _tempRecipeIngredient.contributesToHydration,
                        inputUnit: _selectedInputUnit,
                      );
                  setState(() {
                    _percentageController.text =
                        calculatedPercentage != null
                            ? _formatBakerPercentageForDisplay(
                              calculatedPercentage,
                            )
                            : '';
                  });
                } else {
                  setState(() {
                    _percentageController.text = '';
                  });
                }
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La cantidad es obligatoria';
                }
                final parsedValue = _parseFormattedNumber(value);
                if (parsedValue == null || parsedValue <= 0) {
                  return 'Ingresa un número positivo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _percentageController,
              decoration: const InputDecoration(
                labelText: 'Porcentaje Panadero',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.percent),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Contribuye a la hidratación'),
              subtitle: const Text('Cuenta como líquido'),
              value: _tempRecipeIngredient.contributesToHydration,
              onChanged: (bool value) {
                setState(() {
                  _tempRecipeIngredient = _tempRecipeIngredient.copyWith(
                    contributesToHydration: value,
                  );
                  // Recalcular porcentaje al cambiar la contribución a la hidratación
                  if (_currentSelectedIngredient != null &&
                      _quantityController.text.isNotEmpty) {
                    final double? calculatedPercentage = widget
                        .onCalculateBakerPercentage(
                          recipeIngredientIdToTrack: _tempRecipeIngredient.id,
                          selectedIngredient: _currentSelectedIngredient,
                          quantityText: _quantityController.text,
                          isEditing: widget.ingredientToEdit != null,
                          contributesToHydration:
                              _tempRecipeIngredient.contributesToHydration,
                          inputUnit: _selectedInputUnit,
                        );
                    _percentageController.text =
                        calculatedPercentage != null
                            ? _formatBakerPercentageForDisplay(
                              calculatedPercentage,
                            )
                            : '';
                  }
                });
              },
            ),
            TextFormField(
              initialValue: _tempRecipeIngredient.notes,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              onChanged: (value) {
                _tempRecipeIngredient = _tempRecipeIngredient.copyWith(
                  notes: value,
                );
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Es opcional'),
              subtitle: const Text(
                'Indica si este ingrediente es opcional en la receta.',
              ),
              value: _tempRecipeIngredient.isOptional,
              onChanged: (bool value) {
                setState(() {
                  _tempRecipeIngredient = _tempRecipeIngredient.copyWith(
                    isOptional: value,
                  );
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentSelectedIngredient == null ||
                        _quantityController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor, selecciona un ingrediente y una cantidad.',
                          ),
                        ),
                      );
                      return;
                    }

                    final double? quantity = _parseFormattedNumber(
                      _quantityController.text,
                    );
                    if (quantity == null || quantity <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor, ingresa una cantidad válida.',
                          ),
                        ),
                      );
                      return;
                    }

                    // Convertir la cantidad ingresada a gramos para el almacenamiento interno
                    final double quantityInGrams = widget
                        .convertQuantityToGrams(
                          quantity,
                          _currentSelectedIngredient!,
                          _selectedInputUnit,
                        );

                    final savedRecipeIngredient = _tempRecipeIngredient.copyWith(
                      ingredientId: _currentSelectedIngredient!.id,
                      quantity: quantityInGrams, // Guardar en gramos
                      unit:
                          MeasurementUnit
                              .grams, // La unidad interna siempre es gramos
                      displayUnit:
                          _selectedInputUnit, // Guardar la unidad de visualización
                      ingredient:
                          _currentSelectedIngredient, // Adjuntar el objeto Ingredient
                    );
                    widget.onIngredientSaved(savedRecipeIngredient);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
