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
CiIchimoku IchiMoku;
CiMA MovAvgFast,MovAvgSlow;


#include <Indicators\Oscilators.mqh>
CiRSI RSI;



enum LotTyp {Lot_per_1k_capital = 0, Fixed_Lot_Size = 1};
enum IcTypes {Price_above_Cloud=0,Price_above_Ten = 1,Price_above_Kij = 2,Price_above_SenA =3,Price_above_SenB=4,Ten_above_Kij = 5,Ten_above_Kij_above_Cloud = 6,Ten_above_Cloud = 7,Kij_above_Cloud = 8 };
input group "=== EA specific Variables ==="

input ulong InpMagic = 23948;
input string Curren = "GBPJPY,GBPCAD,GBPCHF,USDCAD,NZDJPY,EURGBP,EURNZD,AUDJPY,EURAUD,EURCAD,AUDCAD,NZDCAD";
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


input group "=== Moving Average Filter ==="
input bool MAFilterOn = false;
input ENUM_TIMEFRAMES MATimeframe = PERIOD_D1;
input int Slow_MAPeriod = 200;
input int Fast_MAPeriod = 50;
input ENUM_MA_METHOD MA_Mode = MODE_EMA;
input ENUM_APPLIED_PRICE MA_AppPrice = PRICE_MEDIAN;

input group "=== IchiMoku Filter===="
input bool IchiFilterOn = false;
input IcTypes IchiFilterType = 0;
input ENUM_TIMEFRAMES IchiMokuTimeframe = PERIOD_D1;
input int tenkan = 9;
input int kijun = 26;
input int senkon_b = 52;




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
   double FastMA = 0, SlowMA = 0;
   double SenA=0,SenB=0,Ten=0,Kij =0;

   if(MAFilterOn)
     {
      MovAvgSlow= new CiMA;
      MovAvgSlow.Create(symbol,MATimeframe,Slow_MAPeriod,0,MA_Mode,MA_AppPrice);
      MovAvgFast = new CiMA;
      MovAvgFast.Create(symbol,MATimeframe,Fast_MAPeriod,0,MA_Mode,MA_AppPrice);

      MovAvgFast.Refresh(-1);
      MovAvgSlow.Refresh(-1);
      FastMA = MovAvgFast.Main(1);
      SlowMA = MovAvgSlow.Main(1);

     }
   if(IchiFilterOn)
     {
      IchiMoku = new CiIchimoku;
      IchiMoku.Create(symbol,IchiMokuTimeframe,tenkan,kijun,senkon_b);
      IchiMoku.Refresh(-1);
      SenA = IchiMoku.SenkouSpanA(1);
      SenB = IchiMoku.SenkouSpanB(1);
      Ten = IchiMoku.TenkanSen(1);
      Kij = IchiMoku.KijunSen(1);

     }

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
      if(MAFilterOn && PricevsMovAvg(FastMA,SlowMA) != "above")
         return;
      if(IchiFilterOn && PricevsIchiMoku(symbol,SenA,SenB,Ten,Kij) != "above")
         return;
      double tp = Bollinger.Upper(0);
      trade.Buy(lots, symbol, 0, 0, tp, NULL);
      SetBarsTraded(symbol);
     }
   else
      if(Closex1 > Bollinger.Upper(1) && BarsNow > BarsLastTraded + BarsSince && RSI.Main(1) > 80)
        {
         if(MAFilterOn && PricevsMovAvg(FastMA,SlowMA) != "below")
            return;
         if(IchiFilterOn && PricevsIchiMoku(symbol,SenA,SenB,Ten,Kij) != "below")
            return;
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

      if(posinfo.Symbol() == symbol && posinfo.Magic() == InpMagic)
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
//|                                                                  |
//+------------------------------------------------------------------+
string PricevsMovAvg(double MAFast,double MASlow)
  {
   if(MAFast>MASlow)
      return "above";
   if(MAFast<MASlow)
      return "below";
   return "error for ma calulation";
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string PricevsIchiMoku(string symbol,double SenA,double SenB,double Ten,double Kij)
  {
   double ask = SymbolInfoDouble(symbol,SYMBOL_ASK);
   if(IchiFilterType == 0)
     {
      if(ask>SenA && ask>SenB)
         return "above";
      if(ask<SenA && ask<SenB)
         return "below";
     }

   if(IchiFilterType == 1)
     {
      if(ask>Ten)
         return "above";
      if(ask<Ten)
         return "below";
     }
   if(IchiFilterType == 2)
     {
      if(ask>Kij)
         return "above";
      if(ask<Kij)
         return "below";
     }
   if(IchiFilterType == 3)
     {
      if(ask>SenA)
         return "above";
      if(ask<SenA)
         return "below";
     }
   if(IchiFilterType == 4)
     {
      if(ask>SenB)
         return "above";
      if(ask<SenB)
         return "below";
     }
   if(IchiFilterType == 5)
     {
      if(Ten>Kij)
         return "above";
      if(Ten<Kij)
         return "below";
     }
   if(IchiFilterType == 6)
     {
      if(Ten>Kij && Kij > SenA && Kij > SenB)
         return "above";
      if(Ten<Kij && Kij < SenA && Kij < SenB)
         return "below";
     }
   if(IchiFilterType == 7)
     {
      if(Ten>SenA && Ten > SenB)
         return "above";
      if(Ten<SenA && Ten < SenB)
         return "below";
     }
   if(IchiFilterType == 8)
     {
      if(Kij > SenA && Kij > SenB)
         return "above";
      if(Kij < SenA && Kij < SenB)
         return "below";
     }
   return "InCloud";
  }

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
