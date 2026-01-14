//+------------------------------------------------------------------+
//|                                                 Scalping eaA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
// this ea very thight stoploss
// this we added new filter
// video link : https://youtu.be/9zoeRuDK5ec?si=AGtPN7FvdeBIvPHB
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade/Trade.mqh>


CTrade trade;
CPositionInfo pos;
COrderInfo ord;



input group "=== Common Trading Inputs ==="
input double RiskPercent = 2;
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;
input int BarsN = 50;

input int ExpirationBars = 100;
enum TradeHour {Inactive = 0, _0100 = 1, _0200 = 2, _0300 = 3, _0400 = 4, _0500 = 5, _0600 = 6, _0700 = 7, _0800 = 8, _0900 = 9, _1000 = 10, _1100 = 11, _1200 = 12, _1300 = 13, _1400 = 14, _1500 = 15, _1600 = 16, _1700 = 17, _1800 = 18, _1900 = 19, _2000 = 20, _2100 = 21, _2200 = 22, _2300 = 23};
input TradeHour SHInput = 7; //007
input TradeHour EHInput = 21;  //021
int SHChoice;
int EHChoice;
input int InpMagic = 1001;
input string TradeComment = "No Shenanigans";
double OrderDistPoints = 100;
double Tppoints, Slpoints, TslTriggerPoints, TslPoints;


int handleRSI;
input color ChartColorTradingOff = clrPink;
input color ChartColorTradingOn = clrBlack;
bool Tradingenabled = true;
input bool HideIndicators = false;
string TradingEnabledComm = "";


input group "===Gold Related Input ==="
input double TPasPctGold = 0.2;
input double SLasPctGold = 0.2;
input double TSLasPctofTPGold = 5;
input double TSLTgrasPctofTPGold = 7;


input group "===News Filter ==="
input bool NewsFilterOn = true;
enum sep_dropdown {commo = 0, semicolon = 1};
input sep_dropdown separater = 0;
input string KeyNews = "BCB,NFP,JOLTX,Nonfarm,PMI,Retail,GDP,Confidence,Interest Rate";
input string NewsCurrencies = "USD,GBP,EUR,JPY";
input int DaysNewsLookup = 100;
input int StopsBeforeMin = 15;
input int StartTradingMin = 15;
bool TrDisableNews = false;


input group "===RSI Filter ==="

input bool RSIfilterOn = true;
input ENUM_TIMEFRAMES RSITimeframe = PERIOD_H1;
input double RSILowerLvl  = 20;
input double RSIUpperlvl  = 80;
input int RSI_MA = 14;
input ENUM_APPLIED_PRICE RSI_AppPrice = PRICE_MEDIAN;

ushort sep_code;
string Newstoavoid[];
datetime LastNewsAvoided;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   trade.SetExpertMagicNumber(InpMagic);

   SHChoice = SHInput;
   EHChoice = EHInput;

 

  
   if(HideIndicators == true)
      TesterHideIndicators(true);
   handleRSI = iRSI(_Symbol, RSITimeframe, RSI_MA, RSI_AppPrice);
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   TrailStop();

   if(IsRSIFilter())
     {
      CloseAllOrders();
      Tradingenabled = false;
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, ChartColorTradingOff);
      if(TradingEnabledComm != "Printed")
        {
         Print(TradingEnabledComm);
        }
      TradingEnabledComm = "Printed";
      return;
     }

   Tradingenabled = true;
   if(TradingEnabledComm != "")
     {
      Print("Trading is again enabled");
      TradingEnabledComm = "";
     }
     
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, ChartColorTradingOn);
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
   
          double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      Tppoints = ask * TPasPctGold;
      Slpoints = ask * SLasPctGold;
      OrderDistPoints = Tppoints / 2;
      TslPoints =  Tppoints * TSLasPctofTPGold / 100;
      TslTriggerPoints = Tppoints * TSLTgrasPctofTPGold / 100;
     

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
   trade.BuyStop(0.01, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration);
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
   trade.SellStop(0.01, entry, _Symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration);
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
               if(bid - pos.PriceOpen() > TslTriggerPoints * _Point)
                 {
                  tp = pos.TakeProfit();
                  sl = bid - (TslPoints * _Point);
                  Print("TslPoints : ", TslPoints);
                  Print("TslPoints *Points : ", TslPoints * _Point);
                  Print("Points : ", _Point);
                  if(sl > pos.StopLoss() && sl != 0)
                    {
                     trade.PositionModify(ticket, sl, tp);
                    }
                 }
              }
            else
               if(pos.PositionType() == POSITION_TYPE_SELL)
                 {
                  if(ask + (TslTriggerPoints * _Point) < pos.PriceOpen())
                    {
                     tp = pos.TakeProfit();
                     sl = ask + (TslPoints * _Point);
                     Print("TslPoints : ", TslPoints);
                     Print("TslPoints *Points : ", TslPoints * _Point);
                     Print("Points : ", _Point);
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
//|                                                                  |
//+------------------------------------------------------------------+
bool ISUpcomingNews()
  {
   if(NewsFilterOn == false)
      return(false);
   if(TrDisableNews && TimeCurrent() - LastNewsAvoided < StartTradingMin * PeriodSeconds(PERIOD_M1))
      return true;

   TrDisableNews = false;

   string sep;
   switch(separater)
     {
      case 0:
         sep = ",";
         break;
      case 1:
         sep = ";";
     }
   sep_code = StringGetCharacter(sep, 0);
   int k = StringSplit(KeyNews, sep_code, Newstoavoid);

   MqlCalendarValue values[];
   datetime starttime = TimeCurrent();
   datetime endtime = starttime + PeriodSeconds(PERIOD_D1) * DaysNewsLookup;

   CalendarValueHistory(values, starttime, endtime, NULL, NULL);

   for(int i = 0; i < ArraySize(values); i++)
     {
      MqlCalendarEvent event;
      CalendarEventById(values[i].event_id, event);
      MqlCalendarCountry country;
      CalendarCountryById(event.country_id, country);

      if(StringFind(NewsCurrencies, country.currency) < 0)
         continue;

      for(int j = 0; j < k; j++)
        {
         string currnetevent = Newstoavoid[j];
         string currnetnews = event.name;

         if(StringFind(currnetnews, currnetevent) < 0)
            continue;

         Comment("Next News: ", country.currency, " : ", event.name, "->", values[i].time);
         if(values[i].time - TimeCurrent() < StopsBeforeMin * PeriodSeconds(PERIOD_M1))
           {
            LastNewsAvoided = values[i].time;
            TrDisableNews = true;
            if(TradingEnabledComm == "" || TradingEnabledComm != "Printed")
              {
               TradingEnabledComm = "Trading is disabled due to upcoming news : " + event.name;
              }
            return true;
           }
         return false;
        }

     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsRSIFilter()
  {
   if(RSIfilterOn == false)
      return(false);

   double RSI[];

   CopyBuffer(handleRSI, MAIN_LINE, 0, 1, RSI);
   ArraySetAsSeries(RSI, true);

   double RSInow = RSI[0];
   Comment("RSI = ", RSInow);

   if(RSInow > RSIUpperlvl || RSInow < RSILowerLvl)
     {
      if(TradingEnabledComm == ""  || TradingEnabledComm != "Printed")
        {
         TradingEnabledComm = "Trading is disabled due to RSI Filter";
        }
      return(true);
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
