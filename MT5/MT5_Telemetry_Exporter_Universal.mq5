//+------------------------------------------------------------------+
//|                             MT5_Telemetry_Exporter_Universal.mq5 |
//|                                                    QRT Solutions |
//|                                             www.qrtsolutions.com |
//+------------------------------------------------------------------+
#property copyright   "QRT Solutions"
#property link        "https://www.qrtsolutions.com"
#property version     "3.40"
#property description "Telemetria MT5 hacia receptor Supabase con credencial por cuenta. Sin funciones de trading ni cierre remoto."

// Solo lectura: no se incluye ninguna libreria de ejecucion de operaciones.

//+------------------------------------------------------------------+
//| Parametros de Entrada Modulares                                  |
//+------------------------------------------------------------------+
input group "=== 1. Conexion a la Nube (Supabase / REST) ==="
input string   InpSupabaseUrl        = "";                  // URL del Proyecto Supabase (ej: https://xyz.supabase.co)
input string   InpSupabaseKey        = "";                  // Credencial mt5_ exclusiva del receptor (NO clave API Supabase)
input string   InpProjectName        = "Default-Project";   // Nombre del Proyecto
input string   InpBrokerAlias        = "";                  // Alias de Broker (Vacio = Auto-detectar de MT5)

input group "=== 2. Transmision en Tiempo Real y Eventos ==="
input bool     InpEventDrivenSync    = true;                // Reactividad sub-segundo en OnTradeTransaction
input int      InpHeartbeatSeconds   = 30;                  // Intervalo de latido / snapshot de cuenta (segundos)
input bool     InpExportDeals        = true;                // Exportar aperturas, cierres y comentarios del historial
input bool     InpExportSwapRates    = true;                // Exportar radar de tasas swap de mercado
input string   InpWatchSymbols       = "";                  // Simbolos adicionales para radar swap (separados por coma)
input bool     InpEnableKillSwitch   = false;               // Debe ser false: cierre remoto no soportado en esta version

input group "=== 3. Auditoria y Respaldo Local ==="
input bool     InpSaveLocalBackup    = true;                // Guardar JSON de respaldo en MQL5/Files
input bool     InpShowVisualPanel    = true;                // Mostrar panel de telemetria en el grafico



//+------------------------------------------------------------------+
//| Helper: Limpiar caracteres especiales para JSON seguro           |
//+------------------------------------------------------------------+
string EscapeJson(string text)
{
   string result = "";
   for(int i = 0; i < StringLen(text); i++)
   {
      ushort ch = StringGetCharacter(text, i);
      if(ch == 34) result += "\\\"";
      else if(ch == 92) result += "\\\\";
      else if(ch < 32) result += StringFormat("\\u%04x", (uint)ch);
      else result += StringSubstr(text, i, 1);
   }
   return result;
}

//+------------------------------------------------------------------+
//| Helper: Timestamp ISO 8601 UTC                                   |
//+------------------------------------------------------------------+
string FormatIsoTimestamp(datetime dt)
{
   MqlDateTime mdt;
   TimeToStruct(dt, mdt);
   return StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ",
                       mdt.year, mdt.mon, mdt.day,
                       mdt.hour, mdt.min, mdt.sec);
}

//+------------------------------------------------------------------+
//| Variables Globales de Control y Estado                           |
//+------------------------------------------------------------------+
static long     g_lastLogin              = 0;
static int      g_lastTotalDeals         = -1;
static ulong    g_firstSyncedTicket      = 0;
static ulong    g_maxSyncedTicket        = 0;
static datetime g_lastHeartbeatTime      = 0;
static int      g_lastHttpStatus         = 0;
static string   g_cleanSupabaseUrl       = "";
static string   g_cleanSupabaseKey       = "";

// Declaraciones de funciones operativas
void CollectAndSendSnapshot();
void ExportDeals(string accountId, long login, string company);
void ExportSingleDeal(ulong dealTicket, string accountId, long login, string company);
void ExportSwapRates(string company);
int  SendHttpRequest(string url, string jsonBody);

