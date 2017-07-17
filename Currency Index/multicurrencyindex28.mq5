//+------------------------------------------------------------------+
//|                                         MultiCurrencyIndex28.mq5 |
//|     Price and RSI Calculations copied from Corr_RSI.mq4 - mladen |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "2017, getYourNet.ch"
#property version   "1.0"
#property indicator_separate_window

#property indicator_buffers 52
#property indicator_plots   8

#include <MovingAverages.mqh>

enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_tbiased2,   // Trend biased (extreme) price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased,  // Heiken ashi trend biased price
   pr_hatbiased2  // Heiken ashi trend biased (extreme) price
};

input enPrices PriceType = pr_close; // Price Type
input int rsi_period = 9; // RSI Period
input int ma_period = 6; // MA Period
input int ma_smoothing = 3; // MA Smoothing
input int shiftbars = 300; // Number of Bars to calculate

input color Color_USD = SeaGreen;            // USD line color
input color Color_EUR = DarkSlateBlue;         // EUR line color
input color Color_GBP = DeepPink;              // GBP line color
input color Color_CHF = Black;        // CHF line color
input color Color_JPY = Maroon;           // JPY line color
input color Color_AUD = DarkOrange;       // AUD line color
input color Color_CAD = MediumVioletRed;           // CAD line color
input color Color_NZD = Gray;         // NZD line color

input int                wid_main =         2; //Lines width for current chart
input ENUM_LINE_STYLE style_slave = STYLE_DOT; //Style of alternative lines for current chart
input bool all_solid = false; //Draw all main style


double  EURUSD[], // quotes
        GBPUSD[],
        USDCHF[],
        USDJPY[],
        AUDUSD[],
        USDCAD[],
        NZDUSD[],
        
         EURNZD[],
         EURCAD[],
         EURAUD[],
         EURJPY[],
         EURCHF[],
         EURGBP[],

         GBPNZD[],
         GBPAUD[],
         GBPCAD[],
         GBPJPY[],
         GBPCHF[],

         CADJPY[],
         CADCHF[],
         AUDCAD[],
         NZDCAD[],

         AUDCHF[],
         AUDJPY[],
         AUDNZD[],

         NZDJPY[],
         NZDCHF[],
         CHFJPY[];

        
double    USDx[], // indexes
          EURx[],
          GBPx[],
          JPYx[],
          CHFx[],
          CADx[],
          AUDx[],
          NZDx[];                         
double USDplot[], // results of currency lines
       EURplot[],
       GBPplot[],
       JPYplot[],
       CHFplot[],
       CADplot[],
       AUDplot[],
       NZDplot[]; 
double USDrsi[], // buffers of intermediate data rsi
       EURrsi[],
       GBPrsi[],
       JPYrsi[],
       CHFrsi[],
       CADrsi[],
       AUDrsi[],
       NZDrsi[];

int         y_pos = 3; // Y coordinate variable for the informatory objects  
datetime   arrTime[]; // Array with the last known time of a zero valued bar (needed for synchronization)  
int        bars_tf[]; // To check the number of available bars in different currency pairs  
int         index = 0;
datetime  tmp_time[1]; // Intermediate array for the time of the bar 
string namespace = "MultiCurrencyIndex28";


void InitBuffer(int idx, double& buffer[], ENUM_INDEXBUFFER_TYPE data_type, string currency=NULL, color col=NULL)
{
   SetIndexBuffer(idx,buffer,data_type);
   ArraySetAsSeries(buffer,true);
   ArrayInitialize(buffer,EMPTY_VALUE);
   if(currency!=NULL)
   {
      PlotIndexSetString(idx,PLOT_LABEL,currency+"plot");
      PlotIndexSetInteger(idx,PLOT_DRAW_BEGIN,shiftbars);
      PlotIndexSetInteger(idx,PLOT_DRAW_TYPE,DRAW_LINE);
      PlotIndexSetInteger(idx,PLOT_LINE_COLOR,col);
      if(StringFind(Symbol(),currency,0)!=-1 || all_solid)
      {
        PlotIndexSetInteger(idx,PLOT_LINE_WIDTH,wid_main);
        PlotIndexSetInteger(idx,PLOT_LINE_STYLE,STYLE_SOLID);
      }
      else
      {
        PlotIndexSetInteger(idx,PLOT_LINE_WIDTH,1);
        PlotIndexSetInteger(idx,PLOT_LINE_STYLE,style_slave);
      }
      f_draw(currency,col);
   }
}


