// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../middleware/ws_channel/AbstractIOWsChannel.dart' as _i3;
import '../middleware/ws_channel/FakeIOWsChannel.dart' as _i5;
import '../middleware/ws_channel/IOWsChannel.dart' as _i4;

const String _dev = 'dev';
const String _prod = 'prod';
const String _test = 'test';
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: lines_longer_than_80_chars
/// initializes the registration of provided dependencies inside of [GetIt]
_i1.GetIt $initGetIt(_i1.GetIt get,
    {String? environment, _i2.EnvironmentFilter? environmentFilter}) {
  final gh = _i2.GetItHelper(get, environment, environmentFilter);
  gh.factoryParam<_i3.AbstractIOWsChannel, String?, dynamic>(
      (serverUrl, _) => _i4.IOWsChannel(serverUrl),
      registerFor: {_dev, _prod});
  gh.factoryParam<_i3.AbstractIOWsChannel, String?, dynamic>(
      (serverUrl, _) => _i5.FakeIOWsChannel(serverUrl: serverUrl),
      registerFor: {_test});
  return get;
}
