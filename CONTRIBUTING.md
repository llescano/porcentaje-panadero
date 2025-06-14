# Guía de Contribución

¡Gracias por tu interés en contribuir a la Calculadora de Porcentaje Panadero! 🍞

## 🚀 Cómo Contribuir

### 1. Configuración del Entorno
1. Fork el repositorio
2. Clona tu fork localmente:
   ```bash
   git clone https://github.com/tu-usuario/porcentaje-panadero.git
   ```
3. Instala las dependencias:
   ```bash
   flutter pub get
   ```
4. Verifica que todo funcione:
   ```bash
   flutter run
   ```

### 2. Tipos de Contribuciones Bienvenidas

#### 🐛 Reportes de Bugs
- Usa la plantilla de issue para bugs
- Incluye pasos detallados para reproducir
- Especifica versión de Flutter y dispositivo
- Adjunta screenshots si es relevante

#### ✨ Nuevas Características
- Discute la idea primero en un issue
- Sigue los patrones de arquitectura existentes
- Incluye tests para nuevas funcionalidades
- Actualiza la documentación correspondiente

#### 📚 Mejoras de Documentación
- Corrige errores tipográficos
- Mejora explicaciones existentes
- Traduce contenido
- Agrega ejemplos de uso

#### 🔧 Refactoring y Optimizaciones
- Mejora el rendimiento
- Simplifica código complejo
- Actualiza dependencias
- Mejora la accesibilidad

### 3. Proceso de Desarrollo

#### Flujo de Trabajo
1. **Crea un issue** (si no existe) describiendo el problema/mejora
2. **Asígnate el issue** para evitar trabajo duplicado
3. **Crea una rama** desde `main`:
   ```bash
   git checkout -b feature/nombre-descriptivo
   git checkout -b bugfix/descripcion-del-bug
   git checkout -b docs/mejora-documentacion
   ```
4. **Desarrolla** siguiendo las convenciones del proyecto
5. **Haz commits** descriptivos y frecuentes
6. **Testea** tu código exhaustivamente
7. **Abre un Pull Request** con descripción detallada

#### Convenciones de Código

##### Estilo Dart/Flutter
```dart
// ✅ Bueno
class RecipeService {
  Future<List<Recipe>> getAllRecipes() async {
    // Implementación clara y comentada
  }
}

// ❌ Evitar
class recipe_service {
  get_all_recipes() {
    // Sin tipos, sin documentación
  }
}
```

##### Estructura de Archivos
- Un widget/clase por archivo
- Nombres de archivo en snake_case
- Imports organizados (dart: -> flutter: -> packages: -> local)

##### Documentación de Código
```dart
/// Servicio para gestionar operaciones de recetas.
/// 
/// Proporciona métodos para CRUD de recetas y cálculos
/// de porcentajes panaderos.
class RecipeService {
  /// Obtiene todas las recetas de la base de datos.
  /// 
  /// Retorna una lista vacía si no hay recetas.
  Future<List<Recipe>> getAllRecipes() async {
    // Implementación...
  }
}
```

### 4. Testing

#### Tests Requeridos
- **Unit tests** para servicios y lógica de negocio
- **Widget tests** para componentes de UI
- **Integration tests** para flujos completos

#### Ejecutar Tests
```bash
# Tests unitarios
flutter test

# Tests de integración
flutter drive --target=test_driver/app.dart
```

#### Cobertura de Tests
- Mantener >80% de cobertura
- Tests obligatorios para nuevas features
- Verificar que tests existentes sigan pasando

### 5. Pull Request Guidelines

#### Antes de Abrir el PR
- [ ] Código sigue las convenciones establecidas
- [ ] Todos los tests pasan
- [ ] No hay warnings de `flutter analyze`
- [ ] Documentación actualizada si es necesario
- [ ] Commits son claros y atómicos

#### Descripción del PR
```markdown
## 📝 Descripción
Breve descripción de los cambios realizados.

## 🔗 Issue Relacionado
Fixes #[número-del-issue]

## 🧪 Testing
- [ ] Tests unitarios agregados/actualizados
- [ ] Tests manuales realizados
- [ ] Verificado en Android/iOS

## 📱 Screenshots
[Si aplica, incluir screenshots de cambios visuales]

## ✅ Checklist
- [ ] Código revisado por mí mismo
- [ ] Sin conflicts con main
- [ ] Documentación actualizada
```

### 6. Estructura del Proyecto

#### Arquitectura
- **Models**: Entidades de datos
- **Services**: Lógica de negocio
- **Database**: Acceso a datos
- **Screens**: Pantallas de la aplicación
- **Widgets**: Componentes reutilizables

#### Patrones a Seguir
- Service Layer Pattern
- Repository Pattern
- Single Responsibility
- DRY (Don't Repeat Yourself)

### 7. Issues y Bugs

#### Reportar un Bug
1. Busca si ya existe un issue similar
2. Usa la plantilla de bug report
3. Incluye información completa:
   - Versión de la app
   - Versión de Flutter
   - Dispositivo/OS
   - Pasos para reproducir
   - Comportamiento esperado vs actual

#### Solicitar una Feature
1. Verifica que no esté en el roadmap
2. Describe el problema que resuelve
3. Propón una solución si tienes ideas
4. Considera el impacto en usuarios existentes

### 8. Código de Conducta

#### Nuestros Valores
- **Respeto**: Trata a todos con cortesía
- **Inclusión**: Acoge diferentes perspectivas
- **Colaboración**: Ayuda a otros a crecer
- **Calidad**: Busca la excelencia técnica

#### Comportamientos Esperados
- Comunicación constructiva en reviews
- Paciencia con desarrolladores novatos
- Feedback específico y accionable
- Reconocimiento del trabajo de otros

### 9. Recursos Útiles

#### Documentación
- [Flutter Docs](https://docs.flutter.dev/)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Material Design](https://m3.material.io/)

#### Herramientas
- [Flutter Inspector](https://docs.flutter.dev/development/tools/flutter-inspector)
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
- [VS Code Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)

---

## 🙏 Reconocimientos

Agradecemos a todos los contribuidores que hacen posible este proyecto. Cada aporte, por pequeño que sea, es valioso para la comunidad.

### Contribuidores Actuales
- Creador del proyecto: [@tu-usuario]
- [Lista se actualizará con contribuciones]

---

¿Tienes preguntas? ¡Abre un [Discussion](https://github.com/tu-usuario/porcentaje-panadero/discussions) o un issue!
