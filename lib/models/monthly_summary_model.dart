/// Current-month attendance summary returned by the dashboard `home` endpoint
/// under the `summary_current_month` key.
class MonthlySummaryModel {
  final int present;
  final int late;
  final int absent;
  final int leave;
  final int workingDay;

  const MonthlySummaryModel({
    this.present = 0,
    this.late = 0,
    this.absent = 0,
    this.leave = 0,
    this.workingDay = 0,
  });

  factory MonthlySummaryModel.fromJson(Map<String, dynamic> json) {
    int parse(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

    return MonthlySummaryModel(
      present: parse(json['present']),
      late: parse(json['late']),
      absent: parse(json['absent']),
      leave: parse(json['leave']),
      workingDay: parse(json['working_day']),
    );
  }
}
