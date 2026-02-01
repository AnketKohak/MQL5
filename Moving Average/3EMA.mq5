//+------------------------------------------------------------------+
//|                                                         3EMA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

// https://www.youtube.com/watch?v=Q2ZU_VA9I8A

//this good for gold 
// this 5 mintues strategy



#include <Trade/Trade.mqh>
CTrade trade;
CPositionInfo posinfo;
COrderInfo ordinfo;

enum enumLotType {Fixed_Lots = 0, Pct_Of_Balance = 1, Pct_Of_Equity = 2, Pct_Of_Margin = 3};
enum enumHour {Inactive = 0, _0100 = 1, _0200 = 2, _0300 = 3, _0400 = 4, _0500 = 5, _0600 = 6, _0700 = 7, _0800 = 8, _0900 = 9, _1000 = 10, _1100 = 11, _1200 = 12, _1300 = 13, _1400 = 14, _1500 = 15, _1600 = 16, _1700 = 17, _1800 = 18, _1900 = 19, _2000 = 20, _2100 = 21, _2200 = 22, _2300 = 23};

input group  "===Moving Average Profile ===="

input ENUM_TIMEFRAMES TradingTimeFrame = PERIOD_M5;
input int TradingMAFastest_Period = 8;
input int TradingMAMiddle_Period = 13;
input int TradingMASlowest_Period = 21;
input ENUM_TIMEFRAMES TrendTimeFrame = PERIOD_H1;
input int TrendMAFast_Period = 13;
input int TrendMASlow_Period = 21;
input ENUM_MA_METHOD MA_Mode  = MODE_EMA;
input ENUM_APPLIED_PRICE MA_AppliedPrice = PRICE_MEDIAN;

input group "=== EA Releated variables ===="
input enumLotType Lotype = 1;
input double FixedLots = 0.01;
input double RiskPercent = 2;
input ulong InpMagic  = 10;
input enumHour SHInput = 7;
input enumHour EHInput = 21;
input int ExpirationBars = 12;
input double tppoint = 1;

// === Genral global varibales ===
int handleTradingMA_Fastest, handleTradingMA_Slowest, handleTradingMA_Middle, handleTrendMA_Fast, handleTrendMA_Slow;
double IndBuffer[];
double TradingMA_Fastest, TradingMA_Middle, TradingMA_Slowest, TrendMA_Fast, TrendMA_Slow;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagic);
   ChartSetInteger(0, CHART_SHOW_GRID, false);
// === moving average handles
   handleTradingMA_Fastest = iMA(_Symbol, TradingTimeFrame, TradingMAFastest_Period, 1, MA_Mode, MA_AppliedPrice);
   handleTradingMA_Middle  = iMA(_Symbol, TradingTimeFrame, TradingMAMiddle_Period, 1, MA_Mode, MA_AppliedPrice);
   handleTradingMA_Slowest = iMA(_Symbol, TradingTimeFrame, TradingMASlowest_Period, 1, MA_Mode, MA_AppliedPrice);
   handleTrendMA_Fast = iMA(_Symbol, TrendTimeFrame, TrendMAFast_Period, 1, MA_Mode, MA_AppliedPrice);
   handleTrendMA_Slow = iMA(_Symbol, TrendTimeFrame, TrendMASlow_Period, 1, MA_Mode, MA_AppliedPrice);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print("3EMA stopped");
   IndicatorRelease(handleTradingMA_Fastest);
   IndicatorRelease(handleTradingMA_Middle);
   IndicatorRelease(handleTradingMA_Slowest);
   IndicatorRelease(handleTrendMA_Fast);
   IndicatorRelease(handleTrendMA_Slow);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  int BuyTotal =0, SellTotal=0;
   if(isOnePositionClosed())
     {
      SetToBreakEven();
     }

   if(!IsNewbar())
     {
      return ;
     }
   MqlDateTime time;
   TimeToStruct(TimeCurrent(), time);
   int Hournow = time.hour;

   if(Hournow < SHInput)
     {
      CloseAllOrders();
      return;
     }
   if(Hournow >= EHInput && EHInput != 0)
     {
      CloseAllOrders();
      return;
     }

   AssignEMAValues();
// === High and Low Finding ===
   double Open1x = iOpen(_Symbol, TradingTimeFrame, 1);
   double Low1x = iLow(_Symbol, TradingTimeFrame, 1);
   double High1x = iHigh(_Symbol, TradingTimeFrame, 1);

   int Lowestx5 = iLowest(_Symbol, TradingTimeFrame, MODE_LOW, 5, 1);
   double Low5x = iLow(_Symbol, TradingTimeFrame, Lowestx5);
   int Highestx5 = iHighest(_Symbol, TradingTimeFrame, MODE_HIGH, 5, 1);
   double Highx5 = iHigh(_Symbol, TradingTimeFrame, Highestx5);

// == this will allow to use this ea on multiple ea wala account
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ordinfo.SelectByIndex(i);
      if(ordinfo.OrderType() == ORDER_TYPE_BUY_STOP && ordinfo.Symbol() == _Symbol && ordinfo.Magic() == InpMagic)
        {
         BuyTotal++;
        }
      if(ordinfo.OrderType() == ORDER_TYPE_SELL_STOP && ordinfo.Symbol() == _Symbol && ordinfo.Magic() == InpMagic)
        {
         SellTotal++;
        }
     }
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      posinfo.SelectByIndex(i);
      if(posinfo.PositionType() == POSITION_TYPE_BUY && posinfo.Symbol() == _Symbol && posinfo.Magic() == InpMagic)
        {
         BuyTotal++;
        }
      if(posinfo.PositionType() == POSITION_TYPE_SELL && posinfo.Symbol() == _Symbol && posinfo .Magic() == InpMagic)
        {
         SellTotal++;
        }
     }
