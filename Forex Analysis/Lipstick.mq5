
//
// Lipstick.mq5
//

#property copyright "Copyright 2023, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots 0

enum TypeLipStickMode
{
   LipStickNone,
   LipStickMode1,
   LipStickMode2
};

int lipstickmode;
int currentlipstickmode;
long firstbar;
long lastfirstbar;
datetime lastbartime;
bool crosshairon;
string appnamespace="LipstickIndicator";


void OnInit()
{
   lipstickmode=LipStickNone;
   currentlipstickmode=LipStickNone;
   firstbar=0;
   lastfirstbar=-1;
   lastbartime=-1;
   crosshairon=false;

   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,0,true);

   if(GlobalVariableCheck(appnamespace+IntegerToString(ChartID())+"lipstickmode"))
      lipstickmode=(int)GlobalVariableGet(appnamespace+IntegerToString(ChartID())+"lipstickmode");

   EventSetMillisecondTimer(200);
}


void OnDeinit(const int reason)
{
   GlobalVariableSet(appnamespace+IntegerToString(ChartID())+"lipstickmode",lipstickmode);

   DeleteLipstick();
   EventKillTimer();
}


void OnTimer()
{
   ManageLipStick();
}


void ManageLipStick()
{
   bool draw=false;

   if(currentlipstickmode!=lipstickmode)
   {
      if(lipstickmode==LipStickNone)
         DeleteLipstick();
      else
         draw=true;
   }

   if(lipstickmode!=LipStickNone)
      if(lastfirstbar!=firstbar || lastbartime!=(datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE))
         draw=true;
   
   if(draw)
   {
      DeleteLipstick();
      if(CreateLipstick())
      {
         ChartRedraw();
         lastfirstbar=firstbar;
         lastbartime=(datetime)SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
         currentlipstickmode=lipstickmode;
      }
   }
}


