import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../services/ingredient_service.dart';

class RecipeService {
  DatabaseHelper? _db;
  final IngredientService _ingredientService = IngredientService();
  
  DatabaseHelper? get db {
    if (kIsWeb) return null;
    _db ??= DatabaseHelper();
    return _db;
  }

  // Crear una nueva receta
  Future<String> addRecipe(Recipe recipe, List<RecipeIngredient> ingredients) async {
    if (kIsWeb) {
      // En web, simular éxito pero no hacer nada
      return recipe.id;
    }
    final database = await db!.database;
    
    await database.transaction((txn) async {
      await txn.insert('recipes', recipe.toMap());
      for (var ri in ingredients) {
        await txn.insert('recipe_ingredients', ri.toMap());
      }
    });
    return recipe.id;
  }

  // Obtener todas las recetas
  Future<List<Recipe>> getRecipes() async {
    if (kIsWeb) {
      // En web, retornar lista vacía
      return [];
    }
    final database = await db!.database;
    final List<Map<String, dynamic>> maps = await database.query(
      'recipes',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    List<Recipe> recipes = [];
    for (var map in maps) {
      recipes.add(Recipe.fromMap(map));
    }
    return recipes;
  }

  // Obtener receta por ID
  Future<Recipe?> getRecipeById(String id) async {
    if (kIsWeb) {
      // En web, retornar null
      return null;
    }
    final database = await db!.database;
    final List<Map<String, dynamic>> maps = await database.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Recipe.fromMap(maps.first);
    }
    return null;
  }

  // Obtener ingredientes de una receta
  Future<List<RecipeIngredient>> getRecipeIngredients(String recipeId) async {
    if (kIsWeb) {
      // En web, retornar lista vacía
      return [];
    }
    final database = await db!.database;
    final List<Map<String, dynamic>> maps = await database.rawQuery('''
      SELECT ri.*, i.name as ingredient_name, i.default_unit as ingredient_unit
      FROM recipe_ingredients ri
      INNER JOIN ingredients i ON ri.ingredient_id = i.id
      WHERE ri.recipe_id = ?
      ORDER BY ri.sort_order ASC
    ''', [recipeId]);

    List<RecipeIngredient> recipeIngredients = [];
    for (var map in maps) {
      final recipeIngredient = RecipeIngredient.fromMap(map);
      // Cargar el objeto Ingredient completo
      recipeIngredient.ingredient = await _ingredientService.getIngredientById(recipeIngredient.ingredientId);
      recipeIngredients.add(recipeIngredient);
    }
    return recipeIngredients;
  }

  // Actualizar receta
  Future<void> updateRecipe(Recipe recipe, List<RecipeIngredient> ingredients) async {
    if (kIsWeb) {
      return;
    }
    final database = await db!.database;
    
    await database.transaction((txn) async {
      recipe.touch();
      await txn.update(
        'recipes',
        recipe.toMap(),
        where: 'id = ?',
        whereArgs: [recipe.id],
      );
      
      await txn.delete(
        'recipe_ingredients',
        where: 'recipe_id = ?',
        whereArgs: [recipe.id],
      );
      
      for (var ri in ingredients) {
        await txn.insert('recipe_ingredients', ri.toMap());
      }
    });
  }

  // Eliminar receta (soft delete)
  Future<void> deleteRecipe(String id) async {
    if (kIsWeb) {
      return;
    }
    final database = await db!.database;
    await database.update(
      'recipes',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Eliminar receta permanentemente
  Future<void> deleteRecipePermanently(String id) async {
    if (kIsWeb) {
      return;
    }
    final database = await db!.database;
    
    await database.transaction((txn) async {
      // Eliminar ingredientes de la receta
      await txn.delete(
        'recipe_ingredients',
        where: 'recipe_id = ?',
        whereArgs: [id],
      );
      
      // Eliminar la receta
      await txn.delete(
        'recipes',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // Restaurar receta
  Future<void> restoreRecipe(String id) async {
    if (kIsWeb) {
      return;
    }
    final database = await db!.database;
    await database.update(
      'recipes',
      {
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Duplicar receta
  Future<String> duplicateRecipe(String originalId, {String? newName}) async {
    final originalRecipe = await getRecipeById(originalId);
    if (originalRecipe == null) {
      throw Exception('Receta no encontrada');
    }

    final originalIngredients = await getRecipeIngredients(originalId);

    final duplicatedRecipe = originalRecipe.copyWith(
      name: newName ?? '${originalRecipe.name} (Copia)',
    );

    return await addRecipe(duplicatedRecipe, originalIngredients);
  }

  // Obtener estadísticas de recetas
  Future<Map<String, int>> getRecipeStats() async {
    if (kIsWeb) {
      return {'active': 0, 'total': 0};
    }
    final database = await db!.database;
    
    final activeCount = await database.rawQuery(
      'SELECT COUNT(*) as count FROM recipes WHERE is_active = 1'
    );
    
    final totalCount = await database.rawQuery(
      'SELECT COUNT(*) as count FROM recipes'
    );

    final categoryStats = await database.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM recipes 
      WHERE is_active = 1 
      GROUP BY category
    ''');

    Map<String, int> stats = {
      'active': activeCount.first['count'] as int,
      'total': totalCount.first['count'] as int,
    };

    for (var row in categoryStats) {
      final category = RecipeCategory.values[row['category'] as int];
      stats[category.name] = row['count'] as int;
    }

    return stats;
  }

  // Buscar recetas que usan un ingrediente específico
  Future<List<Recipe>> getRecipesByIngredient(String ingredientId) async {
    if (kIsWeb) {
      return [];
    }
    final database = await db!.database;
    final List<Map<String, dynamic>> maps = await database.rawQuery('''
      SELECT DISTINCT r.* 
      FROM recipes r
      INNER JOIN recipe_ingredients ri ON r.id = ri.recipe_id
      WHERE ri.ingredient_id = ? AND r.is_active = 1
      ORDER BY r.name ASC
    ''', [ingredientId]);

    List<Recipe> recipes = [];
    for (var map in maps) {
      recipes.add(Recipe.fromMap(map));
    }
    
    return recipes;
  }

  // Calcular costo total de una receta
  Future<double?> calculateRecipeCost(String recipeId) async {
    final recipeIngredients = await getRecipeIngredients(recipeId);
    if (recipeIngredients.isEmpty) return null;

    double totalCost = 0.0;
    bool hasAllCosts = true;

    for (var recipeIngredient in recipeIngredients) {
      final ingredient = await _ingredientService.getIngredientById(
        recipeIngredient.ingredientId
      );
      
      if (ingredient?.costPerUnit == null) {
        hasAllCosts = false;
        continue;
      }

      final cost = ingredient!.costPerUnit!.toDouble() * 
                   recipeIngredient.quantity.toDouble();
      totalCost += cost;
    }

    return hasAllCosts ? totalCost : null;
  }

  // Escalar receta
  List<RecipeIngredient> scaleRecipe(List<RecipeIngredient> ingredients, double scaleFactor) {
    return ingredients.map((ingredient) {
      return ingredient.copyWith(
        quantity: ingredient.quantity * scaleFactor,
        bakerPercentage: ingredient.bakerPercentage, // El porcentaje panadero no cambia al escalar
      );
    }).toList();
  }
}
