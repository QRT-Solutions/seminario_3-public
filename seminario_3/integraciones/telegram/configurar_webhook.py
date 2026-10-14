"""Author: QRT Solutions. Call the temporary installer without handling the Telegram token."""
import argparse
import json
import re
import urllib.request
from pathlib import Path


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project-ref', required=True)
    parser.add_argument('--installation', required=True)
    args = parser.parse_args()
    if not re.fullmatch(r'[a-z]{20}', args.project_ref):
        raise ValueError('invalid_project_ref')
    folder = Path(args.installation)
    key = json.loads((folder / 'client.private.json').read_text())['setupKey']
    url = f'https://{args.project_ref}.supabase.co/functions/v1/mt5-telegram/setup'
    req = urllib.request.Request(url, data=b'{}', headers={'Content-Type': 'application/json', 'x-setup-key': key}, method='POST')
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())
    with opener.open(req, timeout=40) as response:
        data = json.load(response)
    result = folder / 'setup-result.json'
    result.write_text(json.dumps(data), encoding='utf-8')
    result.chmod(0o600)
    print('Webhook configurado y verificado. Desplegar ahora index.ts SIN setup.ts ni setup.private.json.')


if __name__ == '__main__':
    try:
        main()
    except Exception as err:
        print(f'{type(err).__name__} (detalles omitidos por seguridad)')
        raise SystemExit(1) from None
