//+------------------------------------------------------------------+
//|                                                       SR_TLB.mq5 |
//|                     Support and Resistance MTF Trend Line Breaks |
//|                                  Copyright 2008, Ulterior (FF) |
//|        Code migrated from MQL4 to MQL5 by getYourNet IT Services |
//|                                                www.getyournet.ch |
//+------------------------------------------------------------------+
#property copyright "Copyright 2008, Ulterior (FF)"
#property link      "http://localhost"

#property indicator_chart_window
#property indicator_buffers 0

input int LB = 3;
input int maxBarsForPeriod = 1000; // Max Bars
input bool showM01 = true; // Show M1
input bool showM05 = true; // Show M5
input bool showM15 = true; // Show M15
input bool showM30 = true; // Show M30
input bool showH01 = true; // Show H1
input bool showH04 = true; // Show H4
input bool showD01 = true; // Show D1
input bool showW01 = true; // Show W1
input bool showMN1 = true; // Show MN1
input bool ShowLineLabels = true; // Show Line Labels
input int LabelShift = 3; // Label Shift
input int LabelCShift = 10; // Label C Shift

string objectnameprefix = "SR-MTF-";

static datetime prevBarTime_M01 = NULL;  
static datetime prevBarTime_M05 = NULL;  
static datetime prevBarTime_M15 = NULL;  
static datetime prevBarTime_M30 = NULL;  
static datetime prevBarTime_H01 = NULL;  
static datetime prevBarTime_H04 = NULL;  
static datetime prevBarTime_D01 = NULL;  
static datetime prevBarTime_W01 = NULL;  
static datetime prevBarTime_MN1 = NULL;  

static datetime prevBarCount_M01 = NULL;  
static datetime prevBarCount_M05 = NULL;  
static datetime prevBarCount_M15 = NULL;  
static datetime prevBarCount_M30 = NULL;  
static datetime prevBarCount_H01 = NULL;  
static datetime prevBarCount_H04 = NULL;  
static datetime prevBarCount_D01 = NULL;  
static datetime prevBarCount_W01 = NULL;  
static datetime prevBarCount_MN1 = NULL;  

double TLBMax_M01[];
double TLBMax_M05[];
double TLBMax_M15[];
double TLBMax_M30[];
double TLBMax_H01[];
double TLBMax_H04[];
double TLBMax_D01[];
double TLBMax_W01[];
double TLBMax_MN1[];

double TLBMin_M01[];
double TLBMin_M05[];
double TLBMin_M15[];
double TLBMin_M30[];
double TLBMin_H01[];
double TLBMin_H04[];
double TLBMin_D01[];
double TLBMin_W01[];
double TLBMin_MN1[];

datetime timebar0;
datetime timebar1;
bool dataloaderror;
bool dataloadattempts=0;


void OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME,"Support and Resistance MTF Trend Line Breaks");
   Reset();
}


void Reset()
{
   set_prevBarTime( PERIOD_M1, NULL );
   set_prevBarTime( PERIOD_M5, NULL );
   set_prevBarTime( PERIOD_M15, NULL );
   set_prevBarTime( PERIOD_M30, NULL );
   set_prevBarTime( PERIOD_H1, NULL );
   set_prevBarTime( PERIOD_H4, NULL );
   set_prevBarTime( PERIOD_D1, NULL );
   set_prevBarTime( PERIOD_W1, NULL );
   set_prevBarTime( PERIOD_MN1, NULL );

   set_prevBarCount( PERIOD_M1, NULL );
   set_prevBarCount( PERIOD_M5, NULL );
   set_prevBarCount( PERIOD_M15, NULL );
   set_prevBarCount( PERIOD_M30, NULL );
   set_prevBarCount( PERIOD_H1, NULL );
   set_prevBarCount( PERIOD_H4, NULL );
   set_prevBarCount( PERIOD_D1, NULL );
   set_prevBarCount( PERIOD_W1, NULL );
   set_prevBarCount( PERIOD_MN1, NULL );

   InitBuffer(0,TLBMax_M01);
   InitBuffer(1,TLBMax_M05);
   InitBuffer(2,TLBMax_M15);
   InitBuffer(3,TLBMax_M30);
   InitBuffer(4,TLBMax_H01);
   InitBuffer(5,TLBMax_H04);
   InitBuffer(6,TLBMax_D01);
   InitBuffer(7,TLBMax_W01);
   InitBuffer(8,TLBMax_MN1);

   InitBuffer(9,TLBMin_M01);
   InitBuffer(10,TLBMin_M05);
   InitBuffer(11,TLBMin_M15);
   InitBuffer(12,TLBMin_M30);
   InitBuffer(13,TLBMin_H01);
   InitBuffer(14,TLBMin_H04);
   InitBuffer(15,TLBMin_D01);
   InitBuffer(16,TLBMin_W01);
   InitBuffer(17,TLBMin_MN1);
}


