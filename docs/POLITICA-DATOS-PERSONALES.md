# Política de tratamiento de datos personales — Agenda (Hefesto Studio)

Estado: vigente desde 2026-10-20. Responsable del tratamiento: el cliente que
opera el kit. Este documento describe qué datos guarda el kit, por qué, cuánto
tiempo los retiene y cómo se exercise los derechos del titular (Ley 21.719).

## 1. Qué datos guarda este kit

El kit de agenda (EasyAppointments) guarda, por persona atendida:

- **Registro de la reserva**: nombre, correo, teléfono, servicio contratado,
  profesional que atiende, fecha y hora, estado (pendiente, confirmado,
  cancelado) y notas internas.
- **Cuentas de la aplicación**: usuario, hash de contraseña, rol y estado.
- **Disponibilidad y agenda del profesional**: horarios y franjas bloqueadas.
- **Copias locales de respaldo**: `backups/<timestamp>/` con el dump de MariaDB
  (`database.sql`), el almacenamiento de archivos (`storage.tar.gz`) y la
  configuración del kit.

Los datos de la reserva identifican a personas que 联系 con el prestador del
servicio: la agenda es un registro de atenciones, no un dato comercial.

## 2. Qué datos NO guarda este kit

- El `.env` **no** se copia en claro al respaldo: solo sus nombres de
  variable (`env.vars`) y, si hay un receptor `age` configurado, el `.env`
  cifrado (`env.age`). Ver `docs/CONTRATO-RESPALDO.md`, regla 5.
- El kit no guarda el historial de pagos: no hay pasarela de pago integrada.
- El kit no exporta los datos de las reservas a servicios de terceros.

## 3. Base legal y deberes

- **Minimización**: el kit guarda solo lo indispensable para atender la reserva: identidad
  de contacto, servicio y horario. No guarda documentos de identidad, dirección
  postal ni datos de salud.
- **Finalidad**: agendar y atender las reservas del cliente. Los datos no se usan para otros fines ni se ceden a terceros.
- **Seguridad**: los respaldos se cifran en reposo con `age` hacia el destino del operador, la clave privada no está en este servidor y el `.env` nunca sale en claro.
- **Auditoría**: cada respaldo y cada restauración dejan registro en `logs/restore.log` con origen, sha256 verificado, destino y resultado. Es registro de actividades de tratamiento: no guarda valores de secretos.

## 4. Retención

| Dato | Dónde | Retención por defecto | Quién lo borra |
|---|---|---|---|
| Datos de la reserva | MariaDB (volumen `database`) | mientras el cliente los mantenga en la agenda | el operador, desde la interfaz |
| Cuentas de la aplicación | MariaDB (volumen `database`) | mientras la cuenta exista | el operador |
| Respaldos en disco | `backups/<timestamp>/` | **a definir por el operador**; el kit no borra nada por su cuenta | el operador |
| Registro de auditoría | `logs/restore.log` | append-only; se trunca por política del cliente | el operador |

**El kit no borra respaldos ni datos por su cuenta.** Borrar es una decisión del
operador, porque un respaldo borrado no se recupera.

## 5. Derechos del titular (acceso, rectificación y supresión)

El cliente que opera el kit debe poder atender las solicitudes de sus
titulares sobre los datos de la reserva:

1. **Acceso**: entregar los datos de una reserva concreta desde la interfaz de
   la agenda o desde el dump de la base.
2. **Rectificación**: corregir nombre, correo o teléfono desde la interfaz.
3. **Supresión**: eliminar la reserva y dejar constancia de la supresión en el
   registro de auditoría.
4. **Revocación del consentimiento**: si el tratamiento depende del
   consentimiento, eliminar la reserva.

El kit garantiza que los datos son localizables, corregibles y borrables; el
cliente es quien conoce la identidad de los titulares.

## 6. Verificación

- `bats tests/backup_restore.bats` comprueba, con datos sintéticos, que el
  `.env` no queda en claro, que el manifiesto lleva las cinco claves, que un
  artefacto alterado se rechaza y que un destino no vacío aborta la
  restauración.
- `gitleaks` corre en CI sobre el repositorio y su historial.
