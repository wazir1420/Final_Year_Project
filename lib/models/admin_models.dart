class CustomerSummary {
  final String uid;
  final String name;
  final List<String> meterIds;
  final bool isOnline;

  CustomerSummary({
    required this.uid,
    required this.name,
    required this.meterIds,
    required this.isOnline,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class MeterRequest {
  final String id;
  final String customerUid;
  final String customerName;
  final String message;

  MeterRequest({
    required this.id,
    required this.customerUid,
    required this.customerName,
    required this.message,
  });
}

class AdminSummary {
  final List<CustomerSummary> customers;
  final int totalMeters;
  final List<MeterRequest> pendingRequests;

  AdminSummary({
    required this.customers,
    required this.totalMeters,
    required this.pendingRequests,
  });
}
