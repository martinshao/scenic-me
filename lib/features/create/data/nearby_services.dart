import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocatedCity {
  const LocatedCity({required this.city, required this.point});

  final String city;
  final LatLng point;
}

enum LocationFailureReason {
  serviceDisabled,
  denied,
  deniedForever,
  unavailable,
}

class LocationFailure implements Exception {
  const LocationFailure(this.reason, this.message);

  final LocationFailureReason reason;
  final String message;

  @override
  String toString() => message;
}

abstract interface class NearbyLocationService {
  Future<LocatedCity> locateCurrentCity();

  Future<bool> openSettings(LocationFailureReason reason);
}

class SystemNearbyLocationService implements NearbyLocationService {
  SystemNearbyLocationService({Geocoding? geocoding})
    : _geocoding = geocoding ?? Geocoding();

  final Geocoding _geocoding;

  @override
  Future<LocatedCity> locateCurrentCity() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(
        LocationFailureReason.serviceDisabled,
        '系统定位服务尚未开启',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        LocationFailureReason.denied,
        '未获得定位权限，你仍可手动选择城市',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureReason.deniedForever,
        '定位权限已关闭，请到系统设置中允许访问',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final city = placemarks.isEmpty
          ? '当前位置'
          : _cityFromPlacemark(placemarks.first);
      return LocatedCity(city: city, point: point);
    } on LocationFailure {
      rethrow;
    } catch (_) {
      throw const LocationFailure(
        LocationFailureReason.unavailable,
        '暂时无法确定当前位置，请稍后重试或手动选城',
      );
    }
  }

  @override
  Future<bool> openSettings(LocationFailureReason reason) {
    if (reason == LocationFailureReason.serviceDisabled) {
      return Geolocator.openLocationSettings();
    }
    return Geolocator.openAppSettings();
  }

  static String _cityFromPlacemark(Placemark placemark) {
    final candidates = [
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ];
    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) {
        return value.endsWith('市')
            ? value.substring(0, value.length - 1)
            : value;
      }
    }
    return '当前位置';
  }
}

class PlaceSearchResult {
  const PlaceSearchResult({
    required this.name,
    required this.displayName,
    required this.point,
  });

  final String name;
  final String displayName;
  final LatLng point;
}

abstract interface class PlaceSearchService {
  Future<List<PlaceSearchResult>> search({
    required String query,
    required String city,
  });
}

class NominatimPlaceSearchService implements PlaceSearchService {
  NominatimPlaceSearchService({
    http.Client? client,
    Uri? endpoint,
    this.userAgent = 'ScenicMe/0.1 (com.martinshaw.scenic_me)',
  }) : _client = client ?? http.Client(),
       _endpoint =
           endpoint ??
           Uri.parse(
             const String.fromEnvironment(
               'SCENIC_ME_GEOCODING_URL',
               defaultValue: 'https://nominatim.openstreetmap.org/search',
             ),
           );

  final http.Client _client;
  final Uri _endpoint;
  final String userAgent;
  final Map<String, List<PlaceSearchResult>> _cache = {};
  DateTime? _lastRequestAt;

  @override
  Future<List<PlaceSearchResult>> search({
    required String query,
    required String city,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final cacheKey = '$city|${trimmed.toLowerCase()}';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final previous = _lastRequestAt;
    if (previous != null) {
      final remaining =
          const Duration(seconds: 1) - DateTime.now().difference(previous);
      if (!remaining.isNegative) await Future<void>.delayed(remaining);
    }
    _lastRequestAt = DateTime.now();

    final uri = _endpoint.replace(
      queryParameters: {
        'q': '$trimmed, $city',
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '5',
        'accept-language': 'zh-CN',
      },
    );
    final response = await _client
        .get(uri, headers: {'User-Agent': userAgent})
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw const FormatException('地点服务暂时不可用');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! List) throw const FormatException('地点服务返回异常');
    final results = <PlaceSearchResult>[];
    for (final item in body.whereType<Map<String, dynamic>>()) {
      final latitude = double.tryParse(item['lat']?.toString() ?? '');
      final longitude = double.tryParse(item['lon']?.toString() ?? '');
      if (latitude == null || longitude == null) continue;
      final displayName = item['display_name']?.toString().trim() ?? trimmed;
      final named = item['name']?.toString().trim();
      results.add(
        PlaceSearchResult(
          name: named == null || named.isEmpty ? trimmed : named,
          displayName: displayName,
          point: LatLng(latitude, longitude),
        ),
      );
    }
    final immutable = List<PlaceSearchResult>.unmodifiable(results);
    _cache[cacheKey] = immutable;
    return immutable;
  }
}

abstract interface class RecentCitiesStore {
  Future<List<String>> load();

  Future<List<String>> remember(String city);
}

class DeviceRecentCitiesStore implements RecentCitiesStore {
  DeviceRecentCitiesStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'nearby.recent_cities.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<String>> load() async {
    try {
      return await _preferences.getStringList(_key) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<String>> remember(String city) async {
    final normalized = city.trim();
    if (normalized.isEmpty || normalized == '当前位置') return load();
    final current = await load();
    final updated = [
      normalized,
      ...current.where((item) => item != normalized),
    ].take(6).toList(growable: false);
    try {
      await _preferences.setStringList(_key, updated);
    } catch (_) {
      // The selected city remains usable even if device persistence fails.
    }
    return updated;
  }
}

class NearbyMapDependencies {
  const NearbyMapDependencies({
    required this.location,
    required this.placeSearch,
    required this.recentCities,
    this.useNetworkTiles = true,
  });

  factory NearbyMapDependencies.production() => NearbyMapDependencies(
    location: SystemNearbyLocationService(),
    placeSearch: NominatimPlaceSearchService(),
    recentCities: DeviceRecentCitiesStore(),
  );

  final NearbyLocationService location;
  final PlaceSearchService placeSearch;
  final RecentCitiesStore recentCities;
  final bool useNetworkTiles;
}
