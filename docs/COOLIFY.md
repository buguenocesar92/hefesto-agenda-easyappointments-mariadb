# Despliegue
1. Configurar DNS agenda.cliente.cl y HTTPS. Crear secretos y completar bootstrap privado del README.
2. Probar administrador. La aplicación puede crear servicios/proveedores de ejemplo al instalar: revisar y retirar antes de admitir reservas.
3. Detener bootstrap con `docker compose -f compose.yaml -f compose.bootstrap.yaml down` SIN -v.
4. Subir archivos versionables a repositorio privado, excluyendo .env/backups. Crear recurso Docker Compose con build desde raíz.
5. Copiar variables .env a Coolify. Mantener DB_VOLUME, STORAGE_VOLUME, ENCRYPTION_KEY y contraseñas; no regenerarlos.
6. Asociar https://agenda.cliente.cl al servicio app, puerto80. No exponer db ni bootstrap. Construir y desplegar.
7. Comprobar que no reaparece el asistente, que las URLs/cookies son HTTPS y que login, calendario y formulario público funcionan detrás del proxy.

Si reaparece instalación, retirar dominio y corregir volúmenes/base. El healthcheck solo prueba HTTP, no que el asistente esté completado ni que la agenda esté bien configurada.

## SMTP
Configurar SMTP_HOST/PORT/AUTH/USERNAME/PASSWORD/CRYPTO y MAIL_FROM con credenciales reales del proveedor. SMTP_AUTH=1 para autenticación; SMTP_CRYPTO=tls o ssl según proveedor. No dejar debug SMTP activado. Sin configurar, la app intenta127.0.0.1:2525 y no envía: acciones de reserva/notificación pueden mostrar errores. No abrir reservas reales con ese estado.

No hace falta crear APP_KEY de Laravel; este producto usa ENCRYPTION_KEY propia de su configuración. El archivo .env de Compose contiene las claves que el contenedor usa para generar config.php/email.php cada arranque; no editarlos manualmente dentro del contenedor.

## Red e imagen
El Dockerfile añade solo la generación de configuración sobre base oficial1.6.0. El almacenamiento persistente es /var/www/html/storage y la base MariaDB. Cualquier modificación adicional de código/assets debe mantenerse en el repositorio y documentarse, no dentro del contenedor.

La rama MariaDB11.4 no fija parche; registrar digest al entregar y validar actualizaciones. No cambiar la base oficial por latest sin comprobar compatibilidad.
