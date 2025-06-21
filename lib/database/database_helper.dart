import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/ingredient.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'porcentaje_panadero.db');

    return await openDatabase(
      path,
      version: 11, // Incrementar la versión de la base de datos
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('DatabaseHelper: _onCreate ejecutado. Versión: $version');
    // Tabla de ingredientes
    await db.execute('''
      CREATE TABLE ingredients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        default_unit INTEGER NOT NULL, -- Cambiado de 'unit' a 'default_unit'
        cost_per_unit REAL,
        supplier TEXT, -- Añadido supplier
        expiration_date TEXT, -- Añadido expiration_date
        category INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        contributes_to_hydration BOOLEAN NOT NULL DEFAULT 0,
        conversion_factor_to_grams REAL, -- Añadir la nueva columna
        is_optional INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabla de recetas
    await db.execute('''
      CREATE TABLE recipes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category INTEGER NOT NULL,
        difficulty INTEGER NOT NULL,
        preparation_time_minutes INTEGER NOT NULL DEFAULT 0,
        baking_time_minutes INTEGER NOT NULL DEFAULT 0,
        rest_time_minutes INTEGER NOT NULL DEFAULT 0,
        servings INTEGER NOT NULL DEFAULT 1,
        instructions TEXT,
        notes TEXT,
        image_url TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_total_dough_weight REAL -- Nuevo campo
      )
    ''');

    // Tabla de ingredientes de recetas (relación many-to-many)
    await db.execute('''
      CREATE TABLE recipe_ingredients (
        id TEXT PRIMARY KEY,
        recipe_id TEXT NOT NULL,
        ingredient_id TEXT NOT NULL,
        quantity REAL NOT NULL, -- Cambiado de TEXT a REAL
        unit INTEGER NOT NULL,
        display_unit INTEGER, -- Nueva columna para la unidad de visualización
        notes TEXT,
        is_optional INTEGER NOT NULL DEFAULT 0,
        baker_percentage REAL NOT NULL, -- Cambiado de TEXT a REAL
        sort_order INTEGER NOT NULL DEFAULT 0,
        contributes_to_hydration INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id) REFERENCES ingredients (id) ON DELETE CASCADE
      )
    ''');

    // Índices para mejorar performance
    await db.execute('CREATE INDEX idx_ingredients_name ON ingredients (name)');
    await db.execute(
      'CREATE INDEX idx_ingredients_category ON ingredients (category)',
    );
    await db.execute('CREATE INDEX idx_recipes_name ON recipes (name)');
    await db.execute('CREATE INDEX idx_recipes_category ON recipes (category)');
    await db.execute(
      'CREATE INDEX idx_recipe_ingredients_recipe_id ON recipe_ingredients (recipe_id)',
    );
    await db.execute(
      'CREATE INDEX idx_recipe_ingredients_ingredient_id ON recipe_ingredients (ingredient_id)',
    );

    // Insertar datos iniciales
    print('DatabaseHelper: Insertando datos iniciales...');
    await _insertInitialData(db);
    print('DatabaseHelper: Datos iniciales insertados.');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Aquí se manejarán las migraciones futuras
    if (oldVersion < 2 && newVersion >= 2) {
      // Migración de v1 a v2: añadir sort_order a recipe_ingredients
      await db.execute(
        'ALTER TABLE recipe_ingredients ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3 && newVersion >= 3) {
      // Migración de v2 a v3: añadir created_at y updated_at a recipe_ingredients
      await db.execute(
        'ALTER TABLE recipe_ingredients ADD COLUMN created_at TEXT NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%S.%fZ\', \'now\'))',
      );
      await db.execute(
        'ALTER TABLE recipe_ingredients ADD COLUMN updated_at TEXT NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%S.%fZ\', \'now\'))',
      );
    }
    if (oldVersion < 4 && newVersion >= 4) {
      // Migración de v3 a v4: añadir contributes_to_hydration a recipe_ingredients
      await db.execute(
        'ALTER TABLE recipe_ingredients ADD COLUMN contributes_to_hydration INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 5 && newVersion >= 5) {
      // Migración de v4 a v5: añadir contributes_to_hydration a ingredients
      await db.execute(
        'ALTER TABLE ingredients ADD COLUMN contributes_to_hydration BOOLEAN NOT NULL DEFAULT 0;',
      );
    }
    if (oldVersion < 7 && newVersion >= 7) {
      // Migración de v6 a v7: eliminar la columna density de ingredients
      await db.execute('ALTER TABLE ingredients DROP COLUMN density;');
    }
    if (oldVersion < 8 && newVersion >= 8) {
      // Migración de v7 a v8: añadir conversion_factor_to_grams a ingredients
      await db.execute(
        'ALTER TABLE ingredients ADD COLUMN conversion_factor_to_grams REAL;',
      );
    }
    if (oldVersion < 9 && newVersion >= 9) {
      // Migración de v8 a v9: añadir display_unit a recipe_ingredients
      await db.execute(
        'ALTER TABLE recipe_ingredients ADD COLUMN display_unit INTEGER;',
      );
    }
    if (oldVersion < 10 && newVersion >= 10) {
      // Migración de v9 a v10: añadir last_total_dough_weight a recipes
      await db.execute(
        'ALTER TABLE recipes ADD COLUMN last_total_dough_weight REAL;',
      );
    }
    if (oldVersion < 11 && newVersion >= 11) {
      // Migración de v10 a v11: añadir is_optional y notes a ingredients
      await db.execute(
        'ALTER TABLE ingredients ADD COLUMN is_optional INTEGER NOT NULL DEFAULT 0;',
      );
      await db.execute(
        'ALTER TABLE ingredients ADD COLUMN notes TEXT;',
      );
    }
  }

  Future<void> _insertInitialData(Database db) async {
    // Ingredientes básicos de panadería
    final basicIngredients = [
      {
        'id': 'ing_harina_000',
        'name': 'Harina 000',
        'description': 'Harina de trigo común',
        'default_unit':
            MeasurementUnit.grams.index, // Cambiado de 'unit' a 'default_unit'
        'category': IngredientCategory.flour.index,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'ing_agua',
        'name': 'Agua',
        'description': 'Agua filtrada',
        'default_unit':
            MeasurementUnit
                .milliliters
                .index, // Cambiado de 'unit' a 'default_unit'
        'category': IngredientCategory.liquid.index,
        'is_active': 1,
        'contributes_to_hydration': 1, // Establecer en true
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'ing_sal',
        'name': 'Sal',
        'description': 'Sal fina común',
        'default_unit':
            MeasurementUnit.grams.index, // Cambiado de 'unit' a 'default_unit'
        'category': IngredientCategory.seasoning.index,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'ing_levadura_fresca',
        'name': 'Levadura fresca',
        'description': 'Levadura prensada',
        'default_unit':
            MeasurementUnit.grams.index, // Cambiado de 'unit' a 'default_unit'
        'category': IngredientCategory.leavening.index,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'ing_aceite',
        'name': 'Aceite neutro',
        'description': 'Aceite de girasol o maíz',
        'default_unit':
            MeasurementUnit
                .milliliters
                .index, // Cambiado de 'unit' a 'default_unit'
        'category': IngredientCategory.fat.index,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'ing_azucar',
        'name': 'Azúcar común',
        'description': 'Azúcar blanca granulada',
        'default_unit':
            MeasurementUnit.grams.index, // Cambiado de 'unit' a 'default_unit'
        'category': IngredientCategory.sweetener.index,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'ing_huevo',
        'name': 'Huevo',
        'description': 'Huevo grande (aprox. 60g)',
        'default_unit':
            MeasurementUnit.pieces.index, // Cambiado de 'unit' a 'default_unit'
        'category': IngredientCategory.protein.index,
        'is_active': 1,
        'contributes_to_hydration': 1, // Establecer en true
        'conversion_factor_to_grams': 60.0, // Establecer factor de conversión
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'ing_manteca',
        'name': 'Manteca',
        'description': 'Manteca sin sal',
        'default_unit':
            MeasurementUnit.grams.index, // Cambiado de 'unit' a 'default_unit'
        'category': IngredientCategory.fat.index,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'ing_leche',
        'name': 'Leche entera',
        'description': 'Leche fresca entera',
        'default_unit':
            MeasurementUnit
                .milliliters
                .index, // Cambiado de 'unit' a 'default_unit'
        'category': IngredientCategory.dairy.index,
        'is_active': 1,
        'contributes_to_hydration': 1, // Establecer en true
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final ingredient in basicIngredients) {
      await db.insert('ingredients', ingredient);
    }
  }

  // Métodos para cerrar la base de datos
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // Método para eliminar la base de datos (útil para testing)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'porcentaje_panadero.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // Método para verificar la integridad de la base de datos
  Future<bool> checkDatabaseIntegrity() async {
    try {
      final db = await database;
      final result = await db.rawQuery('PRAGMA integrity_check');
      return result.isNotEmpty && result.first['integrity_check'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  // Método para obtener el tamaño de la base de datos
  Future<int> getDatabaseSize() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'porcentaje_panadero.db');
      final file = await databaseFactory.databaseExists(path);
      if (file) {
        // En Flutter no tenemos acceso directo al tamaño del archivo
        // Podríamos implementar esto usando platform channels si es necesario
        return 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
