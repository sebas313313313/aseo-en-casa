# Preparar Supabase para Casa Común

Flutter sigue ejecutando la demo local. El esquema prepara un proyecto Supabase dedicado a esta casa, con cinco cuentas y datos separados por tipo.

## Crear el proyecto y las cuentas

1. Crea un proyecto de Supabase y habilita el proveedor **Email** en Authentication. Desactiva el registro público si el proyecto solo se usará para la casa.
2. Ejecuta [`supabase/schema.sql`](../supabase/schema.sql) en **SQL Editor**.
3. En **Authentication → Users**, crea las cuentas de Isa, Sebastián, Andrea, Sofi y Administración. Usa correos distintos y contraseñas propias. Copia el UUID de cada cuenta.
4. En **SQL Editor**, reemplaza cada UUID de ejemplo y ejecuta este bloque. Solo la cuenta de administración recibe el rol `admin`.

```sql
insert into public.profiles (id, name, username, role, color_hex)
values
  ('00000000-0000-0000-0000-000000000001', 'Isa', 'isa', 'tenant', '#FF6B6B'),
  ('00000000-0000-0000-0000-000000000002', 'Sebastián', 'sebas', 'tenant', '#4D96FF'),
  ('00000000-0000-0000-0000-000000000003', 'Andrea', 'andrea', 'tenant', '#B983FF'),
  ('00000000-0000-0000-0000-000000000004', 'Sofi', 'sofi', 'tenant', '#FFB443'),
  ('00000000-0000-0000-0000-000000000005', 'Administración', 'admin', 'admin', '#FF9F0A');
```

5. Guarda la **Project URL** y la **Publishable key** para la futura configuración de Flutter. La clave secreta y las contraseñas de las cuentas quedan fuera del repositorio y del cliente.

Si ya ejecutaste el esquema antiguo, revisa los roles existentes en `public.profiles` antes de conectar la app. El nuevo SQL deja inaccesible al cliente la tabla JSON antigua si existe. Los datos que quedaron allí se conservan para una revisión manual.

## Integración pendiente en Flutter

- Añadir Supabase Auth con dos accesos. Cada uno valida el rol que devuelve el servidor antes de abrir su pantalla. La sesión, el tema y los cambios del hogar tienen ciclos de vida distintos.
- Leer perfiles, configuración y registros desde sus tablas. Si se necesita importar datos de un dispositivo, mapear los identificadores locales a UUID y verificar las fechas y los responsables.
- Añadir operaciones transaccionales para completar tareas y avanzar turnos. El servidor debe verificar la asignación, aplicar el avance y guardar el historial en una sola operación. El esquema restringe esas escrituras directas al administrador hasta que existan dichas operaciones.
- Suscribirse a cambios de Realtime tras el inicio de sesión y comprobar el flujo con dos dispositivos y ambos roles. Los recordatorios actuales son internos. Una notificación con la app cerrada requiere configurar el envío push por separado.

Referencias oficiales de [Supabase Auth](https://supabase.com/docs/guides/auth/managing-user-data) y [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).