void OnInit()
{
   IndicatorSetInteger(INDICATOR_DIGITS,1);                    // number of digits after period, if RSI or Stochastic

   string nameInd="MultiCurrencyIndex28";
   nameInd+=" RSI("+IntegerToString(rsi_period)+")";
   IndicatorSetString(INDICATOR_SHORTNAME,nameInd);

   InitBuffer(0,USDplot,INDICATOR_DATA,"USD",Color_USD);
   InitBuffer(15,USDx,INDICATOR_CALCULATIONS);
   InitBuffer(23,USDrsi,INDICATOR_CALCULATIONS);

   InitBuffer(1,EURplot,INDICATOR_DATA,"EUR",Color_EUR);
   InitBuffer(8,EURUSD,INDICATOR_CALCULATIONS);
   InitBuffer(16,EURx,INDICATOR_CALCULATIONS);
   InitBuffer(24,EURrsi,INDICATOR_CALCULATIONS);

   InitBuffer(2,GBPplot,INDICATOR_DATA,"GBP",Color_GBP);
   InitBuffer(9,GBPUSD,INDICATOR_CALCULATIONS);
   InitBuffer(17,GBPx,INDICATOR_CALCULATIONS);
   InitBuffer(25,GBPrsi,INDICATOR_CALCULATIONS);

   InitBuffer(3,JPYplot,INDICATOR_DATA,"JPY",Color_JPY);
   InitBuffer(10,USDJPY,INDICATOR_CALCULATIONS);
   InitBuffer(18,JPYx,INDICATOR_CALCULATIONS);
   InitBuffer(26,JPYrsi,INDICATOR_CALCULATIONS);

   InitBuffer(4,CHFplot,INDICATOR_DATA,"CHF",Color_CHF);
   InitBuffer(11,USDCHF,INDICATOR_CALCULATIONS);
   InitBuffer(19,CHFx,INDICATOR_CALCULATIONS);
   InitBuffer(27,CHFrsi,INDICATOR_CALCULATIONS);

   InitBuffer(5,CADplot,INDICATOR_DATA,"CAD",Color_CAD);
   InitBuffer(12,USDCAD,INDICATOR_CALCULATIONS);
   InitBuffer(20,CADx,INDICATOR_CALCULATIONS);
   InitBuffer(28,CADrsi,INDICATOR_CALCULATIONS);

   InitBuffer(6,AUDplot,INDICATOR_DATA,"AUD",Color_AUD);
   InitBuffer(13,AUDUSD,INDICATOR_CALCULATIONS);
   InitBuffer(21,AUDx,INDICATOR_CALCULATIONS);
   InitBuffer(29,AUDrsi,INDICATOR_CALCULATIONS);

   InitBuffer(7,NZDplot,INDICATOR_DATA,"NZD",Color_NZD);
   InitBuffer(14,NZDUSD,INDICATOR_CALCULATIONS);
   InitBuffer(22,NZDx,INDICATOR_CALCULATIONS);
   InitBuffer(30,NZDrsi,INDICATOR_CALCULATIONS);


   InitBuffer(31,EURNZD,INDICATOR_CALCULATIONS);
   InitBuffer(32,EURCAD,INDICATOR_CALCULATIONS);
   InitBuffer(33,EURAUD,INDICATOR_CALCULATIONS);
   InitBuffer(34,EURJPY,INDICATOR_CALCULATIONS);
   InitBuffer(35,EURCHF,INDICATOR_CALCULATIONS);
   InitBuffer(36,EURGBP,INDICATOR_CALCULATIONS);

   InitBuffer(37,GBPNZD,INDICATOR_CALCULATIONS);
   InitBuffer(38,GBPAUD,INDICATOR_CALCULATIONS);
   InitBuffer(39,GBPCAD,INDICATOR_CALCULATIONS);
   InitBuffer(40,GBPJPY,INDICATOR_CALCULATIONS);
   InitBuffer(41,GBPCHF,INDICATOR_CALCULATIONS);

   InitBuffer(42,CADJPY,INDICATOR_CALCULATIONS);
   InitBuffer(43,CADCHF,INDICATOR_CALCULATIONS);
   InitBuffer(44,AUDCAD,INDICATOR_CALCULATIONS);
   InitBuffer(45,NZDCAD,INDICATOR_CALCULATIONS);

   InitBuffer(46,AUDCHF,INDICATOR_CALCULATIONS);
   InitBuffer(47,AUDJPY,INDICATOR_CALCULATIONS);
   InitBuffer(48,AUDNZD,INDICATOR_CALCULATIONS);

   InitBuffer(49,NZDJPY,INDICATOR_CALCULATIONS);
   InitBuffer(50,NZDCHF,INDICATOR_CALCULATIONS);
   InitBuffer(51,CHFJPY,INDICATOR_CALCULATIONS);

   //ArrayResize(arrTime,countVal-1);
   //ArrayResize(bars_tf,countVal-1);
   ArrayResize(arrTime,28);
   ArrayResize(bars_tf,28);
}


