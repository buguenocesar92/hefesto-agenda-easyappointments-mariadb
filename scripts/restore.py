#!/usr/bin/env python3
"""Restauracion de hefesto-agenda en un destino nuevo y vacio.

Sin --confirmar CONFIRMAR_RESTAURACION no se escribe nada; con --dry-run se
simula. Valida el manifiesto y los sha256 antes de tocar el destino, exige el
volumen de storage vacio y deja restore-report.json y auditoria.
"""
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from respaldo_contrato import (RespaldoError, auditar, ejecutar, ejecutar_check,
                               escribir_informe, opciones_restore)

SOFTWARE = "hefesto-agenda"
VERSION = "1.6.0"
DATABASE = "mariadb"
RAIZ = Path(__file__).resolve().parents[1]
os.chdir(RAIZ)
os.umask(0o077)


def dc(*args, **kw):
    return subprocess.run(["docker", "compose", *args], check=True, **kw)


def main():
    modo, origen = opciones_restore(sys.argv[1:])
    origen = Path(origen).resolve()
    ejecutar_check(str(origen), SOFTWARE, VERSION, DATABASE)
    if modo == "dry-run":
        print("Simulacion: el respaldo es integro y no se escribio nada.")
        print("Para restaurar de verdad: --confirmar CONFIRMAR_RESTAURACION")
        return 0
    if dc("ps", "--status", "running", "-q", "app", capture_output=True, text=True).stdout.strip():
        raise RespaldoError("app esta activa en el destino; detenerla antes de restaurar", 5)
    ocupado = dc("run", "--rm", "--no-deps", "-T", "--entrypoint", "find", "app",
                 "/var/www/html/storage", "-mindepth", "1", "-maxdepth", "1",
                 capture_output=True, text=True).stdout.strip()
    if ocupado:
        raise RespaldoError("El volumen de storage del destino no esta vacio; usar destino nuevo", 5)
    with (origen / "database.sql").open("rb") as flujo:
        dc("exec", "-T", "db", "sh", "-c",
           'MYSQL_PWD="$MARIADB_PASSWORD" mariadb -u "$MARIADB_USER" "$MARIADB_DATABASE"',
           stdin=flujo)
    with (origen / "storage.tar.gz").open("rb") as flujo:
        dc("run", "--rm", "--no-deps", "-T", "--entrypoint", "tar", "app",
           "-xzf", "-", "-C", "/var/www/html/storage", stdin=flujo)
    escribir_informe(origen, software=SOFTWARE, version=VERSION, database=DATABASE,
                     modo="confirmado", resultado="restaurado", destino=str(RAIZ))
    auditar(RAIZ, operacion="restore", kit=SOFTWARE, origen=str(origen),
            destino=str(RAIZ), resultado="restaurado")
    print("Datos restaurados. Probar en entorno privado antes de publicar.")
    return 0


if __name__ == "__main__":
    raise SystemExit(ejecutar(main))
