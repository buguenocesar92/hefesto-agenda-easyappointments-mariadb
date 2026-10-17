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

## Licencia y alcance
Easy!Appointments conserva GPLv3 para código y CC BY3.0 para su contenido según upstream. Mantener avisos y obligaciones de redistribución. Hefesto cobra instalación, configuración, formación y soporte.

No incluye recordatorios programados, SMS, cobros, sincronización Google activa, firma electrónica, ficha clínica, control de salas simultáneas ni lógica de sobreventa personalizada. Confirmar capacidades nativas y requisitos antes de cotizar extensiones.
