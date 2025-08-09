# Sistema de Diseño

Este documento detalla el sistema de diseño de la aplicación "Porcentaje Panadero", incluyendo la paleta de colores, tipografía y estilos de componentes para asegurar una experiencia de usuario consistente en ambos temas (claro y oscuro).

## Paleta de Colores

### Tema Claro
- **`primary`**: `Color(0xFF6B3410)` (Chocolate oscuro - color principal elegante y profesional)
- **`secondary`**: `Color(0xFFD2691E)` (Chocolate claro - color secundario cálido)
- **`tertiary`**: `Color(0xFFF4A460)` (Sandy Brown - acento cálido para elementos destacados)
- **`surface`**: `Color(0xFFFFFBF5)` (Crema muy suave - fondo de tarjetas con calidez sutil)
- **`onPrimary`**: `Colors.white` (Blanco sobre elementos primarios)
- **`onSecondary`**: `Colors.white` (Blanco sobre elementos secundarios)
- **`onSurface`**: `Color(0xFF2C1810)` (Marrón muy oscuro para texto principal, excelente legibilidad)
- **`onSurfaceVariant`**: `Color(0xFF5D4037)` (Marrón medio para iconos y elementos secundarios)

### Tema Oscuro
- **`primary`**: `Color(0xFF8D6E63)` (Brown 400 - más suave y elegante para tema oscuro)
- **`secondary`**: `Color(0xFFBCAAA4)` (Brown 200 - secundario suave)
- **`tertiary`**: `Color(0xFFFFCC80)` (Amber 200 - acento cálido que contrasta bien en oscuro)
- **`surface`**: `Color(0xFF2E2E2E)` (Gris oscuro elegante para tarjetas)
- **`background`**: `Color(0xFF1C1C1C)` (Fondo principal muy oscuro y profesional)
- **`onPrimary`**: `Colors.white` (Blanco sobre elementos primarios)
- **`onSecondary`**: `Color(0xFF1C1C1C)` (Oscuro sobre elementos secundarios claros)
- **`onSurface`**: `Color(0xFFE8E3E0)` (Beige claro para texto, suave a la vista)
- **`onSurfaceVariant`**: `Color(0xFFBCAAA4)` (Brown 200 para iconos, mantiene la calidez)

## Tipografía

La tipografía principal utilizada es la predeterminada de Material Design (generalmente Roboto).

- **Títulos de AppBar**: `fontWeight: FontWeight.w600`, `fontSize: 18`, `color: Colors.white`
- **Títulos de Sección (ej. en IngredientDetailScreen)**: `fontSize: 24`, `fontWeight: FontWeight.bold`, `color: Theme.of(context).colorScheme.onSurface`
- **Subtítulos/Categorías**: `fontSize: 16`, `color: Theme.of(context).colorScheme.onSurface`
- **Texto de Descripción**: `fontSize: 14`
- **Etiquetas de Información (ej. en IngredientDetailScreen)**: `fontSize: 12`, `fontWeight: FontWeight.w500`, `color: Theme.of(context).colorScheme.onSurface`
- **Valores de Información (ej. en IngredientDetailScreen)**: `fontSize: 14`, `fontWeight: FontWeight.w500`, `color: Theme.of(context).colorScheme.onSurface`

## Componentes

### AppBar (`CustomAppBar`)
- **Uso**: Barra superior de navegación en la mayoría de las pantallas.
- **Estilo**:
  ```dart
  CustomAppBar(
    title: 'Título de la Pantalla',
    actions: [
      IconButton(
        icon: const Icon(Icons.icon_name),
        onPressed: () {},
      ),
    ],
  )
  ```
- **Colores**: El color de fondo y el color del texto del título se gestionan a través de `appBarTheme` en `main.dart`.

### Tarjetas (`Card`)
- **Uso**: Contenedores para agrupar información relacionada, como detalles de ingredientes o elementos de lista.
- **Estilo**:
  ```dart
  Card(
    margin: const EdgeInsets.only(bottom: 8), // Margen inferior para separación
    color: Theme.of(context).colorScheme.surface, // Fondo de la tarjeta
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        // Contenido de la tarjeta
      ),
    ),
  )
  ```
- **Colores**: El color de fondo de la tarjeta se establece usando `Theme.of(context).colorScheme.surface`.

### List Tiles (`ListTile`)
- **Uso**: Elementos interactivos en listas, como la lista de ingredientes.
- **Estilo**:
  ```dart
  ListTile(
    leading: CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1),
      child: Icon(
        Icons.grain,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
    title: Text(
      'Título del elemento',
      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
    ),
    subtitle: Text(
      'Subtítulo del elemento',
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
    ),
    // ... otros parámetros como trailing, onTap
  )
  ```
- **Colores**:
  - El fondo del `CircleAvatar` usa `Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1)`.
  - El color del `Icon` usa `Theme.of(context).colorScheme.onSurfaceVariant`.
  - El color del `title` y `subtitle` usa `Theme.of(context).colorScheme.onSurface`.

## Guía de Uso

- **Siempre usar colores del `Theme`**: Evitar el uso de colores fijos (`Colors.red`, `Colors.blue`) directamente en los widgets. En su lugar, acceder a los colores definidos en `Theme.of(context).colorScheme` para asegurar que la aplicación se adapte correctamente a los temas claro y oscuro.
- **`CustomAppBar`**: Utilizar el widget `CustomAppBar` en todas las pantallas que requieran una barra de aplicación estándar.
- **Consistencia en `Card` y `ListTile`**: Mantener la estructura y el uso de `colorScheme.surface` para los fondos de `Card` y `ListTile` para una apariencia unificada.