void InitBuffer(int index, double &IArray[])
{
   SetIndexBuffer(index, IArray, INDICATOR_CALCULATIONS);
   ArrayInitialize(IArray,NULL);
   ArraySetAsSeries(IArray, true);
}


void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,objectnameprefix);
   ChartRedraw();
   EventKillTimer();
}


double Diap( int mtPeriod, bool up, int C, int shift )
{ 
   int i;
   double MM=0;
   if(up)
     {
       MM = get_max( mtPeriod, shift );
       for(i = 1; i < C; i++)
           if(get_max( mtPeriod, shift-i ) > MM)
               MM = get_max( mtPeriod, shift-i );  
     }
   if(!up)
     {
       MM = get_min( mtPeriod, shift );
       for(i = 1; i < C; i++)
           if(get_min( mtPeriod, shift-i ) < MM)
               MM = get_min( mtPeriod, shift-i );  
     }  
  return(MM);
}

  
void EmulateDoubleBuffer( double &buffer[], int numBars )
{
   if(ArraySize(buffer) < numBars)
     {
       ArraySetAsSeries(buffer, false);
       ArrayResize(buffer, numBars); 
       ArraySetAsSeries(buffer, true);
     } 
}  


void DeleteHLineObject(string name)
{
   ObjectDelete(0, objectnameprefix + name);
   ObjectDelete(0, objectnameprefix + name + "_Label");
   ChartRedraw();
}


void ShowHLineObject(string name, color clr, int style, double dValue, int shift )
{
   if(ObjectFind(0, objectnameprefix + name)!= 0)
   {
      CreateHLineObject(objectnameprefix + name,clr, style, dValue, shift, name);         
   }    
   
   if(ShowLineLabels)
   {
      ObjectSetDouble(0, objectnameprefix + name + "_Label",OBJPROP_PRICE,dValue);
      SetLabelTime(name, shift);
      ObjectSetInteger(0, objectnameprefix + name + "_Label",OBJPROP_STYLE, style);
   }
   
   ObjectSetDouble(0, objectnameprefix + name,OBJPROP_PRICE,dValue);
   ChartRedraw();
}


void SetLabelTime(string name, int shift)
{
   string labelname = objectnameprefix + name + "_Label";
   if(ObjectFind(0, labelname)== 0)
   {
      ObjectSetInteger(0, labelname,OBJPROP_TIME,timebar0+((timebar0-timebar1)*shift));
   }    
}


void CreateHLineObject(string name, color clr, int style, double dValue, int shift, string text)
{
   if(ShowLineLabels)
   {
      ObjectCreate(0, name + "_Label", OBJ_TEXT, 0, timebar0+((timebar0-timebar1)*shift), dValue); 
      ObjectSetString(0, name + "_Label", OBJPROP_TEXT, text);
      ObjectSetString(0, name + "_Label", OBJPROP_FONT, "Calibri");
      ObjectSetInteger(0, name + "_Label", OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, name + "_Label", OBJPROP_COLOR, clr);
   }
   
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, dValue);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style );
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
}


string getPeriodAsString( int mtPeriod )
{
 string periodname = "";
 switch( mtPeriod )
 {
  case PERIOD_M1:  { periodname = "M1"; break; }
  case PERIOD_M5:  { periodname = "M5"; break; }
  case PERIOD_M15: { periodname = "M15"; break; }
  case PERIOD_M30: { periodname = "M30"; break; }
  case PERIOD_H1:  { periodname = "H1"; break; }
  case PERIOD_H4:  { periodname = "H4"; break; }
  case PERIOD_D1:  { periodname = "D1"; break; }
  case PERIOD_W1:  { periodname = "W1"; break; }
  case PERIOD_MN1: { periodname = "MN1"; break; }
 }
 
 return (periodname);
}

    
void set_prevBarTime( int mtPeriod, datetime value )
{
 switch( mtPeriod )
 {
  case PERIOD_M1:  { prevBarTime_M01 = value; break; }
  case PERIOD_M5:  { prevBarTime_M05 = value; break; }
  case PERIOD_M15: { prevBarTime_M15 = value; break; }
  case PERIOD_M30: { prevBarTime_M30 = value; break; }
  case PERIOD_H1:  { prevBarTime_H01 = value; break; }
  case PERIOD_H4:  { prevBarTime_H04 = value; break; }
  case PERIOD_D1:  { prevBarTime_D01 = value; break; }
  case PERIOD_W1:  { prevBarTime_W01 = value; break; }
  case PERIOD_MN1: { prevBarTime_MN1 = value; break; } 
 }
}


