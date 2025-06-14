import 'package:uuid/uuid.dart';
import 'recipe_ingredient.dart';

enum RecipeCategory {
  bread,
  pastry,
  cake,
  cookie,
  pizza,
  pasta,
  sauce,
  cream,
  chocolate,
  other,
}

enum DifficultyLevel { beginner, intermediate, advanced, expert }

class Recipe {
  final String id;
  String name;
  String? description;
  RecipeCategory category;
  DifficultyLevel difficulty;
  int preparationTimeMinutes;
  int bakingTimeMinutes;
  int restTimeMinutes;
  int servings;
  String? instructions;
  String? notes;
  String? imageUrl;
  bool isFavorite;
  bool isActive;
  double? lastTotalDoughWeight;
  DateTime createdAt;
  DateTime updatedAt;

  // Lista de ingredientes (no se almacena directamente en BD)
  List<RecipeIngredient> ingredients;

  Recipe({
    String? id,
    required this.name,
    this.description,
    this.category = RecipeCategory.other,
    this.difficulty = DifficultyLevel.beginner,
    this.preparationTimeMinutes = 0,
    this.bakingTimeMinutes = 0,
    this.restTimeMinutes = 0,
    this.servings = 1,
    this.instructions,
    this.notes,
    this.imageUrl,
    this.isFavorite = false,
    this.isActive = true,
    this.lastTotalDoughWeight,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<RecipeIngredient>? ingredients,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       ingredients = ingredients ?? [];

  // Factory constructor para crear desde Map (SQLite)
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: RecipeCategory.values[map['category']],
      difficulty: DifficultyLevel.values[map['difficulty']],
      preparationTimeMinutes: map['preparation_time_minutes'] ?? 0,
      bakingTimeMinutes: map['baking_time_minutes'] ?? 0,
      restTimeMinutes: map['rest_time_minutes'] ?? 0,
      servings: map['servings'] ?? 1,
      instructions: map['instructions'],
      notes: map['notes'],
      imageUrl: map['image_url'],
      isFavorite: map['is_favorite'] == 1,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      lastTotalDoughWeight:
          (map['last_total_dough_weight'] as num?)?.toDouble(),
    );
  }

  // Convertir a Map para guardar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.index,
      'difficulty': difficulty.index,
      'preparation_time_minutes': preparationTimeMinutes,
      'baking_time_minutes': bakingTimeMinutes,
      'rest_time_minutes': restTimeMinutes,
      'servings': servings,
      'instructions': instructions,
      'notes': notes,
      'image_url': imageUrl,
      'is_favorite': isFavorite ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_total_dough_weight': lastTotalDoughWeight,
    };
  }

  // Calcular tiempo total de la receta
  int get totalTimeMinutes {
    return preparationTimeMinutes + bakingTimeMinutes + restTimeMinutes;
  }

  // Método para actualizar el timestamp
  void touch() {
    updatedAt = DateTime.now();
  }

  // Copy constructor
  Recipe copyWith({
    String? name,
    String? description,
    RecipeCategory? category,
    DifficultyLevel? difficulty,
    int? preparationTimeMinutes,
    int? bakingTimeMinutes,
    int? restTimeMinutes,
    int? servings,
    String? instructions,
    String? notes,
    String? imageUrl,
    bool? isFavorite,
    bool? isActive,
    double? lastTotalDoughWeight,
    List<RecipeIngredient>? ingredients,
  }) {
    return Recipe(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      preparationTimeMinutes:
          preparationTimeMinutes ?? this.preparationTimeMinutes,
      bakingTimeMinutes: bakingTimeMinutes ?? this.bakingTimeMinutes,
      restTimeMinutes: restTimeMinutes ?? this.restTimeMinutes,
      servings: servings ?? this.servings,
      instructions: instructions ?? this.instructions,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      ingredients: ingredients ?? List.from(this.ingredients),
      lastTotalDoughWeight: lastTotalDoughWeight ?? this.lastTotalDoughWeight,
    );
  }

  @override
  String toString() {
    return 'Recipe(id: $id, name: $name, servings: $servings)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recipe && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Extensiones para obtener etiquetas legibles
extension RecipeCategoryExtension on RecipeCategory {
  String get label {
    switch (this) {
      case RecipeCategory.bread:
        return 'Pan';
      case RecipeCategory.pastry:
        return 'Pastelería';
      case RecipeCategory.cake:
        return 'Torta';
      case RecipeCategory.cookie:
        return 'Galleta';
      case RecipeCategory.pizza:
        return 'Pizza';
      case RecipeCategory.pasta:
        return 'Pasta';
      case RecipeCategory.sauce:
        return 'Salsa';
      case RecipeCategory.cream:
        return 'Crema';
      case RecipeCategory.chocolate:
        return 'Chocolate';
      case RecipeCategory.other:
        return 'Otro';
    }
  }
}

extension DifficultyLevelExtension on DifficultyLevel {
  String get label {
    switch (this) {
      case DifficultyLevel.beginner:
        return 'Principiante';
      case DifficultyLevel.intermediate:
        return 'Intermedio';
      case DifficultyLevel.advanced:
        return 'Avanzado';
      case DifficultyLevel.expert:
        return 'Experto';
    }
  }
}
