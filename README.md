# Casa Común

App Flutter para organizar el aseo, las compras compartidas y los pagos de una casa de cuatro personas. La demo guarda los datos en cada dispositivo.

## Accesos de la demo local

| Cuenta | Usuario | Contraseña | Acceso |
| --- | --- | --- | --- |
| Isa | `isa` | `isa123` | Perfil de inquilina |
| Sebastián | `sebas` | `sebas123` | Perfil de inquilino |
| Andrea | `andrea` | `andrea123` | Perfil de inquilina |
| Sofi | `sofi` | `sofi123` | Perfil de inquilina |
| Administración | `admin` | `admin123` | Botón **Administración** |

La cuenta de administración gestiona perfiles, asignaciones y pagos. Los turnos y los aportes corresponden a los cuatro inquilinos. Al abrir datos de la versión anterior, el perfil de Sebastián conserva su identificador, sus pagos y su historial. La sesión anterior se cierra si tenía el rol administrativo.

Estas credenciales son públicas y sirven para probar el modo local. Para uso compartido, crea contraseñas nuevas en Supabase Auth.

## Cómo se organiza la casa

- Cada semana una pareja reparte baño, cocina, sala y pisos. Pisos incluye barrer y trapear. La administración puede ajustar una semana concreta.
- Las bolsas de basura tienen un responsable semanal. Botar la basura y comprar papel de baño tienen turnos que avanzan al completar cada tarea.
- El aporte de servicios es de **$60.000 COP por inquilino**. Vence el día 29 o el último día del mes cuando febrero tiene 28 días.
- La app muestra recordatorios desde el día 25 hasta el vencimiento y avisa de aportes atrasados. Son alertas internas que aparecen al abrir la app.
- La administración puede agregar tareas y turnos personalizados y exportar un respaldo JSON sin contraseñas.

## Ejecutar

```sh
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
flutter build web --release
```

También puedes ejecutar en Windows con `flutter run -d windows` si tienes instalado el toolchain de escritorio. Para Android, configura primero el SDK de Android.

## Arquitectura

- `lib/models/` define perfiles, planes, turnos, pagos y alertas.
- `lib/logic/rotation.dart` calcula las parejas y los responsables a partir del lunes 26 de octubre de 2026.
- `lib/state/app_state.dart` controla sesiones locales, permisos, cambios y alertas.
- `lib/data/` contiene la demo y su persistencia local con SharedPreferences.
- `lib/screens/` y `lib/ui/` implementan la interfaz, inspirada en la [skill Apple Design de Emil Kowalski](https://github.com/emilkowalski/skills/tree/main/skills/apple-design).

El esquema [de Supabase](supabase/schema.sql) prepara los datos compartidos y sus permisos. La app sigue usando el almacenamiento local. La [guía de Supabase](docs/SUPABASE.md) explica cómo preparar el proyecto y qué falta para conectar Flutter.
