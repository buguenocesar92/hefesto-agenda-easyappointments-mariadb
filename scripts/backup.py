#!/usr/bin/env python3
"""Respaldo del kit hefesto-agenda (EasyAppointments + MariaDB).

El .env nunca se copia en claro: al respaldo solo van sus nombres (env.vars) y,
si hay receptor age, el .env cifrado (env.age). El manifiesto lleva las cinco
claves del contrato. Ver docs/CONTRATO-RESPALDO.md.
"""
import datetime
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from respaldo_contrato import (RespaldoError, escribir_manifiesto, ejecutar,
                               exportar_env, marcar_fallido)

SOFTWARE = "hefesto-agenda"
VERSION = "1.6.0"
DATABASE = "mariadb"
RAIZ = Path(__file__).resolve().parents[1]
os.chdir(RAIZ)
os.umask(0o077)


def dc(*args, **kw):
    return subprocess.run(["docker", "compose", *args], check=True, **kw)


def configuracion():
    """Archivos de configuracion que viajan en el respaldo (sin secretos)."""
    lista = ["compose.yaml", "compose.bootstrap.yaml", "Dockerfile"]
    contenedor = RAIZ / "container"
    if contenedor.is_dir():
        for p in sorted(contenedor.rglob("*")):
            if p.is_file():
                lista.append(str(p.relative_to(RAIZ)))
    return [n for n in lista if (RAIZ / n).is_file()]


def main():
    if not (RAIZ / ".env").is_file():
        raise SystemExit("Falta .env")
    if not dc("ps", "--status", "running", "-q", "app", capture_output=True, text=True).stdout.strip():
        raise SystemExit("app no esta activa en este contexto Compose; revisar recurso/proyecto.")
    carpeta = RAIZ / "backups" / datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    carpeta.mkdir(parents=True, mode=0o700)
    config = configuracion()
    try:
        dc("stop", "app")
        with (carpeta / "database.sql").open("wb") as out:
            dc("exec", "-T", "db", "sh", "-c",
               'MYSQL_PWD="$MARIADB_PASSWORD" mariadb-dump -u "$MARIADB_USER" '
               '--single-transaction --skip-lock-tables --no-tablespaces "$MARIADB_DATABASE"',
               stdout=out)
        with (carpeta / "storage.tar.gz").open("wb") as out:
            dc("run", "--rm", "--no-deps", "-T", "--entrypoint", "tar", "app",
               "-czf", "-", "-C", "/var/www/html/storage", ".", stdout=out)
        for nombre in config:
            destino = carpeta / nombre
            destino.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(RAIZ / nombre, destino)
        meta = exportar_env(RAIZ, carpeta)
        artefactos = ["database.sql", "storage.tar.gz", "env.vars"] + config
        if (carpeta / "env.age").is_file():
            artefactos.append("env.age")
        escribir_manifiesto(carpeta, SOFTWARE, VERSION, DATABASE, artefactos, extra=meta)
    except Exception:
        marcar_fallido(carpeta, SOFTWARE, VERSION, DATABASE)
        raise
    finally:
        dc("start", "app")
    print("Respaldo completo:", carpeta)
    print("El .env no viaja en claro: solo env.vars y, si hay receptor age, env.age.")
    return 0


if __name__ == "__main__":
    raise SystemExit(ejecutar(main))
