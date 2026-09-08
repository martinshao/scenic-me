import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../app/theme/app_theme.dart';
import '../data/nearby_services.dart';

const _travelImage =
    'docs/changes/001-ai-travel-photo/prototype/assets/'
    'west-lake-travel-portrait.png';

enum NearbyFilter {
  recommended('为你推荐'),
  nature('自然风光'),
  landmark('城市地标');

  const NearbyFilter(this.label);
  final String label;
}

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({
    required this.city,
    required this.locationMode,
    required this.filter,
    required this.selectedScene,
    required this.onBack,
    required this.onCityChanged,
    required this.onFilterChanged,
    required this.onSceneChanged,
    required this.onContinue,
    this.dependencies,
    super.key,
  });

  final String city;
  final bool locationMode;
  final NearbyFilter filter;
  final String? selectedScene;
  final VoidCallback onBack;
  final void Function(String city, bool locationMode) onCityChanged;
  final ValueChanged<NearbyFilter> onFilterChanged;
  final ValueChanged<String?> onSceneChanged;
  final ValueChanged<String> onContinue;
  final NearbyMapDependencies? dependencies;

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  final MapController _mapController = MapController();
  late final NearbyMapDependencies _dependencies;
  late String _city;
  late bool _locationMode;
  late NearbyFilter _filter;
  late String? _selectedScene;
  bool _showList = false;
  bool _locating = false;
  LatLng? _currentPoint;
  _SceneSpot? _searchedScene;
  List<String> _recentCities = const [];

  List<_SceneSpot> get _scenes => [?_searchedScene, ..._spotsForCity(_city)];

  @override
  void initState() {
    super.initState();
    _dependencies = widget.dependencies ?? NearbyMapDependencies.production();
    _city = widget.city;
    _locationMode = widget.locationMode;
    _filter = widget.filter;
    _selectedScene = widget.selectedScene;
    unawaited(_loadRecentCities());
  }

  Future<void> _loadRecentCities() async {
    final cities = await _dependencies.recentCities.load();
    if (mounted) setState(() => _recentCities = cities);
  }

  Future<void> _openCityPicker() async {
    final choice = await showModalBottomSheet<_CityChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.deepOcean.withValues(alpha: 0.42),
      builder: (_) =>
          _CityPickerSheet(currentCity: _city, recentCities: _recentCities),
    );
    if (!mounted || choice == null) return;
    if (choice.useLocation) {
      await _showLocationPurpose();
    } else if (choice.city != null) {
      _selectCity(choice.city!);
    }
  }

  Future<void> _showLocationPurpose() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.deepOcean.withValues(alpha: 0.42),
      builder: (_) => const _LocationPurposeSheet(),
    );
    if (!mounted || result == null) return;
    if (!result) {
      await _openCityPicker();
      return;
    }
    setState(() => _locating = true);
    try {
      final located = await _dependencies.location.locateCurrentCity();
      if (!mounted) return;
      setState(() {
        _locating = false;
        _city = located.city;
        _currentPoint = located.point;
        _locationMode = true;
        _selectedScene = null;
        _searchedScene = null;
      });
      if (_dependencies.useNetworkTiles) {
        _mapController.move(located.point, 14);
      }
      widget.onCityChanged(_city, true);
      widget.onSceneChanged(null);
      await _rememberCity(_city);
      _showMessage('已定位到$_city，位置只用于本次附近推荐');
    } on LocationFailure catch (error) {
      if (!mounted) return;
      setState(() => _locating = false);
      _showLocationFailure(error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locating = false);
      _showMessage('定位失败，请稍后重试或手动选择城市');
    }
  }

  Future<void> _selectCity(String city) async {
    setState(() {
      _city = city;
      _locationMode = false;
      _currentPoint = null;
      _selectedScene = null;
      _searchedScene = null;
    });
    if (_dependencies.useNetworkTiles) {
      _mapController.move(_centerForCity(city), 12.8);
    }
    widget.onCityChanged(city, false);
    widget.onSceneChanged(null);
    await _rememberCity(city);
    _showMessage('已切换到$city，未使用定位');
  }

  Future<void> _rememberCity(String city) async {
    final cities = await _dependencies.recentCities.remember(city);
    if (mounted) setState(() => _recentCities = cities);
  }

  void _showLocationFailure(LocationFailure error) {
    final canOpenSettings =
        error.reason == LocationFailureReason.deniedForever ||
        error.reason == LocationFailureReason.serviceDisabled;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: canOpenSettings
              ? SnackBarAction(
                  label: '打开设置',
                  onPressed: () =>
                      _dependencies.location.openSettings(error.reason),
                )
              : null,
        ),
      );
  }

  Future<void> _openPlaceSearch() async {
    final result = await showModalBottomSheet<PlaceSearchResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.deepOcean.withValues(alpha: 0.42),
      builder: (_) =>
          _PlaceSearchSheet(city: _city, service: _dependencies.placeSearch),
    );
    if (!mounted || result == null) return;
    final scene = _SceneSpot.search(result);
    setState(() {
      _searchedScene = scene;
      _selectedScene = scene.title;
      _showList = false;
    });
    if (_dependencies.useNetworkTiles) {
      _mapController.move(result.point, 15);
    }
    widget.onSceneChanged(scene.title);
  }

  void _selectFilter(NearbyFilter filter) {
    setState(() => _filter = filter);
    widget.onFilterChanged(filter);
  }

  void _selectScene(_SceneSpot scene) {
    setState(() => _selectedScene = scene.title);
    widget.onSceneChanged(scene.title);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mapLeaf,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Semantics(
                      image: true,
                      label: '$_city真实地图，可选择照片场景或搜索地点',
                      child: _RealMap(
                        mapController: _mapController,
                        city: _city,
                        scenes: _scenes,
                        selectedScene: _selectedScene,
                        currentPoint: _currentPoint,
                        useNetworkTiles: _dependencies.useNetworkTiles,
                        onSelected: _selectScene,
                      ),
                    ),
                  ),
                  _MapHeader(
                    city: _city,
                    showList: _showList,
                    onBack: widget.onBack,
                    onCityTap: _openCityPicker,
                    onSearchTap: _openPlaceSearch,
                    onViewToggle: () => setState(() => _showList = !_showList),
                  ),
                  Positioned(
                    top: 70,
                    left: 16,
                    right: landscape ? constraints.maxWidth - 370 : 16,
                    child: _FilterBar(
                      selected: _filter,
                      locationMode: _locationMode,
                      onSelected: _selectFilter,
                    ),
                  ),
                  Positioned(
                    top: 122,
                    left: 16,
                    child: _ModeBadge(locationMode: _locationMode),
                  ),
                  Positioned(
                    top: 118,
                    right: 16,
                    child: _CircleButton(
                      key: const Key('nearby-locate'),
                      tooltip: '定位当前城市',
                      icon: Icons.my_location_rounded,
                      showNotificationDot: !_locationMode,
                      onPressed: _showLocationPurpose,
                    ),
                  ),
                  if (_showList)
                    Positioned(
                      top: 166,
                      left: 16,
                      right: landscape ? 372 : 16,
                      bottom: landscape
                          ? 16
                          : (_selectedScene == null ? 28 : 226),
                      child: _SceneList(
                        scenes: _scenes,
                        locationMode: _locationMode,
                        selectedScene: _selectedScene,
                        onSelected: _selectScene,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Positioned(
                    right: landscape ? 372 : 14,
                    bottom: landscape
                        ? 12
                        : (_selectedScene == null ? 18 : 218),
                    child: const _MapCredit(),
                  ),
                  if (_selectedScene == null && !_showList)
                    Positioned(
                      left: 16,
                      right: landscape ? 372 : 16,
                      bottom: 18,
                      child: const _ChooseHint(),
                    ),
                  if (_selectedScene != null)
                    _SelectedSceneCard(
                      scene: _scenes.firstWhere(
                        (scene) => scene.title == _selectedScene,
                        orElse: () => _scenes.first,
                      ),
                      locationMode: _locationMode,
                      landscape: landscape,
                      onContinue: () => widget.onContinue(_selectedScene!),
                    ),
                  if (_locating) const _LocatingOverlay(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RealMap extends StatelessWidget {
  const _RealMap({
    required this.mapController,
    required this.city,
    required this.scenes,
    required this.selectedScene,
    required this.currentPoint,
    required this.useNetworkTiles,
    required this.onSelected,
  });

  final MapController mapController;
  final String city;
  final List<_SceneSpot> scenes;
  final String? selectedScene;
  final LatLng? currentPoint;
  final bool useNetworkTiles;
  final ValueChanged<_SceneSpot> onSelected;

  @override
  Widget build(BuildContext context) {
    if (!useNetworkTiles) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final positions = constraints.maxWidth > constraints.maxHeight
              ? const [(0.06, 0.40), (0.31, 0.57), (0.18, 0.72)]
              : const [(0.08, 0.27), (0.49, 0.43), (0.03, 0.60)];
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _TravelMapPainter(city: city)),
              ),
              for (var index = 0; index < scenes.length; index++)
                Positioned(
                  left: constraints.maxWidth * positions[index % 3].$1,
                  top: constraints.maxHeight * positions[index % 3].$2,
                  child: SizedBox(
                    width: 176,
                    height: 94,
                    child: _SceneMarker(
                      key: Key('nearby-scene-$index'),
                      scene: scenes[index],
                      selected: scenes[index].title == selectedScene,
                      onTap: () => onSelected(scenes[index]),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: _centerForCity(city),
        initialZoom: 12.8,
        minZoom: 3,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.martinshaw.scenic_me',
          maxNativeZoom: 19,
        ),
        MarkerLayer(
          markers: [
            for (var index = 0; index < scenes.length; index++)
              Marker(
                point: scenes[index].point,
                width: 176,
                height: 94,
                alignment: Alignment.bottomCenter,
                child: _SceneMarker(
                  key: Key('nearby-scene-$index'),
                  scene: scenes[index],
                  selected: scenes[index].title == selectedScene,
                  onTap: () => onSelected(scenes[index]),
                ),
              ),
            if (currentPoint != null)
              Marker(
                point: currentPoint!,
                width: 30,
                height: 30,
                child: const _CurrentLocationMarker(),
              ),
          ],
        ),
      ],
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '当前位置',
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.clearSky,
          shape: BoxShape.circle,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.white, width: 4),
          ),
          boxShadow: [BoxShadow(color: Color(0x55326473), blurRadius: 10)],
        ),
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.city,
    required this.showList,
    required this.onBack,
    required this.onCityTap,
    required this.onSearchTap,
    required this.onViewToggle,
  });

  final String city;
  final bool showList;
  final VoidCallback onBack;
  final VoidCallback onCityTap;
  final VoidCallback onSearchTap;
  final VoidCallback onViewToggle;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 6,
      left: 16,
      right: 16,
      child: Row(
        children: [
          _CircleButton(
            tooltip: '返回上一页',
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: AppColors.white.withValues(alpha: 0.96),
              elevation: 2,
              shadowColor: AppColors.deepOcean.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(19),
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    TextButton.icon(
                      key: const Key('city-selector'),
                      onPressed: onCityTap,
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                      ),
                      label: Text(city, maxLines: 1),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(60, 44),
                        foregroundColor: AppColors.deepOcean,
                        backgroundColor: AppColors.mintWash,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Container(width: 1, height: 22, color: AppColors.border),
                    const SizedBox(width: 9),
                    Expanded(
                      child: InkWell(
                        key: const Key('place-search'),
                        onTap: onSearchTap,
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '搜索景点或区域',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.supportTeal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CircleButton(
            key: const Key('nearby-view-toggle'),
            tooltip: showList ? '切换到地图' : '切换到列表',
            icon: showList ? Icons.map_outlined : Icons.view_agenda_outlined,
            onPressed: onViewToggle,
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.locationMode,
    required this.onSelected,
  });

  final NearbyFilter selected;
  final bool locationMode;
  final ValueChanged<NearbyFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in NearbyFilter.values) ...[
            Semantics(
              selected: selected == filter,
              button: true,
              child: ChoiceChip(
                key: Key('nearby-filter-${filter.name}'),
                label: Text(
                  filter == NearbyFilter.recommended
                      ? '${locationMode ? '为你推荐' : '精选场景'} 4'
                      : filter.label,
                ),
                selected: selected == filter,
                showCheckmark: false,
                onSelected: (_) => onSelected(filter),
                side: BorderSide(
                  color: selected == filter
                      ? AppColors.deepOcean
                      : AppColors.controlBorder,
                ),
                selectedColor: AppColors.deepOcean,
                backgroundColor: AppColors.white.withValues(alpha: 0.94),
                labelStyle: TextStyle(
                  color: selected == filter
                      ? AppColors.white
                      : AppColors.deepOcean,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.locationMode});

  final bool locationMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(11),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16102F38),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        locationMode ? '当前位置附近 · 已按光线排序' : '城市浏览 · 距离需开启定位',
        style: const TextStyle(color: AppColors.supportTeal, fontSize: 11),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.showNotificationDot = false,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool showNotificationDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.white.withValues(alpha: 0.96),
          elevation: 2,
          shadowColor: AppColors.deepOcean.withValues(alpha: 0.16),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon, size: 21),
            color: AppColors.deepOcean,
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          ),
        ),
        if (showNotificationDot)
          const Positioned(
            top: 3,
            right: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.coralFocus,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.white, width: 2),
                ),
              ),
              child: SizedBox(width: 10, height: 10),
            ),
          ),
      ],
    );
  }
}

