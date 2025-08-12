import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'package:porcentaje_panadero/theme/bakery_theme.dart'; // Importar el nuevo tema
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
      title: 'Bakery Warm Calculator', // Título actualizado
      debugShowCheckedModeBanner: false,
      theme: BakeryTheme.lightTheme, // Usar el nuevo tema
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
