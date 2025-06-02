import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Importar Uuid
import 'package:collection/collection.dart'; // Importar para firstWhereOrNull
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../services/recipe_service.dart';
import '../services/ingredient_service.dart';
import '../services/baker_percentage_service.dart';
import '../models/recipe_ingredient.dart';

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
  
  final RecipeService _recipeService = RecipeService();
  final IngredientService _ingredientService = IngredientService();
  final BakerPercentageService _bakerPercentageService = BakerPercentageService();

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
        _nameController.text = recipe.name;
        _descriptionController.text = recipe.description ?? ''; // Manejar descripción nula
        _recipeIngredients.addAll(await _recipeService.getRecipeIngredients(widget.recipeId!));
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

  void _showIngredientFormDialog({RecipeIngredient? ingredientToEdit}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _IngredientFormDialogContent(
          ingredientToEdit: ingredientToEdit,
          availableIngredients: _availableIngredients,
          recipeId: widget.recipeId,
          recipeIngredients: _recipeIngredients, // Pasar la lista actual de ingredientes de la receta
          onIngredientSaved: (RecipeIngredient savedIngredient) {
            setState(() {
              if (ingredientToEdit == null) {
                _recipeIngredients.add(savedIngredient);
              } else {
                final index = _recipeIngredients.indexWhere((ri) => ri.id == ingredientToEdit.id);
                if (index != -1) {
                  _recipeIngredients[index] = savedIngredient;
                }
              }
              // Recalcular porcentajes globalmente después de añadir/editar
              final updatedIngredients = _bakerPercentageService.calculateBakerPercentages(_recipeIngredients);
              _recipeIngredients.clear();
              _recipeIngredients.addAll(updatedIngredients);
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
  double _convertQuantityToGrams(double quantity, Ingredient ingredient, MeasurementUnit inputUnit) {
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
      final updatedIngredients = _bakerPercentageService.calculateBakerPercentages(_recipeIngredients);
      _recipeIngredients.clear();
      _recipeIngredients.addAll(updatedIngredients);
    });
  }

  void _calculateAndSetBakerPercentage({
    required String? recipeIngredientIdToTrack, // ID único de la instancia de RecipeIngredient
    required Ingredient? selectedIngredient, // El objeto Ingredient completo
    required String quantityText,
    required TextEditingController percentageController,
    required Function(VoidCallback) setStateCallback,
    bool isEditing = false,
    required bool contributesToHydration,
    required MeasurementUnit inputUnit, // Nueva propiedad para la unidad de entrada
  }) {
    if (selectedIngredient == null || quantityText.isEmpty) {
      setStateCallback(() {
        percentageController.text = '';
      });
      return;
    }

    final double? quantity = double.tryParse(quantityText);
    if (quantity == null) {
      setStateCallback(() {
        percentageController.text = '';
      });
      return;
    }

    final List<RecipeIngredient> tempIngredients = List.from(_recipeIngredients); // Copia mutable

    debugPrint('Cantidad ingresada (en _calculateAndSetBakerPercentage): $quantityText'); // Depuración

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
      quantity: _convertQuantityToGrams(quantity, selectedIngredient, inputUnit), // Convertir a gramos aquí
      bakerPercentage: 0.0, // Se actualizará después del cálculo
      unit: MeasurementUnit.grams, // La unidad interna siempre es gramos
      contributesToHydration: contributesToHydration,
    );

    tempIngredients.add(currentTempRecipeIngredient);

    debugPrint('tempIngredients antes del cálculo:'); // Depuración
    for (var ri in tempIngredients) {
      debugPrint('  - ${ri.ingredient?.name} (ID: ${ri.id}): ${ri.quantity}');
    }

    final calculatedPercentages = _bakerPercentageService.calculateBakerPercentages(tempIngredients);

    // Buscar el ingrediente específico por su ID único
    final currentIngredientCalculated = calculatedPercentages.firstWhereOrNull(
      (ri) => ri.id == recipeIngredientIdToTrack,
    );

    setStateCallback(() {
      percentageController.text = currentIngredientCalculated?.bakerPercentage.toStringAsFixed(2) ?? '';
      debugPrint('Porcentaje calculado: ${percentageController.text}'); // Depuración
    });
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
        final newRecipeToSave = Recipe( // Crear una nueva instancia de Recipe con el nuevo ID
          id: newRecipeId,
          name: _nameController.text,
          description: _descriptionController.text,
        );
        await _recipeService.addRecipe(newRecipeToSave, []); // Guardar receta sin ingredientes inicialmente

        // Calcular porcentajes de panadero antes de guardar
        final updatedIngredientsForSave = _bakerPercentageService.calculateBakerPercentages(_recipeIngredients);
        
        // Asignar el ID de la nueva receta a los ingredientes y guardarlos
        List<RecipeIngredient> ingredientsToSave = updatedIngredientsForSave.map((ri) {
          return ri.copyWith(recipeId: newRecipeToSave.id); // Crear nueva instancia con el recipeId correcto
        }).toList();

        await _recipeService.updateRecipe(newRecipeToSave, ingredientsToSave); // Actualizar con ingredientes
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receta creada exitosamente!')),
        );
      } else {
        // Calcular porcentajes de panadero antes de actualizar
        final updatedIngredientsForSave = _bakerPercentageService.calculateBakerPercentages(_recipeIngredients);
        // Actualizar receta existente
        await _recipeService.updateRecipe(newRecipe, updatedIngredientsForSave);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receta actualizada exitosamente!')),
        );
      }
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar la receta: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTotalHydrationDisplay() {
    final totalHydration = _bakerPercentageService.calculateTotalHydration(_recipeIngredients);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Hidratación:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${totalHydration.toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipeId == null ? 'Nueva Receta' : 'Editar Receta'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre de la Receta'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un nombre.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Ingredientes de la Receta:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTotalHydrationDisplay(), // Nuevo widget para mostrar la hidratación
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _recipeIngredients.length,
                        itemBuilder: (context, index) {
                          final recipeIngredient = _recipeIngredients[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              key: ValueKey(recipeIngredient.id), // Añadir ValueKey
                              title: Text(recipeIngredient.ingredient?.name ?? 'Ingrediente Desconocido'),
                              subtitle: Text(
                                  'Cantidad: ${recipeIngredient.quantity.toStringAsFixed(2)} ${recipeIngredient.unit.label} (${recipeIngredient.bakerPercentage.toStringAsFixed(2)}%)'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showIngredientFormDialog(ingredientToEdit: recipeIngredient),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _removeIngredientFromRecipe(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showIngredientFormDialog(),
                      child: const Text('Añadir Ingrediente'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveRecipe,
                      child: const Text('Guardar Receta'),
                    ),
                  ],
                ),
              ),
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
  final List<RecipeIngredient> recipeIngredients; // Lista actual de ingredientes de la receta
  final Function(RecipeIngredient) onIngredientSaved;
  final Function({
    required String? recipeIngredientIdToTrack,
    required Ingredient? selectedIngredient,
    required String quantityText,
    required TextEditingController percentageController,
    required Function(VoidCallback) setStateCallback,
    bool isEditing,
    required bool contributesToHydration,
    required MeasurementUnit inputUnit,
  }) onCalculateBakerPercentage;
  final double Function(double, Ingredient, MeasurementUnit) convertQuantityToGrams;

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
  State<_IngredientFormDialogContent> createState() => _IngredientFormDialogContentState();
}

class _IngredientFormDialogContentState extends State<_IngredientFormDialogContent> {
  late RecipeIngredient _tempRecipeIngredient;
  late TextEditingController _quantityController;
  late TextEditingController _percentageController;
  late MeasurementUnit _selectedInputUnit; // Unidad que el usuario ve y edita
  late Ingredient? _currentSelectedIngredient; // Para mantener el ingrediente seleccionado

  @override
  void initState() {
    super.initState();
    if (widget.ingredientToEdit != null) {
      _tempRecipeIngredient = widget.ingredientToEdit!.copyWith();
      _currentSelectedIngredient = widget.availableIngredients.firstWhereOrNull(
        (ing) => ing.id == _tempRecipeIngredient.ingredientId,
      );
      debugPrint('Editando ingrediente: ${_tempRecipeIngredient.ingredient?.name}');
      debugPrint('displayUnit guardada: ${_tempRecipeIngredient.displayUnit?.label}');
      debugPrint('defaultUnit del ingrediente: ${_currentSelectedIngredient?.defaultUnit.label}');
    } else {
      _tempRecipeIngredient = RecipeIngredient(
        id: const Uuid().v4(),
        recipeId: widget.recipeId ?? '',
        ingredientId: '',
        quantity: 0.0,
        unit: MeasurementUnit.grams, // La unidad interna siempre es gramos
        displayUnit: null, // Se establecerá al seleccionar un ingrediente o al guardar
        bakerPercentage: 0.0,
        contributesToHydration: false,
      );
      _currentSelectedIngredient = null; // Asegurarse de que sea nulo para nuevos ingredientes
      debugPrint('Añadiendo nuevo ingrediente.');
    }

    // Determinar la unidad de visualización inicial y la cantidad a mostrar
    MeasurementUnit initialDisplayUnit;
    double quantityToShow;

    if (_currentSelectedIngredient != null) {
      // Si estamos editando y hay una displayUnit guardada, usarla
      initialDisplayUnit = _tempRecipeIngredient.displayUnit ?? _currentSelectedIngredient!.defaultUnit;
      // Convertir la cantidad (que está en gramos) a la unidad de visualización
      quantityToShow = _convertGramsToDisplayUnit(
        _tempRecipeIngredient.quantity,
        _currentSelectedIngredient!,
        initialDisplayUnit,
      );
    } else {
      // Si es un nuevo ingrediente o no hay displayUnit guardada, usar gramos por defecto
      initialDisplayUnit = MeasurementUnit.grams;
      quantityToShow = _tempRecipeIngredient.quantity; // Cantidad inicial es 0.0
    }

    _selectedInputUnit = initialDisplayUnit;
    _quantityController = TextEditingController(text: quantityToShow.toStringAsFixed(2));
    _percentageController = TextEditingController(text: _tempRecipeIngredient.bakerPercentage.toStringAsFixed(2));

    debugPrint('Unidad de visualización inicial: ${_selectedInputUnit.label}');
    debugPrint('Cantidad a mostrar: ${quantityToShow.toStringAsFixed(2)}');

    // Inicializar el porcentaje si se está editando o si ya hay datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if ((widget.ingredientToEdit != null && _percentageController.text.isEmpty) ||
          (_tempRecipeIngredient.ingredientId.isNotEmpty && _quantityController.text.isNotEmpty && _percentageController.text.isEmpty)) {
        final double? quantity = double.tryParse(_quantityController.text);
        final Ingredient? selectedIng = widget.availableIngredients.firstWhereOrNull(
          (ing) => ing.id == _tempRecipeIngredient.ingredientId,
        );
        if (quantity != null && selectedIng != null) {
          widget.onCalculateBakerPercentage(
            recipeIngredientIdToTrack: _tempRecipeIngredient.id,
            selectedIngredient: selectedIng,
            quantityText: _quantityController.text,
            percentageController: _percentageController,
            setStateCallback: setState,
            isEditing: widget.ingredientToEdit != null,
            contributesToHydration: _tempRecipeIngredient.contributesToHydration,
            inputUnit: _selectedInputUnit,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  // Método auxiliar para convertir gramos a la unidad de visualización
  double _convertGramsToDisplayUnit(double grams, Ingredient ingredient, MeasurementUnit displayUnit) {
    if (displayUnit == MeasurementUnit.grams) {
      return grams;
    } else if (displayUnit == ingredient.defaultUnit) {
      if (ingredient.defaultUnit == MeasurementUnit.kilograms) {
        return grams / 1000.0;
      } else if (ingredient.conversionFactorToGrams != null && ingredient.conversionFactorToGrams! > 0) {
        return grams / ingredient.conversionFactorToGrams!;
      }
    }
    // Si no hay una regla de conversión específica o la unidad de visualización no es la por defecto ni gramos,
    // asumimos que la cantidad ya está en gramos o no se puede convertir directamente.
    return grams;
  }

  @override
  Widget build(BuildContext context) {
    String? selectedIngredientId = _tempRecipeIngredient.ingredientId.isNotEmpty
        ? _tempRecipeIngredient.ingredientId
        : null;

    return AlertDialog(
      title: Text(widget.ingredientToEdit == null ? 'Añadir Ingrediente' : 'Editar Ingrediente'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Ingrediente'),
              value: selectedIngredientId,
              items: widget.availableIngredients.map((ingredient) {
                return DropdownMenuItem(
                  value: ingredient.id,
                  child: Text(ingredient.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tempRecipeIngredient = _tempRecipeIngredient.copyWith(ingredientId: value);
                  _currentSelectedIngredient = widget.availableIngredients.firstWhereOrNull(
                    (ing) => ing.id == value,
                  );
                  // Al cambiar el ingrediente, la unidad de visualización por defecto es la defaultUnit del nuevo ingrediente
                  // y la cantidad se resetea o se convierte a esa unidad.
                  if (_currentSelectedIngredient != null) {
                    _selectedInputUnit = _currentSelectedIngredient!.defaultUnit;
                    _quantityController.text = '0.0'; // Resetear cantidad al cambiar de ingrediente
                    _percentageController.text = ''; // Resetear porcentaje
                    // Inicializar contributesToHydration con el valor del ingrediente seleccionado
                    _tempRecipeIngredient = _tempRecipeIngredient.copyWith(
                      contributesToHydration: _currentSelectedIngredient!.contributesToHydration,
                    );
                  } else {
                    _selectedInputUnit = MeasurementUnit.grams; // Fallback
                    _quantityController.text = '0.0';
                    _percentageController.text = '';
                    _tempRecipeIngredient = _tempRecipeIngredient.copyWith(
                      contributesToHydration: false, // Resetear a false si no hay ingrediente seleccionado
                    );
                  }
                  // Recalcular porcentaje si ya hay cantidad
                  if (_currentSelectedIngredient != null && _quantityController.text.isNotEmpty) {
                    widget.onCalculateBakerPercentage(
                      recipeIngredientIdToTrack: _tempRecipeIngredient.id,
                      selectedIngredient: _currentSelectedIngredient,
                      quantityText: _quantityController.text,
                      percentageController: _percentageController,
                      setStateCallback: setState,
                      isEditing: widget.ingredientToEdit != null,
                      contributesToHydration: _tempRecipeIngredient.contributesToHydration,
                      inputUnit: _selectedInputUnit,
                    );
                  }
                });
              },
            ),
            // Nuevo Dropdown para la unidad de visualización
            if (_currentSelectedIngredient != null)
              DropdownButtonFormField<MeasurementUnit>(
                decoration: const InputDecoration(labelText: 'Unidad de Visualización'),
                value: _selectedInputUnit,
                items: <MeasurementUnit>[
                  _currentSelectedIngredient!.defaultUnit,
                  MeasurementUnit.grams,
                ].toSet().map<DropdownMenuItem<MeasurementUnit>>((MeasurementUnit value) {
                  return DropdownMenuItem<MeasurementUnit>(
                    value: value,
                    child: Text(value.label),
                  );
                }).toList(),
                onChanged: (MeasurementUnit? newValue) {
                  if (newValue != null) {
                    setState(() {
                      // Convertir la cantidad actual a la nueva unidad de visualización
                      final double currentQuantity = double.tryParse(_quantityController.text) ?? 0.0;
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
                      _quantityController.text = newQuantity.toStringAsFixed(2);
                      _selectedInputUnit = newValue;

                      // Recalcular porcentaje con la nueva unidad de entrada
                      widget.onCalculateBakerPercentage(
                        recipeIngredientIdToTrack: _tempRecipeIngredient.id,
                        selectedIngredient: _currentSelectedIngredient,
                        quantityText: _quantityController.text,
                        percentageController: _percentageController,
                        setStateCallback: setState,
                        isEditing: widget.ingredientToEdit != null,
                        contributesToHydration: _tempRecipeIngredient.contributesToHydration,
                        inputUnit: _selectedInputUnit,
                      );
                    });
                  }
                },
              ),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (_currentSelectedIngredient != null) {
                  widget.onCalculateBakerPercentage(
                    recipeIngredientIdToTrack: _tempRecipeIngredient.id,
                    selectedIngredient: _currentSelectedIngredient,
                    quantityText: value,
                    percentageController: _percentageController,
                    setStateCallback: setState,
                    isEditing: widget.ingredientToEdit != null,
                    contributesToHydration: _tempRecipeIngredient.contributesToHydration,
                    inputUnit: _selectedInputUnit,
                  );
                }
              },
            ),
            TextFormField(
              controller: _percentageController,
              decoration: const InputDecoration(labelText: 'Porcentaje Panadero'),
              readOnly: true,
            ),
            SwitchListTile(
              title: const Text('Contribuye a la hidratación'),
              subtitle: const Text(
                'Indica si este ingrediente se considera líquido en los cálculos de porcentaje de panadero.',
              ),
              value: _tempRecipeIngredient.contributesToHydration,
              onChanged: (bool value) {
                setState(() {
                  _tempRecipeIngredient = _tempRecipeIngredient.copyWith(contributesToHydration: value);
                  // Recalcular porcentaje al cambiar la contribución a la hidratación
                  if (_currentSelectedIngredient != null && _quantityController.text.isNotEmpty) {
                    widget.onCalculateBakerPercentage(
                      recipeIngredientIdToTrack: _tempRecipeIngredient.id,
                      selectedIngredient: _currentSelectedIngredient,
                      quantityText: _quantityController.text,
                      percentageController: _percentageController,
                      setStateCallback: setState,
                      isEditing: widget.ingredientToEdit != null,
                      contributesToHydration: _tempRecipeIngredient.contributesToHydration,
                      inputUnit: _selectedInputUnit,
                    );
                  }
                });
              },
            ),
            TextFormField(
              initialValue: _tempRecipeIngredient.notes,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              maxLines: 2,
              onChanged: (value) {
                _tempRecipeIngredient = _tempRecipeIngredient.copyWith(notes: value);
              },
            ),
            SwitchListTile(
              title: const Text('Es opcional'),
              subtitle: const Text(
                'Indica si este ingrediente es opcional en la receta.',
              ),
              value: _tempRecipeIngredient.isOptional,
              onChanged: (bool value) {
                setState(() {
                  _tempRecipeIngredient = _tempRecipeIngredient.copyWith(isOptional: value);
                });
              },
            ),
            const SizedBox(height: 20),
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
                    if (_currentSelectedIngredient == null || _quantityController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, selecciona un ingrediente y una cantidad.')),
                      );
                      return;
                    }
                    final double? quantity = double.tryParse(_quantityController.text);
                    if (quantity == null || quantity <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor, ingresa una cantidad válida.')),
                      );
                      return;
                    }

                    // Convertir la cantidad ingresada a gramos para el almacenamiento interno
                    final double quantityInGrams = widget.convertQuantityToGrams(
                      quantity,
                      _currentSelectedIngredient!,
                      _selectedInputUnit,
                    );

                    final savedRecipeIngredient = _tempRecipeIngredient.copyWith(
                      ingredientId: _currentSelectedIngredient!.id,
                      quantity: quantityInGrams, // Guardar en gramos
                      unit: MeasurementUnit.grams, // La unidad interna siempre es gramos
                      displayUnit: _selectedInputUnit, // Guardar la unidad de visualización
                      ingredient: _currentSelectedIngredient, // Adjuntar el objeto Ingredient
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