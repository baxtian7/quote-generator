# Cuenta Clara

Aplicación Flutter para crear cuentas de cobro de Juan Pablo Jiménez Escobar y exportarlas como PDF. El diseño del documento replica la cuenta de cobro suministrada: tamaño carta, bloques centrados, tabla azul opcional, total en números y letras, datos bancarios y firma.

## Funciones

- Datos fijos protegidos: beneficiario, cédula, cuenta Bancolombia y firma.
- Captura del deudor, identificación, concepto, descripción y fecha.
- Tabla opcional construida en el mismo formulario.
- Columnas editables de tipo texto, fecha, hora, número o moneda.
- Filas dinámicas y cálculo automático desde una columna numérica elegida.
- Total manual cuando no se usa tabla o no se elige una columna para sumar.
- Conversión automática del total a letras en español.
- Vista previa del PDF, descarga con selector de ubicación y uso compartido.
- Fuente embebida para funcionar sin conexión y conservar acentos.

## Ejecutar

```powershell
flutter pub get
flutter run
```

La app está preparada para Android, iOS, web y escritorio. Para una prueba rápida en navegador:

```powershell
flutter run -d chrome
```

## Verificar

```powershell
flutter analyze
flutter test
flutter build web
dart run tool/generate_sample.dart
```

El último comando genera `output/pdf/cuenta_de_cobro_ejemplo.pdf` con los datos del documento de referencia para facilitar la comparación visual.
