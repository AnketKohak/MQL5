//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property version   "1.10"

#include <trade/trade.mqh>

input double Lots = 0.01;
input int MAFast = 20;
input int MASlow = 50;
input int MATrend = 200;
input int takeProfit = 300;
input int stoploss = 200;
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;
input int TriggerStopLoss = 3.00;
long Magic = 6;
CTrade trade;
CPositionInfo pos;
COrderInfo ord;


int hFast, hSlow, hTrend;
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(Magic);
   hFast  = iMA(_Symbol, Timeframe, MAFast, 0, MODE_EMA, PRICE_CLOSE);
   hSlow  = iMA(_Symbol, Timeframe, MASlow, 0, MODE_EMA, PRICE_CLOSE);
   hTrend = iMA(_Symbol, Timeframe, MATrend, 0, MODE_EMA, PRICE_CLOSE);
   return INIT_SUCCEEDED;
  }
//+------------------------------------------------------------------+
void OnTick()
  {
//TrailStop();//-
   datetime currentBar = iTime(_Symbol, Timeframe, 0);
   if(currentBar == lastBarTime)
      return;   // NEW BAR FILTER
   lastBarTime = currentBar;
   double fast[3], slow[3], trend[3], closePrice[3];
   ArraySetAsSeries(fast, true);
   ArraySetAsSeries(slow, true);
   ArraySetAsSeries(trend, true);
   ArraySetAsSeries(closePrice, true);
   CopyBuffer(hFast,  0, 0, 3, fast);
   CopyBuffer(hSlow,  0, 0, 3, slow);
   CopyBuffer(hTrend, 0, 0, 3, trend);
   CopyClose(_Symbol, Timeframe, 0, 3, closePrice);
   bool buySignal  = fast[0] < slow[0] && fast[1] > slow[1] &&  closePrice[1] > trend[1];;
   bool sellSignal = fast[0] > slow[0] && fast[1] < slow[1] &&  closePrice[1] < trend[1];;
   Comment(
      "fast0: ", fast[0], "\n",
      "fast1: ", fast[1], "\n",
      "fast2: ", fast[2], "\n",
      "slow0: ", slow[0], "\n",
      "slow1: ", slow[1], "\n",
      "slow2: ", slow[2]
   );
//   bool trendBuy  = closePrice[1] > trend[1];
//   bool trendSell = closePrice[1] < trend[1];
// ENTRY
   if(!PositionSelect(_Symbol))
     {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid  = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(buySignal)
        {
         double tp = ask + takeProfit * _Point;
         double sl = ask - stoploss * _Point;
         trade.Buy(Lots, _Symbol, ask, 0, 0);
        }
      else
         if(sellSignal)
           {
            double tp = bid - takeProfit * _Point;
            double sl = bid + stoploss * _Point;
            trade.Sell(Lots, _Symbol, bid, 0, 0);
           }
     }
// EXIT
   else
     {
      long type = PositionGetInteger(POSITION_TYPE);
      if(type == POSITION_TYPE_BUY && fast[1] < slow[1])
         trade.PositionClose(_Symbol);
      if(type == POSITION_TYPE_SELL && fast[1] > slow[1])
         trade.PositionClose(_Symbol);
     }
  }
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
               if(profit > TriggerStopLoss)
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
                  if(profit > TriggerStopLoss)
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
