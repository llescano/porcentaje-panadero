import 'package:decimal/decimal.dart';
import 'package:uuid/uuid.dart';

enum MeasurementUnit {
  grams,
  kilograms,
  milliliters,
  liters,
  pieces,
  tablespoons,
  teaspoons,
  cups,
}

enum IngredientCategory {
  flour,
  liquid,
  fat,
  sweetener,
  dairy,
  protein,
  leavening,
  seasoning,
  spice,
  fruit,
  vegetable,
  nut,
  chocolate,
  other,
}

class Ingredient {
  final String id;
  String name;
  String? description;
  MeasurementUnit defaultUnit;
  Decimal? costPerUnit;
  String? supplier;
  DateTime? expirationDate;
  IngredientCategory category;
  bool
  contributesToHydration; // Nueva propiedad para indicar si contribuye a la hidratación
  double?
  conversionFactorToGrams; // Nueva propiedad para el factor de conversión manual a gramos
  bool isActive;
  String? notes; // Nueva propiedad para notas adicionales
  DateTime createdAt;
  DateTime updatedAt;

  Ingredient({
    String? id,
    required this.name,
    this.description,
    required this.defaultUnit,
    this.costPerUnit,
    this.supplier,
    this.expirationDate,
    this.category = IngredientCategory.other,
    this.contributesToHydration = false, // Valor por defecto
    this.conversionFactorToGrams, // Inicializar la nueva propiedad
    this.isActive = true,
    this.notes, // Nueva propiedad para notas
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Factory constructor para crear desde Map (SQLite)
  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      defaultUnit:
          MeasurementUnit.values[map['default_unit'] as int? ??
              MeasurementUnit.grams.index], // Valor por defecto si es nulo
      costPerUnit:
          map['cost_per_unit'] != null
              ? Decimal.parse(map['cost_per_unit'].toString())
              : null,
      supplier: map['supplier'] as String?,
      expirationDate:
          map['expiration_date'] != null
              ? DateTime.parse(map['expiration_date'] as String)
              : null,
      category:
          IngredientCategory.values[map['category'] as int? ??
              IngredientCategory.other.index], // Valor por defecto si es nulo
      contributesToHydration:
          (map['contributes_to_hydration'] as int? ?? 0) ==
          1, // Valor por defecto si es nulo
      conversionFactorToGrams:
          map['conversion_factor_to_grams']
              as double?, // Deserializar la nueva propiedad
      isActive:
          (map['is_active'] as int? ?? 1) == 1, // Valor por defecto si es nulo
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Convertir a Map para guardar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'default_unit': defaultUnit.index,
      'cost_per_unit': costPerUnit?.toString(),
      'supplier': supplier,
      'expiration_date': expirationDate?.toIso8601String(),
      'category': category.index,
      'contributes_to_hydration': contributesToHydration ? 1 : 0,
      'conversion_factor_to_grams':
          conversionFactorToGrams, // Serializar la nueva propiedad
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Método para actualizar el timestamp
  void touch() {
    updatedAt = DateTime.now();
  }

  // Copy constructor
  Ingredient copyWith({
    String? name,
    String? description,
    MeasurementUnit? defaultUnit,
    Decimal? costPerUnit,
    String? supplier,
    DateTime? expirationDate,
    IngredientCategory? category,
    bool? contributesToHydration,
    double? conversionFactorToGrams, // Añadir a copyWith
    bool? isActive,
    String? notes,
  }) {
    final ingredient = Ingredient(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      supplier: supplier ?? this.supplier,
      expirationDate: expirationDate ?? this.expirationDate,
      category: category ?? this.category,
      contributesToHydration:
          contributesToHydration ?? this.contributesToHydration,
      conversionFactorToGrams:
          conversionFactorToGrams ??
          this.conversionFactorToGrams, // Asignar en copyWith
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
    return ingredient;
  }

  @override
  String toString() {
    return 'Ingredient(id: $id, name: $name, defaultUnit: $defaultUnit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ingredient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Extensión para obtener etiquetas legibles de las unidades
extension MeasurementUnitExtension on MeasurementUnit {
  String get label {
    switch (this) {
      case MeasurementUnit.grams:
        return 'g';
      case MeasurementUnit.kilograms:
        return 'kg';
      case MeasurementUnit.milliliters:
        return 'ml';
      case MeasurementUnit.liters:
        return 'l';
      case MeasurementUnit.pieces:
        return 'unid';
      case MeasurementUnit.tablespoons:
        return 'cda';
      case MeasurementUnit.teaspoons:
        return 'cdta';
      case MeasurementUnit.cups:
        return 'taza';
    }
  }

  String get fullName {
    switch (this) {
      case MeasurementUnit.grams:
        return 'Gramos';
      case MeasurementUnit.kilograms:
        return 'Kilogramos';
      case MeasurementUnit.milliliters:
        return 'Mililitros';
      case MeasurementUnit.liters:
        return 'Litros';
      case MeasurementUnit.pieces:
        return 'Unidades';
      case MeasurementUnit.tablespoons:
        return 'Cucharadas';
      case MeasurementUnit.teaspoons:
        return 'Cucharaditas';
      case MeasurementUnit.cups:
        return 'Tazas';
    }
  }
}

// Extensión para obtener etiquetas legibles de las categorías
extension IngredientCategoryExtension on IngredientCategory {
  String get label {
    switch (this) {
      case IngredientCategory.flour:
        return 'Harina';
      case IngredientCategory.liquid:
        return 'Líquido';
      case IngredientCategory.fat:
        return 'Grasa';
      case IngredientCategory.sweetener:
        return 'Endulzante';
      case IngredientCategory.dairy:
        return 'Lácteo';
      case IngredientCategory.protein:
        return 'Proteína';
      case IngredientCategory.leavening:
        return 'Leudante';
      case IngredientCategory.seasoning:
        return 'Condimento';
      case IngredientCategory.spice:
        return 'Especia';
      case IngredientCategory.fruit:
        return 'Fruta';
      case IngredientCategory.vegetable:
        return 'Vegetal';
      case IngredientCategory.nut:
        return 'Fruto seco';
      case IngredientCategory.chocolate:
        return 'Chocolate';
      case IngredientCategory.other:
        return 'Otro';
    }
  }
}
