# Preparación de la agenda
## Empresa y atención
Configurar nombre, correo y sitio de la empresa. Establecer America/Santiago donde la interfaz permita zona horaria, tanto para prestadores como para presentación al cliente. La imagen fija PHP a esa zona, pero eso no reemplaza las preferencias de usuarios/empresa. Probar cambios de horario estacional con fechas representativas.

Crear categorías y servicios con duración, precio informativo, descripción y disponibilidad. El precio mostrado no implica pago cobrado. Asociar cada servicio con los profesionales que efectivamente lo prestan.

Configurar jornada, pausas, excepciones, vacaciones y días cerrados por prestador. Revisar antelación mínima, horizonte de reserva y capacidad conforme a las opciones nativas. Para evitar reservas superpuestas, probar dos usuarios sobre el mismo horario y revisar el resultado real antes de prometer concurrencia o capacidad determinada.

## Roles
Administrador para configuración; prestador para su agenda; secretaria para agendas asignadas según permisos nativos. Usar cuentas individuales. Probar visibilidad de datos con usuarios sin privilegios; no asumir que una cuenta de recepción debe ver a todos los clientes.

## Flujo público
Seleccionar servicio → prestador → fecha/hora → datos de contacto → confirmar → revisar reserva en administración y notificación. Probar también cambio y cancelación mediante los mecanismos nativos disponibles, así como horarios ya ocupados.

Pedir solo datos necesarios. Las notas de reserva no deben usarse como ficha clínica ni depósito de documentos sensibles. Esta configuración no certifica cumplimiento legal por sí sola.

## Correos e integraciones
Configurar remitente y SMTP primero; validar confirmación, cambio y cancelación contra correo recibido, no solo una pantalla de éxito. No se ejecuta scheduler adicional para recordatorios: este ZIP no implementa recordatorios temporizados.

Google Calendar permanece deshabilitado en la capa de configuración. Activarlo requiere credenciales OAuth, revisión del flujo nativo1.6.0 y pruebas de conflictos/permisos; no basta con escribir un ID. Pagos, n8n, WhatsApp y Odoo son integraciones posteriores con alcance separado.

## Branding
Usar opciones nativas de empresa/textos disponibles en la versión instalada. Cualquier cambio adicional de tema debe versionarse y probarse tras actualizar. No se incluye una landing custom ni un panel distinto del nativo.
