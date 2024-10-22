import 'package:flutter/material.dart';
import '../services/travel_service.dart';
import '../models/travel.dart';
import '../show_data.dart';

void main() {
  runApp(const DataWidget());
}

class DataWidget extends StatefulWidget {
  const DataWidget({Key? key}) : super(key: key);

  @override
  State<DataWidget> createState() => DataWidgetState();
}

class DataWidgetState extends State<DataWidget> {
  late Future<List<Travel>> futureTravels;
  List<Travel> _allTravels = [];
  List<Travel> _filteredTravels = [];
  String? _selectedSide;
  String _searchText = '';
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    futureTravels = TravelService().fetchTravels().then((travels) {
      setState(() {
        _allTravels = travels;
        _filteredTravels = travels;
        _suggestions = travels
            .expand((travel) => [travel.namelocation, travel.subname])
            .toSet()
            .toList();
      });
      return travels;
    });
  }

  void _navigateToShowData(String namelocation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShowDataPage(namelocation: namelocation),
      ),
    );
  }

  void _filterTravels(String? side) {
    setState(() {
      _selectedSide = side;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredTravels = _allTravels.where((travel) {
        final matchesSide = _selectedSide == null ||
            _selectedSide == 'ทั้งหมด' ||
            travel.side == _selectedSide;
        final matchesSearch = travel.namelocation
                .toLowerCase()
                .contains(_searchText.toLowerCase()) ||
            travel.subname.toLowerCase().contains(_searchText.toLowerCase());
        return matchesSide && matchesSearch;
      }).toList();
    });
  }

  void _updateSearch(String value) {
    setState(() {
      _searchText = value;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel App',
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
          title: const Row(
            children: [
              SizedBox(width: 21),
              Text(
                "  ข้อมูลสถานที่ท่องเที่ยว",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Color.fromARGB(255, 199, 253, 203), // Soft light green
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Container(
                    width: 245,
                    height: 50,
                    color: Color.fromARGB(255, 255, 255, 255),
                    child: Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return _suggestions.where((suggestion) =>
                            suggestion.toLowerCase().contains(
                                textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (String selection) {
                        _updateSearch(selection);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: _updateSearch,
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            hintText: 'ค้นหาชื่อสถานที่',
                            hintStyle: TextStyle(color: Colors.black54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            prefixIcon: Icon(Icons.search),
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255),
                      border: Border.all(color: Colors.black, width: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      hint: const Text(
                        "พรที่อยากขอ",
                        style: TextStyle(
                          color: Color.fromARGB(255, 122, 122, 122), 
                          fontWeight: FontWeight.bold, 
                          fontSize: 15.5, 
                        ),
                      ),
                      value: _selectedSide,
                      onChanged: (String? newValue) {
                        _filterTravels(newValue);
                      },
                      items: <String>[
                        'ทั้งหมด',
                        'โชคลาภ',
                        'ความรัก',
                        'สุขภาพ',
                        'การเดินทาง',
                        'เสริมดวง',
                        'การงาน',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      underline: SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Travel>>(
                future: futureTravels,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: _filteredTravels.length,
                      itemBuilder: (context, index) {
                        Travel travel = _filteredTravels[index];
                        return GestureDetector(
                          onTap: () {
                            _navigateToShowData(travel.namelocation);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              width: 390,
                              height: 300,
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 255, 255, 255),
                                border: Border.all(color: Colors.black, width: 2),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: travel.namelocation,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Container(
                                          width: 180,
                                          height: 150,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.black, width: 2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              travel.Image1,
                                              width: 180,
                                              height: 150,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Center(
                                                    child: Text(
                                                        'Image not available'));
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          width: 180,
                                          height: 150,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.black, width: 2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.network(
                                              travel.Image2,
                                              width: 180,
                                              height: 150,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Center(
                                                    child: Text(
                                                        'Image not available'));
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: 'ขอพรด้าน : ',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: travel.side,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: 'พิกัด : ',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: travel.location,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
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
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text('No data found'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
