import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'index.config.dart';


final GetIt getIt = GetIt.instance;
bool _dependenciesHasBeenConfigured = false;
late final String _environment;

@InjectableInit(
  initializerName: r'$initGetIt', // default
  preferRelativeImports: true, // default
  asExtension: false, // default
)
void configureDependencies (String environment) {
  assert(!_dependenciesHasBeenConfigured, 'Configuring dependencies twice');
  assert(environment == 'dev' || environment=='prod' || environment=='test');
  _environment = environment;
  $initGetIt(getIt, environment: environment);
  _dependenciesHasBeenConfigured = true;
}

String get environment => _environment;
bool get dependenciesHasBeenConfigured => _dependenciesHasBeenConfigured;