bool CreateLipstick()
{
   datetime dt[1];
   if(CopyTime(_Symbol,_Period,(int)ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR)-((int)ChartGetInteger(0,CHART_VISIBLE_BARS)-1),1,dt)<1)
      return false;

   int rcount=1200;
   MqlRates r[];
   ArrayResize(r,rcount);
   if(CopyRates(_Symbol,PERIOD_M5,dt[0],rcount,r)<rcount)
      return false;

   datetime asiastart=0, asiaend=0, nymidnight=0, dayend=0, lastdaystart=0, day3start=0, day4start=0;
   double asiahigh=DBL_MIN, asialow=DBL_MAX, nyopen=0, drhigh=DBL_MIN, drlow=DBL_MAX, idrhigh=DBL_MIN, idrlow=DBL_MAX, lastdayhigh=DBL_MIN, lastdaylow=DBL_MAX, day3high=DBL_MIN, day3low=DBL_MAX, day4high=DBL_MIN, day4low=DBL_MAX, pmhigh=DBL_MIN, pmlow=DBL_MAX, lunchhigh=DBL_MIN, lunchlow=DBL_MAX, londonhigh=DBL_MIN, londonlow=DBL_MAX, nyhigh=DBL_MIN, nylow=DBL_MAX;
   int lasthour=6, day=1;

   for(int i=rcount-1;i>=0;i--)
   {
      MqlDateTime t;
      TimeToStruct(r[i].time,t);

      if((t.hour==20 && t.min>=30) || t.hour==21 || t.hour==22)
      {
         pmhigh=MathMax(pmhigh,r[i].high);
         pmlow=MathMin(pmlow,r[i].low);
         if(t.hour==20 && t.min==30)
         {
            CreateRectangle(0,appnamespace+"LipstickPMRect"+IntegerToString(t.day),MistyRose,pmhigh,pmlow,r[i].time,r[i].time+8940);
            pmhigh=DBL_MIN;
            pmlow=DBL_MAX;
         }
      }

      if(t.hour==19)
      {
         lunchhigh=MathMax(lunchhigh,r[i].high);
         lunchlow=MathMin(lunchlow,r[i].low);
         if(t.min==0)
         {
            CreateRectangle(0,appnamespace+"LipstickLunchRect"+IntegerToString(t.day),AntiqueWhite,lunchhigh,lunchlow,r[i].time,r[i].time+3540);
            lunchhigh=DBL_MIN;
            lunchlow=DBL_MAX;
         }
      }

      if((t.hour==16 && t.min>=30) || (t.hour==17 && t.min<30))
      {
         nyhigh=MathMax(nyhigh,r[i].high);
         nylow=MathMin(nylow,r[i].low);
         if(t.min==30)
         {
            CreateRectangle(0,appnamespace+"LipstickNYRect"+IntegerToString(t.day),AliceBlue,nyhigh,nylow,r[i].time,r[i].time+3540);
            nyhigh=DBL_MIN;
            nylow=DBL_MAX;
         }
      }

      if(t.hour==10)
      {
         londonhigh=MathMax(londonhigh,r[i].high);
         londonlow=MathMin(londonlow,r[i].low);
         if(t.min==0)
         {
            CreateRectangle(0,appnamespace+"LipstickLondonRect"+IntegerToString(t.day),Beige,londonhigh,londonlow,r[i].time,r[i].time+3540);
            londonhigh=DBL_MIN;
            londonlow=DBL_MAX;
         }
      }

      if(day==1)
      {
         if(t.hour>=7 && dayend==0)
         {
            MqlDateTime dend;
            TimeToStruct(r[i].time,dend);
            dend.hour=23;
            dend.min=59;
            dend.sec=59;
            dayend=StructToTime(dend);
         }
   
         if((t.hour==17 && t.min==25) || drhigh!=DBL_MIN)
         {
            drhigh=MathMax(drhigh,r[i].high);
            drlow=MathMin(drlow,r[i].low);
            idrhigh=MathMax(idrhigh,MathMax(r[i].open,r[i].close));
            idrlow=MathMin(idrlow,MathMin(r[i].open,r[i].close));
         }
   
         if(t.hour==16 && t.min==30)
         {
            CreateTrendline(0,appnamespace+"LipstickNYOpen",Tomato,1,STYLE_SOLID,r[i].open,r[i].open,r[i].time,dayend,false);
            CreateTrendline(0,appnamespace+"LipstickSB1",Tomato,3,STYLE_SOLID,r[i].open,r[i].open,r[i].time+1800,r[i].time+1800+3599,false);
            CreateTrendline(0,appnamespace+"LipstickSB2",Tomato,3,STYLE_SOLID,r[i].open,r[i].open,r[i].time+16200,r[i].time+16200+3599,false);
            //if(drhigh!=DBL_MIN)
            //{
            //   double half=(drhigh-drlow)/2;
            //   //CreateRectangle(0,appnamespace+"LipstickDRRect",AliceBlue,drhigh,drlow,r[i].time,r[i].time+3540);
            //   CreateTrendline(0,appnamespace+"LipstickIDRHigh",LightGray,1,STYLE_DOT,idrhigh,idrhigh,r[i].time,dayend,false);
            //   CreateTrendline(0,appnamespace+"LipstickIDRLow",LightGray,1,STYLE_DOT,idrlow,idrlow,r[i].time,dayend,false);
            //   for(int j=5; j>=-5; j--)
            //   {
            //      double l=drhigh-half+(half*j);
            //      CreateTrendline(0,appnamespace+"LipstickDR-"+IntegerToString(j),LightSkyBlue,1,STYLE_DOT,l,l,r[i].time,dayend,false);
            //   }
            //}
         }
   
         if(t.hour==15 && t.min==30)
            CreateTrendline(0,appnamespace+"LipstickNYPreOpen",Tomato,1,STYLE_DOT,r[i].open,r[i].open,r[i].time,dayend,false);
   
         if(nymidnight==0)
         {
            if(t.hour==7 && t.min==0)
            {
               nymidnight=r[i].time;
               nyopen=r[i].open;
            }
         }
   
         if(nymidnight!=0 && asiaend==0)
         {
            if(t.hour==6)
               asiaend=r[i].time+(PeriodSeconds(PERIOD_M5)-1);
         }

         if(asiaend!=0)
         {
            if(t.hour>lasthour)
            {
               day=2;
            }
            else
            {
               asiahigh=MathMax(asiahigh,r[i].high);
               lastdayhigh=asiahigh;
               asialow=MathMin(asialow,r[i].low);
               lastdaylow=asialow;
               asiastart=r[i].time;
               lasthour=t.hour;
            }
         }
      }
      
      if(day==2)
      {
         lastdayhigh=MathMax(lastdayhigh,r[i].high);
         lastdaylow=MathMin(lastdaylow,r[i].low);

         if(t.hour==7 && t.min==0)
         {
            lastdaystart=r[i].time;
            day=3;
         }

         if(t.hour==23 && t.min==10)
            CreateTrendline(0,appnamespace+"LipstickNYClose",DarkKhaki,1,STYLE_SOLID,r[i].close,r[i].close,r[i].time+(PeriodSeconds(PERIOD_M5)-1),dayend,false);
      }
      else if(day==3)
      {
         day3high=MathMax(day3high,r[i].high);
         day3low=MathMin(day3low,r[i].low);

         if(t.hour==7 && t.min==0)
         {
            day3start=r[i].time;
            day=4;
         }
      }
      else if(day==4)
      {
         day4high=MathMax(day4high,r[i].high);
         day4low=MathMin(day4low,r[i].low);

         if(t.hour==7 && t.min==0)
         {
            day4start=r[i].time;
            break;
         }
      }
   }

   CreateRectangle(0,appnamespace+"LipstickAsiaRect",WhiteSmoke,asiahigh,asialow,asiastart,asiaend);
   //CreateTrendline(0,appnamespace+"LipstickAsiaHigh",CornflowerBlue,1,STYLE_DASH,asiahigh,asiahigh,asiastart,dayend,false);
   //CreateTrendline(0,appnamespace+"LipstickAsiaLow",CornflowerBlue,1,STYLE_DASH,asialow,asialow,asiastart,dayend,false);
   CreateTrendline(0,appnamespace+"LipstickNYMidnight",CornflowerBlue,1,STYLE_SOLID,nyopen,nyopen,nymidnight,dayend,false);

   CreateTrendline(0,appnamespace+"LipstickLastDayHigh",DarkOrange,2,STYLE_DASH,lastdayhigh,lastdayhigh,lastdaystart,dayend,false);
   CreateTrendline(0,appnamespace+"LipstickLastDayLow",CornflowerBlue,2,STYLE_DASH,lastdaylow,lastdaylow,lastdaystart,dayend,false);
   double mid=lastdayhigh-((lastdayhigh-lastdaylow)/2), quarter=(lastdayhigh-lastdaylow)/4;
   CreateTrendline(0,appnamespace+"LipstickLastDayMiddle",DarkGray,1,STYLE_DOT,mid,mid,lastdaystart,dayend,false);
   CreateTrendline(0,appnamespace+"LipstickLastDayUpperQuarter",DarkGray,1,STYLE_DOT,mid+quarter,mid+quarter,lastdaystart,dayend,false);
   CreateTrendline(0,appnamespace+"LipstickLastDayLowerQuarter",DarkGray,1,STYLE_DOT,mid-quarter,mid-quarter,lastdaystart,dayend,false);
   CreateTrendline(0,appnamespace+"LipstickDay3High",DarkOrange,2,STYLE_DASH,day3high,day3high,day3start,lastdaystart-1,false);
   CreateTrendline(0,appnamespace+"LipstickDay3Low",CornflowerBlue,2,STYLE_DASH,day3low,day3low,day3start,lastdaystart-1,false);
   CreateTrendline(0,appnamespace+"LipstickDay4High",DarkOrange,2,STYLE_DASH,day4high,day4high,day4start,day3start-1,false);
   CreateTrendline(0,appnamespace+"LipstickDay4Low",CornflowerBlue,2,STYLE_DASH,day4low,day4low,day4start,day3start-1,false);

   if(lipstickmode<LipStickMode2)
      return true;

   MqlRates r2[20];
   if(CopyRates(_Symbol,PERIOD_W1,0,20,r2)<20)
      return false;
   
   for(int i=10;i<=19;i++)
   {
      //CreateTrendline(0,appnamespace+"LipstickNWOGO"+IntegerToString(i),DimGray,2,STYLE_SOLID,r2[i].open,r2[i].open,r2[i].time,r2[i].time+(86400*3));
      //CreateTrendline(0,appnamespace+"LipstickNWOGC"+IntegerToString(i),DimGray,2,STYLE_SOLID,r2[i-1].close,r2[i-1].close,r2[i].time,r2[i].time+(86400*3));

      int cv=285-(i*4);
      //cv=248;
      //if(i>=16)
         //cv=180;
      CreateRectangle(0,appnamespace+"LipstickNWOGRect"+IntegerToString(i),(cv<<16)+(cv<<8)+(cv),r2[i].open,r2[i-1].close,r2[i].time,r2[19].time+PeriodSeconds(PERIOD_W1));
      double middle=r2[i].open-((r2[i].open-r2[i-1].close)/2);
      CreateTrendline(0,appnamespace+"LipstickNWOGM"+IntegerToString(i),White,1,STYLE_DOT,middle,middle,r2[i].time,r2[i].time+(86400*3));
   }
   return true;
}