//+------------------------------------------------------------------+
//| OnInit: Inicializacion y Auto-Deteccion de Cuenta                |
//+------------------------------------------------------------------+
int OnInit()
{
   if(InpEnableKillSwitch)
   {
      Print("[ERROR] Esta version no admite cierre remoto. InpEnableKillSwitch debe ser false.");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InpHeartbeatSeconds < 5)
   {
      Print("[ERROR] InpHeartbeatSeconds debe ser al menos 5.");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(!EventSetTimer(5))
   {
      Print("[ERROR] No se pudo inicializar OnTimer. Error: ", GetLastError());
      return(INIT_FAILED);
   }

   // Sanitizar URL y Key de Supabase eliminando espacios o slash final
   g_cleanSupabaseUrl = InpSupabaseUrl;
   StringTrimLeft(g_cleanSupabaseUrl);
   StringTrimRight(g_cleanSupabaseUrl);
   while(StringLen(g_cleanSupabaseUrl) > 0 && StringSubstr(g_cleanSupabaseUrl, StringLen(g_cleanSupabaseUrl) - 1, 1) == "/")
   {
      g_cleanSupabaseUrl = StringSubstr(g_cleanSupabaseUrl, 0, StringLen(g_cleanSupabaseUrl) - 1);
   }

   g_cleanSupabaseKey = InpSupabaseKey;
   StringTrimLeft(g_cleanSupabaseKey);
   StringTrimRight(g_cleanSupabaseKey);

   if(g_cleanSupabaseUrl != "" &&
      (StringFind(g_cleanSupabaseUrl, "https://") != 0 ||
       StringFind(g_cleanSupabaseKey, "mt5_") != 0 || StringLen(g_cleanSupabaseKey) != 68))
   {
      EventKillTimer();
      Print("[ERROR] Se requiere URL HTTPS del proyecto y credencial mt5_ del receptor.");
      return INIT_PARAMETERS_INCORRECT;
   }

   long login       = AccountInfoInteger(ACCOUNT_LOGIN);
   string broker    = (InpBrokerAlias != "") ? InpBrokerAlias : AccountInfoString(ACCOUNT_COMPANY);
   string server    = AccountInfoString(ACCOUNT_SERVER);
   string curr      = AccountInfoString(ACCOUNT_CURRENCY);
   long marginMode  = AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   long tradeMode   = AccountInfoInteger(ACCOUNT_TRADE_MODE);

   string modeStr = (marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) ? "HEDGING" : "NETTING";
   string typeStr = (tradeMode == ACCOUNT_TRADE_MODE_REAL) ? "REAL" : (tradeMode == ACCOUNT_TRADE_MODE_DEMO ? "DEMO" : "CONTEST");

   PrintFormat("====================================================================");
   PrintFormat("MT5 Telemetry Exporter Universal v3.4 inicializado exitosamente");
   PrintFormat(" * Proyecto    : %s", InpProjectName);
   PrintFormat(" * Cuenta      : %I64d (%s) | %s | %s", login, broker, modeStr, typeStr);
   PrintFormat(" * Servidor    : %s | Moneda: %s", server, curr);
   PrintFormat(" * Nube URL    : %s", (g_cleanSupabaseUrl != "") ? g_cleanSupabaseUrl : "NO CONFIGURADA (Modo Local)");
   PrintFormat("====================================================================");

   CollectAndSendSnapshot();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| OnDeinit: Limpieza al retirar el EA                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   Comment("");
   Print("[INFO] MT5 Telemetry Exporter Universal detenido. Razon: ", reason);
}

//+------------------------------------------------------------------+
//| OnTimer: Latido periodico (Heartbeat)                            |
//+------------------------------------------------------------------+
void OnTimer()
{
   long login = AccountInfoInteger(ACCOUNT_LOGIN);
   if(login <= 0) return;

   datetime now = TimeGMT();
   int interval = MathMax(5, InpHeartbeatSeconds);
   if(now - g_lastHeartbeatTime >= interval)
   {
      CollectAndSendSnapshot();
   }
}

//+------------------------------------------------------------------+
//| OnTradeTransaction: Reactividad sub-segundo para Telegram         |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   if(!InpEventDrivenSync) return;

   // Author: QRT Solutions. SL/TP changes do not create a deal. Read-only snapshot.
   if(trans.type == TRADE_TRANSACTION_POSITION)
   {
      CollectAndSendSnapshot();
      return;
   }

   // Capturar nuevo deal inmediatamente para el flujo Human-in-the-Loop de Telegram
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      long login = AccountInfoInteger(ACCOUNT_LOGIN);
      string company = (InpBrokerAlias != "") ? InpBrokerAlias : AccountInfoString(ACCOUNT_COMPANY);
      string sanitized = company;
      StringReplace(sanitized, " ", "_");
      string accountId = StringFormat("%I64d_%s", login, sanitized);

      PrintFormat("[EVENTO TRADE] Deal #%I64u detectado. Despachando a Supabase -> Telegram...", trans.deal);
      
      ExportSingleDeal(trans.deal, accountId, login, company);
      CollectAndSendSnapshot();
   }
}

