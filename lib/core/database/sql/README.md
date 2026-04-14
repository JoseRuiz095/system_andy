# SQL POS Offline-First - Endurecimiento para Produccion

Este README documenta los refuerzos aplicados al modelo SQLite/Drift para cubrir escenarios reales de produccion en un POS de cafeteria.

## Cobertura de tus 11 puntos

## 1) Precios historicos (critico)

Se cubre en `sale_items` con snapshot de venta:

- `unit_price`: precio aplicado al momento de la venta.
- `cost_price`: costo historico para calculo de utilidad.
- `discount_percent` y `discount_amount`: descuento historico.
- `line_subtotal` y `line_total`: importes historicos calculados y persistidos.

Resultado: cambios de precio en `products` no alteran reportes historicos.

## 2) Impuestos (MX)

Se reforzo impuesto por linea y cabecera:

- En `sale_items`:
  - `tax_rate`
  - `tax_amount`
- En `sales`:
  - `subtotal`
  - `tax`
  - `total`

El DAO calcula por linea y acumula en cabecera para precision fiscal y auditoria.

## 3) Estados de venta completos

`sales.status` ahora valida:

- `draft`
- `pending`
- `in_progress`
- `completed`
- `cancelled`
- `refunded`

Nota: `draft` se incluyo para resiliencia ante crash/incompletas.

## 4) Sesiones de usuario

Nueva tabla `user_sessions`:

- `user_id`
- `cash_register_id`
- `login_at`
- `logout_at`
- `is_active`

Permite trazabilidad de quien estuvo logueado por turno y asociar ventas a sesion.

## 5) Multi-sucursal desde hoy

Nueva tabla `branches` y `branch_id` agregado en:

- `sales`
- `inventory`
- `cash_registers`
- `cash_movements`
- `receipts`
- `inventory_movements`
- `inventory_batches`

Evita refactor mayor cuando el negocio crezca.

## 6) Productos complejos (cafeteria real)

Soporte agregado:

- `product_variants`: tamanos/variantes por producto.
- `modifiers`: extras (ej. shot, leche).
- `product_modifiers`: relacion de modificadores permitidos por producto.
- `sale_item_modifiers`: snapshot de extras vendidos.

## 7) Unidades de medida

Nueva tabla `units` y referencias:

- `products.unit_id`
- `inventory_movements.unit_id`

Permite manejar piezas, gramos, mililitros, etc.

## 8) Lotes y caducidad

Nueva tabla `inventory_batches`:

- `product_id`
- `branch_id`
- `batch_code`
- `quantity`
- `expiration_date`
- `cost_price`

Con esto ya hay base real para FEFO/caducidad.

## 9) Folios robustos offline

Nueva tabla `folio_sequences` con clave unica por:

- `branch_id`
- `doc_type`
- `work_date`

El DAO genera folio de venta con formato:

- `V-BRANCH-YYYYMMDD-####`

Esto minimiza duplicados en operacion offline por sucursal y dia.

Refuerzo adicional implementado:

- Generacion atomica del consecutivo en una sola sentencia SQL con `UPSERT + RETURNING`.
- Se evita condicion de carrera en multi-caja/multi-hilo dentro del mismo dispositivo.

## 9.1) Idempotencia para sync

Se agregaron llaves idempotentes en:

- `sales.idempotency_key`
- `payments.idempotency_key`
- `refunds.idempotency_key`

Estas columnas son `UNIQUE` para evitar duplicados cuando hay reintentos de sincronizacion, caidas de red o reenvio de requests.

## 9.2) Zona horaria

Regla aplicada:

- Los timestamps de escritura se normalizan a UTC en la capa DAO.
- `work_date` se mantiene como llave de negocio por dia/sucursal para folios.
- Nunca depender de hora local para reportes contables o sincronizacion.

## 10) Seguridad local basica

Se reforzo estructura de usuario:

- `users.password_hash`
- `users.password_algo` (default `bcrypt`)
- `users.pin_hash`

Recomendacion operativa:

- Hash bcrypt para password/PIN (nunca guardar plaintext).
- Si el riesgo lo exige, evaluar SQLite cifrado (SQLCipher).

## 11) Consistencia y errores

Se reforzo en DAO `registerSale`:

- Validacion de estado permitido.
- Validacion de pago minimo para `completed`.
- Transaccion unica para cabecera, items, pagos, inventario y auditoria.
- Uso de `draft`/`pending` para ventas incompletas.

Efecto: si algo falla en pago/inserciones, SQLite hace rollback completo.

Refuerzo adicional implementado:

- Recuperacion de ventas en estado `draft/pending/in_progress` mediante consultas de recovery.
- Metodo para marcar ventas recuperadas como canceladas cuando corresponda.

