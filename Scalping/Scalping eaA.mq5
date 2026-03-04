//+------------------------------------------------------------------+
//|                                                 Scalping eaA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//This ea very fast and tight stoploss trailing it only work due to high win rate 
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade/Trade.mqh>


CTrade trade;
CPositionInfo pos;
COrderInfo ord;
input double RiskPercent = 2;
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;

input int Tppoints = 200;
input int Slpoints = 200;
input int TslPoints = 10;
input int TslTriggerPoints = 15;

input int BarsN = 5;
input int OrderDistPoints = 100;
input int ExpirationBars = 100;

enum TradeHour {Inactive = 0, _0100 = 1, _0200 = 2, _0300 = 3, _0400 = 4, _0500 = 5, _0600 = 6, _0700 = 7, _0800 = 8, _0900 = 9, _1000 = 10, _1100 = 11, _1200 = 12, _1300 = 13, _1400 = 14, _1500 = 15, _1600 = 16, _1700 = 17, _1800 = 18, _1900 = 19, _2000 = 20, _2100 = 21, _2200 = 22, _2300 = 23};

input TradeHour SHInput = 0;

//enum EndHour {Inactive = 0, _0100 = 1, _0200 = 2, _0300 = 3, _0400 = 4, _0500 = 5, _0600 = 6, _0700 = 7, _0800 = 8, _0900 = 9, _1000 = 10, _1100 = 11, _1200 = 12, _1300 = 13, _1400 = 14, _1500 = 15, _1600 = 16, _1700 = 17, _1800 = 18, _1900 = 19, _2000 = 20, _2100 = 21, _2200 = 22, _2300 = 23};
input TradeHour EHInput = 0;

int SHChoice;
int EHChoice;

input int InpMagic = 1001;
input string TradeComment = "No Shenanigans";






//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   trade.SetExpertMagicNumber(InpMagic);

   SHChoice = SHInput;
   EHChoice = EHInput;

   ChartSetInteger(0, CHART_SHOW_GRID, false);
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
   TrailStop();

   if(!IsNewbar())
     {
      return ;
     }
   MqlDateTime time;
   TimeToStruct(TimeCurrent(), time);
   int Hournow = time.hour;

   if(Hournow < SHChoice)
     {
      CloseAllOrders();
      return;
     }
   if(Hournow >= EHChoice && EHChoice != 0)
     {
      CloseAllOrders();
      return;
     }

   int BuyTotal = 0;
   int SellTotal = 0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ord.SelectByIndex(i);
      if(ord.OrderType() ==  ORDER_TYPE_BUY_STOP && ord.Symbol() == _Symbol && ord.Magic() == InpMagic)
        {
         BuyTotal++;
        }
      if(ord.OrderType() ==  ORDER_TYPE_SELL_STOP && ord.Symbol() == _Symbol && ord.Magic() == InpMagic)
        {
         SellTotal++;
        }
     }

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      pos.SelectByIndex(i);

      if(pos.PositionType() ==  POSITION_TYPE_BUY && pos.Symbol() == _Symbol && pos.Magic() == InpMagic)
        {
         BuyTotal++;
        }
      if(pos.PositionType() ==  POSITION_TYPE_SELL && pos.Symbol() == _Symbol && pos.Magic() == InpMagic)
        {
         SellTotal++;
        }
     }

   if(BuyTotal <= 0)
     {
      double  high = findHigh();
      if(high > 0)
        {
         executeBuy(high);
        }
     }

   if(SellTotal <= 0)
     {

      double low = findLow();
      if(low > 0)
        {
         executeSell(low);
        }
     }

  }
//+------------------------------------------------------------------+
bool IsNewbar()
  {
   static datetime previousTime = 0;
   datetime currentTime  = iTime(_Symbol, Timeframe, 0);
   if(previousTime != currentTime)
     {
      previousTime = currentTime;
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
double findHigh()
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
double findLow()
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
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
double calcLots(double slPoints)
  {
   double risk = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent / 100;
   double ticksize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double moneyPerLotstep = slPoints / ticksize * tickvalue * lotstep;
   double lots = MathFloor(risk / moneyPerLotstep) * lotstep;
   double minVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double maxvolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double volumelimit = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT);
//
   if(volumelimit != 0)
      lots = MathMin(lots, volumelimit);
   if(maxvolume != 0)
     {
      lots = MathMin(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
     }
   if(minVolume != 0)
     {
      lots = MathMax(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
     }
   lots = NormalizeDouble(lots, 2);
   return lots;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void executeBuy(double entry)
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if(ask > entry - OrderDistPoints * _Point)
     {
      return;
     }

   double tp = entry + Tppoints * _Point;
   double sl = entry - Slpoints * _Point;

   double lots = 0.01;
   if(RiskPercent > 0)
      lots = calcLots(entry - sl);

   datetime expiration = iTime(_Symbol, Timeframe, 0) + ExpirationBars * PeriodSeconds(Timeframe);
   trade.BuyStop(lots, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void executeSell(double entry)
  {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(bid < entry + OrderDistPoints * _Point)
     {
      return;
     }

   double tp = entry - Tppoints * _Point;
   double sl = entry + Slpoints * _Point;

   double lots = 0.01;
   if(RiskPercent > 0)
      lots = calcLots(sl - entry);

   datetime expiration = iTime(_Symbol, Timeframe, 0) + ExpirationBars * PeriodSeconds(Timeframe);
   trade.SellStop(lots, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllOrders()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ord.SelectByIndex(i);
      ulong ticket = ord.Ticket();
      if(ord.Symbol() == _Symbol && ord.Magic() == InpMagic)
        {
         trade.OrderDelete(ticket);
        }

     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailStop()
  {

   double sl = 0;
   double tp = 0;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i))
        {
         ulong ticket = pos.Ticket();
         if(pos.Magic() == InpMagic && pos.Symbol() == _Symbol)
           {
            if(pos.PositionType() == POSITION_TYPE_BUY)
              {
               if(bid - pos.PriceOpen() > TslTrigferPoints * _Point)
                 {
                  tp = pos.TakeProfit();
                  sl = bid - (TslPoints * _Point);
                  if(sl > pos.StopLoss() && sl != 0)
                    {
                     trade.PositionModify(ticket, sl, tp);
                    }
                 }
              }
            else
               if(pos.PositionType() == POSITION_TYPE_SELL)
                 {
                  if(pos.PriceOpen() - ask > TslTriggerPoints * _Point)
                    {
                     tp = pos.TakeProfit();
                     sl = ask + (TslPoints * _Point);
                     if(sl < pos.StopLoss() && sl != 0)
                       {
                        trade.PositionModify(ticket, sl, tp);
                       }
                    }
                 }
           }
        }



     }

  }
//+------------------------------------------------------------------+
