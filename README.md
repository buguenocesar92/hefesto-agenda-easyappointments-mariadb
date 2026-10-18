# Hefesto Agenda · Easy!Appointments 1.6.0
Paquete para ofrecer agenda online a profesionales y empresas de servicios: configuración de servicios, prestadores, disponibilidad y gestión de reservas.

## Stack
Easy!Appointments1.6.0 estable, imagen derivada de la oficial fijada por digest, MariaDB11.4 y proxy HTTPS de Coolify. No se utiliza la beta1.6.1 ni el Docker de desarrollo del repositorio principal. Este producto es la aplicación independiente Easy!Appointments de easyappointments.org; no confundirla con otros plugins WordPress de nombre similar.

No requiere Supabase: se conserva MariaDB para evitar adaptar las consultas/esquema nativos. No hay conectores Odoo, pagos ni WhatsApp implementados.

## Qué incluye
Compose, Dockerfile, bootstrap privado por SSH, generador de secretos, escritor seguro de configuración PHP, respaldo coordinado, guías de operación/recuperación/traspaso y plantillas de servicios y pruebas.

La capa Hefesto genera configuración mediante literales PHP escapados (admite comillas en credenciales), establece URL canónica, cookies seguras con HTTPS y clave de cifrado propia persistente. No altera la lógica de reservas. La imagen se descarga al construir; el ZIP no contiene sus binarios.

## Estado
Archivos revisados estáticamente. No se ha construido/ejecutado Docker aquí, instalado la aplicación, enviado correos ni validado reservas reales. Las pruebas funcionales de aceptación son obligatorias antes de la entrega. El PHP se comprueba además con php -l durante el build, pendiente de ejecutar en el VPS.

## Inicio
1. `python3 scripts/configure.py cliente-demo agenda.tudominio.cl`
2. `docker compose -f compose.yaml -f compose.bootstrap.yaml up -d --build`
3. Desde tu computador: `ssh -L 8080:127.0.0.1:8080 usuario@IP_DEL_VPS`
4. Abrir http://127.0.0.1:8080 y completar asistente nativo (empresa y administrador).
5. Configurar SMTP y probar en privado. Revisar datos de ejemplo que pueda crear el asistente y eliminarlos antes de abrir reservas.
6. Seguir docs/COOLIFY.md para publicar conservando volúmenes y secretos.
7. Crear servicios/profesionales/horarios y completar docs/ACEPTACION.md.

Python3.11+ para scripts y Docker Compose v2. Recurso inicial orientativo:2vCPU,2GB RAM y20GB SSD, ajustado según actividad/retención. No publicar el asistente inicial en Internet.

## Despliegue en Coolify (MVP Hefesto)

Coolify consume `compose.yaml` como build pack Docker Compose, pone TLS y enruta el dominio al servicio `app` por Traefik. El compose no expone puertos, no nombra volúmenes ni fija el nombre de proyecto; Coolify asigna todo eso. Configurar en Coolify únicamente estas variables:

- `AGENDA_HOST` — dominio público (sin esquema); se usa para `BASE_URL` y cookies seguras.
- `DB_PASSWORD`, `DB_ROOT_PASSWORD`, `ENCRYPTION_KEY` — secretos que conserva Coolify; regenerarlos borra la agenda.
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_AUTH`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_CRYPTO` y `MAIL_FROM` — credenciales reales del proveedor. Sin SMTP la app usa `127.0.0.1:2525` y no envía confirmaciones.

Las variables `DB_VOLUME` y `STORAGE_VOLUME` que escribe `scripts/configure.py` se ignoran en esta rama: el compose no las usa. Solo `COMPOSE_PROJECT_NAME` sigue vigente para el flujo directo con `docker compose`. Las instalaciones previas que dependan de los nombres fijos deben migrar sus datos a los volúmenes nuevos (respaldo con `scripts/backup.py` y restauración, ver `docs/RESPALDOS-TRASPASO.md`) o quedarse en `main`; de lo contrario un `up` con esta rama arranca con una base vacía.

Antes de abrir el dominio:

1. Completar el asistente nativo de la aplicación (empresa y administrador) por acceso privado, reenvío de puerto o túnel SSH; nunca por HTTPS público. Si reaparece, retirar el dominio y revisar volúmenes.
2. Configurar SMTP real y probar el envío antes de admitir reservas. Con el SMTP por defecto no salen notificaciones.

## Licencia y alcance
Easy!Appointments conserva GPLv3 para código y CC BY3.0 para su contenido según upstream. Mantener avisos y obligaciones de redistribución. Hefesto cobra instalación, configuración, formación y soporte.

No incluye recordatorios programados, SMS, cobros, sincronización Google activa, firma electrónica, ficha clínica, control de salas simultáneas ni lógica de sobreventa personalizada. Confirmar capacidades nativas y requisitos antes de cotizar extensiones.
