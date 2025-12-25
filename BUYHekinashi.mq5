//+------------------------------------------------------------------+
//|                                                         test.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.01"
#include <Trade/Trade.mqh>

//--- Global Variables
int handleHeikenAshi;
int barsTotal;
CTrade trade;
ulong posTicket = 0;
input double RiskPercent = 0.5;
input int SlPoints = 200;
double buYPRICESE;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   barsTotal = iBars(_Symbol, PERIOD_CURRENT);
   handleHeikenAshi = iCustom(_Symbol, PERIOD_CURRENT, "Examples//Heiken_Ashi.ex5");

   if(handleHeikenAshi == INVALID_HANDLE)
     {
      Print("Failed to load Heiken Ashi indicator!");
      return(INIT_FAILED);
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Alert("EA stopped.");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int bars = iBars(_Symbol, PERIOD_CURRENT);

// Only check once per new bar
   if(barsTotal == bars)
      return;
   barsTotal = bars;

//--- Get Heiken Ashi values
   double haOpen[], haClose[];
   ArraySetAsSeries(haOpen, true);
   ArraySetAsSeries(haClose, true);

   if(CopyBuffer(handleHeikenAshi, 0, 1, 1, haOpen) <= 0 ||
      CopyBuffer(handleHeikenAshi, 3, 1, 1, haClose) <= 0)
      return;

//--- BUY CONDITION
   if(haOpen[0] < haClose[0])  // Bullish Heiken Ashi candle
     {
      // If already have BUY position, do nothing
      if(posTicket > 0 && PositionSelectByTicket(posTicket))
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           {
            Comment("Already in BUY position. No new entry.");
            return;
           }
        }

      // If old position was closed or none, open new BUY
      double entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      entry = NormalizeDouble(entry, _Digits);
      double sl = entry - SlPoints * _Point;
      //sl = NormalizeDouble(sl, _Digits);

      if(trade.Buy(0.01, _Symbol, entry, 0))
        {
         buYPRICESE = entry;
         posTicket = trade.ResultOrder();
         Print("Opened BUY at ", entry);
        }
     }

//--- CLOSE BUY CONDITION (optional)
   else
      if(haClose[0] < haOpen[0])  // Bearish Heiken Ashi candle
        {
         // Close existing BUY trade if any
         if(posTicket > 0 && PositionSelectByTicket(posTicket))
           {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
              {
               if(trade.PositionClose(posTicket))
                 {
                  Print("Closed BUY position due to bearish HA candle.");
                  posTicket = 0;
                 }
              }
           }
        }

   Comment("\nHA Open: ", DoubleToString(haOpen[0], _Digits),
           "\nHA Close: ", DoubleToString(haClose[0], _Digits),
           "\nPosition Ticket: ", posTicket);
  }
//+------------------------------------------------------------------+