class _SceneMarker extends StatelessWidget {
  const _SceneMarker({
    required this.scene,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final _SceneSpot scene;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${scene.title}，${scene.kind}，${scene.positions}个机位',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: AppColors.white.withValues(alpha: 0.97),
            elevation: selected ? 6 : 3,
            shadowColor: AppColors.deepOcean.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                constraints: const BoxConstraints(minWidth: 132, minHeight: 68),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.deepOcean : AppColors.white,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        _travelImage,
                        width: 50,
                        height: 56,
                        fit: BoxFit.cover,
                        alignment: scene.alignment,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scene.shortTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${scene.kind} · ${scene.positions} 机位',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.supportTeal,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (selected)
            const Positioned(top: -11, right: 8, child: _SelectedLabel()),
          const Positioned(
            left: 25,
            bottom: -8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.coralFocus,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.white, width: 3),
                ),
              ),
              child: SizedBox(width: 15, height: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedLabel extends StatelessWidget {
  const _SelectedLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.deepOcean,
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Text(
        '取景中',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SelectedSceneCard extends StatelessWidget {
  const _SelectedSceneCard({
    required this.scene,
    required this.locationMode,
    required this.landscape,
    required this.onContinue,
  });

  final _SceneSpot scene;
  final bool locationMode;
  final bool landscape;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: landscape ? null : 16,
      right: 16,
      bottom: 16,
      width: landscape ? 340 : null,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.98),
        elevation: 10,
        shadowColor: AppColors.deepOcean.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      _travelImage,
                      width: landscape ? 88 : 98,
                      height: landscape ? 96 : 112,
                      fit: BoxFit.cover,
                      alignment: scene.alignment,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locationMode
                                ? '当前位置 · ${scene.distance} · ${scene.positions} 个机位'
                                : '城市浏览 · 距离需开启定位',
                            style: const TextStyle(
                              color: AppColors.supportTeal,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            scene.title,
                            style: const TextStyle(
                              fontSize: 21,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            scene.description,
                            maxLines: landscape ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.supportTeal,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              FilledButton.icon(
                key: const Key('nearby-continue'),
                onPressed: onContinue,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                label: const Text('用这个场景继续'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: AppColors.white,
                  backgroundColor: AppColors.deepOcean,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneList extends StatelessWidget {
  const _SceneList({
    required this.scenes,
    required this.locationMode,
    required this.selectedScene,
    required this.onSelected,
  });

  final List<_SceneSpot> scenes;
  final bool locationMode;
  final String? selectedScene;
  final ValueChanged<_SceneSpot> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.morningMist.withValues(alpha: 0.97),
      elevation: 5,
      shadowColor: AppColors.deepOcean.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(24),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: scenes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 7),
        itemBuilder: (context, index) {
          final scene = scenes[index];
          return ListTile(
            selected: selectedScene == scene.title,
            selectedTileColor: AppColors.mintWash,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onTap: () => onSelected(scene),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                _travelImage,
                width: 50,
                height: 54,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              scene.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              locationMode
                  ? '${scene.distance} · ${scene.positions} 个机位'
                  : '城市浏览',
            ),
          );
        },
      ),
    );
  }
}

class _ChooseHint extends StatelessWidget {
  const _ChooseHint();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.96),
      elevation: 5,
      borderRadius: BorderRadius.circular(18),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.camera_alt_outlined, color: AppColors.deepOcean),
            SizedBox(width: 10),
            Expanded(child: Text('选择一个照片标记，查看光线和机位建议')),
          ],
        ),
      ),
    );
  }
}