### Integridad de pagos

Para ventas `completed` se valida que:

- `SUM(payments.amount) == sales.total`

Si no coincide, la operacion falla antes de confirmar la transaccion.

### Caja abierta unica por sucursal

Se agrega un indice unico parcial:

- `cash_registers(branch_id) WHERE status = 'open'`

Esto evita dos cajas abiertas simultaneamente en la misma sucursal.

## 12) Endurecimiento final multi-device y sync real

Este bloque cubre los ultimos riesgos de produccion cuando hay varias tablets o cajas trabajando offline al mismo tiempo.

### 12.1) Identidad de origen por dispositivo

Se agrego `device_id` en:

- `sales`
- `payments`
- `cash_movements`
- `sync_outbox`

Ademas, `sales.sale_number` puede evolucionar a un formato por dispositivo para evitar colisiones offline entre tablets de la misma sucursal.

### 12.2) Snapshot completo por evento de sync

La regla de oro es que el backend debe reconstruir la operacion solo con el evento.

Para `sales`, el `payload_json` de `sync_outbox` debe incluir:

- cabecera
- items
- modifiers
- pagos
- impuestos

No debe depender de consultas adicionales en el backend para recomponer la venta.

### 12.3) Entidades inmutables por diseno

Se recomienda escribir solo por insercion para estas entidades:

- `sales`
- `payments`
- `inventory_movements`

Si hay correccion, debe hacerse con soft delete o con un evento compensatorio, nunca con UPDATE de negocio.

### 12.4) Control de reloj del dispositivo

UTC ya esta normalizado, pero aun asi conviene guardar el desfase con el servidor:

- `server_time_offset_seconds`

La aplicacion puede advertir si el desfase supera un umbral operativo.

### 12.5) Cold start mas robusto

En la primera sincronizacion conviene descargar:

- catalogo completo
- configuraciones
- sucursal

Opcionalmente, bloquear ventas hasta completar esta fase para evitar operar con datos incompletos.

### 12.6) Versionado de API

Se agrega `api_version` en el flujo de sync para evitar roturas cuando el backend cambie:

- `sync_outbox.api_version`
- `sync_status.api_version`

### 12.7) Tamano de payload y batch

Cuando la cola crece, conviene aplicar:

- gzip en requests
- lotes limitados, por ejemplo 50 eventos por envio

Esto reduce latencia y evita payloads demasiado grandes en ventas con muchos items.

### 12.8) Observabilidad de sync

Se agrego `sync_status` para monitoreo operativo por dispositivo:

- `last_sync_at`
- `pending_events_count`
- `failed_events_count`
- `last_error`

Tambien puede guardarse `server_time_offset_seconds` para diagnosticar drift de reloj.

## 13) Blindajes finales de largo plazo

Estos puntos no rompen la arquitectura actual, pero si conviene dejarlos cerrados antes de escalar a SaaS o a volumen alto.

### 13.1) Dinero en centavos

Se implemento migracion en `payments` para guardar importes en `INTEGER` (centavos), requisito obligatorio para cobro en produccion real.

Ejemplo:

- `$10.50` -> `1050`

Motivo:

- evita errores de precision acumulativos
- protege caja e impuestos
- simplifica conciliacion contable

Columnas ya migradas:

- `payments.amount`
- `payments.received_amount`
- `payments.change_amount`

Nota: para una fase posterior, se recomienda extender centavos al resto de columnas monetarias historicas.

### 13.2) Firma de eventos

Se agrego `sync_outbox.signature` como campo opcional para firmar eventos con HMAC del `payload_json` y una clave compartida.

Esto ayuda a detectar manipulacion de cliente, payload alterado o fraude basico.

### 13.3) Reglas duras en backend

Las reglas no deben quedar solo como recomendacion del cliente.

El backend debe tratar estas tablas como inmutables por negocio:

- `sales` -> sin UPDATE
- `payments` -> append-only
- `inventory_movements` -> append-only

Si hace falta corregir, debe hacerse por evento compensatorio o soft delete segun aplique.

### 13.4) Archivado y particionado logico

Tablas que creceran mucho:

- `audit_logs`
- `inventory_movements`
- `sync_outbox`

Recomendacion:

- archivado por fecha o por sucursal
- exportacion historica a almacenamiento frio
- retencion diferenciada por tipo de dato

### 13.5) Backup local

Si una tablet muere, la copia local puede ser la unica fuente de recuperacion.

Opciones practicas:

- export JSON
- dump SQLite

Lo ideal es automatizarlo en ventana de cierre o al detectar sincronizacion exitosa.

### 13.6) Feature flags y configuracion remota

