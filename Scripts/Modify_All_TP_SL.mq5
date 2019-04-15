//
// Modify_All_TP_SL.mq5
// Converted to MT5 by getYourNet.ch
//
//+------------------------------------------------------------------+
//|                                             Modify_All_TP_SL.mq4 |
//|                                                  © Tecciztecatl  |
//+------------------------------------------------------------------+
#property copyright     "© Tecciztecatl 2016-2018"
#property link          "https://www.mql5.com/en/users/tecciztecatl"
#property version       "2.00"
#property description   "The script modifies all orders (market and pending) on the symbol Take Profit and Stop Loss."
#property script_show_inputs
#property strict

#include <Trade\Trade.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\PositionInfo.mqh>

input double TakeProfit=0; //Take Profit (price)
input double StopLoss=0; //Stop Loss (price)


void OnStart()
{
   double inputtp=NormalizeDouble(TakeProfit,_Digits);
   double inputsl=NormalizeDouble(StopLoss,_Digits);

   MqlTick last;
   SymbolInfoTick(Symbol(),last);
   
   for(int i=OrdersTotal()-1;i>=0;i--)
   {
      COrderInfo oi;
      oi.SelectByIndex(i);

      if(oi.Symbol()==Symbol())
      {
         double tp=inputtp;
         double sl=inputsl;
         if(tp<=0)
            tp=oi.TakeProfit();
         if(sl<=0)
            sl=oi.StopLoss();

         if(oi.OrderType()==ORDER_TYPE_BUY_LIMIT||oi.OrderType()==ORDER_TYPE_BUY_STOP)
         {
            if(tp<=oi.PriceOpen())
               tp=oi.TakeProfit();
            if(sl>=oi.PriceOpen())
               sl=oi.StopLoss();
         }

         if(oi.OrderType()==ORDER_TYPE_SELL_LIMIT||oi.OrderType()==ORDER_TYPE_SELL_STOP)
         {
            if(tp>=oi.PriceOpen())
               tp=oi.TakeProfit();
            if(sl<=oi.PriceOpen())
               sl=oi.StopLoss();
         }

         if(tp!=oi.TakeProfit()||sl!=oi.StopLoss())
            Modify(oi.Ticket(),tp,sl,&oi);
      }
   }

   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      CPositionInfo pi;
      pi.SelectByIndex(i);

      if(pi.Symbol()==Symbol())
      {
         double tp=inputtp;
         double sl=inputsl;
         if(tp<=0)
            tp=pi.TakeProfit();
         if(sl<=0)
            sl=pi.StopLoss();

         if(pi.PositionType()==POSITION_TYPE_BUY)
         {
            if(tp<last.bid)
               tp=pi.TakeProfit();
            if(sl>last.bid)
               sl=pi.StopLoss();
         }

         if(pi.PositionType()==POSITION_TYPE_SELL)
         {
            if(tp>last.ask)
               tp=pi.TakeProfit();
            if(sl<last.ask)
               sl=pi.StopLoss();
         }

         if(tp!=pi.TakeProfit()||sl!=pi.StopLoss())
            Modify(pi.Ticket(),tp,sl,NULL);
      }
   }
}


void Modify(long ticket, double tp, double sl, COrderInfo *oi=NULL)
{
   CTrade trade;
   ResetLastError();
   bool success=false;
   int retry=0;

   while(!success && !IsStopped() && retry<5)
   {
      if(oi!=NULL)
         success=trade.OrderModify(ticket,oi.PriceOpen(),sl,tp,oi.TypeTime(),oi.TimeExpiration(),oi.PriceStopLimit());
      else
         success=trade.PositionModify(ticket,sl,tp);
      if(!success)
      {
         Print("Error modifying orders, #"+IntegerToString(GetLastError()));
         Sleep(500);
         retry++;
      }
   }
}