void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0,"namespace",ChartWindowFind());
}


int OnCalculate(const int     rates_total, // size of incoming time series
                const int prev_calculated, // processing of bars on the previous request
                const datetime&    time[], // Time
                const double&      open[], // Open
                const double&      high[], // High
                const double&       low[], // Low
                const double&     close[], // Close
                const long& tick_volume[], // Tick Volume
                const long&      volume[], // Real Volume
                const int&       spread[]) // Spread
{
   int i,ii;
   int limit=shiftbars;
   int notcalc=rates_total-shiftbars;

   if(prev_calculated>0)
     {limit=1;}
   else
     {limit=shiftbars;}

   init_tf();

   if(!GetRates("EURUSD",EURUSD)) return(0);
   if(!GetRates("GBPUSD",GBPUSD)) return(0);
   if(!GetRates("USDCHF",USDCHF)) return(0);
   if(!GetRates("USDJPY",USDJPY)) return(0);
   if(!GetRates("AUDUSD",AUDUSD)) return(0);
   if(!GetRates("USDCAD",USDCAD)) return(0);
   if(!GetRates("NZDUSD",NZDUSD)) return(0);
   
   if(!GetRates("EURNZD",EURNZD)) return(0);
   if(!GetRates("EURCAD",EURCAD)) return(0);
   if(!GetRates("EURAUD",EURAUD)) return(0);
   if(!GetRates("EURJPY",EURJPY)) return(0);
   if(!GetRates("EURCHF",EURCHF)) return(0);
   if(!GetRates("EURGBP",EURGBP)) return(0);

   if(!GetRates("GBPNZD",GBPNZD)) return(0);
   if(!GetRates("GBPAUD",GBPAUD)) return(0);
   if(!GetRates("GBPCAD",GBPCAD)) return(0);
   if(!GetRates("GBPJPY",GBPJPY)) return(0);
   if(!GetRates("GBPCHF",GBPCHF)) return(0);

   if(!GetRates("CADJPY",CADJPY)) return(0);
   if(!GetRates("CADCHF",CADCHF)) return(0);
   if(!GetRates("AUDCAD",AUDCAD)) return(0);
   if(!GetRates("NZDCAD",NZDCAD)) return(0);

   if(!GetRates("AUDCHF",AUDCHF)) return(0);
   if(!GetRates("AUDJPY",AUDJPY)) return(0);
   if(!GetRates("AUDNZD",AUDNZD)) return(0);

   if(!GetRates("NZDJPY",NZDJPY)) return(0);
   if(!GetRates("NZDCHF",NZDCHF)) return(0);
   if(!GetRates("CHFJPY",CHFJPY)) return(0);

   for(i=limit-1;i>=0;i--)
   {
      USDx[i]=1.0;
      USDx[i]+=EURUSD[i];
      USDx[i]+=GBPUSD[i];
      USDx[i]+=1/USDCHF[i];
      USDx[i]+=1/USDJPY[i];
      USDx[i]+=1/USDCAD[i];
      USDx[i]+=AUDUSD[i];
      USDx[i]+=NZDUSD[i];
      USDx[i]=1/USDx[i];

      //EURx[i]=EURUSD[i]*USDx[i];
      EURx[i]=1.0;
      EURx[i]+=1/EURUSD[i];
      EURx[i]+=1/EURNZD[i];
      EURx[i]+=1/EURCAD[i];
      EURx[i]+=1/EURAUD[i];
      EURx[i]+=1/EURJPY[i];
      EURx[i]+=1/EURCHF[i];
      EURx[i]+=1/EURGBP[i];
      EURx[i]=1/EURx[i];
      
      //GBPx[i]=GBPUSD[i]*USDx[i];
      GBPx[i]=1.0;
      GBPx[i]+=1/GBPUSD[i];
      GBPx[i]+=1/GBPNZD[i];
      GBPx[i]+=1/GBPAUD[i];
      GBPx[i]+=1/GBPCAD[i];
      GBPx[i]+=1/GBPJPY[i];
      GBPx[i]+=1/GBPCHF[i];
      GBPx[i]+=EURGBP[i];
      GBPx[i]=1/GBPx[i];


      //CHFx[i]=USDx[i]/USDCHF[i];
      CHFx[i]=1.0;
      CHFx[i]+=USDCHF[i];
      CHFx[i]+=EURCHF[i];
      CHFx[i]+=GBPCHF[i];
      CHFx[i]+=CADCHF[i];
      CHFx[i]+=AUDCHF[i];
      CHFx[i]+=NZDCHF[i];
      CHFx[i]+=1/CHFJPY[i];
      CHFx[i]=1/CHFx[i];
      
      
      //JPYx[i]=USDx[i]/USDJPY[i];
      JPYx[i]=1.0;
      JPYx[i]+=USDJPY[i];
      JPYx[i]+=EURJPY[i];
      JPYx[i]+=GBPJPY[i];
      JPYx[i]+=CADJPY[i];
      JPYx[i]+=AUDJPY[i];
      JPYx[i]+=NZDJPY[i];
      JPYx[i]+=CHFJPY[i];
      JPYx[i]=1/JPYx[i];


      //CADx[i]=USDx[i]/USDCAD[i];
      CADx[i]=1.0;
      CADx[i]+=USDCAD[i];
      CADx[i]+=EURCAD[i];
      CADx[i]+=GBPCAD[i];
      CADx[i]+=1/CADJPY[i];
      CADx[i]+=1/CADCHF[i];
      CADx[i]+=AUDCAD[i];
      CADx[i]+=NZDCAD[i];
      CADx[i]=1/CADx[i];


      //AUDx[i]=AUDUSD[i]*USDx[i];
      AUDx[i]=1.0;
      AUDx[i]+=1/AUDUSD[i];
      AUDx[i]+=EURAUD[i];
      AUDx[i]+=GBPAUD[i];
      AUDx[i]+=1/AUDCAD[i];
      AUDx[i]+=1/AUDCHF[i];
      AUDx[i]+=1/AUDJPY[i];
      AUDx[i]+=1/AUDNZD[i];
      AUDx[i]=1/AUDx[i];

      
      //NZDx[i]=NZDUSD[i]*USDx[i];
      NZDx[i]=1.0;
      NZDx[i]+=1/NZDUSD[i];
      NZDx[i]+=EURNZD[i];
      NZDx[i]+=GBPNZD[i];
      NZDx[i]+=1/NZDCAD[i];
      NZDx[i]+=AUDNZD[i];
      NZDx[i]+=1/NZDJPY[i];
      NZDx[i]+=1/NZDCHF[i];
      NZDx[i]=1/NZDx[i];

   }

   if(limit>1)
   {
      ii=limit-rsi_period-1;
   }
   else
   {
      ii=limit-1;
   }
   for(i=ii;i>=0;i--)
   {
      //USDrsi[i]=f_RSI(USDx,rsi_period,i);
      //EURrsi[i]=f_RSI(EURx,rsi_period,i);
      //GBPrsi[i]=f_RSI(GBPx,rsi_period,i);
      //CHFrsi[i]=f_RSI(CHFx,rsi_period,i);
      //JPYrsi[i]=f_RSI(JPYx,rsi_period,i);
      //CADrsi[i]=f_RSI(CADx,rsi_period,i);
      //AUDrsi[i]=f_RSI(AUDx,rsi_period,i);
      //NZDrsi[i]=f_RSI(NZDx,rsi_period,i);

      USDplot[i]=f_RSI(USDx,rsi_period,i);
      EURplot[i]=f_RSI(EURx,rsi_period,i);
      GBPplot[i]=f_RSI(GBPx,rsi_period,i);
      CHFplot[i]=f_RSI(CHFx,rsi_period,i);
      JPYplot[i]=f_RSI(JPYx,rsi_period,i);
      CADplot[i]=f_RSI(CADx,rsi_period,i);
      AUDplot[i]=f_RSI(AUDx,rsi_period,i);
      NZDplot[i]=f_RSI(NZDx,rsi_period,i);
   }
   int period=ma_period, smoothing=ma_smoothing, malimit=rates_total-shiftbars;
   if(limit==1)
      malimit=rates_total-1;

   //SimpleMAOnBuffer
   //ExponentialMAOnBuffer

   //SmoothedMAOnBuffer(rates_total,malimit,period,smoothing,USDrsi,USDplot);
   //SmoothedMAOnBuffer(rates_total,malimit,period,smoothing,EURrsi,EURplot);
   //SmoothedMAOnBuffer(rates_total,malimit,period,smoothing,GBPrsi,GBPplot);
   //SmoothedMAOnBuffer(rates_total,malimit,period,smoothing,CHFrsi,CHFplot);
   //SmoothedMAOnBuffer(rates_total,malimit,period,smoothing,JPYrsi,JPYplot);
   //SmoothedMAOnBuffer(rates_total,malimit,period,smoothing,CADrsi,CADplot);
   //SmoothedMAOnBuffer(rates_total,malimit,period,smoothing,AUDrsi,AUDplot);
   //SmoothedMAOnBuffer(rates_total,malimit,period,smoothing,NZDrsi,NZDplot);
   
   return(rates_total);
}


