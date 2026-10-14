"""Author: QRT Solutions. Generate private setup artifacts; never handles a bot token."""
import argparse
import hashlib
import json
import re
import secrets
import subprocess
import time
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--bot-username', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    if not re.fullmatch(r'[A-Za-z0-9_]{5,32}', args.bot_username):
        raise ValueError('invalid_username')
    output = Path(args.output).resolve()
    probe = subprocess.run(['git', 'check-ignore', '-q', str(output / 'probe')], check=False)
    if probe.returncode != 0 or output.exists():
        raise ValueError('output_must_be_ignored_and_new')
    output.mkdir(parents=True, mode=0o700)
    setup_key = secrets.token_hex(32)
    config = {'author': 'QRT Solutions', 'botUsername': args.bot_username,
              'keyHash': hashlib.sha256(setup_key.encode()).hexdigest(),
              'expiresAt': int((time.time()+900)*1000)}
    for name, value in [('setup.private.json', config), ('client.private.json', {'setupKey': setup_key})]:
        path = output / name
        path.write_text(json.dumps(value), encoding='utf-8')
        path.chmod(0o600)
    print('Configuración temporal generada; vigencia de 15 minutos. No contiene el token del bot.')


if __name__ == '__main__':
    try:
        main()
    except Exception as err:
        print(f'{type(err).__name__} (detalles omitidos por seguridad)')
        raise SystemExit(1) from None
