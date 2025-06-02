import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart'; // Importar provider
import 'screens/home_screen.dart';
import 'screens/ingredient_list_screen.dart';
import 'screens/ingredient_form_screen.dart';
import 'screens/recipe_list_screen.dart';
import 'screens/recipe_form_screen.dart';
import 'screens/recipe_calculator_screen.dart';
import 'screens/recipe_detail_screen.dart';
import 'models/ingredient.dart';
import 'models/recipe.dart';
import 'database/database_helper.dart';
import 'services/recipe_service.dart'; // Importar servicios
import 'services/ingredient_service.dart';
import 'services/baker_percentage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar SQLite para plataformas desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Inicializar la base de datos
  // Para desarrollo, eliminar la base de datos existente para forzar la recreación con el esquema actualizado
  // En producción, se usarían migraciones (onUpgrade)
  await DatabaseHelper().deleteDatabase(); 
  await DatabaseHelper().database;
  
  runApp(
    MultiProvider(
      providers: [
        Provider<RecipeService>(create: (_) => RecipeService()),
        Provider<IngredientService>(create: (_) => IngredientService()),
        Provider<BakerPercentageService>(create: (_) => BakerPercentageService()),
      ],
      child: const PorcentajePanaderoApp(),
    ),
  );
}

class PorcentajePanaderoApp extends StatelessWidget {
  const PorcentajePanaderoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Porcentaje Panadero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            );
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
              builder: (context) => IngredientFormScreen(ingredient: ingredient),
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
            final recipe = settings.arguments as Recipe;
            return MaterialPageRoute(
              builder: (context) => RecipeFormScreen(recipeId: recipe.id),
            );
          case '/recipe/detail':
            final recipe = settings.arguments as Recipe;
            return MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
            );
          case '/recipe/calculator':
            return MaterialPageRoute(
              builder: (context) => const RecipeCalculatorScreen(),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            );
        }
      },
    );
  }
}