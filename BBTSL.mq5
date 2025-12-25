//+------------------------------------------------------------------+
//|                                      |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <trade/trade.mqh>

input double Lots = 0.01;

input string Commentary = "bbstl";
input long Magic = 4;
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;
input int StopLossPoint = 50;

bool tralingStopLoss = false;
int handleBB;
int handleMAFast;
int handleMASlow;
int handleATR;
int barsTotal;
CTrade trade;
ulong orderTicket = 0;
double stopLossPrice;
double takeProfitPrice;
double stopLossPriceOfPos;
bool isBuy = true;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(Magic);
   handleBB = iBands(_Symbol, Timeframe, 20, 0, 2.0, PRICE_CLOSE);
   handleMAFast = iMA(_Symbol, Timeframe, 50, 0, MODE_EMA, PRICE_CLOSE);
   handleMASlow = iMA(_Symbol, Timeframe, 200, 0, MODE_EMA, PRICE_CLOSE);
   handleATR = iATR(_Symbol, Timeframe, 14);
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
   double maSlow[];
   double maFast[];
   double atr[];
   CopyBuffer(handleBB, 0, 0, 2, bbMid);
   CopyBuffer(handleBB, 1, 0, 2, bbHigh);
   CopyBuffer(handleBB, 2, 0, 2, bbLow);
   CopyBuffer(handleMAFast, 0, 0, 1, maFast);
   CopyBuffer(handleMASlow, 0, 0, 1, maSlow);
   CopyBuffer(handleATR, 0, 0, 1, atr);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool buySignal = bbLow[0] > ask;
   bool sellSignal = bbHigh[0] < bid;
   Comment(
      "High: ", bbHigh[0], "\n",
      "Mid:  ", bbMid[0],  "\n",
      "Low:  ", bbLow[0],  "\n",
      "maFast : ", maFast[0], "\n",
      "maSlow : ", maSlow[0], "\n",
      "Ask : ", ask, "\n",
      "Bid : ", bid, "\n",
      "ATR : ", atr[0]
   );
   bool isEligibleForBuy = (bid - 50 * _Point > maFast[0]);
   bool isEligibleForSell = (bid + 50 * _Point < maFast[0]); /// MAKE sure this is changed or not
   bool upTrend = (maSlow[0] <  maFast[0] < ask);
   bool downtrend = (maSlow[0] > maFast[0] > bid);
   if(!CheckIfOpenOrderByMagicNB(Magic))
     {
      if(buySignal && isBuy)
        {
         excuteBuy();
         tralingStopLoss = false;
         isBuy = false;
        }
      else
         if(sellSignal && !isBuy)
           {
            excuteSell();
            tralingStopLoss = false;
            isBuy = true;
           }
     }
   else
      if(!tralingStopLoss)
        {
         if(PositionSelectByTicket(orderTicket))
           {
            if(PositionGetInteger(POSITION_MAGIC) == Magic)
              {
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                 {
                  if(sellSignal)
                    {
                     tralingStopLoss = true;
                    }
                 // else
                   //  if(maFast[0] > ask)
                     //  {
                       // trade.PositionClose(orderTicket);
                       //}
                 }
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                 {
                  if(buySignal)
                    {
                     tralingStopLoss = true;
                    }
                  //else
                    // if(maFast[0] < bid)
                      // {
                        //trade.PositionClose(orderTicket);
                       //}
                 }
              }
           }
        }
      else
         if(tralingStopLoss)
           {
            if(PositionSelectByTicket(orderTicket))
               Print("Order ticket : ", orderTicket);
              {
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                 {
                  if(bbMid[0] > bid)
                    {
                     trade.PositionClose(orderTicket);
                    }
                 }
               else
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                    {
                     if(bbMid[0] < bid)
                       {
                        trade.PositionClose(orderTicket);
                       }
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
