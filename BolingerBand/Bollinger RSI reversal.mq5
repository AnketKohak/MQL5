//+------------------------------------------------------------------+
//|                                       Bollinger RSI reversal.mq5 |
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
CiBands Bollinger;
CiBands TPBol;

#include <Indicators\Oscilators.mqh>
CiRSI RSI;

input group "=== EA specific Variables ==="

input ulong InpMagic = 23948;
input  ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;

input group "=== Trade Settings ==="
input int BollingerMAperiod = 200;
input double BollingerStDev = 4;
input int RSIUpper = 80;
input int RSIlower = 20;
input int RSIPeriod = 14;

input group "=== Trade Managment ==="
input LotTyp Lot_Type = 0;
input double Lotsize = 0.02;
input double Lotsizeper = 0.01;
input double BarsSince = 100;

ENUM_APPLIED_PRICE  AppPrice = PRICE_MEDIAN;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagic);
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
   string symbol = _Symbol;

   if(!IsNewbar())
      return;



   Bollinger = new CiBands;
   Bollinger.Create(symbol, Timeframe, BollingerMAperiod, 0, AppPrice);
   RSI = new CiRSI;
   RSI.Create(symbol, Timeframe, RSIPeriod, AppPrice);
   RSI.Refresh(-1);
   Bollinger.Refresh(-1);

   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid  = SymbolInfoDouble(symbol, SYMBOL_BID);
   double Closex1 = iClose(symbol, Timeframe, 1);
//ulong BarsLastTraded = GetBarsLastTrade(symbol);
   ulong BarsNow = iBars(symbol, Timeframe);


   if(Closex1 < Bollinger.Lower(1) && BarsNow > BarsLastTraded + BarsSince && RSI.Main(1) < 20)
     {
      double tp = TPBol.Upper(0);
      trade.Buy(lots, symbol, 0, 0, tp, NULL);

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
//+----------
//+------------------------------------------------------------------+
