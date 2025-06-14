import 'package:flutter/foundation.dart'; // Para debugPrint
import '../models/recipe_ingredient.dart';
import '../models/ingredient.dart'; // Necesario para IngredientCategory

/// Servicio para cálculos de porcentaje panadero
class BakerPercentageService {
  /// Convierte la cantidad de un RecipeIngredient a gramos.
  /// Utiliza el factor de conversión del ingrediente si está disponible.
  /// Para líquidos (categoría IngredientCategory.liquid) sin factor de conversión específico
  /// y en unidades de volumen (ml, litros), asume una densidad de 1.0 g/ml (o 1000 g/l).
  double _convertToGrams(RecipeIngredient recipeIngredient) {
    final ingredient = recipeIngredient.ingredient;
    if (ingredient == null) {
      debugPrint(
        'Advertencia: Ingrediente nulo para ${recipeIngredient.id}. No se puede convertir a gramos.',
      );
      return 0.0;
    }

    // Si la unidad de la receta ya es gramos, no se necesita conversión adicional.
    if (recipeIngredient.unit == MeasurementUnit.grams) {
      debugPrint(
        'Ingrediente ${ingredient.name} ya está en gramos: ${recipeIngredient.quantity} g.',
      );
      return recipeIngredient.quantity;
    }

    // Si el ingrediente tiene un factor de conversión manual a gramos, úsalo.
    // Este factor se aplica a la cantidad de la receta, independientemente de su unidad,
    // asumiendo que el factor de conversión ya considera la unidad de la receta.
    if (ingredient.conversionFactorToGrams != null) {
      double quantityInGrams =
          recipeIngredient.quantity * ingredient.conversionFactorToGrams!;
      debugPrint(
        'Convertido ${recipeIngredient.quantity} ${recipeIngredient.unit.label} de ${ingredient.name} a $quantityInGrams g usando factor de conversión: ${ingredient.conversionFactorToGrams}.',
      );
      return quantityInGrams;
    }

    // Si no hay factor de conversión manual y la unidad no es gramos, usa la lógica de unidades predefinida.
    double quantityInGrams = 0.0;
    switch (recipeIngredient.unit) {
      case MeasurementUnit.kilograms:
        quantityInGrams = recipeIngredient.quantity * 1000;
        debugPrint(
          'Convertido ${recipeIngredient.quantity} kg de ${ingredient.name} a $quantityInGrams g.',
        );
        break;
      case MeasurementUnit.milliliters:
        if (ingredient.category == IngredientCategory.liquid) {
          quantityInGrams =
              recipeIngredient.quantity * 1.0; // Asume densidad de 1.0 g/ml
          debugPrint(
            'Convertido ${recipeIngredient.quantity} ml de ${ingredient.name} a $quantityInGrams g (líquido, densidad 1.0).',
          );
        } else {
          debugPrint(
            'Advertencia: Ingrediente ${ingredient.name} en ml pero no es líquido y sin factor de conversión. No se puede convertir a gramos.',
          );
          quantityInGrams = 0.0;
        }
        break;
      case MeasurementUnit.liters:
        if (ingredient.category == IngredientCategory.liquid) {
          quantityInGrams =
              recipeIngredient.quantity * 1000.0; // Asume densidad de 1.0 g/ml
          debugPrint(
            'Convertido ${recipeIngredient.quantity} L de ${ingredient.name} a $quantityInGrams g (líquido, densidad 1.0).',
          );
        } else {
          debugPrint(
            'Advertencia: Ingrediente ${ingredient.name} en litros pero no es líquido y sin factor de conversión. No se puede convertir a gramos.',
          );
          quantityInGrams = 0.0;
        }
        break;
      case MeasurementUnit.pieces:
      case MeasurementUnit.tablespoons:
      case MeasurementUnit.teaspoons:
      case MeasurementUnit.cups:
        debugPrint(
          'Advertencia: Ingrediente ${ingredient.name} con unidad ${recipeIngredient.unit} no se puede convertir a gramos sin factor de conversión manual.',
        );
        quantityInGrams = 0.0;
        break;
      case MeasurementUnit
          .grams: // Ya manejado arriba, pero incluido para exhaustividad
        quantityInGrams = recipeIngredient.quantity;
        break;
    }
    return quantityInGrams;
  }