// Author: QRT Solutions. Preserve broker comments separately from manual journal notes.
string BuildDealJson(ulong ticket, string accountId, long login, string company, string status)
{
   long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
   long type = HistoryDealGetInteger(ticket, DEAL_TYPE);
   ulong order = (ulong)HistoryDealGetInteger(ticket, DEAL_ORDER);
   ulong position = (ulong)HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
   string entryStr = entry == DEAL_ENTRY_IN ? "IN" :
                     entry == DEAL_ENTRY_OUT ? "OUT" :
                     entry == DEAL_ENTRY_OUT_BY ? "OUT_BY" : "INOUT";
   string reason = EnumToString((ENUM_DEAL_REASON)HistoryDealGetInteger(ticket, DEAL_REASON));
   HistoryOrderSelect(order);
   string orderComment = HistoryOrderGetString(order, ORDER_COMMENT);
   string comment = HistoryDealGetString(ticket, DEAL_COMMENT);
   return StringFormat(
      "{\"deal_ticket\":\"%I64u\",\"order_ticket\":\"%I64u\",\"position_id\":\"%I64u\","
      "\"account_id\":\"%s\",\"login\":\"%I64d\",\"broker\":\"%s\",\"project_name\":\"%s\","
      "\"symbol\":\"%s\",\"deal_type\":\"%s\",\"deal_entry\":\"%s\",\"volume\":%.8f,\"price\":%.8f,"
      "\"profit\":%.2f,\"commission\":%.2f,\"swap\":%.2f,\"deal_time\":\"%s\","
      "\"approval_status\":\"%s\",\"deal_comment\":\"%s\",\"order_comment\":\"%s\","
      "\"deal_reason\":\"%s\",\"magic\":\"%I64u\"}",
      ticket, order, position, EscapeJson(accountId), login, EscapeJson(company), EscapeJson(InpProjectName),
      EscapeJson(HistoryDealGetString(ticket, DEAL_SYMBOL)), type == DEAL_TYPE_BUY ? "BUY" : "SELL",
      entryStr, HistoryDealGetDouble(ticket, DEAL_VOLUME), HistoryDealGetDouble(ticket, DEAL_PRICE),
      HistoryDealGetDouble(ticket, DEAL_PROFIT), HistoryDealGetDouble(ticket, DEAL_COMMISSION),
      HistoryDealGetDouble(ticket, DEAL_SWAP), FormatIsoTimestamp((datetime)HistoryDealGetInteger(ticket, DEAL_TIME)),
      status, EscapeJson(comment), EscapeJson(orderComment), EscapeJson(reason),
      (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC)
   );
}

//+------------------------------------------------------------------+
//| Despachar Deal Individual Instantaneo para Webhook de Telegram   |
//+------------------------------------------------------------------+
void ExportSingleDeal(ulong dealTicket, string accountId, long login, string company)
{
   if(dealTicket == 0 || g_cleanSupabaseUrl == "") return;

   if(!HistoryDealSelect(dealTicket))
   {
      HistorySelect(TimeCurrent() - 60, TimeCurrent() + 60);
      if(!HistoryDealSelect(dealTicket)) return;
   }

   long dealType = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
   if(dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL) return;
   string payload = "[" + BuildDealJson(dealTicket, accountId, login, company, "PENDING") + "]";

   string url = "mt5_deals";
   int code = SendHttpRequest(url, payload);
   if(code >= 200 && code < 300)
   {
      PrintFormat("[TELEMETRY] Deal #%I64u subido con estado PENDING para revision (HTTP %d).", dealTicket, code);
   }
}

