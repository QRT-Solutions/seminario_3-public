// Author: QRT Solutions. Dependency-free telemetry-only ingestion.
const MAX_BYTES = 512 * 1024;
const fields = {
  mt5_accounts_snapshot: {
    text: 'account_id broker server currency account_type margin_mode project_name',
    ids: 'login',
    numbers: 'balance equity margin margin_free margin_level profit_floating terminal_closed_profit today_closed_profit',
    integers: 'leverage open_positions_count terminal_total_deals today_trades_count',
    dates: 'updated_at', json: 'positions_json', conflict: 'account_id',
  },
  mt5_deals: {
    text: 'account_id broker project_name symbol deal_type deal_entry approval_status',
    ids: 'login deal_ticket order_ticket position_id',
    numbers: 'volume price profit commission swap', integers: '', dates: 'deal_time',
    json: '', conflict: 'deal_ticket',
  },
  mt5_swap_rates: {
    text: 'broker symbol', ids: '', numbers: 'swap_long swap_short',
    integers: 'swap_mode triple_swap_day', dates: 'updated_at', json: '', conflict: 'broker,symbol',
  },
};
const words = (s) => s ? s.split(' ') : [];
const object = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);
const identifier = (v) => typeof v === 'string' && /^(0|[1-9][0-9]{0,19})$/.test(v)
  && BigInt(v) <= 18446744073709551615n;
const finite = (v) => typeof v === 'number' && Number.isFinite(v);
const fail = (status, code) => Object.assign(new Error(code), {status, code});
const response = (status, body) => Response.json(body, {
  status, headers: {'Cache-Control': 'no-store'},
});

async function readJson(req) {
  if (!req.body) throw fail(400, 'invalid_payload');
  const reader = req.body.getReader();
  const chunks = [];
  let size = 0;
  while (true) {
    const {done, value} = await reader.read();
    if (done) break;
    size += value.byteLength;
    if (size > MAX_BYTES) {
      await reader.cancel();
      throw fail(413, 'payload_too_large');
    }
    chunks.push(value);
  }
  const data = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) { data.set(chunk, offset); offset += chunk.byteLength; }
  try { return JSON.parse(new TextDecoder('utf-8', {fatal: true}).decode(data)); }
  catch { throw fail(400, 'invalid_json'); }
}

function validPosition(p) {
  const keys = ['ticket','symbol','type','volume','open_price','current_price','sl','tp','profit','swap'];
  return object(p) && Object.keys(p).length === keys.length + ('position_id' in p ? 1 : 0) && keys.every(k => k in p)
    && (!('position_id' in p) || (identifier(p.position_id) && p.position_id !== '0')) && identifier(p.ticket) && typeof p.symbol === 'string' && p.symbol.length <= 128
    && ['BUY','SELL'].includes(p.type)
    && keys.slice(3).every(k => finite(p[k]));
}

