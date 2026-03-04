//+------------------------------------------------------------------+
//|                                                      ProjectName |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
CTrade trade;
CPositionInfo posinfo;
COrderInfo ordinfo;


input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;
input double lots = 0.01;
input bool CompoundingInterestswitch = false;
input int Risk = 40;
input bool ParameterSwitching = false;
input int Volatility = 14; // used as RSI period
input int Stoploss = 300;
input int Profit = 300;
input double Pointdifferencelimit = 50.0;
input bool DisplaySwitch = true;
input int Magic = 9090;
input string CommentName = "TopBottom";

int Volatilitythreshold = Volatility;
int StopLoss_points = Stoploss;
int TakeProfit_points = Profit;
int MaxBandWidth = 1000;
int MinBandWidth = 150;
double calculatedLotSize = 0.0;

double accountBalanceDivisor = 1000000;
int maxSlippage = 30;
bool tradingAllowed = true;

int rsiThreshold = 30;   // same idea as wprThreshold
int handleBollinger;
int handleRSI;

int startTradingHour1 = 20;
int endTradingHour1 = 24;
int startTradingHour2 = 0;
int endTradingHour2 = 3;
datetime lastSignalTime = 0;
datetime lastBarTime = 0;

int buyPositionCount = 0;
int sellPositionCount = 0;

double BuyPrice = 0.0;
double SellPrice = 0.0;

double totalBuyProfit = 0.0;
double totalSellProfit = 0.0;


//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(Magic);
   handleBollinger = iBands(_Symbol, Timeframe, 20, 0, 2.0, PRICE_CLOSE);
   handleRSI       = iRSI(_Symbol, Timeframe, Volatilitythreshold, PRICE_CLOSE);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsNewbar())
      return;
   double upperBollingerBand, lowerBollingerBand;
   double rsiValue;
   double indBuffer[];
   ArraySetAsSeries(indBuffer, true);
   ArrayResize(indBuffer, 1);
   CopyBuffer(handleBollinger, 1, 0, 1, indBuffer);
   upperBollingerBand = indBuffer[0];
   CopyBuffer(handleBollinger, 2, 0, 1, indBuffer);
   lowerBollingerBand = indBuffer[0];
   CopyBuffer(handleRSI, 0, 0, 1, indBuffer);
   rsiValue = indBuffer[0];
   tradingAllowed = (SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) <= Pointdifferencelimit);
   lastBarTime = iTime(_Symbol, PERIOD_M1, 1);
   if(CompoundingInterestswitch)
     {
      calculatedLotSize = NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY) * Risk / accountBalanceDivisor, 2);
     }
   else
     {
      calculatedLotSize = lots;
     }
   double Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double Point = _Point;
   if(sellPositionCount + buyPositionCount < 1 && tradingAllowed)
     {
      // BUY → RSI Oversold
      //if(rsiValue > (100 - rsiThreshold) && lastSignalTime != lastBarTime)
      if(rsiValue < rsiThreshold && lastSignalTime != lastBarTime)
        {
         double sl = NormalizeDouble(Ask - StopLoss_points * Point, _Digits);
         double tp = NormalizeDouble(Ask + TakeProfit_points * Point, _Digits);
         trade.Buy(calculatedLotSize, _Symbol, Ask, sl, tp, CommentName);
         lastSignalTime = lastBarTime;
        }
      // SELL → RSI Overbought
      //if(rsiValue < rsiThreshold && lastSignalTime != lastBarTime)
      if(rsiValue > (100 - rsiThreshold) && lastSignalTime != lastBarTime)
        {
         double sl = NormalizeDouble(Bid + StopLoss_points * Point, _Digits);
         double tp = NormalizeDouble(Bid - TakeProfit_points * Point, _Digits);
         trade.Sell(calculatedLotSize, _Symbol, Bid, sl, tp, CommentName);
         lastSignalTime = lastBarTime;
        }
     }
// Close BUY if RSI crosses opposite
//   if(buyPositionCount > 0 && (rsiValue > 50 || rsiValue <20) )
//   {
//      for(int i=PositionsTotal()-1;i>=0;i--)
//      {
//         if(posinfo.SelectByIndex(i))
//         {
//            if(posinfo.Symbol()==_Symbol && posinfo.Magic()==Magic)
//            {
//               if(posinfo.PositionType()==POSITION_TYPE_BUY)
//                  trade.PositionClose(posinfo.Ticket(),maxSlippage);
//            }
//         }
//      }
//   }
//
//   // Close SELL if RSI crosses opposite
//   if(sellPositionCount > 0 && (rsiValue < 50 || rsiValue > 80))
//   {
//      for(int i=PositionsTotal()-1;i>=0;i--)
//      {
//         if(posinfo.SelectByIndex(i))
//         {
//            if(posinfo.Symbol()==_Symbol && posinfo.Magic()==Magic)
//            {
//               if(posinfo.PositionType()==POSITION_TYPE_SELL)
//                  trade.PositionClose(posinfo.Ticket(),maxSlippage);
//            }
//         }
//      }
//   }
   UpdatePositions();
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
int UpdatePositions()
  {
   buyPositionCount = 0;
   sellPositionCount = 0;
   totalBuyProfit = 0;
   totalSellProfit = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      posinfo.SelectByIndex(i);
      if(posinfo.Symbol() == _Symbol && posinfo.Magic() == Magic)
        {
         if(posinfo.PositionType() == POSITION_TYPE_BUY)
           {
            buyPositionCount++;
            BuyPrice = posinfo.PriceOpen();
           }
         else
            if(posinfo.PositionType() == POSITION_TYPE_SELL)
              {
               sellPositionCount++;
               SellPrice = posinfo.PriceOpen();
              }
        }
     }
   return 0;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
