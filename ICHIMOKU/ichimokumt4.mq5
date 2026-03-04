//+------------------------------------------------------------------+
//|                  Ichimoku 2Bans MR - MQL5 Version                |
//+------------------------------------------------------------------+
#property copyright "Converted to MQL5"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>

CTrade trade;

input double lotsize = 0.01;
input int    magicNB = 55555;
input double TakeProfit = 250;
input double StopLoss = 250;
//--- indicator handles
int ichimokuHandle;
int maHandle;

//--- buffers
double tenkan[], kijun[], chikou[];
double senkouA[], senkouB[];
double maBuffer[];

//+------------------------------------------------------------------+
int OnInit()
  {
   ichimokuHandle = iIchimoku(_Symbol, _Period, 9, 26, 52);
   maHandle       = iMA(_Symbol, _Period, 200, 0, MODE_SMA, PRICE_CLOSE);
   if(ichimokuHandle == INVALID_HANDLE || maHandle == INVALID_HANDLE)
     {
      Print("Indicator handle failed");
      return INIT_FAILED;
     }
   trade.SetExpertMagicNumber(magicNB);
   Print("Starting Strategy BB 2Bans MR (MQL5)");
   return INIT_SUCCEEDED;
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(ichimokuHandle);
   IndicatorRelease(maHandle);
   Print("Stopping Strategy");
  }
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!CopyBuffers())
      return;
   double Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
//--- trend logic (same as yours)
  
      bool uptrend =
   (tenkan[0] >= kijun[0]) &&
   (senkouA[26] > senkouB[26]) &&
   (Bid > senkouA[26]) &&
   (Bid > senkouB[26]) &&
   (kijun[0] > senkouA[26]) &&
   (chikou[0] > iClose(_Symbol, _Period, 26)) &&
   (tenkan[1] < tenkan[0]) &&
   (kijun[1] < kijun[0]);
  
      bool downtrend =
   (tenkan[0] <= kijun[0]) &&
   (senkouA[26] < senkouB[26]) &&
   (Bid < senkouA[26]) &&
   (Bid < senkouB[26]) &&
   (kijun[0] < senkouA[26]) &&   // FIXED HERE
    
   (tenkan[1] > tenkan[0]) &&
   (kijun[1] > kijun[0]);
//--- if no open position
   if(!PositionExists())
     {
      if(tenkan[1] < kijun[1] && tenkan[0] > kijun[0] && maBuffer[0] < Ask)
      //if(uptrend)
        {
         double sl = Ask - StopLoss * _Point;
         double tp = Ask + TakeProfit * _Point;
         trade.Buy(lotsize, _Symbol, Ask, sl, tp);
        }
      else
         if(tenkan[1] > kijun[1] && tenkan[0] < kijun[0] && maBuffer[0] > Bid)
         //if(downtrend)
           {
            double sl = Ask + StopLoss * _Point;
            double tp = Ask - TakeProfit * _Point;
            trade.Sell(lotsize, _Symbol, Bid, sl, tp);
           }
     }
   else
     {
      ManagePositions(uptrend, downtrend);
     }
  }
//+------------------------------------------------------------------+
bool CopyBuffers()
  {
   ArraySetAsSeries(tenkan, true);
   ArraySetAsSeries(kijun, true);
   ArraySetAsSeries(senkouA, true);
   ArraySetAsSeries(senkouB, true);
   ArraySetAsSeries(chikou, true);
   ArraySetAsSeries(maBuffer, true);
   if(CopyBuffer(ichimokuHandle, 0, 0, 100, tenkan) <= 0)
      return false;
   if(CopyBuffer(ichimokuHandle, 1, 0, 100, kijun) <= 0)
      return false;
   if(CopyBuffer(ichimokuHandle, 2, 0, 100, senkouA) <= 0)
      return false;
   if(CopyBuffer(ichimokuHandle, 3, 0, 100, senkouB) <= 0)
      return false;
   if(CopyBuffer(ichimokuHandle, 4, 0, 100, chikou) <= 0)
      return false;
   if(CopyBuffer(maHandle, 0, 0, 10, maBuffer) <= 0)
      return false;
   return true;
  }
//+------------------------------------------------------------------+
bool PositionExists()
  {
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(PositionGetTicket(i) > 0)
        {
         if(PositionGetInteger(POSITION_MAGIC) == magicNB &&
            PositionGetString(POSITION_SYMBOL) == _Symbol)
            return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
void ManagePositions(bool uptrend, bool downtrend)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         if(PositionGetInteger(POSITION_MAGIC) != magicNB)
            continue;
         long type = PositionGetInteger(POSITION_TYPE);
         if(type == POSITION_TYPE_BUY)
           {
            if(tenkan[0] < kijun[0])
               trade.PositionClose(ticket);
           }
         if(type == POSITION_TYPE_SELL)
           {
            if(tenkan[0] > kijun[0])
               trade.PositionClose(ticket);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
