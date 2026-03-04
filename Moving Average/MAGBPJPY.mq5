//+------------------------------------------------------------------+
//  Momentum Breakout EA - GBPJPY M15
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
CTrade trade;
CPositionInfo posinfo;
COrderInfo ordinfo;

//------------------- INPUTS ---------------------------------------//
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT;

input int InpMAFast = 50;
input int InpMASlow = 200;
input ENUM_MA_METHOD MA_Mode = MODE_SMA;
input ENUM_APPLIED_PRICE MA_AppliedPrice = PRICE_CLOSE;

input int    InpRSI = 14;
input int    InpATR = 14;
input int    BreakoutLookback = 20;
input int tppoint = 200;
input int slpoint = 100;

input double ATR_SL_Multiplier    = 1.5;
input double ATR_Trail_Multiplier = 1.0;
input double MaxSpread = 40;

input double lots = 0.01;
input ulong  InpMagic = 10;

//------------------- GLOBAL VARIABLES ------------------------------//
int handleMAFast, handleMASlow;
int handleRSI, handleATR;

double IndBuffer[1];
double maFast, maSlow;
double rsiValue, atrValue;

int BuyTotal = 0;
int SellTotal = 0;

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagic);
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   handleMAFast = iMA(_Symbol, TimeFrame, InpMAFast, 1, MA_Mode, MA_AppliedPrice);
   handleMASlow = iMA(_Symbol, TimeFrame, InpMASlow, 1, MA_Mode, MA_AppliedPrice);
   handleRSI    = iRSI(_Symbol, TimeFrame, InpRSI, PRICE_CLOSE);
   handleATR    = iATR(_Symbol, TimeFrame, InpATR);
   if(handleMAFast == INVALID_HANDLE ||
      handleMASlow == INVALID_HANDLE ||
      handleRSI    == INVALID_HANDLE ||
      handleATR    == INVALID_HANDLE)
     {
      Print("Indicator handle creation failed");
      return INIT_FAILED;
     }
   return INIT_SUCCEEDED;
  }
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(handleMAFast);
   IndicatorRelease(handleMASlow);
   IndicatorRelease(handleRSI);
   IndicatorRelease(handleATR);
  }
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsNewbar())
      return;
   if(!AssignIndicatorValues())
      return;
   CheckPosition();
   CloseOpenOrder();
   PlaceOrder();
   TrailPosition();//---//---
   
//   
  }
//+------------------------------------------------------------------+
bool AssignIndicatorValues()
  {
   if(CopyBuffer(handleMAFast, 0, 1, 1, IndBuffer) <= 0)
      return false;
   maFast = IndBuffer[0];
   if(CopyBuffer(handleMASlow, 0, 1, 1, IndBuffer) <= 0)
      return false;
   maSlow = IndBuffer[0];
   if(CopyBuffer(handleRSI, 0, 1, 1, IndBuffer) <= 0)
      return false;
   rsiValue = IndBuffer[0];
   if(CopyBuffer(handleATR, 0, 1, 1, IndBuffer) <= 0)
      return false;
   atrValue = IndBuffer[0];
   return true;
  }
//+------------------------------------------------------------------+
void PlaceOrder()
  {
//   double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) -
//                    SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
//
//   if(spread > MaxSpread)
//      return;
// BUY
   if(maFast > maSlow &&
      //rsiValue > 60 &&
      IsBreakoutBuy() &&
      BuyTotal == 0)
     {
      double entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      //double sl = entry - (atrValue * ATR_SL_Multiplier);
      double sl = entry - (slpoint* _Point);
       double tp = entry + (tppoint * _Point);
      trade.Buy(lots, _Symbol, entry, sl, tp);
     }
// SELL
   if(maFast < maSlow &&
      //rsiValue < 40 &&
      IsBreakoutSell() &&
      SellTotal == 0)
     {
      double entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      //double sl = entry + (atrValue * ATR_SL_Multiplier);
       double sl = entry + (slpoint* _Point);
       double tp = entry - (tppoint * _Point);
      trade.Sell(lots, _Symbol, entry, sl, tp);
     }
  }
//+------------------------------------------------------------------+
bool IsBreakoutBuy()
  {
   int highestIndex = iHighest(_Symbol, TimeFrame, MODE_HIGH, BreakoutLookback, 2);
   double highest = iHigh(_Symbol, TimeFrame, highestIndex);
   double close1  = iClose(_Symbol, TimeFrame, 1);
   bool r = close1 > highest;
   return r;
  }
//+------------------------------------------------------------------+
bool IsBreakoutSell()
  {
   int lowestIndex = iLowest(_Symbol, TimeFrame, MODE_LOW, BreakoutLookback, 2);
   double lowest = iLow(_Symbol, TimeFrame, lowestIndex);
   double close1 = iClose(_Symbol, TimeFrame, 1);
   bool r = close1 < lowest;
   return r;
  }
//+------------------------------------------------------------------+
void TrailPosition()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(posinfo.SelectByIndex(i))
        {
         if(posinfo.Symbol() == _Symbol &&
            posinfo.Magic()  == InpMagic)
           {
            double newSL;
            if(posinfo.PositionType() == POSITION_TYPE_BUY)
              {
               newSL = SymbolInfoDouble(_Symbol, SYMBOL_BID)
                       - (atrValue * ATR_Trail_Multiplier);
               if(newSL > posinfo.StopLoss())
                  trade.PositionModify(posinfo.Ticket(), newSL, 0);
              }
            if(posinfo.PositionType() == POSITION_TYPE_SELL)
              {
               newSL = SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                       + (atrValue * ATR_Trail_Multiplier);
               if(newSL < posinfo.StopLoss() || posinfo.StopLoss() == 0)
                  trade.PositionModify(posinfo.Ticket(), newSL, 0);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
void CloseOpenOrder()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(posinfo.SelectByIndex(i))
        {
         if(posinfo.Magic() == InpMagic &&
            posinfo.Symbol() == _Symbol)
           {
            ulong ticket = posinfo.Ticket();
            if(posinfo.PositionType() == POSITION_TYPE_BUY)
              {
               if(maFast < maSlow)
                  trade.PositionClose(ticket);
              }
            if(posinfo.PositionType() == POSITION_TYPE_SELL)
              {
               if(maFast > maSlow)
                  trade.PositionClose(ticket);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
void CheckPosition()
  {
   BuyTotal = 0;
   SellTotal = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(posinfo.SelectByIndex(i))
        {
         if(posinfo.Symbol() == _Symbol &&
            posinfo.Magic() == InpMagic)
           {
            if(posinfo.PositionType() == POSITION_TYPE_BUY)
               BuyTotal++;
            if(posinfo.PositionType() == POSITION_TYPE_SELL)
               SellTotal++;
           }
        }
     }
  }
//+------------------------------------------------------------------+
bool IsNewbar()
  {
   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol, TimeFrame, 0);
   if(previousTime != currentTime)
     {
      previousTime = currentTime;
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