bool GetRates(string pair, double& buffer[])
{
   bool ret = true;
   int copied;
   MqlRates rates[];
   ArraySetAsSeries(rates,true); 
   copied=CopyRates(pair,PERIOD_CURRENT,0,shiftbars,rates);
   if(copied==-1)
   {
      f_comment("Wait..."+pair);
      ret=false;
   }
   else
   {
      for(int i=0;i<copied;i++)
         buffer[i]=GetPrice(PriceType,rates,i);
   }
   return ret;
}


double f_RSI(double &buf_in[],int period,int shift)
{
   double pos=0.00000000,neg=0.00000000;
   double diff=0.0;
   for(int j=shift;j<=shift+period;j++)
   {
      diff=buf_in[j]-buf_in[j+1];
      pos+=(diff>0?diff:0.0);
      neg+=(diff<0?-diff:0.0);
   }
   if(neg<0.000000001){return(100.0);}//Protection from division by zero
   pos/=period;
   neg/=period;
   return(100.0 -(100.0/(1.0+pos/neg)));
}


int f_draw(string name,color _color)
{
   string oname = namespace+"-"+name;
   ObjectCreate(0,oname,OBJ_LABEL,ChartWindowFind(),0,0);
   ObjectSetInteger(0,oname,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,oname,OBJPROP_XDISTANCE,5);
   ObjectSetInteger(0,oname,OBJPROP_YDISTANCE,y_pos);
   ObjectSetString(0,oname,OBJPROP_TEXT,name);
   ObjectSetInteger(0,oname,OBJPROP_COLOR,_color);
   ObjectSetInteger(0,oname,OBJPROP_FONTSIZE,8);
   y_pos+=15;
   return(0);
}


