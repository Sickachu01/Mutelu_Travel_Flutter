import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'onedaytripmap.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OneDayWidget extends StatefulWidget {
  const OneDayWidget({Key? key}) : super(key: key);

  @override
  State<OneDayWidget> createState() => OneDayWidgetState();
}

class OneDayWidgetState extends State<OneDayWidget> {
  List<String> _locationNames = []; // เปลี่ยนชื่อเป็น _locationNames
  int selectedPlacesCount = 1; // จำนวนสถานที่ที่ผู้ใช้เลือก
  List<String?> selectedLocations = []; // ตัวแปรเก็บชื่อสถานที่ที่ผู้ใช้เลือก
  List<dynamic> tripLocations = []; // ตัวแปรสำหรับเก็บข้อมูลสถานที่
  LatLng startPoint = LatLng(13.7563, 100.5018); // จุดเริ่มต้น (กรุงเทพฯ)
  LatLng? selectedPosition; // ตำแหน่งที่ผู้ใช้เลือกจากแผนที่
  late MapController _mapController;
  double _currentZoom = 13.0;
  bool showByDistance = true; // แสดงตามระยะทาง
  bool showByTime = true; // แสดงตามเวลา เปิด-ปิด

  Future<void> _fetchAvailableLocations() async {
    const String url = 'http://10.0.2.2:3001/maps'; // URL API
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        Set<String> locationNamesSet = {};
        for (var mapData in data) {
          if (mapData['namelocation'] != null) {
            locationNamesSet.add(mapData['namelocation'] as String);
          }
        }

        _locationNames = locationNamesSet.toList(); // อัปเดตให้เป็นชื่อสถานที่
        tripLocations = data; // เก็บข้อมูลทั้งหมดเพื่อใช้งานที่อื่น

        print('Available locations: $_locationNames');
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchAvailableLocations(); // เรียกใช้ฟังก์ชันนี้
    selectedLocations = List.generate(selectedPlacesCount, (_) => null);
  }

  void _updateSelectedLocations(int index, String? newValue) {
    if (index < selectedLocations.length) {
      selectedLocations[index] = newValue;
    }
  }

  List<String> _getAvailableLocations(int index) {
    // สร้างสำเนาของ _locationNames
    List<String> availableLocations = List.from(_locationNames);

    // ลบสถานที่ที่ถูกเลือกไปแล้วออก
    for (int i = 0; i < selectedLocations.length; i++) {
      if (i != index && selectedLocations[i] != null) {
        availableLocations.remove(selectedLocations[i]);
      }
    }

    return availableLocations;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travelapp',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 81, 218, 152),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 81, 218, 152),
        ),
        textTheme: const TextTheme(
          bodyText1: TextStyle(color: Colors.black87),
          bodyText2: TextStyle(color: Colors.black54),
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
            "         จัดทริปสถานที่ท่องเที่ยว",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 199, 253, 203),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ส่วนสำหรับเลือกจำนวนสถานที่
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "กำหนดจำนวนสถานที่:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (selectedPlacesCount > 1) {
                              selectedPlacesCount--;
                              selectedLocations.removeLast(); // ลบค่าล่าสุด
                            }
                          });
                        },
                      ),
                      Text(selectedPlacesCount.toString()),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            selectedPlacesCount++;
                            selectedLocations
                                .add(null); // เพิ่ม null สำหรับสถานที่ใหม่
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              // ส่วนเลือกการแสดง marker
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "แสดงตามระยะทางที่ใกล้สุด:",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Checkbox(
                    value: showByDistance,
                    onChanged: (bool? value) {
                      setState(() {
                        showByDistance =
                            value ?? true; // อัปเดตค่าเมื่อ Checkbox ถูกติ๊ก
                        showByTime = !showByDistance; // อัปเดตให้ตรงกัน
                      });
                    },
                  ),
                  const Text(
                    "แสดงตามเวลาเปิด-ปิด:",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Checkbox(
                    value: showByTime,
                    onChanged: (bool? value) {
                      setState(() {
                        showByTime =
                            value ?? false; // อัปเดตค่าเมื่อ Checkbox ถูกติ๊ก
                        showByDistance = !showByTime; // อัปเดตให้ตรงกัน
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              // Dropdown สำหรับเลือกชื่อสถานที่
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedPlacesCount,
                itemBuilder: (context, index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ข้อความบอกลำดับสถานที่
                      const Text(
                        'ชื่อสถานที่',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      DropdownButton<String>(
                        value: selectedLocations[index],
                        hint: const Text("กรอกชื่อสถานที่"),
                        isExpanded: true,
                        items: _getAvailableLocations(index)
                            .map((String location) {
                          return DropdownMenuItem<String>(
                            value: location,
                            child: Text(location),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _updateSelectedLocations(
                                index, newValue); // อัพเดต selectedLocations
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16.0),
              // แผนที่
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: startPoint,
                        zoom: 14,
                        onTap: (tapPosition, point) {
                          setState(() {
                            selectedPosition =
                                point; // บันทึกตำแหน่งที่ผู้ใช้เลือก
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: selectedPosition != null
                              ? [
                                  Marker(
                                    point: selectedPosition!,
                                    builder: (ctx) => const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 30,
                                    ),
                                  ),
                                ]
                              : [],
                        ),
                      ],
                    ),
                    // ข้อความแสดงเมื่อยังไม่มีการเลือกจุด
                    if (selectedPosition == null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          color: Colors.black54,
                          child: const Text(
                            "กรุณากำหนดจุดที่คุณอยู่",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // ปุ่มซูมที่มุมขวาล่าง
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                                  if (_currentZoom < 20) {
                                    // ตรวจสอบให้แน่ใจว่าไม่ซูมเกินขอบเขต
                                    _currentZoom++;
                                    _mapController.move(
                                        _mapController.center, _currentZoom);
                                  }
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
                                  if (_currentZoom > 1) {
                                    // ตรวจสอบให้แน่ใจว่าไม่ซูมต่ำกว่าขอบเขต
                                    _currentZoom--;
                                    _mapController.move(
                                        _mapController.center, _currentZoom);
                                  }
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
              const SizedBox(height: 16.0),
              // เมื่อกดปุ่ม 'จัดทริป'
              ElevatedButton(
                onPressed: () {
                  if (selectedPosition == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("กรุณาเลือกตำแหน่งบนแผนที่")),
                    );
                  } else {
                    // ส่งข้อมูลไปยัง OneDayTripMap
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OneDayTripMap(
                          tripLocations: tripLocations.where((location) {
                            // กรอง tripLocations โดยใช้ selectedLocations
                            return selectedLocations
                                .contains(location['namelocation']);
                          }).toList(), // ส่งเฉพาะสถานที่ที่ผู้ใช้เลือก
                          selectedSides: selectedLocations,
                          startPoint: selectedPosition!,
                          selectedPosition: selectedPosition!,
                          maxMarkers: selectedPlacesCount,
                          showByDistance:
                              showByDistance, // ส่งค่า showByDistance ที่นี่
                          showByTime: showByTime, // ส่งค่า showByTime
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  primary: const Color.fromARGB(255, 81, 218, 152),
                  onPrimary: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('จัดทริป',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
