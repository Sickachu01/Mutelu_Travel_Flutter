import 'package:flutter/material.dart';
import 'data.dart';
import 'locationmap.dart';
import 'onedaytrip.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travelapp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          color: Colors.blue,
        ),
      ),
      home: SplashScreen(), // เปลี่ยนไปยังหน้า SplashScreen
    );
  }
}

// สร้าง SplashScreen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ใช้ Future.delayed เพื่อรอเวลาที่กำหนดก่อนจะเปลี่ยนหน้า
    Future.delayed(const Duration(seconds: 8), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 199, 253, 203), // สีพื้นหลัง
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15), // กำหนดมุมโค้ง
                border: Border.all(
                  color: Colors.black, // สีของขอบ
                  width: 4, // ความหนาของขอบ
                ),
              ),
              child: ClipRRect(
                // ใช้ ClipRRect เพื่อให้มุมโค้ง
                borderRadius:
                    BorderRadius.circular(15), // ให้มุมโค้งของภาพตรงกัน
                child: Image.asset(
                  'assets/images/Logo.png',
                  width: 300,
                  height: 150,
                  fit: BoxFit.cover, // ให้ภาพเติมเต็ม Container
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mutelu Travel',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// หน้า MainScreen ที่จะนำไปยังหลังจาก SplashScreen
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 199, 253, 203),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DataWidget()),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 320,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        image: const DecorationImage(
                          image: AssetImage('assets/images/Templeicon.png'),
                        ),
                        border: Border.all(color: Colors.black, width: 3),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'ข้อมูลสถานที่ท่องเที่ยว',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OneDayWidget()),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 320,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        image: const DecorationImage(
                          image: AssetImage('assets/images/onedaytripicon.jpg'),
                        ),
                        border: Border.all(color: Colors.black, width: 3),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'จัดทริปสถานที่ท่องเที่ยว',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MapWidget()),
                  );
                },
                child: Container(
                  width: 320,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    image: const DecorationImage(
                      image: AssetImage('assets/images/Mapicon.png'),
                    ),
                    border: Border.all(color: Colors.black, width: 3),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'แผนที่สถานที่ท่องเที่ยว',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