int f_comment(string  text)
{
   string name=namespace+"-f_comment";
   color _color=Gray;
   ObjectCreate(0,name,OBJ_LABEL,ChartWindowFind(),0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,5);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,3);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,_color);
   //ChartRedraw();
   return(0);
}


int init_tf()
{
   ArrayInitialize(arrTime,0);
   ArrayInitialize(bars_tf,0);
   bool writeComment=true;
   for(int n=0;n<10;n++) // Loop for initializing used currency pairs with the same TF
   {
      index=0;
      int exit=-1;
      if(writeComment){f_comment("Synchronizing TF");writeComment=false;}

      GetPairData(index,"EURUSD");
      index++;
      GetPairData(index,"GBPUSD");
      index++;
      GetPairData(index,"USDCHF");
      index++;
      GetPairData(index,"USDJPY");
      index++;
      GetPairData(index,"USDCAD");
      index++;
      GetPairData(index,"AUDUSD");
      index++;
      GetPairData(index,"NZDUSD");

      index++;
      GetPairData(index,"EURNZD");
      index++;
      GetPairData(index,"EURCAD");
      index++;
      GetPairData(index,"EURAUD");
      index++;
      GetPairData(index,"EURJPY");
      index++;
      GetPairData(index,"EURCHF");
      index++;
      GetPairData(index,"EURGBP");

      index++;
      GetPairData(index,"GBPNZD");
      index++;
      GetPairData(index,"GBPAUD");
      index++;
      GetPairData(index,"GBPCAD");
      index++;
      GetPairData(index,"GBPJPY");
      index++;
      GetPairData(index,"GBPCHF");

      index++;
      GetPairData(index,"CADJPY");
      index++;
      GetPairData(index,"CADCHF");
      index++;
      GetPairData(index,"AUDCAD");
      index++;
      GetPairData(index,"NZDCAD");

      index++;
      GetPairData(index,"AUDCHF");
      index++;
      GetPairData(index,"AUDJPY");
      index++;
      GetPairData(index,"AUDNZD");

      index++;
      GetPairData(index,"NZDJPY");
      index++;
      GetPairData(index,"NZDCHF");
      index++;
      GetPairData(index,"CHFJPY");

      for(int h=1;h<=index;h++)
      {
         if(arrTime[0]==arrTime[h]&&  arrTime[0]!=0 && exit==-1){exit=1;}
         if(arrTime[0]!=arrTime[h] &&  arrTime[0]!=0 && exit==1){exit=0;}
         if(bars_tf[h]<shiftbars){exit=0;}
      }
      if(exit==1){f_comment("Timeframes synchronized");return(0);}
   }
   f_comment("Unable to synchronize TF");
   return(0);
}


