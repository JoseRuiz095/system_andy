import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

const Uuid _uuidGenerator = Uuid();

String _newUuid() => _uuidGenerator.v4();

String _dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y$m$d';
}

DateTime _utcNow() => DateTime.now().toUtc();

double _money(double value) => double.parse(value.toStringAsFixed(2));

int _toCents(double value) => (value * 100).round();

mixin SyncEntity on Table {
  TextColumn get uuid => text().clientDefault(_newUuid).unique()();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

class Branches extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 2, max: 20).unique()();
  TextColumn get name => text().withLength(min: 2, max: 120)();
  TextColumn get address => text().nullable()();
  BoolColumn get allowNegativeInventory =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class Users extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 3, max: 64).unique()();
  TextColumn get email => text().nullable().unique()();
  TextColumn get fullName => text().withLength(min: 3, max: 120)();
  TextColumn get passwordHash => text().nullable()();
  TextColumn get passwordAlgo => text().withDefault(const Constant('bcrypt'))();
  TextColumn get pinHash => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastAccessAt => dateTime().nullable()();
  IntColumn get failedAttempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get blockedAt => dateTime().nullable()();
  DateTimeColumn get passwordChangedAt => dateTime().nullable()();
  BoolColumn get forcePasswordChange =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get twoFactorEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get twoFactorSecret => text().nullable()();

  @override
  List<String> get customConstraints => [
        "CHECK(status IN ('active','pending','blocked'))",
      ];
}

class Roles extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 2, max: 40).unique()();
  TextColumn get name => text().withLength(min: 3, max: 80)();
  TextColumn get description => text().nullable()();
}

class Permissions extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 2, max: 80).unique()();
  TextColumn get name => text().withLength(min: 3, max: 100)();
}

class UserRoles extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  IntColumn get roleId =>
      integer().references(Roles, #id, onDelete: KeyAction.cascade)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {userId, roleId},
      ];
}

class RolePermissions extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get roleId =>
      integer().references(Roles, #id, onDelete: KeyAction.cascade)();
  IntColumn get permissionId =>
      integer().references(Permissions, #id, onDelete: KeyAction.cascade)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {roleId, permissionId},
      ];
}

class Units extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 1, max: 20).unique()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get symbol => text().withLength(min: 1, max: 10)();
  IntColumn get precisionScale => integer().withDefault(const Constant(2))();
}

class Suppliers extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 3, max: 120)();
  TextColumn get contactName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
}

class Products extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text().withLength(min: 2, max: 60).unique()();
  TextColumn get name => text().withLength(min: 2, max: 120)();
  TextColumn get category => text().nullable()();
  IntColumn get unitId =>
      integer().references(Units, #id, onDelete: KeyAction.restrict)();
  IntColumn get supplierId => integer()
      .nullable()
      .references(Suppliers, #id, onDelete: KeyAction.setNull)();
  IntColumn get unitPrice => integer()();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  RealColumn get defaultTaxRate => real().withDefault(const Constant(0.16))();
  BoolColumn get trackStock => boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  List<String> get customConstraints => [
        'CHECK(unit_price >= 0)',
        'CHECK(cost_price >= 0)',
        'CHECK(default_tax_rate >= 0)',
      ];
}

class ProductVariants extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.cascade)();
  TextColumn get code => text().withLength(min: 1, max: 30)();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get priceDelta => integer().withDefault(const Constant(0))();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {productId, code},
      ];

  @override
  List<String> get customConstraints => [
        'CHECK(cost_price >= 0)',
      ];
}

class Modifiers extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 1, max: 30).unique()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get price => integer().withDefault(const Constant(0))();
  RealColumn get taxRate => real().withDefault(const Constant(0.16))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  List<String> get customConstraints => [
        'CHECK(price >= 0)',
        'CHECK(tax_rate >= 0)',
      ];
}

class ProductModifiers extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.cascade)();
  IntColumn get modifierId =>
      integer().references(Modifiers, #id, onDelete: KeyAction.cascade)();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  IntColumn get minSelection => integer().withDefault(const Constant(0))();
  IntColumn get maxSelection => integer().withDefault(const Constant(10))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {productId, modifierId},
      ];
}

class Inventory extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.cascade)();
  IntColumn get branchId =>
      integer().references(Branches, #id, onDelete: KeyAction.restrict)();
  RealColumn get quantityOnHand => real().withDefault(const Constant(0))();
  RealColumn get reorderLevel => real().withDefault(const Constant(0))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {productId, branchId},
      ];

  @override
  List<String> get customConstraints => [
        'CHECK(reorder_level >= 0)',
      ];
}

class InventoryBatches extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  IntColumn get branchId =>
      integer().references(Branches, #id, onDelete: KeyAction.restrict)();
  TextColumn get batchCode => text().withLength(min: 1, max: 40)();
  RealColumn get quantity => real()();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  DateTimeColumn get receivedAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get expirationDate => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {productId, branchId, batchCode},
      ];

  @override
  List<String> get customConstraints => [
        'CHECK(quantity >= 0)',
        'CHECK(cost_price >= 0)',
      ];
}

