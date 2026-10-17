import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quote_generator/main.dart';

void main() {
  testWidgets('muestra datos fijos y el constructor de tabla', (tester) async {
    await tester.pumpWidget(const QuoteGeneratorApp());

    expect(find.text('Cuenta Clara'), findsOneWidget);
    expect(find.textContaining('JUAN PABLO JIMÉNEZ ESCOBAR'), findsWidgets);
    expect(find.textContaining('52791286425'), findsOneWidget);
    expect(find.text('Tabla de detalle'), findsOneWidget);
    expect(find.text('Agregar columna'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Total a pagar'), findsOneWidget);
  });

  testWidgets('se adapta a pantalla móvil sin desbordamientos', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const QuoteGeneratorApp());
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Crea tu cuenta de cobro').hitTestable(), findsOneWidget);
    expect(find.text('Vista previa del PDF').hitTestable(), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Tabla de detalle'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Agregar columna'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
