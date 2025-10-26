import 'dart:js_interop';

/// Utilidad para convertir JSPromise a Future con tipo correcto
extension JSPromiseExtension on JSPromise {
  Future<T?> toDartTyped<T>() async {
    final result = await toDart;
    return result as T?;
  }
}

/// Convertir JSAny? a tipo Dart
T? dartifyTyped<T>(JSAny? value) {
  if (value == null) return null;
  
  // Para tipos primitivos
  if (value is JSString) return value.toDart as T;
  if (value is JSNumber) return value.toDartInt as T;
  if (value is JSBoolean) return value.toDart as T;
  
  // Para objetos complejos, devolver como está
  return value as T;
}
