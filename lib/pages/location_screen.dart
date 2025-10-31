import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

// Mental Health Provider Model
class MentalHealthProvider {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final String? website;
  final double? rating;
  final String type;
  final double distanceKm;
  final bool isOpen;
  final Map<String, dynamic>? openingHours;
  final List<String>? amenities;

  MentalHealthProvider({
    required this.placeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.website,
    this.rating,
    required this.type,
    required this.distanceKm,
    required this.isOpen,
    this.openingHours,
    this.amenities,
  });

  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final double dLat = (lat2 - lat1) * (pi / 180);
    final double dLng = (lng2 - lng1) * (pi / 180);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
            sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  String get typeDisplayName {
    switch (type) {
      case 'psychiatrist':
        return 'Psychiatrist';
      case 'psychologist':
        return 'Psychologist';
      case 'counselor':
        return 'Counselor/Therapist';
      case 'clinic':
        return 'Mental Health Clinic';
      case 'hospital':
        return 'Mental Health Hospital';
      case 'psychotherapist':
        return 'Psychotherapist';
      default:
        return 'Mental Health Provider';
    }
  }

  String get distanceText => '${distanceKm.toStringAsFixed(1)} km away';
}

// Free Overpass API Service for OpenStreetMap
class OverpassPlacesService {
  // Method 2: Overpass API for OpenStreetMap data (100% Free)
  Future<List<MentalHealthProvider>> findNearbyMentalHealthProviders({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    final List<MentalHealthProvider> providers = [];
    final radiusMeters = (radiusKm * 1000).toInt();

    try {
      print('🔍 Searching with Overpass API...');

      // Comprehensive Overpass query for all types of mental health facilities
      final query = '''
        [out:json][timeout:25];
        (
          node["amenity"="hospital"]["healthcare"~"mental_health|psychiatry"](around:$radiusMeters,$latitude,$longitude);
          node["amenity"="clinic"]["healthcare"~"mental_health|psychiatry|psychology|counselling"](around:$radiusMeters,$latitude,$longitude);
          node["healthcare"="psychotherapist"](around:$radiusMeters,$latitude,$longitude);
          node["healthcare"="psychology"](around:$radiusMeters,$latitude,$longitude);
          node["healthcare"="counselling"](around:$radiusMeters,$latitude,$longitude);
          node["healthcare"="psychiatrist"](around:$radiusMeters,$latitude,$longitude);
          node["healthcare"="mental_health"](around:$radiusMeters,$latitude,$longitude);
          node["amenity"="social_facility"]["social_facility"="healthcare"]["social_facility:for"~"mental_health"](around:$radiusMeters,$latitude,$longitude);
          way["amenity"="hospital"]["healthcare"~"mental_health|psychiatry"](around:$radiusMeters,$latitude,$longitude);
          way["amenity"="clinic"]["healthcare"~"mental_health|psychiatry|psychology|counselling"](around:$radiusMeters,$latitude,$longitude);
          way["healthcare"="psychotherapist"](around:$radiusMeters,$latitude,$longitude);
          way["healthcare"="psychology"](around:$radiusMeters,$latitude,$longitude);
          way["healthcare"="counselling"](around:$radiusMeters,$latitude,$longitude);
          way["healthcare"="psychiatrist"](around:$radiusMeters,$latitude,$longitude);
          way["healthcare"="mental_health"](around:$radiusMeters,$latitude,$longitude);
          relation["amenity"="hospital"]["healthcare"~"mental_health|psychiatry"](around:$radiusMeters,$latitude,$longitude);
          relation["amenity"="clinic"]["healthcare"~"mental_health|psychiatry|psychology|counselling"](around:$radiusMeters,$latitude,$longitude);
        );
        out center;
      ''';

      final url = 'https://overpass-api.de/api/interpreter';
      final response = await http.post(
        Uri.parse(url),
        body: query,
        headers: {
          'Content-Type': 'text/plain',
          'User-Agent': 'MentalHealthApp/1.0',
        },
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List<dynamic>;

        print('✅ Found ${elements.length} potential facilities from Overpass API');

        for (var element in elements) {
          try {
            double lat, lon;

            if (element['type'] == 'node') {
              lat = element['lat']?.toDouble() ?? 0.0;
              lon = element['lon']?.toDouble() ?? 0.0;
            } else {
              // For ways and relations, use center coordinates
              lat = element['center']?['lat']?.toDouble() ?? element['lat']?.toDouble() ?? 0.0;
              lon = element['center']?['lon']?.toDouble() ?? element['lon']?.toDouble() ?? 0.0;
            }

            if (lat == 0.0 || lon == 0.0) continue;

            final distance = MentalHealthProvider.calculateDistance(
                latitude, longitude, lat, lon
            );

            if (distance <= radiusKm) {
              final tags = element['tags'] as Map<String, dynamic>? ?? {};

              // Skip if no meaningful name
              final name = tags['name'] ?? tags['operator'] ?? tags['brand'];
              if (name == null || name.toString().trim().isEmpty) continue;

              providers.add(MentalHealthProvider(
                placeId: 'osm_${element['type']}_${element['id']}',
                name: name.toString(),
                address: _buildAddress(tags),
                latitude: lat,
                longitude: lon,
                phoneNumber: tags['phone'] ?? tags['contact:phone'],
                website: tags['website'] ?? tags['contact:website'],
                type: _determineTypeFromTags(tags),
                distanceKm: distance,
                isOpen: _determineOpenStatus(tags),
                openingHours: _parseOpeningHours(tags['opening_hours']),
                amenities: _parseAmenities(tags),
              ));
            }
          } catch (e) {
            print('Error processing element: $e');
            continue;
          }
        }
      } else {
        print('❌ Overpass API error: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error with Overpass API: $e');
    }

    // If no real data found, return empty list
    if (providers.isEmpty) {
      print('⚠️ No mental health providers found in OpenStreetMap data for this area');
    }

    // Remove duplicates and sort by distance
    final uniqueProviders = _removeDuplicates(providers);
    uniqueProviders.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    print('✅ Returning ${uniqueProviders.length} unique mental health providers');
    return uniqueProviders;
  }

  // Helper method to generate sample data when real data is not available
  Future<List<MentalHealthProvider>> _generateSampleProviders(
      double latitude,
      double longitude,
      double radiusKm
      ) async {
    final List<MentalHealthProvider> sampleProviders = [];
    final random = Random();

    final sampleData = [
      {
        'name': 'City Mental Health Clinic',
        'type': 'clinic',
        'phone': '+91-11-12345678',
        'website': 'https://citymentalhealth.com',
      },
      {
        'name': 'Dr. Sarah Psychology Center',
        'type': 'psychologist',
        'phone': '+91-11-87654321',
        'website': null,
      },
      {
        'name': 'Wellness Counseling Services',
        'type': 'counselor',
        'phone': '+91-11-11223344',
        'website': 'https://wellnesscounseling.com',
      },
      {
        'name': 'Mind Care Psychiatry Hospital',
        'type': 'psychiatrist',
        'phone': '+91-11-55667788',
        'website': 'https://mindcare.com',
      },
      {
        'name': 'Peaceful Therapy Center',
        'type': 'psychotherapist',
        'phone': '+91-11-99887766',
        'website': null,
      },
    ];

    for (int i = 0; i < sampleData.length; i++) {
      var sample = sampleData[i];

      // Generate coordinates within the specified radius
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radiusKm;

      // Convert to lat/lng offset
      final latOffset = (distance / 111.0) * cos(angle);
      final lngOffset = (distance / (111.0 * cos(latitude * pi / 180))) * sin(angle);

      final adjustedLat = latitude + latOffset;
      final adjustedLng = longitude + lngOffset;

      final actualDistance = MentalHealthProvider.calculateDistance(
          latitude, longitude, adjustedLat, adjustedLng
      );

      sampleProviders.add(MentalHealthProvider(
        placeId: 'sample_$i',
        name: sample['name'] as String,
        address: 'Sample Address, City',
        latitude: adjustedLat,
        longitude: adjustedLng,
        phoneNumber: sample['phone'] as String?,
        website: sample['website'] as String?,
        type: sample['type'] as String,
        distanceKm: actualDistance,
        isOpen: random.nextBool(),
        amenities: ['Parking Available', 'Wheelchair Accessible'],
      ));
    }

    return sampleProviders;
  }

  // Helper methods
  String _determineTypeFromTags(Map<String, dynamic> tags) {
    final healthcare = tags['healthcare']?.toString().toLowerCase() ?? '';
    final specialty = tags['healthcare:speciality']?.toString().toLowerCase() ?? '';
    final amenity = tags['amenity']?.toString().toLowerCase() ?? '';
    final name = tags['name']?.toString().toLowerCase() ?? '';

    if (healthcare.contains('psychiatrist') || specialty.contains('psychiatry') || name.contains('psychiatr')) {
      return 'psychiatrist';
    } else if (healthcare.contains('psychologist') || healthcare.contains('psychology') || name.contains('psycholog')) {
      return 'psychologist';
    } else if (healthcare.contains('counsell') || healthcare.contains('therapy') || name.contains('counsel') || name.contains('therapy')) {
      return 'counselor';
    } else if (healthcare.contains('psychotherap') || name.contains('psychotherap')) {
      return 'psychotherapist';
    } else if (amenity.contains('hospital') || name.contains('hospital')) {
      return 'hospital';
    } else if (amenity.contains('clinic') || name.contains('clinic')) {
      return 'clinic';
    }
    return 'clinic'; // default
  }

  String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];

    if (tags['addr:housenumber'] != null) parts.add(tags['addr:housenumber'].toString());
    if (tags['addr:street'] != null) parts.add(tags['addr:street'].toString());
    if (tags['addr:suburb'] != null) parts.add(tags['addr:suburb'].toString());
    if (tags['addr:city'] != null) parts.add(tags['addr:city'].toString());
    if (tags['addr:state'] != null) parts.add(tags['addr:state'].toString());
    if (tags['addr:postcode'] != null) parts.add(tags['addr:postcode'].toString());

    if (parts.isEmpty) {
      // Try to build from other available info
      if (tags['addr:full'] != null) return tags['addr:full'].toString();
      if (tags['address'] != null) return tags['address'].toString();
      return 'Address not available';
    }

    return parts.join(', ');
  }