datetime get_prevBarTime( int mtPeriod )
{
 switch( mtPeriod )
 {
  case PERIOD_M1:  { return (prevBarTime_M01); break; }
  case PERIOD_M5:  { return (prevBarTime_M05); break; }
  case PERIOD_M15: { return (prevBarTime_M15); break; }
  case PERIOD_M30: { return (prevBarTime_M30); break; }
  case PERIOD_H1:  { return (prevBarTime_H01); break; }
  case PERIOD_H4:  { return (prevBarTime_H04); break; }
  case PERIOD_D1:  { return (prevBarTime_D01); break; }
  case PERIOD_W1:  { return (prevBarTime_W01); break; }
  case PERIOD_MN1: { return (prevBarTime_MN1); break; } 
 }
 return 0;
}
    
    
void set_prevBarCount( int mtPeriod, int value )
{
 switch( mtPeriod )
 {
  case PERIOD_M1:  { prevBarCount_M01 = value; break; }
  case PERIOD_M5:  { prevBarCount_M05 = value; break; }
  case PERIOD_M15: { prevBarCount_M15 = value; break; }
  case PERIOD_M30: { prevBarCount_M30 = value; break; }
  case PERIOD_H1:  { prevBarCount_H01 = value; break; }
  case PERIOD_H4:  { prevBarCount_H04 = value; break; }
  case PERIOD_D1:  { prevBarCount_D01 = value; break; }
  case PERIOD_W1:  { prevBarCount_W01 = value; break; }
  case PERIOD_MN1: { prevBarCount_MN1 = value; break; } 
 }
}


int get_prevBarCount( int mtPeriod )
{
 switch( mtPeriod )
 {
  case PERIOD_M1:  { return (prevBarCount_M01); break; }
  case PERIOD_M5:  { return (prevBarCount_M05); break; }
  case PERIOD_M15: { return (prevBarCount_M15); break; }
  case PERIOD_M30: { return (prevBarCount_M30); break; }
  case PERIOD_H1:  { return (prevBarCount_H01); break; }
  case PERIOD_H4:  { return (prevBarCount_H04); break; }
  case PERIOD_D1:  { return (prevBarCount_D01); break; }
  case PERIOD_W1:  { return (prevBarCount_W01); break; }
  case PERIOD_MN1: { return (prevBarCount_MN1); break; } 
 }
 return 0;
}

    
void set_max( int mtPeriod, int shift, double value )
{
 switch( mtPeriod )
 {
  case PERIOD_M1:  { TLBMax_M01[ shift ] = value; break; }
  case PERIOD_M5:  { TLBMax_M05[ shift ] = value; break; }
  case PERIOD_M15: { TLBMax_M15[ shift ] = value; break; }
  case PERIOD_M30: { TLBMax_M30[ shift ] = value; break; }
  case PERIOD_H1:  { TLBMax_H01[ shift ] = value; break; }
  case PERIOD_H4:  { TLBMax_H04[ shift ] = value; break; }
  case PERIOD_D1:  { TLBMax_D01[ shift ] = value; break; }
  case PERIOD_W1:  { TLBMax_W01[ shift ] = value; break; }
  case PERIOD_MN1: { TLBMax_MN1[ shift ] = value; break; }
 }
}


double get_max( int mtPeriod, int shift )
{
 switch( mtPeriod )
 {
  case PERIOD_M1:  { return(TLBMax_M01[ shift ]); break; }
  case PERIOD_M5:  { return(TLBMax_M05[ shift ]); break; }
  case PERIOD_M15: { return(TLBMax_M15[ shift ]); break; }
  case PERIOD_M30: { return(TLBMax_M30[ shift ]); break; }
  case PERIOD_H1:  { return(TLBMax_H01[ shift ]); break; }
  case PERIOD_H4:  { return(TLBMax_H04[ shift ]); break; }
  case PERIOD_D1:  { return(TLBMax_D01[ shift ]); break; }
  case PERIOD_W1:  { return(TLBMax_W01[ shift ]); break; }
  case PERIOD_MN1: { return(TLBMax_MN1[ shift ]); break; }
 }
 return 0;
}


