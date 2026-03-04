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
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;
input double lots = 0.01;
input int BarsN = 50;
input int ExpirationBars = 100;
input int InpMagic = 1001;
input string TradeComment = "No Shenanigans";
double OrderDistPoints = 100;

input double takeprofit = 500;
input double stoploss = 200;
int handleRSI;
input color ChartColorTradingOff = clrPink;
input color ChartColorTradingOn = clrBlack;
bool Tradingenabled = true;
input bool HideIndicators = false;
string TradingEnabledComm = "";
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

input double TslTriggerPoints = 300.00;

ushort sep_code;
string Newstoavoid[];
datetime LastNewsAvoided;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagic);
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
   if(!IsNewbar())
     {
      return ;
     }
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
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
//|                                                                  |
//+------------------------------------------------------------------+
void TrailStop()
  {
   double sl = 0;
   double tp = 0;
   double profit = 0;
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
               profit = pos.Profit();
               tp = pos.TakeProfit();
               double openPrice = pos.PriceOpen();
               double currntPoint = bid - openPrice;
               if(profit > 3.00)
                 {
                  sl = bid - (100 * _Point);
                  if(sl > pos.StopLoss() && sl != 0)
                    {
                     trade.PositionModify(ticket, sl, 0);
                    }
                 }
              }
            else
               if(pos.PositionType() == POSITION_TYPE_SELL)
                 {
                  tp = pos.TakeProfit();
                  profit = pos.Profit();
                  sl = ask + (100 * _Point);
                  double openPrice = pos.PriceOpen();
                  double currntPoint = bid - openPrice;
                  if(profit > 3.00)
                    {
                     if(sl < pos.StopLoss() && sl != 0)
                       {
                        trade.PositionModify(ticket, sl, 0);
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
void executeBuy(double entry)
  {
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(ask > entry - OrderDistPoints * _Point)
     {
      return;
     }
   double tp = entry + takeprofit * _Point;
   double sl = entry - stoploss * _Point;
   datetime expiration = iTime(_Symbol, Timeframe, 0) + ExpirationBars * PeriodSeconds(Timeframe);
   bool result = trade.BuyStop(lots, entry, _Symbol, sl, 0, ORDER_TIME_SPECIFIED, expiration);
   if(result)
     {
      string name = "BuyStopLine_" + IntegerToString(TimeCurrent());
      ObjectCreate(0, name, OBJ_TREND, 0,
                   TimeCurrent(), entry,
                   expiration, entry);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void executeSell(double entry)
  {
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   Print("Gap for Sell :" + (entry + OrderDistPoints * _Point));
   if(bid < entry + OrderDistPoints * _Point)
     {
      return;
     }
   double tp = entry - takeprofit * _Point;
   double sl = entry + stoploss * _Point;
   datetime expiration = iTime(_Symbol, Timeframe, 0) + ExpirationBars * PeriodSeconds(Timeframe);
   bool result = trade.SellStop(lots, entry, _Symbol, sl, 0, ORDER_TIME_SPECIFIED, expiration);
   if(result)
     {
      string name = "SellStopLine_" + IntegerToString(TimeCurrent());
      ObjectCreate(0, name, OBJ_TREND, 0,
                   TimeCurrent(), entry,
                   expiration, entry);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
     }
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