  bool _determineOpenStatus(Map<String, dynamic> tags) {
    final openingHours = tags['opening_hours']?.toString();
    if (openingHours == null) return true; // Assume open if no info

    // Simple check - you can enhance this with proper opening hours parsing
    final now = DateTime.now();
    final currentHour = now.hour;

    // Basic heuristic: if it mentions "24/7" it's always open
    if (openingHours.contains('24/7')) return true;

    // Default assumption for business hours
    return currentHour >= 8 && currentHour < 18;
  }

  Map<String, dynamic>? _parseOpeningHours(dynamic openingHours) {
    if (openingHours == null) return null;
    return {'raw': openingHours.toString()};
  }

  List<String>? _parseAmenities(Map<String, dynamic> tags) {
    final amenities = <String>[];

    if (tags['wheelchair'] == 'yes') amenities.add('Wheelchair Accessible');
    if (tags['parking'] == 'yes' || tags['parking:disabled'] == 'yes') amenities.add('Parking Available');
    if (tags['internet_access'] == 'wlan' || tags['wifi'] == 'yes') amenities.add('WiFi');
    if (tags['emergency'] == 'yes') amenities.add('Emergency Services');
    if (tags['appointment'] == 'yes') amenities.add('Appointment Required');
    if (tags['payment:cash'] == 'yes') amenities.add('Cash Accepted');
    if (tags['payment:cards'] == 'yes') amenities.add('Cards Accepted');

    return amenities.isNotEmpty ? amenities : null;
  }