void set_min( int mtPeriod, int shift, double value )
{
 switch( mtPeriod )
 {
  case PERIOD_M1:  { TLBMin_M01[ shift ] = value; break; }
  case PERIOD_M5:  { TLBMin_M05[ shift ] = value; break; }
  case PERIOD_M15: { TLBMin_M15[ shift ] = value; break; }
  case PERIOD_M30: { TLBMin_M30[ shift ] = value; break; }
  case PERIOD_H1:  { TLBMin_H01[ shift ] = value; break; }
  case PERIOD_H4:  { TLBMin_H04[ shift ] = value; break; }
  case PERIOD_D1:  { TLBMin_D01[ shift ] = value; break; }
  case PERIOD_W1:  { TLBMin_W01[ shift ] = value; break; }
  case PERIOD_MN1: { TLBMin_MN1[ shift ] = value; break; }
 }
}


double get_min( int mtPeriod, int shift )
{
 switch( mtPeriod )
 {
  case PERIOD_M1:  { return(TLBMin_M01[ shift ]); break; }
  case PERIOD_M5:  { return(TLBMin_M05[ shift ]); break; }
  case PERIOD_M15: { return(TLBMin_M15[ shift ]); break; }
  case PERIOD_M30: { return(TLBMin_M30[ shift ]); break; }
  case PERIOD_H1:  { return(TLBMin_H01[ shift ]); break; }
  case PERIOD_H4:  { return(TLBMin_H04[ shift ]); break; }
  case PERIOD_D1:  { return(TLBMin_D01[ shift ]); break; }
  case PERIOD_W1:  { return(TLBMin_W01[ shift ]); break; }
  case PERIOD_MN1: { return(TLBMin_MN1[ shift ]); break; }
 }
 return 0;
}


void emulate_tlbmaxmin( int mtPeriod, int numBars )
{
 switch( mtPeriod )
 {
  case PERIOD_M1:  { EmulateDoubleBuffer(TLBMax_M01, numBars ); EmulateDoubleBuffer(TLBMin_M01, numBars ); break; }
  case PERIOD_M5:  { EmulateDoubleBuffer(TLBMax_M05, numBars ); EmulateDoubleBuffer(TLBMin_M05, numBars ); break; }
  case PERIOD_M15: { EmulateDoubleBuffer(TLBMax_M15, numBars ); EmulateDoubleBuffer(TLBMin_M15, numBars ); break; }
  case PERIOD_M30: { EmulateDoubleBuffer(TLBMax_M30, numBars ); EmulateDoubleBuffer(TLBMin_M30, numBars ); break; }
  case PERIOD_H1:  { EmulateDoubleBuffer(TLBMax_H01, numBars ); EmulateDoubleBuffer(TLBMin_H01, numBars ); break; }
  case PERIOD_H4:  { EmulateDoubleBuffer(TLBMax_H04, numBars ); EmulateDoubleBuffer(TLBMin_H04, numBars ); break; }
  case PERIOD_D1:  { EmulateDoubleBuffer(TLBMax_D01, numBars ); EmulateDoubleBuffer(TLBMin_D01, numBars ); break; }
  case PERIOD_W1:  { EmulateDoubleBuffer(TLBMax_W01, numBars ); EmulateDoubleBuffer(TLBMin_W01, numBars ); break; }
  case PERIOD_MN1: { EmulateDoubleBuffer(TLBMax_MN1, numBars ); EmulateDoubleBuffer(TLBMin_MN1, numBars ); break; }
 }
}   


