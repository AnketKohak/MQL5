//+------------------------------------------------------------------+
//|                London Breakout Retest EA (15M)                  |
//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>



CTrade trade;
CPositionInfo pos;
COrderInfo ord;


//================ INPUTS =================//
input double RiskPercent      = 1.0;     // Risk per trade (%)
input double RR               = 2.0;     // Risk Reward ratio
input int    AsianStartHour   = 0;       // Asian session start (server time)
input int    AsianEndHour     = 6;       // Asian session end
input int    LondonStartHour  = 7;       // London start
input int    LondonEndHour    = 12;      // London end
input int    MaxSpreadPoints  = 20;      // Max allowed spread
input ulong  Magic            = 123456;

//================ GLOBALS =================//
double AsianHigh = 0;
double AsianLow  = 0;
datetime LastTradeDay = 0;

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(Magic);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   TrailStop();
   if(_Period != PERIOD_M15)
      return;
   if(!IsNewBar())
      return;
   if(!SpreadOK())
      return;
   datetime currentDay = iTime(_Symbol, PERIOD_D1, 0);
   if(currentDay == LastTradeDay)
      return; // Only one trade per day
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   int hour = tm.hour;
   if(hour >= AsianStartHour && hour < AsianEndHour)
      CalculateAsianRange();
   if(hour >= LondonStartHour && hour < LondonEndHour)
      CheckBreakout();
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   static datetime lastBar = 0;
   datetime currentBar = iTime(_Symbol, PERIOD_M15, 0);
   if(lastBar != currentBar)
     {
      lastBar = currentBar;
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SpreadOK()
  {
   double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) -
                    SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
   return spread <= MaxSpreadPoints;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateAsianRange()
  {
   AsianHigh = -DBL_MAX;
   AsianLow  = DBL_MAX;
   for(int i = 1; i <= 24; i++) // 6 hours * 4 candles per hour
     {
      datetime t = iTime(_Symbol, PERIOD_M15, i);
      MqlDateTime tm2;
      TimeToStruct(t, tm2);
      int h = tm2.hour;
      if(h >= AsianStartHour && h < AsianEndHour)
        {
         double high = iHigh(_Symbol, PERIOD_M15, i);
         double low  = iLow(_Symbol, PERIOD_M15, i);
         if(high > AsianHigh)
            AsianHigh = high;
         if(low < AsianLow)
            AsianLow = low;
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckBreakout()
  {
   double close1 = iClose(_Symbol, PERIOD_M15, 1);
   double high1  = iHigh(_Symbol, PERIOD_M15, 1);
   double low1   = iLow(_Symbol, PERIOD_M15, 1);
// BUY breakout + pullback
   if(close1 > AsianHigh)
     {
      if(low1 <= AsianHigh) // retest happened
        {
         ExecuteTrade(ORDER_TYPE_BUY);
         return;
        }
     }
// SELL breakout + pullback
   if(close1 < AsianLow)
     {
      if(high1 >= AsianLow)
        {
         ExecuteTrade(ORDER_TYPE_SELL);
         return;
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_ORDER_TYPE type)
  {
   double entry, sl, tp;
   double lot = CalculateLotSize();
   if(type == ORDER_TYPE_BUY)
     {
      entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      sl = entry - 300 * _Point;
      tp = entry + 300 * _Point;;
      trade.Buy(lot, _Symbol, entry, sl, 0);
     }
   else
     {
      entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      sl = entry + 300 * _Point;
      tp = entry - 300 * _Point;;
      trade.Sell(lot, _Symbol, entry, sl, 0);
     }
   LastTradeDay = iTime(_Symbol, PERIOD_D1, 0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailStop()
  {
   double sl = 0;
   double tp = 0;
   double profit = 0;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i))
        {
         ulong ticket = pos.Ticket();
         if(pos.Magic() == Magic && pos.Symbol() == _Symbol)
           {
            if(pos.PositionType() == POSITION_TYPE_BUY)
              {
               profit = pos.Profit();
               tp = pos.TakeProfit();
               double openPrice = pos.PriceOpen();
               double currntPoint = bid - openPrice;
               if(profit > 3.00)
                 {
                  sl = bid - (100 * _Point);
                  if(sl > pos.StopLoss() && sl != 0)
                    {
                     trade.PositionModify(ticket, sl, 0);
                    }
                 }
              }
            else
               if(pos.PositionType() == POSITION_TYPE_SELL)
                 {
                  tp = pos.TakeProfit();
                  profit = pos.Profit();
                  sl = ask + (100 * _Point);
                  double openPrice = pos.PriceOpen();
                  double currntPoint = bid - openPrice;
                  if(profit > 3.00)
                    {
                     if(sl < pos.StopLoss() && sl != 0)
                       {
                        trade.PositionModify(ticket, sl, 0);
                       }
                    }
                 }
           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateLotSize()
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * RiskPercent / 100.0;
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double slPoints = MathAbs(AsianHigh - AsianLow) / _Point;
   double lot = riskAmount / (slPoints * tickValue / tickSize);
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lot = MathMax(minLot, MathMin(maxLot, lot));
   lot = NormalizeDouble(lot / step, 0) * step;
   return lot;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
