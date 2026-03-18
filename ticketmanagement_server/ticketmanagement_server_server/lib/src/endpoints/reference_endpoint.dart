import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Handles reference data: categories, assets, departments, emergency contacts.
/// Access via `client.reference` on the Flutter client.
class ReferenceEndpoint extends Endpoint {
  Future<List<Category>> getCategories(Session session) async {
    return Category.db.find(session);
  }

  /// Admin: create or update a category.
  Future<Category> upsertCategory(Session session, Category cat) async {
    if (cat.id == null) return Category.db.insertRow(session, cat);
    return Category.db.updateRow(session, cat);
  }

  /// Admin: delete a category by id.
  Future<void> deleteCategory(Session session, int id) async {
    final cat = await Category.db.findById(session, id);
    if (cat != null) await Category.db.deleteRow(session, cat);
  }

  Future<List<Asset>> getAssets(Session session) async {
    return Asset.db.find(session);
  }

  /// Admin: create or update an asset.
  Future<Asset> upsertAsset(Session session, Asset asset) async {
    if (asset.id == null) return Asset.db.insertRow(session, asset);
    return Asset.db.updateRow(session, asset);
  }

  /// Admin: delete an asset by id.
  Future<void> deleteAsset(Session session, int id) async {
    final asset = await Asset.db.findById(session, id);
    if (asset != null) await Asset.db.deleteRow(session, asset);
  }

  Future<List<Department>> getDepartments(Session session) async {
    return Department.db.find(session);
  }

  // ── Emergency Contacts ──────────────────────────────────────────

  /// Public: any authenticated user can fetch Emergency Contacts.
  Future<List<EmergencyContact>> getEmergencyContacts(Session session) async {
    return EmergencyContact.db.find(
      session,
      orderBy: (t) => t.sortOrder,
    );
  }

  /// Admin only: create or update an EmergencyContact.
  Future<EmergencyContact> upsertEmergencyContact(
      Session session, EmergencyContact contact) async {
    if (contact.id == null) {
      return EmergencyContact.db.insertRow(session, contact);
    } else {
      return EmergencyContact.db.updateRow(session, contact);
    }
  }

  /// Admin only: delete an EmergencyContact by id.
  Future<void> deleteEmergencyContact(Session session, int id) async {
    final contact = await EmergencyContact.db.findById(session, id);
    if (contact != null) {
      await EmergencyContact.db.deleteRow(session, contact);
    }
  }
}