void displayPeriod( int mtPeriod )
{
   datetime TimeArr[];
   int received = -1;
   received = CopyTime(Symbol(), TFMigrate(mtPeriod), 0, 1, TimeArr);
   if(received==-1)
   {
      Print("CopyTime failed " + getPeriodAsString(mtPeriod));
      dataloaderror = true;
      return;
   }

   double CloseArr[];
   ArraySetAsSeries(CloseArr,true);

   received = -1;
   received = CopyClose(Symbol(), TFMigrate(mtPeriod), 0, maxBarsForPeriod, CloseArr);
   if(received==-1)
   {
      Print("CopyClose failed " + getPeriodAsString(mtPeriod));
      dataloaderror = true;
      return;
   }


  if( get_prevBarTime( mtPeriod ) == NULL || get_prevBarTime( mtPeriod ) != TimeArr[0] ||
      get_prevBarCount( mtPeriod ) == NULL || get_prevBarCount( mtPeriod ) != Bars(Symbol(), TFMigrate(mtPeriod)) )
  {
   set_prevBarTime( mtPeriod, TimeArr[0]);
   set_prevBarCount( mtPeriod, Bars(Symbol(), TFMigrate(mtPeriod)));
  } 
  else return;

  int numBars = Bars(Symbol(), TFMigrate(mtPeriod));
  if( maxBarsForPeriod > 0 && numBars > maxBarsForPeriod ) numBars = maxBarsForPeriod; 
  int TLBBuffShift = 0;
  int limit=numBars;

  emulate_tlbmaxmin( mtPeriod, numBars );
  
   int i, j;
   j = 1;
   while( CloseArr[limit-1] == CloseArr[limit-1-j] )
   {
       j++;
       if(j > limit-1)
        break;
   }    
      
   if(CloseArr[limit-1] > CloseArr[limit-1-j])
     {
       set_max( mtPeriod, 0, CloseArr[limit-1]);
       set_min( mtPeriod, 0, CloseArr[limit-1-j]);
     } 
   if(CloseArr[limit-1] < CloseArr[limit-1-j])
     {
       set_max( mtPeriod, 0, CloseArr[limit-1-j]);
       set_min( mtPeriod, 0, CloseArr[limit-1]);
     } 
   
   for(i = 1; i < LB; i++)
     {
       while(CloseArr[limit-j] <= Diap(mtPeriod, true, i, TLBBuffShift) && CloseArr[limit-j] >= Diap(mtPeriod, false, i, TLBBuffShift))
       {
         j++;

         if(j > limit-1)
         break;
       }     
       if(j > limit-1)
           break;   

       if(CloseArr[limit-j] > get_max( mtPeriod, i-1 ))
         {
           set_max( mtPeriod, i, CloseArr[limit-j]);
           set_min( mtPeriod, i, get_max( mtPeriod, i-1 ));
           TLBBuffShift++;
         }
       if(CloseArr[limit-j] < get_min( mtPeriod, i-1 ))
         {
           set_min( mtPeriod, i, CloseArr[limit-j]);
           set_max( mtPeriod, i, get_min( mtPeriod, i-1 ));
           TLBBuffShift++;
         }  
     }
     
   for(i = LB; i < limit; i++)   
     {    
       while(CloseArr[limit-j] <= Diap(mtPeriod, true, LB, TLBBuffShift) && CloseArr[limit-j] >= Diap(mtPeriod, false, LB, TLBBuffShift))
         {
           j++;
           if(j > limit-1)
               break;
         }
       if(j > limit-1)
           break;   

       if(CloseArr[limit-j] > get_max( mtPeriod, i-1 ))
         {
           set_max( mtPeriod, i, CloseArr[limit-j]);
           set_min( mtPeriod, i, get_max( mtPeriod, i-1 ));
           TLBBuffShift++;
         }
       if(CloseArr[limit-j] < get_min( mtPeriod, i-1 ))
         {
           set_min( mtPeriod, i, CloseArr[limit-j]);
           set_max( mtPeriod, i, get_min( mtPeriod, i-1 ));
           TLBBuffShift++;
         }  
     }
   
   double sup = 0, res = 0, supc = 0, resc = 0;   
   int redCnt=0, blueCnt=0; 
   int numObj = 0;  
   for(i = 1; i <= TLBBuffShift; i++)
     {
       if(get_max( mtPeriod, i ) > get_max( mtPeriod, i-1 ))
         {
           if( blueCnt >= LB )   
            sup = get_max( mtPeriod, i-LB );
           else
            sup = get_min( mtPeriod, i-blueCnt-1 ); 
           
           resc = get_max( mtPeriod, i );
           supc = 0;
           res = 0;

           blueCnt++;
           redCnt=0;                        
         }
       if(get_max( mtPeriod, i ) < get_max( mtPeriod, i-1 ))
         {
           if( redCnt >= LB )   
            res = get_min( mtPeriod, i-LB );
           else
            res = get_max( mtPeriod, i-redCnt-1 );

           supc = get_min( mtPeriod, i );
           sup = 0;
           resc = 0;
           
           blueCnt=0;
           redCnt++;             
         }
       
     }

   string oname;
   string pname = getPeriodAsString( mtPeriod );
   
   oname = pname + " Sup";
   if( sup > 0.0 )
      ShowHLineObject(oname , C'0,172,230', STYLE_SOLID, sup, LabelShift );
   else
      DeleteHLineObject(oname);
   
   oname = pname + " Res";
   if( res > 0.0 )
      ShowHLineObject(oname, C'251,0,138', STYLE_SOLID, res, LabelShift );
   else
      DeleteHLineObject(oname);
   
   oname = pname + " Sup C";
   if( supc > 0.0 )
      ShowHLineObject(oname, C'0,172,230', STYLE_DOT, supc, LabelCShift );
   else
      DeleteHLineObject(oname);
   
   oname = pname + " Res C";
   if( resc > 0.0 )
      ShowHLineObject(oname, C'251,0,138', STYLE_DOT, resc, LabelCShift );            
   else
      DeleteHLineObject(oname);             
}


