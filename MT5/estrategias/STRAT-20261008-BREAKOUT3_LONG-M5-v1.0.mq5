// Author: QRT Solutions
// STRAT-20261008-BREAKOUT3_LONG-M5-v1.0
// M5: Buy Stop at the maximum of three closed bars; 0.10 lots; 600s.
#property copyright "QRT Solutions"
#property version   "1.00"
#property description "M5 breakout: High[1..3], 0.10 lots, ATR D1 barriers, 600-second exit."
#include <Trade\Trade.mqh>

enum ENUM_TESTER_CRITERION
{
   CRITERION_CUMULATIVE_PCT_RETURN = 0,
   CRITERION_SHARPE_PCT           = 1,
   CRITERION_PROFIT_FACTOR_PCT    = 2
};
input bool InPenableTrading = false; // Habilitar Trading Real (Seguridad)
input ulong InpMagicNumber = 2026100801; // Una instancia por simbolo y Magic
input ENUM_TESTER_CRITERION InTesterCriterion = CRITERION_CUMULATIVE_PCT_RETURN;

const double FIXED_LOTS = 0.10;
const int LOOKBACK_BARS = 3;
const int ATR_PERIOD = 14;
const double SL_ATR_MULTIPLIER = 0.25;
const double TP_ATR_MULTIPLIER = 0.50;
const long HOLD_MILLISECONDS = 600000;

struct SPositionReturn
{
   ulong id;
   double entry_volume;
   double entry_notional;
   double exit_volume;
   double exit_notional;
   double money_net;
   long entry_msc;
   long exit_msc;
};

class CBreakout3
{
private:
   CTrade m_trade;
   int m_atr;
   datetime m_last_bar;
   datetime m_last_exit;
   datetime m_test_start;
   datetime m_last_close_attempt;
   bool m_enabled;
   bool m_netting;

   datetime ServerNow()
   {
      if(MQLInfoInteger(MQL_TESTER))
         return TimeCurrent();
      return TimeTradeServer();
   }

   long ServerNowMilliseconds()
   {
      MqlTick quote={};
      SymbolInfoTick(_Symbol,quote);
      long clock_msc=(long)ServerNow()*1000;
      return MathMax(clock_msc,quote.time_msc);
   }

   bool IsOwnPosition()
   {
      return PositionGetString(POSITION_SYMBOL)==_Symbol &&
             (ulong)PositionGetInteger(POSITION_MAGIC)==InpMagicNumber &&
             PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
   }

   bool IsOwnOrder()
   {
      return OrderGetString(ORDER_SYMBOL)==_Symbol &&
             (ulong)OrderGetInteger(ORDER_MAGIC)==InpMagicNumber;
   }

   int OwnPositionCount()
   {
      int count=0;
      for(int i=PositionsTotal()-1;i>=0;i--)
         if(PositionGetTicket(i)>0 && IsOwnPosition())
            count++;
      return count;
   }

   int OwnOrderCount()
   {
      int count=0;
      for(int i=OrdersTotal()-1;i>=0;i--)
         if(OrderGetTicket(i)>0 && IsOwnOrder())
            count++;
      return count;
   }

   bool HasForeignNettingExposure()
   {
      if(!m_netting)
         return false;
      for(int i=PositionsTotal()-1;i>=0;i--)
      {
         if(PositionGetTicket(i)>0 &&
            PositionGetString(POSITION_SYMBOL)==_Symbol &&
            (ulong)PositionGetInteger(POSITION_MAGIC)!=InpMagicNumber)
            return true;
      }
      for(int i=OrdersTotal()-1;i>=0;i--)
      {
         if(OrderGetTicket(i)>0 && OrderGetString(ORDER_SYMBOL)==_Symbol &&
            (ulong)OrderGetInteger(ORDER_MAGIC)!=InpMagicNumber)
            return true;
      }
      return false;
   }