//+------------------------------------------------------------------+
//| Recolectar y Despachar Snapshot Completo                         |
//+------------------------------------------------------------------+
void CollectAndSendSnapshot()
{
   bool isConnected = (bool)TerminalInfoInteger(TERMINAL_CONNECTED);
   long login       = AccountInfoInteger(ACCOUNT_LOGIN);

   if(!isConnected && login == 0)
   {
      Comment("MT5 Telemetry: Desconectado del Broker. Esperando red...");
      return;
   }

   if(login != g_lastLogin)
   {
      PrintFormat("[ROTACION] Cambio de cuenta detectado (%I64d -> %I64d). Reinicializando cache.", g_lastLogin, login);
      g_lastLogin         = login;
      g_lastTotalDeals    = -1;
      g_firstSyncedTicket = 0;
      g_maxSyncedTicket   = 0;
   }

   string company      = (InpBrokerAlias != "") ? InpBrokerAlias : AccountInfoString(ACCOUNT_COMPANY);
   string server       = AccountInfoString(ACCOUNT_SERVER);
   string currency     = AccountInfoString(ACCOUNT_CURRENCY);
   long   marginMode   = AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   long   tradeMode    = AccountInfoInteger(ACCOUNT_TRADE_MODE);
   long   leverage     = AccountInfoInteger(ACCOUNT_LEVERAGE);

   double balance      = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity       = AccountInfoDouble(ACCOUNT_EQUITY);
   double margin       = AccountInfoDouble(ACCOUNT_MARGIN);
   double margin_free  = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   double profit       = AccountInfoDouble(ACCOUNT_PROFIT);

   string sanitized = company;
   StringReplace(sanitized, " ", "_");
   string accountId = StringFormat("%I64d_%s", login, sanitized);

   // 1. Posiciones Abiertas
   int totalPositions = PositionsTotal();
   string positionsJson = "[";

   for(int i = 0; i < totalPositions; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      string sym        = PositionGetString(POSITION_SYMBOL);
      long   posType    = PositionGetInteger(POSITION_TYPE);
      double vol        = PositionGetDouble(POSITION_VOLUME);
      double priceOpen  = PositionGetDouble(POSITION_PRICE_OPEN);
      double priceCurr  = PositionGetDouble(POSITION_PRICE_CURRENT);
      double sl         = PositionGetDouble(POSITION_SL);
      double tp         = PositionGetDouble(POSITION_TP);
      double posProfit  = PositionGetDouble(POSITION_PROFIT);
      double posSwap    = PositionGetDouble(POSITION_SWAP);

      string typeStr = (posType == POSITION_TYPE_BUY) ? "BUY" : "SELL";

      string posObj = StringFormat(
         "{\"ticket\":\"%I64u\",\"position_id\":\"%I64u\",\"symbol\":\"%s\",\"type\":\"%s\",\"volume\":%.8f,"
         "\"open_price\":%.8f,\"current_price\":%.8f,\"sl\":%.8f,\"tp\":%.8f,"
         "\"profit\":%.2f,\"swap\":%.2f}",
         ticket, (ulong)PositionGetInteger(POSITION_IDENTIFIER), EscapeJson(sym), typeStr, vol,
         priceOpen, priceCurr, sl, tp, posProfit, posSwap
      );

      if(StringLen(positionsJson) > 1) positionsJson += ",";
      positionsJson += posObj;
   }
   positionsJson += "]";

   // 2. Metricas Acumuladas
   double terminalClosedProfit = 0;
   int    terminalTotalDeals    = 0;
   double todayClosedProfit    = 0;
   int    todayTradesCount     = 0;

   MqlDateTime mdt;
   TimeToStruct(TimeCurrent(), mdt);
   mdt.hour = 0; mdt.min = 0; mdt.sec = 0;
   datetime todayStart = StructToTime(mdt);

   if(HistorySelect(0, TimeCurrent() + 86400))
   {
      int hTotal = HistoryDealsTotal();
      for(int i = 0; i < hTotal; i++)
      {
         ulong t = HistoryDealGetTicket(i);
         if(t == 0) continue;

         long entry = HistoryDealGetInteger(t, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT) continue;

         terminalTotalDeals++;
         double net = HistoryDealGetDouble(t, DEAL_PROFIT) + 
                      HistoryDealGetDouble(t, DEAL_COMMISSION) + 
                      HistoryDealGetDouble(t, DEAL_SWAP);
         terminalClosedProfit += net;

         datetime dTime = (datetime)HistoryDealGetInteger(t, DEAL_TIME);
         if(dTime >= todayStart)
         {
            todayTradesCount++;
            todayClosedProfit += net;
         }
      }
   }

   string nowIso = FormatIsoTimestamp(TimeGMT());
   string modeStr = (marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) ? "HEDGING" : "NETTING";
   string typeStr = (tradeMode == ACCOUNT_TRADE_MODE_REAL) ? "REAL" : (tradeMode == ACCOUNT_TRADE_MODE_DEMO ? "DEMO" : "CONTEST");

   string snapshotPayload = StringFormat(
      "[{"
      "\"account_id\":\"%s\","
      "\"login\":\"%I64d\","
      "\"broker\":\"%s\","
      "\"server\":\"%s\","
      "\"currency\":\"%s\","
      "\"account_type\":\"%s\","
      "\"margin_mode\":\"%s\","
      "\"leverage\":%I64d,"
      "\"balance\":%.2f,"
      "\"equity\":%.2f,"
      "\"margin\":%.2f,"
      "\"margin_free\":%.2f,"
      "\"margin_level\":%.2f,"
      "\"profit_floating\":%.2f,"
      "\"open_positions_count\":%d,"
      "\"positions_json\":%s,"
      "\"updated_at\":\"%s\","
      "\"project_name\":\"%s\","
      "\"terminal_closed_profit\":%.2f,"
      "\"terminal_total_deals\":%d,"
      "\"today_closed_profit\":%.2f,"
      "\"today_trades_count\":%d"
      "}]",
      EscapeJson(accountId), login, EscapeJson(company), EscapeJson(server),
      EscapeJson(currency), typeStr, modeStr, leverage,
      balance, equity, margin, margin_free, margin_level, profit,
      totalPositions, positionsJson, nowIso, EscapeJson(InpProjectName),
      terminalClosedProfit, terminalTotalDeals, todayClosedProfit, todayTradesCount
   );

   // 3. Respaldo Local en Disco
   if(InpSaveLocalBackup)
   {
      string filename = StringFormat("telemetry_%I64d.json", login);
      int handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_ANSI);
      if(handle != INVALID_HANDLE)
      {
         FileWriteString(handle, snapshotPayload);
         FileClose(handle);
      }
   }

   // 4. Despacho a Supabase
   if(g_cleanSupabaseUrl != "")
   {
      string snapshotUrl = "mt5_accounts_snapshot";
      g_lastHttpStatus = SendHttpRequest(snapshotUrl, snapshotPayload);
      if(g_lastHttpStatus >= 200 && g_lastHttpStatus < 300)
      {
         g_lastHeartbeatTime = TimeGMT();
      }
   }

   // 5. Exportar Historial de Deals
   if(InpExportDeals)
   {
      ExportDeals(accountId, login, company);
   }

   // 6. Exportar Radar Swaps
   if(InpExportSwapRates)
   {
      ExportSwapRates(company);
   }

   // 7. Panel Visual en Grafico
   if(InpShowVisualPanel)
   {
      string httpStr = (g_lastHttpStatus >= 200 && g_lastHttpStatus < 300) ? "CONECTADO (200 OK)" : 
                       ((g_cleanSupabaseUrl == "") ? "MODO LOCAL (Sin URL)" : StringFormat("ERROR HTTP %d", g_lastHttpStatus));

      Comment(StringFormat(
         "================================================================\n"
         "          MT5 TELEMETRY EXPORTER UNIVERSAL v3.2                 \n"
         "================================================================\n"
         " * Proyecto     : %s\n"
         " * Cuenta       : %I64d (%s) [%s | %s]\n"
         " * Servidor     : %s | Moneda: %s | Lev: 1:%I64d\n"
         " * Hora Broker  : %s | Local: %s (GMT: %s)\n"
         "----------------------------------------------------------------\n"
         " * Balance      : %s %.2f\n"
         " * Equity       : %s %.2f (Flotante: %.2f)\n"
         " * Posiciones   : %d abiertas\n"
         " * PnL de Hoy   : %s %.2f (%d trades cerrados)\n"
         "----------------------------------------------------------------\n"
         " * Kill-Switch  : %s\n"
         " * Nube Status  : %s (Ultimo: %s UTC)\n"
         "================================================================",
         InpProjectName, login, company, modeStr, typeStr, server, currency, leverage,
         TimeToString(TimeCurrent(), TIME_SECONDS), TimeToString(TimeLocal(), TIME_SECONDS), TimeToString(TimeGMT(), TIME_SECONDS),
         currency, balance, currency, equity, profit, totalPositions,
         currency, todayClosedProfit, todayTradesCount,
         "DESACTIVADO (sin funciones de trading)",
         httpStr, nowIso
      ));
   }
}

