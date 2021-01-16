//
// ButtonCloseBuySellGBP.mq5
// getYournet.ch
//

#property copyright "Copyright 2021, getYourNet.ch"
#property version   "1.00"

#include <Trade\Trade.mqh>

input color BuysButtonColor=SeaGreen; // Buys Button Color
input color SellsButtonColor=Crimson; // Sells Button Color
input color ButtonsTextColor=White; // Text Color
input ENUM_BASE_CORNER ButtonsPositionCorner=CORNER_LEFT_UPPER; // Buttons Position Corner
input int BuysButtonPositionX=20; // Buys Button Position X
input int BuysButtonPositionY=25; // Buys Button Position Y
input int SellsButtonPositionX=152; // Sells Button Position X
input int SellsButtonPositionY=25; // Sells Button Position Y
input bool HideButtonsNoPositions=false; // Hide Buttons if no Positions

string appnamespace="ButtonCloseBuySellGBP";
enum Objects
{
   BuyButton,
   BuyText,
   SellButton,
   SellText
};
bool calculating=false;
bool buyclosecommand=false;
bool sellclosecommand=false;
datetime lastcalculated=0;


void OnInit()
{
   CreateButtons();
   EventSetMillisecondTimer(100);

   if(MQLInfoInteger(MQL_TESTER))
   {
      CTrade trade;
//      trade.PositionOpen("EURUSD",ORDER_TYPE_BUY,0.1,0,NULL,NULL);
//
//      trade.PositionOpen("GBPUSD",ORDER_TYPE_BUY,0.1,0,NULL,NULL);
//      trade.PositionOpen("EURGBP",ORDER_TYPE_SELL,0.1,0,NULL,NULL);
//      trade.PositionOpen("GBPJPY",ORDER_TYPE_BUY,0.1,0,NULL,NULL);
//      trade.PositionOpen("GBPCHF",ORDER_TYPE_BUY,0.1,0,NULL,NULL);
//      trade.PositionOpen("GBPCAD",ORDER_TYPE_BUY,0.1,0,NULL,NULL);
//      trade.PositionOpen("GBPAUD",ORDER_TYPE_BUY,0.1,0,NULL,NULL);
//      trade.PositionOpen("GBPNZD",ORDER_TYPE_BUY,0.1,0,NULL,NULL);
//
//      trade.PositionOpen("GBPUSD",ORDER_TYPE_SELL,0.1,0,NULL,NULL);
//      trade.PositionOpen("EURGBP",ORDER_TYPE_BUY,0.1,0,NULL,NULL);
//      trade.PositionOpen("GBPJPY",ORDER_TYPE_SELL,0.1,0,NULL,NULL);
//      trade.PositionOpen("GBPCHF",ORDER_TYPE_SELL,0.1,0,NULL,NULL);
//      trade.PositionOpen("GBPCAD",ORDER_TYPE_SELL,0.1,0,NULL,NULL);
//      trade.PositionOpen("GBPAUD",ORDER_TYPE_SELL,0.1,0,NULL,NULL);
//      trade.PositionOpen("GBPNZD",ORDER_TYPE_SELL,0.1,0,NULL,NULL);
   }
}


void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0,appnamespace);
}


void OnTick()
{
}


void OnTimer()
{
   Calculate();
}


void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      if(StringFind(sparam,appnamespace+IntegerToString(BuyButton))>-1)
      {
         buyclosecommand=true;
         ObjectSetString(0,appnamespace+IntegerToString(BuyText),OBJPROP_TEXT,"Closing Buys...");
         ChartRedraw();
      }
      if(StringFind(sparam,appnamespace+IntegerToString(SellButton))>-1)
      {
         sellclosecommand=true;
         ObjectSetString(0,appnamespace+IntegerToString(SellText),OBJPROP_TEXT,"Closing Sells...");
         ChartRedraw();
      }
   }
}


