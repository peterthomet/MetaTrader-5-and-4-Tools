//
// Set All Charts.mq4/mq5
// getYourNet.ch
//

#property copyright "Copyright 2019, getYourNet.ch"
string namespace="SetAllCharts";

enum Command
{
   Clean,
   Pivots,
   Murrey,
   Line,
   Candles,
   ZoomIn,
   ZoomOut,
   M1,
   M2,
   M3,
   M4,
   M5,
   M6,
   M10,
   M12,
   M15,
   M20,
   M30,
   H1,
   H2,
   H3,
   H4,
   H6,
   H8,
   H12,
   D1,
   W1,
   MN
};
string CommandText[MN+1]={"Clean","Pivots","Murrey","Line","Candles","+","-","M1","M2","M3","M4","M5","M6","M10","M12","M15","M20","M30","H1","H2","H3","H4","H6","H8","H12","D1","W1","MN"};
int CommandPeriod[MN+1]={0,0,0,0,0,0,0,PERIOD_M1,PERIOD_M2,PERIOD_M3,PERIOD_M4,PERIOD_M5,PERIOD_M6,PERIOD_M10,PERIOD_M12,PERIOD_M15,PERIOD_M20,PERIOD_M30,PERIOD_H1,PERIOD_H2,PERIOD_H3,PERIOD_H4,PERIOD_H6,PERIOD_H8,PERIOD_H12,PERIOD_D1,PERIOD_W1,PERIOD_MN1};


void OnInit()
{
   ChartSetInteger(0,CHART_SHOW,false);

   CreateButton(7,5,M1);
   CreateButton(7,25,M2);
   CreateButton(7,45,M3);
   CreateButton(7,65,M4);
   CreateButton(35,5,M5);
   CreateButton(35,25,M6);
   CreateButton(35,45,M10);
   CreateButton(35,65,M12);
   CreateButton(63,5,M15);
   CreateButton(63,25,M20);
   CreateButton(100,5,M30);
   CreateButton(138,5,H1);
   CreateButton(138,25,H2);
   CreateButton(138,45,H3);
   CreateButton(163,5,H4);
   CreateButton(163,25,H6);
   CreateButton(163,45,H8);
   CreateButton(163,65,H12);
   CreateButton(190,5,D1);
   CreateButton(217,5,W1);
   CreateButton(247,5,MN);
   CreateButton(305,5,ZoomIn);
   CreateButton(327,5,ZoomOut);
   CreateButton(305,25,Line);
   CreateButton(345,25,Candles);
   CreateButton(305,45,Clean);
   CreateButton(355,45,Pivots);
   CreateButton(405,45,Murrey);
   
   ChartRedraw();
}


void CreateButton(int xPos, int yPos, int command)
{
   string text=CommandText[command];
   string objname=namespace+"Command"+IntegerToString(command);
   ObjectCreate(0,objname,OBJ_LABEL,0,0,0,0,0);
   ObjectSetInteger(0,objname,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,objname,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,objname,OBJPROP_XDISTANCE,xPos);
   ObjectSetInteger(0,objname,OBJPROP_YDISTANCE,yPos);
   ObjectSetInteger(0,objname,OBJPROP_COLOR,C'100,100,100');
   ObjectSetInteger(0,objname,OBJPROP_FONTSIZE,11);
   ObjectSetString(0,objname,OBJPROP_FONT,"Arial");
   ObjectSetString(0,objname,OBJPROP_TEXT," "+text+" ");
}


void OnDeinit(const int reason)
{
   DeleteAllObjects();
   ChartSetInteger(0,CHART_SHOW,true);
}


void DeleteAllObjects()
{
   ObjectsDeleteAll(0,namespace);
}


void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_OBJECT_CLICK)
   {
      int pos=StringFind(sparam,"Command");
      if(pos>-1)
         ExecuteCommand((int)StringToInteger(StringSubstr(sparam,pos+7)));
   }
}


void ExecuteCommand(int command)
{
   long chartid=ChartFirst();
   while(chartid>-1)
   {
      if(chartid!=ChartID())
      {
         bool hassubwindows=(ChartGetInteger(chartid,CHART_WINDOWS_TOTAL)>1);
         if(command==Clean)
            if(!hassubwindows)
               ChartApplyTemplate(chartid,"Empty Small.tpl");
         if(command==Pivots)
            if(!hassubwindows)
               ChartApplyTemplate(chartid,"Forex Small.tpl");
         if(command==Murrey)
            if(!hassubwindows)
               ChartApplyTemplate(chartid,"Forex Murrey Math Small.tpl");
         if(command==Line)
            ChartSetInteger(chartid,CHART_MODE,CHART_LINE);
         if(command==Candles)
            ChartSetInteger(chartid,CHART_MODE,CHART_CANDLES);
         if(command==ZoomIn)
            if(!hassubwindows)
               Zoom(chartid,1);
         if(command==ZoomOut)
            if(!hassubwindows)
               Zoom(chartid,-1);
         if(command>ZoomOut)
            ChartSetSymbolPeriod(chartid,ChartSymbol(chartid),(ENUM_TIMEFRAMES)CommandPeriod[command]);

         ChartRedraw(chartid);
      }
      chartid=ChartNext(chartid);
   }
}


void Zoom(long chartid, int value)
{
   long zoom=ChartGetInteger(chartid,CHART_SCALE);
   zoom+=value;
   if(zoom>5) zoom=5;
   if(zoom<0) zoom=0;
   ChartSetInteger(chartid,CHART_SCALE,zoom);
   ChartNavigate(chartid,CHART_END);
}