  /// Calcula los porcentajes panaderos de una lista de ingredientes de receta.
  /// Retorna una nueva lista de RecipeIngredient con las cantidades escaladas.
  List<RecipeIngredient> scaleRecipe(
    List<RecipeIngredient> ingredients,
    double scaleFactor,
  ) {
    return ingredients.map((ri) {
      return ri.copyWith(
        quantity: ri.quantity * scaleFactor,
        bakerPercentage:
            ri.bakerPercentage, // El porcentaje panadero no cambia al escalar
      );
    }).toList();
  }

  /// Calcula los porcentajes panaderos de una lista de ingredientes.
  /// Retorna una nueva lista de RecipeIngredient con los porcentajes actualizados.
  /// La "harina" se considera el 100%. Si no hay harinas, los porcentajes serán 0.
  List<RecipeIngredient> calculateBakerPercentages(
    List<RecipeIngredient> ingredients,
  ) {
    debugPrint('--- calculateBakerPercentages: Ingredientes de entrada ---');
    for (var ri in ingredients) {
      debugPrint(
        '  ${ri.ingredient?.name ?? 'N/A'}: ${ri.quantity} ${ri.unit}',
      );
    }

    final List<RecipeIngredient> updatedIngredients = [];

    // 1. Consolidación de Cantidades de Harinas (en gramos)
    double totalFlourWeightInGrams = 0.0;

    for (final recipeIngredient in ingredients) {
      final ingredient = recipeIngredient.ingredient;
      if (ingredient != null &&
          ingredient.category == IngredientCategory.flour) {
        totalFlourWeightInGrams += _convertToGrams(recipeIngredient);
      }
    }

    debugPrint(
      'Total de Harina Consolidada (en gramos): $totalFlourWeightInGrams',
    );

    // Manejar el caso donde no hay harinas
    if (totalFlourWeightInGrams <= 0) {
      for (final ingredient in ingredients) {
        updatedIngredients.add(ingredient.copyWith(bakerPercentage: 0.0));
      }
      return updatedIngredients;
    }

    // 2. Ajuste de Porcentajes para Harinas y Otros Ingredientes
    for (final recipeIngredient in ingredients) {
      final quantityInGrams = _convertToGrams(recipeIngredient);
      double percentage = (quantityInGrams / totalFlourWeightInGrams) * 100;
      updatedIngredients.add(
        recipeIngredient.copyWith(
          bakerPercentage:
              percentage, // Asignar directamente el double sin parsear de String
        ),
      );
    }

    debugPrint('--- Porcentajes calculados ---');
    for (var ri in updatedIngredients) {
      debugPrint(
        '  ${ri.ingredient?.name ?? 'N/A'}: ${ri.bakerPercentage?.toStringAsFixed(2) ?? 'N/A'}%',
      );
    }

    return updatedIngredients;
  }