void CreateButtons()
{
   string on;
   
   int xf=1;
   int yf=1;
   if(ButtonsPositionCorner==CORNER_LEFT_LOWER)
      yf=-1;   
   if(ButtonsPositionCorner==CORNER_RIGHT_LOWER)
   {
      xf=-1;   
      yf=-1;   
   }
   if(ButtonsPositionCorner==CORNER_RIGHT_UPPER)
      xf=-1;   

   on=appnamespace+IntegerToString(BuyButton);
   ObjectCreate(0,on,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,on,OBJPROP_WIDTH,0);
   ObjectSetInteger(0,on,OBJPROP_FILL,true);
   ObjectSetInteger(0,on,OBJPROP_BGCOLOR,BuysButtonColor);
   ObjectSetInteger(0,on,OBJPROP_CORNER,ButtonsPositionCorner);
   ObjectSetInteger(0,on,OBJPROP_XDISTANCE,BuysButtonPositionX);
   ObjectSetInteger(0,on,OBJPROP_YDISTANCE,BuysButtonPositionY);
   ObjectSetInteger(0,on,OBJPROP_XSIZE,132);
   ObjectSetInteger(0,on,OBJPROP_YSIZE,22);
   ObjectSetInteger(0,on,OBJPROP_ZORDER,1000);
   ObjectSetString(0,on,OBJPROP_TOOLTIP,"Close GBP Buys");

   on=appnamespace+IntegerToString(BuyText);
   ObjectCreate(0,on,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,on,OBJPROP_CORNER,ButtonsPositionCorner);
   ObjectSetInteger(0,on,OBJPROP_ANCHOR,ANCHOR_CENTER);
   ObjectSetInteger(0,on,OBJPROP_XDISTANCE,BuysButtonPositionX+(66*xf));
   ObjectSetInteger(0,on,OBJPROP_YDISTANCE,BuysButtonPositionY+(11*yf));
   ObjectSetInteger(0,on,OBJPROP_COLOR,ButtonsTextColor);
   ObjectSetInteger(0,on,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,on,OBJPROP_ZORDER,-100);
   ObjectSetString(0,on,OBJPROP_TEXT," ");

   on=appnamespace+IntegerToString(SellButton);
   ObjectCreate(0,on,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,on,OBJPROP_WIDTH,0);
   ObjectSetInteger(0,on,OBJPROP_FILL,true);
   ObjectSetInteger(0,on,OBJPROP_BGCOLOR,SellsButtonColor);
   ObjectSetInteger(0,on,OBJPROP_CORNER,ButtonsPositionCorner);
   ObjectSetInteger(0,on,OBJPROP_XDISTANCE,SellsButtonPositionX);
   ObjectSetInteger(0,on,OBJPROP_YDISTANCE,SellsButtonPositionY);
   ObjectSetInteger(0,on,OBJPROP_XSIZE,132);
   ObjectSetInteger(0,on,OBJPROP_YSIZE,22);
   ObjectSetInteger(0,on,OBJPROP_ZORDER,1000);
   ObjectSetString(0,on,OBJPROP_TOOLTIP,"Close GBP Sells");

   on=appnamespace+IntegerToString(SellText);
   ObjectCreate(0,on,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,on,OBJPROP_CORNER,ButtonsPositionCorner);
   ObjectSetInteger(0,on,OBJPROP_ANCHOR,ANCHOR_CENTER);
   ObjectSetInteger(0,on,OBJPROP_XDISTANCE,SellsButtonPositionX+(66*xf));
   ObjectSetInteger(0,on,OBJPROP_YDISTANCE,SellsButtonPositionY+(11*yf));
   ObjectSetInteger(0,on,OBJPROP_COLOR,ButtonsTextColor);
   ObjectSetInteger(0,on,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,on,OBJPROP_ZORDER,-100);
   ObjectSetString(0,on,OBJPROP_TEXT," ");
}


