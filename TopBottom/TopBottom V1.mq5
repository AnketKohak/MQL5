//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
CTrade trade;
CPositionInfo posinfo;
COrderInfo ordinfo;
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;
input double lots = 0.01;                     // Lot size for trading
input bool CompoundingInterestswitch = false; // Risk in basis points instead of fixed lots?
input int Risk = 40;
input bool ParameterSwitching = false; // Switch between fixed and dynamic parameters
input int Volatility = 110;
input int Stoploss = 800;
input int Profit = 300;
input double Pointdifferencelimit = 50.0; // Maximum allowed spread in points
input bool DisplaySwitch = true;
input int Magic = 9090;
input string CommentName = "TopBottom";
input int wprThreshold = 20 ;
int Volatilitythreshold = Volatility;
int StopLoss_points = Stoploss;
int TakeProfit_points = Profit;
int MaxBandWidth = 1000;
int MinBandWidth = 150;
double calculatedLotSize = 0.0;
bool isBuyOn = true;
bool isSellOn = true;


double accountBalanceDivisor = 1000000;
int maxSlippage = 30;
bool tradingAllowed = true;


int handleBollinger;
int handleWPR;

int startTradingHour1 = 20;
int endTradingHour1 = 24;
int startTradingHour2 = 0;
int endTradingHour2 = 3;
datetime lastSignalTime = 0;
datetime lastBarTime = 0;
MqlDateTime BrokerTime, GMTTime;

int buyPositionCount = 0;
int sellPositionCount = 0;

double totalBuyLots = 0.0;
double totalSellLots = 0.0;
double BuyPrice = 0.0;
double SellPrice = 0.0;
double buyStopLoss = 0.0;
double sellStopLoss = 0.0;

double totalBuyProfit = 0.0;
double totalSellProfit = 0.0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(Magic);
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   if(ParameterSwitching)
     {
      if(StringFind(_Symbol, "CHFSGD", 0) < 0 && StringFind(_Symbol, "GBPSGD", 0) < 0)
        {
         Volatilitythreshold = Volatility;
         StopLoss_points = Stoploss;
         TakeProfit_points = Profit;
         MaxBandWidth = 1000;
         MinBandWidth = 150;
        }
      else
        {
         Volatilitythreshold = 35;
         StopLoss_points = Stoploss;
         TakeProfit_points = Profit;
         MaxBandWidth = 1000;
         MinBandWidth = 0;
        }
     }
   else
     {
      if(StringFind(_Symbol, "GBPCAD", 0) >= 0)
        {
         Volatilitythreshold = 110;
         StopLoss_points = 800;
         TakeProfit_points = 300;
         MaxBandWidth = 1000;
         MinBandWidth = 150;
        }
      if(StringFind(_Symbol, "EURSGD", 0) >= 0)
        {
         Volatilitythreshold = 140;
         StopLoss_points = 700;
         TakeProfit_points = 160;
         MaxBandWidth = 1000;
         MinBandWidth = 150;
        }
      if(StringFind(_Symbol, "GBPCHF", 0) >= 0)
        {
         Volatilitythreshold = 110;
         StopLoss_points = 600;
         TakeProfit_points = 200;
         MaxBandWidth = 1000;
         MinBandWidth = 150;
        }
      if(StringFind(_Symbol, "CHFSGD", 0) >= 0)
        {
         Volatilitythreshold = 60;
         StopLoss_points = 700;
         TakeProfit_points = 160;
         MaxBandWidth = 1000;
         MinBandWidth = 0;
        }
      if(StringFind(_Symbol, "GBPSGD", 0) >= 0)
        {
         Volatilitythreshold = 35;
         StopLoss_points = 700;
         TakeProfit_points = 160;
         MaxBandWidth = 1000;
         MinBandWidth = 0;
        }
     }
   TesterHideIndicators(false);
   handleBollinger = iBands(_Symbol, Timeframe, 20, 0, 2.0, PRICE_CLOSE);
   handleWPR = iWPR(_Symbol, Timeframe, Volatilitythreshold);
   if(DisplaySwitch)
     {
      CreateDisplayPanel();
     }
   return (INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, "TB_");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   double upperBollingerBand, lowerBollingerBand, indBuffer[];
   CopyBuffer(handleBollinger, 1, 0, 1, indBuffer);
   upperBollingerBand = indBuffer[0];
   CopyBuffer(handleBollinger, 2, 0, 1, indBuffer);
   lowerBollingerBand = indBuffer[0];
