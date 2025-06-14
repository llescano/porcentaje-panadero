import 'package:flutter/material.dart';
import 'dart:io';
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

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await DatabaseHelper().deleteDatabase();
  await DatabaseHelper().database;

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
          seedColor: Colors.brown,
          primary: Colors.brown[700],
          onSurface: Colors.black, // Texto principal sobre fondos claros
          onSurfaceVariant:
              Colors.brown[900]!, // Iconos más oscuros para tema claro
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: Colors.white,
          ), // Mantener blanco para AppBar
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown[800]!,
          brightness: Brightness.dark,
          surface: Colors.blueGrey[900]!, // Fondo de tarjetas más claro
          onSurface: Colors.white, // Texto principal sobre fondos oscuros
          onSurfaceVariant: Colors.brown[300]!, // Iconos
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w500,
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
