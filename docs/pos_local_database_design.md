# Diseno de Base de Datos Local POS (SQLite Offline-First)

## 1) Diagrama logico (ERD en texto)

### Ventas
- `sales` (cabecera de venta) 1:N `sale_items`
- `sales` 1:N `payments`
- `sales` 1:1 `receipts` (comprobante)
- `sales` N:1 `users` (empleado que vende)
- `sales` N:1 `cash_registers` (caja activa)

### Inventario
- `products` 1:1 `inventory` (stock actual)
- `products` 1:N `inventory_movements` (kardex)
- `suppliers` 1:N `products`

### Caja
- `cash_registers` 1:N `cash_movements`
- `cash_movements` N:1 `sales` (opcional, cuando el movimiento viene de venta)
- `cash_registers` N:1 `users` (apertura/cierre)

### Administracion
- `users` N:M `roles` via `user_roles`
- `roles` N:M `permissions` via `role_permissions`
- `audit_logs` registra cambios por entidad (`table_name`, `row_uuid`, `action`)

### Sincronizacion futura
- Todas las tablas de negocio usan `id` local + `uuid` global.
- `is_synced` marca pendiente/sincronizado.
- `sync_outbox` conserva operaciones para replicacion futura.

## 2) SQL completo

El SQL completo y ejecutable se encuentra en:

- `lib/core/database/sql/pos_schema.sql`

Incluye:
- DDL de tablas de ventas, inventario, caja y administracion.
- FKs, CHECK constraints, soft delete (`deleted_at`) y timestamps.
- Indices de rendimiento para POS.
- Seed inicial de metodos de pago.

## 3) Relaciones clave

- Integridad fuerte por FK con reglas `CASCADE`, `RESTRICT` y `SET NULL` segun dominio.
- Evita duplicados con `UNIQUE` en:
  - `sku`, `sale_number`, `receipt_number`, `username`, `code`
  - relaciones N:M (`user_roles`, `role_permissions`)
- Stock consistente:
  - cada producto tiene una fila en `inventory`
  - cada ajuste/venta/entrada genera fila en `inventory_movements`

## 4) Indices recomendados

Principales indices aplicados:
- `idx_sales_sold_at`
- `idx_sales_user_id_sold_at`
- `idx_sale_items_sale_id`
- `idx_sale_items_product_id`
- `idx_payments_sale_id`
- `idx_inventory_product_id`
- `idx_inventory_low_stock`
- `idx_inventory_movements_product_created`
- `idx_cash_movements_register_moved`
- `idx_audit_logs_table_row`
- `idx_sync_outbox_entity`

## 5) Queries clave de reportes

### Ventas por dia
```sql
SELECT date(s.sold_at) AS day,
       COUNT(*) AS tickets,
       ROUND(SUM(s.total), 2) AS total
FROM sales s
WHERE s.deleted_at IS NULL
  AND s.status = 'completed'
GROUP BY date(s.sold_at)
ORDER BY day DESC;
```

### Ventas por producto
```sql
SELECT p.name,
       SUM(si.quantity) AS qty,
       ROUND(SUM(si.line_total), 2) AS amount
FROM sale_items si
JOIN products p ON p.id = si.product_id
JOIN sales s ON s.id = si.sale_id
WHERE s.deleted_at IS NULL
  AND s.status = 'completed'
GROUP BY p.id, p.name
ORDER BY qty DESC;
```

### Ventas por empleado
```sql
SELECT u.full_name,
       COUNT(s.id) AS tickets,
       ROUND(SUM(s.total), 2) AS total
FROM sales s
JOIN users u ON u.id = s.user_id
WHERE s.deleted_at IS NULL
  AND s.status = 'completed'
GROUP BY u.id, u.full_name
ORDER BY total DESC;
```

### Productos mas vendidos
```sql
SELECT p.sku,
       p.name,
       SUM(si.quantity) AS total_unidades
FROM sale_items si
JOIN products p ON p.id = si.product_id
JOIN sales s ON s.id = si.sale_id
WHERE s.deleted_at IS NULL
  AND s.status = 'completed'
GROUP BY p.id, p.sku, p.name
ORDER BY total_unidades DESC
LIMIT 20;
```

## 6) Estructura sugerida en Flutter con Drift

Implementacion base agregada en:

- `lib/core/database/app_database.dart`

### Incluye
- Tablas Drift para ventas, inventario, caja, seguridad y auditoria.
- Configuracion SQLite con `PRAGMA foreign_keys = ON` y `WAL`.
- DAO principal `PosDao` con operaciones de ejemplo:
  - `openCashRegister`
  - `closeCashRegister`
  - `registerInventoryMovement`
  - `registerSale`
  - `getDailySalesReport`

### Inyeccion de dependencias
- Provider de BD y DAO en:
  - `lib/config/dependencies.dart`

## 7) Flujos de ejemplo

### Registrar venta
1. Insertar `sales`.
2. Insertar `sale_items`.
3. Descontar stock en `inventory`.
4. Registrar `inventory_movements` tipo `out`.
5. Insertar `payments`.
6. Insertar `cash_movements` tipo `income` si hay caja.
7. Guardar `audit_logs`.

### Registrar movimiento de inventario
1. Ajustar cantidad en `inventory`.
2. Insertar fila en `inventory_movements`.
3. Registrar auditoria.

### Apertura/Cierre de caja
- Apertura:
  - Insert `cash_registers` con estado `open`.
  - Insert `cash_movements` tipo `opening`.
- Cierre:
  - Update `cash_registers` a `closed` con montos/fechas.
  - Insert `cash_movements` tipo `closing`.

## 8) Notas de crecimiento

- Ya queda preparado para sincronizacion diferencial por `uuid`, `is_synced` y `sync_outbox`.
- El siguiente paso recomendado es agregar procesos de cola (retry/backoff) para sincronizar con backend cuando haya conectividad.
