class HolidayModel {
  final String holidayName;
  final DateTime holidayDate;
  final int year;
  final String holidayType;
  final String country;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  HolidayModel({
    required this.holidayName,
    required this.holidayDate,
    required this.year,
    required this.holidayType,
    required this.country,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      holidayName: json['holidayName'],
      holidayDate: DateTime.parse(json['holidayDate']),
      year: json['year'],
      holidayType: json['holidayType'],
      country: json['country'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