void SetLabels(int mtPeriod)
{
   SetLabelTime(getPeriodAsString(mtPeriod)+" Sup",LabelShift);
   SetLabelTime(getPeriodAsString(mtPeriod)+" Res",LabelShift);
   SetLabelTime(getPeriodAsString(mtPeriod)+" Sup C",LabelCShift);
   SetLabelTime(getPeriodAsString(mtPeriod)+" Res C",LabelCShift);
   ChartRedraw();
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
                const int &spread[]
                )
{

   ArraySetAsSeries(time,true);
   timebar0 = time[0];
   timebar1 = time[1];

   if(rates_total > prev_calculated)
   {
      dataloadattempts = 0;
      EventSetTimer(1);
   }

   return(rates_total);
}


void OnTimer()
{
   EventKillTimer();
   dataloaderror = false;
   dataloadattempts++;

   Print("OnTimer - Trying to load Histories");

   if( Period() <= PERIOD_M1 && showM01 ) displayPeriod(PERIOD_M1);
   if( Period() <= PERIOD_M5 && showM05 ) displayPeriod(PERIOD_M5);
   if( Period() <= PERIOD_M15 && showM15 ) displayPeriod(PERIOD_M15);
   if( Period() <= PERIOD_M30 && showM30 ) displayPeriod(PERIOD_M30);
   if( Period() <= PERIOD_H1 && showH01 ) displayPeriod(PERIOD_H1);
   if( Period() <= PERIOD_H4 && showH04 ) displayPeriod(PERIOD_H4);
   if( Period() <= PERIOD_D1 && showD01 ) displayPeriod(PERIOD_D1);
   if( Period() <= PERIOD_W1 && showW01 ) displayPeriod(PERIOD_W1);
   if( Period() <= PERIOD_MN1 && showMN1 ) displayPeriod(PERIOD_MN1);

   SetLabels(PERIOD_M1);
   SetLabels(PERIOD_M5);
   SetLabels(PERIOD_M15);
   SetLabels(PERIOD_M30);
   SetLabels(PERIOD_H1);
   SetLabels(PERIOD_H4);
   SetLabels(PERIOD_D1);
   SetLabels(PERIOD_W1);
   SetLabels(PERIOD_MN1);

   if(dataloaderror && dataloadattempts <= 50)
      EventSetTimer(5);
}


ENUM_TIMEFRAMES TFMigrate(int tf)
{
   switch(tf)
     {
      case 0: return(PERIOD_CURRENT);
      case 1: return(PERIOD_M1);
      case 5: return(PERIOD_M5);
      case 15: return(PERIOD_M15);
      case 30: return(PERIOD_M30);
      case 60: return(PERIOD_H1);
      case 240: return(PERIOD_H4);
      case 1440: return(PERIOD_D1);
      case 10080: return(PERIOD_W1);
      case 43200: return(PERIOD_MN1);
      
      case 2: return(PERIOD_M2);
      case 3: return(PERIOD_M3);
      case 4: return(PERIOD_M4);      
      case 6: return(PERIOD_M6);
      case 10: return(PERIOD_M10);
      case 12: return(PERIOD_M12);
      case 16385: return(PERIOD_H1);
      case 16386: return(PERIOD_H2);
      case 16387: return(PERIOD_H3);
      case 16388: return(PERIOD_H4);
      case 16390: return(PERIOD_H6);
      case 16392: return(PERIOD_H8);
      case 16396: return(PERIOD_H12);
      case 16408: return(PERIOD_D1);
      case 32769: return(PERIOD_W1);
      case 49153: return(PERIOD_MN1);      
      default: return(PERIOD_CURRENT);
     }
}

