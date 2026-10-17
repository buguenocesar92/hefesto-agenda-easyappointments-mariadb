# Fuentes consultadas el14-10-2026
- https://github.com/alextselegidis/easyappointments/releases/tag/1.6.0 — estable27-05-2026.
- https://easyappointments.org/ —1.6.0 estable y1.6.1 beta para pruebas.
- https://github.com/alextselegidis/easyappointments-docker — empaquetado oficial de producción.
- https://hub.docker.com/r/alextselegidis/easyappointments/tags — tag1.6.0 y digest de base.
- https://github.com/alextselegidis/easyappointments/blob/1.6.0/application/config/config.php — configuración nativa.
- https://easyappointments.org/documentation/installation/ — instalación.

Se sustituye el entrypoint generador de configuración por una capa Hefesto para escapar valores, fijar URL/cookies y generar clave de cifrado propia. Debe comprobarse mediante las pruebas de instalación; no constituye una nueva versión oficial del producto.
