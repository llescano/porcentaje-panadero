import '../database/database_helper.dart';
import '../models/ingredient.dart';

class IngredientService {
  final DatabaseHelper _db = DatabaseHelper();

  // Crear un nuevo ingrediente
  Future<String> createIngredient(Ingredient ingredient) async {
    final db = await _db.database;
    await db.insert('ingredients', ingredient.toMap());
    return ingredient.id;
  }

  // Obtener todos los ingredientes activos
  Future<List<Ingredient>> getActiveIngredients() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ingredients',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Ingredient.fromMap(maps[i]);
    });
  }

  // Obtener todos los ingredientes (activos e inactivos)
  Future<List<Ingredient>> getAllIngredients() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ingredients',
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Ingredient.fromMap(maps[i]);
    });
  }

  // Obtener ingrediente por ID
  Future<Ingredient?> getIngredientById(String id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Ingredient.fromMap(maps.first);
    }
    return null;
  }

  // Buscar ingredientes por nombre
  Future<List<Ingredient>> searchIngredients(String query) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ingredients',
      where: 'name LIKE ? AND is_active = ?',
      whereArgs: ['%$query%', 1],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Ingredient.fromMap(maps[i]);
    });
  }

  // Obtener ingredientes por categoría
  Future<List<Ingredient>> getIngredientsByCategory(IngredientCategory category) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ingredients',
      where: 'category = ? AND is_active = ?',
      whereArgs: [category.index, 1],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Ingredient.fromMap(maps[i]);
    });
  }

  // Actualizar ingrediente
  Future<void> updateIngredient(Ingredient ingredient) async {
    final db = await _db.database;
    ingredient.touch(); // Actualizar timestamp
    await db.update(
      'ingredients',
      ingredient.toMap(),
      where: 'id = ?',
      whereArgs: [ingredient.id],
    );
  }

  // Eliminar ingrediente (soft delete)
  Future<void> deleteIngredient(String id) async {
    final db = await _db.database;
    await db.update(
      'ingredients',
      {
        'is_active': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Eliminar ingrediente permanentemente
  Future<void> deleteIngredientPermanently(String id) async {
    final db = await _db.database;
    await db.delete(
      'ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Restaurar ingrediente
  Future<void> restoreIngredient(String id) async {
    final db = await _db.database;
    await db.update(
      'ingredients',
      {
        'is_active': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Verificar si un ingrediente está siendo usado en recetas
  Future<bool> isIngredientInUse(String ingredientId) async {
    final db = await _db.database;
    final result = await db.query(
      'recipe_ingredients',
      where: 'ingredient_id = ?',
      whereArgs: [ingredientId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Obtener estadísticas de ingredientes
  Future<Map<String, int>> getIngredientStats() async {
    final db = await _db.database;
    
    final activeCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ingredients WHERE is_active = 1'
    );
    
    final totalCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ingredients'
    );

    final categoryStats = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM ingredients 
      WHERE is_active = 1 
      GROUP BY category
    ''');

    Map<String, int> stats = {
      'active': activeCount.first['count'] as int,
      'total': totalCount.first['count'] as int,
    };

    for (var row in categoryStats) {
      final category = IngredientCategory.values[row['category'] as int];
      stats[category.name] = row['count'] as int;
    }

    return stats;
  }

  // Importar ingredientes en lote
  Future<List<String>> importIngredients(List<Ingredient> ingredients) async {
    final db = await _db.database;
    final batch = db.batch();
    final ids = <String>[];

    for (var ingredient in ingredients) {
      batch.insert('ingredients', ingredient.toMap());
      ids.add(ingredient.id);
    }

    await batch.commit();
    return ids;
  }

  // Exportar ingredientes
  Future<List<Ingredient>> exportIngredients({bool activeOnly = true}) async {
    if (activeOnly) {
      return await getActiveIngredients();
    } else {
      return await getAllIngredients();
    }
  }
}