//+------------------------------------------------------------------+
//| Exportar Historial de Entradas y Salidas (Lotes de 50)               |
//+------------------------------------------------------------------+
void ExportDeals(string accountId, long login, string company)
{
   if(g_cleanSupabaseUrl == "") return;
   if(!HistorySelect(0, TimeCurrent() + 86400)) return;

   int totalDeals = HistoryDealsTotal();
   if(totalDeals <= 0) return;

   ulong firstTicket = HistoryDealGetTicket(0);
   if(totalDeals == g_lastTotalDeals && firstTicket == g_firstSyncedTicket) return;

   string dealsJson = "[";
   int batch = 0;
   ulong newMaxTicket = g_maxSyncedTicket;

   for(int i = 0; i < totalDeals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;

      long dType = HistoryDealGetInteger(ticket, DEAL_TYPE);
      if(dType != DEAL_TYPE_BUY && dType != DEAL_TYPE_SELL) continue;
      if(g_lastTotalDeals != -1 && ticket <= g_maxSyncedTicket) continue;
      string obj = BuildDealJson(ticket, accountId, login, company, "APPROVED");

      if(batch > 0) dealsJson += ",";
      dealsJson += obj;
      batch++;

      if(ticket > newMaxTicket) newMaxTicket = ticket;

      if(batch >= 50)
      {
         dealsJson += "]";
         string url = "mt5_deals";
      int code = SendHttpRequest(url, dealsJson);
      if(code < 200 || code >= 300) return; // Reintentar sin avanzar el cursor.
         dealsJson = "[";
         batch = 0;
         Sleep(100);
      }
   }

   if(batch > 0)
   {
      dealsJson += "]";
      string url = "mt5_deals";
      int code = SendHttpRequest(url, dealsJson);
      if(code < 200 || code >= 300) return; // Reintentar sin avanzar el cursor.
   }

   g_lastTotalDeals    = totalDeals;
   g_firstSyncedTicket = firstTicket;
   g_maxSyncedTicket   = newMaxTicket;
}

