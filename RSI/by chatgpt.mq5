#include <Trade\Trade.mqh>
CTrade trade;
CPositionInfo posinfo;

input double Lots = 0.01;
input int RSI_Period = 14;
input int EMA_Period = 200;
input int ATR_Period = 14;
input double RR_Multiplier = 2.5;
input double SL_Multiplier = 1.5;
input double MaxSpread = 30;
input int Magic = 2025;

int handleRSI, handleEMA, handleATR;

datetime lastBarTime = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(Magic);

   handleRSI = iRSI(_Symbol, PERIOD_M5, RSI_Period, PRICE_CLOSE);
   handleEMA = iMA(_Symbol, PERIOD_M5, EMA_Period, 0, MODE_EMA, PRICE_CLOSE);
   handleATR = iATR(_Symbol, PERIOD_M5, ATR_Period);

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnTick()
{
   if(SymbolInfoInteger(_Symbol,SYMBOL_SPREAD) > MaxSpread)
      return;

   datetime currentBar = iTime(_Symbol,PERIOD_M5,0);
   if(currentBar == lastBarTime)
      return;
   lastBarTime = currentBar;

   double rsi[2], ema[1], atr[1];
   ArraySetAsSeries(rsi,true);
   ArraySetAsSeries(ema,true);
   ArraySetAsSeries(atr,true);

   CopyBuffer(handleRSI,0,0,2,rsi);
   CopyBuffer(handleEMA,0,0,1,ema);
   CopyBuffer(handleATR,0,0,1,atr);

   double Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   double sl, tp;

   bool positionExists=false;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(posinfo.SelectByIndex(i))
         if(posinfo.Symbol()==_Symbol && posinfo.Magic()==Magic)
            positionExists=true;
   }

   if(positionExists)
      return;

   double prevHigh = iHigh(_Symbol,PERIOD_M5,1);
   double prevLow  = iLow(_Symbol,PERIOD_M5,1);
   double close    = iClose(_Symbol,PERIOD_M5,0);
   Comment("rsi[0] :"+ rsi[0]);

   // ================= BUY =================
   if(close > ema[0] &&          // trend up
      rsi[1] < 40 &&             // pullback
      rsi[0] > 50 &&             // momentum return
      close > prevHigh)          // break structure
   {
      sl = Ask - (atr[0]*SL_Multiplier);
      tp = Ask + (atr[0]*RR_Multiplier);

      trade.Buy(Lots,_Symbol,Ask,sl,tp,"RSI_Intraday_Buy");
   }

   // ================= SELL =================
   if(close < ema[0] &&
      rsi[1] > 60 &&
      rsi[0] < 50 &&
      close < prevLow)
   {
      sl = Bid + (atr[0]*SL_Multiplier);
      tp = Bid - (atr[0]*RR_Multiplier);

      trade.Sell(Lots,_Symbol,Bid,sl,tp,"RSI_Intraday_Sell");
   }
}