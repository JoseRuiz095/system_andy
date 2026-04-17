PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

-- =====================================================
-- BASE
-- =====================================================
CREATE TABLE IF NOT EXISTS branches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  address TEXT,
  allow_negative_inventory INTEGER NOT NULL DEFAULT 0 CHECK(allow_negative_inventory IN (0, 1)),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1))
);

CREATE TABLE IF NOT EXISTS units (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  symbol TEXT NOT NULL,
  precision_scale INTEGER NOT NULL DEFAULT 2,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1))
);

-- =====================================================
-- ADMINISTRACION / SEGURIDAD
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  username TEXT NOT NULL UNIQUE,
  email TEXT UNIQUE,
  full_name TEXT NOT NULL,
  password_hash TEXT,
  password_algo TEXT NOT NULL DEFAULT 'bcrypt',
  pin_hash TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('active', 'pending', 'blocked')),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
  last_access_at TEXT,
  failed_attempts INTEGER NOT NULL DEFAULT 0,
  blocked_at TEXT,
  password_changed_at TEXT,
  force_password_change INTEGER NOT NULL DEFAULT 0 CHECK(force_password_change IN (0, 1)),
  two_factor_enabled INTEGER NOT NULL DEFAULT 0 CHECK(two_factor_enabled IN (0, 1)),
  two_factor_secret TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1))
);

CREATE TABLE IF NOT EXISTS roles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1))
);

CREATE TABLE IF NOT EXISTS permissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1))
);

CREATE TABLE IF NOT EXISTS user_roles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  user_id INTEGER NOT NULL,
  role_id INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  UNIQUE(user_id, role_id),
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(role_id) REFERENCES roles(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS role_permissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  role_id INTEGER NOT NULL,
  permission_id INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  UNIQUE(role_id, permission_id),
  FOREIGN KEY(role_id) REFERENCES roles(id) ON DELETE CASCADE,
  FOREIGN KEY(permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  user_id INTEGER NOT NULL,
  cash_register_id INTEGER,
  login_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  logout_at TEXT,
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE RESTRICT,
  FOREIGN KEY(cash_register_id) REFERENCES cash_registers(id) ON DELETE SET NULL
);

-- =====================================================
-- INVENTARIO / CATALOGO
-- =====================================================
CREATE TABLE IF NOT EXISTS suppliers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  contact_name TEXT,
  phone TEXT,
  email TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1))
);

CREATE TABLE IF NOT EXISTS products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  sku TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  category TEXT,
  unit_id INTEGER NOT NULL,
  supplier_id INTEGER,
    unit_price INTEGER NOT NULL CHECK(unit_price >= 0),
    cost_price INTEGER NOT NULL DEFAULT 0 CHECK(cost_price >= 0),
  default_tax_rate NUMERIC NOT NULL DEFAULT 0.16 CHECK(default_tax_rate >= 0),
  track_stock INTEGER NOT NULL DEFAULT 1 CHECK(track_stock IN (0, 1)),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  FOREIGN KEY(unit_id) REFERENCES units(id) ON DELETE RESTRICT,
  FOREIGN KEY(supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS product_variants (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  product_id INTEGER NOT NULL,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
    price_delta INTEGER NOT NULL DEFAULT 0,
    cost_price INTEGER NOT NULL DEFAULT 0 CHECK(cost_price >= 0),
  is_default INTEGER NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1)),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  UNIQUE(product_id, code),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS modifiers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  price INTEGER NOT NULL DEFAULT 0 CHECK(price >= 0),
  tax_rate NUMERIC NOT NULL DEFAULT 0.16 CHECK(tax_rate >= 0),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1))
);

