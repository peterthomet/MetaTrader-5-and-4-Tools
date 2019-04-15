//
// StopAndTake.mq5
// Converted to MT5 by getYourNet.ch
//
//+------------------------------------------------------------------+
//|                                                  StopAndTake.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Melnichenko D.A."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

double selectedprice=0;


void OnStart()
{
   bool error=false;
   selectedprice=ChartPriceOnDropped();

   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(PositionGetSymbol(i)==Symbol())
         if(!ModifyOrder())
            error=true;
   }

   if(error)
      MessageBox("Order change error", "Warning", MB_OK|MB_ICONWARNING);
}


bool ModifyOrder()
{
   bool ret=true;
   CTrade trade;
   MqlTick last;
   SymbolInfoTick(Symbol(),last);

   int positiontype=(int)PositionGetInteger(POSITION_TYPE);
   long ticket=PositionGetInteger(POSITION_TICKET);
   double tp=PositionGetDouble(POSITION_TP);
   double sl=PositionGetDouble(POSITION_SL);
   
   if(positiontype==POSITION_TYPE_BUY)
   {
      if(selectedprice > last.bid)
         ret=trade.PositionModify(ticket,sl,selectedprice);
      if(selectedprice < last.bid)
         ret=trade.PositionModify(ticket,selectedprice,tp);
   }
   
   if(positiontype==POSITION_TYPE_SELL)
   {
      if(selectedprice < last.ask)
         ret=trade.PositionModify(ticket,sl,selectedprice);
      if(selectedprice > last.ask)
         ret=trade.PositionModify(ticket,selectedprice,tp);
   }

   return ret;
}
