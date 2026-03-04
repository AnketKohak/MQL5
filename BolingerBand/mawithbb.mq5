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
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;
input int maperiod = 200;


input long Magic = 3;


bool tralingStopLoss = false;
int handleBB;
int handleMA;
input int Slpoint = 100;
input int BarsN = 5;
int barsTotal;
ulong orderTicket = 0;
CTrade trade;
bool isBuyOn = true;
bool isSellOn = true;
string Commentary = "bb";

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(Magic);
   handleBB = iBands(_Symbol, Timeframe, 20, 0, 2.0, PRICE_CLOSE);
   handleMA = iMA(_Symbol, Timeframe, maperiod, 1, MODE_EMA, PRICE_CLOSE);
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
 if(barsTotal == bars)
  return;
   barsTotal = bars;
   double bbHigh[];
   double bbMid[];
   double bbLow[];
   double ma[];
   CopyBuffer(handleBB, 0, 0, 1, bbMid);
   CopyBuffer(handleBB, 1, 0, 1, bbHigh);
   CopyBuffer(handleBB, 2, 0, 1, bbLow);
   CopyBuffer(handleMA, 0, 0,2, ma);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool buySignal = bbLow[0] > ask;
   bool sellSignal = bbHigh[0] < bid;
   Comment(
      "High: ", bbHigh[0], "\n",
      "Mid:  ", bbMid[0],  "\n",
      "Low:  ", bbLow[0],  "\n",
      "MA0:   ", ma[0] ,   "\n",
      "MA1:   ", ma[1]
   );
   if(!CheckIfOpenOrderByMagicNB(Magic))
     {
      if(buySignal && ask > ma[0])
        {
         excuteBuy();
         isBuyOn = false;
         isSellOn = true;
        }
      if(sellSignal && ask < ma[0])
        {
         excuteSell();
         isBuyOn = true;
         isSellOn = false;
        }
     }
   else
      if(!tralingStopLoss)
        {
         if(PositionSelect(_Symbol))
           {
            if(PositionGetInteger(POSITION_MAGIC) == Magic)
              {
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && (sellSignal))
                  trade.PositionClose(_Symbol);
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && (buySignal))
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
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl = bid - Slpoint * _Point;
   trade.Buy(Lots, _Symbol, ask, 0, 0);
   orderTicket = trade.ResultOrder();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void excuteSell()
  {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = ask + Slpoint * _Point;
   trade.Sell(Lots, _Symbol, bid, 0, 0);
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
double findHigh(int BarsN)
  {
   double highestHigh = 0;
   for(int i = 0; i < 200; i++)
     {
      double high = iHigh(_Symbol, Timeframe, i);
      if(i > BarsN && iHighest(_Symbol, Timeframe, MODE_HIGH, BarsN * 2 + 1, i - BarsN) == i)
        {
         if(high > highestHigh)
           {
            return high;
           }
        }
      highestHigh = MathMax(high, highestHigh);
     }
   return -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double findLow(int BarsN)
  {
   double lowestLow = DBL_MAX;
   for(int i = 0; i < 200; i++)
     {
      double low = iLow(_Symbol, Timeframe, i);
      if(i > BarsN && iLowest(_Symbol, Timeframe, MODE_LOW, BarsN * 2 + 1, i - BarsN) == i)
        {
         if(low < lowestLow)
           {
            return low;
           }
        }
      lowestLow = MathMin(low, lowestLow);
     }
   return -1;
  }
//+-
//+------------------------------------------------------------------+
