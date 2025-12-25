//+------------------------------------------------------------------+
//|                                                     Learning.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade/Trade.mqh>


input ENUM_TIMEFRAMES Timeframe = PERIOD_D1;
input int Count = 20;
input double Lots = 0.1;
input long Magic = 5669;
input double TpPercent = 0;
input long SlPercent = 1.0;
input bool IsTsl = true;
input double TslBufferPercent = 1.0;


CTrade trade;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("Learnig ea started");
   trade.SetExpertMagicNumber(Magic);
   return(INIT_SUCCEEDED);
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("Learnig ea stopeed");
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

   int hightest = iHighest(_Symbol,Timeframe,MODE_HIGH,Count,1);
   double high = iHigh(_Symbol,PERIOD_M5,hightest);
   

   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   Print("hightest :",high,     "   Bid  :",bid);
   bool isPosOpen = loopPos(bid);


   if(!isPosOpen && bid>high)
     {

      double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double tp = 0;
      if(TpPercent > 0)
         tp = ask + ask *TpPercent/100;
      double sl = ask - ask * SlPercent/100;
      trade.Buy(Lots,_Symbol,ask,sl,tp);
     }


  }
  
  
  bool loopPos(double bid){
  bool isOpen = false;
  for(int i = PositionsTotal()-1; i>=0;i--)
     {
      ulong posTicket = PositionGetTicket(i);

      string posSymbol = PositionGetString(POSITION_SYMBOL);
      if(posSymbol != _Symbol)
         continue;

      long posMagic = PositionGetInteger(POSITION_MAGIC);
      if(posMagic != Magic)
         continue;

       isOpen = true;

      if(IsTsl)
        {
         double sl = iLow(_Symbol,Timeframe,1) - bid * TslBufferPercent / 100;
         double posSl = PositionGetDouble(POSITION_SL);
         double posTp = PositionGetDouble(POSITION_TP);

         if(sl > posSl)
           {
            trade.PositionModify(posTicket,sl,posTp);

           }
        }
     }
     return isOpen;
  
  }
//+------------------------------------------------------------------+
