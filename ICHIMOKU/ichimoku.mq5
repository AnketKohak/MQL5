//+------------------------------------------------------------------+
//|                                        TimeRange with filter.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

// Youtube video link : https://www.youtube.com/watch?v=M8Z6czLQYns&t=3123s
// this is good to use in 15m timeframe

#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;
CPositionInfo posinfo;
COrderInfo ordinfo;

#include <Indicators\Trend.mqh>
CiIchimoku IchiMoku;
CiMA MovAvgFast, MovAvgSlow;


enum IcTypes {Price_above_Cloud = 0, Price_above_Ten = 1, Price_above_Kij = 2, Price_above_SenA = 3, Price_above_SenB = 4, Ten_above_Kij = 5, Ten_above_Kij_above_Cloud = 6, Ten_above_Cloud = 7, Kij_above_Cloud = 8 };


input group "=== Ea specfic variables ===";
input ulong InpMagic = 11;
input string TradeComment = "TimeRangeEA";
int BuyTotal, SellTotal;
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;

input group "=== Trade Management ===";


input double FixedLotSize = 0.01;
input double RiskPercent = 2.0;
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M5;
input int OrdDistpct = 10;
input int SLPercent = 100;
input int TPPercent = 180;

input group "=== Stoploss Management ===";

input int BarsN = 5;


input group "=== IchiMoku Filter===="
input bool IchiFilterOn = true;
input IcTypes IchiFilterType = 0;
input ENUM_TIMEFRAMES IchiMokuTimeframe = PERIOD_D1;
input int tenkan = 9;
input int kijun = 26;
input int senkon_b = 52;
bool Ichi_BuyOn = true;
bool Ichi_SellOn = true;
void PricevsIchiMoku()
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double SenA = IchiMoku.SenkouSpanA(1);
   double SenB = IchiMoku.SenkouSpanB(1);
   double Ten = IchiMoku.TenkanSen(1);
   double Kij = IchiMoku.KijunSen(1);
   
   if(kijun > tenkan && )
     bool uptrend   =((tenkan_sen>=kijun_sen)&&(up_kumo26>down_kumo26)&&(Bid>up_kumo)&&(Bid>down_kumo)&&(kijun_sen>up_kumo)&&(chikou_span>Close[26]) && (tenkan_sen1<tenkan_sen) && (kijun_sen1<kijun_sen));
   bool downtrend =((tenkan_sen<=kijun_sen)&&(up_kumo26<down_kumo26)&&(Bid<up_kumo)&&(Bid<down_kumo)&&(kijun_sen<up_kumo)&&(chikou_span<Close[26])
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagic);
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   if(IchiFilterOn == true)
     {
      IchiMoku = new CiIchimoku;
      IchiMoku.Create(_Symbol, IchiMokuTimeframe, tenkan, kijun, senkon_b);
     }
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsNewbar())
      return;
   if(IchiFilterOn)
      IchiMoku.Refresh(-1);
   if((BuyTotal > 0 || SellTotal > 0))
      TrailSL();
   Prepareorder();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Prepareorder()
  {
  }

//+------------------------------------------------------------------+
//|                                                                  |
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
//|                                                                  |
//+------------------------------------------------------------------+
void CheckForOpenOrdersandPositions()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ordinfo.SelectByIndex(i);
      if(ordinfo.OrderType() == ORDER_TYPE_BUY_STOP && ordinfo.Symbol() == _Symbol && ordinfo.Magic() == InpMagic)
         BuyTotal++;
      if(ordinfo.OrderType() == ORDER_TYPE_SELL_STOP && ordinfo.Symbol() == _Symbol && ordinfo.Magic() == InpMagic)
         SellTotal++;
      if(ordinfo.OrderType() == ORDER_TYPE_BUY_LIMIT && ordinfo.Symbol() == _Symbol && ordinfo.Magic() == InpMagic)
         BuyTotal++;
      if(ordinfo.OrderType() == ORDER_TYPE_SELL_LIMIT && ordinfo.Symbol() == _Symbol && ordinfo.Magic() == InpMagic)
         SellTotal++;
     }
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      posinfo.SelectByIndex(i);
      if(posinfo.PositionType() == POSITION_TYPE_BUY && posinfo.Symbol() == _Symbol && posinfo.Magic() == InpMagic)
         BuyTotal++;
      if(posinfo.PositionType() == POSITION_TYPE_SELL && posinfo.Symbol() == _Symbol && posinfo.Magic() == InpMagic)
         SellTotal++;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
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
//|                                                                  |
//+------------------------------------------------------------------+
void TrailSL()
  {
   for(int i = PositionsTotal() - 1 ; i >= 0; i--)
     {
      posinfo.SelectByIndex(i);
      long magic = posinfo.Magic();
      ulong ticket = posinfo.Ticket();
      ENUM_POSITION_TYPE postype = posinfo.PositionType();
      string symbol = posinfo.Symbol();
      if(symbol == _Symbol && InpMagic == magic)
        {
         double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double tp = posinfo.TakeProfit();
         double sl = posinfo.StopLoss();
         double openPrice = posinfo.PriceOpen();
         double high = findHigh();
         double low = findLow();
         if(postype == POSITION_TYPE_BUY)
           {
            if()
              {
               //sl = price - RangeSize * TrailRangePct / 100;
               trade.PositionModify(ticket, sl, tp);
              }
           }
         else
            if(postype == POSITION_TYPE_SELL)
              {
               if()
                 {
                  //sl = price + RangeSize * TrailRangePct / 100;
                  trade.PositionModify(ticket, sl, tp);
                 }
              }
        }
     }
  }

//+------------------------------------------------------------------+
