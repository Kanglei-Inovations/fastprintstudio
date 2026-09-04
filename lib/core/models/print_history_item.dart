class PrintHistoryItem {
  final String id;
  final DateTime timestamp;
  final String serviceName;
  final String paperName;
  final int copiesCount;
  final String printerName;
  final String status; // 'Printed', 'Exported PDF', 'Cancelled', 'Failed'
  final String dimensionsSummary;
  final String? errorMessage;

  // Financial Transaction Model
  final double sellingPrice;
  final double materialCost;
  final double inkCost;
  final double profit;
  final String paymentStatus; // 'Paid', 'Due'
  final String paymentMethod; // 'Cash', 'UPI', 'Other'
  final String? customerName;

  const PrintHistoryItem({
    required this.id,
    required this.timestamp,
    required this.serviceName,
    required this.paperName,
    required this.copiesCount,
    required this.printerName,
    required this.status,
    required this.dimensionsSummary,
    this.errorMessage,
    this.sellingPrice = 0.0,
    this.materialCost = 0.0,
    this.inkCost = 0.0,
    this.profit = 0.0,
    this.paymentStatus = 'Paid',
    this.paymentMethod = 'Cash',
    this.customerName,
  });

  PrintHistoryItem copyWith({
    String? id,
    DateTime? timestamp,
    String? serviceName,
    String? paperName,
    int? copiesCount,
    String? printerName,
    String? status,
    String? dimensionsSummary,
    String? errorMessage,
    double? sellingPrice,
    double? materialCost,
    double? inkCost,
    double? profit,
    String? paymentStatus,
    String? paymentMethod,
    String? customerName,
  }) {
    return PrintHistoryItem(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      serviceName: serviceName ?? this.serviceName,
      paperName: paperName ?? this.paperName,
      copiesCount: copiesCount ?? this.copiesCount,
      printerName: printerName ?? this.printerName,
      status: status ?? this.status,
      dimensionsSummary: dimensionsSummary ?? this.dimensionsSummary,
      errorMessage: errorMessage ?? this.errorMessage,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      materialCost: materialCost ?? this.materialCost,
      inkCost: inkCost ?? this.inkCost,
      profit: profit ?? this.profit,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerName: customerName ?? this.customerName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'serviceName': serviceName,
        'paperName': paperName,
        'copiesCount': copiesCount,
        'printerName': printerName,
        'status': status,
        'dimensionsSummary': dimensionsSummary,
        'errorMessage': errorMessage,
        'sellingPrice': sellingPrice,
        'materialCost': materialCost,
        'inkCost': inkCost,
        'profit': profit,
        'paymentStatus': paymentStatus,
        'paymentMethod': paymentMethod,
        'customerName': customerName,
      };

  factory PrintHistoryItem.fromJson(Map<String, dynamic> json) => PrintHistoryItem(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        serviceName: json['serviceName'] as String,
        paperName: json['paperName'] as String,
        copiesCount: json['copiesCount'] as int? ?? 1,
        printerName: json['printerName'] as String? ?? 'Default Printer',
        status: json['status'] as String? ?? 'Printed',
        dimensionsSummary: json['dimensionsSummary'] as String? ?? '',
        errorMessage: json['errorMessage'] as String?,
        sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
        materialCost: (json['materialCost'] as num?)?.toDouble() ?? 0.0,
        inkCost: (json['inkCost'] as num?)?.toDouble() ?? 0.0,
        profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
        paymentStatus: json['paymentStatus'] as String? ?? 'Paid',
        paymentMethod: json['paymentMethod'] as String? ?? 'Cash',
        customerName: json['customerName'] as String?,
      );
}