Se agrego `feature_flags` para controlar comportamiento por sucursal o globalmente sin redeploy:

- inventario negativo
- validaciones
- reglas de sync

Esto permite apagar o ajustar comportamiento operativo desde backend de manera controlada.

### 13.7) Defaults y nulabilidad en campos criticos

Se reforzo en entidades de operacion y sync:

- `uuid` -> `NOT NULL`
- `created_at` -> `NOT NULL`
- `updated_at` -> `NOT NULL`
- `is_synced` -> `DEFAULT 0`
- `device_id` -> `NOT NULL DEFAULT 'unknown-device'` en `sales`, `payments`, `cash_movements`, `sync_outbox`

Esto reduce bugs silenciosos por datos incompletos en modo offline.

### 13.8) Performance de cola de sync

Se agrego indice para procesamiento masivo de eventos:

- `idx_sync_outbox_status ON sync_outbox(status, created_at DESC)`

Con esto el polling por estado en lotes grandes se mantiene estable.

## Ajustes Senior/Pro adicionales

1. Concurrencia de folios:
- `generateSaleNumber` ahora incrementa folio con operacion atomica (`INSERT ... ON CONFLICT ... DO UPDATE ... RETURNING`).

2. Arqueo de caja:
- `cash_registers` incluye `expected_amount`, `counted_amount` y `difference_amount`.
- `closeCashRegister` calcula esperado desde movimientos y guarda diferencia.

3. Reembolsos parciales:
- Tablas nuevas `refunds` y `refund_items`.
- Metodo `registerPartialRefund` para devolver productos especificos sin cancelar toda la venta.

4. Inventario negativo configurable:
- `branches.allow_negative_inventory` define politica por sucursal.
- Si esta desactivado, el DAO bloquea salida sin stock suficiente.

5. FEFO real:
- Consumo por lotes ordenado por caducidad (`expiration_date`) y luego recepcion (`received_at`).
- Si faltan lotes y la sucursal permite negativo, descuenta remanente sin lote.

6. Versionado de esquema:
- `schemaVersion = 7`.
- `onUpgrade` agrega columnas/tablas nuevas sin romper instalaciones existentes.

7. Auditoria extendida:
- `audit_logs` ahora incluye `old_values` y `new_values` en JSON para trazabilidad fina.

8. Indices compuestos clave:
- `idx_sales_branch_date`.
- `idx_inventory_product_branch`.
- Indices nuevos para reembolsos (`idx_refunds_sale`, `idx_refund_items_sale_item`).

9. Precisión monetaria:
- La capa transaccional de cobro y caja ya opera con `INTEGER` en centavos.
- Se elimino el riesgo de precision acumulativa en pagos/caja y montos de venta/reembolso.

10. Conflictos de sincronizacion:
- Politica recomendada: `last write wins` para catalogos simples y reglas de negocio explicitas para inventario/ventas.
- `uuid`, `updated_at` e `is_synced` quedan como base para resolver conflictos en backend.

11. Validacion periodica de integridad:
- Se recomienda un job de mantenimiento que revise:
  - inventario vs movimientos,
  - ventas vs pagos,
  - caja vs movimientos.
  - discrepancias entre `total`, `tax` y reembolsos.

9. Soft delete operativo:
- Las consultas de negocio/recuperacion filtran `deleted_at IS NULL`.
- Recomendacion: mantener esta regla en todos los DAOs y reportes nuevos.

## Estructura final principal

## Catalogo y seguridad

- `branches`
- `units`
- `users`, `roles`, `permissions`, `user_roles`, `role_permissions`, `user_sessions`

## Inventario

- `suppliers`, `products`, `product_variants`
- `modifiers`, `product_modifiers`
- `inventory`, `inventory_batches`, `inventory_movements`

## Venta/caja

- `payment_methods`
- `cash_registers`, `cash_movements`
- `sales`, `sale_items`, `sale_item_modifiers`, `payments`, `receipts`
- `folio_sequences`

## Integracion/sync

- `audit_logs`
- `sync_status`
- `sync_outbox`

## Archivos tecnicos

- SQL: `lib/core/database/sql/pos_schema.sql`
- Drift + DAO: `lib/core/database/app_database.dart`
- Codigo generado Drift: `lib/core/database/app_database.g.dart`

## Comandos

Generar codigo Drift:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Analizar proyecto:

```bash
flutter analyze
```

## Notas de operacion

- El modelo esta listo para POS offline-first multi-sucursal.
- Reportes historicos son consistentes por snapshots en `sale_items`.
- Queda preparada la sincronizacion futura por `uuid` + `is_synced` + `device_id` + `sync_outbox` + `sync_status`.
