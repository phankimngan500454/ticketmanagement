/// assetGroup: 'Phần cứng' | 'Phần mềm' | 'Mạng'
/// assetType: loại cụ thể trong từng nhóm
/// Status: 'Active' | 'Inactive' | 'Maintenance'
class Asset {
  final int assetId;
  final String assetName;   // tên thiết bị / phần mềm
  final String assetCode;   // serial number / mã
  final String assetGroup;  // nhóm lớn: Phần cứng / Phần mềm / Mạng
  final String assetType;   // loại cụ thể trong nhóm
  final String assetModel;  // model cụ thể (ví dụ: Dell XPS 15, HP LaserJet...)
  final String status;
  final int? categoryId;

  const Asset({
    required this.assetId,
    required this.assetName,
    required this.assetCode,
    required this.assetGroup,
    required this.assetType,
    required this.assetModel,
    required this.status,
    this.categoryId,
  });

  factory Asset.fromJson(Map<dynamic, dynamic> json) => Asset(
        assetId:    json['AssetID'] as int,
        assetName:  json['AssetName'] as String? ?? '',
        assetCode:  json['AssetCode'] as String? ?? '',
        assetGroup: json['AssetGroup'] as String? ?? 'Phần cứng',
        assetType:  json['AssetType'] as String? ?? 'Khác',
        assetModel: json['AssetModel'] as String? ?? '',
        status:     json['Status'] as String? ?? 'Active',
        categoryId: json['CategoryID'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'AssetID':    assetId,
        'AssetName':  assetName,
        'AssetCode':  assetCode,
        'AssetGroup': assetGroup,
        'AssetType':  assetType,
        'AssetModel': assetModel,
        'Status':     status,
        'CategoryID': categoryId,
      };
}
