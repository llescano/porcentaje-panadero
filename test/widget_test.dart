import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:porcentaje_panadero/main.dart';

void main() {
  testWidgets('App starts with the new Bakery Warm home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We need to wrap it in a MultiProvider if it's not already handled in main.dart's test setup
    // but PorcentajePanaderoApp should be the root.
    await tester.pumpWidget(const PorcentajePanaderoApp());

    // Verify the new AppBar title is displayed
    expect(find.widgetWithText(AppBar, 'Bakery Warm'), findsOneWidget);

    // Verify the new welcome message
    expect(find.text('Bienvenido a Bakery Warm'), findsOneWidget);

    // Verify the new action card titles
    expect(find.text('Crear Receta'), findsOneWidget);
    expect(find.text('Agregar Ingrediente'), findsOneWidget);
    expect(find.text('Mis Recetas'), findsOneWidget);
    expect(find.text('Mi Alacena'), findsOneWidget);
  });
}
