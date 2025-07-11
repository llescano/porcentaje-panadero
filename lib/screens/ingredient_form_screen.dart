import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart'; // Importar NumberFormat
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';
import '../widgets/custom_app_bar.dart'; // Importar CustomAppBar

class IngredientFormScreen extends StatefulWidget {
  final Ingredient? ingredient;

  const IngredientFormScreen({super.key, this.ingredient});

  @override
  State<IngredientFormScreen> createState() => _IngredientFormScreenState();
}

class _IngredientFormScreenState extends State<IngredientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _supplierController = TextEditingController();
  final _conversionFactorToGramsController = TextEditingController();
  final _notesController = TextEditingController();

  MeasurementUnit _selectedUnit = MeasurementUnit.grams;
  IngredientCategory _selectedCategory = IngredientCategory.other;
  DateTime? _expirationDate;
  bool _contributesToHydration = false;
  bool _isActive = true;
  double? _conversionFactorToGrams;
  bool _isLoading = false;

  final IngredientService _ingredientService = IngredientService();

  // Función para capitalizar la primera letra
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text[0].toUpperCase() + text.substring(1);
  }

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

  @override
  void initState() {
    super.initState();
    if (widget.ingredient != null) {
      _loadIngredientData();
    }
    // Enfocar automáticamente el campo del nombre al cargar el formulario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocusNode);
    });
  }

  void _loadIngredientData() {
    final ingredient = widget.ingredient!;
    _nameController.text = ingredient.name;
    _descriptionController.text = ingredient.description ?? '';
    _costController.text =
        ingredient.costPerUnit != null
            ? NumberFormat(
              '###,##0.00',
              'es_ES',
            ).format(ingredient.costPerUnit!.toDouble())
            : '';
    _supplierController.text = ingredient.supplier ?? '';
    _selectedUnit = ingredient.defaultUnit;
    _selectedCategory = ingredient.category;
    _expirationDate = ingredient.expirationDate;
    _contributesToHydration = ingredient.contributesToHydration;
    _isActive = ingredient.isActive;
    _notesController.text = ingredient.notes ?? '';
    _conversionFactorToGrams = ingredient.conversionFactorToGrams;
    _conversionFactorToGramsController.text =
        ingredient.conversionFactorToGrams != null
            ? NumberFormat(
              '###,##0.00',
              'es_ES',
            ).format(ingredient.conversionFactorToGrams!)
            : '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _supplierController.dispose();
    _conversionFactorToGramsController.dispose();
    _notesController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      double? finalConversionFactor;
      if (_selectedUnit == MeasurementUnit.grams ||
          _selectedUnit == MeasurementUnit.kilograms) {
        finalConversionFactor = 1.0;
      } else {
        // Usar la función auxiliar para parsear el número
        finalConversionFactor = _parseFormattedNumber(
          _conversionFactorToGramsController.text,
        );
      }

      final ingredient = Ingredient(
        id: widget.ingredient?.id,
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        defaultUnit: _selectedUnit,
        costPerUnit:
            _costController.text.trim().isEmpty
                ? null
                : Decimal.parse(
                  _costController.text
                      .trim()
                      .replaceAll(',', '')
                      .replaceFirst(
                        '.',
                        '',
                      ), // Limpiar antes de parsear a Decimal
                ),
        supplier:
            _supplierController.text.trim().isEmpty
                ? null
                : _supplierController.text.trim(),
        expirationDate: _expirationDate,
        category: _selectedCategory,
        contributesToHydration: _contributesToHydration,
        conversionFactorToGrams: finalConversionFactor,
        isActive: _isActive,
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
        createdAt: widget.ingredient?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (widget.ingredient == null) {
        await _ingredientService.createIngredient(ingredient);
      } else {
        await _ingredientService.updateIngredient(ingredient);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ingredient == null
                  ? 'Ingrediente creado exitosamente'
                  : 'Ingrediente actualizado exitosamente',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _expirationDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  bool _isMassUnit(MeasurementUnit unit) {
    return unit == MeasurementUnit.grams || unit == MeasurementUnit.kilograms;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title:
            widget.ingredient == null
                ? 'Nuevo Ingrediente'
                : 'Editar Ingrediente',
        isForm: true,
        isLoading: _isLoading,
        onSave: _saveIngredient,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Estado activo (movido al inicio) - Switch más pequeño
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.power_settings_new, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ingrediente activo',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _isActive
                                ? 'Disponible para usar en recetas'
                                : 'No disponible para usar',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8, // Hacer el switch más pequeño
                      child: Switch(
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Controles restantes (habilitados/deshabilitados según _isActive)
            Opacity(
              opacity: _isActive ? 1.0 : 0.5,
              child: AbsorbPointer(
                absorbing: !_isActive,
                child: Column(
                  children: [
                    // Nombre del ingrediente
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del ingrediente *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.grain),
                      ),
                      validator: (value) {
                        if (_isActive &&
                            (value == null || value.trim().isEmpty)) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        final String capitalizedValue = _capitalizeFirstLetter(value);
                        if (_nameController.text != capitalizedValue) {
                          _nameController.value = _nameController.value.copyWith(
                            text: capitalizedValue,
                            selection: TextSelection.collapsed(
                              offset: capitalizedValue.length,
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Descripción - Campo expandible
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      minLines: 1,
                      maxLines: null, // Permite expansión ilimitada
                      keyboardType: TextInputType.multiline,
                    ),

                    const SizedBox(height: 16),

                    // Categoría
                    DropdownButtonFormField<IngredientCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items:
                          IngredientCategory.values.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category.label),
                            );
                          }).toList(),
                      onChanged:
                          _isActive
                              ? (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                }
                              }
                              : null,
                    ),

                    const SizedBox(height: 16),

                    // Unidad de medida por defecto
                    DropdownButtonFormField<MeasurementUnit>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unidad de medida *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      items:
                          MeasurementUnit.values.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text('${unit.fullName} (${unit.label})'),
                            );
                          }).toList(),
                      onChanged:
                          _isActive
                              ? (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedUnit = value;
                                    // Si la unidad seleccionada es de masa, limpiar el campo de conversión
                                    if (_isMassUnit(value)) {
                                      _conversionFactorToGramsController
                                          .clear();
                                      _conversionFactorToGrams =
                                          1.0; // Establecer implícitamente a 1.0
                                    } else {
                                      // Si no es de masa, restaurar el valor si existe o dejar nulo
                                      _conversionFactorToGrams =
                                          widget
                                              .ingredient
                                              ?.conversionFactorToGrams;
                                      _conversionFactorToGramsController.text =
                                          _conversionFactorToGrams
                                              ?.toString() ??
                                          '';
                                    }
                                  });
                                }
                              }
                              : null,
                    ),

                    const SizedBox(height: 16),

                    // Campo de factor de conversión a gramos (condicional)
                    if (!_isMassUnit(
                      _selectedUnit,
                    )) // Solo mostrar si no es unidad de masa
                      TextFormField(
                        controller: _conversionFactorToGramsController,
                        decoration: InputDecoration(
                          labelText: 'En gramos',
                          hintText: 'Ej: 1 taza = 240 g',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.balance),
                          suffixText: 'g / ${_selectedUnit.label}',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (_isActive &&
                              !_isMassUnit(_selectedUnit) &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Este campo es obligatorio si la unidad no es de masa';
                          }
                          if (value != null && value.trim().isNotEmpty) {
                            // Usar la función auxiliar para parsear el valor para la validación
                            final parsedValue = _parseFormattedNumber(value);
                            if (parsedValue == null || parsedValue <= 0) {
                              return 'Ingresa un número positivo válido';
                            }
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            // Usar la función auxiliar para parsear el valor al cambiar
                            _conversionFactorToGrams = _parseFormattedNumber(
                              value,
                            );
                          });
                        },
                      ),

                    if (!_isMassUnit(_selectedUnit))
                      const SizedBox(height: 16), // Espacio condicional
                    // Costo por unidad
                    TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(
                        labelText: 'Costo por unidad',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        suffixText: '\$',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          try {
                            // Limpiar el valor antes de intentar parsear a Decimal
                            Decimal.parse(
                              value
                                  .trim()
                                  .replaceAll(',', '')
                                  .replaceFirst('.', ''),
                            );
                          } catch (e) {
                            return 'Ingresa un número válido';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Proveedor
                    TextFormField(
                      controller: _supplierController,
                      decoration: const InputDecoration(
                        labelText: 'Proveedor',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Fecha de vencimiento
                    ListTile(
                      title: const Text('Fecha de vencimiento'),
                      subtitle: Text(
                        _expirationDate == null
                            ? 'No establecida'
                            : '${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}',
                      ),
                      leading: const Icon(Icons.calendar_today),
                      trailing:
                          _expirationDate == null
                              ? const Icon(Icons.add)
                              : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed:
                                    () =>
                                        setState(() => _expirationDate = null),
                              ),
                      onTap: _isActive ? _selectExpirationDate : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Contribuye a la hidratación - Switch más pequeño
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.water_drop, color: Colors.grey),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Cuenta como líquido',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Transform.scale(
                              scale: 0.8, // Hacer el switch más pequeño
                              child: Switch(
                                value: _contributesToHydration,
                                onChanged:
                                    _isActive
                                        ? (value) {
                                          setState(() {
                                            _contributesToHydration = value;
                                          });
                                        }
                                        : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notas - Campo expandible al final
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                        alignLabelWithHint: true,
                      ),
                      minLines: 1,
                      maxLines: null, // Permite expansión ilimitada
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