//+------------------------------------------------------------------+
//| Exportar Radar de Tasas Swap de Mercado                          |
//+------------------------------------------------------------------+
void ExportSwapRates(string company)
{
   if(g_cleanSupabaseUrl == "") return;

   string symbols[];
   ArrayResize(symbols, 1);
   symbols[0] = _Symbol;

   if(InpWatchSymbols != "")
   {
      string extra[];
      int k = StringSplit(InpWatchSymbols, ',', extra);
      for(int i = 0; i < k; i++)
      {
         StringTrimLeft(extra[i]);
         StringTrimRight(extra[i]);
         if(extra[i] != "")
         {
            int sz = ArraySize(symbols);
            ArrayResize(symbols, sz + 1);
            symbols[sz] = extra[i];
         }
      }
   }

   int posTotal = PositionsTotal();
   for(int i = 0; i < posTotal; i++)
   {
      ulong t = PositionGetTicket(i);
      if(t > 0)
      {
         string s = PositionGetString(POSITION_SYMBOL);
         bool found = false;
         for(int j = 0; j < ArraySize(symbols); j++)
            if(symbols[j] == s) { found = true; break; }
         if(!found)
         {
            int sz = ArraySize(symbols);
            ArrayResize(symbols, sz + 1);
            symbols[sz] = s;
         }
      }
   }

   string payload = "[";
   int count = 0;
   string nowIso = FormatIsoTimestamp(TimeGMT());

   for(int s = 0; s < ArraySize(symbols); s++)
   {
      string sym = symbols[s];
      if(!SymbolInfoInteger(sym, SYMBOL_SELECT)) SymbolSelect(sym, true);

      double sLong  = SymbolInfoDouble(sym, SYMBOL_SWAP_LONG);
      double sShort = SymbolInfoDouble(sym, SYMBOL_SWAP_SHORT);
      long   sMode  = SymbolInfoInteger(sym, SYMBOL_SWAP_MODE);
      long   tDay   = SymbolInfoInteger(sym, SYMBOL_SWAP_ROLLOVER3DAYS);

      if(sLong == 0 && sShort == 0 && !SymbolInfoInteger(sym, SYMBOL_EXIST)) continue;

      string obj = StringFormat(
         "{\"broker\":\"%s\",\"symbol\":\"%s\",\"swap_long\":%.4f,\"swap_short\":%.4f,"
         "\"swap_mode\":%d,\"triple_swap_day\":%d,\"updated_at\":\"%s\"}",
         EscapeJson(company), EscapeJson(sym), sLong, sShort, (int)sMode, (int)tDay, nowIso
      );

      if(count > 0) payload += ",";
      payload += obj;
      count++;
   }
   payload += "]";

   if(count > 0)
   {
      string url = "mt5_swap_rates";
         SendHttpRequest(url, payload);
   }
}

