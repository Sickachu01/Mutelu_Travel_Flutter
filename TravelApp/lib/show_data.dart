import 'package:flutter/material.dart';
import '../services/travel_service.dart';
import '../models/travel.dart';

class ShowDataPage extends StatefulWidget {
  final String namelocation;

  const ShowDataPage({Key? key, required this.namelocation}) : super(key: key);

  @override
  State<ShowDataPage> createState() => ShowDataPageState();
}

class ShowDataPageState extends State<ShowDataPage> {
  late Future<Travel?> futureTravel;

  @override
  void initState() {
    super.initState();
    futureTravel = _fetchTravelByName(widget.namelocation);
  }

  Future<Travel?> _fetchTravelByName(String namelocation) async {
    List<Travel> travels = await TravelService().fetchTravels();
    return travels.firstWhere(
      (travel) => travel.namelocation == namelocation,
      orElse: () => Travel(
        namelocation: 'Not Found',
        subname: '',
        Image1: '',
        Image2: '',
        side: '',
        location: '',
        detail: '',
        time: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          title: FutureBuilder<Travel?>(
            future: futureTravel,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text(
                  '  Loading...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } else if (snapshot.hasError) {
                return const Text(
                  '  Error',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } else if (snapshot.hasData && snapshot.data != null) {
                final travel = snapshot.data!;
                return Text(
                  travel.namelocation,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                );
              } else {
                return const Text(
                  'No Data',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
            },
          ),
          centerTitle: true,
        ),
        backgroundColor: Color.fromARGB(255, 199, 253, 203), // Soft light green
        body: FutureBuilder<Travel?>(
          future: futureTravel,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data != null) {
              Travel travel = snapshot.data!;
              return SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          width: 370,
                          height: 300,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(travel.Image1),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              travel.namelocation, // ชื่อสถานที่
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              travel.subname, // ชื่อย่อย
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  travel.detail,
                                  style: const TextStyle(
                                    fontSize: 17,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'ขอพรด้าน : ',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: travel.side, // ด้าน
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'เวลาเปิด-ปิด : ',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: travel.time, // เวลาเปิด-ปิด
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'พิกัด : ',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: travel.location, // พิกัด
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height:30),
                    ],
                  ),
                ),
              );
            } else {
              return const Center(child: Text('ไม่มีข้อมูลที่จะแสดง'));
            }
          },
        ),
      ),
    );
  }
}