// Checking for Buy Conditions

   if(TradingMA_Fastest    > TradingMA_Middle
      && TradingMA_Middle  > TradingMA_Slowest
      && TrendMA_Fast      > TrendMA_Slow
      && Open1x            > TradingMA_Fastest
      && Low1x             < TradingMA_Fastest
      && Low1x             > TradingMA_Slowest
      && BuyTotal          < 1
     )
     {
      double entry = Highx5 + 30 * _Point;
      double sl = Low1x - 30 * _Point;
      double tp1 = entry + (entry - sl);
      double tp2 = entry + ((entry - sl)*2);
      double lots = calcLots(entry - sl);
      datetime expiration = iTime(_Symbol, TradingTimeFrame, 0) + ExpirationBars * PeriodSeconds(TradingTimeFrame);

      trade.BuyStop(lots, entry, _Symbol, sl, tp1, ORDER_TIME_SPECIFIED, expiration, "Mr capfree");
      trade.BuyStop(lots, entry, _Symbol, sl, tp2, ORDER_TIME_SPECIFIED, expiration, "Mr capfree");
     }

   if(TradingMA_Fastest    < TradingMA_Middle
      && TradingMA_Middle  < TradingMA_Slowest
      && TrendMA_Fast      < TrendMA_Slow
      && Open1x            < TradingMA_Fastest
      && High1x             > TradingMA_Fastest
      && High1x             < TradingMA_Slowest
      && SellTotal         < 1
     )
     {
      double entry = Low5x - 30 * _Point;
      double sl = High1x + 30 * _Point;
      double tp1 = entry - (sl - entry);
      double tp2 = entry - ((sl - entry)*2);
      double lots = calcLots(sl - entry);
      datetime expiration = iTime(_Symbol, TradingTimeFrame, 0) + ExpirationBars * PeriodSeconds(TradingTimeFrame);

      trade.SellStop(lots, entry, _Symbol, sl, tp1, ORDER_TIME_SPECIFIED, expiration, "Mr capfree");
      trade.SellStop(lots, entry, _Symbol, sl, tp2, ORDER_TIME_SPECIFIED, expiration, "Mr capfree");
     }



  }
//+------------------------------------------------------------------+
double calcLots(double slPoints)
  {
   double lots = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   double AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double EquityBalance = AccountInfoDouble(ACCOUNT_EQUITY);
   double FreeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double risk = 0;
   switch(Lotype)
     {
      case 0 :
         lots = FixedLots;
         return lots;
      case 1:
         risk = (AccountBalance * RiskPercent / 100) / 2;
         break;
      case 2:
         risk = (EquityBalance * RiskPercent / 100) / 2;
         break;
      case 3:
         risk = (FreeMargin * RiskPercent / 100) / 2;
         break;

     }

   double ticksize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double moneyPerLotstep = slPoints / ticksize * tickvalue * lotstep;
   lots = MathFloor(risk / moneyPerLotstep) * lotstep;
   double minVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double maxvolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double volumelimit = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT);
//
   if(volumelimit != 0)
      lots = MathMin(lots, volumelimit);
   if(maxvolume != 0)
     {
      lots = MathMin(lots, maxvolume);
     }
   if(minVolume != 0)
     {
      lots = MathMax(lots, minVolume);
     }
   lots = NormalizeDouble(lots, 2);
   return lots;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNewbar()
  {
   static datetime previousTime = 0;
   datetime currentTime  = iTime(_Symbol, TradingTimeFrame, 0);
   if(previousTime != currentTime)
     {
      previousTime = currentTime;
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllOrders()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ordinfo.SelectByIndex(i);
      ulong ticket = ordinfo.Ticket();
      if(ordinfo.Symbol() == _Symbol && ordinfo.Magic() == InpMagic)
        {
         trade.OrderDelete(ticket);
        }

     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AssignEMAValues()
  {

   CopyBuffer(handleTradingMA_Fastest, 0, 1, 1, IndBuffer);
   TradingMA_Fastest = IndBuffer[0];

   CopyBuffer(handleTradingMA_Middle, 0, 1, 1, IndBuffer);
   TradingMA_Middle = IndBuffer[0];

   CopyBuffer(handleTradingMA_Slowest, 0, 1, 1, IndBuffer);
   TradingMA_Slowest = IndBuffer[0];
   CopyBuffer(handleTrendMA_Fast, 0, 1, 1, IndBuffer);
   TrendMA_Fast = IndBuffer[0];
   CopyBuffer(handleTrendMA_Slow, 0, 1, 1, IndBuffer);
   TrendMA_Slow = IndBuffer[0];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetToBreakEven()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      posinfo.SelectByIndex(i);
      if(posinfo.Magic() == InpMagic && posinfo.Symbol() == _Symbol)
        {
         ulong ticket = posinfo.Ticket();
         double entry = posinfo.PriceOpen();
         if(posinfo.PositionType() == POSITION_TYPE_BUY)
           {
            trade.PositionModify(ticket, entry + 5 * _Point, posinfo.TakeProfit());
           }
         if(posinfo.PositionType() == POSITION_TYPE_SELL)
           {
            trade.PositionModify(ticket, entry - 5 * _Point, posinfo.TakeProfit());
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isOnePositionClosed()
  {
   static int PosTotalprv = 0;
   int PosTotalcurr = PositionsTotal();
   if(PosTotalcurr == 2 && PosTotalprv != PosTotalcurr)
     {
      PosTotalprv = PosTotalcurr;
     }
   if(PosTotalprv == 2 && PosTotalcurr == 1)
     {
      PosTotalprv = PosTotalcurr;
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