class InventoryMovements extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  IntColumn get branchId =>
      integer().references(Branches, #id, onDelete: KeyAction.restrict)();
  IntColumn get unitId =>
      integer().references(Units, #id, onDelete: KeyAction.restrict)();
  IntColumn get batchId => integer()
      .nullable()
      .references(InventoryBatches, #id, onDelete: KeyAction.setNull)();
  IntColumn get userId => integer()
      .nullable()
      .references(Users, #id, onDelete: KeyAction.setNull)();
  TextColumn get movementType => text()();
  RealColumn get quantity => real()();
  TextColumn get reason => text().nullable()();
  TextColumn get referenceType => text().nullable()();
  TextColumn get referenceUuid => text().nullable()();

  @override
  List<String> get customConstraints => [
        'CHECK(quantity > 0)',
        "CHECK(movement_type IN ('in','out','adjustment','waste','sale_return','purchase'))",
      ];
}

class PaymentMethods extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().withLength(min: 2, max: 30).unique()();
  TextColumn get name => text().withLength(min: 2, max: 60)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class CashRegisters extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get branchId =>
      integer().references(Branches, #id, onDelete: KeyAction.restrict)();
  IntColumn get openedByUserId =>
      integer().references(Users, #id, onDelete: KeyAction.restrict)();
  IntColumn get closedByUserId => integer()
      .nullable()
      .references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get openedAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get closedAt => dateTime().nullable()();
  IntColumn get openingAmount => integer()();
  IntColumn get expectedAmount => integer().nullable()();
  IntColumn get countedAmount => integer().nullable()();
  IntColumn get differenceAmount => integer().nullable()();
  IntColumn get closingAmount => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('open'))();

  @override
  List<String> get customConstraints => [
        'CHECK(opening_amount >= 0)',
        'CHECK(expected_amount IS NULL OR expected_amount >= 0)',
        'CHECK(counted_amount IS NULL OR counted_amount >= 0)',
        'CHECK(closing_amount IS NULL OR closing_amount >= 0)',
        "CHECK(status IN ('open','closed'))",
      ];
}

class UserSessions extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.restrict)();
  IntColumn get cashRegisterId => integer()
      .nullable()
      .references(CashRegisters, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get loginAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get logoutAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class Sales extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get saleNumber => text().withLength(min: 3, max: 50).unique()();
  IntColumn get branchId =>
      integer().references(Branches, #id, onDelete: KeyAction.restrict)();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.restrict)();
  IntColumn get userSessionId => integer()
      .nullable()
      .references(UserSessions, #id, onDelete: KeyAction.setNull)();
  IntColumn get cashRegisterId => integer()
      .nullable()
      .references(CashRegisters, #id, onDelete: KeyAction.setNull)();
  TextColumn get deviceId =>
      text().withDefault(const Constant('unknown-device'))();
  TextColumn get idempotencyKey => text().nullable().unique()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  IntColumn get subtotal => integer()();
  IntColumn get discount => integer().withDefault(const Constant(0))();
  IntColumn get tax => integer().withDefault(const Constant(0))();
  IntColumn get total => integer()();
  DateTimeColumn get soldAt => dateTime().clientDefault(_utcNow)();

  @override
  List<String> get customConstraints => [
        'CHECK(subtotal >= 0)',
        'CHECK(discount >= 0)',
        'CHECK(tax >= 0)',
        'CHECK(total >= 0)',
        "CHECK(status IN ('draft','pending','in_progress','completed','cancelled','refunded'))",
      ];
}

class SaleItems extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId =>
      integer().references(Sales, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId =>
      integer().references(Products, #id, onDelete: KeyAction.restrict)();
  IntColumn get productVariantId => integer()
      .nullable()
      .references(ProductVariants, #id, onDelete: KeyAction.setNull)();
  RealColumn get quantity => real()();
  IntColumn get unitPrice => integer()();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0))();
  IntColumn get discountAmount => integer().withDefault(const Constant(0))();
  RealColumn get taxRate => real().withDefault(const Constant(0.16))();
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  IntColumn get lineSubtotal => integer().withDefault(const Constant(0))();
  IntColumn get lineTotal => integer().withDefault(const Constant(0))();

  @override
  List<String> get customConstraints => [
        'CHECK(quantity > 0)',
        'CHECK(unit_price >= 0)',
        'CHECK(cost_price >= 0)',
        'CHECK(discount_percent >= 0 AND discount_percent <= 100)',
        'CHECK(discount_amount >= 0)',
        'CHECK(tax_rate >= 0)',
        'CHECK(tax_amount >= 0)',
        'CHECK(line_subtotal >= 0)',
        'CHECK(line_total >= 0)',
      ];
}

class SaleItemModifiers extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleItemId =>
      integer().references(SaleItems, #id, onDelete: KeyAction.cascade)();
  IntColumn get modifierId =>
      integer().references(Modifiers, #id, onDelete: KeyAction.restrict)();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  IntColumn get unitPrice => integer().withDefault(const Constant(0))();
  IntColumn get total => integer().withDefault(const Constant(0))();

  @override
  List<String> get customConstraints => [
        'CHECK(quantity > 0)',
        'CHECK(unit_price >= 0)',
        'CHECK(total >= 0)',
      ];
}

class Payments extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId =>
      integer().references(Sales, #id, onDelete: KeyAction.cascade)();
  IntColumn get paymentMethodId =>
      integer().references(PaymentMethods, #id, onDelete: KeyAction.restrict)();
  TextColumn get deviceId =>
      text().withDefault(const Constant('unknown-device'))();
  TextColumn get idempotencyKey => text().nullable().unique()();
  IntColumn get amount => integer()();
  IntColumn get receivedAmount => integer().nullable()();
  IntColumn get changeAmount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('applied'))();

  @override
  List<String> get customConstraints => [
        'CHECK(amount >= 0)',
        "CHECK(status IN ('applied','void'))",
      ];
}

class Refunds extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId =>
      integer().references(Sales, #id, onDelete: KeyAction.cascade)();
  IntColumn get branchId =>
      integer().references(Branches, #id, onDelete: KeyAction.restrict)();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.restrict)();
  IntColumn get cashRegisterId => integer()
      .nullable()
      .references(CashRegisters, #id, onDelete: KeyAction.setNull)();
  TextColumn get idempotencyKey => text().nullable().unique()();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  IntColumn get subtotal => integer().withDefault(const Constant(0))();
  IntColumn get tax => integer().withDefault(const Constant(0))();
  IntColumn get total => integer().withDefault(const Constant(0))();
  TextColumn get reason => text().nullable()();

  @override
  List<String> get customConstraints => [
        'CHECK(subtotal >= 0)',
        'CHECK(tax >= 0)',
        'CHECK(total >= 0)',
        "CHECK(status IN ('pending','completed','void'))",
      ];
}

class RefundItems extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get refundId =>
      integer().references(Refunds, #id, onDelete: KeyAction.cascade)();
  IntColumn get saleItemId =>
      integer().references(SaleItems, #id, onDelete: KeyAction.restrict)();
  RealColumn get quantity => real()();
  IntColumn get unitPrice => integer().withDefault(const Constant(0))();
  RealColumn get taxRate => real().withDefault(const Constant(0))();
  IntColumn get subtotal => integer().withDefault(const Constant(0))();
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  IntColumn get total => integer().withDefault(const Constant(0))();
  TextColumn get reason => text().nullable()();

  @override
  List<String> get customConstraints => [
        'CHECK(quantity > 0)',
        'CHECK(unit_price >= 0)',
        'CHECK(tax_rate >= 0)',
        'CHECK(subtotal >= 0)',
        'CHECK(tax_amount >= 0)',
        'CHECK(total >= 0)',
      ];
}

class Receipts extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get branchId =>
      integer().references(Branches, #id, onDelete: KeyAction.restrict)();
  IntColumn get saleId =>
      integer().references(Sales, #id, onDelete: KeyAction.cascade)();
  TextColumn get receiptNumber => text().withLength(min: 3, max: 60).unique()();
  TextColumn get payloadJson => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {saleId},
      ];
}

class CashMovements extends Table with SyncEntity {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get branchId =>
      integer().references(Branches, #id, onDelete: KeyAction.restrict)();
  IntColumn get cashRegisterId =>
      integer().references(CashRegisters, #id, onDelete: KeyAction.cascade)();
  IntColumn get saleId => integer()
      .nullable()
      .references(Sales, #id, onDelete: KeyAction.setNull)();
  IntColumn get userId => integer()
      .nullable()
      .references(Users, #id, onDelete: KeyAction.setNull)();
  TextColumn get deviceId =>
      text().withDefault(const Constant('unknown-device'))();
  TextColumn get movementType => text()();
  IntColumn get amount => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get movedAt => dateTime().clientDefault(_utcNow)();

  @override
  List<String> get customConstraints => [
        'CHECK(amount >= 0)',
        "CHECK(movement_type IN ('opening','closing','income','expense','withdrawal','deposit','correction','refund'))",
      ];
}

class FolioSequences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get branchId =>
      integer().references(Branches, #id, onDelete: KeyAction.cascade)();
  TextColumn get docType => text().withLength(min: 2, max: 30)();
  TextColumn get workDate => text().withLength(min: 8, max: 8)();
  IntColumn get currentNumber => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {branchId, docType, workDate},
      ];
}

class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(_newUuid).unique()();
  TextColumn get entityTable => text()();
  TextColumn get rowUuid => text()();
  TextColumn get action => text()();
  TextColumn get eventAction =>
      text().withDefault(const Constant('unspecified'))();
  TextColumn get module => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get changedByUserId => integer()
      .nullable()
      .references(Users, #id, onDelete: KeyAction.setNull)();
  TextColumn get result => text().withDefault(const Constant('success'))();
  TextColumn get ipAddress => text().nullable()();
  TextColumn get deviceInfo => text().nullable()();
  TextColumn get oldValues => text().nullable()();
  TextColumn get newValues => text().nullable()();
  TextColumn get payloadJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();

  @override
  List<String> get customConstraints => [
        "CHECK(action IN ('insert','update','delete'))",
      ];
}

class SecuritySettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().withLength(min: 2, max: 80).unique()();
  TextColumn get value => text()();
  TextColumn get description => text().nullable()();
  IntColumn get updatedByUserId => integer()
      .nullable()
      .references(Users, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();
}

class SyncStatus extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().withLength(min: 1, max: 120).unique()();
  TextColumn get apiVersion => text().withDefault(const Constant('v1'))();
  IntColumn get serverTimeOffsetSeconds => integer().nullable()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  IntColumn get pendingEventsCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get failedEventsCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();
}

class FeatureFlags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().withLength(min: 2, max: 80).unique()();
  TextColumn get value => text()();
  TextColumn get scope => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('remote'))();
  DateTimeColumn get updatedAt => dateTime().clientDefault(_utcNow)();
}

class SyncOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId =>
      text().withDefault(const Constant('unknown-device'))();
  TextColumn get entityType => text()();
  TextColumn get entityUuid => text()();
  TextColumn get operation => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get apiVersion => text().withDefault(const Constant('v1'))();
  TextColumn get signature => text().nullable()();
  TextColumn get payloadJson => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(_utcNow)();

  @override
  List<String> get customConstraints => [
        "CHECK(operation IN ('insert','update','delete'))",
        "CHECK(status IN ('pending','processing','sent','failed','dead_letter'))",
      ];
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documents = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(documents.path, 'system_andy_pos.sqlite'));

    return NativeDatabase.createInBackground(
      dbFile,
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON;');
        rawDb.execute('PRAGMA journal_mode = WAL;');
        rawDb.execute('PRAGMA synchronous = NORMAL;');
      },
    );
  });
}

@DriftDatabase(
  tables: [
    Branches,
    Users,
    Roles,
    Permissions,
    UserRoles,
    RolePermissions,
    Units,
    Suppliers,
    Products,
    ProductVariants,
    Modifiers,
    ProductModifiers,
    Inventory,
    InventoryBatches,
    InventoryMovements,
    PaymentMethods,
    CashRegisters,
    UserSessions,
    Sales,
    SaleItems,
    SaleItemModifiers,
    Payments,
    Refunds,
    RefundItems,
    Receipts,
    CashMovements,
    FolioSequences,
    AuditLogs,
    SecuritySettings,
    SyncStatus,
    FeatureFlags,
    SyncOutbox,
  ],
  daos: [PosDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes();
          await _seedCatalogs();
          await _seedSecurityCatalogs();
          await _seedSecuritySettings();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 3) {
            await m.addColumn(branches, branches.allowNegativeInventory);
            await m.addColumn(cashRegisters, cashRegisters.expectedAmount);
            await m.addColumn(cashRegisters, cashRegisters.countedAmount);
            await m.addColumn(cashRegisters, cashRegisters.differenceAmount);
            await m.addColumn(auditLogs, auditLogs.oldValues);
            await m.addColumn(auditLogs, auditLogs.newValues);
            await m.createTable(refunds);
            await m.createTable(refundItems);
            await _createIndexes();
          }
          if (from < 4) {
            await m.addColumn(sales, sales.idempotencyKey);
            await m.addColumn(payments, payments.idempotencyKey);
            await m.addColumn(refunds, refunds.idempotencyKey);
            await _createIndexes();
          }
          if (from < 5) {
            await m.addColumn(sales, sales.deviceId);
            await m.addColumn(payments, payments.deviceId);
            await m.addColumn(cashMovements, cashMovements.deviceId);
            await m.addColumn(syncOutbox, syncOutbox.deviceId);
            await m.addColumn(syncOutbox, syncOutbox.apiVersion);
            await m.addColumn(syncOutbox, syncOutbox.signature);
            await m.createTable(syncStatus);
            await m.createTable(featureFlags);
          }
          if (from < 6) {
            await customStatement(
                "UPDATE sales SET device_id = 'legacy-device' WHERE device_id IS NULL OR TRIM(device_id) = ''; ");
            await customStatement(
                "UPDATE cash_movements SET device_id = 'legacy-device' WHERE device_id IS NULL OR TRIM(device_id) = ''; ");
            await customStatement(
                "UPDATE sync_outbox SET device_id = 'legacy-device' WHERE device_id IS NULL OR TRIM(device_id) = ''; ");

            await customStatement('''
              CREATE TABLE payments_v2 (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                uuid TEXT NOT NULL UNIQUE,
                sale_id INTEGER NOT NULL,
                payment_method_id INTEGER NOT NULL,
                device_id TEXT NOT NULL DEFAULT 'unknown-device',
                idempotency_key TEXT UNIQUE,
                amount INTEGER NOT NULL CHECK(amount >= 0),
                received_amount INTEGER,
                change_amount INTEGER NOT NULL DEFAULT 0,
                status TEXT NOT NULL DEFAULT 'applied' CHECK(status IN ('applied', 'void')),
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                deleted_at TEXT,
                is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
                FOREIGN KEY(sale_id) REFERENCES sales(id) ON DELETE CASCADE,
                FOREIGN KEY(payment_method_id) REFERENCES payment_methods(id) ON DELETE RESTRICT
              );
            ''');

            await customStatement('''
              INSERT INTO payments_v2 (
                id, uuid, sale_id, payment_method_id, device_id, idempotency_key,
                amount, received_amount, change_amount, status,
                created_at, updated_at, deleted_at, is_synced
              )
              SELECT
                id,
                uuid,
                sale_id,
                payment_method_id,
                COALESCE(NULLIF(TRIM(device_id), ''), 'legacy-device') AS device_id,
                idempotency_key,
                CAST(ROUND(amount * 100.0) AS INTEGER) AS amount,
                CASE
                  WHEN received_amount IS NULL THEN NULL
                  ELSE CAST(ROUND(received_amount * 100.0) AS INTEGER)
                END AS received_amount,
                CAST(ROUND(change_amount * 100.0) AS INTEGER) AS change_amount,
                status,
                created_at,
                updated_at,
                deleted_at,
                is_synced
              FROM payments;
            ''');

            await customStatement('DROP TABLE payments;');
            await customStatement(
                'ALTER TABLE payments_v2 RENAME TO payments;');

            await m.addColumn(syncOutbox, syncOutbox.status);
            await customStatement(
                "UPDATE sync_outbox SET status = 'pending' WHERE status IS NULL OR TRIM(status) = ''; ");

            await _createIndexes();
          }
          if (from < 7) {
            await customStatement(
                'UPDATE products SET unit_price = CAST(ROUND(unit_price * 100.0) AS INTEGER), cost_price = CAST(ROUND(cost_price * 100.0) AS INTEGER);');
            await customStatement(
                'UPDATE product_variants SET price_delta = CAST(ROUND(price_delta * 100.0) AS INTEGER), cost_price = CAST(ROUND(cost_price * 100.0) AS INTEGER);');
            await customStatement(
                'UPDATE modifiers SET price = CAST(ROUND(price * 100.0) AS INTEGER);');
            await customStatement(
                'UPDATE inventory_batches SET cost_price = CAST(ROUND(cost_price * 100.0) AS INTEGER);');

            await customStatement('''
              UPDATE cash_registers
              SET opening_amount = CAST(ROUND(opening_amount * 100.0) AS INTEGER),
                  expected_amount = CASE
                    WHEN expected_amount IS NULL THEN NULL
                    ELSE CAST(ROUND(expected_amount * 100.0) AS INTEGER)
                  END,
                  counted_amount = CASE
                    WHEN counted_amount IS NULL THEN NULL
                    ELSE CAST(ROUND(counted_amount * 100.0) AS INTEGER)
                  END,
                  difference_amount = CASE
                    WHEN difference_amount IS NULL THEN NULL
                    ELSE CAST(ROUND(difference_amount * 100.0) AS INTEGER)
                  END,
                  closing_amount = CASE
                    WHEN closing_amount IS NULL THEN NULL
                    ELSE CAST(ROUND(closing_amount * 100.0) AS INTEGER)
                  END;
            ''');

            await customStatement(
                'UPDATE sales SET subtotal = CAST(ROUND(subtotal * 100.0) AS INTEGER), discount = CAST(ROUND(discount * 100.0) AS INTEGER), tax = CAST(ROUND(tax * 100.0) AS INTEGER), total = CAST(ROUND(total * 100.0) AS INTEGER);');

            await customStatement(
                'UPDATE sale_items SET unit_price = CAST(ROUND(unit_price * 100.0) AS INTEGER), cost_price = CAST(ROUND(cost_price * 100.0) AS INTEGER), discount_amount = CAST(ROUND(discount_amount * 100.0) AS INTEGER), tax_amount = CAST(ROUND(tax_amount * 100.0) AS INTEGER), line_subtotal = CAST(ROUND(line_subtotal * 100.0) AS INTEGER), line_total = CAST(ROUND(line_total * 100.0) AS INTEGER);');

            await customStatement(
                'UPDATE sale_item_modifiers SET unit_price = CAST(ROUND(unit_price * 100.0) AS INTEGER), total = CAST(ROUND(total * 100.0) AS INTEGER);');

            await customStatement(
                'UPDATE refunds SET subtotal = CAST(ROUND(subtotal * 100.0) AS INTEGER), tax = CAST(ROUND(tax * 100.0) AS INTEGER), total = CAST(ROUND(total * 100.0) AS INTEGER);');

            await customStatement(
                'UPDATE refund_items SET unit_price = CAST(ROUND(unit_price * 100.0) AS INTEGER), subtotal = CAST(ROUND(subtotal * 100.0) AS INTEGER), tax_amount = CAST(ROUND(tax_amount * 100.0) AS INTEGER), total = CAST(ROUND(total * 100.0) AS INTEGER);');

            await customStatement(
                'UPDATE cash_movements SET amount = CAST(ROUND(amount * 100.0) AS INTEGER);');
          }
          if (from < 8) {
            await m.addColumn(users, users.email);
            await m.addColumn(users, users.status);
            await m.addColumn(users, users.lastAccessAt);
            await m.addColumn(users, users.failedAttempts);
            await m.addColumn(users, users.blockedAt);
            await m.addColumn(users, users.passwordChangedAt);
            await m.addColumn(users, users.forcePasswordChange);
            await m.addColumn(users, users.twoFactorEnabled);
            await m.addColumn(users, users.twoFactorSecret);

            await m.addColumn(auditLogs, auditLogs.eventAction);
            await m.addColumn(auditLogs, auditLogs.module);
            await m.addColumn(auditLogs, auditLogs.description);
            await m.addColumn(auditLogs, auditLogs.result);
            await m.addColumn(auditLogs, auditLogs.ipAddress);
            await m.addColumn(auditLogs, auditLogs.deviceInfo);

            await m.createTable(securitySettings);
            await _createIndexes();
            await _seedSecurityCatalogs();
            await _seedSecuritySettings();
          }
        },
      );

  Future<void> _seedCatalogs() async {
    await batch((b) {
      b.insertAll(branches, [
        BranchesCompanion.insert(code: 'MAIN', name: 'Sucursal Principal'),
      ]);

      b.insertAll(units, [
        UnitsCompanion.insert(code: 'pc', name: 'Pieza', symbol: 'pz'),
        UnitsCompanion.insert(code: 'gr', name: 'Gramo', symbol: 'g'),
        UnitsCompanion.insert(code: 'ml', name: 'Mililitro', symbol: 'ml'),
      ]);

      b.insertAll(paymentMethods, [
        PaymentMethodsCompanion.insert(code: 'cash', name: 'Efectivo'),
        PaymentMethodsCompanion.insert(code: 'card', name: 'Tarjeta'),
        PaymentMethodsCompanion.insert(code: 'transfer', name: 'Transferencia'),
      ]);
    });
  }

  Future<void> _seedSecurityCatalogs() async {
    final defaultPermissions = <(String, String)>[
      ('registrar_venta', 'Registrar venta'),
      ('procesar_cobro', 'Procesar cobro'),
      ('abrir_caja', 'Abrir caja'),
      ('cerrar_caja', 'Cerrar caja'),
      ('ajustar_inventario', 'Ajustar inventario'),
      ('gestionar_productos', 'Gestionar productos'),
      ('ver_reportes', 'Ver reportes'),
      ('cancelar_venta', 'Cancelar venta'),
      ('aplicar_descuento', 'Aplicar descuento'),
      ('configurar_sistema', 'Configurar sistema'),
    ];

    final defaultRoles = <(String, String, String)>[
      ('admin', 'Administrador', 'Acceso total al sistema POS'),
      ('cashier', 'Cajero', 'Operacion de caja y cobro'),
      ('barista', 'Barista', 'Operacion de venta basica y producto'),
    ];

    for (final role in defaultRoles) {
      await into(roles).insertOnConflictUpdate(
        RolesCompanion.insert(
          code: role.$1,
          name: role.$2,
          description: Value(role.$3),
        ),
      );
    }

    for (final permission in defaultPermissions) {
      await into(permissions).insertOnConflictUpdate(
        PermissionsCompanion.insert(code: permission.$1, name: permission.$2),
      );
    }

    final roleRows = await select(roles).get();
    final permissionRows = await select(permissions).get();
    final roleIdByCode = <String, int>{
      for (final role in roleRows) role.code: role.id,
    };
    final permissionIdByCode = <String, int>{
      for (final permission in permissionRows) permission.code: permission.id,
    };

    final rolePermissionsMap = <String, List<String>>{
      'admin': defaultPermissions.map((entry) => entry.$1).toList(),
      'cashier': [
        'registrar_venta',
        'procesar_cobro',
        'abrir_caja',
        'cerrar_caja',
        'cancelar_venta',
        'aplicar_descuento',
      ],
      'barista': [
        'registrar_venta',
        'ajustar_inventario',
      ],
    };

    for (final roleCode in rolePermissionsMap.keys) {
      final roleId = roleIdByCode[roleCode];
      if (roleId == null) continue;
      for (final permissionCode in rolePermissionsMap[roleCode]!) {
        final permissionId = permissionIdByCode[permissionCode];
        if (permissionId == null) continue;
        await into(rolePermissions).insertOnConflictUpdate(
          RolePermissionsCompanion.insert(
            roleId: roleId,
            permissionId: permissionId,
          ),
        );
      }
    }

    const adminUsername = 'admin';
    final existingAdmin = await (select(users)
          ..where((u) => u.username.equals(adminUsername)))
        .getSingleOrNull();

    if (existingAdmin == null) {
      final bcryptHash =
          BCrypt.hashpw('Admin123!', BCrypt.gensalt(logRounds: 12));
      final adminId = await into(users).insert(
        UsersCompanion.insert(
          username: adminUsername,
          email: const Value('admin@andys.cafe'),
          fullName: 'Administrador Andy',
          passwordHash: Value(bcryptHash),
          passwordAlgo: const Value('bcrypt'),
          status: const Value('active'),
          isActive: const Value(true),
          passwordChangedAt: Value(_utcNow()),
        ),
      );

      final adminRoleId = roleIdByCode['admin'];
      if (adminRoleId != null) {
        await into(userRoles).insertOnConflictUpdate(
          UserRolesCompanion.insert(userId: adminId, roleId: adminRoleId),
        );
      }
    }
  }

  Future<void> _seedSecuritySettings() async {
    final defaults = <(String, String, String)>[
      ('session_expiration_minutes', '480', 'Tiempo maximo de sesion activa'),
      (
        'force_password_rotation',
        'true',
        'Solicitar cambio periodico de contrasena'
      ),
      (
        'strong_password_required',
        'true',
        'Aplicar politica de contrasena fuerte'
      ),
      (
        'two_factor_enabled',
        'false',
        'Activar segundo factor en autenticacion'
      ),
      ('mask_sensitive_data', 'true', 'Ocultar datos sensibles en pantalla'),
      ('max_failed_attempts', '5', 'Intentos fallidos antes de bloqueo'),
      ('lockout_minutes', '15', 'Minutos de bloqueo por seguridad'),
    ];

    for (final setting in defaults) {
      await into(securitySettings).insertOnConflictUpdate(
        SecuritySettingsCompanion.insert(
          key: setting.$1,
          value: setting.$2,
          description: Value(setting.$3),
        ),
      );
    }
  }

  Future<void> _createIndexes() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sales_branch_sold_at ON sales(branch_id, sold_at DESC);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sales_branch_date ON sales(branch_id, created_at DESC);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sales_user_id_sold_at ON sales(user_id, sold_at DESC);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(status, sold_at DESC);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sale_items_product_id ON sale_items(product_id);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_payments_sale_id ON payments(sale_id);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_inventory_branch_product ON inventory(branch_id, product_id);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_inventory_product_branch ON inventory(product_id, branch_id);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_inventory_movements_branch_product_created ON inventory_movements(branch_id, product_id, created_at DESC);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_inventory_batches_expiry ON inventory_batches(branch_id, product_id, expiration_date);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_cash_movements_branch_moved ON cash_movements(branch_id, moved_at DESC);');
    await customStatement(
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_cash_registers_open_branch ON cash_registers(branch_id) WHERE status = 'open';");
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_user_sessions_active ON user_sessions(user_id, is_active, login_at DESC);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_row ON audit_logs(entity_table, row_uuid, created_at DESC);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_users_status ON users(status, is_active, updated_at DESC);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_users_failed_attempts ON users(failed_attempts, blocked_at);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_role_permissions_role_id ON role_permissions(role_id);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_audit_logs_security ON audit_logs(module, event_action, result, created_at DESC);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_security_settings_key ON security_settings(key);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sync_status_device ON sync_status(device_id);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_feature_flags_scope ON feature_flags(scope, key);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sync_outbox_entity ON sync_outbox(entity_type, entity_uuid, created_at DESC);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sync_outbox_device ON sync_outbox(device_id, created_at DESC);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sync_outbox_status ON sync_outbox(status, created_at DESC);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_refunds_sale ON refunds(sale_id, created_at DESC);');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_refund_items_sale_item ON refund_items(sale_item_id, created_at DESC);');
  }
}

class SaleLineInput {
  const SaleLineInput({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.productVariantId,
    this.costPrice = 0,
    this.discountPercent = 0,
    this.discountAmount,
    this.taxRate = 0.16,
  });

  final int productId;
  final int? productVariantId;
  final double quantity;
  final double unitPrice;
  final double costPrice;
  final double discountPercent;
  final double? discountAmount;
  final double taxRate;
}

class PaymentInput {
  const PaymentInput({
    required this.paymentMethodId,
    required this.amount,
    this.receivedAmount,
    this.changeAmount = 0,
    this.status = 'applied',
    this.idempotencyKey,
  });

  final int paymentMethodId;
  final double amount;
  final double? receivedAmount;
  final double changeAmount;
  final String status;
  final String? idempotencyKey;
}

class RefundLineInput {
  const RefundLineInput({
    required this.saleItemId,
    required this.quantity,
    this.reason,
  });

  final int saleItemId;
  final double quantity;
  final String? reason;
}

class DailySalesReportRow {
  DailySalesReportRow(
      {required this.day, required this.tickets, required this.total});

  final DateTime day;
  final int tickets;
  final double total;
}

class SecurityUserView {
  const SecurityUserView({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.lastAccessAt,
    required this.failedAttempts,
    required this.blockedAt,
  });

  final int id;
  final String username;
  final String? email;
  final String fullName;
  final String role;
  final String status;
  final DateTime createdAt;
  final DateTime? lastAccessAt;
  final int failedAttempts;
  final DateTime? blockedAt;
}

class RolePermissionView {
  const RolePermissionView({
    required this.roleId,
    required this.roleCode,
    required this.roleName,
    required this.permissions,
  });

  final int roleId;
  final String roleCode;
  final String roleName;
  final Set<String> permissions;
}

class SecurityAuditLogView {
  const SecurityAuditLogView({
    required this.id,
    required this.createdAt,
    required this.user,
    required this.eventAction,
    required this.module,
    required this.description,
    required this.result,
    required this.ipAddress,
    required this.deviceInfo,
  });

  final int id;
  final DateTime createdAt;
  final String user;
  final String eventAction;
  final String module;
  final String description;
  final String result;
  final String ipAddress;
  final String deviceInfo;
}

class SecurityAuditFilter {
  const SecurityAuditFilter({
    this.from,
    this.to,
    this.userId,
    this.eventAction,
    this.module,
    this.search,
    this.limit = 20,
    this.offset = 0,
  });

  final DateTime? from;
  final DateTime? to;
  final int? userId;
  final String? eventAction;
  final String? module;
  final String? search;
  final int limit;
  final int offset;
}

class SecuritySettingView {
  const SecuritySettingView({
    required this.key,
    required this.value,
    required this.description,
    required this.updatedAt,
    required this.updatedByUserId,
  });

  final String key;
  final String value;
  final String? description;
  final DateTime updatedAt;
  final int? updatedByUserId;
}

class _ComputedLine {
  _ComputedLine({
    required this.subtotalCents,
    required this.discountAmountCents,
    required this.taxAmountCents,
    required this.totalCents,
  });

  final int subtotalCents;
  final int discountAmountCents;
  final int taxAmountCents;
  final int totalCents;
}

@DriftAccessor(
  tables: [
    Branches,
    Units,
    Products,
    Inventory,
    InventoryBatches,
    InventoryMovements,
    UserSessions,
    Sales,
    SaleItems,
    Refunds,
    RefundItems,
    Payments,
    PaymentMethods,
    CashRegisters,
    CashMovements,
    Receipts,
    FolioSequences,
    AuditLogs,
    SecuritySettings,
    Users,
    Roles,
    Permissions,
    UserRoles,
    RolePermissions,
  ],
)
class PosDao extends DatabaseAccessor<AppDatabase> with _$PosDaoMixin {
  PosDao(super.db);

  Future<bool> _branchAllowsNegativeInventory(int branchId) async {
    final branch = await (select(branches)..where((b) => b.id.equals(branchId)))
        .getSingle();
    return branch.allowNegativeInventory;
  }

  _ComputedLine _computeLine(SaleLineInput item) {
    final grossCents = _toCents(item.quantity * item.unitPrice);
    final percentDiscountCents =
        ((grossCents * item.discountPercent) / 100.0).round();
    final absoluteDiscountCents = _toCents(item.discountAmount ?? 0);
    final discountCents =
        ((percentDiscountCents + absoluteDiscountCents).clamp(0, grossCents))
            .toInt();
    final subtotalCents =
        ((grossCents - discountCents).clamp(0, 1 << 30)).toInt();
    final taxAmountCents = (subtotalCents * item.taxRate).round();
    final totalCents = subtotalCents + taxAmountCents;

    return _ComputedLine(
      subtotalCents: subtotalCents,
      discountAmountCents: discountCents,
      taxAmountCents: taxAmountCents,
      totalCents: totalCents,
    );
  }

  Future<int> startUserSession({
    required int userId,
    int? cashRegisterId,
  }) async {
    return into(userSessions).insert(
      UserSessionsCompanion.insert(
        userId: userId,
        cashRegisterId: Value(cashRegisterId),
      ),
    );
  }

  Future<void> closeUserSession(int sessionId) async {
    await (update(userSessions)..where((t) => t.id.equals(sessionId))).write(
      UserSessionsCompanion(
        isActive: const Value(false),
        logoutAt: Value(_utcNow()),
        updatedAt: Value(_utcNow()),
        isSynced: const Value(false),
      ),
    );
  }

  Future<int> openCashRegister({
    required int branchId,
    required int openedByUserId,
    required double openingAmount,
  }) async {
    return transaction(() async {
      final openRegisters = await (select(cashRegisters)
            ..where(
                (t) => t.branchId.equals(branchId) & t.status.equals('open')))
          .get();
      if (openRegisters.isNotEmpty) {
        throw StateError(
            'Ya existe una caja abierta en la sucursal $branchId.');
      }

      final registerId = await into(cashRegisters).insert(
        CashRegistersCompanion.insert(
          branchId: branchId,
          openedByUserId: openedByUserId,
          openingAmount: _toCents(openingAmount),
          status: const Value('open'),
        ),
      );

      await into(cashMovements).insert(
        CashMovementsCompanion.insert(
          branchId: branchId,
          cashRegisterId: registerId,
          movementType: 'opening',
          amount: _toCents(openingAmount),
          userId: Value(openedByUserId),
          note: const Value('Apertura de caja'),
        ),
      );

      return registerId;
    });
  }

  Future<void> closeCashRegister({
    required int registerId,
    required int closedByUserId,
    required double countedAmount,
  }) async {
    await transaction(() async {
      final register = await (select(cashRegisters)
            ..where((t) => t.id.equals(registerId)))
          .getSingle();

      final movementRows = await customSelect(
        '''
        SELECT COALESCE(SUM(
          CASE
            WHEN movement_type IN ('opening', 'income', 'deposit', 'correction') THEN amount
            WHEN movement_type IN ('expense', 'withdrawal', 'refund') THEN -amount
            ELSE 0
          END
        ), 0) AS expected_amount
        FROM cash_movements
        WHERE cash_register_id = ?
          AND deleted_at IS NULL
        ''',
        variables: [Variable<int>(registerId)],
        readsFrom: {cashMovements},
      ).getSingle();

      final expectedAmountCents = movementRows.read<int>('expected_amount');
      final countedAmountCents = _toCents(countedAmount);
      final differenceCents = countedAmountCents - expectedAmountCents;

      await (update(cashRegisters)..where((t) => t.id.equals(registerId)))
          .write(
        CashRegistersCompanion(
          status: const Value('closed'),
          closedByUserId: Value(closedByUserId),
          closedAt: Value(_utcNow()),
          expectedAmount: Value(expectedAmountCents),
          countedAmount: Value(countedAmountCents),
          differenceAmount: Value(differenceCents),
          closingAmount: Value(countedAmountCents),
          updatedAt: Value(_utcNow()),
          isSynced: const Value(false),
        ),
      );

      await into(cashMovements).insert(
        CashMovementsCompanion.insert(
          branchId: register.branchId,
          cashRegisterId: registerId,
          movementType: 'closing',
          amount: countedAmountCents,
          userId: Value(closedByUserId),
          note: const Value('Cierre de caja'),
        ),
      );
    });
  }

  Future<int> registerInventoryMovement({
    required int branchId,
    required int productId,
    required int unitId,
    required String movementType,
    required double quantity,
    int? batchId,
    int? userId,
    String? reason,
    String? referenceType,
    String? referenceUuid,
  }) async {
    return transaction(() async {
      final signal =
          movementType == 'out' || movementType == 'waste' ? -1.0 : 1.0;
      final allowsNegative = await _branchAllowsNegativeInventory(branchId);

      final inventoryRow = await customSelect(
        '''
        SELECT quantity_on_hand
        FROM inventory
        WHERE product_id = ?
          AND branch_id = ?
        LIMIT 1
        ''',
        variables: [Variable<int>(productId), Variable<int>(branchId)],
        readsFrom: {inventory},
      ).get();

      final currentQty = inventoryRow.isEmpty
          ? 0.0
          : inventoryRow.first.read<double>('quantity_on_hand');
      final projectedQty = currentQty + (signal * quantity);

      if (!allowsNegative && projectedQty < 0) {
        throw StateError(
            'Stock insuficiente para producto $productId en sucursal $branchId.');
      }

      await customStatement(
        'INSERT OR IGNORE INTO inventory (uuid, product_id, branch_id, quantity_on_hand, reorder_level, created_at, updated_at, is_synced) VALUES (?, ?, ?, 0, 0, ?, ?, 0);',
        [_newUuid(), productId, branchId, _utcNow(), _utcNow()],
      );

      await customStatement(
        'UPDATE inventory SET quantity_on_hand = quantity_on_hand + ?, updated_at = ?, is_synced = 0 WHERE product_id = ? AND branch_id = ?;',
        [signal * quantity, _utcNow(), productId, branchId],
      );

      final movementId = await into(inventoryMovements).insert(
        InventoryMovementsCompanion.insert(
          productId: productId,
          branchId: branchId,
          unitId: unitId,
          movementType: movementType,
          quantity: quantity,
          batchId: Value(batchId),
          userId: Value(userId),
          reason: Value(reason),
          referenceType: Value(referenceType),
          referenceUuid: Value(referenceUuid),
        ),
      );

      await _insertAudit(
        tableName: 'inventory_movements',
        rowUuid: _newUuid(),
        action: 'insert',
        changedByUserId: userId,
      );

      return movementId;
    });
  }

  Future<void> _consumeInventoryByFefo({
    required int branchId,
    required int productId,
    required int unitId,
    required double quantity,
    required int userId,
    required String saleUuid,
  }) async {
    var pending = quantity;
    final allowsNegative = await _branchAllowsNegativeInventory(branchId);

    final batches = await (select(inventoryBatches)
          ..where((b) =>
              b.branchId.equals(branchId) &
              b.productId.equals(productId) &
              b.quantity.isBiggerThanValue(0) &
              b.deletedAt.isNull())
          ..orderBy([
            (b) => OrderingTerm.asc(b.expirationDate),
            (b) => OrderingTerm.asc(b.receivedAt),
          ]))
        .get();

    for (final batch in batches) {
      if (pending <= 0) {
        break;
      }

      final consume = pending > batch.quantity ? batch.quantity : pending;
      if (consume <= 0) {
        continue;
      }

      await (update(inventoryBatches)..where((b) => b.id.equals(batch.id)))
          .write(
        InventoryBatchesCompanion(
          quantity: Value((batch.quantity - consume).toDouble()),
          updatedAt: Value(_utcNow()),
          isSynced: const Value(false),
        ),
      );

      await registerInventoryMovement(
        branchId: branchId,
        productId: productId,
        unitId: unitId,
        movementType: 'out',
        quantity: consume,
        batchId: batch.id,
        userId: userId,
        reason: 'Venta POS (FEFO)',
        referenceType: 'sale_item',
        referenceUuid: saleUuid,
      );

      pending -= consume;
    }

    if (pending > 0) {
      if (!allowsNegative) {
        throw StateError(
            'Stock insuficiente para aplicar FEFO en producto $productId. Pendiente: $pending');
      }

      await registerInventoryMovement(
        branchId: branchId,
        productId: productId,
        unitId: unitId,
        movementType: 'out',
        quantity: pending,
        userId: userId,
        reason: 'Venta POS (sin lote, negativo permitido)',
        referenceType: 'sale_item',
        referenceUuid: saleUuid,
      );
    }
  }

  Future<String> generateSaleNumber({
    required int branchId,
    required DateTime soldAt,
  }) async {
    return transaction(() async {
      final key = _dateKey(soldAt);
      final rows = await customSelect(
        '''
        INSERT INTO folio_sequences (branch_id, doc_type, work_date, current_number, updated_at)
        VALUES (?, 'sale', ?, 1, ?)
        ON CONFLICT(branch_id, doc_type, work_date)
        DO UPDATE SET
          current_number = current_number + 1,
          updated_at = excluded.updated_at
        RETURNING current_number;
        ''',
        variables: [
          Variable<int>(branchId),
          Variable<String>(key),
          Variable<DateTime>(_utcNow()),
        ],
        readsFrom: {folioSequences},
      ).getSingle();

      final nextNumber = rows.read<int>('current_number');

      return 'V-${branchId.toString().padLeft(2, '0')}-$key-${nextNumber.toString().padLeft(4, '0')}';
    });
  }

  Future<int> registerSale({
    required int branchId,
    required int userId,
    required List<SaleLineInput> items,
    required List<PaymentInput> paymentData,
    int? userSessionId,
    int? cashRegisterId,
    String status = 'completed',
    String? saleNumber,
    String? idempotencyKey,
    String? receiptNumber,
    DateTime? soldAt,
  }) async {
    return transaction(() async {
      if (items.isEmpty) {
        throw ArgumentError('La venta debe incluir al menos un item.');
      }

      final allowedStatuses = {
        'draft',
        'pending',
        'in_progress',
        'completed',
        'cancelled',
        'refunded',
      };
      if (!allowedStatuses.contains(status)) {
        throw ArgumentError('Estado de venta no valido: $status');
      }

      final at = soldAt ?? _utcNow();
      final folio = saleNumber ??
          await generateSaleNumber(
            branchId: branchId,
            soldAt: at,
          );

      final computedItems = items.map(_computeLine).toList();
      final subtotal =
          computedItems.fold<int>(0, (acc, e) => acc + e.subtotalCents);
      final tax =
          computedItems.fold<int>(0, (acc, e) => acc + e.taxAmountCents);
      final discount =
          computedItems.fold<int>(0, (acc, e) => acc + e.discountAmountCents);
      final total = subtotal + tax;
      final totalPaid =
          paymentData.fold<int>(0, (acc, p) => acc + _toCents(p.amount));

      final requiresSettlement = status == 'completed';
      if (requiresSettlement && paymentData.isEmpty) {
        throw StateError('Una venta completada requiere al menos un pago.');
      }
      if (requiresSettlement && totalPaid != total) {
        throw StateError(
            'La suma de pagos debe ser exactamente igual al total de la venta.');
      }

      final saleId = await into(sales).insert(
        SalesCompanion.insert(
          saleNumber: folio,
          branchId: branchId,
          userId: userId,
          userSessionId: Value(userSessionId),
          cashRegisterId: Value(cashRegisterId),
          idempotencyKey: Value(idempotencyKey),
          status: Value(status),
          subtotal: subtotal,
          discount: Value(discount),
          tax: Value(tax),
          total: total,
          soldAt: Value(at.toUtc()),
        ),
      );

      final sale =
          await (select(sales)..where((s) => s.id.equals(saleId))).getSingle();

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final computed = computedItems[i];

        final saleItemId = await into(saleItems).insert(
          SaleItemsCompanion.insert(
            saleId: saleId,
            productId: item.productId,
            productVariantId: Value(item.productVariantId),
            quantity: _money(item.quantity),
            unitPrice: _toCents(item.unitPrice),
            costPrice: Value(_toCents(item.costPrice)),
            discountPercent: Value(_money(item.discountPercent)),
            discountAmount: Value(computed.discountAmountCents),
            taxRate: Value(_money(item.taxRate)),
            taxAmount: Value(computed.taxAmountCents),
            lineSubtotal: Value(computed.subtotalCents),
            lineTotal: Value(computed.totalCents),
          ),
        );

        if (status == 'in_progress' || status == 'completed') {
          final product = await (select(products)
                ..where((p) => p.id.equals(item.productId)))
              .getSingle();

          await _consumeInventoryByFefo(
            branchId: branchId,
            productId: item.productId,
            unitId: product.unitId,
            quantity: item.quantity,
            userId: userId,
            saleUuid: sale.uuid,
          );

          await _insertAudit(
            tableName: 'sale_items',
            rowUuid: sale.uuid,
            action: 'insert',
            changedByUserId: userId,
            payloadJson: '{"sale_item_id":$saleItemId}',
          );
        }
      }

      for (final payment in paymentData) {
        await into(payments).insert(
          PaymentsCompanion.insert(
            saleId: saleId,
            paymentMethodId: payment.paymentMethodId,
            idempotencyKey: Value(payment.idempotencyKey),
            amount: _toCents(payment.amount),
            receivedAmount: Value(
              payment.receivedAmount == null
                  ? null
                  : _toCents(payment.receivedAmount!),
            ),
            changeAmount: Value(_toCents(payment.changeAmount)),
            status: Value(payment.status),
          ),
        );
      }

      if (receiptNumber != null && receiptNumber.isNotEmpty) {
        await into(receipts).insert(
          ReceiptsCompanion.insert(
            branchId: branchId,
            saleId: saleId,
            receiptNumber: receiptNumber,
          ),
        );
      }

      if (cashRegisterId != null && status == 'completed') {
        await into(cashMovements).insert(
          CashMovementsCompanion.insert(
            branchId: branchId,
            cashRegisterId: cashRegisterId,
            movementType: 'income',
            amount: total,
            saleId: Value(saleId),
            userId: Value(userId),
            note: Value('Venta $folio'),
          ),
        );
      }

      await _insertAudit(
        tableName: 'sales',
        rowUuid: sale.uuid,
        action: 'insert',
        changedByUserId: userId,
        payloadJson:
            '{"sale_number":"$folio","status":"$status","total_cents":$total}',
      );

      return saleId;
    });
  }

  Future<int> registerPartialRefund({
    required int saleId,
    required int userId,
    required List<RefundLineInput> items,
    int? cashRegisterId,
    String? idempotencyKey,
    String? reason,
  }) async {
    return transaction(() async {
      if (items.isEmpty) {
        throw ArgumentError('Debe indicar al menos un item para reembolso.');
      }

      final sale =
          await (select(sales)..where((s) => s.id.equals(saleId))).getSingle();
      if (sale.status != 'completed' && sale.status != 'refunded') {
        throw StateError('Solo se pueden reembolsar ventas completadas.');
      }

      var subtotal = 0;
      var tax = 0;
      var total = 0;

      final refundId = await into(refunds).insert(
        RefundsCompanion.insert(
          saleId: saleId,
          branchId: sale.branchId,
          userId: userId,
          cashRegisterId: Value(cashRegisterId),
          idempotencyKey: Value(idempotencyKey),
          reason: Value(reason),
          status: const Value('completed'),
        ),
      );

      for (final line in items) {
        final saleItem = await (select(saleItems)
              ..where((s) => s.id.equals(line.saleItemId)))
            .getSingle();
        if (saleItem.saleId != saleId) {
          throw StateError(
              'El saleItem ${line.saleItemId} no pertenece a la venta $saleId.');
        }
        if (line.quantity <= 0 || line.quantity > saleItem.quantity) {
          throw StateError(
              'Cantidad invalida para el item ${line.saleItemId}.');
        }

        final unitSubtotal = saleItem.lineSubtotal / saleItem.quantity;
        final unitTax = saleItem.taxAmount / saleItem.quantity;
        final lineSubtotal = (unitSubtotal * line.quantity).round();
        final lineTax = (unitTax * line.quantity).round();
        final lineTotal = lineSubtotal + lineTax;

        subtotal += lineSubtotal;
        tax += lineTax;
        total += lineTotal;

        await into(refundItems).insert(
          RefundItemsCompanion.insert(
            refundId: refundId,
            saleItemId: line.saleItemId,
            quantity: _money(line.quantity),
            unitPrice: Value(saleItem.unitPrice),
            taxRate: Value(saleItem.taxRate),
            subtotal: Value(lineSubtotal),
            taxAmount: Value(lineTax),
            total: Value(lineTotal),
            reason: Value(line.reason),
          ),
        );

        final product = await (select(products)
              ..where((p) => p.id.equals(saleItem.productId)))
            .getSingle();
        await registerInventoryMovement(
          branchId: sale.branchId,
          productId: saleItem.productId,
          unitId: product.unitId,
          movementType: 'sale_return',
          quantity: line.quantity,
          userId: userId,
          reason: 'Reembolso parcial',
          referenceType: 'refund',
          referenceUuid: sale.uuid,
        );
      }

      await (update(refunds)..where((r) => r.id.equals(refundId))).write(
        RefundsCompanion(
          subtotal: Value(subtotal),
          tax: Value(tax),
          total: Value(total),
          updatedAt: Value(_utcNow()),
          isSynced: const Value(false),
        ),
      );

      if (cashRegisterId != null) {
        await into(cashMovements).insert(
          CashMovementsCompanion.insert(
            branchId: sale.branchId,
            cashRegisterId: cashRegisterId,
            saleId: Value(saleId),
            userId: Value(userId),
            movementType: 'refund',
            amount: total,
            note: const Value('Reembolso parcial'),
          ),
        );
      }

      await _insertAudit(
        tableName: 'refunds',
        rowUuid: sale.uuid,
        action: 'insert',
        changedByUserId: userId,
        newValues:
            '{"sale_id":$saleId,"refund_id":$refundId,"total_cents":$total}',
      );

      return refundId;
    });
  }

  Future<List<Sale>> getRecoverableDraftSales({required int branchId}) {
    return (select(sales)
          ..where((s) =>
              s.branchId.equals(branchId) &
              s.deletedAt.isNull() &
              s.status.isIn(const ['draft', 'pending', 'in_progress']))
          ..orderBy([(s) => OrderingTerm.desc(s.updatedAt)]))
        .get();
  }

  Future<void> markSaleAsCancelled({
    required int saleId,
    required int userId,
    String? reason,
  }) async {
    final sale =
        await (select(sales)..where((s) => s.id.equals(saleId))).getSingle();
    await (update(sales)..where((s) => s.id.equals(saleId))).write(
      SalesCompanion(
        status: const Value('cancelled'),
        updatedAt: Value(_utcNow()),
        isSynced: const Value(false),
      ),
    );

    await _insertAudit(
      tableName: 'sales',
      rowUuid: sale.uuid,
      action: 'update',
      changedByUserId: userId,
      oldValues: '{"status":"${sale.status}"}',
      newValues: '{"status":"cancelled","reason":"${reason ?? ''}"}',
    );
  }

  Future<User?> findUserByIdentifier(String identifier) {
    final normalized = identifier.trim().toLowerCase();
    return (select(users)
          ..where((u) =>
              u.username.lower().equals(normalized) |
              u.email.lower().equals(normalized))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<Role?> findRoleByCode(String code) {
    return (select(roles)..where((r) => r.code.equals(code))).getSingleOrNull();
  }

  Future<int> createPendingUserAccount({
    required String username,
    required String? email,
    required String fullName,
    required String passwordHash,
    required String roleCode,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    return transaction(() async {
      final role = await findRoleByCode(roleCode);
      if (role == null) {
        throw StateError('No existe el rol solicitado: $roleCode');
      }

      final userId = await into(users).insert(
        UsersCompanion.insert(
          username: username,
          email: Value(email),
          fullName: fullName,
          passwordHash: Value(passwordHash),
          passwordAlgo: const Value('bcrypt'),
          status: const Value('pending'),
          isActive: const Value(true),
          passwordChangedAt: Value(_utcNow()),
        ),
      );

      await into(userRoles).insert(
        UserRolesCompanion.insert(userId: userId, roleId: role.id),
      );

      final created =
          await (select(users)..where((u) => u.id.equals(userId))).getSingle();
      await _insertAudit(
        tableName: 'users',
        rowUuid: created.uuid,
        action: 'insert',
        changedByUserId: userId,
        eventAction: 'user_registered',
        module: 'Seguridad',
        description: 'Nuevo usuario creado en estado pendiente.',
        result: 'success',
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );

      return userId;
    });
  }

  Future<void> closeAllActiveSessionsForUser(int userId) async {
    await (update(userSessions)
          ..where((s) => s.userId.equals(userId) & s.isActive.equals(true)))
        .write(
      UserSessionsCompanion(
        isActive: const Value(false),
        logoutAt: Value(_utcNow()),
        updatedAt: Value(_utcNow()),
        isSynced: const Value(false),
      ),
    );
  }

  Future<Set<String>> getPermissionCodesForUser(int userId) async {
    final rows = await customSelect(
      '''
      SELECT DISTINCT p.code
      FROM permissions p
      INNER JOIN role_permissions rp ON rp.permission_id = p.id
      INNER JOIN user_roles ur ON ur.role_id = rp.role_id
      WHERE ur.user_id = ?
      ''',
      variables: [Variable<int>(userId)],
      readsFrom: {permissions, rolePermissions, userRoles},
    ).get();

    return rows.map((row) => row.read<String>('code')).toSet();
  }

  Future<String?> getPrimaryRoleCodeForUser(int userId) async {
    final row = await customSelect(
      '''
      SELECT r.code
      FROM roles r
      INNER JOIN user_roles ur ON ur.role_id = r.id
      WHERE ur.user_id = ?
      ORDER BY CASE r.code WHEN 'admin' THEN 0 WHEN 'cashier' THEN 1 ELSE 2 END
      LIMIT 1
      ''',
      variables: [Variable<int>(userId)],
      readsFrom: {roles, userRoles},
    ).getSingleOrNull();

    return row?.read<String>('code');
  }

  Future<void> registerFailedLoginAttempt({
    required int userId,
    required int maxFailedAttempts,
    required int lockoutMinutes,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    await transaction(() async {
      final user =
          await (select(users)..where((u) => u.id.equals(userId))).getSingle();
      final nextAttempts = user.failedAttempts + 1;
      final shouldBlock = nextAttempts >= maxFailedAttempts;
      final nextStatus = shouldBlock ? 'blocked' : user.status;
      final blockedAt = shouldBlock ? _utcNow() : null;

      await (update(users)..where((u) => u.id.equals(userId))).write(
        UsersCompanion(
          failedAttempts: Value(nextAttempts),
          status: Value(nextStatus),
          blockedAt: Value(blockedAt),
          updatedAt: Value(_utcNow()),
          isSynced: const Value(false),
        ),
      );

      await _insertAudit(
        tableName: 'users',
        rowUuid: user.uuid,
        action: 'update',
        changedByUserId: userId,
        eventAction: shouldBlock ? 'login_blocked' : 'login_failed',
        module: 'Acceso',
        description: shouldBlock
            ? 'Usuario bloqueado por exceder intentos fallidos.'
            : 'Intento de login fallido.',
        result: 'failure',
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
        newValues:
            '{"failed_attempts":$nextAttempts,"status":"$nextStatus","lockout_minutes":$lockoutMinutes}',
      );
    });
  }

  Future<void> registerSuccessfulLogin({
    required int userId,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    await transaction(() async {
      final user =
          await (select(users)..where((u) => u.id.equals(userId))).getSingle();

      await (update(users)..where((u) => u.id.equals(userId))).write(
        UsersCompanion(
          status: const Value('active'),
          failedAttempts: const Value(0),
          blockedAt: const Value(null),
          lastAccessAt: Value(_utcNow()),
          updatedAt: Value(_utcNow()),
          isSynced: const Value(false),
        ),
      );

      await _insertAudit(
        tableName: 'users',
        rowUuid: user.uuid,
        action: 'update',
        changedByUserId: userId,
        eventAction: 'login_success',
        module: 'Acceso',
        description: 'Inicio de sesion exitoso.',
        result: 'success',
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );
    });
  }

  Future<List<SecurityUserView>> listSecurityUsers() async {
    final rows = await customSelect(
      '''
      SELECT
        u.id,
        u.username,
        u.email,
        u.full_name,
        u.status,
        u.created_at,
        u.last_access_at,
        u.failed_attempts,
        u.blocked_at,
        COALESCE(r.name, 'Sin rol') AS role_name
      FROM users u
      LEFT JOIN user_roles ur ON ur.user_id = u.id
      LEFT JOIN roles r ON r.id = ur.role_id
      WHERE u.deleted_at IS NULL
      ORDER BY u.created_at DESC
      ''',
      readsFrom: {users, userRoles, roles},
    ).get();

    return rows
        .map(
          (row) => SecurityUserView(
            id: row.read<int>('id'),
            username: row.read<String>('username'),
            email: row.data['email'] as String?,
            fullName: row.read<String>('full_name'),
            role: row.read<String>('role_name'),
            status: row.read<String>('status'),
            createdAt: row.read<DateTime>('created_at'),
            lastAccessAt: row.data['last_access_at'] as DateTime?,
            failedAttempts: row.read<int>('failed_attempts'),
            blockedAt: row.data['blocked_at'] as DateTime?,
          ),
        )
        .toList();
  }

  Future<void> validatePendingUser({
    required int targetUserId,
    required int adminUserId,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    await transaction(() async {
      final user = await (select(users)
            ..where((u) => u.id.equals(targetUserId)))
          .getSingle();
      await (update(users)..where((u) => u.id.equals(targetUserId))).write(
        UsersCompanion(
          status: const Value('active'),
          isActive: const Value(true),
          failedAttempts: const Value(0),
          blockedAt: const Value(null),
          updatedAt: Value(_utcNow()),
          isSynced: const Value(false),
        ),
      );

      await _insertAudit(
        tableName: 'users',
        rowUuid: user.uuid,
        action: 'update',
        changedByUserId: adminUserId,
        eventAction: 'user_validated',
        module: 'Seguridad',
        description: 'Usuario validado por administrador.',
        result: 'success',
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
        oldValues: '{"status":"${user.status}"}',
        newValues: '{"status":"active"}',
      );
    });
  }

  Future<void> updateUserStatus({
    required int targetUserId,
    required String status,
    required int changedByUserId,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    await transaction(() async {
      final user = await (select(users)
            ..where((u) => u.id.equals(targetUserId)))
          .getSingle();
      final normalizedStatus = status.trim().toLowerCase();
      final blockedAt = normalizedStatus == 'blocked' ? _utcNow() : null;

      await (update(users)..where((u) => u.id.equals(targetUserId))).write(
        UsersCompanion(
          status: Value(normalizedStatus),
          isActive: Value(normalizedStatus != 'blocked'),
          blockedAt: Value(blockedAt),
          failedAttempts:
              Value(normalizedStatus == 'blocked' ? user.failedAttempts : 0),
          updatedAt: Value(_utcNow()),
          isSynced: const Value(false),
        ),
      );

      await _insertAudit(
        tableName: 'users',
        rowUuid: user.uuid,
        action: 'update',
        changedByUserId: changedByUserId,
        eventAction:
            normalizedStatus == 'blocked' ? 'user_blocked' : 'user_unblocked',
        module: 'Seguridad',
        description: normalizedStatus == 'blocked'
            ? 'Usuario bloqueado manualmente.'
            : 'Usuario desbloqueado manualmente.',
        result: 'success',
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
        oldValues: '{"status":"${user.status}"}',
        newValues: '{"status":"$normalizedStatus"}',
      );
    });
  }

  Future<void> resetUserPassword({
    required int targetUserId,
    required String passwordHash,
    required String passwordAlgo,
    required int changedByUserId,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    await transaction(() async {
      final user = await (select(users)
            ..where((u) => u.id.equals(targetUserId)))
          .getSingle();

      await (update(users)..where((u) => u.id.equals(targetUserId))).write(
        UsersCompanion(
          passwordHash: Value(passwordHash),
          passwordAlgo: Value(passwordAlgo),
          failedAttempts: const Value(0),
          blockedAt: const Value(null),
          forcePasswordChange: const Value(true),
          passwordChangedAt: Value(_utcNow()),
          status: const Value('active'),
          updatedAt: Value(_utcNow()),
          isSynced: const Value(false),
        ),
      );

      await _insertAudit(
        tableName: 'users',
        rowUuid: user.uuid,
        action: 'update',
        changedByUserId: changedByUserId,
        eventAction: 'password_reset',
        module: 'Seguridad',
        description: 'Contrasena restablecida por administrador.',
        result: 'success',
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );
    });
  }

  Future<void> changeUserRole({
    required int targetUserId,
    required int newRoleId,
    required int changedByUserId,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    await transaction(() async {
      final user = await (select(users)
            ..where((u) => u.id.equals(targetUserId)))
          .getSingle();
      await (delete(userRoles)..where((ur) => ur.userId.equals(targetUserId)))
          .go();
      await into(userRoles).insert(
        UserRolesCompanion.insert(userId: targetUserId, roleId: newRoleId),
      );

      final role = await (select(roles)..where((r) => r.id.equals(newRoleId)))
          .getSingle();

      await _insertAudit(
        tableName: 'user_roles',
        rowUuid: user.uuid,
        action: 'update',
        changedByUserId: changedByUserId,
        eventAction: 'role_changed',
        module: 'Seguridad',
        description: 'Rol del usuario actualizado a ${role.code}.',
        result: 'success',
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );
    });
  }

  Future<List<RolePermissionView>> listRolesWithPermissions() async {
    final roleRows = await select(roles).get();
    final rows = await customSelect(
      '''
      SELECT r.id AS role_id, r.code AS role_code, r.name AS role_name, p.code AS permission_code
      FROM roles r
      LEFT JOIN role_permissions rp ON rp.role_id = r.id
      LEFT JOIN permissions p ON p.id = rp.permission_id
      ORDER BY r.name, p.code
      ''',
      readsFrom: {roles, rolePermissions, permissions},
    ).get();

    final permissionsByRole = <int, Set<String>>{
      for (final role in roleRows) role.id: <String>{},
    };

    for (final row in rows) {
      final roleId = row.read<int>('role_id');
      final permissionCode = row.data['permission_code'] as String?;
      if (permissionCode == null || permissionCode.isEmpty) continue;
      permissionsByRole
          .putIfAbsent(roleId, () => <String>{})
          .add(permissionCode);
    }

    return roleRows
        .map(
          (role) => RolePermissionView(
            roleId: role.id,
            roleCode: role.code,
            roleName: role.name,
            permissions: permissionsByRole[role.id] ?? <String>{},
          ),
        )
        .toList();
  }

  Future<List<Permission>> listAllPermissions() {
    return (select(permissions)..orderBy([(p) => OrderingTerm.asc(p.code)]))
        .get();
  }

  Future<void> replaceRolePermissions({
    required int roleId,
    required Set<String> permissionCodes,
    required int changedByUserId,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    await transaction(() async {
      final role =
          await (select(roles)..where((r) => r.id.equals(roleId))).getSingle();
      await (delete(rolePermissions)..where((rp) => rp.roleId.equals(roleId)))
          .go();

      if (permissionCodes.isNotEmpty) {
        final permissionRows = await (select(permissions)
              ..where((p) => p.code.isIn(permissionCodes.toList())))
            .get();

        for (final permission in permissionRows) {
          await into(rolePermissions).insert(
            RolePermissionsCompanion.insert(
              roleId: roleId,
              permissionId: permission.id,
            ),
          );
        }
      }

      await _insertAudit(
        tableName: 'role_permissions',
        rowUuid: role.uuid,
        action: 'update',
        changedByUserId: changedByUserId,
        eventAction: 'permissions_changed',
        module: 'Seguridad',
        description: 'Permisos actualizados para rol ${role.code}.',
        result: 'success',
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
        newValues:
            '{"role":"${role.code}","permissions":${permissionCodes.toList()}}',
      );
    });
  }

  Future<List<SecuritySettingView>> listSecuritySettings() async {
    final rows = await (select(securitySettings)
          ..orderBy([(s) => OrderingTerm.asc(s.key)]))
        .get();

    return rows
        .map(
          (row) => SecuritySettingView(
            key: row.key,
            value: row.value,
            description: row.description,
            updatedAt: row.updatedAt,
            updatedByUserId: row.updatedByUserId,
          ),
        )
        .toList();
  }

  Future<String?> getSecuritySettingValue(String key) async {
    final row = await (select(securitySettings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> upsertSecuritySetting({
    required String key,
    required String value,
    String? description,
    int? updatedByUserId,
  }) async {
    await into(securitySettings).insertOnConflictUpdate(
      SecuritySettingsCompanion.insert(
        key: key,
        value: value,
        description: Value(description),
        updatedByUserId: Value(updatedByUserId),
        updatedAt: Value(_utcNow()),
      ),
    );
  }

  Future<List<SecurityAuditLogView>> querySecurityAuditLogs(
      SecurityAuditFilter filter) async {
    final whereParts = <String>['1 = 1'];
    final variables = <Variable<Object>>[];

    if (filter.from != null) {
      whereParts.add('a.created_at >= ?');
      variables.add(Variable<DateTime>(filter.from!));
    }
    if (filter.to != null) {
      whereParts.add('a.created_at <= ?');
      variables.add(Variable<DateTime>(filter.to!));
    }
    if (filter.userId != null) {
      whereParts.add('a.changed_by_user_id = ?');
      variables.add(Variable<int>(filter.userId!));
    }
    if (filter.eventAction != null && filter.eventAction!.isNotEmpty) {
      whereParts.add('a.event_action = ?');
      variables.add(Variable<String>(filter.eventAction!));
    }
    if (filter.module != null && filter.module!.isNotEmpty) {
      whereParts.add('a.module = ?');
      variables.add(Variable<String>(filter.module!));
    }
    if (filter.search != null && filter.search!.trim().isNotEmpty) {
      whereParts.add(
          '(LOWER(a.event_action) LIKE ? OR LOWER(a.module) LIKE ? OR LOWER(a.description) LIKE ? OR LOWER(COALESCE(u.full_name, u.username, \'sistema\')) LIKE ?)');
      final wildcard = '%${filter.search!.trim().toLowerCase()}%';
      variables.add(Variable<String>(wildcard));
      variables.add(Variable<String>(wildcard));
      variables.add(Variable<String>(wildcard));
      variables.add(Variable<String>(wildcard));
    }

    final rows = await customSelect(
      '''
      SELECT
        a.id,
        a.created_at,
        COALESCE(u.full_name, u.username, 'Sistema') AS actor,
        a.event_action,
        COALESCE(a.module, 'General') AS module,
        COALESCE(a.description, '') AS description,
        a.result,
        COALESCE(a.ip_address, '-') AS ip_address,
        COALESCE(a.device_info, '-') AS device_info
      FROM audit_logs a
      LEFT JOIN users u ON u.id = a.changed_by_user_id
      WHERE ${whereParts.join(' AND ')}
      ORDER BY a.created_at DESC
      LIMIT ? OFFSET ?
      ''',
      variables: [
        ...variables,
        Variable<int>(filter.limit),
        Variable<int>(filter.offset),
      ],
      readsFrom: {auditLogs, users},
    ).get();

    return rows
        .map(
          (row) => SecurityAuditLogView(
            id: row.read<int>('id'),
            createdAt: row.read<DateTime>('created_at'),
            user: row.read<String>('actor'),
            eventAction: row.read<String>('event_action'),
            module: row.read<String>('module'),
            description: row.read<String>('description'),
            result: row.read<String>('result'),
            ipAddress: row.read<String>('ip_address'),
            deviceInfo: row.read<String>('device_info'),
          ),
        )
        .toList();
  }

  Future<int> countSecurityAuditLogs(SecurityAuditFilter filter) async {
    final whereParts = <String>['1 = 1'];
    final variables = <Variable<Object>>[];

    if (filter.from != null) {
      whereParts.add('a.created_at >= ?');
      variables.add(Variable<DateTime>(filter.from!));
    }
    if (filter.to != null) {
      whereParts.add('a.created_at <= ?');
      variables.add(Variable<DateTime>(filter.to!));
    }
    if (filter.userId != null) {
      whereParts.add('a.changed_by_user_id = ?');
      variables.add(Variable<int>(filter.userId!));
    }
    if (filter.eventAction != null && filter.eventAction!.isNotEmpty) {
      whereParts.add('a.event_action = ?');
      variables.add(Variable<String>(filter.eventAction!));
    }
    if (filter.module != null && filter.module!.isNotEmpty) {
      whereParts.add('a.module = ?');
      variables.add(Variable<String>(filter.module!));
    }
    if (filter.search != null && filter.search!.trim().isNotEmpty) {
      whereParts.add(
          '(LOWER(a.event_action) LIKE ? OR LOWER(a.module) LIKE ? OR LOWER(a.description) LIKE ? OR LOWER(COALESCE(u.full_name, u.username, \'sistema\')) LIKE ?)');
      final wildcard = '%${filter.search!.trim().toLowerCase()}%';
      variables.add(Variable<String>(wildcard));
      variables.add(Variable<String>(wildcard));
      variables.add(Variable<String>(wildcard));
      variables.add(Variable<String>(wildcard));
    }

    final row = await customSelect(
      '''
      SELECT COUNT(*) AS total
      FROM audit_logs a
      LEFT JOIN users u ON u.id = a.changed_by_user_id
      WHERE ${whereParts.join(' AND ')}
      ''',
      variables: variables,
      readsFrom: {auditLogs, users},
    ).getSingle();

    return row.read<int>('total');
  }

  Future<void> registerUnauthorizedAttempt({
    required int userId,
    required String attemptedAction,
    required String module,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    final user = await (select(users)..where((u) => u.id.equals(userId)))
        .getSingleOrNull();
    await _insertAudit(
      tableName: 'authorization',
      rowUuid: user?.uuid ?? '-',
      action: 'insert',
      changedByUserId: userId,
      eventAction: 'permission_denied',
      module: module,
      description: 'Intento bloqueado para accion: $attemptedAction',
      result: 'failure',
      ipAddress: ipAddress,
      deviceInfo: deviceInfo,
    );
  }

  Future<void> _insertAudit({
    required String tableName,
    required String rowUuid,
    required String action,
    int? changedByUserId,
    String? eventAction,
    String? module,
    String? description,
    String? result,
    String? ipAddress,
    String? deviceInfo,
    String? oldValues,
    String? newValues,
    String? payloadJson,
  }) async {
    await into(auditLogs).insert(
      AuditLogsCompanion.insert(
        entityTable: tableName,
        rowUuid: rowUuid,
        action: action,
        changedByUserId: Value(changedByUserId),
        eventAction: Value(eventAction ?? action),
        module: Value(module),
        description: Value(description),
        result: Value(result ?? 'success'),
        ipAddress: Value(ipAddress),
        deviceInfo: Value(deviceInfo),
        oldValues: Value(oldValues),
        newValues: Value(newValues),
        payloadJson: Value(payloadJson),
      ),
    );
  }

  Future<List<DailySalesReportRow>> getDailySalesReport({
    required int branchId,
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await customSelect(
      '''
      SELECT date(s.sold_at) AS day,
             COUNT(*) AS tickets,
              COALESCE(SUM(s.total), 0) AS total_cents
      FROM sales s
      WHERE s.deleted_at IS NULL
        AND s.branch_id = ?
        AND s.status = 'completed'
        AND s.sold_at >= ?
        AND s.sold_at < ?
      GROUP BY date(s.sold_at)
      ORDER BY day DESC
      ''',
      variables: [
        Variable<int>(branchId),
        Variable<DateTime>(from),
        Variable<DateTime>(to),
      ],
      readsFrom: {sales},
    ).get();

    return rows
        .map(
          (row) => DailySalesReportRow(
            day: DateTime.parse(row.data['day'] as String),
            tickets: row.read<int>('tickets'),
            total: row.read<int>('total_cents') / 100.0,
          ),
        )
        .toList();
  }
}