  /// Calcula la hidratación total de la receta.
  /// Solo considera ingredientes marcados con `contributesToHydration = true`
  /// y unidades compatibles (ml o gramos).
  /// La hidratación se calcula como (suma_ingredientes_hidratantes / totalFlourWeight) * 100.
  double calculateTotalHydration(List<RecipeIngredient> ingredients) {
    debugPrint('--- calculateTotalHydration: Ingredientes de entrada ---');
    for (var ri in ingredients) {
      debugPrint(
        '  ${ri.ingredient?.name ?? 'N/A'}: ${ri.quantity} ${ri.unit}, Contribuye a hidratación: ${ri.contributesToHydration}',
      );
    }

    // 1. Consolidación de Cantidades de Harinas (en gramos)
    double totalFlourWeightInGrams = 0.0;
    for (final recipeIngredient in ingredients) {
      final ingredient = recipeIngredient.ingredient;
      if (ingredient != null &&
          ingredient.category == IngredientCategory.flour) {
        totalFlourWeightInGrams += _convertToGrams(recipeIngredient);
      }
    }

    debugPrint(
      'Total de Harina para Hidratación (en gramos): $totalFlourWeightInGrams',
    );

    // Manejar el caso donde no hay harinas para evitar división por cero
    if (totalFlourWeightInGrams <= 0) {
      debugPrint(
        'No hay harinas para calcular la hidratación. Retornando 0.0.',
      );
      return 0.0;
    }

    // 2. Sumar cantidades de ingredientes que contribuyen a la hidratación (en gramos)
    double totalHydrationWeightInGrams = 0.0;
    for (final recipeIngredient in ingredients) {
      if (recipeIngredient.contributesToHydration) {
        totalHydrationWeightInGrams += _convertToGrams(recipeIngredient);
      }
    }

    debugPrint(
      'Total de Ingredientes Hidratantes (en gramos): $totalHydrationWeightInGrams',
    );

    // 3. Calcular la hidratación total
    final double totalHydration =
        (totalHydrationWeightInGrams / totalFlourWeightInGrams) * 100;
    debugPrint('Hidratación Total Calculada: $totalHydration%');

    // Retornar la hidratación total con un redondeo para evitar imprecisiones de punto flotante
    return double.parse(totalHydration.toStringAsFixed(6));
  }

  /// Calcula el peso total de la masa sumando las cantidades en gramos de todos los ingredientes.
  double calculateTotalDoughWeight(List<RecipeIngredient> ingredients) {
    double totalDoughWeight = 0.0;
    for (final recipeIngredient in ingredients) {
      totalDoughWeight += _convertToGrams(recipeIngredient);
    }
    // Retornar el peso total de la masa con un redondeo para evitar imprecisiones de punto flotante
    return double.parse(totalDoughWeight.toStringAsFixed(6));
  }

