//+------------------------------------------------------------------+
//|                                        TimeRange with filter.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
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


enum LST {Fixed = 0, RiskPct = 1};
enum Hours {_1 = 1,_2=2,_3=3,_4=4,_5=5,_6=6,_7=7,_8=8,_9=9,_10=10,_11=11,_12=12,_13=13,_14=14,_15=15,_16=16,_17=17,_18=18,_19=19,_20=20,_21=21,_22=22,_23=23,_24=24};
enum Minutes {_0=0,_5=5,_10=10,_15=15,_20=20,_25=25,_30=30,_35=35,_40=40,_45=45,_50=50,_55=55};
enum TrsSides{Onesided =0, Bothsided=1};
enum SLType {Yes = 0, No = 1};
enum TrType {RangePct = 0, HighLow = 1,Fixedpips =2};
enum TrStyles {With_Break = 0, Opposite_to_Break = 1};
enum IcTypes {Price_above_Cloud=0,Price_above_Ten = 1,Price_above_Kij = 2,Price_above_SenA =3,Price_above_SenB=4,Ten_above_Kij = 5,Ten_above_Kij_above_Cloud = 6,Ten_above_Cloud = 7,Kij_above_Cloud = 8 };
enum  sep_dropdown{comma = 0, semicolon = 1};

input group "=== Ea specfic variables ===";
input ulong InpMagic
input string TradeComment = "TimeRangeEA";
input TrStyle TradingStyle = 1;
input TrSides TradingSides 0;

input group "=== Range Settings ===";
input Hours RangeStartHour = 8;
input Minutes RangeStartMin = 0;
input Hours RangeEndHour = 12;
input Minutes RangeEndMin = 0;
input Hours TradeCloseHour = 22;
input Minutes TradeCloseMin = 0;
input color rangeColor = clrBeige
input int MinRangeSize = 15;
input int MaxRangeSize = 30;
input color rangeColordisabled = clrRed;

input group "=== Trade Management ===";

input LST LotSizeType = 1;
input double FixedLotSize = 0.01;
input double RiskPercent = 2.0;
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M5;
input int OrdDistpct = 10;
input int SLPercent = 100;
input int TPPercent = 180;

input group "=== Stoploss Management ===";
input SLType SLT = 1;
input TrType TrailType = 1;
input int TrailFiexdpips = 1;
input int TrailRangePct = 30;
input int TrailRangePct = 80;
input int BarsN = 5;
input int HighLowBuffer 2;

int OnInit()
  {
//---
   
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
   
  }
//+------------------------------------------------------------------+
