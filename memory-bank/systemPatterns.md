# Patrones del Sistema - Porcentaje Panadero

## Arquitectura General

### Patrón MVVM (Model-View-ViewModel)
```
View (Widgets) ↔ ViewModel (Providers) ↔ Model (Entities + Services)
```

**Responsabilidades:**
- **View**: Presentación UI, eventos de usuario
- **ViewModel**: Lógica de presentación, gestión de estado
- **Model**: Datos, lógica de negocio, persistencia

### Repository Pattern
Abstracción entre ViewModels y fuentes de datos:

```
ViewModel → Repository Interface → Implementación (Local/Remote)
```

**Beneficios:**
- Fácil testing con mocks
- Preparación para backend futuro
- Separación clara de responsabilidades

## Gestión de Estado

### Provider Pattern
```dart
// Proveedor de estado global
class RecipeProvider extends ChangeNotifier {
  List<Recipe> _recipes = [];
  
  void addRecipe(Recipe recipe) {
    _recipes.add(recipe);
    notifyListeners();
  }
}

// Uso en Widget
Consumer<RecipeProvider>(
  builder: (context, provider, child) {
    return ListView.builder(
      itemCount: provider.recipes.length,
      itemBuilder: (context, index) => RecipeCard(provider.recipes[index]),
    );
  },
)
```

### Dependency Injection con GetIt
```dart
// Registro de servicios
void setupServiceLocator() {
  GetIt.instance.registerLazySingleton(() => DatabaseService());
  GetIt.instance.registerLazySingleton(() => RecipeRepository());
  GetIt.instance.registerFactory(() => RecipeProvider());
}
```

## Arquitectura de Base de Datos

### Tablas Principales
```sql
-- Ingredientes base
CREATE TABLE ingredients (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'flour', 'liquid', 'fat', 'salt', etc.
    unit TEXT NOT NULL, -- 'grams', 'ml', 'units'
    protein_content REAL,
    cost_per_unit REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Recetas
CREATE TABLE recipes (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    total_flour_weight REAL NOT NULL,
    yield_count INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Ingredientes en recetas (relación N:M)
CREATE TABLE recipe_ingredients (
    id INTEGER PRIMARY KEY,
    recipe_id INTEGER NOT NULL,
    ingredient_id INTEGER NOT NULL,
    percentage REAL NOT NULL,
    weight_grams REAL GENERATED ALWAYS AS (
        (SELECT total_flour_weight FROM recipes WHERE id = recipe_id) * percentage / 100
    ),
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id),
    UNIQUE(recipe_id, ingredient_id)
);

-- Alacena
CREATE TABLE pantry_items (
    id INTEGER PRIMARY KEY,
    ingredient_id INTEGER NOT NULL,
    current_stock REAL NOT NULL,
    expiry_date DATE,
    supplier TEXT,
    purchase_price REAL,
    purchase_date DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
);
```

### Índices para Rendimiento
```sql
CREATE INDEX idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);
CREATE INDEX idx_pantry_items_ingredient_id ON pantry_items(ingredient_id);
CREATE INDEX idx_recipes_category ON recipes(category);
```

## Patrones de Cálculo

### Calculadora de Porcentaje Panadero
```dart
class BakerPercentageCalculator {
  // Calcula pesos basado en porcentajes y peso total de harina
  Map<String, double> calculateWeights({
    required Map<String, double> percentages,
    required double totalFlourWeight,
  }) {
    final weights = <String, double>{};
    
    for (final entry in percentages.entries) {
      weights[entry.key] = (totalFlourWeight * entry.value) / 100;
    }
    
    return weights;
  }
  
  // Calcula porcentajes basado en pesos
  Map<String, double> calculatePercentages({
    required Map<String, double> weights,
    required double flourWeight,
  }) {
    final percentages = <String, double>{};
    
    for (final entry in weights.entries) {
      percentages[entry.key] = (entry.value / flourWeight) * 100;
    }
    
    return percentages;
  }
  
  // Escala una receta a nuevo peso total
  Recipe scaleRecipe(Recipe original, double newFlourWeight) {
    final scaleFactor = newFlourWeight / original.totalFlourWeight;
    
    return original.copyWith(
      totalFlourWeight: newFlourWeight,
      ingredients: original.ingredients.map((ingredient) {
        return ingredient.copyWith(
          weightGrams: ingredient.weightGrams * scaleFactor,
        );
      }).toList(),
    );
  }
}
```

## Navegación y Routing

### Named Routes Pattern
```dart
class AppRoutes {
  static const String home = '/';
  static const String recipes = '/recipes';
  static const String recipeDetail = '/recipes/:id';
  static const String recipeEdit = '/recipes/:id/edit';
  static const String ingredients = '/ingredients';
  static const String pantry = '/pantry';
  static const String calculator = '/calculator';
}
```

## Validaciones y Errores

### Validation Pattern
```dart
class RecipeValidator {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de la receta es requerido';
    }
    if (value.length > 100) {
      return 'El nombre no puede exceder 100 caracteres';
    }
    return null;
  }
  
  static String? validatePercentage(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    
    final percentage = double.tryParse(value);
    if (percentage == null) {
      return 'Ingrese un número válido';
    }
    if (percentage < 0 || percentage > 1000) {
      return 'El porcentaje debe estar entre 0 y 1000';
    }
    return null;
  }
}
```

## Localización

### L10n Pattern
```dart
// Uso de claves de localización
Text(AppLocalizations.of(context)!.recipeNameLabel)

// Archivo de localización es.arb
{
  "recipeNameLabel": "Nombre de la receta",
  "percentageLabel": "Porcentaje (%)",
  "weightLabel": "Peso (g)",
  "flourPercentageInfo": "La harina siempre es 100%"
}
```

## Testing Patterns

### Arquitectura Testeable
```dart
// Mock repositories para testing
class MockRecipeRepository implements RecipeRepository {
  @override
  Future<List<Recipe>> getAllRecipes() async {
    return [
      Recipe(id: 1, name: 'Pan Básico', totalFlourWeight: 1000),
    ];
  }
}

// Tests de ViewModels
void main() {
  group('RecipeProvider', () {
    late RecipeProvider provider;
    late MockRecipeRepository repository;
    
    setUp(() {
      repository = MockRecipeRepository();
      provider = RecipeProvider(repository);
    });
    
    test('should load recipes on init', () async {
      await provider.loadRecipes();
      expect(provider.recipes.length, 1);
    });
  });
}
```

## Patrones de Performance

### Lazy Loading
- Carga de recetas bajo demanda
- Pagination en listas grandes
- Caching de resultados de cálculos

### Debounce en Búsquedas
```dart
Timer? _debounceTimer;

void onSearchChanged(String query) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 300), () {
    _performSearch(query);
  });
}
