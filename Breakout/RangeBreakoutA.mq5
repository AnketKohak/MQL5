//+------------------------------------------------------------------+
//|                                               RangeBreakoutA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com

//This stragy is range stragy
//this need to use on 15 minutes
//this is speacial for only USDJPY
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://youtu.be/1Y6j8_9Hzgk?si=lTmLFU_6M878WyZS"
#property version   "1.00"
#include <Trade/Trade.mqh>

input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;
input int RangeStartHour = 3;
input int RangeStartMin = 0;
input int RangeEndHour = 6;
input int RangeEndMin = 0;
input int TradingEndHour = 18;
input int TradingEndMin = 0;
input double Lots = 0.1;
datetime rangeTimeStart;
datetime rangeTimeEnd;
datetime tradingTimeEnd;

double rangeHigh;
double rangeLow;
input long MagicNB = 7;

bool isTrade;
CTrade trade;


int OnInit()
  {
//---
   trade.SetExpertMagicNumber(MagicNB);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   calcTimes();
   
   calcRange();

   if(TimeCurrent() > rangeTimeEnd && TimeCurrent() < tradingTimeEnd)
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      if(!isTrade)
        {
         if(rangeHigh > 0 && rangeLow > 0)
           {
            if(bid > rangeHigh)
              {
               trade.Buy(Lots);
               isTrade = true;
              }
            else
               if(bid < rangeLow)
                 {
                  trade.Sell(Lots);
                  isTrade = true;
                 }
           }
        }
     }
   else
      if(TimeCurrent() >= tradingTimeEnd)
        {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
           {
            CPositionInfo pos;
            if(pos.SelectByIndex(i))
              {
               if(pos.Magic() == MagicNB)
                 {
                  trade.PositionClose(pos.Ticket());
                 }
              }
           }
        }
  }
//+------------------------------------------------------------------+
void calcTimes()
  {
   MqlDateTime dt;
   TimeCurrent(dt);
   dt.sec = 0;

   dt.hour = RangeStartHour;
   dt.min = RangeStartMin;
   Print("dt.hour : ", dt.hour, " dt.min : ", dt.min);
   if(rangeTimeStart != StructToTime(dt))
     {
      isTrade = false;
      rangeHigh = 0;
      rangeLow = 0;
     }

   rangeTimeStart = StructToTime(dt);
   //Print("rangetimestart : ", rangeTimeStart);

   dt.hour = RangeEndHour;
   dt.min = RangeEndMin;

   rangeTimeEnd = StructToTime(dt);
   //Print("rangeTimeEnd : ", rangeTimeEnd);


   dt.hour = TradingEndHour;
   dt.min = TradingEndMin;
   tradingTimeEnd = StructToTime(dt);
   //Print("tradingTimeEnd  : ", tradingTimeEnd);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calcRange()
  {
   double highs[];
   CopyHigh(_Symbol, Timeframe, rangeTimeStart, rangeTimeEnd, highs);

   double lows[];
   CopyLow(_Symbol, Timeframe, rangeTimeStart, rangeTimeEnd, lows);
   if(ArraySize(highs) < 1 || ArraySize(lows) < 1)
      return;
   int indexHighest = ArrayMaximum(highs);
   int indexLowest = ArrayMinimum(lows);
   Print("highs: ", indexHighest);
//
   rangeHigh = highs[indexHighest];
   rangeLow = lows[indexLowest];


   //string objName = "Range" + TimeToString(rangeTimeStart, TIME_DATE);
   //if(ObjectFind(0, objName) < 0)
   //  {
   //   ObjectCreate(0, objName, OBJ_RECTANGLE, 0, rangeTimeStart, rangeLow, rangeTimeEnd, rangeHigh);
   //   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   //   ObjectSetInteger(0, objName, OBJPROP_COLOR, clrYellow);
   //  }
   //else
   //  {
   //   ObjectSetDouble(0, objName, OBJPROP_PRICE, 0, rangeLow);
   //   ObjectSetDouble(0, objName, OBJPROP_PRICE, 1, rangeHigh);
   //  }

  }
//+------------------------------------------------------------------+
