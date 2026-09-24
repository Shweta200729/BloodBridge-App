import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/models/hospital_model.dart';
import '../../../core/services/hospital_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/hospital_card.dart';
import '../../../core/widgets/loading_widget.dart';
import 'widgets/hospital_details_sheet.dart';

enum HospitalViewMode { list, map }

class HospitalsScreen extends ConsumerStatefulWidget {
  const HospitalsScreen({super.key});

  @override
  ConsumerState<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends ConsumerState<HospitalsScreen> {
  HospitalViewMode _viewMode = HospitalViewMode.list;
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  HospitalModel? _selectedMapHospital;
  bool _isLocating = false;

  // Default fallback center (Central India / National overview)
  static const LatLng _defaultCenter = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Initial passive attempt to obtain user location for proximity sorting.
  Future<void> _initUserLocation() async {
    final position = await HospitalService.determinePosition();
    if (position != null && mounted) {
      ref.read(userLocationProvider.notifier).state = position;
    }
  }

  Future<void> _centerOnUserLocation() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled on your device.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission was denied. You can still browse facilities manually.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is permanently denied. You can enable it in system settings.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (mounted) {
        ref.read(userLocationProvider.notifier).state = position;
      }

      final userLatLng = LatLng(position.latitude, position.longitude);
      _mapController.move(userLatLng, 13.0);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to obtain current location. Map remains interactive.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hospitalsAsync = ref.watch(filteredHospitalsProvider);
    final selectedType = ref.watch(hospitalTypeFilterProvider);
    final userPos = ref.watch(userLocationProvider);
    final sortByProximity = ref.watch(hospitalSortByProximityProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hospitals & Blood Banks',
        subtitle: 'Verified facilities & blood centers',
        actions: [
          // Toggle between List and Map view
          IconButton(
            icon: Icon(
              _viewMode == HospitalViewMode.list
                  ? Icons.map_outlined
                  : Icons.view_list_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip:
                _viewMode == HospitalViewMode.list ? 'Show Map' : 'Show List',
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == HospitalViewMode.list
                    ? HospitalViewMode.map
                    : HospitalViewMode.list;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Filter Bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceMD,
              vertical: AppDimensions.spaceSM,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                ref.read(hospitalSearchQueryProvider.notifier).state = val;
              },
              decoration: InputDecoration(
                hintText: 'Search by hospital, blood bank, or city...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(hospitalSearchQueryProvider.notifier).state =
                              '';
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceMD,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppDimensions.borderRadiusMD,
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
            ),
          ),

          // ── Facility Type Filters & Proximity Sort ───────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMD),
            child: Row(
              children: [
                // Proximity Sort Pill
                FilterChip(
                  avatar: Icon(
                    Icons.near_me_rounded,
                    size: 16,
                    color: sortByProximity && userPos != null
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                  label: Text(
                    userPos != null
                        ? 'Nearest First'
                        : 'Sort by Distance',
                  ),
                  selected: sortByProximity && userPos != null,
                  onSelected: (selected) async {
                    if (userPos == null) {
                      await _centerOnUserLocation();
                    }
                    ref.read(hospitalSortByProximityProvider.notifier).state =
                        !sortByProximity;
                  },
                ),
                const SizedBox(width: 8),

                // Category Filters
                ChoiceChip(
                  label: const Text('All Facilities'),
                  selected: selectedType == null,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(hospitalTypeFilterProvider.notifier).state = null;
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Hospitals'),
                  selected: selectedType == HospitalType.hospital,
                  onSelected: (selected) {
                    ref.read(hospitalTypeFilterProvider.notifier).state =
                        selected ? HospitalType.hospital : null;
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Blood Banks'),
                  selected: selectedType == HospitalType.bloodBank,
                  onSelected: (selected) {
                    ref.read(hospitalTypeFilterProvider.notifier).state =
                        selected ? HospitalType.bloodBank : null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── Body: List View or Map View ──────────────────────────────
          Expanded(
            child: hospitalsAsync.when(
              loading: () => const LoadingWidget(),
              error: (err, _) => Center(
                child: Padding(
                  padding: AppDimensions.screenPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      Text(
                        'Failed to load healthcare facilities.',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: AppDimensions.spaceMD),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(hospitalsStreamProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (hospitals) {
                if (hospitals.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.local_hospital_outlined,
                    title: 'No Facilities Found',
                    message:
                        'No hospitals or blood banks match your search. Try adjusting the search term or category filter.',
                  );
                }

                if (_viewMode == HospitalViewMode.list) {
                  return _buildListView(hospitals, userPos);
                } else {
                  return _buildMapView(hospitals, userPos);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<HospitalModel> hospitals, Position? userPos) {
    return ListView.separated(
      padding: AppDimensions.screenPadding,
      itemCount: hospitals.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.spaceMD),
      itemBuilder: (context, index) {
        final hospital = hospitals[index];
        final distanceText =
            hospital.formattedDistanceTo(userPos?.latitude, userPos?.longitude);

        return HospitalCard(
          hospital: hospital,
          distanceText: distanceText,
          onTap: () => HospitalDetailsSheet.show(context, hospital),
          onCallTap: () =>
              HospitalDetailsSheet.launchCall(context, hospital.phone),
          onDirectionsTap: () =>
              HospitalDetailsSheet.launchDirections(context, hospital),
        );
      },
    );
  }

  Widget _buildMapView(List<HospitalModel> hospitals, Position? userPos) {
    final validHospitals =
        hospitals.where((h) => h.hasCoordinates).toList();

    if (validHospitals.isEmpty) {
      return Center(
        child: Padding(
          padding: AppDimensions.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppDimensions.spaceMD),
              Text(
                'No Geo-Coordinates Available',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'None of the currently filtered facilities have geographic coordinates on file. Please switch to the list view to browse by address.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _viewMode = HospitalViewMode.list),
                icon: const Icon(Icons.view_list_rounded),
                label: const Text('Switch to List View'),
              ),
            ],
          ),
        ),
      );
    }

    final initialCenter = userPos != null
        ? LatLng(userPos.latitude, userPos.longitude)
        : validHospitals.isNotEmpty
            ? LatLng(
                validHospitals.first.latitude!,
                validHospitals.first.longitude!,
              )
            : _defaultCenter;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: userPos != null ? 11.0 : 6.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // OpenStreetMap Standard Tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bloodbridge.app',
            ),

            // OpenStreetMap Attribution (Required by OSM Foundation)
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  '© OpenStreetMap contributors',
                ),
              ],
            ),

            // Facility & User Pins
            MarkerLayer(
              markers: [
                // User Location Pin
                if (userPos != null)
                  Marker(
                    point: LatLng(userPos.latitude, userPos.longitude),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.healthcareBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.my_location_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                // Facility Pins
                ...validHospitals.map((h) {
                  final isSelected = _selectedMapHospital?.id == h.id;
                  final isBloodBank = h.type == HospitalType.bloodBank;
                  final pinColor = isBloodBank
                      ? AppColors.primaryRed
                      : AppColors.healthcareBlue;

                  return Marker(
                    point: LatLng(h.latitude!, h.longitude!),
                    width: isSelected ? 48 : 40,
                    height: isSelected ? 48 : 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedMapHospital = h);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: pinColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isBloodBank
                              ? Icons.water_drop_rounded
                              : Icons.local_hospital_rounded,
                          color: Colors.white,
                          size: isSelected ? 24 : 20,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // ── Floating Action: Locate Me ───────────────────────────────
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'locate_me_fab',
            backgroundColor: AppColors.surfaceWhite,
            foregroundColor: AppColors.textPrimary,
            tooltip: 'Center on my location',
            onPressed: _isLocating ? null : _centerOnUserLocation,
            child: _isLocating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, size: 20),
          ),
        ),

        // ── Selected Facility Preview Card ───────────────────────────
        if (_selectedMapHospital != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: AppDimensions.borderRadiusMD,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceMD),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedMapHospital!.name,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_selectedMapHospital!.address}, ${_selectedMapHospital!.city}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (userPos != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.near_me_rounded,
                                      size: 13,
                                      color: AppColors.primaryRed,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedMapHospital!
                                              .formattedDistanceTo(
                                                  userPos.latitude,
                                                  userPos.longitude) ??
                                          '',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.primaryRed,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              setState(() => _selectedMapHospital = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_selectedMapHospital!.hasPhone)
                          TextButton.icon(
                            onPressed: () => HospitalDetailsSheet.launchCall(
                              context,
                              _selectedMapHospital!.phone,
                            ),
                            icon: const Icon(Icons.call, size: 16),
                            label: const Text('Call'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.success,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        TextButton.icon(
                          onPressed: () =>
                              HospitalDetailsSheet.launchDirections(
                            context,
                            _selectedMapHospital!,
                          ),
                          icon: const Icon(Icons.directions, size: 16),
                          label: const Text('Directions'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.healthcareBlue,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        TextButton(
                          onPressed: () => HospitalDetailsSheet.show(
                            context,
                            _selectedMapHospital!,
                          ),
                          child: const Text('Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