//WPR
   double wprBuffer[];
   ArraySetAsSeries(wprBuffer, true);
   CopyBuffer(handleWPR, 0, 0, 3, wprBuffer);
   double currentWPR  = wprBuffer[0];
   double lastWPR     = wprBuffer[1];
   double previousWPR = wprBuffer[2];
   if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) <= Pointdifferencelimit)
     {
      tradingAllowed = true;
     }
   else
     {
      tradingAllowed = false;
     }
   lastBarTime = iTime(_Symbol, Timeframe, 1);
   if(CompoundingInterestswitch)
     {
      calculatedLotSize = AccountInfoDouble(ACCOUNT_EQUITY) * Risk / accountBalanceDivisor;
      calculatedLotSize = NormalizeDouble(calculatedLotSize, 2);
     }
   else
     {
      calculatedLotSize = lots;
     }
   TimeCurrent(BrokerTime);
   TimeGMT(GMTTime);
   double Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double Point = _Point;
   if(MQLInfoInteger(MQL_TESTER))
     {
      if((BrokerTime.hour >= startTradingHour1 && BrokerTime.hour <= endTradingHour1) ||
         (BrokerTime.hour >= startTradingHour2 && BrokerTime.hour <= endTradingHour2))
        {
         if(upperBollingerBand - lowerBollingerBand < MaxBandWidth * Point)
           {
            double dif = upperBollingerBand - lowerBollingerBand;
            double diffpoint = MinBandWidth * Point;
            if(upperBollingerBand - lowerBollingerBand > MinBandWidth * Point)
              {
               if(sellPositionCount + buyPositionCount < 1 && tradingAllowed == 1)
                 {
                  // Buy Logic
                  if(isBuyOn)
                    {
                     if(previousWPR < wprThreshold - 100 &&  lastWPR >wprThreshold - 100  && lastSignalTime != lastBarTime)
                       {
                        double margin;
                        if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, calculatedLotSize, Ask, margin) &&
                           AccountInfoDouble(ACCOUNT_MARGIN_FREE) > margin)
                          {
                           double sl = NormalizeDouble(Ask - StopLoss_points * Point, _Digits);
                           trade.Buy(calculatedLotSize, _Symbol, Ask, sl, 0, CommentName);
                           lastSignalTime = lastBarTime;
                           isBuyOn = false;
                           isSellOn = true;
                          }
                       }
                    }
                  // Sell Logic
                  if(isSellOn)
                    {
                     if(previousWPR > -wprThreshold && lastWPR < -wprThreshold &&  lastSignalTime != lastBarTime)
                       {
                        double margin;
                        if(OrderCalcMargin(ORDER_TYPE_SELL, _Symbol, calculatedLotSize, Bid, margin) &&
                           AccountInfoDouble(ACCOUNT_MARGIN_FREE) > margin)
                          {
                           double sl = NormalizeDouble(Bid + StopLoss_points * Point, _Digits);
                           trade.Sell(calculatedLotSize, _Symbol, Bid, sl, 0, CommentName);
                           lastSignalTime = lastBarTime;
                           isBuyOn = true;
                           isSellOn = false;
                          }
                       }
                    }
                 }
              }
           }
        }
     }
   else
     {
      if(GMTTime.hour >= 18 || GMTTime.hour <= 1)
         if(upperBollingerBand - lowerBollingerBand < MaxBandWidth * Point)
           {
            if(upperBollingerBand - lowerBollingerBand > MinBandWidth * Point)
              {
               if(sellPositionCount + buyPositionCount < 1 && tradingAllowed == 1)
                 {
                  // Buy Logic
                  if(currentWPR < wprThreshold - 100 && lastSignalTime != lastBarTime)
                    {
                     double margin;
                     if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, calculatedLotSize, Ask, margin) &&
                        AccountInfoDouble(ACCOUNT_MARGIN_FREE) > margin)
                       {
                        double sl = NormalizeDouble(Ask - StopLoss_points * Point, _Digits);
                        trade.Buy(calculatedLotSize, _Symbol, Ask, sl, 0, CommentName);
                        lastSignalTime = lastBarTime;
                       }
                    }
                  // Sell Logic
                  if(currentWPR > -wprThreshold && lastSignalTime != lastBarTime)
                    {
                     double margin;
                     if(OrderCalcMargin(ORDER_TYPE_SELL, _Symbol, calculatedLotSize, Bid, margin) &&
                        AccountInfoDouble(ACCOUNT_MARGIN_FREE) > margin)
                       {
                        double sl = NormalizeDouble(Bid + StopLoss_points * Point, _Digits);
                        trade.Sell(calculatedLotSize, _Symbol, Bid, sl, 0, CommentName);
                        lastSignalTime = lastBarTime;
                       }
                    }
                 }
              }
           }
     }
   if(buyPositionCount > 0 && tradingAllowed == 1 && currentWPR > (-wprThreshold))
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(posinfo.SelectByIndex(i))
           {
            if(posinfo.Symbol() == _Symbol && posinfo.Magic() == Magic)
              {
               if(posinfo.PositionType() == POSITION_TYPE_BUY)
                 {
                  trade.PositionClose(posinfo.Ticket(), maxSlippage);
                 }
              }
           }
        }
     }
   if(sellPositionCount > 0 && tradingAllowed == 1 && currentWPR < (wprThreshold - 100))
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(posinfo.SelectByIndex(i))
           {
            if(posinfo.Symbol() == _Symbol && posinfo.Magic() == Magic)
              {
               if(posinfo.PositionType() == POSITION_TYPE_SELL)
                 {
                  trade.PositionClose(posinfo.Ticket(), maxSlippage);
                 }
              }
           }
        }
     }
   if(buyPositionCount > 0 && tradingAllowed == 1 && (Bid - BuyPrice) > (TakeProfit_points * _Point))
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(posinfo.SelectByIndex(i))
           {
            if(posinfo.Symbol() == _Symbol && posinfo.Magic() == Magic)
              {
               if(posinfo.PositionType() == POSITION_TYPE_BUY)
                 {
                  trade.PositionClose(posinfo.Ticket(), maxSlippage);
                 }
              }
           }
        }
     }
   if(sellPositionCount > 0 && tradingAllowed == 1 && (SellPrice - Ask) > (TakeProfit_points * _Point))
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(posinfo.SelectByIndex(i))
           {
            if(posinfo.Symbol() == _Symbol && posinfo.Magic() == Magic)
              {
               if(posinfo.PositionType() == POSITION_TYPE_SELL)
                 {
                  trade.PositionClose(posinfo.Ticket(), maxSlippage);
                 }
              }
           }
        }
     }
   UpdatePositions();
   UpdatePanelData();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int UpdatePositions()
  {
   buyPositionCount = 0;
   sellPositionCount = 0;
   totalBuyLots = 0.0;
   totalSellLots = 0.0;
   totalBuyProfit = 0.0;
   totalSellProfit = 0.0;
   BuyPrice = 0.0;
   SellPrice = 0.0;
   buyStopLoss = 0.0;
   sellStopLoss = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      posinfo.SelectByIndex(i);
      if(posinfo.Symbol() == _Symbol && posinfo.Magic() == Magic)
        {
         if(posinfo.PositionType() == POSITION_TYPE_BUY)
           {
            ++buyPositionCount;
            totalBuyLots += posinfo.Volume();
            totalBuyProfit += posinfo.Profit() + posinfo.Swap() + posinfo.Commission();
            BuyPrice = posinfo.PriceOpen();
            buyStopLoss = posinfo.StopLoss();
           }
         else
            if(posinfo.PositionType() == POSITION_TYPE_SELL)
              {
               ++sellPositionCount;
               totalSellLots += posinfo.Volume();
               totalSellProfit += posinfo.Profit() + posinfo.Swap() + posinfo.Commission();
               SellPrice = posinfo.PriceOpen();
               sellStopLoss = posinfo.StopLoss();
              }
        }
     }
   return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateDisplayPanel()
  {
   int panelX = 10;
   int panelY = 40;
   int panelWidth = 250;
   int panelHeight = 60;
   int spacing = 5;
   string fontName = "Arial";
   int fontSize = 10;
   ObjectCreate(0, "PositionsPanel", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "PositionsPanel", OBJPROP_XDISTANCE, panelX);
   ObjectSetInteger(0, "PositionsPanel", OBJPROP_YDISTANCE, panelY);
   ObjectSetInteger(0, "PositionsPanel", OBJPROP_XSIZE, panelWidth);
   ObjectSetInteger(0, "PositionsPanel", OBJPROP_YSIZE, panelHeight);
   ObjectSetInteger(0, "PositionsPanel", OBJPROP_BGCOLOR, 0x575757);
   ObjectSetInteger(0, "PositionsPanel", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "PositionsPanel", OBJPROP_BORDER_COLOR, clrGray);
//sell Posiotn Label
   ObjectCreate(0, "SellLotsLabel", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "SellLotsLabel", OBJPROP_XDISTANCE, panelX + 10);
   ObjectSetInteger(0, "SellLotsLabel", OBJPROP_YDISTANCE, panelY + 10);
   ObjectSetString(0, "SellLotsLabel", OBJPROP_TEXT, "Sell Lots: 0.00");
   ObjectSetInteger(0, "SellLotsLabel", OBJPROP_COLOR, clrGoldenrod);
   ObjectSetInteger(0, "SellLotsLabel", OBJPROP_FONTSIZE, fontSize);
//Buy Position Label
   ObjectCreate(0, "BuyLotsLabel", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "BuyLotsLabel", OBJPROP_XDISTANCE, panelX + 10);
   ObjectSetInteger(0, "BuyLotsLabel", OBJPROP_YDISTANCE, panelY + 30);
   ObjectSetString(0, "BuyLotsLabel", OBJPROP_TEXT, "Buy Lots: 0.00");
   ObjectSetInteger(0, "BuyLotsLabel", OBJPROP_COLOR, clrGoldenrod);
   ObjectSetInteger(0, "BuyLotsLabel", OBJPROP_FONTSIZE, fontSize);
   panelX = panelWidth + spacing;
//profit loss pannel
   ObjectCreate(0, "ProfitPanel", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "ProfitPanel", OBJPROP_XDISTANCE, panelX);
   ObjectSetInteger(0, "ProfitPanel", OBJPROP_YDISTANCE, panelY);
   ObjectSetInteger(0, "ProfitPanel", OBJPROP_XSIZE, panelWidth);
   ObjectSetInteger(0, "ProfitPanel", OBJPROP_YSIZE, panelHeight);
   ObjectSetInteger(0, "ProfitPanel", OBJPROP_BGCOLOR, 0x575757);
   ObjectCreate(0, "BuyProfitLabel", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "BuyProfitLabel", OBJPROP_XDISTANCE, panelX + 10);
   ObjectSetInteger(0, "BuyProfitLabel", OBJPROP_YDISTANCE, panelY + 30);
   ObjectSetString(0, "BuyProfitLabel", OBJPROP_TEXT, "Buy P/L: ");
   ObjectSetInteger(0, "BuyProfitLabel", OBJPROP_COLOR, clrDeepSkyBlue);
   ObjectSetInteger(0, "BuyProfitLabel", OBJPROP_FONTSIZE, fontSize);
//Buy profit - right label
   ObjectCreate(0, "BuyProfitValueLabel", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "BuyProfitValueLabel", OBJPROP_XDISTANCE, panelX + panelWidth - 10);
   ObjectSetInteger(0, "BuyProfitValueLabel", OBJPROP_YDISTANCE, panelY + 40);
   ObjectSetString(0, "BuyProfitValueLabel", OBJPROP_TEXT, "0.00");
   ObjectSetInteger(0, "BuyProfitValueLabel", OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, "BuyProfitValueLabel", OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, "BuyProfitValueLabel", OBJPROP_ANCHOR, ANCHOR_RIGHT);
// sell profit -Left label
   ObjectCreate(0, "SellProfitLabel", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "SellProfitLabel", OBJPROP_XDISTANCE, panelX + 10);
   ObjectSetInteger(0, "SellProfitLabel", OBJPROP_YDISTANCE, panelY + 10);
   ObjectSetString(0, "SellProfitLabel", OBJPROP_TEXT, "Sell P/L: ");
   ObjectSetInteger(0, "SellProfitLabel", OBJPROP_COLOR, clrDeepSkyBlue);
   ObjectSetInteger(0, "SellProfitLabel", OBJPROP_FONTSIZE, fontSize);
//sell profit - right label
   ObjectCreate(0, "SellProfitValueLabel", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "SellProfitValueLabel", OBJPROP_XDISTANCE, panelX + panelWidth - 10);
   ObjectSetInteger(0, "SellProfitValueLabel", OBJPROP_YDISTANCE, panelY + 20);
   ObjectSetString(0, "SellProfitValueLabel", OBJPROP_TEXT, "0.00");
   ObjectSetInteger(0, "SellProfitValueLabel", OBJPROP_COLOR, clrDeepSkyBlue);
   ObjectSetInteger(0, "SellProfitValueLabel", OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, "SellProfitValueLabel", OBJPROP_ANCHOR, ANCHOR_RIGHT);
// Buy profit -Left label
//Spread Label
   panelX += panelWidth + spacing ;
   ObjectCreate(0, "SpreadPanel", OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "SpreadPanel", OBJPROP_XDISTANCE, panelX);
   ObjectSetInteger(0, "SpreadPanel", OBJPROP_YDISTANCE, panelY);
   ObjectSetInteger(0, "SpreadPanel", OBJPROP_XSIZE, panelWidth);
   ObjectSetInteger(0, "SpreadPanel", OBJPROP_YSIZE, panelHeight);
   ObjectSetInteger(0, "SpreadPanel", OBJPROP_BGCOLOR, 0x575757);
//Spread Label(Red)
   ObjectCreate(0, "SpreadLabel", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "SpreadLabel", OBJPROP_XDISTANCE, panelX + 10);
   ObjectSetInteger(0, "SpreadLabel", OBJPROP_YDISTANCE, panelY + 10);
   ObjectSetString(0, "SpreadLabel", OBJPROP_TEXT, "Spread: ");
   ObjectSetInteger(0, "SpreadLabel", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "SpreadLabel", OBJPROP_FONTSIZE, fontSize);
//spread value label(white )
   ObjectCreate(0, "SpreadValueLabel", OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, "SpreadValueLabel", OBJPROP_XDISTANCE, panelX + 10);
   ObjectSetInteger(0, "SpreadValueLabel", OBJPROP_YDISTANCE, panelY + 30);
   ObjectSetString(0, "SpreadValueLabel", OBJPROP_TEXT, (string)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD));
   ObjectSetInteger(0, "SpreadValueLabel", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "SpreadValueLabel", OBJPROP_FONTSIZE, fontSize);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdatePanelData()
  {
   double totalBuylots = 0.00;
   double totalSelllots = 0.00;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      posinfo.SelectByIndex(i);
      if(posinfo.Symbol() == _Symbol && posinfo.Magic() == Magic)
        {
         if(posinfo.PositionType() == POSITION_TYPE_BUY)
           {
            totalBuylots += posinfo.Volume();
           }
         else
            if(posinfo.PositionType() == POSITION_TYPE_SELL)
              {
               totalSelllots += posinfo.Volume();
              }
        }
     }
   ObjectSetString(0, "BuyLotsLabel", OBJPROP_TEXT, "Buy Lots : " + DoubleToString(totalBuylots, 2));
   ObjectSetString(0, "SellLotsLabel", OBJPROP_TEXT, "Sell Lots : " + DoubleToString(totalSelllots, 2));
   UpdateProfitDisplay("SellProfitValueLabel", totalSellProfit);
   UpdateProfitDisplay("BuyProfitValueLabel", totalBuyProfit);
   ObjectSetString(0, "SpreadValueLabel", OBJPROP_TEXT, (string)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateProfitDisplay(string objName, double profit)
  {
   color textColor = profit >= 0 ? clrLime : clrRed;
   string text = DoubleToString(profit, 2);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, textColor);
  }
//+------------------------------------------------------------------+
