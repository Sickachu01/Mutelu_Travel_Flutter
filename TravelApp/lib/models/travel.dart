class Travel {
  final String namelocation;
  final String subname;
  final String detail;
  final String side;
  final String location;
  final String time;
  final String Image1;
  final String Image2;

  Travel({
    required this.namelocation,
    required this.subname,
    required this.detail,
    required this.side,
    required this.location,
    required this.time,
    required this.Image1,
    required this.Image2,
  });

  factory Travel.fromJson(Map<String, dynamic> json) {
    return Travel(
      namelocation: json['namelocation'] ?? 'Unknown Location', 
      subname: json['subname'] ?? 'Unknown Subname',
      detail: json['detail'] ?? 'No details available',
      side: json['side'] ?? 'Unknown Side',
      location: json['location'] ?? 'Unknown Location',
      time: json['time'] ?? 'No Time Provided',
      Image1: json['Image1'] ?? 'https://via.placeholder.com/150', 
      Image2: json['Image2'] ?? 'https://via.placeholder.com/150',
    );
  }
}
