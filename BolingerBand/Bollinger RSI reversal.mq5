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


enum LotTyp {Lot_per_1k_capital = 0, Fixed_Lot_Size = 1};
input group "=== EA specific Variables ==="

input ulong InpMagic = 23948;
input string Curren = "USDJPY,GBPUSD";
input  ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;

input group "=== Trade Settings ==="
input int BollingerMAperiod = 200;
input double BollingerStDev = 4;
input int RSIUpper = 80;
input int RSIlower = 20;
input int RSIPeriod = 14;

input group "=== Trade Managment ==="
input  LotTyp Lot_Type = 0;
input double Lotsize = 0.02;
input double Lotsizeper1000 = 0.01;
input double TPBolStDev = 3;
input double BarsSince = 100;

ENUM_APPLIED_PRICE  AppPrice = PRICE_MEDIAN;


string Currencies[];
string BarsTraded[][2];
string sep = ",";
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagic);
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   int sep_code = StringGetCharacter(sep, 0);
   int k = StringSplit(Curren, sep_code, Currencies);

   ArrayResize(BarsTraded, k);
   for(int i = k - 1; i >= 0; i--)
     {
      BarsTraded[i][0] = Currencies[i];
      BarsTraded[i][1] = IntegerToString(i);
     }
   ArrayPrint(BarsTraded);
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

   for(int i = ArraySize(Currencies) - 1; i >= 0; i--)
     {
      RunSymbols(Currencies[i]);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RunSymbols(string symbol)
  {

   TrailSL(symbol);

   Bollinger = new CiBands;
   Bollinger.Create(symbol, Timeframe, BollingerMAperiod, 0, BollingerStDev, AppPrice);
   RSI = new CiRSI;
   RSI.Create(symbol, Timeframe, RSIPeriod, AppPrice);
   RSI.Refresh(-1);
   Bollinger.Refresh(-1);

   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid  = SymbolInfoDouble(symbol, SYMBOL_BID);
   double Closex1 = iClose(symbol, Timeframe, 1);
   int BarsLastTraded = GetBarsLastTraded(symbol);
   int BarsNow = iBars(symbol, Timeframe);
   double lots = 0.01;
   double AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   switch(Lot_Type)
     {
      case 0:
         lots = NormalizeDouble(Lotsizeper1000 * AccountBalance / 1000, 2);
         break;
      case 1:
         lots = Lotsize;
     }
   if(Closex1 < Bollinger.Lower(1) && BarsNow > BarsLastTraded + BarsSince && RSI.Main(1) < 20)
     {
      double tp = Bollinger.Upper(0);
      trade.Buy(lots, symbol, 0, 0, tp, NULL);
      SetBarsTraded(symbol);
     }
   else
      if(Closex1 > Bollinger.Upper(1) && BarsNow > BarsLastTraded + BarsSince && RSI.Main(0) > 80)
        {
         double tp = Bollinger.Lower(0);
         trade.Sell(lots, symbol, 0, 0, tp, NULL);
         SetBarsTraded(symbol);
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
void TrailSL(string symbol)
  {
   TPBol = new CiBands;
   TPBol.Create(symbol, Timeframe, BollingerMAperiod, 0, TPBolStDev, AppPrice);
   TPBol.Refresh(-1);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      posinfo.SelectByIndex(i);
      ulong ticket = posinfo.Ticket();
      double tp = posinfo.TakeProfit();

      switch(posinfo.PositionType())
        {
         case POSITION_TYPE_BUY :
            tp = TPBol.Upper(1);
            break;
         case POSITION_TYPE_SELL :
            tp = TPBol.Lower(1);
            break;
        }

      if(posinfo.Symbol() == symbol & posinfo.Magic() == InpMagic)
        {
         trade.PositionModify(ticket, 0, tp);
        }
     }
  }
//+------------------------------------------------------------------+
void SetBarsTraded(string symbol)
  {
   for(int i = ArraySize(Currencies) - 1; i >= 0; i--)
     {
      string targetsymbol = BarsTraded[i][0];
      int BarsNow = iBars(symbol, Timeframe);
      if(targetsymbol == symbol)
        {
         BarsTraded[i][1] = IntegerToString(BarsNow);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetBarsLastTraded(string symbol)
  {
   long BarsLastTraded = 0;
   for(int i = ArraySize(Currencies) - 1; i >= 0; i--)
     {
      string targetsymbol = BarsTraded[i][0];
      if(targetsymbol == symbol)
        {
         BarsLastTraded = StringToInteger(BarsTraded[i][1]);
        }
     }
   return BarsLastTraded;
  }
//+------------------------------------------------------------------+
