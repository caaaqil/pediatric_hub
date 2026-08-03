import 'json_utils.dart';

/// `model GrowthRecord`
class GrowthRecord {
  const GrowthRecord({
    required this.id,
    required this.childId,
    required this.measurementDate,
    required this.recorderRole,
    this.weightKg,
    this.heightCm,
    this.headCircumCm,
    this.milestoneNotes,
    this.authorEmail,
  });

  final String id;
  final String childId;
  final DateTime measurementDate;

  /// 'PARENT' or 'DOCTOR' — written from the caller's JWT role.
  final String recorderRole;
  final double? weightKg;
  final double? heightCm;
  final double? headCircumCm;
  final String? milestoneNotes;
  final String? authorEmail;

  factory GrowthRecord.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? author = Json.mapOrNull(json['author']);
    return GrowthRecord(
      id: Json.str(json['id']),
      childId: Json.str(json['childId']),
      measurementDate: Json.date(json['measurementDate']),
      recorderRole: Json.str(json['recorderRole']),
      weightKg: Json.decimalOrNull(json['weightKg']),
      heightCm: Json.decimalOrNull(json['heightCm']),
      headCircumCm: Json.decimalOrNull(json['headCircumCm']),
      milestoneNotes: Json.strOrNull(json['milestoneNotes']),
      authorEmail: author == null ? null : Json.strOrNull(author['email']),
    );
  }
}

/// One point of the chart array the backend derives in `growth.service.js`.
class GrowthPoint {
  const GrowthPoint({
    required this.ageInMonths,
    required this.date,
    required this.authorRole,
    this.weight,
    this.height,
    this.headCircum,
  });

  final double ageInMonths;
  final DateTime date;
  final String authorRole;
  final double? weight;
  final double? height;
  final double? headCircum;

  factory GrowthPoint.fromJson(Map<String, dynamic> json) {
    return GrowthPoint(
      ageInMonths: Json.decimal(json['ageInMonths']),
      date: Json.date(json['date']),
      authorRole: Json.str(json['authorRole']),
      weight: Json.decimalOrNull(json['weight']),
      height: Json.decimalOrNull(json['height']),
      headCircum: Json.decimalOrNull(json['headCircum']),
    );
  }
}

/// `GET /growth/child/:childId` → `{ records, chartData }`.
class GrowthData {
  const GrowthData({
    this.records = const <GrowthRecord>[],
    this.chartData = const <GrowthPoint>[],
  });

  final List<GrowthRecord> records;
  final List<GrowthPoint> chartData;

  factory GrowthData.fromJson(Map<String, dynamic> json) {
    return GrowthData(
      records: Json.mapList(
        json['records'],
      ).map(GrowthRecord.fromJson).toList(),
      chartData: Json.mapList(
        json['chartData'],
      ).map(GrowthPoint.fromJson).toList(),
    );
  }

  bool get isEmpty => records.isEmpty;

  GrowthRecord? get latest => records.isEmpty ? null : records.last;
}
