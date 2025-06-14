import 'package:flutter_test/flutter_test.dart';

import 'package:porcentaje_panadero/main.dart';

void main() {
  testWidgets('App starts with home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PorcentajePanaderoApp());

    // Verify that our app title is displayed
    expect(find.text('Porcentaje Panadero'), findsOneWidget);
    
    // Verify that we have the welcome message
    expect(find.text('¡Bienvenido!'), findsOneWidget);
    
    // Verify that we have the main action cards
    expect(find.text('Nueva Receta'), findsOneWidget);
    expect(find.text('Nuevo Ingrediente'), findsOneWidget);
    expect(find.text('Calculadora'), findsOneWidget);
    
    // Verify that we have the recent activity section
    expect(find.text('Explorar Recetas'), findsOneWidget);
    expect(find.text('Ver Alacena'), findsOneWidget);
  });
}