export function validatePayload(payload, grant) {
  if (!object(payload) || Object.keys(payload).sort().join(',') !== 'account,records,resource')
    throw fail(400, 'invalid_payload');
  const {account, resource, records} = payload;
  if (!Object.hasOwn(fields, resource)) throw fail(400, 'unsupported_resource');
  if (!object(account) || Object.keys(account).sort().join(',') !== 'broker,login,server'
      || account.login !== grant.login || account.broker !== grant.broker || account.server !== grant.server)
    throw fail(403, 'account_not_allowed');
  if (!Array.isArray(records) || records.length < 1 || records.length > 100
      || (resource === 'mt5_accounts_snapshot' && records.length !== 1))
    throw fail(400, 'invalid_batch');
  const spec = fields[resource];
  const expected = ['text','ids','numbers','integers','dates','json'].flatMap(k => words(spec[k]));
  const deduplicated = new Map();
  for (const row of records) {
    const journalFields = resource === 'mt5_deals' ? ['deal_comment','order_comment','deal_reason','magic'] : [];
    const hasJournal = object(row) && journalFields.some(k => k in row);
    const allowed = hasJournal ? [...expected,...journalFields] : expected;
    if (!object(row) || Object.keys(row).length !== allowed.length || !allowed.every(k => k in row))
      throw fail(400, 'invalid_fields');
    if (words(spec.text).some(k => typeof row[k] !== 'string' || row[k].length > 256)
      || words(spec.ids).some(k => !identifier(row[k]))
      || words(spec.numbers).some(k => !finite(row[k]))
      || words(spec.integers).some(k => !Number.isSafeInteger(row[k]))
      || words(spec.dates).some(k => typeof row[k] !== 'string'
        || !/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/.test(row[k]) || !Number.isFinite(Date.parse(row[k]))))
      throw fail(400, 'invalid_fields');
    if (row.broker !== grant.broker || ('account_id' in row && row.account_id !== grant.account_id)
      || ('login' in row && row.login !== grant.login)
      || ('server' in row && row.server !== grant.server)
      || ('project_name' in row && row.project_name !== grant.project_name))
      throw fail(403, 'account_not_allowed');
    if (resource === 'mt5_accounts_snapshot') {
      if (!['DEMO','REAL','CONTEST'].includes(row.account_type) || !['HEDGING','NETTING'].includes(row.margin_mode)
          || !Array.isArray(row.positions_json) || row.positions_json.length > 500
          || !row.positions_json.every(validPosition) || row.open_positions_count !== row.positions_json.length)
        throw fail(400, 'invalid_snapshot');
    }
    if (resource === 'mt5_deals' && (!['BUY','SELL','BALANCE'].includes(row.deal_type)
      || !['IN','OUT','INOUT','OUT_BY'].includes(row.deal_entry) || !['PENDING','APPROVED'].includes(row.approval_status)))
      throw fail(400, 'invalid_deal');
    if (hasJournal && (typeof row.deal_comment !== 'string' || row.deal_comment.length > 1024
      || typeof row.order_comment !== 'string' || row.order_comment.length > 1024
      || !/^DEAL_REASON_(CLIENT|MOBILE|WEB|EXPERT|SL|TP|SO|ROLLOVER|VMARGIN|SPLIT|CORPORATE_ACTION)$/.test(row.deal_reason)
      || !identifier(row.magic))) throw fail(400, 'invalid_journal_fields');
    const key = spec.conflict.split(',').map(k => row[k]).join('\u0000');
    deduplicated.set(key, {...row});
  }
  return {resource, conflict: spec.conflict, records: [...deduplicated.values()]};
}

export function makeHandler({lookup, upsert, afterWrite = async () => {}, now = () => new Date()}) {
  return async (req) => {
    try {
      if (req.method !== 'POST') return response(405, {error: 'method_not_allowed'});
      const token = req.headers.get('x-mt5-token') ?? '';
      if (!/^mt5_[a-f0-9]{64}$/.test(token)) return response(401, {error: 'unauthorized'});
      const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(token));
      const hash = [...new Uint8Array(digest)].map(v => v.toString(16).padStart(2, '0')).join('');
      const grant = await lookup(hash);
      if (!grant || !grant.active || !grant.expires_at || Date.parse(grant.expires_at) <= now().getTime()
          || !Number.isFinite(Date.parse(grant.expires_at)))
        return response(401, {error: 'unauthorized'});
      if (!(req.headers.get('content-type') ?? '').toLowerCase().startsWith('application/json'))
        return response(415, {error: 'json_required'});
      const batch = validatePayload(await readJson(req), grant);
      const received_at = now().toISOString();
      await upsert(batch.resource, batch.conflict, batch.records.map(r => ({...r, received_at})));
      // Notification delivery is recoverable and must never fail a successful telemetry write.
      try { await afterWrite(grant.account_id); } catch { /* durable queue retries on a later heartbeat */ }
      return response(200, {ok: true, resource: batch.resource, accepted: batch.records.length, received_at});
    } catch (err) {
      // Never return database responses, personal data, tokens or stack traces.
      return response(err.status ?? 503, {error: err.code ?? 'temporarily_unavailable'});
    }
  };
}
