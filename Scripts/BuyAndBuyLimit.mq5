//
// BuyAndBuyLimit.mq5
// getYourNet.ch
//

#property copyright "Copyright 2019, getYourNet.ch"
#property version   "1.00"
#property description "Open a Buy market order by dragging the script above the current price or create a BuyLimit order by dragging the scipt below the current price"
#property script_show_inputs

#include <Trade\Trade.mqh>

input int NumberOfOrders=1; // Number of Orders to open
input double EntryPrice=0; // Entry Price for Buy Limit (overrules drag and drop price)
input double RiskPercent=1; // Risk Percent Money Management
input double Lots=0; // ----- OR Lot Size
input int LotSizeDigits=2; // Lot Size Fractional Digits
input double StopLoss=100; // Stop Loss Points
input double StopLossPrice=0; // ----- OR Stop Loss Price
input double TakeProfit=100; // Take Profit Points
input double TakeProfitPrice=0; // ----- OR Take Profit Price
input string OrderComment="Buy Script"; // Add this Comment to Orders


void OnStart()
{
   CTrade trade;

   MqlTick last;
   SymbolInfoTick(Symbol(),last);

   double selectedprice=ChartPriceOnDropped();
   if(EntryPrice>0&&EntryPrice<last.ask)
      selectedprice=EntryPrice;
   
   double entryprice=selectedprice;
   if(entryprice==0||last.ask<selectedprice)
      entryprice=last.ask;
      
   double slprice=StopLossPrice;
   if(StopLoss>0)
      slprice=entryprice-(StopLoss*Point());

   double tpprice=TakeProfitPrice;
   if(TakeProfit>0)
      tpprice=entryprice+(TakeProfit*Point());

   double volume=Lots;
   if(RiskPercent>0&&slprice>0)
      volume=AccountInfoDouble(ACCOUNT_BALANCE)*(RiskPercent/100)/((entryprice-slprice)/Point())/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE));
   volume=NormalizeDouble(volume,LotSizeDigits);

   if(volume>0)
   {
      for(int i=0;i<NumberOfOrders;i++)
      {
         if(last.ask>selectedprice&&selectedprice>0)
            trade.BuyLimit(volume,selectedprice,NULL,slprice,tpprice,0,0,OrderComment);
         else
            trade.Buy(volume,NULL,0,slprice,tpprice,OrderComment);
      }
   }
}