   bool CancelOwnOrders()
   {
      bool ok=true;
      for(int i=OrdersTotal()-1;i>=0;i--)
      {
         ulong ticket=OrderGetTicket(i);
         if(ticket==0 || !IsOwnOrder())
            continue;
         bool sent=m_trade.OrderDelete(ticket);
         uint code=m_trade.ResultRetcode();
         if(!sent || code!=TRADE_RETCODE_DONE)
         {
            PrintFormat("[QRT] Cancel %I64u failed: %u %s",
                        ticket,code,m_trade.ResultRetcodeDescription());
            ok=false;
         }
      }
      // Reconcile after a cancellation/fill race; never blindly replace.
      return ok && OwnOrderCount()==0;
   }

   double RoundTick(const double value,const double tick_size)
   {
      return NormalizeDouble(MathRound(value/tick_size)*tick_size,_Digits);
   }

   bool FixedVolumeValid()
   {
      double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
      double maximum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
      double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
      if(step<=0 || minimum<=0 || maximum<minimum)
         return false;
      double units=FIXED_LOTS/step;
      return FIXED_LOTS>=minimum-1e-9 && FIXED_LOTS<=maximum+1e-9 &&
             MathAbs(units-MathRound(units))<1e-7;
   }

   void RecoverLastExit()
   {
      datetime now=ServerNow();
      if(!HistorySelect(now-86400,now))
         return;
      for(int i=HistoryDealsTotal()-1;i>=0;i--)
      {
         ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0 || HistoryDealGetString(ticket,DEAL_SYMBOL)!=_Symbol ||
            (ulong)HistoryDealGetInteger(ticket,DEAL_MAGIC)!=InpMagicNumber)
            continue;
         ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY);
         if(entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_OUT_BY)
         {
            m_last_exit=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
            break;
         }
      }
   }

   bool ExpirationForBar(const datetime bar,ENUM_ORDER_TYPE_TIME &kind,datetime &expiry)
   {
      long allowed=SymbolInfoInteger(_Symbol,SYMBOL_EXPIRATION_MODE);
      if((allowed & SYMBOL_EXPIRATION_SPECIFIED)!=0)
      {
         kind=ORDER_TIME_SPECIFIED;
         expiry=bar+PeriodSeconds(PERIOD_M5);
         return expiry>ServerNow();
      }
      if((allowed & SYMBOL_EXPIRATION_GTC)!=0)
      {
         kind=ORDER_TIME_GTC;
         expiry=0;
         return true;
      }
      Print("[QRT] Symbol lacks specified/GTC expiration; signal skipped.");
      return false;
   }

   void PrepareSignal()
   {
      if(!CancelOwnOrders() || OwnPositionCount()>0 || HasForeignNettingExposure())
         return;
      // A close at a bar boundary must not cause immediate re-entry.
      if(m_last_exit>=m_last_bar)
         return;
      if(!FixedVolumeValid())
      {
         Print("[QRT] 0.10 lots incompatible with symbol; volume not changed.");
         return;
      }
      long mode=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE);
      long order_modes=SymbolInfoInteger(_Symbol,SYMBOL_ORDER_MODE);
      if((mode!=SYMBOL_TRADE_MODE_FULL && mode!=SYMBOL_TRADE_MODE_LONGONLY) ||
         (order_modes & SYMBOL_ORDER_STOP)==0 ||
         (order_modes & SYMBOL_ORDER_SL)==0 || (order_modes & SYMBOL_ORDER_TP)==0)
      {
         Print("[QRT] Symbol does not allow long stop orders with SL/TP.");
         return;
      }
      MqlRates bars[];
      double atr[];
      if(CopyRates(_Symbol,PERIOD_M5,1,LOOKBACK_BARS,bars)!=LOOKBACK_BARS ||
         CopyBuffer(m_atr,0,1,1,atr)!=1 || !MathIsValidNumber(atr[0]) || atr[0]<=0)
      {
         Print("[QRT] Closed M5/D1 data unavailable; signal skipped.");
         return;
      }
      double high=bars[0].high;
      for(int i=1;i<LOOKBACK_BARS;i++)
         high=MathMax(high,bars[i].high);
      double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
      if(tick_size<=0 || high<=0)
         return;
      double entry=NormalizeDouble(MathCeil(high/tick_size-1e-9)*tick_size,_Digits);
      double sl=RoundTick(entry-SL_ATR_MULTIPLIER*atr[0],tick_size);
      double tp=RoundTick(entry+TP_ATR_MULTIPLIER*atr[0],tick_size);
      MqlTick quote={};
      if(!SymbolInfoTick(_Symbol,quote) || quote.ask<=0)
         return;
      double min_distance=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point;
      if(entry<=quote.ask || entry-quote.ask+1e-9<min_distance ||
         sl<=0 || sl>=entry || tp<=entry ||
         entry-sl+1e-9<min_distance || tp-entry+1e-9<min_distance)
      {
         Print("[QRT] Breakout already reached or stops too close; signal skipped.");
         return;
      }
      ENUM_ORDER_TYPE_TIME time_kind=ORDER_TIME_GTC;
      datetime expiry=0;
      if(!ExpirationForBar(m_last_bar,time_kind,expiry))
         return;
      MqlTradeRequest request={};
      MqlTradeCheckResult check={};
      request.action=TRADE_ACTION_PENDING;
      request.magic=InpMagicNumber;
      request.symbol=_Symbol;
      request.volume=FIXED_LOTS;
      request.price=entry;
      request.sl=sl;
      request.tp=tp;
      request.type=ORDER_TYPE_BUY_STOP;
      request.type_filling=ORDER_FILLING_RETURN;
      request.type_time=time_kind;
      request.expiration=expiry;
      request.comment="QRT Breakout3 M5";
      if(!OrderCheck(request,check))
      {
         PrintFormat("[QRT] OrderCheck rejected: %u %s",check.retcode,check.comment);
         return;
      }
      // Refresh exposure after preflight; no accumulation of pending orders.
      if(OwnPositionCount()>0 || OwnOrderCount()>0 || HasForeignNettingExposure())
         return;
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
      bool sent=m_trade.BuyStop(FIXED_LOTS,entry,_Symbol,sl,tp,time_kind,expiry,request.comment);
      uint code=m_trade.ResultRetcode();
      if(!sent || (code!=TRADE_RETCODE_PLACED && code!=TRADE_RETCODE_DONE))
         PrintFormat("[QRT] BuyStop failed: %u %s",code,m_trade.ResultRetcodeDescription());
      else
         PrintFormat("[QRT] BuyStop %I64u %s 0.10: entry=%.*f SL=%.*f TP=%.*f ATR_D1=%.*f",
                     m_trade.ResultOrder(),_Symbol,_Digits,entry,_Digits,sl,_Digits,tp,_Digits,atr[0]);
   }

