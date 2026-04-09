# Flutter POS Cafetería - Clean Architecture

## Estructura de carpetas

- **core/**: Utilidades globales (temas, constantes, helpers, manejo de errores)
- **features/**: Módulos del sistema, cada uno con data/domain/presentation
- **shared/**: Widgets y componentes reutilizables
- **config/**: Configuración de rutas, dependencias e inyección
- **services/**: APIs externas (facturación, base de datos, etc.)

### Módulos en features/
- ventas
- inventario
- caja
- administracion
- reportes
- facturacion
- pedidos_internos
- seguridad

Cada módulo:
- data/: models, datasources, repositories impl
- domain/: entities, abstract repositories, use cases
- presentation/: pages/screens, widgets, controllers/state management

## Interacción de capas

- **presentation**: UI y lógica de presentación. Interactúa con los casos de uso del dominio.
- **domain**: Lógica de negocio pura. Define entidades, repositorios abstractos y casos de uso.
- **data**: Implementa repositorios, modelos y fuentes de datos (API/local).
- **core/shared/services/config**: Soporte transversal, utilidades, widgets comunes, configuración e inyección de dependencias.

## Estado y dependencias
- Se recomienda usar **Riverpod** para gestión de estado e inyección de dependencias.
- Ejemplo de provider e inyección en config/

## Navegación
- Definir rutas en config/routes.dart

## API REST y errores
- Preparado para consumir APIs REST desde data/datasources
- Manejo de errores centralizado en core/errors

## .gitignore
- Incluido para Flutter/Dart

