class HistoryEntry {
  final int taps;
  final int durationSeconds;
  final DateTime timestamp;

  HistoryEntry({
    required this.taps,
    required this.durationSeconds,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'taps': taps,
        'duration': durationSeconds,
        'ts': timestamp.millisecondsSinceEpoch,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        taps: json['taps'] as int,
        durationSeconds: json['duration'] as int,
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
      );
}
