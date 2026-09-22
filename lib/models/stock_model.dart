import 'user_model.dart';

class StockModel {
  final String id, name, sku, category, description, imageUrl;
  final double purchasePrice, sellingPrice;
  final int addedQuantity, soldQuantity, remainingQuantity, lowStockLimit;
  final DateTime? addedDate, lastUpdatedAt;
  final String lastUpdatedByUid, lastUpdatedByName, lastUpdatedByEmail;
  const StockModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.addedQuantity,
    required this.soldQuantity,
    required this.remainingQuantity,
    required this.lowStockLimit,
    this.addedDate,
    this.lastUpdatedAt,
    required this.lastUpdatedByUid,
    required this.lastUpdatedByName,
    required this.lastUpdatedByEmail,
  });
  bool get isLow => remainingQuantity <= lowStockLimit;
  factory StockModel.fromMap(Map<String, dynamic> d) => StockModel(
    id: d['id'],
    name: d['name'],
    sku: d['sku'],
    category: d['category'],
    description: (d['description'] as String? ?? ''),
    imageUrl: (d['imageUrl'] as String? ?? ''),
    purchasePrice: (d['purchasePrice'] as num? ?? 0).toDouble(),
    sellingPrice: (d['sellingPrice'] as num).toDouble(),
    addedQuantity: (d['addedQuantity'] as num).toInt(),
    soldQuantity: (d['soldQuantity'] as num).toInt(),
    remainingQuantity: (d['remainingQuantity'] as num).toInt(),
    lowStockLimit: (d['lowStockLimit'] as num? ?? 5).toInt(),
    addedDate: readDate(d['addedDate']),
    lastUpdatedAt: readDate(d['lastUpdatedAt']),
    lastUpdatedByUid: d['lastUpdatedByUid'],
    lastUpdatedByName: (d['lastUpdatedByName'] as String? ?? ''),
    lastUpdatedByEmail: (d['lastUpdatedByEmail'] as String? ?? ''),
  );
}

class StockUpdate {
  final String id,
      productId,
      productName,
      updateType,
      note,
      updatedByUid,
      updatedByName,
      updatedByEmail;
  final int previousQuantity, changedQuantity, newQuantity;
  final DateTime? createdAt;
  StockUpdate.fromMap(Map<String, dynamic> d)
    : id = d['id'],
      productId = d['productId'],
      productName = d['productName'],
      updateType = d['updateType'],
      note = (d['note'] as String? ?? ''),
      updatedByUid = d['updatedByUid'],
      updatedByName = (d['updatedByName'] as String? ?? ''),
      updatedByEmail = (d['updatedByEmail'] as String? ?? ''),
      previousQuantity = (d['previousQuantity'] as num).toInt(),
      changedQuantity = (d['changedQuantity'] as num).toInt(),
      newQuantity = (d['newQuantity'] as num).toInt(),
      createdAt = readDate(d['createdAt']);
}
