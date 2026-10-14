"""Author: QRT Solutions. Create a single-use private pairing code and registration SQL."""
import argparse
import hashlib
import json
import secrets
import subprocess
from pathlib import Path


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--account-id', required=True)
    p.add_argument('--output', required=True)
    args = p.parse_args()
    output = Path(args.output).resolve()
    if output.exists() or subprocess.run(['git', 'check-ignore', '-q', str(output / 'probe')], check=False).returncode:
        raise ValueError('output_must_be_new_and_ignored')
    if not args.account_id or len(args.account_id) > 256 or '\x00' in args.account_id:
        raise ValueError('invalid_account')
    code = secrets.token_hex(16)
    digest = hashlib.sha256(code.encode()).hexdigest()
    account = args.account_id.replace("'", "''")
    sql = ("-- Author: QRT Solutions. Private scope; expires one hour after registration.\n"
           "insert into public.mt5_telegram_pairing(token_sha256,account_id,expires_at) "
           f"select '{digest}',account_id,now()+interval '60 minutes' "
           f"from public.mt5_accounts_snapshot where account_id='{account}' returning expires_at;\n")
    output.mkdir(parents=True, mode=0o700)
    for name, content in [('register.sql', sql), ('pairing.private.json', json.dumps({'code': code, 'hash': digest}))]:
        path = output / name
        path.write_text(content, encoding='utf-8')
        path.chmod(0o600)
    print('Código privado generado. Registrar el hash antes de entregar /vincular CODIGO al propietario.')


if __name__ == '__main__':
    try:
        main()
    except Exception as err:
        print(f'{type(err).__name__} (detalles omitidos por seguridad)')
        raise SystemExit(1) from None