CREATE TABLE IF NOT EXISTS product_modifiers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  product_id INTEGER NOT NULL,
  modifier_id INTEGER NOT NULL,
  is_required INTEGER NOT NULL DEFAULT 0 CHECK(is_required IN (0, 1)),
  min_selection INTEGER NOT NULL DEFAULT 0,
  max_selection INTEGER NOT NULL DEFAULT 10,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  UNIQUE(product_id, modifier_id),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY(modifier_id) REFERENCES modifiers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS inventory (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  product_id INTEGER NOT NULL,
  branch_id INTEGER NOT NULL,
  quantity_on_hand NUMERIC NOT NULL DEFAULT 0,
  reorder_level NUMERIC NOT NULL DEFAULT 0 CHECK(reorder_level >= 0),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  UNIQUE(product_id, branch_id),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
  FOREIGN KEY(branch_id) REFERENCES branches(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS inventory_batches (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  product_id INTEGER NOT NULL,
  branch_id INTEGER NOT NULL,
  batch_code TEXT NOT NULL,
  quantity NUMERIC NOT NULL CHECK(quantity >= 0),
  cost_price INTEGER NOT NULL DEFAULT 0 CHECK(cost_price >= 0),
  received_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expiration_date TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  UNIQUE(product_id, branch_id, batch_code),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT,
  FOREIGN KEY(branch_id) REFERENCES branches(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS inventory_movements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  product_id INTEGER NOT NULL,
  branch_id INTEGER NOT NULL,
  unit_id INTEGER NOT NULL,
  batch_id INTEGER,
  user_id INTEGER,
  movement_type TEXT NOT NULL CHECK(movement_type IN ('in', 'out', 'adjustment', 'waste', 'sale_return', 'purchase')),
  quantity NUMERIC NOT NULL CHECK(quantity > 0),
  reason TEXT,
  reference_type TEXT,
  reference_uuid TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT,
  FOREIGN KEY(branch_id) REFERENCES branches(id) ON DELETE RESTRICT,
  FOREIGN KEY(unit_id) REFERENCES units(id) ON DELETE RESTRICT,
  FOREIGN KEY(batch_id) REFERENCES inventory_batches(id) ON DELETE SET NULL,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- =====================================================
-- VENTAS / CAJA / FOLIOS
-- =====================================================
CREATE TABLE IF NOT EXISTS payment_methods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1))
);

CREATE TABLE IF NOT EXISTS cash_registers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  branch_id INTEGER NOT NULL,
  opened_by_user_id INTEGER NOT NULL,
  closed_by_user_id INTEGER,
  opened_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  closed_at TEXT,
    opening_amount INTEGER NOT NULL CHECK(opening_amount >= 0),
    expected_amount INTEGER,
    counted_amount INTEGER,
    difference_amount INTEGER,
    closing_amount INTEGER CHECK(closing_amount IS NULL OR closing_amount >= 0),
  status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open', 'closed')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  FOREIGN KEY(branch_id) REFERENCES branches(id) ON DELETE RESTRICT,
  FOREIGN KEY(opened_by_user_id) REFERENCES users(id) ON DELETE RESTRICT,
  FOREIGN KEY(closed_by_user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_cash_registers_open_branch
ON cash_registers(branch_id)
WHERE status = 'open';

CREATE TABLE IF NOT EXISTS folio_sequences (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  branch_id INTEGER NOT NULL,
  doc_type TEXT NOT NULL,
  work_date TEXT NOT NULL,
  current_number INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(branch_id, doc_type, work_date),
  FOREIGN KEY(branch_id) REFERENCES branches(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  sale_number TEXT NOT NULL UNIQUE,
  branch_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  user_session_id INTEGER,
  cash_register_id INTEGER,
  device_id TEXT NOT NULL DEFAULT 'unknown-device',
  idempotency_key TEXT UNIQUE,
  status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft', 'pending', 'in_progress', 'completed', 'cancelled', 'refunded')),
    subtotal INTEGER NOT NULL CHECK(subtotal >= 0),
    discount INTEGER NOT NULL DEFAULT 0 CHECK(discount >= 0),
    tax INTEGER NOT NULL DEFAULT 0 CHECK(tax >= 0),
    total INTEGER NOT NULL CHECK(total >= 0),
  sold_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  FOREIGN KEY(branch_id) REFERENCES branches(id) ON DELETE RESTRICT,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE RESTRICT,
  FOREIGN KEY(user_session_id) REFERENCES user_sessions(id) ON DELETE SET NULL,
  FOREIGN KEY(cash_register_id) REFERENCES cash_registers(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sale_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  sale_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  product_variant_id INTEGER,
  quantity NUMERIC NOT NULL CHECK(quantity > 0),
    unit_price INTEGER NOT NULL CHECK(unit_price >= 0),
    cost_price INTEGER NOT NULL DEFAULT 0 CHECK(cost_price >= 0),
  discount_percent NUMERIC NOT NULL DEFAULT 0 CHECK(discount_percent >= 0 AND discount_percent <= 100),
  discount_amount INTEGER NOT NULL DEFAULT 0 CHECK(discount_amount >= 0),
  tax_rate NUMERIC NOT NULL DEFAULT 0.16 CHECK(tax_rate >= 0),
    tax_amount INTEGER NOT NULL DEFAULT 0 CHECK(tax_amount >= 0),
    line_subtotal INTEGER NOT NULL DEFAULT 0 CHECK(line_subtotal >= 0),
    line_total INTEGER NOT NULL DEFAULT 0 CHECK(line_total >= 0),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  FOREIGN KEY(sale_id) REFERENCES sales(id) ON DELETE CASCADE,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT,
  FOREIGN KEY(product_variant_id) REFERENCES product_variants(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sale_item_modifiers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  sale_item_id INTEGER NOT NULL,
  modifier_id INTEGER NOT NULL,
  quantity NUMERIC NOT NULL DEFAULT 1 CHECK(quantity > 0),
  unit_price INTEGER NOT NULL DEFAULT 0 CHECK(unit_price >= 0),
  total INTEGER NOT NULL DEFAULT 0 CHECK(total >= 0),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  FOREIGN KEY(sale_item_id) REFERENCES sale_items(id) ON DELETE CASCADE,
  FOREIGN KEY(modifier_id) REFERENCES modifiers(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS payments (
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
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  FOREIGN KEY(sale_id) REFERENCES sales(id) ON DELETE CASCADE,
  FOREIGN KEY(payment_method_id) REFERENCES payment_methods(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS refunds (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  sale_id INTEGER NOT NULL,
  branch_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  cash_register_id INTEGER,
  idempotency_key TEXT UNIQUE,
  status TEXT NOT NULL DEFAULT 'completed' CHECK(status IN ('pending', 'completed', 'void')),
  subtotal INTEGER NOT NULL DEFAULT 0 CHECK(subtotal >= 0),
  tax INTEGER NOT NULL DEFAULT 0 CHECK(tax >= 0),
  total INTEGER NOT NULL DEFAULT 0 CHECK(total >= 0),
  reason TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  FOREIGN KEY(sale_id) REFERENCES sales(id) ON DELETE CASCADE,
  FOREIGN KEY(branch_id) REFERENCES branches(id) ON DELETE RESTRICT,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE RESTRICT,
  FOREIGN KEY(cash_register_id) REFERENCES cash_registers(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS refund_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  refund_id INTEGER NOT NULL,
  sale_item_id INTEGER NOT NULL,
  quantity NUMERIC NOT NULL CHECK(quantity > 0),
  unit_price INTEGER NOT NULL DEFAULT 0 CHECK(unit_price >= 0),
  tax_rate NUMERIC NOT NULL DEFAULT 0 CHECK(tax_rate >= 0),
  subtotal INTEGER NOT NULL DEFAULT 0 CHECK(subtotal >= 0),
  tax_amount INTEGER NOT NULL DEFAULT 0 CHECK(tax_amount >= 0),
  total INTEGER NOT NULL DEFAULT 0 CHECK(total >= 0),
  reason TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  FOREIGN KEY(refund_id) REFERENCES refunds(id) ON DELETE CASCADE,
  FOREIGN KEY(sale_item_id) REFERENCES sale_items(id) ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS receipts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  branch_id INTEGER NOT NULL,
  sale_id INTEGER NOT NULL UNIQUE,
  receipt_number TEXT NOT NULL UNIQUE,
  payload_json TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  FOREIGN KEY(branch_id) REFERENCES branches(id) ON DELETE RESTRICT,
  FOREIGN KEY(sale_id) REFERENCES sales(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cash_movements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  branch_id INTEGER NOT NULL,
  cash_register_id INTEGER NOT NULL,
  sale_id INTEGER,
  user_id INTEGER,
  device_id TEXT NOT NULL DEFAULT 'unknown-device',
  movement_type TEXT NOT NULL CHECK(movement_type IN ('opening', 'closing', 'income', 'expense', 'withdrawal', 'deposit', 'correction', 'refund')),
  amount INTEGER NOT NULL CHECK(amount >= 0),
  note TEXT,
  moved_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at TEXT,
  is_synced INTEGER NOT NULL DEFAULT 0 CHECK(is_synced IN (0, 1)),
  FOREIGN KEY(branch_id) REFERENCES branches(id) ON DELETE RESTRICT,
  FOREIGN KEY(cash_register_id) REFERENCES cash_registers(id) ON DELETE CASCADE,
  FOREIGN KEY(sale_id) REFERENCES sales(id) ON DELETE SET NULL,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- =====================================================
-- AUDITORIA / OUTBOX
-- =====================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  entity_table TEXT NOT NULL,
  row_uuid TEXT NOT NULL,
  action TEXT NOT NULL CHECK(action IN ('insert', 'update', 'delete')),
  event_action TEXT NOT NULL DEFAULT 'unspecified',
  module TEXT,
  description TEXT,
  changed_by_user_id INTEGER,
  result TEXT NOT NULL DEFAULT 'success',
  ip_address TEXT,
  device_info TEXT,
  old_values TEXT,
  new_values TEXT,
  payload_json TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(changed_by_user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS security_settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT NOT NULL UNIQUE,
  value TEXT NOT NULL,
  description TEXT,
  updated_by_user_id INTEGER,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(updated_by_user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sync_status (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_id TEXT NOT NULL UNIQUE,
  api_version TEXT NOT NULL DEFAULT 'v1',
  server_time_offset_seconds INTEGER,
  last_sync_at TEXT,
  pending_events_count INTEGER NOT NULL DEFAULT 0,
  failed_events_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS feature_flags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT NOT NULL UNIQUE,
  value TEXT NOT NULL,
  scope TEXT,
  source TEXT NOT NULL DEFAULT 'remote',
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sync_outbox (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_id TEXT NOT NULL DEFAULT 'unknown-device',
  entity_type TEXT NOT NULL,
  entity_uuid TEXT NOT NULL,
  operation TEXT NOT NULL CHECK(operation IN ('insert', 'update', 'delete')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'processing', 'sent', 'failed', 'dead_letter')),
  api_version TEXT NOT NULL DEFAULT 'v1',
  signature TEXT,
  payload_json TEXT,
  retry_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  next_retry_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- INDICES
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_sales_branch_sold_at ON sales(branch_id, sold_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_branch_date ON sales(branch_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_user_id_sold_at ON sales(user_id, sold_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(status, sold_at DESC);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product_id ON sale_items(product_id);
CREATE INDEX IF NOT EXISTS idx_payments_sale_id ON payments(sale_id);
CREATE INDEX IF NOT EXISTS idx_inventory_branch_product ON inventory(branch_id, product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_product_branch ON inventory(product_id, branch_id);
CREATE INDEX IF NOT EXISTS idx_inventory_batches_expiry ON inventory_batches(branch_id, product_id, expiration_date);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_branch_product_created ON inventory_movements(branch_id, product_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cash_movements_branch_moved ON cash_movements(branch_id, moved_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_sessions_active ON user_sessions(user_id, is_active, login_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity_row ON audit_logs(entity_table, row_uuid, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status, is_active, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_users_failed_attempts ON users(failed_attempts, blocked_at);
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_security ON audit_logs(module, event_action, result, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_security_settings_key ON security_settings(key);
CREATE INDEX IF NOT EXISTS idx_sync_status_device ON sync_status(device_id);
CREATE INDEX IF NOT EXISTS idx_feature_flags_scope ON feature_flags(scope, key);
CREATE INDEX IF NOT EXISTS idx_sync_outbox_entity ON sync_outbox(entity_type, entity_uuid, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sync_outbox_status ON sync_outbox(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sync_outbox_device ON sync_outbox(device_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_refunds_sale ON refunds(sale_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_refund_items_sale_item ON refund_items(sale_item_id, created_at DESC);

-- =====================================================
-- SEMILLAS
-- =====================================================
INSERT OR IGNORE INTO branches (uuid, code, name)
VALUES ('branch-main', 'MAIN', 'Sucursal Principal');

INSERT OR IGNORE INTO units (uuid, code, name, symbol, precision_scale)
VALUES
  ('unit-pc', 'pc', 'Pieza', 'pz', 0),
  ('unit-gr', 'gr', 'Gramo', 'g', 2),
  ('unit-ml', 'ml', 'Mililitro', 'ml', 2);

INSERT OR IGNORE INTO payment_methods (uuid, code, name)
VALUES
  ('pm-cash', 'cash', 'Efectivo'),
  ('pm-card', 'card', 'Tarjeta'),
  ('pm-transfer', 'transfer', 'Transferencia');

INSERT OR IGNORE INTO roles (uuid, code, name, description)
VALUES
  ('role-admin', 'admin', 'Administrador', 'Acceso total al sistema POS'),
  ('role-cashier', 'cashier', 'Cajero', 'Operacion de caja y cobro'),
  ('role-barista', 'barista', 'Barista', 'Operacion de venta basica y producto');

INSERT OR IGNORE INTO permissions (uuid, code, name)
VALUES
  ('perm-registrar-venta', 'registrar_venta', 'Registrar venta'),
  ('perm-procesar-cobro', 'procesar_cobro', 'Procesar cobro'),
  ('perm-abrir-caja', 'abrir_caja', 'Abrir caja'),
  ('perm-cerrar-caja', 'cerrar_caja', 'Cerrar caja'),
  ('perm-ajustar-inventario', 'ajustar_inventario', 'Ajustar inventario'),
  ('perm-gestionar-productos', 'gestionar_productos', 'Gestionar productos'),
  ('perm-ver-reportes', 'ver_reportes', 'Ver reportes'),
  ('perm-cancelar-venta', 'cancelar_venta', 'Cancelar venta'),
  ('perm-aplicar-descuento', 'aplicar_descuento', 'Aplicar descuento'),
  ('perm-configurar-sistema', 'configurar_sistema', 'Configurar sistema');

INSERT OR IGNORE INTO security_settings (key, value, description)
VALUES
  ('session_expiration_minutes', '480', 'Tiempo maximo de sesion activa'),
  ('force_password_rotation', 'true', 'Solicitar cambio periodico de contrasena'),
  ('strong_password_required', 'true', 'Aplicar politica de contrasena fuerte'),
  ('two_factor_enabled', 'false', 'Activar segundo factor en autenticacion'),
  ('mask_sensitive_data', 'true', 'Ocultar datos sensibles en pantalla'),
  ('max_failed_attempts', '5', 'Intentos fallidos antes de bloqueo'),
  ('lockout_minutes', '15', 'Minutos de bloqueo por seguridad');