void Calculate()
{
   if(calculating)
      return;

   if(!buyclosecommand && !sellclosecommand && (TimeLocal()-lastcalculated)<1)
      return;

   calculating=true;

   double buystotal=0;
   double sellstotal=0;
   int buyscount=0;
   int sellscount=0;
   CTrade trade;

   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      int pos=StringFind(PositionGetSymbol(i),"GBP");
      if(pos>-1)
      {
         long type=PositionGetInteger(POSITION_TYPE);
         if(type==POSITION_TYPE_BUY&&pos==3)
            type=POSITION_TYPE_SELL;
         else if(type==POSITION_TYPE_SELL&&pos==3)
            type=POSITION_TYPE_BUY;
         
         if((buyclosecommand&&type==POSITION_TYPE_BUY) || (sellclosecommand&&type==POSITION_TYPE_SELL))
            trade.PositionClose(PositionGetInteger(POSITION_TICKET));
         else
         {
            if(type==POSITION_TYPE_BUY)
            {
               buystotal+=PositionProfitNet();
               buyscount++;
            }
            if(type==POSITION_TYPE_SELL)
            {
               sellstotal+=PositionProfitNet();
               sellscount++;
            }
         }
      }
   }

   if(buyclosecommand&&buyscount==0)
      buyclosecommand=false;
   if(sellclosecommand&&sellscount==0)
      sellclosecommand=false;

   if(!buyclosecommand)
      ObjectSetString(0,appnamespace+IntegerToString(BuyText),OBJPROP_TEXT,"Close GBP Buys "+DoubleToString(NormalizeDouble(buystotal,1),1));
   if(!sellclosecommand)
      ObjectSetString(0,appnamespace+IntegerToString(SellText),OBJPROP_TEXT,"Close GBP Sells "+DoubleToString(NormalizeDouble(sellstotal,1),1));

   if(HideButtonsNoPositions)
   {
      string on;
      int yoffset;

      on=appnamespace+IntegerToString(BuyButton);
      bool buysvisible=(ObjectGetInteger(0,on,OBJPROP_YDISTANCE)>-1000);
      yoffset=0;
      if(buyscount>0&&!buysvisible)
         yoffset=10000;
      if(buyscount==0&&buysvisible)
         yoffset=-10000;
      if(yoffset!=0)
      {
         ObjectSetInteger(0,on,OBJPROP_YDISTANCE,ObjectGetInteger(0,on,OBJPROP_YDISTANCE)+yoffset);
         on=appnamespace+IntegerToString(BuyText);
         ObjectSetInteger(0,on,OBJPROP_YDISTANCE,ObjectGetInteger(0,on,OBJPROP_YDISTANCE)+yoffset);
      }

      on=appnamespace+IntegerToString(SellButton);
      bool sellsvisible=(ObjectGetInteger(0,on,OBJPROP_YDISTANCE)>-1000);
      yoffset=0;
      if(sellscount>0&&!sellsvisible)
         yoffset=10000;
      if(sellscount==0&&sellsvisible)
         yoffset=-10000;
      if(yoffset!=0)
      {
         ObjectSetInteger(0,on,OBJPROP_YDISTANCE,ObjectGetInteger(0,on,OBJPROP_YDISTANCE)+yoffset);
         on=appnamespace+IntegerToString(SellText);
         ObjectSetInteger(0,on,OBJPROP_YDISTANCE,ObjectGetInteger(0,on,OBJPROP_YDISTANCE)+yoffset);
      }
   }

   ChartRedraw();

   lastcalculated=TimeLocal();
   calculating=false;
}


double PositionProfitNet()
{
   double commission=0;
   if(HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER)))
   {
      ulong Ticket=0;
      int dealscount=HistoryDealsTotal();
      for(int i=0;i<dealscount;i++)
      {
         ulong TicketDeal=HistoryDealGetTicket(i);
         if(TicketDeal>0)
         {
            if(HistoryDealGetInteger(TicketDeal,DEAL_ENTRY)==DEAL_ENTRY_IN)
            {
               Ticket=TicketDeal;
               break;
            }
         }
      }
      if(Ticket>0)
      {
         double LotsIn=HistoryDealGetDouble(Ticket,DEAL_VOLUME);
         if(LotsIn>0)
            commission=HistoryDealGetDouble(Ticket,DEAL_COMMISSION)*PositionGetDouble(POSITION_VOLUME)/LotsIn;
         if(true) // Commission per Deal
            commission=commission*2;
      }
   }
   return PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+commission;
}
