import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'package:porcentaje_panadero/providers/theme_provider.dart'; // Importar ThemeProvider
import 'screens/home_screen.dart';
import 'screens/ingredient_list_screen.dart';
import 'screens/ingredient_form_screen.dart';
import 'screens/recipe_list_screen.dart';
import 'screens/recipe_form_screen.dart';
import 'screens/recipe_detail_screen.dart';
import 'models/ingredient.dart';
import 'models/recipe.dart';
import 'database/database_helper.dart';
import 'services/recipe_service.dart';
import 'services/ingredient_service.dart';
import 'services/baker_percentage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solo inicializar sqflite_ffi en plataformas de escritorio (no web)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Solo inicializar la base de datos en plataformas que la soporten
    await DatabaseHelper().deleteDatabase();
    await DatabaseHelper().database;
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<RecipeService>(create: (_) => RecipeService()),
        Provider<IngredientService>(create: (_) => IngredientService()),
        Provider<BakerPercentageService>(
          create: (_) => BakerPercentageService(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ), // Añadir ThemeProvider
      ],
      child: const PorcentajePanaderoApp(),
    ),
  );
}

class PorcentajePanaderoApp extends StatelessWidget {
  const PorcentajePanaderoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(
      context,
    ); // Acceder al ThemeProvider

    return MaterialApp(
      title: 'Porcentaje Panadero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B4513), // Saddle Brown - más elegante
          primary: const Color(0xFF6B3410), // Chocolate oscuro
          secondary: const Color(0xFFD2691E), // Chocolate claro
          tertiary: const Color(0xFFF4A460), // Sandy Brown - acento cálido
          surface: const Color(0xFFFFFBF5), // Crema muy suave
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF2C1810), // Marrón muy oscuro para texto
          onSurfaceVariant: const Color(0xFF5D4037), // Marrón medio para iconos
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D4037), // Brown 700
          brightness: Brightness.dark,
          primary: const Color(0xFF8D6E63), // Brown 400 - más suave para tema oscuro
          secondary: const Color(0xFFBCAAA4), // Brown 200
          tertiary: const Color(0xFFFFCC80), // Amber 200 - acento cálido
          surface: const Color(0xFF2E2E2E), // Gris oscuro elegante
          onPrimary: Colors.white,
          onSecondary: const Color(0xFF1C1C1C),
          onSurface: const Color(0xFFE8E3E0), // Beige claro para texto
          onSurfaceVariant: const Color(0xFFBCAAA4), // Brown 200 para iconos
          background: const Color(0xFF1C1C1C), // Fondo principal muy oscuro
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      themeMode: themeProvider.themeMode, // Usar el themeMode del ThemeProvider
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case '/ingredients':
            return MaterialPageRoute(
              builder: (context) => const IngredientListScreen(),
            );
          case '/ingredient/add':
            return MaterialPageRoute(
              builder: (context) => const IngredientFormScreen(),
            );
          case '/ingredient/edit':
            final ingredient = settings.arguments as Ingredient;
            return MaterialPageRoute(
              builder:
                  (context) => IngredientFormScreen(ingredient: ingredient),
            );
          case '/recipes':
            return MaterialPageRoute(
              builder: (context) => const RecipeListScreen(),
            );
          case '/recipe/add':
            return MaterialPageRoute(
              builder: (context) => const RecipeFormScreen(),
            );
          case '/recipe/edit':
            final recipeId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => RecipeFormScreen(recipeId: recipeId),
            );
          case '/recipe/detail':
            final recipe = settings.arguments as Recipe;
            return MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
            );
          default:
            return MaterialPageRoute(builder: (context) => const HomeScreen());
        }
      },
    );
  }
}