void CreateRectangle(long chartid, string objname, color c, double price1, double price2, datetime time1=NULL, datetime time2=NULL)
{
   if(time1==NULL)
      time1=TimeCurrent()-4000000;
   if(time2==NULL)
      time2=TimeCurrent();
   if(ObjectFind(chartid,objname)<0)
   {
      ObjectCreate(chartid,objname,OBJ_RECTANGLE,0,0,0);
      ObjectSetInteger(chartid,objname,OBJPROP_FILL,true);
      ObjectSetInteger(chartid,objname,OBJPROP_COLOR,c);
      ObjectSetInteger(chartid,objname,OBJPROP_BGCOLOR,c);
      ObjectSetInteger(chartid,objname,OBJPROP_BACK,true);
   }
   ObjectSetDouble(chartid,objname,OBJPROP_PRICE,0,price1);
   ObjectSetInteger(chartid,objname,OBJPROP_TIME,0,time1);
   ObjectSetDouble(chartid,objname,OBJPROP_PRICE,1,price2);
   ObjectSetInteger(chartid,objname,OBJPROP_TIME,1,time2);
}


void CreateTrendline(long chartid, string objname, color c, int width, int style, double price1, double price2, datetime time1, datetime time2, bool rayright=true)
{
   if(ObjectFind(chartid,objname)<0)
   {
      ObjectCreate(chartid,objname,OBJ_TREND,0,0,0);
      ObjectSetInteger(chartid,objname,OBJPROP_COLOR,c);
      ObjectSetInteger(chartid,objname,OBJPROP_WIDTH,width);
      ObjectSetInteger(chartid,objname,OBJPROP_STYLE,style);
      ObjectSetInteger(chartid,objname,OBJPROP_RAY_RIGHT,rayright);
      ObjectSetInteger(chartid,objname,OBJPROP_BACK,true);
   }
   ObjectSetDouble(chartid,objname,OBJPROP_PRICE,0,price1);
   ObjectSetInteger(chartid,objname,OBJPROP_TIME,0,time1);
   ObjectSetDouble(chartid,objname,OBJPROP_PRICE,1,price2);
   ObjectSetInteger(chartid,objname,OBJPROP_TIME,1,time2);
}


