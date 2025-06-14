# Contexto Técnico - Porcentaje Panadero

## Stack Tecnológico

### Framework Principal
- **Flutter 3.x**: Framework multiplataforma para desarrollo móvil, web y desktop
- **Dart**: Lenguaje de programación principal

### Arquitectura de la Aplicación
- **Patrón MVVM**: Model-View-ViewModel para separación de responsabilidades
- **Provider**: Gestión de estado reactivo y simple, utilizado para inyección de dependencias de servicios.
- **Dependency Injection**: GetIt para inyección de dependencias (aunque Provider se usa para servicios).

### Base de Datos Local
- **SQLite**: Base de datos embebida para almacenamiento local, utilizada directamente con `sqflite`.
- **Migraciones**: Sistema de versionado de base de datos implementado manualmente en `DatabaseHelper`.

### Gestión de Estado
- **Provider Pattern**: Utilizado para inyección de dependencias de servicios (RecipeService, IngredientService, BakerPercentageService) a nivel de la aplicación.
- **ChangeNotifier**: Para notificaciones de cambios en modelos (si se implementa estado reactivo a nivel de modelo).
- **Consumer/Selector**: Para reconstrucción eficiente de widgets (si se implementa estado reactivo a nivel de modelo).
- **ThemeProvider**: Un `ChangeNotifierProvider` global para la gestión del tema claro/oscuro, ubicado en `lib/providers/theme_provider.dart`.

## Dependencias Principales

### Core
```yaml
flutter:
  sdk: flutter
cupertino_icons: ^1.0.2
```

### Estado y Arquitectura
```yaml
provider: ^6.1.1
get_it: ^7.6.4
```

### Base de Datos
```yaml
sqlite3_flutter_libs: ^0.5.18
path_provider: ^2.1.1
path: ^1.8.3
sqflite: ^2.3.0 # Añadido explícitamente para SQLite directo
```

### UI/UX
```yaml
flutter_localizations:
  sdk: flutter
intl: ^0.18.1
```

### Desarrollo
```yaml
flutter_lints: ^3.0.1
# drift_dev y build_runner no son necesarios si no se usa Drift
```

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── app.dart                  # Configuración de la app
├── core/                     # Funcionalidades core
│   ├── database/            # Configuración de BD
│   ├── di/                  # Dependency Injection
│   ├── constants/           # Constantes globales
│   └── utils/               # Utilidades
├── features/                # Funcionalidades por módulo
│   ├── recipes/            # Gestión de recetas
│   ├── ingredients/        # Gestión de ingredientes
│   ├── calculator/         # Calculadora panadero
│   └── pantry/             # Alacena
├── shared/                  # Componentes compartidos
│   ├── widgets/            # Widgets reutilizables
│   ├── models/             # Modelos de datos
│   └── services/           # Servicios compartidos
└── l10n/                   # Localización
```

## Modelos de Datos Principales

### Ingredient (Ingrediente)
- id, name, type, unit, cost_per_unit, protein_content

### Recipe (Receta) 
- id, name, description, category, total_flour_weight, yield_count

### RecipeIngredient (Ingrediente en Receta)
- recipe_id, ingredient_id, percentage, weight_grams

### PantryItem (Item de Alacena)
- ingredient_id, current_stock, expiry_date, supplier

## Configuración de Desarrollo

### Build Tools
- **build_runner**: Para generación de código (Drift, JSON serialization)
- **Flutter Analyze**: Análisis estático de código
- **Flutter Test**: Testing unitario y de widgets

### Plataformas de Desarrollo
- **Android Studio / VS Code**: IDEs principales
- **Windows**: Plataforma principal de desarrollo y testing para `flutter run`
- **Android SDK**: Para compilación Android
- **Xcode**: Para compilación iOS (en macOS)

### Configuración de Base de Datos
- **Migraciones manuales**: Manejadas en `DatabaseHelper` a través de `onUpgrade`.
- **Validaciones**: Constraints a nivel de base de datos y validaciones en modelos/servicios.
- **Índices**: Para optimizar consultas frecuentes.

## Consideraciones de Rendimiento
- **Lazy Loading**: Carga bajo demanda de recetas e ingredientes
- **Debounce**: En búsquedas y cálculos en tiempo real
- **Caching**: Resultado de cálculos complejos
- **Optimización de Imágenes**: Para fotos de recetas futuras

## Preparación para Backend Futuro
- **Modelos Serializables**: JSON serialization preparada
- **Repository Pattern**: Abstracción para futuro switch a API
- **Offline First**: Funcionalidad completa sin conexión
- **Sincronización**: Estructura preparada para Appwrite integration

## Sistema de Diseño
- Para detalles sobre la paleta de colores, tipografía y estilos de componentes, consultar `memory-bank/design_system.md`.
