import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'show_data.dart'; // Import หน้า showdata.dart

void main() {
  runApp(const MapWidget());
}

class MapWidget extends StatefulWidget {
  const MapWidget({Key? key}) : super(key: key);

  @override
  State<MapWidget> createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
  late MapController _mapController;
  double _currentZoom = 13.0;
  List<Marker> _markers = [];
  List<String> _selectedSides = [];
  List<String> _sides = [];
  bool _isExpanded = true; // สถานะการพับข้อมูล
  List<LatLng> _selectedPoints = [];
  List<LatLng> _routePoints = []; //
  // ignore: unused_field
  LatLng? _selectedLocation; // ตำแหน่งที่ผู้ใช้เลือก
  bool _isAddingMarker = false; // สถานะสำหรับการเพิ่ม Marker
  List<Polyline> _lines = []; // ประกาศลิสต์ของ Polyline
  String _searchQuery = ''; // ตัวแปรสำหรับคำค้นหา
  List<String> _suggestions = []; // ตัวแปรใหม่สำหรับเก็บคำแนะนำ
  List<dynamic> _mapData = [];
  final TextEditingController _searchController = TextEditingController();

  final Map<String, Color> _sideColors = {
    'โชคลาภ': const Color.fromARGB(255, 228, 210, 54),
    'ความรัก': Colors.pink,
    'สุขภาพ': Colors.green,
    'การเดินทาง': Colors.blue,
    'เสริมดวง': Colors.orange,
    'การงาน': Colors.teal,
  };

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    print("Fetching map data..."); // ตรวจสอบว่า initState ถูกเรียก
    _fetchMapData();
  }

  Future<void> _fetchMapData() async {
    const String url = 'http://192.168.56.1:3001/maps'; // URL API
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _sides = data
            .map<String>((mapData) => mapData['side'] as String)
            .toSet()
            .toList();
        _mapData = data;
        _updateMarkers(data);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  void _updateMarkers(List<dynamic> data) {
    setState(() {
      _markers = data
          .where((mapData) =>
              (_selectedSides.isEmpty ||
                  _selectedSides.contains(mapData['side'])) &&
              (mapData['namelocation']
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))
          .map<Marker>((mapData) {
        Color markerColor = _sideColors[mapData['side']] ?? Colors.black;
        return Marker(
          width: 80.0,
          height: 80.0,
          point: LatLng(mapData['latitude'], mapData['longitude']),
          builder: (ctx) => GestureDetector(
            onTap: () {
              _showMarkerInfo(context, mapData);
            },
            child: Icon(
              Icons.location_on,
              color: markerColor,
              size: 40,
            ),
          ),
        );
      }).toList();
    });
  }

  void _updateSuggestions() {
    setState(() {
      _suggestions = _mapData
          .where((mapData) => mapData['namelocation']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .map<String>((mapData) => mapData['namelocation'])
          .toList();
    });
  }

  void _showMarkerInfo(BuildContext context, dynamic mapData) {
    int index =
        _selectedPoints.length + 1; // ใช้จำนวนจุดที่เลือกในการแสดงหมายเลข
    String displayText = index == 1
        ? 'จุดเริ่มต้น'
        : 'จุดหมายที่: $index'; // เปลี่ยนข้อความที่แสดง

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 199, 253, 203),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  mapData['namelocation'] ?? 'Unknown Location',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mapData['Image1'] != null && mapData['Image1'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Image.network(
                      mapData['Image1'],
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 10),
                _buildTextInfo('พรที่อยากขอ: ', mapData['side'] ?? 'N/A'),
                _buildTextInfo('เวลาเปิด-ปิด: ', mapData['time'] ?? 'N/A'),
                _buildTextInfo('พิกัด: ', mapData['location'] ?? 'N/A'),
                const SizedBox(height: 10),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ShowDataPage(namelocation: mapData['namelocation']),
                  ),
                );
              },
              child: const Text(
                'ดูข้อมูล',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            // แสดงปุ่มยกเลิกหรือเลือกจุดขึ้นอยู่กับสถานะ
            if (_selectedPoints.any((point) =>
                point.latitude == mapData['latitude'] &&
                point.longitude == mapData['longitude']))
              TextButton(
                onPressed: () {
                  _cancelDestination(mapData); // เรียกฟังก์ชันยกเลิก
                  Navigator.of(context).pop(); // ปิด Popup
                },
                child: Text(
                  _selectedPoints.firstWhere((point) =>
                              point.latitude == mapData['latitude'] &&
                              point.longitude == mapData['longitude']) ==
                          _selectedPoints.first
                      ? 'ยกเลิกจุดเริ่มต้น' // ถ้าเป็นจุดเริ่มต้น
                      : 'ยกเลิกจุดหมายที่: ${_selectedPoints.indexOf(_selectedPoints.firstWhere((point) => point.latitude == mapData['latitude'] && point.longitude == mapData['longitude'])) + 1}', // ถ้าเป็นจุดหมายที่...
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red),
                ),
              )
            else
              TextButton(
                onPressed: () {
                  _selectPoint(mapData);
                  Navigator.of(context).pop(); // ปิด Popup ปัจจุบัน
                  _showSelectedPointPopup(context, displayText);
                },
                child: Text(
                  displayText, // ใช้ข้อความที่เตรียมไว้
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showUserMarker(LatLng point) {
    // ตรวจสอบว่าจุดนี้เป็นจุดเริ่มต้นหรือไม่
    bool isStartPoint = _selectedPoints.isEmpty ||
        (_selectedPoints[0].latitude == point.latitude &&
            _selectedPoints[0].longitude == point.longitude);

    // คำนวณหมายเลขจุดหมาย
    int index = isStartPoint
        ? 1
        : _selectedPoints
            .length; // กำหนดให้จุดเริ่มต้นเป็น 1 และจุดหมายที่ตามมาจะเรียงตามจำนวนที่เลือก

    // กำหนดข้อความสำหรับยกเลิก
    String cancelText = isStartPoint
        ? 'ยกเลิกจุดเริ่มต้น'
        : 'ยกเลิกจุดหมายที่: ${index}'; // แสดงหมายเลขที่ถูกต้อง

    String selectText = isStartPoint
        ? 'เลือกจุดเริ่มต้น'
        : 'เลือกจุดหมายที่: ${index + 1}'; // แสดงหมายเลขที่ถูกต้อง

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ตำแหน่งที่คุณเลือก',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close), // ไอคอนกากบาท
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Latitude: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${point.latitude}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Longitude: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${point.longitude}'),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.delete), // ไอคอนถังขยะ
              onPressed: () {
                setState(() {
                  _markers.removeWhere((marker) => marker.point == point);
                });
                Navigator.of(context).pop();
              },
            ),
            // ตรวจสอบว่าพิกัดนี้ถูกเลือกไว้แล้วหรือไม่
            if (_selectedPoints.any((selectedPoint) =>
                selectedPoint.latitude == point.latitude &&
                selectedPoint.longitude == point.longitude))
              TextButton(
                onPressed: () {
                  // เรียกฟังก์ชันยกเลิกจุด
                  _cancelDestination({
                    'latitude': point.latitude,
                    'longitude': point.longitude,
                  });
                  Navigator.of(context).pop(); // ปิด popup
                },
                child: Text(
                  cancelText,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red),
                ),
              )
            else
              TextButton(
                onPressed: () {
                  // สร้าง mapData จากพิกัดที่เลือก
                  var mapData = {
                    'latitude': point.latitude,
                    'longitude': point.longitude,
                  };

                  // เรียกใช้งานฟังก์ชัน _selectPoint
                  _selectPoint(mapData);
                  Navigator.of(context).pop(); // ปิด Popup ปัจจุบัน

                  // แสดงข้อความจุดเริ่มต้นใน Popup ของการยืนยันจุด
                  _showSelectedPointPopup(context, selectText);
                },
                child: Text(
                  selectText, // ใช้ข้อความที่เหมาะสม
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        );
      },
    );
  }

  void _cancelDestination(dynamic mapData) {
    setState(() {
      // ลบพิกัดจาก _selectedPoints
      _selectedPoints.removeWhere((point) =>
          point.latitude == mapData['latitude'] &&
          point.longitude == mapData['longitude']);

      // ลบเส้นที่วาดจากแผนที่
      _removeLine(mapData);
    });
  }

  void _removeLine(dynamic mapData) {
    setState(() {
      // ลบเส้นจาก _lines หรือโครงสร้างข้อมูลที่คุณใช้
      _lines.removeWhere((line) {
        // ตรวจสอบว่าพิกัดเริ่มต้นหรือพิกัดสิ้นสุดตรงกับพิกัดใน mapData หรือไม่
        return (line.points.any((point) =>
            point.latitude == mapData['latitude'] &&
            point.longitude == mapData['longitude']));
      });
    });
  }

  void _selectPoint(dynamic mapData) {
    setState(() {
      // เพิ่มพิกัดลงใน _selectedPoints
      _selectedPoints.add(LatLng(mapData['latitude'], mapData['longitude']));

      // คำนวณเส้นทางเมื่อมีมากกว่า 1 จุด
      if (_selectedPoints.length > 1) {
        _getRoute(_selectedPoints);
      }
    });
  }

  void _showSelectedPointPopup(BuildContext context, String displayText) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 199, 253, 203),
          title: const Text(
            'กำหนดเส้นทางการเดินทาง',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Icon(
                Icons.location_on,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 10),
              Text(
                // ตรวจสอบว่าจุดที่เลือกคือจุดเริ่มต้นหรือไม่
                displayText == 'จุดเริ่มต้น'
                    ? 'กำหนดจุดเริ่มต้นแล้ว!!!'
                    : displayText,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center, // จัดข้อความให้อยู่กลาง
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ปิด Popup นี้
              },
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getRoute(List<LatLng> points) async {
    if (points.length < 2) return; // ต้องมีอย่างน้อย 2 จุด

    final waypoints =
        points.map((point) => '${point.longitude},${point.latitude}').join(';');
    final url =
        'https://router.project-osrm.org/route/v1/driving/$waypoints?overview=full&geometries=geojson';

    print('Requesting URL: $url'); // พิมพ์ URL ที่เรียกใช้

    try {
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}'); // พิมพ์ statusCode

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response body: ${response.body}'); // พิมพ์ response body

        final route = data['routes'][0]['geometry']['coordinates'] as List;

        setState(() {
          // แปลงข้อมูลเส้นที่ได้รับมาเป็น LatLng
          _routePoints =
              route.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();

          // เพิ่ม Polyline ใหม่ลงใน _lines
          _lines.add(Polyline(
            points: _routePoints,
            strokeWidth: 4.0,
            color: Colors.red,
          ));
        });
      } else {
        print(
            'Failed to load route. Status code: ${response.statusCode}'); // แสดงข้อผิดพลาดถ้าสถานะไม่ใช่ 200
        throw Exception('Failed to load route');
      }
    } catch (error) {
      print('Error fetching route: $error'); // แสดงข้อผิดพลาดที่จับได้
    }
  }

  Widget _buildTextInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectAllSides() {
    setState(() {
      if (_selectedSides.length == _sides.length) {
        _selectedSides.clear();
      } else {
        _selectedSides = List.from(_sides);
      }
      _fetchMapData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travelapp',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          color: Color.fromARGB(255, 81, 218, 152),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            "     แผนที่สถานที่ท่องเที่ยว",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 199, 253, 203),
        body: Stack(
          children: [
            // FlutterMap widget คลุมทั้งหน้า
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: LatLng(13.7563, 100.5018),
                zoom: _currentZoom,
                onTap: (tapPosition, point) {
                  setState(() {
                    if (_isAddingMarker) {
                      // ถ้าผู้ใช้เลือกโหมดเพิ่ม Marker
                      _markers.add(Marker(
                        width: 80.0,
                        height: 80.0,
                        point: point,
                        builder: (ctx) => GestureDetector(
                          onTap: () {
                            _showUserMarker(point);
                          },
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ));
                    } else {
                      _selectedLocation = point; // เก็บตำแหน่งที่ถูกคลิก
                    }
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.red,
                    ),
                  ],
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
            // ช่องค้นหาและแนะนำ
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // สีพื้นหลัง
                      borderRadius: BorderRadius.circular(30), // ขอบโค้ง
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // เงา
                          blurRadius: 5,
                          offset: const Offset(0, 2), // ตำแหน่งเงา
                        ),
                      ],
                    ),
                    child: TextField(
                      controller:
                          _searchController, // ใช้ Controller เพื่อควบคุมค่าในช่อง
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        _updateSuggestions();
                      },
                      decoration: const InputDecoration(
                        hintText: 'ค้นหาสถานที่...',
                        hintStyle: TextStyle(
                          color: Colors.black54, // สีตัวหนังสือ hint
                          fontWeight: FontWeight
                              .bold, // ทำให้ตัวหนังสือ hint เป็นตัวหนา
                        ),
                        filled: true, // เปิดใช้งานพื้นหลัง
                        fillColor: Colors.white, // สีพื้นหลัง
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                    ),
                  ),
                  if (_suggestions.isNotEmpty)
                    Positioned(
                      top: 60,
                      left: 16,
                      right: 16,
                      child: Container(
                        height:
                            145, 
                        decoration: BoxDecoration(
                          color: Colors.white, // สีพื้นหลัง
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics:
                              AlwaysScrollableScrollPhysics(), // เปิดการเลื่อนของ ListView
                          itemCount: _suggestions.length > 5
                              ? 5
                              : _suggestions.length, 
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                _suggestions[index],
                                style: TextStyle(
                                  color: Colors.black, // สีตัวหนังสือ
                                ),
                              ),
                              onTap: () {
                                // เมื่อผู้ใช้คลิกที่คำแนะนำ
                                String selectedLocation = _suggestions[index];
                                // กำหนดข้อความที่เลือกให้กับ TextField
                                _searchController.text = selectedLocation;

                                // ค้นหาตำแหน่งของ namelocation ที่เลือก
                                var selectedMapData = _mapData.firstWhere(
                                  (mapData) =>
                                      mapData['namelocation'] ==
                                      selectedLocation,
                                );

                                // เลื่อนแผนที่ไปที่ตำแหน่งของ Marker
                                _mapController.move(
                                  LatLng(selectedMapData['latitude'],
                                      selectedMapData['longitude']),
                                  15.0, // ระดับการซูม
                                );

                                setState(() {
                                  _searchQuery = selectedLocation;
                                  _suggestions
                                      .clear(); // ล้างคำแนะนำหลังจากเลือก
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 10), // เพิ่มช่องว่าง
                  Container(
                    padding: const EdgeInsets.all(10), // เพิ่มช่องว่างภายใน
                    margin:
                        const EdgeInsets.symmetric(horizontal: 2), // ขอบซ้ายขวา
                    decoration: BoxDecoration(
                      color: Colors.white, // สีพื้นหลัง
                      borderRadius: BorderRadius.circular(8), // ขอบโค้ง
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5), // เงา
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpanded =
                                  !_isExpanded; // เปลี่ยนสถานะการพับข้อมูล
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                _isExpanded
                                    ? Icons.arrow_drop_down
                                    : Icons.arrow_right,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "พรที่อยากขอ",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (_isExpanded) // แสดงข้อมูลเฉพาะเมื่อเปิด
                          Wrap(
                            spacing: 0.0,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value:
                                        _selectedSides.length == _sides.length,
                                    onChanged: (bool? selected) {
                                      _selectAllSides();
                                    },
                                  ),
                                  const Text(
                                    'ทั้งหมด',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              ..._sides.map((String side) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: _selectedSides.contains(side),
                                      onChanged: (bool? selected) {
                                        setState(() {
                                          if (selected == true) {
                                            _selectedSides.add(side);
                                          } else {
                                            _selectedSides.remove(side);
                                          }
                                          _fetchMapData();
                                        });
                                      },
                                    ),
                                    Text(
                                      side,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ปุ่มซูมที่มุมขวาล่าง
            Positioned(
              right: 20,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.add_location,
                        size: 18,
                        color: _isAddingMarker ? Colors.green : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _isAddingMarker =
                              !_isAddingMarker; // สลับโหมดการเพิ่ม Marker
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () {
                        setState(() {
                          _currentZoom++;
                          _mapController.move(
                              _mapController.center, _currentZoom);
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () {
                        setState(() {
                          _currentZoom--;
                          _mapController.move(
                              _mapController.center, _currentZoom);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
