//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <trade/trade.mqh>

input double Lots = 0.1;
input int TpPoints = 1000;
input int SlPoints = 500;
input int TslTriggerPoints = 200;
input int TslPoint = 100;
input string Commentary = "atr breackout";
input int Magic = 1;
input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;
input int AtrPeriod = 14;
input double TriggerFactor = 2.5;

int handleAtr;
int barsTotal;
CTrade trade;
int OnInit()
  {
   Print("this is onit Function ....");
   trade.SetExpertMagicNumber(Magic);
   handleAtr = iATR(_Symbol, Timeframe, AtrPeriod);
   barsTotal = iBars(_Symbol, Timeframe);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("this is Deinit Function and the reason is", reason, ".....");
  }




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   for(int i = 0; i < PositionsTotal(); i++)
     {
      ulong posTicket = PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != Magic)
         continue;
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double posPriceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
      double posSl = PositionGetDouble(POSITION_SL);
      double posTp = PositionGetDouble(POSITION_TP);
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
         if(bid > posPriceOpen + TslTriggerPoints * _Point)
           {
            double sl = bid - TslPoint * _Point;
            sl = NormalizeDouble(sl, _Digits);
            if(sl > posSl)
              {
               trade.PositionModify(posTicket, sl, posTp);
              }
           }
        }
      else
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
           {
            if(ask < posPriceOpen - TslPoint * _Point)
              {
               double sl = ask + TslPoint * _Point;
               sl = NormalizeDouble(sl, _Digits);
               if(sl < posSl || posSl == 0)
                 {
                  trade.PositionModify(posTicket, sl, posTp);
                 }
              }
           }
     }
   int bars = iBars(_Symbol, Timeframe);
   if(barsTotal != bars)
     {
      barsTotal = bars;
      double atr[];
      CopyBuffer(handleAtr, 0, 1, 1, atr);
      double open = iOpen(_Symbol, Timeframe, 1);
      double close = iClose(_Symbol, Timeframe, 1);
      if(open < close && close - open > atr[0] * TriggerFactor)
        {
         Print("Buy Signal");
         excuteBuy();
        }
      else
         if(open > close && open - close > atr[0]* TriggerFactor)
           {
            Print("Sell Signal");
            excuteSell();
           }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void excuteBuy()
  {
   double entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   entry = NormalizeDouble(entry, _Digits);
   double tp = entry + TpPoints * _Point;
   tp = NormalizeDouble(tp, _Digits);
   double sl = entry - SlPoints * _Point;
   sl = NormalizeDouble(sl, _Digits);
   trade.Buy(Lots, _Symbol, entry, sl, tp, Commentary);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void excuteSell()
  {
   double entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   entry = NormalizeDouble(entry, _Digits);
   double tp = entry - TpPoints * _Point;
   tp = NormalizeDouble(tp, _Digits);
   double sl = entry + SlPoints * _Point;
   sl = NormalizeDouble(sl, _Digits);
   trade.Sell(Lots, _Symbol, entry, sl, tp, Commentary);
  }


//+------------------------------------------------------------------+