//+------------------------------------------------------------------+
//| HTTP WebRequest Universal                                        |
//+------------------------------------------------------------------+
int SendHttpRequest(string resource, string jsonBody)
{
   if(g_cleanSupabaseUrl == "") return 0;
   if(resource != "mt5_accounts_snapshot" && resource != "mt5_deals" && resource != "mt5_swap_rates")
      return -1;

   string broker = (InpBrokerAlias != "") ? InpBrokerAlias : AccountInfoString(ACCOUNT_COMPANY);
   string envelope = StringFormat(
      "{\"resource\":\"%s\",\"account\":{\"login\":\"%I64d\",\"broker\":\"%s\",\"server\":\"%s\"},\"records\":%s}",
      resource, AccountInfoInteger(ACCOUNT_LOGIN), EscapeJson(broker),
      EscapeJson(AccountInfoString(ACCOUNT_SERVER)), jsonBody);
   string url = g_cleanSupabaseUrl + "/functions/v1/mt5-telemetry";
   string headers = "Content-Type: application/json\r\nx-mt5-token: " + g_cleanSupabaseKey + "\r\n";
   char postData[], result[];
   string resultHeaders;
   int size = StringToCharArray(envelope, postData, 0, WHOLE_ARRAY, CP_UTF8);
   if(size > 0 && postData[size - 1] == 0) ArrayResize(postData, size - 1);
   ResetLastError();
   int res = WebRequest("POST", url, headers, 10000, postData, result, resultHeaders);
   if(res == -1)
   {
      PrintFormat("[TELEMETRY] %s fallo WebRequest: %d. Revisar URL permitida: %s",
                  resource, GetLastError(), g_cleanSupabaseUrl);
      return -1;
   }
   PrintFormat("[TELEMETRY] %s HTTP %d", resource, res);
   return res;
}