class _MapCredit extends StatelessWidget {
  const _MapCredit();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '© OpenStreetMap contributors',
        style: TextStyle(color: AppColors.supportTeal, fontSize: 10),
      ),
    );
  }
}

class _LocatingOverlay extends StatelessWidget {
  const _LocatingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.morningMist.withValues(alpha: 0.76),
        child: Center(
          child: Material(
            color: AppColors.white,
            elevation: 8,
            borderRadius: BorderRadius.circular(24),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 34, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(),
                  ),
                  SizedBox(height: 14),
                  Text(
                    '正在定位',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text('正在获取当前位置，请稍候。'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet({required this.city, required this.service});

  final String city;
  final PlaceSearchService service;

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _controller = TextEditingController();
  List<PlaceSearchResult> _results = const [];
  bool _searching = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() => _error = '请输入景点或区域名称');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _submitted = true;
      _error = null;
    });
    try {
      final results = await widget.service.search(
        query: query,
        city: widget.city,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searching = false;
        _error = '地点搜索暂时不可用，请检查网络后重试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.morningMist,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '在${widget.city}搜索地点',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭地点搜索',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('place-search-input'),
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  labelText: '景点或区域',
                  hintText: '例如：雷峰塔、外滩',
                  errorText: _error,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    key: const Key('place-search-submit'),
                    tooltip: '搜索地点',
                    onPressed: _searching ? null : _search,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_searching)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_submitted && _results.isEmpty && _error == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Text('没有找到匹配地点，请尝试更完整的名称。'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return ListTile(
                        key: Key('place-search-result-$index'),
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.mintWash,
                          foregroundColor: AppColors.deepOcean,
                          child: Icon(Icons.place_outlined),
                        ),
                        title: Text(
                          result.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          result.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(result),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                '仅在点击搜索后查询 · 地点数据 © OpenStreetMap contributors',
                style: TextStyle(color: AppColors.supportTeal, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({
    required this.currentCity,
    required this.recentCities,
  });

  final String currentCity;
  final List<String> recentCities;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = '请输入城市名称');
      return;
    }
    Navigator.of(context).pop(_CityChoice.city(value));
  }

  @override
  Widget build(BuildContext context) {
    const popularCities = ['杭州', '上海', '北京', '成都', '西安', '厦门'];
    final cities = {
      ...widget.recentCities,
      ...popularCities,
    }.take(6).toList(growable: false);
    return Material(
      color: AppColors.morningMist,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '想去哪里找场景？',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: '关闭城市选择',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.mintWash,
                    minimumSize: const Size(44, 44),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Material(
              color: AppColors.deepOcean,
              borderRadius: BorderRadius.circular(18),
              child: ListTile(
                key: const Key('use-current-city'),
                minTileHeight: 68,
                textColor: AppColors.white,
                iconColor: AppColors.white,
                leading: const Icon(Icons.my_location_rounded),
                title: const Text(
                  '定位当前城市',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  '查看附近距离与推荐机位',
                  style: TextStyle(color: Color(0xFFCDE1DF), fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    Navigator.of(context).pop(const _CityChoice.location()),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '手动选择城市',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 9),
            TextField(
              key: const Key('manual-city-input'),
              controller: _controller,
              textInputAction: TextInputAction.search,
              autofillHints: const [AutofillHints.addressCity],
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: '城市名称',
                hintText: '例如：杭州',
                errorText: _error,
                suffixIcon: IconButton(
                  key: const Key('manual-city-submit'),
                  tooltip: '查找城市',
                  onPressed: _submit,
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.recentCities.isEmpty ? '常用城市' : '最近与常用',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 9),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cities.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 44,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) => OutlinedButton(
                key: Key('city-${cities[index]}'),
                onPressed: () =>
                    Navigator.of(context).pop(_CityChoice.city(cities[index])),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: AppColors.deepOcean,
                  side: BorderSide(
                    color: cities[index] == widget.currentCity
                        ? AppColors.deepOcean
                        : AppColors.controlBorder,
                  ),
                  backgroundColor: AppColors.white,
                ),
                child: Text(cities[index]),
              ),
            ),
            const SizedBox(height: 13),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: AppColors.supportTeal,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '手动选城无需定位权限。最近城市仅保存在这台设备，不保存你的具体位置。',
                    style: TextStyle(
                      color: AppColors.supportTeal,
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPurposeSheet extends StatelessWidget {
  const _LocationPurposeSheet();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.morningMist,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '用位置找附近机位',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 104,
              decoration: BoxDecoration(
                color: AppColors.mapWaterLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.deepOcean,
                  child: Icon(Icons.my_location_rounded, size: 30),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              '只用于推荐你附近的景点、距离和拍摄机位。继续后系统会询问前台定位权限；你也可以不开启定位，手动选择城市。',
              style: TextStyle(color: AppColors.supportTeal, height: 1.55),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('continue-location'),
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: AppColors.white,
                backgroundColor: AppColors.deepOcean,
              ),
              child: const Text('继续并允许定位'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('choose-city-instead'),
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('改为手动选城'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelMapPainter extends CustomPainter {
  const _TravelMapPainter({required this.city});

  final String city;

  @override
  void paint(Canvas canvas, Size size) {
    final land = Paint()..color = AppColors.mapLeaf;
    final park = Paint()..color = AppColors.mapLeafDark;
    final water = Paint()..color = AppColors.mapWater;
    canvas.drawRect(Offset.zero & size, land);

    final waterPath = Path()
      ..moveTo(size.width * .31, 0)
      ..cubicTo(
        size.width * .75,
        size.height * .03,
        size.width,
        size.height * .18,
        size.width * .88,
        size.height * .43,
      )
      ..cubicTo(
        size.width * .76,
        size.height * .67,
        size.width * .82,
        size.height * .88,
        size.width * .42,
        size.height,
      )
      ..cubicTo(
        size.width * .12,
        size.height * .86,
        size.width * .11,
        size.height * .56,
        size.width * .24,
        size.height * .38,
      )
      ..cubicTo(
        size.width * .34,
        size.height * .23,
        size.width * .18,
        size.height * .08,
        size.width * .31,
        0,
      )
      ..close();
    canvas.drawPath(waterPath, water);

    final parkPath = Path()
      ..moveTo(0, size.height * .05)
      ..quadraticBezierTo(
        size.width * .42,
        size.height * .02,
        size.width * .34,
        size.height * .42,
      )
      ..quadraticBezierTo(
        size.width * .08,
        size.height * .57,
        0,
        size.height * .74,
      )
      ..close();
    canvas.drawPath(parkPath, park);

    final road = Paint()
      ..color = AppColors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    final roadPath = Path()
      ..moveTo(-20, size.height * .13)
      ..cubicTo(
        size.width * .32,
        size.height * .21,
        size.width * .72,
        size.height * .08,
        size.width + 30,
        size.height * .02,
      );
    canvas.drawPath(roadPath, road);
    final road2 = Path()
      ..moveTo(-10, size.height * .74)
      ..cubicTo(
        size.width * .34,
        size.height * .61,
        size.width * .64,
        size.height * .82,
        size.width + 20,
        size.height * .77,
      );
    canvas.drawPath(road2, road);

    final route = Paint()
      ..color = AppColors.mapRoute
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final routePath = Path()
      ..moveTo(size.width * .14, size.height * .49)
      ..cubicTo(
        size.width * .4,
        size.height * .58,
        size.width * .69,
        size.height * .55,
        size.width * .95,
        size.height * .4,
      );
    for (final metric in routePath.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 7), route);
        distance += 15;
      }
    }

    final label = TextPainter(
      text: TextSpan(
        text: city,
        style: const TextStyle(
          color: Color(0xFF6A987D),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(
      canvas,
      Offset(size.width * .5 - label.width / 2, size.height * .54),
    );
  }

  @override
  bool shouldRepaint(covariant _TravelMapPainter oldDelegate) =>
      oldDelegate.city != city;
}

class _SceneSpot {
  const _SceneSpot({
    required this.title,
    required this.shortTitle,
    required this.kind,
    required this.positions,
    required this.distance,
    required this.description,
    required this.alignment,
    required this.point,
  });

  factory _SceneSpot.search(PlaceSearchResult result) => _SceneSpot(
    title: result.name,
    shortTitle: result.name,
    kind: '搜索地点',
    positions: 1,
    distance: '已找到真实地点',
    description: '以这个地点为场景继续，下一步可以添加肖像与选择风格。',
    alignment: Alignment.center,
    point: result.point,
  );

  final String title;
  final String shortTitle;
  final String kind;
  final int positions;
  final String distance;
  final String description;
  final Alignment alignment;
  final LatLng point;
}

class _CityChoice {
  const _CityChoice.location() : city = null, useLocation = true;
  const _CityChoice.city(this.city) : useLocation = false;

  final String? city;
  final bool useLocation;
}

List<_SceneSpot> _spotsForCity(String city) {
  if (city == '杭州') {
    return const [
      _SceneSpot(
        title: '雷峰塔 · 夕照',
        shortTitle: '雷峰塔',
        kind: '夕照',
        positions: 3,
        distance: '约 1.2 km',
        description: '现在适合侧逆光，人物轮廓会更自然。',
        alignment: Alignment(-0.1, 0),
        point: LatLng(30.2319, 120.1483),
      ),
      _SceneSpot(
        title: '西湖游船',
        shortTitle: '西湖游船',
        kind: '自然',
        positions: 2,
        distance: '约 800 m',
        description: '水面反光柔和，适合自然抓拍感。',
        alignment: Alignment(0.55, 0),
        point: LatLng(30.2426, 120.1536),
      ),
      _SceneSpot(
        title: '曲院风荷',
        shortTitle: '曲院风荷',
        kind: '自然',
        positions: 1,
        distance: '约 2.4 km',
        description: '绿意充足，适合清透的半身构图。',
        alignment: Alignment(-0.45, 0),
        point: LatLng(30.2535, 120.1374),
      ),
    ];
  }
  final names = switch (city) {
    '上海' => ('外滩 · 蓝调时刻', '武康路', '苏州河'),
    '北京' => ('景山 · 日落', '什刹海', '前门街景'),
    '成都' => ('望江楼', '锦里夜色', '东郊记忆'),
    '西安' => ('城墙 · 暮色', '大雁塔', '永宁门'),
    '厦门' => ('环岛路', '沙坡尾', '鼓浪屿'),
    _ => ('$city · 城市光影', '$city · 街角', '$city · 天际线'),
  };
  final center = _centerForCity(city);
  return [
    _SceneSpot(
      title: names.$1,
      shortTitle: names.$1.split(' · ').first,
      kind: '城市',
      positions: 3,
      distance: '约 1.0 km',
      description: '适合利用城市轮廓和当前光线完成人像构图。',
      alignment: const Alignment(-0.1, 0),
      point: LatLng(center.latitude - 0.006, center.longitude + 0.004),
    ),
    _SceneSpot(
      title: names.$2,
      shortTitle: names.$2,
      kind: '街景',
      positions: 2,
      distance: '约 1.8 km',
      description: '街道纵深清晰，适合自然行走画面。',
      alignment: const Alignment(0.55, 0),
      point: LatLng(center.latitude + 0.006, center.longitude - 0.008),
    ),
    _SceneSpot(
      title: names.$3,
      shortTitle: names.$3,
      kind: '地标',
      positions: 1,
      distance: '约 2.6 km',
      description: '地标辨识度高，适合完整环境人像。',
      alignment: const Alignment(-0.45, 0),
      point: LatLng(center.latitude + 0.002, center.longitude + 0.011),
    ),
  ];
}

LatLng _centerForCity(String city) => switch (city) {
  '杭州' => const LatLng(30.2434, 120.1502),
  '上海' => const LatLng(31.2304, 121.4737),
  '北京' => const LatLng(39.9042, 116.4074),
  '成都' => const LatLng(30.5728, 104.0668),
  '西安' => const LatLng(34.3416, 108.9398),
  '厦门' => const LatLng(24.4798, 118.0894),
  _ => const LatLng(35.8617, 104.1954),
};
