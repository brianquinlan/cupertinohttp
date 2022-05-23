import 'dart:ffi';

import 'native_cupertino_bindings.dart' as ncb;

// Access to symbols that are linked into the process. The "Foundation"
// framework is linked to Dart so no additional libraries need to be loaded
// to access those symbols.
late ncb.NativeCupertinoHttp linkedLibs = () {
  final lib = DynamicLibrary.process();
  return ncb.NativeCupertinoHttp(lib);
}();

// TODO(https://github.com/dart-lang/ffigen/issues/373): Change to
// ncb.NSString.
String? toStringOrNull(ncb.NSObject? o) {
  if (o == null) {
    return null;
  }

  return ncb.NSString.castFrom(o).toString();
}

/// Converts a NSDictionary containing NSString keys and NSString values into
/// an equivalent map.
Map<String, String> stringDictToMap(ncb.NSDictionary d) {
  // TODO(https://github.com/dart-lang/ffigen/issues/374): Make this
  // function type safe. Currently it will unconditionally cast both keys and
  // values to NSString with a likely crash down the line if that isn't their
  // true types.
  final m = Map<String, String>();

  final keys = ncb.NSArray.castFrom(d.allKeys!);
  for (var i = 0; i < keys.count; ++i) {
    final nsKey = keys.objectAtIndex_(i);
    final key = toStringOrNull(nsKey)!;
    final value = toStringOrNull(d.objectForKey_(nsKey))!;
    m[key] = value;
  }

  return m;
}