  List<MentalHealthProvider> _removeDuplicates(List<MentalHealthProvider> providers) {
    final Map<String, MentalHealthProvider> uniqueMap = {};

    for (var provider in providers) {
      // Create a unique key based on name and approximate location
      final key = '${provider.name.toLowerCase().trim()}_${provider.latitude.toStringAsFixed(4)}_${provider.longitude.toStringAsFixed(4)}';

      if (!uniqueMap.containsKey(key) ||
          (uniqueMap[key]!.distanceKm > provider.distanceKm)) {
        uniqueMap[key] = provider;
      }
    }

    return uniqueMap.values.toList();
  }
}

// Main Location Screen with integrated Overpass API
class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<MentalHealthProvider> _providers = [];
  List<Marker> _markers = [];
  bool _isLoading = true;
  bool _isLoadingProviders = false;
  String _statusMessage = 'Checking permissions...';
  final OverpassPlacesService _placesService = OverpassPlacesService();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _statusMessage = 'Checking location services...';
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = 'Location services are disabled. Please enable them.';
          _isLoading = false;
        });
        _showLocationServiceDialog();
        return;
      }

      setState(() {
        _statusMessage = 'Requesting location permission...';
      });

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = 'Location permission denied';
            _isLoading = false;
          });
          _showPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage = 'Location permission permanently denied';
          _isLoading = false;
        });
        _showPermissionDialog();
        return;
      }

      setState(() {
        _statusMessage = 'Getting your location...';
      });

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ).timeout(
        Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Location timeout - trying last known location...');
        },
      );

      setState(() {
        _currentPosition = position;
        _statusMessage = 'Location found! Searching providers...';
        _isLoading = false;
      });

      print('📍 Location found: ${position.latitude}, ${position.longitude}');
      await _searchProviders();

    } catch (e) {
      print('❌ Location error: $e');

      try {
        setState(() {
          _statusMessage = 'Trying last known location...';
        });

        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          setState(() {
            _currentPosition = lastPosition;
            _statusMessage = 'Using last known location...';
            _isLoading = false;
          });
          await _searchProviders();
          return;
        }
      } catch (e2) {
        print('❌ Last known position failed: $e2');
      }

      // Use default location (Delhi - change to your city)
      setState(() {
        _currentPosition = Position(
          latitude: 28.6139, // Delhi coordinates
          longitude: 77.2090,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _statusMessage = 'Using default location...';
        _isLoading = false;
      });

      await _searchProviders();
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2A2A),
        title: Text('Location Services Disabled', style: TextStyle(color: Colors.white)),
        content: Text(
          'Please enable location services to find nearby mental health providers.',
          style: TextStyle(color: Colors.grey.shade300),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: Text('Open Settings', style: TextStyle(color: Color(0xFF6A1B9A))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2A2A),
        title: Text('Location Permission Required', style: TextStyle(color: Colors.white)),
        content: Text(
          'This app needs location permission to find nearby mental health providers.',
          style: TextStyle(color: Colors.grey.shade300),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: Text('Open Settings', style: TextStyle(color: Color(0xFF6A1B9A))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _searchProviders() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoadingProviders = true;
    });

    try {
      print('🔍 Searching providers with Overpass API near: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

      final providers = await _placesService.findNearbyMentalHealthProviders(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: 10.0,
      );

      print('✅ Found ${providers.length} mental health providers');

      setState(() {
        _providers = providers;
        _isLoadingProviders = false;
      });

      _updateMarkers();

      if (providers.isNotEmpty) {
        _showSuccessSnackbar('Found ${providers.length} mental health providers nearby!');
      } else {
        _showInfoSnackbar('Sorry, we could not find any psychologists or mental health providers near your location. Try expanding your search area or check back later.');
      }

    } catch (e) {
      print('❌ Provider search error: $e');
      setState(() {
        _isLoadingProviders = false;
      });
      _showError('Error finding providers. Please check your internet connection and try again.');
    }
  }

  void _updateMarkers() {
    final markers = <Marker>[];

    // Current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.person, color: Colors.white, size: 25),
          ),
        ),
      );
    }

    // Provider markers
    for (var provider in _providers) {
      markers.add(
        Marker(
          point: LatLng(provider.latitude, provider.longitude),
          width: 45,
          height: 45,
          child: GestureDetector(
            onTap: () => _showProviderDetails(provider),
            child: Container(
              decoration: BoxDecoration(
                color: _getProviderColor(provider.type),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _getProviderColor(provider.type).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                _getProviderIcon(provider.type),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  Color _getProviderColor(String type) {
    switch (type) {
      case 'psychiatrist':
        return Color(0xFF6A1B9A);
      case 'psychologist':
        return Color(0xFF8E24AA);
      case 'counselor':
        return Color(0xFFAB47BC);
      case 'clinic':
        return Color(0xFF4A148C);
      case 'hospital':
        return Color(0xFF7B1FA2);
      case 'psychotherapist':
        return Color(0xFF9C27B0);
      default:
        return Color(0xFF7B1FA2);
    }
  }

  IconData _getProviderIcon(String type) {
    switch (type) {
      case 'psychiatrist':
        return Icons.medical_services;
      case 'psychologist':
        return Icons.psychology;
      case 'counselor':
        return Icons.support_agent;
      case 'clinic':
        return Icons.local_hospital;
      case 'hospital':
        return Icons.local_hospital;
      case 'psychotherapist':
        return Icons.healing;
      default:
        return Icons.healing;
    }
  }

  void _showProviderDetails(MentalHealthProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_getProviderColor(provider.type), _getProviderColor(provider.type).withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getProviderIcon(provider.type),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                provider.typeDisplayName,
                                style: TextStyle(
                                  color: _getProviderColor(provider.type),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Status and distance
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: provider.isOpen ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            provider.isOpen ? 'Open' : 'Closed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.location_on, color: Color(0xFF6A1B9A), size: 20),
                        SizedBox(width: 4),
                        Text(
                          provider.distanceText,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Address
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined, color: Colors.grey.shade400),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              provider.address,
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (provider.phoneNumber != null) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.phone, color: Colors.grey.shade400),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                provider.phoneNumber!,
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (provider.website != null) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.language, color: Colors.grey.shade400),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                provider.website!,
                                style: TextStyle(color: Color(0xFF6A1B9A), fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Amenities
                    if (provider.amenities != null && provider.amenities!.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        'Amenities',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.amenities!.map((amenity) => Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFF6A1B9A).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Color(0xFF6A1B9A), width: 1),
                          ),
                          child: Text(
                            amenity,
                            style: TextStyle(
                              color: Color(0xFF6A1B9A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],

                    Spacer(),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6A1B9A),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _openDirections(provider),
                            icon: Icon(Icons.directions),
                            label: Text('Directions'),
                          ),
                        ),
                        if (provider.phoneNumber != null) ...[
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF00BFA5),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _makePhoneCall(provider.phoneNumber!),
                              icon: Icon(Icons.phone),
                              label: Text('Call'),
                            ),
                          ),
                        ],
                        if (provider.website != null) ...[
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2196F3),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _openWebsite(provider.website!),
                              icon: Icon(Icons.language),
                              label: Text('Website'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDirections(MentalHealthProvider provider) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${provider.latitude},${provider.longitude}';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not open directions');
      }
    } catch (e) {
      _showError('Error opening directions: $e');
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _showError('Could not make phone call');
      }
    } catch (e) {
      _showError('Error making phone call: $e');
    }
  }

  void _openWebsite(String website) async {
    try {
      if (await canLaunchUrl(Uri.parse(website))) {
        await launchUrl(Uri.parse(website), mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not open website');
      }
    } catch (e) {
      _showError('Error opening website: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showInfoSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Color(0xFF6A1B9A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: Color(0xFF6A1B9A),
          title: Text('Find Mental Health Providers', style: TextStyle(color: Colors.white)),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_searching, color: Colors.white, size: 50),
              ),
              SizedBox(height: 30),
              CircularProgressIndicator(color: Color(0xFF6A1B9A), strokeWidth: 3),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _statusMessage,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _initializeLocation,
                child: Text('Retry Location'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: Stack(
        children: [
          // Map
          if (_currentPosition != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                initialZoom: 13.0,
                maxZoom: 18.0,
                minZoom: 5.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.cognify',
                  maxZoom: 19,
                ),
                MarkerLayer(markers: _markers),
              ],
            ),

          // Header
          SafeArea(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mental Health Providers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'OpenStreetMap • FREE • Within 10km',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingProviders)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_providers.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Provider type legend
          if (_providers.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 120,
              left: 16,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF6A1B9A), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Legend',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ..._getLegendItems(),
                  ],
                ),
              ),
            ),

          // Floating action buttons
          Positioned(
            bottom: 30,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "refresh",
                  onPressed: _isLoadingProviders ? null : _searchProviders,
                  backgroundColor: Color(0xFF6A1B9A),
                  child: _isLoadingProviders
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Icon(Icons.refresh, color: Colors.white),
                ),
                SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: "center",
                  onPressed: () {
                    if (_currentPosition != null) {
                      _mapController.move(
                        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        13.0,
                      );
                    }
                  },
                  backgroundColor: Color(0xFF00BFA5),
                  child: Icon(Icons.my_location, color: Colors.white),
                ),
                SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: "list",
                  onPressed: () => _showProvidersList(),
                  backgroundColor: Color(0xFF2196F3),
                  child: Icon(Icons.list, color: Colors.white),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoadingProviders)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFF1A1A1A).withOpacity(0.9),
                      Color(0xFF1A1A1A).withOpacity(0.0),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFF6A1B9A),
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Searching mental health providers...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _getLegendItems() {
    final uniqueTypes = _providers.map((p) => p.type).toSet().toList();
    return uniqueTypes.map((type) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getProviderColor(type),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(
              _getTypeDisplayName(type),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'psychiatrist':
        return 'Psychiatrist';
      case 'psychologist':
        return 'Psychologist';
      case 'counselor':
        return 'Counselor';
      case 'clinic':
        return 'Clinic';
      case 'hospital':
        return 'Hospital';
      case 'psychotherapist':
        return 'Therapist';
      default:
        return 'Provider';
    }
  }

  void _showProvidersList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.list, color: Color(0xFF6A1B9A)),
                  SizedBox(width: 12),
                  Text(
                    'All Mental Health Providers (${_providers.length})',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _providers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 64,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No providers found',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Sorry, we could not find any psychologists or mental health providers near your location.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6A1B9A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _searchProviders();
                      },
                      child: Text('Refresh Search'),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: _providers.length,
                itemBuilder: (context, index) {
                  final provider = _providers[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getProviderColor(provider.type),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getProviderIcon(provider.type),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        provider.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            provider.typeDisplayName,
                            style: TextStyle(
                              color: _getProviderColor(provider.type),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            provider.distanceText,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey.shade600,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showProviderDetails(provider);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}






// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'dart:math';
//
// // Mental Health Provider Model
// class MentalHealthProvider {
//   final String placeId;
//   final String name;
//   final String address;
//   final double latitude;
//   final double longitude;
//   final String? phoneNumber;
//   final String? website;
//   final double? rating;
//   final String type;
//   final double distanceKm;
//   final bool isOpen;
//
//   MentalHealthProvider({
//     required this.placeId,
//     required this.name,
//     required this.address,
//     required this.latitude,
//     required this.longitude,
//     this.phoneNumber,
//     this.website,
//     this.rating,
//     required this.type,
//     required this.distanceKm,
//     required this.isOpen,
//   });
//
//   static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
//     const double earthRadius = 6371;
//     final double dLat = (lat2 - lat1) * (pi / 180);
//     final double dLng = (lng2 - lng1) * (pi / 180);
//     final double a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
//             sin(dLng / 2) * sin(dLng / 2);
//     final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     return earthRadius * c;
//   }
//
//   String get typeDisplayName {
//     switch (type) {
//       case 'psychiatrist':
//         return 'Psychiatrist';
//       case 'psychologist':
//         return 'Psychologist';
//       case 'counselor':
//         return 'Counselor';
//       case 'clinic':
//         return 'Mental Health Clinic';
//       default:
//         return 'Mental Health Provider';
//     }
//   }
//
//   String get distanceText => '${distanceKm.toStringAsFixed(1)} km away';
// }
//
// // Enhanced Internet-Based Places Service
// class InternetPlacesService {
//   // Sample mental health providers data
//   static final List<Map<String, dynamic>> _sampleProviders = [
//     {
//       'name': 'Mind Wellness Clinic',
//       'type': 'clinic',
//       'address': 'Mental Health Street, Delhi',
//       'phone': '+91-11-12345678',
//       'website': 'https://mindwellness.com',
//       'rating': 4.5,
//     },
//     {
//       'name': 'Dr. Sharma Psychology Center',
//       'type': 'psychologist',
//       'address': 'Wellness Avenue, Delhi',
//       'phone': '+91-11-87654321',
//       'rating': 4.2,
//     },
//     {
//       'name': 'Peace of Mind Counseling',
//       'type': 'counselor',
//       'address': 'Therapy Lane, Delhi',
//       'phone': '+91-11-11223344',
//       'rating': 4.7,
//     },
//     {
//       'name': 'Serenity Mental Health Hospital',
//       'type': 'clinic',
//       'address': 'Healthcare District, Delhi',
//       'phone': '+91-11-55667788',
//       'rating': 4.3,
//     },
//     {
//       'name': 'Dr. Priya Counseling Services',
//       'type': 'counselor',
//       'address': 'Wellness Complex, Delhi',
//       'phone': '+91-11-99887766',
//       'rating': 4.8,
//     },
//   ];
//
//   Future<List<MentalHealthProvider>> findNearbyMentalHealthProviders({
//     required double latitude,
//     required double longitude,
//     double radiusKm = 10.0,
//   }) async {
//     List<MentalHealthProvider> allProviders = [];
//
//     try {
//       // Generate sample providers near location
//       final sampleProviders = await _getSampleProvidersNearLocation(latitude, longitude, radiusKm);
//       allProviders.addAll(sampleProviders);
//
//       print('Generated ${allProviders.length} providers near location');
//
//     } catch (e) {
//       print('Error in provider search: $e');
//     }
//
//     // Remove duplicates and sort by distance
//     final uniqueProviders = <String, MentalHealthProvider>{};
//     for (var provider in allProviders) {
//       final key = '${provider.name}_${provider.latitude}_${provider.longitude}';
//       if (!uniqueProviders.containsKey(key)) {
//         uniqueProviders[key] = provider;
//       }
//     }
//
//     final result = uniqueProviders.values.toList();
//     result.sort((a, bsample) => a.distanceKm.compareTo(b.distanceKm));
//
//     return result;
//   }
//
//   Future<List<MentalHealthProvider>> _getSampleProvidersNearLocation(
//       double latitude,
//       double longitude,
//       double radiusKm
//       ) async {
//     List<MentalHealthProvider> providers = [];
//     final random = Random();
//
//     for (int i = 0; i < _sampleProviders.length; i++) {
//       var sample = _sampleProviders[i];
//
//       // Generate coordinates within the specified radius
//       final angle = random.nextDouble() * 2 * pi;
//       final distance = random.nextDouble() * radiusKm;
//
//       // Convert to lat/lng offset
//       final latOffset = (distance / 111.0) * cos(angle); // ~111km per degree lat
//       final lngOffset = (distance / (111.0 * cos(latitude * pi / 180))) * sin(angle);
//
//       final adjustedLat = latitude + latOffset;
//       final adjustedLng = longitude + lngOffset;
//
//       final actualDistance = MentalHealthProvider.calculateDistance(
//           latitude, longitude, adjustedLat, adjustedLng
//       );
//
//       if (actualDistance <= radiusKm) {
//         providers.add(MentalHealthProvider(
//           placeId: 'sample_$i',
//           name: sample['name'],
//           address: sample['address'],
//           latitude: adjustedLat,
//           longitude: adjustedLng,
//           phoneNumber: sample['phone'],
//           website: sample['website'],
//           rating: sample['rating']?.toDouble(),
//           type: sample['type'],
//           distanceKm: actualDistance,
//           isOpen: random.nextBool(),
//         ));
//       }
//     }
//
//     return providers;
//   }
// }
//
// // Main Location Screen
// class LocationScreen extends StatefulWidget {
//   @override
//   _LocationScreenState createState() => _LocationScreenState();
// }
//
// class _LocationScreenState extends State<LocationScreen> {
//   final MapController _mapController = MapController();
//   Position? _currentPosition;
//   List<MentalHealthProvider> _providers = [];
//   List<Marker> _markers = [];
//   bool _isLoading = true;
//   bool _isLoadingProviders = false;
//   String _statusMessage = 'Checking permissions...';
//   final InternetPlacesService _placesService = InternetPlacesService();
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeLocation();
//   }
//
//   Future<void> _initializeLocation() async {
//     try {
//       setState(() {
//         _statusMessage = 'Checking location services...';
//       });
//
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         setState(() {
//           _statusMessage = 'Location services are disabled. Please enable them.';
//           _isLoading = false;
//         });
//         _showLocationServiceDialog();
//         return;
//       }
//
//       setState(() {
//         _statusMessage = 'Requesting location permission...';
//       });
//
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           setState(() {
//             _statusMessage = 'Location permission denied';
//             _isLoading = false;
//           });
//           _showPermissionDialog();
//           return;
//         }
//       }
//
//       if (permission == LocationPermission.deniedForever) {
//         setState(() {
//           _statusMessage = 'Location permission permanently denied';
//           _isLoading = false;
//         });
//         _showPermissionDialog();
//         return;
//       }
//
//       setState(() {
//         _statusMessage = 'Getting your location...';
//       });
//
//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: Duration(seconds: 15),
//       ).timeout(
//         Duration(seconds: 20),
//         onTimeout: () {
//           throw Exception('Location timeout - trying last known location...');
//         },
//       );
//
//       setState(() {
//         _currentPosition = position;
//         _statusMessage = 'Location found! Searching providers...';
//         _isLoading = false;
//       });
//
//       print('📍 Location found: ${position.latitude}, ${position.longitude}');
//       await _searchProviders();
//
//     } catch (e) {
//       print('❌ Location error: $e');
//
//       try {
//         setState(() {
//           _statusMessage = 'Trying last known location...';
//         });
//
//         final lastPosition = await Geolocator.getLastKnownPosition();
//         if (lastPosition != null) {
//           setState(() {
//             _currentPosition = lastPosition;
//             _statusMessage = 'Using last known location...';
//             _isLoading = false;
//           });
//           await _searchProviders();
//           return;
//         }
//       } catch (e2) {
//         print('❌ Last known position failed: $e2');
//       }
//
//       // Use default location (change coordinates to your city)
//       setState(() {
//         _currentPosition = Position(
//           latitude: 28.6139, // Delhi - change to your city
//           longitude: 77.2090,
//           timestamp: DateTime.now(),
//           accuracy: 0,
//           altitude: 0,
//           altitudeAccuracy: 0,
//           heading: 0,
//           headingAccuracy: 0,
//           speed: 0,
//           speedAccuracy: 0,
//         );
//         _statusMessage = 'Using default location...';
//         _isLoading = false;
//       });
//
//       await _searchProviders();
//     }
//   }
//
//   void _showLocationServiceDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Color(0xFF2A2A2A),
//         title: Text('Location Services Disabled', style: TextStyle(color: Colors.white)),
//         content: Text(
//           'Please enable location services to find nearby mental health providers.',
//           style: TextStyle(color: Colors.grey.shade300),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Geolocator.openLocationSettings();
//             },
//             child: Text('Open Settings', style: TextStyle(color: Color(0xFF6A1B9A))),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.pop(context);
//             },
//             child: Text('Cancel', style: TextStyle(color: Colors.grey)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showPermissionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Color(0xFF2A2A2A),
//         title: Text('Location Permission Required', style: TextStyle(color: Colors.white)),
//         content: Text(
//           'This app needs location permission to find nearby mental health providers.',
//           style: TextStyle(color: Colors.grey.shade300),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Geolocator.openAppSettings();
//             },
//             child: Text('Open Settings', style: TextStyle(color: Color(0xFF6A1B9A))),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.pop(context);
//             },
//             child: Text('Cancel', style: TextStyle(color: Colors.grey)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _searchProviders() async {
//     if (_currentPosition == null) return;
//
//     setState(() {
//       _isLoadingProviders = true;
//     });
//
//     try {
//       print('🔍 Searching providers near: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
//
//       final providers = await _placesService.findNearbyMentalHealthProviders(
//         latitude: _currentPosition!.latitude,
//         longitude: _currentPosition!.longitude,
//         radiusKm: 10.0,
//       );
//
//       print('✅ Found ${providers.length} providers');
//
//       setState(() {
//         _providers = providers;
//         _isLoadingProviders = false;
//       });
//
//       _updateMarkers();
//
//     } catch (e) {
//       print('❌ Provider search error: $e');
//       setState(() {
//         _isLoadingProviders = false;
//       });
//       _showError('Error finding providers: $e');
//     }
//   }
//
//   void _updateMarkers() {
//     final markers = <Marker>[];
//
//     // Current location marker
//     if (_currentPosition != null) {
//       markers.add(
//         Marker(
//           point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
//           width: 50,
//           height: 50,
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.blue,
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.white, width: 3),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.blue.withOpacity(0.3),
//                   blurRadius: 10,
//                   spreadRadius: 2,
//                 ),
//               ],
//             ),
//             child: Icon(Icons.person, color: Colors.white, size: 25),
//           ),
//         ),
//       );
//     }
//
//     // Provider markers
//     for (var provider in _providers) {
//       markers.add(
//         Marker(
//           point: LatLng(provider.latitude, provider.longitude),
//           width: 45,
//           height: 45,
//           child: GestureDetector(
//             onTap: () => _showProviderDetails(provider),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: _getProviderColor(provider.type),
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.white, width: 2),
//                 boxShadow: [
//                   BoxShadow(
//                     color: _getProviderColor(provider.type).withOpacity(0.4),
//                     blurRadius: 8,
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               child: Icon(
//                 _getProviderIcon(provider.type),
//                 color: Colors.white,
//                 size: 20,
//               ),
//             ),
//           ),
//         ),
//       );
//     }
//
//     setState(() {
//       _markers = markers;
//     });
//   }
//
//   Color _getProviderColor(String type) {
//     switch (type) {
//       case 'psychiatrist':
//         return Color(0xFF6A1B9A);
//       case 'psychologist':
//         return Color(0xFF8E24AA);
//       case 'counselor':
//         return Color(0xFFAB47BC);
//       case 'clinic':
//         return Color(0xFF4A148C);
//       default:
//         return Color(0xFF7B1FA2);
//     }
//   }
//
//   IconData _getProviderIcon(String type) {
//     switch (type) {
//       case 'psychiatrist':
//         return Icons.medical_services;
//       case 'psychologist':
//         return Icons.psychology;
//       case 'counselor':
//         return Icons.support_agent;
//       case 'clinic':
//         return Icons.local_hospital;
//       default:
//         return Icons.healing;
//     }
//   }
//
//   void _showProviderDetails(MentalHealthProvider provider) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.6,
//         decoration: BoxDecoration(
//           color: Color(0xFF1A1A1A),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           children: [
//             Container(
//               margin: EdgeInsets.symmetric(vertical: 12),
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade600,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Provider header
//                     Row(
//                       children: [
//                         Container(
//                           padding: EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
//                             ),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Icon(
//                             _getProviderIcon(provider.type),
//                             color: Colors.white,
//                             size: 24,
//                           ),
//                         ),
//                         SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 provider.name,
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               SizedBox(height: 4),
//                               Text(
//                                 provider.typeDisplayName,
//                                 style: TextStyle(
//                                   color: Color(0xFF6A1B9A),
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     SizedBox(height: 20),
//
//                     // Rating and distance
//                     Row(
//                       children: [
//                         if (provider.rating != null) ...[
//                           Icon(Icons.star, color: Colors.orange, size: 20),
//                           SizedBox(width: 4),
//                           Text(
//                             provider.rating!.toStringAsFixed(1),
//                             style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//                           ),
//                           SizedBox(width: 20),
//                         ],
//                         Icon(Icons.location_on, color: Color(0xFF6A1B9A), size: 20),
//                         SizedBox(width: 4),
//                         Text(
//                           provider.distanceText,
//                           style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
//                         ),
//                       ],
//                     ),
//
//                     SizedBox(height: 16),
//
//                     // Address
//                     Container(
//                       padding: EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Color(0xFF2A2A2A),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Icon(Icons.location_on_outlined, color: Colors.grey.shade400),
//                           SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               provider.address,
//                               style: TextStyle(color: Colors.white, fontSize: 14),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     if (provider.phoneNumber != null) ...[
//                       SizedBox(height: 12),
//                       Container(
//                         padding: EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Color(0xFF2A2A2A),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(Icons.phone, color: Colors.grey.shade400),
//                             SizedBox(width: 12),
//                             Text(
//                               provider.phoneNumber!,
//                               style: TextStyle(color: Colors.white, fontSize: 14),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//
//                     Spacer(),
//
//                     // Action buttons
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton.icon(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Color(0xFF6A1B9A),
//                               foregroundColor: Colors.white,
//                               padding: EdgeInsets.symmetric(vertical: 12),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             onPressed: () => _openDirections(provider),
//                             icon: Icon(Icons.directions),
//                             label: Text('Directions'),
//                           ),
//                         ),
//                         if (provider.phoneNumber != null) ...[
//                           SizedBox(width: 12),
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Color(0xFF00BFA5),
//                                 foregroundColor: Colors.white,
//                                 padding: EdgeInsets.symmetric(vertical: 12),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                               ),
//                               onPressed: () => _makePhoneCall(provider.phoneNumber!),
//                               icon: Icon(Icons.phone),
//                               label: Text('Call'),
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _openDirections(MentalHealthProvider provider) async {
//     final url = 'https://www.google.com/maps/dir/?api=1&destination=${provider.latitude},${provider.longitude}';
//     if (await canLaunchUrl(Uri.parse(url))) {
//       await launchUrl(Uri.parse(url));
//     }
//   }
//
//   void _makePhoneCall(String phoneNumber) async {
//     final url = 'tel:$phoneNumber';
//     if (await canLaunchUrl(Uri.parse(url))) {
//       await launchUrl(Uri.parse(url));
//     }
//   }
//
//   void _showError(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message), backgroundColor: Colors.red),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: Color(0xFF1A1A1A),
//         appBar: AppBar(
//           backgroundColor: Color(0xFF6A1B9A),
//           title: Text('Find Providers', style: TextStyle(color: Colors.white)),
//           iconTheme: IconThemeData(color: Colors.white),
//         ),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(color: Color(0xFF6A1B9A)),
//               SizedBox(height: 20),
//               Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 40),
//                 child: Text(
//                   _statusMessage,
//                   style: TextStyle(color: Colors.white, fontSize: 16),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//               SizedBox(height: 30),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xFF6A1B9A),
//                   foregroundColor: Colors.white,
//                   padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 ),
//                 onPressed: _initializeLocation,
//                 child: Text('Retry Location'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: Color(0xFF1A1A1A),
//       body: Stack(
//         children: [
//           // Map
//           if (_currentPosition != null)
//             FlutterMap(
//               mapController: _mapController,
//               options: MapOptions(
//                 initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
//                 initialZoom: 13.0,
//                 maxZoom: 18.0,
//                 minZoom: 5.0,
//               ),
//               children: [
//                 TileLayer(
//                   urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//                   userAgentPackageName: 'com.example.cognify',
//                   maxZoom: 19,
//                 ),
//                 MarkerLayer(markers: _markers),
//               ],
//             ),
//
//           // Header
//           SafeArea(
//             child: Container(
//               margin: EdgeInsets.all(16),
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black26,
//                     blurRadius: 10,
//                     offset: Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   GestureDetector(
//                     onTap: () => Navigator.pop(context),
//                     child: Container(
//                       padding: EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(Icons.arrow_back, color: Colors.white),
//                     ),
//                   ),
//                   SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           'Mental Health Providers',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           'Within 10km • FREE',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.9),
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   if (_isLoadingProviders)
//                     SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: 2,
//                       ),
//                     )
//                   else
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         '${_providers.length}',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Floating action buttons
//           Positioned(
//             bottom: 30,
//             right: 16,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 FloatingActionButton(
//                   heroTag: "refresh",
//                   onPressed: _searchProviders,
//                   backgroundColor: Color(0xFF6A1B9A),
//                   child: Icon(Icons.refresh, color: Colors.white),
//                 ),
//                 SizedBox(height: 12),
//                 FloatingActionButton(
//                   heroTag: "center",
//                   onPressed: () {
//                     if (_currentPosition != null) {
//                       _mapController.move(
//                         LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
//                         13.0,
//                       );
//                     }
//                   },
//                   backgroundColor: Color(0xFF00BFA5),
//                   child: Icon(Icons.my_location, color: Colors.white),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
