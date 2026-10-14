"""QRT Solutions: generate a scoped device credential locally; never upload a raw token."""

import argparse
import hashlib
import json
import os
import re
import secrets
import subprocess
from datetime import UTC, datetime, timedelta
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project-ref', required=True)
    parser.add_argument('--login', required=True)
    parser.add_argument('--broker', required=True)
    parser.add_argument('--server', required=True)
    parser.add_argument('--project-name', default='Seminario-3')
    parser.add_argument('--days', type=int, default=90)
    parser.add_argument('--output', default='.local/supabase-setup/device')
    args = parser.parse_args()
    if not re.fullmatch(r'[a-z]{20}', args.project_ref):
        parser.error('Referencia de proyecto invalida.')
    if not re.fullmatch(r'[1-9][0-9]{0,18}', args.login) or int(args.login) > 9223372036854775807:
        parser.error('Login MT5 invalido.')
    if not 1 <= args.days <= 365:
        parser.error('Vigencia permitida: 1 a 365 dias.')
    for value in (args.broker, args.server, args.project_name):
        if not value or len(value) > 256 or any(ord(c) < 32 for c in value):
            parser.error('Broker, servidor y proyecto requieren texto valido.')
    root = Path(args.output)
    probe = root / 'connection.json'
    result = subprocess.run(['git', 'check-ignore', '--quiet', str(probe)], check=False)
    if result.returncode != 0:
        parser.error('El destino debe estar excluido de Git. Usa .local/ dentro del clon.')
    if root.exists():
        parser.error('El destino ya existe. Reutiliza la credencial o elige otro directorio para rotarla.')
    root.mkdir(parents=True, mode=0o700)
    os.chmod(root, 0o700)
    token = 'mt5_' + secrets.token_hex(32)
    identity = {
        'author': 'QRT Solutions', 'project_ref': args.project_ref,
        'project_url': f'https://{args.project_ref}.supabase.co',
        'token': token, 'token_sha256': hashlib.sha256(token.encode()).hexdigest(),
        'login': args.login, 'broker': args.broker, 'server': args.server,
        'account_id': args.login + '_' + args.broker.replace(' ', '_'),
        'project_name': args.project_name,
        'expires_at': (datetime.now(UTC) + timedelta(days=args.days)).isoformat(),
    }
    params = {
        'InpSupabaseUrl': identity['project_url'], 'InpSupabaseKey': token,
        'InpProjectName': args.project_name, 'InpBrokerAlias': '',
        'InpEventDrivenSync': 'true', 'InpHeartbeatSeconds': '30', 'InpExportDeals': 'true',
        'InpExportSwapRates': 'true', 'InpWatchSymbols': '', 'InpEnableKillSwitch': 'false',
        'InpSaveLocalBackup': 'true', 'InpShowVisualPanel': 'true',
    }

    def write(name, text, encoding='utf-8'):
        fd = os.open(root / name, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, 'w', encoding=encoding, newline='') as stream:
            stream.write(text)

    def quote(value):
        return "'" + value.replace("'", "''") + "'"
    columns = ['token_sha256', 'login', 'broker', 'server', 'account_id', 'project_name', 'expires_at']
    write('connection.json', json.dumps(identity, indent=2))
    write('parameters.json', json.dumps(params, indent=2))
    write('register.sql', '-- Author: QRT Solutions. Private account scope; no raw token.\n'
          + 'insert into public.mt5_ingest_credentials (' + ','.join(columns) + ') values ('
          + ','.join(quote(identity[k]) for k in columns) + ');\n')
    write('revoke.sql', '-- Author: QRT Solutions. Revoke this credential only.\n'
          + 'update public.mt5_ingest_credentials set active=false where token_sha256='
          + quote(identity['token_sha256']) + ';\n')
    inputs = '; Author: QRT Solutions. PRIVATE: do not share or commit.\r\n'
    inputs += '\r\n'.join(k + '=' + v for k, v in params.items()) + '\r\n'
    write('MT5_Telemetry_Supabase.set', inputs, encoding='utf-16')
    print(f'Credencial creada en {root}. No se muestra el secreto. Registro remoto pendiente.')


if __name__ == '__main__':
    try:
        main()
    except Exception as err:
        raise SystemExit(type(err).__name__ + ' (detalles omitidos por seguridad)') from None
