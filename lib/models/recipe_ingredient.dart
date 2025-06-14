import 'package:uuid/uuid.dart';
import 'ingredient.dart';

class RecipeIngredient {
  final String id;
  final String recipeId;
  final String ingredientId;
  double quantity;
  MeasurementUnit unit;
  MeasurementUnit? displayUnit; // Nueva propiedad
  String? notes;
  bool isOptional;
  bool contributesToHydration;
  double bakerPercentage;
  int sortOrder;
  DateTime createdAt;
  DateTime updatedAt;

  // Ingrediente asociado (no se almacena directamente en BD)
  Ingredient? ingredient;

  RecipeIngredient({
    String? id,
    required this.recipeId,
    required this.ingredientId,
    required this.quantity,
    required this.unit,
    this.displayUnit, // Añadir al constructor
    this.notes,
    this.isOptional = false,
    this.contributesToHydration = false,
    this.bakerPercentage = 0.0,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.ingredient,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Factory constructor para crear desde Map (SQLite)
  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      id: map['id'],
      recipeId: map['recipe_id'],
      ingredientId: map['ingredient_id'],
      quantity: double.parse(
        (map['quantity'] as num).toDouble().toStringAsFixed(6),
      ),
      unit: MeasurementUnit.values[map['unit']],
      displayUnit:
          map['display_unit'] != null
              ? MeasurementUnit.values[map['display_unit']]
              : null, // Leer displayUnit
      notes: map['notes'],
      isOptional: map['is_optional'] == 1,
      contributesToHydration: map['contributes_to_hydration'] == 1,
      bakerPercentage: double.parse(
        ((map['baker_percentage'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(
          6,
        ),
      ),
      sortOrder: map['sort_order'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Convertir a Map para guardar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'ingredient_id': ingredientId,
      'quantity': quantity,
      'unit': unit.index,
      'display_unit': displayUnit?.index, // Escribir displayUnit
      'notes': notes,
      'is_optional': isOptional ? 1 : 0,
      'contributes_to_hydration': contributesToHydration ? 1 : 0,
      'baker_percentage': bakerPercentage,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Método para actualizar el timestamp
  void touch() {
    updatedAt = DateTime.now();
  }

  // Copy constructor
  RecipeIngredient copyWith({
    String? recipeId,
    String? ingredientId,
    double? quantity,
    MeasurementUnit? unit,
    MeasurementUnit? displayUnit, // Añadir a copyWith
    String? notes,
    bool? isOptional,
    bool? contributesToHydration,
    double? bakerPercentage,
    int? sortOrder,
    Ingredient? ingredient,
  }) {
    return RecipeIngredient(
      id: id,
      recipeId: recipeId ?? this.recipeId,
      ingredientId: ingredientId ?? this.ingredientId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      displayUnit: displayUnit ?? this.displayUnit, // Asignar displayUnit
      notes: notes ?? this.notes,
      isOptional: isOptional ?? this.isOptional,
      contributesToHydration:
          contributesToHydration ?? this.contributesToHydration,
      bakerPercentage: bakerPercentage ?? this.bakerPercentage,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      ingredient: ingredient ?? this.ingredient,
    );
  }

  // Calcular cantidad escalada según factor
  double getScaledQuantity(double scaleFactor) {
    return quantity * scaleFactor;
  }

  // Obtener texto formateado para mostrar
  String getDisplayText({double? scaleFactor}) {
    final qty = scaleFactor != null ? getScaledQuantity(scaleFactor) : quantity;
    final ingredientName = ingredient?.name ?? 'Ingrediente desconocido';
    final unitLabel = unit.label;
    final optionalText = isOptional ? ' (opcional)' : '';

    return '$qty $unitLabel $ingredientName$optionalText';
  }

  @override
  String toString() {
    return 'RecipeIngredient(id: $id, quantity: $quantity, unit: $unit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecipeIngredient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
