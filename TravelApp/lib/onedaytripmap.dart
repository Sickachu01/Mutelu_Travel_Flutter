import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import '../show_data.dart';

class OneDayTripMap extends StatefulWidget {
  final List<dynamic> tripLocations;
  final List<String?> selectedSides;
  final LatLng startPoint;
  final LatLng selectedPosition;
  final int maxMarkers;
  final bool showByDistance; // เพิ่มที่นี่
  final bool showByTime; // เพิ่มที่นี่

  const OneDayTripMap({
    Key? key,
    required this.tripLocations,
    required this.selectedSides,
    required this.startPoint,
    required this.selectedPosition,
    required this.maxMarkers,
    required this.showByDistance, // เพิ่มที่นี่
    required this.showByTime, // เพิ่มที่นี่
  }) : super(key: key);

  @override
  _OneDayTripMapState createState() => _OneDayTripMapState();
}

class _OneDayTripMapState extends State<OneDayTripMap> {
  List<LatLng> _polylinePoints = [];
  late MapController _mapController;
  double _currentZoom = 13.0;
  String? selectedStartTime;
  String? selectedEndTime;
  bool showByDistance = true;
  late List<LatLng> points; // ใช้ late เพื่อบอกว่าจะถูกกำหนดค่าในภายหลัง

  // กำหนดค่าเวลาเปิด-ปิด
  String startTime = "06.00 น."; // ค่าเริ่มต้น
  String endTime = "12.00 น."; // ค่าเริ่มต้น

  // ตัวอย่างค่าความเร็วเฉลี่ยสำหรับแต่ละวิธีการเดินทาง
  double averageWalkingSpeed = 5.0; // กิโลเมตรต่อชั่วโมง
  double averageCarSpeed = 40.0; // กิโลเมตรต่อชั่วโมง
  double averageMotorbikeSpeed = 30.0; // กิโลเมตรต่อชั่วโมง
  final double trafficDelayFactor =
      1.5; // เพิ่มเวลา 50% ในกรณีที่มีการจราจรหนาแน่น

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final points = _createPolylinePoints();
    final waypoints =
        points.map((point) => '${point.longitude},${point.latitude}').join(';');
    final url =
        'https://router.project-osrm.org/route/v1/driving/$waypoints?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      print(response.body); // แสดงข้อมูลที่ได้รับจาก API

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          // ตรวจสอบว่ามีเส้นทางหรือไม่
          final route = data['routes'][0]['geometry']['coordinates'];