void DeleteLipstick()
{
   ObjectsDeleteAll(0,appnamespace+"Lipstick");
   ChartRedraw();
}


void DrawTimelines(datetime time)
{
   long chartid=ChartFirst();
   while(chartid>-1)
   {
      if(chartid!=ChartID() && ChartPeriod(chartid)==Period())
         DrawTimeline(chartid,time);
      chartid=ChartNext(chartid);
   }
}


void DrawTimeline(long chartid, datetime time)
{
   string objname=appnamespace+"Timeline";
   if(ObjectFind(chartid,objname)<0)
   {
      ObjectCreate(chartid,objname,OBJ_VLINE,0,0,0);
      ObjectSetInteger(chartid,objname,OBJPROP_COLOR,ChartGetInteger(chartid,CHART_COLOR_FOREGROUND));
      ObjectSetInteger(chartid,objname,OBJPROP_WIDTH,1);
      ObjectSetInteger(chartid,objname,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(chartid,objname,OBJPROP_BACK,true);
   }
   ObjectSetInteger(chartid,objname,OBJPROP_TIME,time);
   ChartRedraw(chartid);
}


void DeleteTimelines()
{
   long chartid=ChartFirst();
   while(chartid>-1)
   {
      if(chartid!=ChartID())
      {
         ObjectsDeleteAll(chartid,appnamespace+"Timeline");
         ChartRedraw(chartid);
      }
      chartid=ChartNext(chartid);
   }
}


void SetAutoScroll(bool value)
{
   long chartid=ChartFirst();
   while(chartid>-1)
   {
      if(ChartPeriod(chartid)==Period())
      {
         ChartSetInteger(chartid,CHART_AUTOSCROLL,value);
         ChartRedraw(chartid);
      }
      chartid=ChartNext(chartid);
   }
}


void SyncChartScroll(datetime time)
{
   long chartid=ChartFirst();
   while(chartid>-1)
   {
      if(chartid!=ChartID() && ChartPeriod(chartid)==Period())
      {
         datetime dt=0;
         double price=0;
         int window=0;
         if(ChartXYToTimePrice(chartid,0,0,window,dt,price))
         {
            int bars=Bars(ChartSymbol(chartid),Period(),time,dt);
            bars-=1;
            if(time>dt)
               bars=0-bars;

            bars=-bars;

            //Print(ChartSymbol(chartid)+" Bars:"+bars);
            
            if(bars!=0)
            {
               ChartNavigate(chartid,CHART_CURRENT_POS,bars);
               EventChartCustom(chartid,5000,0,0,"");
            }
            
         }
      }
      chartid=ChartNext(chartid);
   }
}


void BroadcastMode(int _lipstickmode)
{
   long chartid=ChartFirst();
   while(chartid>-1)
   {
      if(chartid!=ChartID())
         EventChartCustom(chartid,5001,_lipstickmode,0,"");

      chartid=ChartNext(chartid);
   }
}


void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if(id==CHARTEVENT_MOUSE_MOVE)
   {
      uint state=(uint)sparam;
      if((state&16)==16)
      {
         SetAutoScroll(false);
         crosshairon=true;
      }
      if(((state&2)==2 || (state&1)==1) && crosshairon)
      {
         DeleteTimelines();
         SetAutoScroll(true);
         crosshairon=false;
      }
         
      if(crosshairon)
      {
         int x=(int)lparam;
         int y=(int)dparam;
         datetime dt=0;
         double price=0;
         int window=0;
         if(ChartXYToTimePrice(0,x,y,window,dt,price))
         {
            //PrintFormat("Window=%d X=%d  Y=%d  =>  Time=%s  Price=%G SParam=%s",window,x,y,TimeToString(dt),price,sparam);
            DrawTimelines(dt);
         }
      }
   }
   
   if(id==CHARTEVENT_CHART_CHANGE || id-CHARTEVENT_CUSTOM==5000)
   {
      long firstvisible=ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR);
      long visiblebars=ChartGetInteger(0,CHART_VISIBLE_BARS);
      if(firstvisible>visiblebars-1)
         firstbar=firstvisible-visiblebars+1;
      else
         firstbar=0;

      if(crosshairon)
      {
         datetime dt=0;
         double price=0;
         int window=0;
         if(ChartXYToTimePrice(0,0,0,window,dt,price))
            SyncChartScroll(dt);
      }
   }

   if(id-CHARTEVENT_CUSTOM==5001)
   {
      lipstickmode=(int)lparam;
   }

   
   if(id==CHARTEVENT_KEYDOWN)
   {
      if (lparam == 76)
      {
         if((lipstickmode+1)>LipStickMode2)
            lipstickmode=LipStickNone;
         else
            lipstickmode++;
            
         BroadcastMode(lipstickmode);
      }
   }
}


int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   return(rates_total);
}
