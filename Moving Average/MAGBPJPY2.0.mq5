//+------------------------------------------------------------------+
//| Momentum Breakout EA - Improved Version                         |
//| Optimized for GBPJPY M15                                        |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>

CTrade trade;
CPositionInfo posinfo;

//------------------- INPUTS ---------------------------------------//
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT;

input int InpMAFast = 50;
input int InpMASlow = 200;
input ENUM_MA_METHOD MA_Mode = MODE_SMA;
input ENUM_APPLIED_PRICE MA_AppliedPrice = PRICE_CLOSE;

input int InpRSI = 14;
input int InpATR = 14;
input int BreakoutLookback = 20;

input double ATR_SL_Multiplier    = 1.5;
input double ATR_TP_Multiplier    = 3.0;
input double ATR_Trail_Multiplier = 1.0;

input double RiskPercent = 1.0;
input double MaxSpread   = 30;
input ulong  InpMagic    = 10;

//------------------- GLOBAL VARIABLES ------------------------------//
int handleMAFast, handleMASlow;
int handleRSI, handleATR;

double IndBuffer[2];
double maFast, maSlow;
double rsiValue, atrValue;

int BuyTotal = 0;
int SellTotal = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagic);

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
   if(!IsNewBar()) return;
   if(!IsTradingTime()) return;
   if(!AssignIndicatorValues()) return;

   CheckPosition();
   CloseOnTrendChange();
   PlaceOrder();
   //TrailPosition();
}
//+------------------------------------------------------------------+
bool AssignIndicatorValues()
{
   if(CopyBuffer(handleMAFast, 0, 1, 1, IndBuffer) <= 0) return false;
   maFast = IndBuffer[0];

   if(CopyBuffer(handleMASlow, 0, 1, 1, IndBuffer) <= 0) return false;
   maSlow = IndBuffer[0];

   if(CopyBuffer(handleRSI, 0, 1, 1, IndBuffer) <= 0) return false;
   rsiValue = IndBuffer[0];

   if(CopyBuffer(handleATR, 0, 1, 1, IndBuffer) <= 0) return false;
   atrValue = IndBuffer[0];

   return true;
}
//+------------------------------------------------------------------+
void PlaceOrder()
{
   double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) -
                    SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;

   if(spread > MaxSpread) return;

   double slDistance = atrValue * ATR_SL_Multiplier;
   double lot = CalculateLot(slDistance);

   // BUY
   if(maFast > maSlow &&
      //rsiValue > 55 &&
      //IsBreakoutBuy() &&
      BuyTotal == 0)
   {
      double entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl = entry - slDistance;
      double tp = entry + (atrValue * ATR_TP_Multiplier);

      trade.Buy(lot, _Symbol, entry, sl, tp);
   }

   // SELL
   if(maFast < maSlow &&
      //rsiValue < 45 &&
      //IsBreakoutSell() &&
      SellTotal == 0)
   {
      double entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl = entry + slDistance;
      double tp = entry - (atrValue * ATR_TP_Multiplier);

      trade.Sell(lot, _Symbol, entry, sl, tp);
   }
}
//+------------------------------------------------------------------+
bool IsBreakoutBuy()
{
   int index = iHighest(_Symbol, TimeFrame, MODE_HIGH, BreakoutLookback, 1);
   double highest = iHigh(_Symbol, TimeFrame, index);

   double close1 = iClose(_Symbol, TimeFrame, 1);
   double close2 = iClose(_Symbol, TimeFrame, 2);

   return (close1 > highest && close2 <= highest);
}
//+------------------------------------------------------------------+
bool IsBreakoutSell()
{
   int index = iLowest(_Symbol, TimeFrame, MODE_LOW, BreakoutLookback, 1);
   double lowest = iLow(_Symbol, TimeFrame, index);

   double close1 = iClose(_Symbol, TimeFrame, 1);
   double close2 = iClose(_Symbol, TimeFrame, 2);

   return (close1 < lowest && close2 >= lowest);
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
                  trade.PositionModify(posinfo.Ticket(), newSL, posinfo.TakeProfit());
            }

            if(posinfo.PositionType() == POSITION_TYPE_SELL)
            {
               newSL = SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                       + (atrValue * ATR_Trail_Multiplier);

               if(newSL < posinfo.StopLoss() || posinfo.StopLoss() == 0)
                  trade.PositionModify(posinfo.Ticket(), newSL, posinfo.TakeProfit());
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
void CloseOnTrendChange()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(posinfo.SelectByIndex(i))
      {
         if(posinfo.Symbol() == _Symbol &&
            posinfo.Magic() == InpMagic)
         {
            if(posinfo.PositionType() == POSITION_TYPE_BUY &&
               maFast < maSlow)
               trade.PositionClose(posinfo.Ticket());

            if(posinfo.PositionType() == POSITION_TYPE_SELL &&
               maFast > maSlow)
               trade.PositionClose(posinfo.Ticket());
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
bool IsTradingTime()
{
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);

   if(tm.hour >= 7 && tm.hour <= 17) // London session
      return true;

   return false;
}
//+------------------------------------------------------------------+
bool IsNewBar()
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
double CalculateLot(double slDistance)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = balance * RiskPercent / 100.0;

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lot = riskAmount / (slDistance / _Point * tickValue);

   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lot = MathMax(minLot, MathMin(maxLot, lot));
   lot = NormalizeDouble(lot / step, 0) * step;

   return lot;
}
//+------------------------------------------------------------------+