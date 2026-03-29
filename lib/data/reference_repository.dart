// ============================================================
//  reference_repository.dart
//  Dữ liệu tham chiếu: Category, Asset, Department, EmergencyContact
// ============================================================
import 'package:ticketmanagement_server_client/ticketmanagement_server_client.dart'
    as sp;
import 'repository_base.dart';
import '../models/category.dart';
import '../models/asset.dart';
import '../models/department.dart';
import '../models/emergency_contact.dart';
import '../services/sp_client.dart';

mixin ReferenceRepository on RepositoryBase {
  // ════════════════════════════════════════════════════════════
  // CATEGORY
  // ════════════════════════════════════════════════════════════

  Future<List<Category>> getCategories() async {
    final cats = await client.reference.getCategories();
    categoryCache = cats.map(mapCategory).toList();
    return categoryCache;
  }

  Future<Category> upsertCategory(Category cat) async {
    final spCat = await client.reference.upsertCategory(
      sp.Category(
        id: cat.categoryId == 0 ? null : cat.categoryId,
        categoryName: cat.categoryName,
      ));
    categoryCache = []; // invalidate cache
    return mapCategory(spCat);
  }

  Future<void> deleteCategory(int categoryId) async {
    await client.reference.deleteCategory(categoryId);
    categoryCache = [];
  }

  // ════════════════════════════════════════════════════════════
  // ASSET (Thiết bị)
  // ════════════════════════════════════════════════════════════

  Future<List<Asset>> getAssets() async {
    final assets = await client.reference.getAssets();
    assetCache = assets.map(mapAsset).toList();
    return assetCache;
  }

  Future<Asset> upsertAsset(Asset asset) async {
    final spAsset = await client.reference.upsertAsset(
      sp.Asset(
        id: asset.assetId == 0 ? null : asset.assetId,
        assetName: asset.assetName,
        assetType: asset.assetType.isEmpty ? null : asset.assetType,
        serialNumber: asset.assetCode.isEmpty ? null : asset.assetCode,
        categoryId: asset.categoryId,
        assetGroup: asset.assetGroup.isEmpty ? null : asset.assetGroup,
        assetModel: asset.assetModel.isEmpty ? null : asset.assetModel,
      ));
    assetCache = [];
    return mapAsset(spAsset);
  }

  Future<void> deleteAsset(int assetId) async {
    await client.reference.deleteAsset(assetId);
    assetCache = [];
  }

  // ════════════════════════════════════════════════════════════
  // DEPARTMENT (Phòng ban)
  // ════════════════════════════════════════════════════════════

  Future<List<Department>> getDepartments() async {
    final depts = await client.reference.getDepartments();
    final seen = <int>{};
    return depts
        .where((d) => d.id != null && d.id! > 0)
        .map((d) => Department(deptId: d.id!, deptName: d.name))
        .where((d) => seen.add(d.deptId))
        .toList();
  }

  Future<Department> upsertDepartment(Department dept) async {
    final spDept = await client.reference.upsertDepartment(
      sp.Department(
        id: dept.deptId == 0 ? null : dept.deptId,
        name: dept.deptName,
      ),
    );
    return Department(deptId: spDept.id ?? 0, deptName: spDept.name);
  }

  Future<void> deleteDepartment(int deptId) async {
    await client.reference.deleteDepartment(deptId);
  }

  // ════════════════════════════════════════════════════════════
  // EMERGENCY CONTACT (Liên hệ khẩn cấp)
  // ════════════════════════════════════════════════════════════

  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final list = await client.reference.getEmergencyContacts();
    return list.map((e) => EmergencyContact.fromSp(e)).toList();
  }

  Future<EmergencyContact> upsertEmergencyContact(
      EmergencyContact contact) async {
    final spContact = sp.EmergencyContact(
      id: contact.id,
      userId: contact.userId,
      name: contact.name,
      phoneNumber: contact.phoneNumber,
      description: contact.description,
      sortOrder: contact.sortOrder,
    );
    final result =
        await client.reference.upsertEmergencyContact(spContact);
    return EmergencyContact.fromSp(result);
  }

  Future<void> deleteEmergencyContact(int id) async {
    await client.reference.deleteEmergencyContact(id);
  }
}