          setState(() {
            // แปลง List<dynamic> เป็น List<LatLng>
            _polylinePoints = route.map<LatLng>((coord) {
              return LatLng(coord[1], coord[0]); // สลับพ้อยท์
            }).toList();
          });
        } else {
          print('No routes found'); // ไม่มีเส้นทางที่พบ
        }
      } else {
        throw Exception('Failed to load route');
      }
    } catch (e) {
      print(e); // จัดการข้อผิดพลาดที่เกิดขึ้น
    }
  }

  void _showFilteredMarkers(BuildContext context) {
    List<dynamic> filteredMarkers = _createFilteredMarkersData();

    // สร้างข้อความที่บอกว่ากรองตามระยะทางหรือเวลา
    String filterCriteria = widget.showByDistance
        ? 'แสดงตามระยะทางที่ใกล้ที่สุด'
        : 'แสดงตามเวลาเปิด-ปิด';

    // แสดงข้อมูลใน Modal Bottom Sheet
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 81, 218, 152),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    filterCriteria,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // ทำให้ข้อความเป็นสีขาว
                    ),
                  ),
                  // ปุ่มกากบาทที่มุมขวาบน
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white, // สีของปุ่มกากบาท
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // ปิด Modal Bottom Sheet
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16), // เว้นระยะห่าง
              Expanded(
                child: ListView.builder(
                  itemCount: filteredMarkers.length,
                  itemBuilder: (context, index) {
                    var location = filteredMarkers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // แสดงข้อความบอกว่าเป็นจุดหมายที่เท่าไร
                            Text(
                              'จุดหมายที่ ${index + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: location['Image1'] != null
                                  ? Image.network(
                                      location['Image1'],
                                      height: 150,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    (loadingProgress
                                                            .expectedTotalBytes ??
                                                        1)
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Text('ไม่มีภาพ');
                                      },
                                    )
                                  : const Text('ไม่มีภาพ'),
                            ),
                            const SizedBox(height: 15),
                            // แสดงชื่อสถานที่
                            Text(
                              location['namelocation'] ?? 'ไม่ทราบชื่อสถานที่',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // แสดงด้าน (ตัวหนาเฉพาะข้อความ "ด้าน:")
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: 'ด้าน: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: '${location['side'] ?? 'ไม่ระบุ'}',
                                  ),
                                ],
                              ),
                            ),
                            // แสดงเวลา (ตัวหนาเฉพาะข้อความ "เวลา:")
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: 'เวลา: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: '${location['time'] ?? 'ไม่ระบุ'}',
                                  ),
                                ],
                              ),
                            ),
                            // แสดงพิกัด (ตัวหนาเฉพาะข้อความ "พิกัด:")
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black),
                                children: [
                                  const TextSpan(
                                    text: 'พิกัด: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text:
                                        '${location['location'] ?? 'ไม่ระบุ'}',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // แสดงข้อความที่กดได้เพื่อไปยังหน้า ShowDataPage
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ShowDataPage(
                                        namelocation:
                                            location['namelocation'] ??
                                                'ไม่ระบุ',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'ดูรายละเอียด',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<dynamic> _createFilteredMarkersData() {
    List<dynamic> markersData = [];
    Set<LatLng> markerPoints = _createFilteredMarkers()
        .map((marker) => marker.point)
        .toSet(); // สร้าง Set สำหรับตำแหน่งของมาร์คเกอร์

    // กรองสถานที่ตามชื่อที่เลือก
    for (var location in widget.tripLocations) {
      if (location['namelocation'] !=
              null && // ตรวจสอบให้แน่ใจว่าชื่อสถานที่ไม่เป็น null
          markerPoints
              .contains(LatLng(location['latitude'], location['longitude']))) {
        markersData
            .add(location); // เพิ่มลงใน markersData เฉพาะจุดที่มีมาร์คเกอร์
      }
    }

    // จัดเรียง markersData ตามระยะทางหรือเวลาเปิด
    if (widget.showByDistance) {
      // เรียงตามระยะทางจาก selectedPosition
      markersData.sort((a, b) {
        LatLng pointA = LatLng(a['latitude'], a['longitude']);
        LatLng pointB = LatLng(b['latitude'], b['longitude']);

        double distanceA = _calculateDistance(widget.selectedPosition, pointA);
        double distanceB = _calculateDistance(widget.selectedPosition, pointB);

        // ถ้าระยะทางเท่ากัน ให้จัดเรียงตามชื่อสถานที่
        if (distanceA == distanceB) {
          String nameA = a['namelocation'] ?? '';
          String nameB = b['namelocation'] ?? '';
          return nameA.compareTo(nameB); // เรียงตามชื่อสถานที่
        }

        return distanceA.compareTo(distanceB); // เรียงตามระยะทาง
      });
    } else {
      // เรียงตามเวลาเปิด
      // ดึงตำแหน่ง Marker ที่กรองในลำดับที่เราต้องการ
      List<LatLng> polylinePoints = _createPolylinePointsByTime();

      // สร้าง Map เพื่อตรวจสอบตำแหน่งของ Marker
      Map<LatLng, dynamic> locationMap = {
        for (var loc in markersData)
          LatLng(loc['latitude'], loc['longitude']): loc
      };

      // สร้างลิสต์ใหม่เพื่อเก็บข้อมูลเรียงตามลำดับ Polyline
      markersData = polylinePoints
          .map((point) => locationMap[point])
          .where((location) => location != null)
          .toList();

      // หากต้องการจัดเรียงตามเวลาเปิด
      markersData.sort((a, b) {
        String timeA =
            a['time']?.split(' - ')[0] ?? '00.00'; // เวลาที่เปิดของสถานที่ A
        String timeB =
            b['time']?.split(' - ')[0] ?? '00.00'; // เวลาที่เปิดของสถานที่ B

        DateTime openingTimeA =
            DateFormat("HH.mm").parse(timeA.replaceAll(" น.", ""));
        DateTime openingTimeB =
            DateFormat("HH.mm").parse(timeB.replaceAll(" น.", ""));

        // ถ้าเวลาเปิดเท่ากัน ให้จัดเรียงตามชื่อสถานที่
        if (openingTimeA == openingTimeB) {
          String nameA = a['namelocation'] ?? '';
          String nameB = b['namelocation'] ?? '';
          return nameA.compareTo(nameB); // เรียงตามชื่อสถานที่
        }

        return openingTimeA.compareTo(openingTimeB); // เรียงตามเวลาเปิด
      });
    }

    return markersData; // คืนค่า List ของสถานที่ที่กรองแล้ว
  }

  void _showTravelTimesPopup(
      BuildContext context, List<Map<String, dynamic>> travelTimes) {
    // ขั้นตอนที่ 1: จัดกลุ่มข้อมูลการเดินทางตามเส้นทาง
    Map<String, List<Map<String, dynamic>>> groupedTravelTimes = {};
    for (var travel in travelTimes) {
      String route = travel['route'] ??
          'ไม่ระบุเส้นทาง'; // ใช้ค่าเริ่มต้นหาก route เป็น null
      if (!groupedTravelTimes.containsKey(route)) {
        groupedTravelTimes[route] = [];
      }
      groupedTravelTimes[route]!.add(travel);
    }

    // ขั้นตอนที่ 2: แสดงข้อมูลใน Modal Bottom Sheet
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 81, 218, 152),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // แสดงข้อความหัวข้อ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'เวลาการเดินทาง',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                      color: Colors.white, // ทำให้ข้อความเป็นสีขาว
                    ),
                  ),
                  // ปุ่มกากบาทที่มุมขวาบน
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white, // สีของปุ่มกากบาท
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // ปิด Modal Bottom Sheet
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16), // เว้นระยะห่าง
              Expanded(
                child: ListView.builder(
                  itemCount: groupedTravelTimes.keys.length,
                  itemBuilder: (context, index) {
                    String route = groupedTravelTimes.keys.elementAt(index);
                    var travels = groupedTravelTimes[route]!;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white, // สีพื้นหลังของ Container
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2), // สีเงา
                            spreadRadius: 2, // ระยะเงา
                            blurRadius: 5, // ขอบเงาเบลอ
                            offset: const Offset(0, 3), // ตำแหน่งของเงา
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // แสดงข้อมูลสถานที่และการเดินทางในบรรทัดเดียว
                          if (travels.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  // ใช้ Expanded เพื่อให้ Row ขยายเต็มพื้นที่
                                  child: Icon(
                                    travels[0]['isUser'] == true
                                        ? Icons.person
                                        : Icons.location_on,
                                    size: 50, // ปรับขนาดให้ใหญ่ขึ้น
                                    color: travels[0]['isUser'] == true
                                        ? Colors.blue
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(
                                    width: 5), // ระยะห่างระหว่างไอคอนกับลูกศร
                                Expanded(
                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: 30, // ปรับขนาดให้ใหญ่ขึ้น
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(
                                    width:
                                        5), // ระยะห่างระหว่างลูกศรกับไอคอนถัดไป
                                Expanded(
                                  child: Icon(
                                    travels[0]['isUser'] == false
                                        ? Icons.person
                                        : Icons.location_on,
                                    size: 50, // ปรับขนาดให้ใหญ่ขึ้น
                                    color: travels[0]['isUser'] == false
                                        ? Colors.blue
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 10),
                          // ข้อมูลเส้นทาง
                          Text(route,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          // แสดงข้อมูลการเดินทางทั้งหมดสำหรับเส้นทางนี้
                          Column(
                            children: travels.map((travel) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    _getTravelModeIcon(travel['mode']),
                                    size: 20,
                                  ),
                                  Text(
                                      '${travel['time'] ?? 'ไม่ระบุเวลา'}'), // ใช้ค่าเริ่มต้นถ้า time เป็น null
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// ฟังก์ชันเพื่อให้ไอคอนตามวิธีการเดินทาง
  IconData _getTravelModeIcon(String mode) {
    switch (mode) {
      case 'เดินเท้า':
        return Icons.directions_walk; // ใช้ไอคอนเดินเท้า
      case 'รถยนต์':
        return Icons.directions_car; // ใช้ไอคอนรถยนต์
      case 'รถมอเตอร์ไซต์':
        return Icons.motorcycle; // ใช้ไอคอนมอเตอร์ไซค์
      default:
        return Icons.directions; // ไอคอนเริ่มต้น
    }
  }

  List<Map<String, dynamic>> _calculateTravelTimes() {
    List<Map<String, dynamic>> travelTimes = [];

    // เริ่มจากตำแหน่งของผู้ใช้
    LatLng userPosition = widget.selectedPosition;

    // คำนวณเวลาการเดินทางจากผู้ใช้ไปยังจุดแรก
    if (widget.tripLocations.isNotEmpty) {
      var firstLocation = widget.tripLocations[0];
      LatLng firstPosition =
          LatLng(firstLocation['latitude'], firstLocation['longitude']);

      // คำนวณระยะทาง
      double distanceToFirst = _calculateDistance(userPosition, firstPosition);
      travelTimes.addAll(_getTravelTimesForLocation(
          'ตำแหน่งผู้ใช้ ไปยัง ${firstLocation['namelocation'] ?? 'ไม่ทราบชื่อ'}',
          distanceToFirst));

      // คำนวณเวลาการเดินทางจากจุดแรกไปยังจุดที่สอง
      for (int i = 1; i < widget.tripLocations.length; i++) {
        var currentLocation = widget.tripLocations[i];
        LatLng currentPosition =
            LatLng(currentLocation['latitude'], currentLocation['longitude']);
        double distanceToCurrent =
            _calculateDistance(firstPosition, currentPosition);

        // เพิ่มเวลาเดินทางจากจุดก่อนหน้าไปยังจุดปัจจุบัน
        travelTimes.addAll(_getTravelTimesForLocation(
            '${firstLocation['namelocation'] ?? 'ไม่ทราบชื่อ'} ไปยัง ${currentLocation['namelocation'] ?? 'ไม่ทราบชื่อ'}',
            distanceToCurrent));

        // อัปเดตตำแหน่งก่อนหน้าให้เป็นตำแหน่งปัจจุบัน
        firstPosition = currentPosition;
        firstLocation = currentLocation;
      }
    }

    return travelTimes;
  }

// ฟังก์ชันเพื่อคำนวณเวลาเดินทางสำหรับแต่ละวิธี
  List<Map<String, dynamic>> _getTravelTimesForLocation(
      String route, double distance) {
    List<Map<String, dynamic>> times = [];

    // คำนวณเวลาเดินทางสำหรับการเดินเท้า
    times.add({
      'route': route,
      'mode': 'เดินเท้า',
      'time': _formatTravelTime(distance, averageWalkingSpeed),
    });

    // ปรับความเร็วสำหรับรถยนต์ตามสภาพการจราจร
    double adjustedCarSpeed = averageCarSpeed;
    if (isTrafficHeavy()) {
      adjustedCarSpeed /= trafficDelayFactor; // ลดความเร็วลงตามปัจจัยการจราจร
    }

    // คำนวณเวลาเดินทางสำหรับรถยนต์
    times.add({
      'route': route,
      'mode': 'รถยนต์',
      'time': _formatTravelTime(distance, adjustedCarSpeed),
    });

    // ปรับความเร็วสำหรับรถมอเตอร์ไซค์ตามสภาพการจราจร
    double adjustedMotorbikeSpeed = averageMotorbikeSpeed;
    if (isTrafficHeavy()) {
      adjustedMotorbikeSpeed /=
          trafficDelayFactor; // ลดความเร็วลงตามปัจจัยการจราจร
    }

    // คำนวณเวลาเดินทางสำหรับรถมอเตอร์ไซค์
    times.add({
      'route': route,
      'mode': 'รถมอเตอร์ไซต์',
      'time': _formatTravelTime(distance, adjustedMotorbikeSpeed),
    });

    return times;
  }

// ฟังก์ชันเพื่อตรวจสอบว่ามีการจราจรหนาแน่นหรือไม่ (ตัวอย่าง)
  bool isTrafficHeavy() {
    return true; // เปลี่ยนเป็น false เพื่อให้ไม่ใช่ช่วงจราจรหนาแน่น
  }

// ฟังก์ชันเพื่อแสดงเวลาเดินทาง
  String _formatTravelTime(double distance, double averageSpeed) {
    double timeInHours = distance / averageSpeed; // เวลาในชั่วโมง
    int hours = timeInHours.floor();
    int minutes = ((timeInHours - hours) * 60).round();

    return '$hours ชั่วโมง $minutes นาที';
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    List<Marker> markers =
        _createFilteredMarkers(); // เรียกใช้ Marker ตามเงื่อนไข
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "       แผนที่สำหรับการเดินทาง",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 81, 218, 152),
      ),
      body: Container(
        color: Colors.grey[200], // สีพื้นหลัง
        child: Stack(
          // เปลี่ยนจาก Column เป็น Stack
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: widget.startPoint,
                zoom: _currentZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    // Marker สำหรับจุดเริ่มต้น
                    Marker(
                      point: widget.startPoint,
                      builder: (ctx) => Container(
                        padding: const EdgeInsets.all(4),
                      ),
                    ),
                    // Marker สำหรับตำแหน่งที่ผู้ใช้เลือก
                    Marker(
                      point: widget.selectedPosition,
                      builder: (ctx) => Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                    // สร้าง Marker สำหรับสถานที่ใน tripLocations ตาม selectedSides
                    ..._createFilteredMarkers(),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _polylinePoints, // ใช้พ้อยท์จากการดึงข้อมูล
                      color: Colors.red, // สีของเส้น
                      strokeWidth: 3.5, // ความหนาของเส้น
                    ),
                  ],
                ),
              ],
            ),
            // ปุ่มซูมที่มุมขวาล่าง
            Positioned(
              right: 20,
              bottom: 100, // เปลี่ยนจาก 20 เป็น 100 เพื่อเลื่อนขึ้นมา
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (_currentZoom < 20) {
                          _currentZoom++;
                          _mapController.move(
                              _mapController.center, _currentZoom);
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (_currentZoom > 1) {
                          _currentZoom--;
                          _mapController.move(
                              _mapController.center, _currentZoom);
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // ปุ่มแสดงข้อมูลสถานที่ที่มี Marker
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _showFilteredMarkers(context);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Color.fromARGB(255, 81, 218, 152),
                        onPrimary: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'ข้อมูลสถานที่ในจุดต่างๆ',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10), // เพิ่มช่องว่างระหว่างปุ่ม
                    // ปุ่มเพื่อแสดงเวลาการเดินทาง
                    Positioned(
                      bottom:
                          60, // เลื่อนขึ้นมาเพื่อไม่ให้ทับกับปุ่มข้อมูลสถานที่
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () {
                            // คำนวณเวลาการเดินทางทั้งหมด
                            List<Map<String, dynamic>> travelTimes =
                                _calculateTravelTimes();
                            _showTravelTimesPopup(context, travelTimes);
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Color.fromARGB(255, 81, 218, 152),
                            onPrimary: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 3,
                          ),
                          child: const Text(
                            'เวลาในการเดินทาง',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
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

  List<Marker> _createFilteredMarkersByDistance() {
    List<Marker> markers = [];
    List<Map<String, dynamic>> locationsWithDistance = [];

    for (var location in widget.tripLocations) {
      LatLng position = LatLng(location['latitude'], location['longitude']);
      double distance = _calculateDistance(
          widget.selectedPosition, position); // คำนวณระยะทางจากตำแหน่งที่เลือก
      locationsWithDistance
          .add({...location, 'distance': distance}); // เก็บระยะทางลงไปในข้อมูล
    }

    // เรียงลำดับตามระยะทาง
    locationsWithDistance
        .sort((a, b) => a['distance'].compareTo(b['distance']));

    // สร้าง Marker สำหรับสถานที่ที่กรองแล้ว
    for (var location in locationsWithDistance) {
      LatLng position = LatLng(location['latitude'], location['longitude']);
      markers.add(Marker(
        width: 100.0,
        height: 100.0,
        point: position,
        builder: (ctx) {
          return Container(
            padding: const EdgeInsets.all(4),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 500,
                    child: Text(
                      location['namelocation'] ?? 'ไม่ทราบชื่อ',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Icon(Icons.place,
                    color: _getColorForSide(location['side']), size: 40),
              ],
            ),
          );
        },
      ));
    }

    return markers; // คืนค่า markers ที่กรองตามระยะทาง
  }

  List<Marker> _createFilteredMarkersByTime(String startTime, String endTime) {
    List<Marker> markers = [];
    List<Map<String, dynamic>> filteredLocations = [];

    DateTime start = DateFormat("HH.mm").parse(startTime.replaceAll(" น.", ""));
    DateTime end = DateFormat("HH.mm").parse(endTime.replaceAll(" น.", ""));

    // แสดงช่วงเวลาที่เลือก
    print('ช่วงเวลาที่เลือก: จาก $start ถึง $end');

    // แสดงข้อมูลสถานที่ทั้งหมด
    print('ข้อมูลสถานที่ทั้งหมด: ${widget.tripLocations}');

    // กรองสถานที่ที่เปิดในช่วงเวลาที่กำหนด
    for (var location in widget.tripLocations) {
      String time = location['time'] ?? '';
      List<String> timeParts = time
          .split(RegExp(r'[–-]')); // แยกเวลาเปิด-ปิด โดยใช้ตัวคั่นที่แตกต่างกัน

      if (timeParts.length >= 2) {
        DateTime locationOpeningTime = DateFormat("HH.mm")
            .parse(timeParts[0].trim().replaceAll(" น.", "")); // เวลา **เปิด**
        DateTime locationClosingTime = DateFormat("HH.mm")
            .parse(timeParts[1].trim().replaceAll(" น.", "")); // เวลา **ปิด**

        // เช็คว่าถ้าเวลาที่เปิดและปิดอยู่ในช่วงเวลาที่เลือก
        if (locationOpeningTime.isBefore(end) &&
            locationClosingTime.isAfter(start)) {
          filteredLocations
              .add(location); // เก็บข้อมูลสถานที่ที่เปิดอยู่ในช่วงเวลาที่เลือก
        }
      }
    }

    // แสดงสถานที่ที่ผ่านการกรอง
    print('สถานที่ที่ผ่านการกรอง: $filteredLocations');

    // แยกสถานที่ที่ปิดเวลา 23.59
    List<Map<String, dynamic>> closingAtMidnight = [];
    filteredLocations.removeWhere((location) {
      String time = location['time'] ?? '';
      List<String> timeParts = time.split(RegExp(r'[–-]'));
      if (timeParts.length >= 2) {
        DateTime closingTime = DateFormat("HH.mm")
            .parse(timeParts[1].trim().replaceAll(" น.", ""));
        if (closingTime.hour == 23 && closingTime.minute == 59) {
          closingAtMidnight.add(location);
          return true; // ลบสถานที่ที่ปิดเวลา 23.59 ออกจาก filteredLocations
        }
      }
      return false;
    });

    // เรียงลำดับสถานที่ตามเวลา **ปิด** จากเร็วไปช้า
    filteredLocations.sort((a, b) {
      DateTime closingTimeA = DateFormat("HH.mm").parse(a['time']
          .split(RegExp(r'[–-]'))[1]
          .trim()
          .replaceAll(" น.", "")); // เวลา **ปิด**
      DateTime closingTimeB = DateFormat("HH.mm").parse(b['time']
          .split(RegExp(r'[–-]'))[1]
          .trim()
          .replaceAll(" น.", "")); // เวลา **ปิด**
      return closingTimeA.compareTo(closingTimeB); // เรียงตามเวลา **ปิด**
    });

    // เพิ่มสถานที่ที่ปิดเวลา 23.59 ไว้ท้ายสุด
    filteredLocations.addAll(closingAtMidnight);

    // แสดงชื่อสถานที่ใน Console
    if (filteredLocations.isNotEmpty) {
      print('สถานที่ที่เปิดอยู่ในช่วงเวลาที่เลือก:');
      for (var location in filteredLocations) {
        print(location['namelocation'] ?? 'ไม่ทราบชื่อ');
      }
    } else {
      print('ไม่มีสถานที่เปิดในช่วงเวลาที่เลือก');
    }

    // สร้าง Marker สำหรับสถานที่ที่กรองแล้ว
    for (var location in filteredLocations) {
      LatLng position = LatLng(location['latitude'], location['longitude']);
      markers.add(Marker(
        width: 100.0,
        height: 100.0,
        point: position,
        builder: (ctx) {
          return Container(
            padding: const EdgeInsets.all(4),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 250,
                    child: Text(
                      location['namelocation'] ?? 'ไม่ทราบชื่อ',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Icon(Icons.place,
                    color: _getColorForSide(location['side']), size: 40),
              ],
            ),
          );
        },
      ));
    }

    return markers; // คืนค่า markers ที่กรองแล้ว
  }

  List<Marker> _createFilteredMarkers() {
    if (showByDistance) {
      return _createFilteredMarkersByDistance();
    } else {
      return _createFilteredMarkersByTime(selectedStartTime!, selectedEndTime!);
    }
  }

// ฟังก์ชันเพื่อกำหนดสีของ Marker ตาม side
  Color _getColorForSide(String side) {
    // ignore: unnecessary_null_comparison
    if (side == null) {
      print('Error: side is null');
      return Colors.red; // ค่า default
    }

    switch (side) {
      case 'โชคลาภ':
        return const Color.fromARGB(255, 228, 210, 54);
      case 'ความรัก':
        return Colors.pink;
      case 'สุขภาพ':
        return Colors.green;
      case 'การเดินทาง':
        return Colors.blue;
      case 'เสริมดวง':
        return Colors.orange;
      case 'การงาน':
        return Colors.teal;
      default:
        print('Unknown side: $side'); // แสดงค่าไม่รู้จัก
        return Colors.red; // ค่า default
    }
  }

  List<LatLng> _createPolylinePointsByTime() {
    List<LatLng> points = [
      widget.selectedPosition
    ]; // เริ่มจากตำแหน่งที่ผู้ใช้เลือก

    // สร้าง Marker ที่กรองตามเวลา
    List<Marker> filteredMarkers =
        _createFilteredMarkersByTime(startTime, endTime);

    // สร้างลิสต์เพื่อเก็บตำแหน่งของ Markers ที่กรองตามเวลา
    List<LatLng> markerPositions = [];

    // เพิ่มตำแหน่งของ Marker ที่กรองตามเวลา
    for (var marker in filteredMarkers) {
      markerPositions.add(marker.point); // เพิ่มตำแหน่งของ Marker
    }

    // ถ้าไม่มี Markers ให้คืนค่า points ที่มีเพียงตำแหน่งเริ่มต้น
    if (markerPositions.isEmpty) {
      return points; // คืนค่าที่มีเพียงตำแหน่งผู้ใช้
    }

    // เพิ่มตำแหน่ง Marker ตามลำดับที่กรอง
    points.addAll(
        markerPositions); // เพิ่มตำแหน่งทั้งหมดของ Marker ที่กรองตามเวลา

    // ตรวจสอบจำนวนพ้อยท์ก่อนคืนค่า
    if (points.length < 2) {
      return [
        widget.selectedPosition
      ]; // คืนค่าพ้อยท์ที่มีเพียงตำแหน่งเริ่มต้นถ้าจำนวนไม่ถึง 2
    }

    return points; // คืนค่า List ของพ้อยท์ที่ใช้ในการวาด Polyline
  }

  List<LatLng> _createPolylinePointsByDistance() {
    List<LatLng> points = [
      widget.selectedPosition
    ]; // เริ่มจากตำแหน่งที่ผู้ใช้เลือก

    // สร้าง Marker ที่กรองตามระยะทาง
    List<Marker> filteredMarkers = _createFilteredMarkersByDistance();
    List<LatLng> markerPositions = []; // สร้างลิสต์เพื่อเก็บตำแหน่งของ Markers

    // ดึงตำแหน่งของ Markers ที่กรองแล้ว
    for (var marker in filteredMarkers) {
      markerPositions.add(marker.point); // เพิ่มตำแหน่งของ Marker
    }

    // ถ้าไม่มี Markers ให้คืนค่า points ที่มีเพียงตำแหน่งเริ่มต้น
    if (markerPositions.isEmpty) {
      return points;
    }

    // วาด Polyline โดยเชื่อมต่อ Marker ที่เรียงลำดับตามระยะทาง
    for (var position in markerPositions) {
      // เพิ่มพ้อยท์ไปยังลิสต์
      points.add(position);
    }

    return points; // คืนค่า List ของพ้อยท์ที่ใช้ในการวาด Polyline
  }

  List<LatLng> _createPolylinePoints() {
    if (widget.showByDistance) {
      // ใช้ widget.showByDistance แทน
      return _createPolylinePointsByDistance();
    } else if (widget.showByTime) {
      // ใช้ widget.showByTime แทน
      return _createPolylinePointsByTime();
    }
    return []; // คืนค่ารายการว่างถ้าไม่มีเงื่อนไขที่ถูกต้อง
  }

  // ฟังก์ชันคำนวณระยะห่างระหว่างสองตำแหน่ง
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // รัศมีของโลกในกิโลเมตร

    double dLat = _degreesToRadians(point2.latitude - point1.latitude);
    double dLon = _degreesToRadians(point2.longitude - point1.longitude);

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(point1.latitude)) *
            cos(_degreesToRadians(point2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // คืนค่าระยะห่างในกิโลเมตร
  }

  // ฟังก์ชันช่วยเพื่อแปลงองศาเป็นเรเดียน
  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793238 / 180.0);
  }
}