void GetPairData(int idx, string pair)
{
   int copy;
   bars_tf[idx]=Bars(pair,PERIOD_CURRENT);
   copy=CopyTime(pair,PERIOD_CURRENT,0,1,tmp_time);
   arrTime[idx]=tmp_time[0];
}


#define _pricesInstances 1
#define _pricesSize      4
double workHa[][_pricesInstances*_pricesSize];
double GetPrice(int tprice, MqlRates& rates[], int i, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      int ratessize = ArraySize(rates);
      if (ArrayRange(workHa,0)!= ratessize) ArrayResize(workHa,ratessize); instanceNo*=_pricesSize;
         
         double haOpen;
         if (i>0)
                haOpen  = (workHa[i-1][instanceNo+2] + workHa[i-1][instanceNo+3])/2.0;
         else   haOpen  = (rates[i].open+rates[i].close)/2;
         double haClose = (rates[i].open + rates[i].high + rates[i].low + rates[i].close) / 4.0;
         double haHigh  = MathMax(rates[i].high, MathMax(haOpen,haClose));
         double haLow   = MathMin(rates[i].low , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[i][instanceNo+0] = haLow;  workHa[i][instanceNo+1] = haHigh; } 
         else                 { workHa[i][instanceNo+0] = haHigh; workHa[i][instanceNo+1] = haLow;  } 
                                workHa[i][instanceNo+2] = haOpen;
                                workHa[i][instanceNo+3] = haClose;

         switch (tprice)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
            case pr_hatbiased2:
               if (haClose>haOpen)  return(haHigh);
               if (haClose<haOpen)  return(haLow);
                                    return(haClose);        
         }
   }
   
   switch (tprice)
   {
      case pr_close:     return(rates[i].close);
      case pr_open:      return(rates[i].open);
      case pr_high:      return(rates[i].high);
      case pr_low:       return(rates[i].low);
      case pr_median:    return((rates[i].high+rates[i].low)/2.0);
      case pr_medianb:   return((rates[i].open+rates[i].close)/2.0);
      case pr_typical:   return((rates[i].high+rates[i].low+rates[i].close)/3.0);
      case pr_weighted:  return((rates[i].high+rates[i].low+rates[i].close+rates[i].close)/4.0);
      case pr_average:   return((rates[i].high+rates[i].low+rates[i].close+rates[i].open)/4.0);
      case pr_tbiased:   
               if (rates[i].close>rates[i].open)
                     return((rates[i].high+rates[i].close)/2.0);
               else  return((rates[i].low+rates[i].close)/2.0);        
      case pr_tbiased2:   
               if (rates[i].close>rates[i].open) return(rates[i].high);
               if (rates[i].close<rates[i].open) return(rates[i].low);
                                     return(rates[i].close);        
   }
   return(0);
}

