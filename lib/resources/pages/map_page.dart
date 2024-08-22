import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
// import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
// import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

import '../../app/networking/user_api_service.dart';

// import 'package:location/location.dart';

class MapPage extends NyStatefulWidget {
  static const path = '/map';

  MapPage({super.key}) : super(path, child: _MapPageState());
}

class _MapPageState extends NyState<MapPage> {
  late MapController _mapController;
  // final Location location = Location();
  // LatLng? currentLocation;
  // List<Marker> markers = [];

  Random random = new Random();
  // List<Marker> _markers = [];
  // double minLat = -90.0;
  // double maxLat = 90.0;
  // double minLong = -180.0;
  // double maxLong = 180.0;
  List<Marker> _userMarkers = [];

  // @override
  // void initState() {
  //   super.initState();
  //   _mapController = MapController();
  //   _initializeMarker();
  //   startMovingMarker();
  //   // _updateLocation();
  // }

  // Future<void> _initializeMarker() async {
  //   setState(() {
  //     _markers.add(
  //       Marker(
  //         width: 80.0,
  //         height: 80.0,
  //         point: LatLng(28.3949, 84.1240), // Initial position
  //         child: Container(
  //           child: Icon(
  //             Icons.pin_drop,
  //             color: Colors.red,
  //           ),
  //         ),
  //       ),
  //     );
  //   });
  // }

  // void startMovingMarker() {
  //   Timer.periodic(Duration(seconds: 1), (Timer t) {
  //     _moveMarker(LatLng(nextDoubleInRange(minLat, maxLat),
  //         nextDoubleInRange(minLong, maxLong)));
  //   });
  // }

  // double nextDoubleInRange(double min, double max) {
  //   return min + random.nextDouble() * (max - min);
  // }

  // void _moveMarker(LatLng newPosition) {
  //   setState(() {
  //     LatLng currentPosition = _markers[0].point;
  //     LatLng newPosition = LatLng(currentPosition.latitude + 0.00009,
  //         currentPosition.longitude + 0.00009);

  //     _markers[0] = Marker(
  //       width: 80.0,
  //       height: 80.0,
  //       point: newPosition,
  //       child: Container(
  //         child: IconButton(
  //           icon: Icon(
  //             Icons.bus_alert_outlined,
  //             color: Colors.red,
  //           ), // Replace this with your icon
  //           onPressed: () {
  //             showDialog(
  //               context: context,
  //               builder: (BuildContext context) {
  //                 return AlertDialog(
  //                   backgroundColor: const Color.fromARGB(28, 0, 0, 0),
  //                   title: Text('Bus Details'),
  //                   content: Column(
  //                     children: <Widget>[
  //                       Text(
  //                           'Latitude: ${currentPosition.latitude}'), // Replace with your latitude
  //                       Text(
  //                           'Longitude: ${currentPosition.longitude}'), // Replace with your longitude
  //                       // Add more details here
  //                     ],
  //                   ),
  //                   actions: <Widget>[
  //                     TextButton(
  //                       child: Text('Close'),
  //                       onPressed: () {
  //                         Navigator.of(context).pop();
  //                       },
  //                     ),
  //                   ],
  //                 );
  //               },
  //             );
  //           },
  //         ),
  //       ),
  //     );
  //   });
  // }

  List<Marker> _markers = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchMarkers();
    _startFetchingMarkers();
  }

  void _startFetchingMarkers() {
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _fetchMarkers();
    });
  }

  Future<void> _fetchMarkers() async {
    try {
      var response =
          await api<UserApiService>((request) => request.buscoordinates());
      print('Response: $response');
      List<dynamic> data = response;

      List<Marker> markers = data.map((item) {
        return Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(item['lat'], item['lng']),
          child: Container(
            child: IconButton(
              icon: Icon(
                Icons.bus_alert_outlined,
                color: Colors.red,
              ), // Replace this with your icon
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: const Color.fromARGB(28, 0, 0, 0),
                      title: Text('Bus Details'),
                      content: Container(
                        width: 300.0,
                        height: 200.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text('Bus No: ${item['gps_uid']}'),
                            Text('Latitude: ${item['lat']}'),
                            Text('Longitude: ${item['lng']}'),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Close'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      }).toList();

      setState(() {
        _markers = markers;
      });
    } catch (e) {
      print("Error fetching markers: $e");
    }
  }

  Future<void> _updateLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
      setState(() {
        _userMarkers.clear();
        _userMarkers.add(Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(position.latitude, position.longitude),
            child: const Icon(
              Icons.circle_sharp,
              color: Colors.blue,
              size: 20,
            )));
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget view(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(27.673163, 85.384712),
              initialZoom: 13,
              // onTap: (_, latLng) => _onMapTap(latLng),
            ),
            // Move the layers inside MapOptions
            children: [
              TileLayer(
                // tileProvider: FileTileProvider(),
                urlTemplate: getEnv('MAP_URL'),
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: [..._userMarkers, ..._markers]),
              // PolylineLayer(
              //   polylines: [
              //     Polyline(
              //         points: _routePoints, strokeWidth: 4, color: Colors.blue),
              //   ],
              // ),
            ],
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateLocation,
        child: Icon(Icons.location_searching),
      ),
    );
  }
}
