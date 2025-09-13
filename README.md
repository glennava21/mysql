 🏢 Sistema de Gestión de Coworking

**Autor:** Samuel Alexander Rodríguez Becerra  

Este proyecto consiste en el diseño y desarrollo de una **base de datos relacional en MySQL** para administrar eficientemente todas las operaciones de un espacio de coworking moderno.  
La solución es **robusta, escalable** y refleja escenarios reales de administración de usuarios, reservas, membresías, pagos y control de accesos.

---

## 🚀 Objetivo
Facilitar la **gestión integral de un coworking**:  
- Control de usuarios y empresas.  
- Administración de membresías.  
- Gestión de espacios y reservas.  
- Facturación y pagos.  
- Registro de accesos y auditoría de eventos.

---

## 🗂️ Estructura de la Base de Datos

### Tablas principales
- **empresas**: Información de empresas asociadas.
- **usuarios**: Datos de usuarios individuales, con relación opcional a empresas.
- **roles** y **usuario_roles**: Sistema de permisos y roles (Admin, Staff, Cliente, Corporativo).
- **logs**: Registro de eventos importantes.

### Membresías
- **membresias_tipo**: Catálogo de tipos de membresía (Mensual, Anual, Premium, etc.).
- **usuario_membresias**: Histórico de membresías de cada usuario.

### Espacios y reservas
- **espacios**: Tipos de espacios: escritorios, oficinas privadas, salas de reuniones o eventos.
- **reservas**: Reservas de espacios, incluyendo estado y duración.
- **reserva_servicios**: Servicios extra asociados a una reserva.

### Servicios
- **servicios**: Catálogo de servicios adicionales (Locker, Café, Parking…).
- **usuario_servicios**: Servicios contratados de forma permanente.

### Facturación y pagos
- **facturas**: Registro de facturación de membresías y reservas.
- **pagos**: Control de pagos realizados, pendientes o fallidos.

### Seguridad y control
- **registros_acceso**: Entradas y salidas de usuarios mediante RFID, QR o registro manual.
- **accesos_fallidos**: Intentos de acceso no autorizados.
- **auditoria**: Historial de cambios críticos en el sistema.

---

## 💾 Datos de prueba incluidos
El script incluye datos de ejemplo:
- 5 empresas y 10 usuarios con distintos roles.
- 6 tipos de membresía y múltiples estados (Activa, Suspendida, Vencida).
- Espacios de trabajo y reservas en diferentes estados (Confirmada, Cancelada, NoShow).
- Servicios adicionales, facturas y pagos de prueba.

---

## 🛠️ Requisitos

- **MySQL 8.x** o compatible.
- Herramienta de gestión (por ejemplo, MySQL Workbench o phpMyAdmin).

---

## ▶️ Instalación y Uso

1. **Clonar o descargar** este repositorio.  
2. Importar el archivo `coworking.sql` en tu servidor MySQL:
   ```bash
   mysql -u usuario -p < coworking.sql
   ```
3. Verificar que la base de datos y tablas se hayan creado:
   ```sql
   SHOW DATABASES;
   USE coworking;
   SHOW TABLES;
   ```

---

## 🔍 Consultas de ejemplo
Algunas consultas útiles que ya vienen en el script:
- Usuarios con membresía activa.
- Usuarios que nunca han hecho una reserva.
- Reservas con servicios adicionales contratados.
- Reporte de ingresos mensuales por pagos.

---

## 🛡️ Recomendaciones
- Implementar **backups automáticos** para proteger la información.
- Usar **roles y privilegios de MySQL** para limitar accesos.
- Añadir **validaciones y triggers** si se requiere mayor consistencia de datos.

---

## 📄 Licencia
... (1 línea restante)