public:
   CBreakout3():m_atr(INVALID_HANDLE),m_last_bar(0),m_last_exit(0),
                m_test_start(0),m_last_close_attempt(0),m_enabled(false),m_netting(false) {}

   bool IsNewBar()
   {
      datetime bar=iTime(_Symbol,PERIOD_M5,0);
      if(bar<=0 || bar==m_last_bar)
         return false;
      if(m_last_bar==0)
      {
         m_last_bar=bar;
         return false;
      }
      m_last_bar=bar;
      return true;
   }

   int Init()
   {
      if(_Period!=PERIOD_M5 || InpMagicNumber==0)
      {
         Print("[QRT] Use an M5 chart and a nonzero exclusive Magic Number.");
         return INIT_PARAMETERS_INCORRECT;
      }
      m_enabled=(bool)MQLInfoInteger(MQL_TESTER) || InPenableTrading;
      m_netting=(ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING;
      m_trade.SetExpertMagicNumber(InpMagicNumber);
      m_trade.SetAsyncMode(false);
      m_trade.SetMarginMode();
      m_atr=iATR(_Symbol,PERIOD_D1,ATR_PERIOD);
      if(m_atr==INVALID_HANDLE)
         return INIT_FAILED;
      m_last_bar=iTime(_Symbol,PERIOD_M5,0);
      m_test_start=TimeCurrent();
      RecoverLastExit();
      if(!EventSetTimer(1))
      {
         Print("[QRT] Failed to initialize the one-second timer.");
         IndicatorRelease(m_atr);
         m_atr=INVALID_HANDLE;
         return INIT_FAILED;
      }
      PrintFormat("[QRT] STRAT-20261008-BREAKOUT3_LONG-M5-v1.0: %s M5; volume=0.10; enabled=%s",
                  _Symbol,m_enabled ? "true" : "false");
      return INIT_SUCCEEDED;
   }

   void Deinit()
   {
      EventKillTimer();
      if(m_enabled)
         CancelOwnOrders();
      if(m_atr!=INVALID_HANDLE)
         IndicatorRelease(m_atr);
      m_atr=INVALID_HANDLE;
   }

   void ManagePosition()
   {
      if(!m_enabled)
         return;
      int own_count=OwnPositionCount();
      if(own_count==0)
         return;
      // Cancel any remaining unfilled volume after a partial fill.
      if(OwnOrderCount()>0)
         CancelOwnOrders(); // A cancel failure must not block a due time-stop.
      long now_msc=ServerNowMilliseconds();
      datetime now=ServerNow();
      if(now==m_last_close_attempt)
         return;
      for(int i=PositionsTotal()-1;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !IsOwnPosition())
            continue;
         long opened=PositionGetInteger(POSITION_TIME_MSC);
         if(opened<=0 || now_msc-opened<HOLD_MILLISECONDS)
            continue;
         m_last_close_attempt=now;
         if(!m_trade.SetTypeFillingBySymbol(_Symbol))
         {
            Print("[QRT] Cannot select a valid close filling policy; retry pending.");
            continue;
         }
         bool sent=m_trade.PositionClose(ticket);
         uint code=m_trade.ResultRetcode();
         if(!sent || (code!=TRADE_RETCODE_DONE && code!=TRADE_RETCODE_DONE_PARTIAL))
            PrintFormat("[QRT] Time-stop close %I64u failed: %u %s",
                        ticket,code,m_trade.ResultRetcodeDescription());
         else
         {
            m_last_exit=now;
            PrintFormat("[QRT] Time-stop close %I64u: elapsed_ms=%I64d retcode=%u",
                        ticket,now_msc-opened,code);
         }
      }
   }

   void Tick()
   {
      ManagePosition();
      if(!IsNewBar() || !m_enabled)
         return;
      PrepareSignal();
   }

   void Transaction(const MqlTradeTransaction &transaction)
   {
      if(transaction.type!=TRADE_TRANSACTION_DEAL_ADD || transaction.deal==0 ||
         !HistoryDealSelect(transaction.deal))
         return;
      ulong deal=transaction.deal;
      if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol ||
         (ulong)HistoryDealGetInteger(deal,DEAL_MAGIC)!=InpMagicNumber)
         return;
      ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
      if(entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_OUT_BY)
         m_last_exit=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
      if(entry==DEAL_ENTRY_IN && m_enabled)
         CancelOwnOrders();
   }

   double TesterResult()
   {
      datetime ended=TimeCurrent();
      if(!HistorySelect(0,ended))
         return 0;
      SPositionReturn positions[];
      int count=0;
      for(int i=0;i<HistoryDealsTotal();i++)
      {
         ulong deal=HistoryDealGetTicket(i);
         if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol ||
            (ulong)HistoryDealGetInteger(deal,DEAL_MAGIC)!=InpMagicNumber)
            continue;
         ENUM_DEAL_TYPE type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(deal,DEAL_TYPE);
         if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL)
            continue;
         ulong id=(ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID);
         int index=-1;
         for(int j=0;j<count;j++)
            if(positions[j].id==id)
            {
               index=j;
               break;
            }
         if(index<0)
         {
            index=count++;
            ArrayResize(positions,count);
            ZeroMemory(positions[index]);
            positions[index].id=id;
         }
         double volume=HistoryDealGetDouble(deal,DEAL_VOLUME);
         double price=HistoryDealGetDouble(deal,DEAL_PRICE);
         long time_msc=HistoryDealGetInteger(deal,DEAL_TIME_MSC);
         ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
         if(entry==DEAL_ENTRY_IN && type==DEAL_TYPE_BUY)
         {
            positions[index].entry_volume+=volume;
            positions[index].entry_notional+=volume*price;
            if(positions[index].entry_msc==0 || time_msc<positions[index].entry_msc)
               positions[index].entry_msc=time_msc;
         }
         else if((entry==DEAL_ENTRY_OUT || entry==DEAL_ENTRY_OUT_BY) && type==DEAL_TYPE_SELL)
         {
            positions[index].exit_volume+=volume;
            positions[index].exit_notional+=volume*price;
            positions[index].exit_msc=MathMax(positions[index].exit_msc,time_msc);
         }
         positions[index].money_net+=HistoryDealGetDouble(deal,DEAL_PROFIT)+
                                     HistoryDealGetDouble(deal,DEAL_COMMISSION)+
                                     HistoryDealGetDouble(deal,DEAL_SWAP)+
                                     HistoryDealGetDouble(deal,DEAL_FEE);
      }
      long first_day=(long)m_test_start/86400;
      long last_day=(long)ended/86400;
      int days=(int)(last_day-first_day+1);
      if(days<=0)
         return 0;
      double daily[];
      ArrayResize(daily,days);
      ArrayInitialize(daily,0.0);
      double sum_r=0,gains=0,losses=0,money=0,total_hold=0;
      int closed=0,wins=0;
      for(int i=0;i<count;i++)
      {
         if(positions[i].entry_volume<=0 || positions[i].exit_volume<=0 ||
            MathAbs(positions[i].exit_volume-positions[i].entry_volume)>1e-8)
            continue;
         double price_in=positions[i].entry_notional/positions[i].entry_volume;
         double price_out=positions[i].exit_notional/positions[i].exit_volume;
         if(price_in<=0 || positions[i].exit_msc<=0)
            continue;
         double r=100.0*(price_out-price_in)/price_in;
         sum_r+=r;
         if(r>0) gains+=r;
         if(r<0) losses-=r;
         money+=positions[i].money_net;
         if(positions[i].money_net>0) wins++;
         total_hold+=(double)(positions[i].exit_msc-positions[i].entry_msc)/1000.0;
         closed++;
         int day=(int)(positions[i].exit_msc/86400000-first_day);
         if(day>=0 && day<days)
            daily[day]+=r;
      }
      double mean=0,m2=0;
      for(int i=0;i<days;i++)
      {
         double delta=daily[i]-mean;
         mean+=delta/(i+1);
         m2+=delta*(daily[i]-mean);
      }
      double sharpe=0;
      if(days>1 && m2>0)
         sharpe=mean/MathSqrt(m2/(days-1))*MathSqrt(365.0);
      else
         Print("[QRT] Daily price-return Sharpe undefined; tester criterion=0.");
      double pf=0;
      if(losses>0)
         pf=gains/losses;
      else
         Print("[QRT] Price-return profit factor undefined without losses; tester criterion=0.");
      PrintFormat("[QRT] TESTER closed=%d net_money=%.2f wins=%d sum_price_return_pct=%.8f PF_price=%.8f Sharpe_daily_price=%.8f mean_hold_seconds=%.3f",
                  closed,money,wins,sum_r,pf,sharpe,closed>0 ? total_hold/closed : 0.0);
      switch(InTesterCriterion)
      {
         case CRITERION_SHARPE_PCT: return sharpe;
         case CRITERION_PROFIT_FACTOR_PCT: return pf;
         default: return sum_r;
      }
   }
};

CBreakout3 strategy;
int OnInit() { return strategy.Init(); }
void OnDeinit(const int reason) { strategy.Deinit(); }
void OnTick() { strategy.Tick(); }
void OnTimer() { strategy.ManagePosition(); }
void OnTradeTransaction(const MqlTradeTransaction &transaction,
                        const MqlTradeRequest &request,const MqlTradeResult &result)
{
   strategy.Transaction(transaction);
}
double OnTester() { return strategy.TesterResult(); }
