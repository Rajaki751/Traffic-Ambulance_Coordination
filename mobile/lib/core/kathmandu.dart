class KathmanduLocation {
  static const double centerLat = 27.7172;
  static const double centerLon = 85.3240;
}

class KathmanduHospital {
  final String name;
  final double lat;
  final double lon;

  const KathmanduHospital(this.name, this.lat, this.lon);
}

const kathmanduHospitals = <KathmanduHospital>[
  KathmanduHospital("Teaching Hospital", 27.7358, 85.3304),
  KathmanduHospital("Bir Hospital", 27.7048, 85.3130),
  KathmanduHospital("Patan Hospital", 27.6685, 85.3194),
  KathmanduHospital("Civil Hospital", 27.6972, 85.3188),
  KathmanduHospital("Grande Hospital", 27.7444, 85.3375),
  KathmanduHospital("Norvic Hospital", 27.7103, 85.3198),
];
