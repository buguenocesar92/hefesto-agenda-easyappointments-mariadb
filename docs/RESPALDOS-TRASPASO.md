# Respaldo y traslado
`python3 scripts/backup.py` genera dump SQL, storage.tar.gz, .env, Compose, Dockerfile y manifest con hashes. Detiene app para consistencia y luego intenta reiniciar; programar pausa de acceso. Ejecutar dentro del contexto real de Coolify/Compose, con sus variables y nombres de proyecto.

Verificar manifest.status=completed, salida del script y app activa. Las citas/contactos y claves son sensibles: cifrar y copiar fuera del VPS. No se incluyen cifrado, almacenamiento remoto, cron o rotación. Conservar repositorio/ZIP completo junto al respaldo; Dockerfile depende de container/.

## Recuperación en destino vacío
1. Usar esta versión1.6.0 y validar hashes del manifest.
2. Recuperar .env original con modo0600; conservar ENCRYPTION_KEY y contraseñas. Para pruebas cambiar el nombre de proyecto; los volúmenes los asigna Compose automáticamente.
3. Construir imagen: `docker compose build`.
4. `docker compose up -d db`; esperar healthy y verificar base easyappointments vacía. No sobrescribir una base con datos.
5. `docker compose exec -T db sh -c 'MYSQL_PWD="$MARIADB_PASSWORD" mariadb -u "$MARIADB_USER" "$MARIADB_DATABASE"' < /ruta/respaldo/database.sql`
6. `docker compose run --rm --no-deps -T --entrypoint tar app -xzf - -C /var/www/html/storage < /ruta/respaldo/storage.tar.gz`
7. Revisar SMTP y salida externa antes de iniciar copia de pruebas; evitar correos duplicados a clientes. Abrir por bootstrap privado y validar usuarios, prestadores, horarios y citas.
8. Para migración final detener origen, hacer respaldo final, restaurar destino, ajustar dominio y probar antes de cambiar DNS. No aceptar reservas en dos instancias independientes simultáneamente.

Restaurar solo copias propias confiables. No ejecutar down -v sobre datos reales. Cambiar variables DB_PASSWORD no cambia por sí solo la contraseña ya almacenada en MariaDB.

## Actualizar y entregar
Revisar notas oficiales y procedimiento de migración para la versión destino; no asumir migración automática por sustituir imagen. Ensayar con copia de la base. Rollback puede requerir base/archivos compatibles.

Entregar dominio, infraestructura/Coolify, repositorio, versiones/digests, nombres de volúmenes, ENCRYPTION_KEY, credenciales DB, administrador, SMTP, respaldo probado y configuración de horarios. Secretos por gestor seguro separado. El dump restaura Easy!Appointments, no convierte la agenda a Odoo o Supabase.
