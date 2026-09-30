class MeterSummary {
  final String id;
  final String name;
  final double activePower; // kW
  final double avgVoltage;
  final bool isOnline;
  final DateTime lastUpdated;

  MeterSummary({
    required this.id,
    required this.name,
    required this.activePower,
    required this.avgVoltage,
    required this.isOnline,
    required this.lastUpdated,
  });

  factory MeterSummary.fromJson(String id, Map<String, dynamic> data) {
    final latest = (data['latest'] as Map?)?.cast<String, dynamic>() ?? {};

    final voltage = (latest['voltage'] as num?)?.toDouble() ?? 0;
    final powerW = (latest['power'] as num?)?.toDouble() ?? 0;

    final tsMillis = (latest['timestamp'] as num?)?.toInt();
    final timestamp = tsMillis != null
        ? DateTime.fromMillisecondsSinceEpoch(tsMillis)
        : DateTime.now().subtract(const Duration(days: 1));

    final ageSeconds = DateTime.now().difference(timestamp).inSeconds;

    // age >= 0 ka sakht check phone ke clock peeche hone par meter ko jhooti
    // "offline" dikha deta hai (meter apni NTP ghari se timestamp bhejta hai).
    // Is liye thoda negative skew (60s) bhi fresh hi ginte hain.
    return MeterSummary(
      id: id,
      name: (data['name'] ?? id).toString(),
      activePower: powerW / 1000,
      avgVoltage: voltage,
      isOnline: ageSeconds > -60 && ageSeconds < 10,
      lastUpdated: timestamp,
    );
  }
}