  /// Recalcula las cantidades de todos los ingredientes en una receta
  /// basándose en la nueva cantidad de un ingrediente específico.
  /// Asume que existe al menos una harina (IngredientCategory.flour) que actúa como el 100%.
  /// Si el ingrediente modificado es una harina, su nueva cantidad se convierte en la nueva base del 100%.
  /// Si no es harina, la cantidad de la harina base se ajusta para mantener
  /// la proporción original del ingrediente modificado.
  List<RecipeIngredient> recalculateRecipeBasedOnEditedIngredient(
    List<RecipeIngredient> currentIngredients,
    String editedRecipeIngredientId,
    double newQuantityInGramsForEditedIngredient,
  ) {
    if (currentIngredients.isEmpty) {
      return [];
    }

    final List<RecipeIngredient> workingIngredients =
        currentIngredients.map((ri) => ri.copyWith()).toList();

    // 1. Identificar la harina base (la primera que se encuentre)
    RecipeIngredient? mainFlourIngredient;
    for (var ri in workingIngredients) {
      if (ri.ingredient?.category == IngredientCategory.flour) {
        mainFlourIngredient = ri;
        break; // Asume la primera harina como la principal para el 100%
      }
    }

    if (mainFlourIngredient == null) {
      debugPrint(
        'Error: No se encontró un ingrediente de harina para calcular porcentajes.',
      );
      return currentIngredients; // No se puede recalcular sin una base de harina
    }

    // 2. Encontrar el ingrediente que fue editado
    RecipeIngredient? editedIngredient = workingIngredients.firstWhere(
      (ri) => ri.id == editedRecipeIngredientId,
      orElse:
          () =>
              throw Exception("Ingrediente editado no encontrado en la lista."),
    );

    double newReferenceFlourWeight;

    if (editedIngredient.ingredient?.category == IngredientCategory.flour) {
      // Caso 1: Se editó una harina. La nueva cantidad de esta harina es la nueva referencia de 100%.
      newReferenceFlourWeight = newQuantityInGramsForEditedIngredient;
    } else {
      // Caso 2: Se editó un ingrediente que NO es harina.
      // Queremos que el porcentaje panadero de este ingrediente se mantenga con su nueva cantidad.
      // Calculamos la nueva harina de referencia en base a eso.
      if (editedIngredient.bakerPercentage == null ||
          editedIngredient.bakerPercentage! <= 0) {
        debugPrint(
          'Advertencia: Porcentaje panadero del ingrediente editado es cero o nulo. No se puede inferir nueva harina base.',
        );
        return currentIngredients; // No se puede recalcular
      }
      newReferenceFlourWeight =
          newQuantityInGramsForEditedIngredient /
          (editedIngredient.bakerPercentage! / 100.0);
    }

    // Asegurar que la nueva harina de referencia sea positiva
    if (newReferenceFlourWeight <= 0) {
      debugPrint(
        'Advertencia: La nueva cantidad de harina de referencia es cero o negativa.',
      );
      return currentIngredients;
    }

    // 3. Crear una nueva lista de ingredientes recalculados
    final List<RecipeIngredient> recalculatedIngredients = [];
    for (final ri in workingIngredients) {
      double calculatedQuantity;

      if (ri.ingredient?.category == IngredientCategory.flour) {
        // Para la harina principal, establecer su nueva cantidad directamente
        if (ri.id == mainFlourIngredient.id) {
          calculatedQuantity = newReferenceFlourWeight;
        } else {
          // Si hay otras harinas, escalarlas proporcionalmente a la harina principal
          calculatedQuantity =
              (ri.bakerPercentage! / 100.0) * newReferenceFlourWeight;
        }
      } else {
        // Para los ingredientes no harinas, escalarlos por su porcentaje panadero
        calculatedQuantity =
            (ri.bakerPercentage! / 100.0) * newReferenceFlourWeight;
      }

      // Asegurarse de que el ingrediente editado tenga exactamente la nueva cantidad deseada
      if (ri.id == editedRecipeIngredientId) {
        calculatedQuantity = newQuantityInGramsForEditedIngredient;
      }

      recalculatedIngredients.add(ri.copyWith(quantity: calculatedQuantity));
    }

    // 4. Recalcular todos los porcentajes panaderos con la nueva base de harina
    return calculateBakerPercentages(recalculatedIngredients);
  }

  /// Recalcula las cantidades de todos los ingredientes de la receta
  /// basándose en un nuevo peso total de la masa deseado.
  /// Las proporciones (porcentajes panaderos) se mantienen.
  List<RecipeIngredient> recalculateRecipeBasedOnTotalDoughWeight(
    List<RecipeIngredient> currentIngredients,
    double newTotalDoughWeightInGrams,
  ) {
    if (currentIngredients.isEmpty) {
      return [];
    }

    if (newTotalDoughWeightInGrams <= 0) {
      // Si el peso total objetivo es 0 o negativo, todas las cantidades de los ingredientes deben ser 0.
      return currentIngredients
          .map((ri) => ri.copyWith(quantity: 0.0, bakerPercentage: 0.0))
          .toList();
    }

    final double currentTotalDoughWeight = calculateTotalDoughWeight(
      currentIngredients,
    );
    if (currentTotalDoughWeight <= 0) {
      debugPrint(
        'Advertencia: El peso total actual de la masa es cero o negativo. No se puede escalar.',
      );
      // Si el peso total actual es 0 (o negativo) y el nuevo peso total es positivo,
      // no se puede escalar proporcionalmente. Establecer todas las cantidades a 0.0.
      return currentIngredients
          .map((ri) => ri.copyWith(quantity: 0.0, bakerPercentage: 0.0))
          .toList();
    }

    final double scaleFactor =
        newTotalDoughWeightInGrams / currentTotalDoughWeight;

    final List<RecipeIngredient> recalculatedIngredients = [];
    for (final ri in currentIngredients) {
      recalculatedIngredients.add(
        ri.copyWith(quantity: ri.quantity * scaleFactor),
      );
    }

    // Recalcular porcentajes panaderos después de escalar
    return calculateBakerPercentages(recalculatedIngredients);
  }
}
