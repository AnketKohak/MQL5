#property copyright "Copyright 2025"
#property version   "1.10"

#include <trade/trade.mqh>

input double Lots = 0.01;
input int MAFast = 20;
input int MASlow = 50;
input int MATrend = 200;
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;

long Magic = 6;
CTrade trade;

int hFast, hSlow, hTrend;
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(Magic);

   hFast  = iMA(_Symbol, Timeframe, MAFast, 0, MODE_EMA, PRICE_CLOSE);
   hSlow  = iMA(_Symbol, Timeframe, MASlow, 0, MODE_EMA, PRICE_CLOSE);
   hTrend = iMA(_Symbol, Timeframe, MATrend,0, MODE_EMA, PRICE_CLOSE);

   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentBar = iTime(_Symbol, Timeframe, 0);
   if(currentBar == lastBarTime) return;   // NEW BAR FILTER
   lastBarTime = currentBar;

   double fast[3], slow[3], trend[3], closePrice[3];

   ArraySetAsSeries(fast, true);
   ArraySetAsSeries(slow, true);
   ArraySetAsSeries(trend,true);
   ArraySetAsSeries(closePrice,true);

   CopyBuffer(hFast,  0, 0, 3, fast);
   CopyBuffer(hSlow,  0, 0, 3, slow);
   CopyBuffer(hTrend, 0, 0, 3, trend);
   CopyClose(_Symbol, Timeframe, 0, 3, closePrice);

   bool buySignal  = fast[2] < slow[2] && fast[1] > slow[1];
   bool sellSignal = fast[2] > slow[2] && fast[1] < slow[1];

   bool trendBuy  = closePrice[1] > trend[1];
   bool trendSell = closePrice[1] < trend[1];

   // ENTRY
   if(!PositionSelect(_Symbol))
   {
      if(buySignal)
         trade.Buy(Lots, _Symbol);

      else if(sellSignal)
         trade.Sell(Lots, _Symbol);
   }
   // EXIT
   else
   {
      long type = PositionGetInteger(POSITION_TYPE);

      if(type == POSITION_TYPE_BUY && sellSignal)
         trade.PositionClose(_Symbol);

      if(type == POSITION_TYPE_SELL && buySignal)
         trade.PositionClose(_Symbol);
   }
}
//+------------------------------------------------------------------+
