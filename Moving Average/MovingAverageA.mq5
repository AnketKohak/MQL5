//+------------------------------------------------------------------+
//|                                               MovingAverageA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

// This is simple Stragy Buy and Exit on crossover
//18/12/2025




#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <trade/trade.mqh>

input double Lots = 0.01;

input int MAFast = 20;
input int MASlow = 50;
input int MATrend = 200;

long Magic = 6;
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;

int handleMAFast;
int handleMASlow;
int handleMATrend;
ulong orderTicket = 0;


int barsTotal;
CTrade trade;
string Commentary = "MA Crossover";
int hFast, hSlow, hTrend;
datetime lastBarTime = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(Magic);
   handleMAFast = iMA(_Symbol, Timeframe, MAFast, 0, MODE_EMA, PRICE_CLOSE);
   handleMASlow = iMA(_Symbol, Timeframe, MASlow, 0, MODE_EMA, PRICE_CLOSE);
   handleMATrend = iMA(_Symbol, Timeframe, MATrend, 0, MODE_EMA, PRICE_CLOSE);
   barsTotal = iBars(_Symbol, Timeframe);
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
   datetime currentBar = iTime(_Symbol, Timeframe, 0);
   if(currentBar == lastBarTime)
      return;   // NEW BAR FILTER
   lastBarTime = currentBar;
   double maFast[];
   double maSlow[];
   double maTrend[];
   CopyBuffer(handleMAFast, 0, 0, 3, maFast);
   CopyBuffer(handleMASlow, 0, 0, 3, maSlow);
   CopyBuffer(handleMATrend, 0, 0, 3, maTrend);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool buySignal = maFast[2] < maSlow[2]  && maFast[1] > maSlow[1];
   bool sellSignal = maFast[2] > maSlow[2] && maFast[1] < maSlow[1];
   if(!CheckIfOpenOrderByMagicNB(Magic))
     {
      if(buySignal && maTrend[1] < ask)
        {
         excuteBuy();
        }
      else
         if(sellSignal && maTrend[1] > bid)
           {
            excuteSell();
           }
     }
   else
     {
      if(PositionSelectByTicket(orderTicket))
        {
         if(PositionGetInteger(POSITION_MAGIC) == Magic)
           {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
              {
               if(sellSignal)
                 {
                  trade.PositionClose(orderTicket);
                 }
              }
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
              {
               if(buySignal)
                 {
                  trade.PositionClose(orderTicket);
                 }
              }
           }
        }
     }
  }
//---

//+------------------------------------------------------------------+


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
//+---------
//+------------------------------------------------------------------+
