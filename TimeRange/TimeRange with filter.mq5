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
enum Minutes {_0=00,_25=25,_30=30,_35=35,_40=40,_45=45,_50=50,_55=55};
enum TrsSides {Onesided =0, Bothsided=1};
enum SLType {Yes = 0, No = 1};
enum TrType {RangePct = 0, HighLow = 1,Fixedpips =2};
enum TrStyle {With_Break = 0, Opposite_to_Break = 1};
enum IcTypes {Price_above_Cloud=0,Price_above_Ten = 1,Price_above_Kij = 2,Price_above_SenA =3,Price_above_SenB=4,Ten_above_Kij = 5,Ten_above_Kij_above_Cloud = 6,Ten_above_Cloud = 7,Kij_above_Cloud = 8 };


input group "=== Ea specfic variables ===";
input ulong InpMagic = 11;
input string TradeComment = "TimeRangeEA";
input TrStyle TradingStyle = 1;
input TrsSides TradingSides = 0;
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;

input group "=== Range Settings ===";
input Hours RangeStartHour = 8;
input Minutes RangeStartMin = 0;
input Hours RangeEndHour = 12;
input Minutes RangeEndMin = 0;
input Hours TradeCloseHour = 22;
input Minutes TradeCloseMin = 0;
input color rangeColor = clrBeige;
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
input int TrailFiexdpips = 30;
input int TrailRangePct = 80;
input int BarsN = 5;
input int HighLowBuffer = 2;

MqlDateTime starttime,endtime,closetime;
datetime timestart,timeend,timeclose;
int BarsRangeStart,BarstoCount,BuyTotal,SellTotal;
double RangeHigh,RangeLow,RangeSize,Tsl;


input group "===News Filter ==="
input bool NewsFilterOn = true;
enum sep_dropdown {commo = 0,semicolon = 1};
input sep_dropdown separater = 0;
input string KeyNews = "BCB,NFP,JOLTX,Nonfarm,PMI,Retail,GDP,Confidence,Interest Rate";
input string NewsCurrencies = "USD,GBP,EUR,JPY";
input int DaysNewsLookup = 100;
input color InpDisabledColor = clrRed;
bool TrDisableNews = false;


ushort sep_code;
string Newstoavoid[];
datetime LastNewsAvoided;


input group "===Moving Average Filter ==="

input bool MAFilterOn = true;
input ENUM_TIMEFRAMES MATimeframe = PERIOD_D1;
input int Slow_MA_Period = 200;
input int Fast_MA_Period = 50;
input ENUM_MA_METHOD MA_Mode = MODE_EMA;
input ENUM_APPLIED_PRICE MA_AppPrice = PRICE_MEDIAN;

bool MA_BuyOn = true;
bool MA_SellOn = true;

input group "=== IchiMoku Filter===="
input bool IchiFilterOn = true;
input IcTypes IchiFilterType = 0;
input ENUM_TIMEFRAMES IchiMokuTimeframe = PERIOD_D1;
input int tenkan = 9;
input int kijun = 26;
input int senkon_b = 52;
bool Ichi_BuyOn = true;
bool Ichi_SellOn = true;



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagic);
   ChartSetInteger(0, CHART_SHOW_GRID, false);

   if(IchiFilterOn == true)
     {
      IchiMoku = new CiIchimoku;
      IchiMoku.Create(_Symbol,IchiMokuTimeframe,tenkan,kijun,senkon_b);
     }
   if(MAFilterOn == true)
     {
      MovAvgSlow = new CiMA;
      MovAvgSlow.Create(_Symbol,MATimeframe,Slow_MA_Period,0,MA_Mode,MA_AppPrice);
      MovAvgFast = new CiMA;
      MovAvgFast.Create(_Symbol,MATimeframe,Fast_MA_Period,0,MA_Mode,MA_AppPrice);
     }

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
//|                                                                  |
//+------------------------------------------------------------------+
void convertTimes()
  {
   TimeToStruct(TimeCurrent(),starttime);
   starttime.hour = RangeStartHour;
   starttime.min = RangeStartMin;
   timestart = StructToTime(starttime);

   TimeToStruct(TimeCurrent(),endtime);
   endtime.hour = RangeEndHour;
   endtime.min = RangeEndMin;
   timeend = StructToTime(endtime);

   TimeToStruct(TimeCurrent(),closetime);
   closetime.hour = TradeCloseHour;
   closetime.min = TradeCloseMin;
   timeclose = StructToTime(closetime);

   if(BarsRangeStart == 0 && TimeCurrent()>= timestart)
     {
      BarsRangeStart = iBars(_Symbol,InpTimeframe);
     }


  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetHigh()
  {
   double high = 0;
   int highestbar = 0;
   int BarsNow = iBars(_Symbol,InpTimeframe);
   if(TimeCurrent() > timestart && TimeCurrent()<timeend)
     {
      BarstoCount = iBars(_Symbol,InpTimeframe) - BarsRangeStart +1;
      highestbar = iHighest(_Symbol,InpTimeframe,MODE_HIGH,BarstoCount,0);
      high = iHigh(_Symbol,InpTimeframe,highestbar);
      if(high!=RangeHigh)
         return high;
     }
   return RangeHigh;
  }
  double GetLow()
  {
   double low = 0;
   int lowestbar = 0;

   if(TimeCurrent() > timestart && TimeCurrent()<timeend)
     {
      BarstoCount = iBars(_Symbol,InpTimeframe) - BarsRangeStart +1;
      lowestbar = iLowest(_Symbol,InpTimeframe,MODE_LOW,BarstoCount,0);
      low = iLow(_Symbol,InpTimeframe,lowestbar);
      if(low!=RangeLow)
         return low;
     }
   return RangeLow;
  }
//+------------------------------------------------------------------+
//|                                                                  |
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
void CheckForOpenOrdersandPositions()
  {

   for(int i = OrdersTotal()-1;i>=0;i--)
     {
      ordinfo.SelectByIndex(i);
      if(ordinfo.OrderType()==ORDER_TYPE_BUY_STOP && ordinfo.Symbol()==_Symbol && ordinfo.Magic()==InpMagic)
         BuyTotal++;

      if(ordinfo.OrderType()==ORDER_TYPE_SELL_STOP && ordinfo.Symbol()==_Symbol && ordinfo.Magic()==InpMagic)
         SellTotal++;
      if(ordinfo.OrderType()==ORDER_TYPE_BUY_LIMIT && ordinfo.Symbol()==_Symbol && ordinfo.Magic()==InpMagic)
         BuyTotal++;

      if(ordinfo.OrderType()==ORDER_TYPE_SELL_LIMIT && ordinfo.Symbol()==_Symbol && ordinfo.Magic()==InpMagic)
         SellTotal++;
     }

   for(int i = PositionsTotal()-1;i>=0;i--)
     {
      posinfo.SelectByIndex(i);
      if(posinfo.PositionType() == POSITION_TYPE_BUY && posinfo.Symbol()== _Symbol&& posinfo.Magic()==InpMagic)
         BuyTotal++;
      if(posinfo.PositionType() == POSITION_TYPE_SELL && posinfo.Symbol()== _Symbol&& posinfo.Magic()==InpMagic)
         SellTotal++;
     }
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
