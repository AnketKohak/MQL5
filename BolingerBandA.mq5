//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <trade/trade.mqh>

input double Lots = 0.1;

input string Commentary = "bb";
input long Magic = 3;
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;

bool tralingStopLoss = false;
int handleBB;
int barsTotal;
ulong orderTicket = 0;
CTrade trade;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(Magic);
   handleBB = iBands(_Symbol, Timeframe, 20, 0, 2.0, PRICE_CLOSE);
   barsTotal = iBars(_Symbol, Timeframe);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   int bars = iBars(_Symbol, Timeframe);
// if(barsTotal == bars)
//  return;
   barsTotal = bars;
   double bbHigh[];
   double bbMid[];
   double bbLow[];
   CopyBuffer(handleBB, 0, 0, 1, bbMid);
   CopyBuffer(handleBB, 1, 0, 1, bbHigh);
   CopyBuffer(handleBB, 2, 0, 1, bbLow);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool buySignal = bbLow[0] > ask;
   bool sellSignal = bbHigh[0] < bid;
   Comment(
      "High: ", bbHigh[0], "\n",
      "Mid:  ", bbMid[0],  "\n",
      "Low:  ", bbLow[0]
   );
   if(!CheckIfOpenOrderByMagicNB(Magic))
     {
      if(buySignal)
         excuteBuy();
      if(sellSignal)
         excuteSell();
     }
   else
      if(!tralingStopLoss)
        {
         if(PositionSelect(_Symbol))
           {
            if(PositionGetInteger(POSITION_MAGIC) == Magic)
              {
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && sellSignal)
                  trade.PositionClose(_Symbol);
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && buySignal)
                  trade.PositionClose(_Symbol);
              }
           }
        }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void excuteBuy()
  {
   trade.Buy(Lots, _Symbol);
   orderTicket = trade.ResultOrder();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void excuteSell()
  {
   trade.Sell(Lots, _Symbol);
   orderTicket = trade.ResultOrder();
  }
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckIfOpenOrderByMagicNB(long magicNB)
  {
   if(PositionSelect(_Symbol))
     {
      if(PositionGetInteger(POSITION_MAGIC) == magicNB)
         return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
