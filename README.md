# Calculadora de Porcentaje Panadero

Una aplicación Flutter para calcular y gestionar recetas de panadería utilizando el método de porcentaje panadero, donde la harina representa el 100% y todos los demás ingredientes se calculan como porcentajes relativos.

## 🎯 Características Principales

### ✅ Gestión de Ingredientes
- **Lista completa de ingredientes** con navegación fluida
- **Creación y edición** de ingredientes personalizados
- **Categorización automática** (Harinas, Líquidos, Grasas, etc.)
- **Validación de datos** para mantener consistencia
- **Eliminación segura** con confirmación

### ✅ Gestión de Recetas
- **Creación de recetas** con múltiples ingredientes
- **Edición completa** de recetas existentes
- **Visualización detallada** con porcentajes calculados automáticamente
- **Sistema de validación** para ingredientes duplicados
- **Eliminación controlada** con confirmación

### ✅ Calculadora de Porcentajes Panaderos
- **Cálculo automático** de porcentajes basado en harina (100%)
- **Escalado de recetas** - ajustar cantidades manteniendo proporciones
- **Cálculo por peso final** deseado
- **Interfaz intuitiva** con campos de entrada claros
- **Resultados precisos** con decimales apropiados

### ✅ Navegación y UX
- **Drawer de navegación** consistente en toda la app
- **Interfaz Material Design** moderna y limpia
- **Transiciones fluidas** entre pantallas
- **Feedback visual** para todas las acciones
- **Manejo de estados** robusto

## 🏗️ Arquitectura Técnica

### Estructura del Proyecto
```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── models/                   # Modelos de datos
│   ├── ingredient.dart       # Modelo de ingrediente
│   ├── recipe.dart          # Modelo de receta
│   └── recipe_ingredient.dart # Relación receta-ingrediente
├── database/
│   └── database_helper.dart  # Gestión de SQLite
├── services/                 # Lógica de negocio
│   ├── ingredient_service.dart
│   ├── recipe_service.dart
│   └── baker_percentage_service.dart
├── screens/                  # Pantallas de la aplicación
│   ├── home_screen.dart
│   ├── ingredient_list_screen.dart
│   ├── ingredient_form_screen.dart
│   ├── ingredient_detail_screen.dart
│   ├── recipe_list_screen.dart
│   ├── recipe_form_screen.dart
│   ├── recipe_detail_screen.dart
│   └── recipe_calculator_screen.dart
└── widgets/
    └── navigation_drawer.dart
```

### Tecnologías Utilizadas
- **Flutter SDK**: Framework de desarrollo multiplataforma
- **Dart**: Lenguaje de programación
- **SQLite**: Base de datos local via `sqflite`
- **Material Design**: Sistema de diseño de Google

### Patrones Implementados
- **Service Layer Pattern**: Separación de lógica de negocio
- **Repository Pattern**: Abstracción de acceso a datos
- **Model-View Pattern**: Separación clara de responsabilidades
- **Singleton Pattern**: Para manejo de base de datos

## 🚀 Instalación y Configuración

### Prerrequisitos
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- Emulador Android o iOS

### Pasos de Instalación
1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/porcentaje-panadero.git
   cd porcentaje-panadero
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Verificar configuración**
   ```bash
   flutter doctor
   ```

4. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 📱 Uso de la Aplicación

### 1. Gestión de Ingredientes
- Accede a "Ingredientes" desde el menú principal
- Agrega nuevos ingredientes con nombre y categoría
- Edita o elimina ingredientes existentes
- Visualiza detalles completos de cada ingrediente

### 2. Creación de Recetas
- Ve a "Recetas" y presiona "Agregar Receta"
- Asigna un nombre a tu receta
- Agrega ingredientes uno por uno con sus cantidades
- El sistema calcula automáticamente los porcentajes

### 3. Calculadora de Porcentajes
- Selecciona una receta existente
- Ingresa el peso final deseado o ajusta proporciones
- Obtén las cantidades exactas para tu producción

## 🛠️ Desarrollo y Contribución

### Comandos Útiles
```bash
# Análisis de código
flutter analyze

# Ejecutar tests
flutter test

# Generar APK
flutter build apk

# Generar App Bundle
flutter build appbundle
```

### Estructura de Base de Datos

#### Tabla `ingredients`
```sql
CREATE TABLE ingredients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL
);
```

#### Tabla `recipes`
```sql
CREATE TABLE recipes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);
```

#### Tabla `recipe_ingredients`
```sql
CREATE TABLE recipe_ingredients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  recipe_id INTEGER NOT NULL,
  ingredient_id INTEGER NOT NULL,
  quantity REAL NOT NULL,
  UNIQUE(recipe_id, ingredient_id)
);
```

## 🎯 Roadmap

### 🔄 Próximas Mejoras (v2.0)
- [ ] **Importación/Exportación** de recetas (JSON/CSV)
- [ ] **Calculadora de costos** por receta
- [ ] **Historial de producciones** con seguimiento
- [ ] **Sistema de favoritos** para recetas
- [ ] **Búsqueda y filtros** avanzados
- [ ] **Temas personalizables** (modo oscuro)
- [ ] **Sincronización en la nube** (opcional)

### 🚀 Características Avanzadas (v3.0)
- [ ] **Gestión de proveedores** y precios
- [ ] **Calculadora nutricional** básica
- [ ] **Generador de etiquetas** para productos
- [ ] **Sistema de conversión** de unidades
- [ ] **Backup automático** local
- [ ] **Compartir recetas** entre usuarios

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Agrega nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 👥 Autor

Desarrollado con ❤️ para la comunidad panadera.

---

### 📞 Soporte

Si encuentras algún problema o tienes sugerencias, por favor:
- Abre un [Issue](https://github.com/tu-usuario/porcentaje-panadero/issues)
- Describe detalladamente el problema
- Incluye pasos para reproducir errores

### 🙏 Agradecimientos

Gracias a todos los panaderos que inspiraron este proyecto y a la comunidad de Flutter por las excelentes herramientas de desarrollo.
