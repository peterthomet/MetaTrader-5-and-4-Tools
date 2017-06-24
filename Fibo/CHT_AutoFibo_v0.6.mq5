
/*==============================================================================
 *
 *  The SmartFibo program is free software: you can redistribute
 *  it and/or modify it under the terms of the GNU General Public License as
 *  published by the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  SmartFibo is distributed in the hope that it will be useful, but WITHOUT ANY
 *  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 *  A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with CHT_AutoFibo. If not, see <http://www.gnu.org/licenses/>.
 *
 *
 *  FILE: SmartFibo_0.1.mq4
 *  VERSION: 0.1
 *  AUTHOR: Thierry Chappuis <tc77@pygnol.ch>
 *
 *  DESCRIPTION:
 *  MT4 Custom indicator to automatically draw fibonacci lines suitable to trade
 *  ABCD patterns.
 *
 *  LOG:
 *  - 20130118: version 0.1
 *  - 20170419: Conversion to MQL5 by Peter Thomet, www.getyournet.ch
 *
 *  Copyright 2012, Thierry Chappuis
 *=============================================================================*/

#property copyright "Copyright 2012, Thierry Chappuis"
#property link      "tc77@pygnol.ch"

#property indicator_chart_window

#property indicator_buffers 3

#property indicator_plots 3

#property indicator_color1 Tomato
#property indicator_color2 Blue
#property indicator_color3 Red

/* Input parameters */

// AutoFibo
input int AF_Period = 0;
input int AF_NumBars = 200;
input double AF_MinLevelDiplayed = -5;
input int AF_LevelStyle = 0;
input bool AF_LabelsVisible = true;
input string AF_LabelFont = "Arial";
input int AF_LabelSize = 7;
input string AF_PriceCycleAlgo = "ZigZag";

input bool AF_DrawBody2Body = false;
input int AF_NumFibos = 1;
input color AF_FiboColor = Silver;
input color AF_FiboColor2 = Orange;
input color AF_FiboColor3 = Magenta;
input color AF_FiboColor4 = Aqua;

// ZigZag
input int ExtDepth = 5;
input int ExtDeviation = 3;
input int ExtBackstep = 1;
input bool ZigZag_Visible = false;

string AF_Name;
int AF_NumFibosInt;

double NB_FIBO_LEVELS = 23;
double FiboRatios[23] =
{
    0.0,
    1.0,
    0.114,
    0.236,
    0.382,
    0.500,
    0.618,
    0.764,
    0.886,
    1.272,
    1.382,
    1.618,
    2.000,
    2.618,
    4.236,
    4.618,
    -0.272,
    -0.382,
    -0.618,
    -1.0,
    -1.618,
    -3.236,
    -3.618  
};
string FiboLabels[23] =
{
    "0.0",
    "100.0",
    "88.6",
    "76.4",
    "61.8",
    "50.0",
    "61.8",
    "76.4",
    "88.6",
    "127.2",
    "138.2",
    "161.8",
    "200.0",
    "261.8",
    "423.6",
    "461.8",
    "127.2",
    "138.2",
    "161.8",
    "200.0",
    "261.8",
    "423.6",
    "461.8",
};

#define AF_FIBO_HISTORY_MAX_LENGTH 4
#define AF_FIBO_DEFINITION_LENGTH 4

double af_fibo_colors[AF_FIBO_HISTORY_MAX_LENGTH];
double af_fibo_history[AF_FIBO_HISTORY_MAX_LENGTH][AF_FIBO_DEFINITION_LENGTH];

/* Value Chart parameters */
int vc_NUM_BARS = 5;

int level=3; // recounting's depth
bool downloadhistory=false;

/* Buffers */
double ZigzagBuffer[];
double HighMapBuffer[];
double LowMapBuffer[];

double High[];
double Low[];
double Close[];
double Open[];
datetime Time[];

int IndicatorCounted;

/* Error management */
bool error_alert_triggered = 0;


void OnInit()
{
    int i, j;

    AF_Name = MQLInfoString(MQL_PROGRAM_NAME);

   ArraySetAsSeries(ZigzagBuffer,true);
   ArraySetAsSeries(HighMapBuffer,true);
   ArraySetAsSeries(LowMapBuffer,true);

   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);
   ArraySetAsSeries(Close,true);
   ArraySetAsSeries(Open,true);
   ArraySetAsSeries(Time,true);

    SetIndexBuffer(0, ZigzagBuffer);
    SetIndexBuffer(1, HighMapBuffer);
    SetIndexBuffer(2, LowMapBuffer);

    if (ZigZag_Visible == true)
    {
        PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_SECTION);
    }
    else
    {
        PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
    }
    PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);
    PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE);

    PlotIndexSetString(0,PLOT_LABEL,"AF_ZigZag");

    PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
    PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
    PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);

    AF_NumFibosInt = AF_NumFibos;
    if (AF_NumFibos > AF_FIBO_HISTORY_MAX_LENGTH)
    {
        AF_NumFibosInt = AF_FIBO_HISTORY_MAX_LENGTH;
    }

    for (i = 0; i < AF_FIBO_HISTORY_MAX_LENGTH; i++)
    {
        for (j = 0; j < AF_FIBO_DEFINITION_LENGTH; j++)
        {
            af_fibo_history[i][j] = 0.0;
        }
    }
    af_fibo_colors[0] = AF_FiboColor;
    af_fibo_colors[1] = AF_FiboColor2;
    af_fibo_colors[2] = AF_FiboColor3;
    af_fibo_colors[3] = AF_FiboColor4;

    IndicatorSetString(INDICATOR_SHORTNAME,AF_Name + "(" + IntegerToString(AF_Period) + "," + IntegerToString(ExtDepth) + "," + IntegerToString(ExtDeviation) + "," + IntegerToString(ExtBackstep) + ")");
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

   if(prev_calculated > 0 && rates_total == prev_calculated)
      return(rates_total);

   //Print("Calc");

     ArrayInitialize(ZigzagBuffer,0.0);
     ArrayInitialize(HighMapBuffer,0.0);
     ArrayInitialize(LowMapBuffer,0.0);

     ArrayInitialize(High,0.0);
     ArrayInitialize(Low,0.0);
     ArrayInitialize(Close,0.0);
     ArrayInitialize(Open,0.0);
     ArrayInitialize(Time,0.0);


   IndicatorCounted = 0;
   if(prev_calculated>0) IndicatorCounted = prev_calculated-1;
   IndicatorCounted = rates_total;
   
   //int to_copy = rates_total-prev_calculated;
   int to_copy = rates_total;
   
   CopyHigh(_Symbol,_Period,0,to_copy,High);
   CopyLow(_Symbol,_Period,0,to_copy,Low);
   CopyClose(_Symbol,_Period,0,to_copy,Close);
   CopyOpen(_Symbol,_Period,0,to_copy,Open);
   CopyTime(_Symbol,_Period,0,to_copy,Time);

    if (AF_Period == 0 || AF_Period == Period())
    {
        zigzag();
        auto_fibo();
    }
    else if (AF_Period < Period() && AF_Period != 0)
    {
        if(error_alert_triggered == false)
        {
            Alert("AutoFibo: AF_Period must be larger than the period of the current chart!");
            error_alert_triggered = true;
        }
        return(0);
    }
    else
    {
        error_alert_triggered = false;

        iCustom(NULL,
                TFMigrate(AF_Period),
                AF_Name,
                AF_Name,
                AF_Period,
                AF_NumBars,
                AF_FiboColor,
                AF_PriceCycleAlgo,
                ExtDepth,
                ExtDeviation,
                ExtBackstep,
                ZigZag_Visible,
                0, 0);
    }

    return(rates_total);
}


void OnDeinit(const int reason)
{
    af_delete();
    Comment("");
}


int zigzag()
{
    int i=0, counted_bars = IndicatorCounted;
    int limit=0,counterZ=0,whatlookfor=0;
    //int shift,back,lasthighpos=-1,lastlowpos=-1;
    int shift,back,lasthighpos=0,lastlowpos=0;
    double val,res;
    double curlow=0,curhigh=0,lasthigh=0,lastlow=0;

    //if(counted_bars>200)
      //counted_bars=200;

    if (counted_bars==0 && downloadhistory) // history was downloaded
    {
        ArrayInitialize(ZigzagBuffer,0.0);
        ArrayInitialize(HighMapBuffer,0.0);
        ArrayInitialize(LowMapBuffer,0.0);
    }
    if (counted_bars==0)
    {
        limit=Bars(_Symbol,_Period)-ExtDepth;
        downloadhistory=true;
    }
    // TODO, optimize
    limit=Bars(_Symbol,_Period)-ExtDepth;
    counted_bars=0;
    
    if (counted_bars>0)
    {
        while (counterZ<level && i<100)
        {
            res=ZigzagBuffer[i];
            if (res!=0) counterZ++;
            i++;
        }
        i--;
        limit=i;
        if (LowMapBuffer[i]!=0)
        {
            curlow=LowMapBuffer[i];
            whatlookfor=1;
        }
        else
        {
            curhigh=HighMapBuffer[i];
            whatlookfor=-1;
        }
        for (i=limit-1; i>=0; i--)
        {
            ZigzagBuffer[i]=0.0;
            LowMapBuffer[i]=0.0;
            HighMapBuffer[i]=0.0;
        }
    }

    for(shift=limit; shift>=0; shift--)
    {
        val=Low[ArrayMinimum(Low,shift,ExtDepth)];
        if(val==lastlow) val=0.0;
        else
        {
            lastlow=val;
            if((Low[shift]-val)>(ExtDeviation*_Point)) val=0.0;
            else
            {
                for(back=1; back<=ExtBackstep; back++)
                {
                    res=LowMapBuffer[shift+back];
                    if((res!=0)&&(res>val)) LowMapBuffer[shift+back]=0.0;
                }
            }
        }
        if (Low[shift]==val) LowMapBuffer[shift]=val;
        else LowMapBuffer[shift]=0.0;
        //--- high
        val=High[ArrayMaximum(High,shift,ExtDepth)];
        if(val==lasthigh) val=0.0;
        else
        {
            lasthigh=val;
            if((val-High[shift])>(ExtDeviation*_Point)) val=0.0;
            else
            {
                for(back=1; back<=ExtBackstep; back++)
                {
                    res=HighMapBuffer[shift+back];
                    if((res!=0)&&(res<val)) HighMapBuffer[shift+back]=0.0;
                }
            }
        }
        if (High[shift]==val) HighMapBuffer[shift]=val;
        else HighMapBuffer[shift]=0.0;
    }

    // final cutting
    if (whatlookfor==0)
    {
        lastlow=0;
        lasthigh=0;
    }
    else
    {
        lastlow=curlow;
        lasthigh=curhigh;
    }
    for (shift=limit; shift>=0; shift--)
    {
        res=0.0;
        switch(whatlookfor)
        {
        case 0: // look for peak or lawn
            if (lastlow==0 && lasthigh==0)
            {
                if (HighMapBuffer[shift]!=0)
                {
                    lasthigh=High[shift];
                    lasthighpos=shift;
                    whatlookfor=-1;
                    ZigzagBuffer[shift]=lasthigh;
                    res=1;
                }
                if (LowMapBuffer[shift]!=0)
                {
                    lastlow=Low[shift];
                    lastlowpos=shift;
                    whatlookfor=1;
                    ZigzagBuffer[shift]=lastlow;
                    res=1;
                }
            }
            break;
        case 1: // look for peak
            //if (lastlowpos < 0)
               //Print("No lastlowpos");
            if (LowMapBuffer[shift]!=0.0 && LowMapBuffer[shift]<lastlow && HighMapBuffer[shift]==0.0 && lastlowpos > -1)
            {
                ZigzagBuffer[lastlowpos]=0.0;
                lastlowpos=shift;
                lastlow=LowMapBuffer[shift];
                ZigzagBuffer[shift]=lastlow;
                res=1;
            }
            if (HighMapBuffer[shift]!=0.0 && LowMapBuffer[shift]==0.0)
            {
                lasthigh=HighMapBuffer[shift];
                lasthighpos=shift;
                ZigzagBuffer[shift]=lasthigh;
                whatlookfor=-1;
                res=1;
            }
            break;
        case -1: // look for lawn
            //if (lasthighpos < 0)
               //Print("No lasthighpos");
            if (HighMapBuffer[shift]!=0.0 && HighMapBuffer[shift]>lasthigh && LowMapBuffer[shift]==0.0 && lasthighpos > -1)
            {
               //Print(IntegerToString(lasthighpos));
                ZigzagBuffer[lasthighpos]=0.0;
                lasthighpos=shift;
                lasthigh=HighMapBuffer[shift];
                ZigzagBuffer[shift]=lasthigh;
            }
            if (LowMapBuffer[shift]!=0.0 && HighMapBuffer[shift]==0.0)
            {
                lastlow=LowMapBuffer[shift];
                lastlowpos=shift;
                ZigzagBuffer[shift]=lastlow;
                whatlookfor=1;
            }
            break;
        default:
            return(0);
        }
    }

    return(0);
}


void auto_fibo()
{
    int i, j, y;
    double zz[4];
    ArrayInitialize(zz,0);
    int zzpos[4];
    ArrayInitialize(zzpos,0);

    bool new_fibo = false;
    datetime time1=0, time2=0;
    double low=0, high=0, price1=0, price2=0;

    af_delete();

    for (i = 0, y = 0; i < AF_NumBars && y < 4; i++)
    {
        if (ZigzagBuffer[i] != 0.0)
        {
            zz[y] = ZigzagBuffer[i];
            zzpos[y] = i;
            y++;
        }
    }

    if (zz[3] < zz[2] &&  zz[1] < zz[2] && zz[3] <= zz[1] && zz[1] < zz[0])
    {
        if (AF_DrawBody2Body) // Wick2Wick fibos e.g. for JPY pairs
        {
            low = Close[zzpos[3]];
            high = Close[zzpos[2]];

            if (Open[zzpos[3]] < Close[zzpos[3]]) low = Open[zzpos[3]];
            if (Open[zzpos[2]] > Close[zzpos[2]]) high = Open[zzpos[2]];

            time1 = Time[zzpos[3]];
            price1 = low;
            time2 = Time[zzpos[2]];
            price2 = high;
            new_fibo = true;
        }
        else
        {
            time1 = Time[zzpos[3]];
            price1 = zz[3];
            time2 = Time[zzpos[2]];
            price2 = zz[2];
            new_fibo = true;
        }
    }
    else if (zz[3] > zz[2] && zz[1] > zz[2] && zz[3] >= zz[1] && zz[1] > zz[0])
    {
        if (AF_DrawBody2Body) // Body2Body fibos for JPY pairs
        {
            low = Close[zzpos[2]];
            high = Close[zzpos[3]];

            if (Open[zzpos[2]] < Close[zzpos[2]]) low = Open[zzpos[2]];
            if (Open[zzpos[3]] > Close[zzpos[3]]) high = Open[zzpos[3]];

            time1 = Time[zzpos[3]];
            price1 = high;
            time2 = Time[zzpos[2]];
            price2 = low;
            new_fibo = true;
        }
        else // Wick2Wick fibos
        {
            time1 = Time[zzpos[3]];
            price1 = zz[3];
            time2 = Time[zzpos[2]];
            price2 = zz[2];
            new_fibo = true;

        }
    }
    else if (zz[3] < zz[2] && zz[1] < zz[3] && zz[0] > zz[1])
    {
        if (AF_DrawBody2Body) // Body2Body fibos for JPY pairs
        {
            low = Close[zzpos[1]];
            high = Close[zzpos[2]];

            if (Open[zzpos[1]] < Close[zzpos[1]]) low = Open[zzpos[1]];
            if (Open[zzpos[2]] > Close[zzpos[2]]) high = Open[zzpos[2]];

            time1 = Time[zzpos[1]];
            price1 = low;
            time2 = Time[zzpos[2]];
            price2 = high;
            new_fibo = true;
        }
        else
        {
            time1 = Time[zzpos[1]];
            price1 = zz[1];
            time2 = Time[zzpos[2]];
            price2 = zz[2];
            new_fibo = true;
        }
    }
    else if (zz[3] > zz[2] && zz[1] > zz[3] &&  zz[0] < zz[1])
    {
        if (AF_DrawBody2Body) // Body2Body fibos for JPY pairs
        {
            low = Close[zzpos[2]];
            high = Close[zzpos[1]];

            if (Open[zzpos[2]] < Close[zzpos[2]]) low = Open[zzpos[2]];
            if (Open[zzpos[1]] > Close[zzpos[1]]) high = Open[zzpos[1]];

            time1 = Time[zzpos[1]];
            price1 = high;
            time2 = Time[zzpos[2]];
            price2 = low;
            new_fibo = true;
        }
        else
        {
            time1 = Time[zzpos[1]];
            price1 = zz[1];
            time2 = Time[zzpos[2]];
            price2 = zz[2];
            new_fibo = true;
        }
    }

    if (new_fibo)
    {
        if (time1 != af_fibo_history[0][0] && time2 != af_fibo_history[0][0])
        {
            for (i = AF_NumFibosInt - 1; i > 0; i--)
            {
                for (j = 0; j < 4; j++)
                {
                    af_fibo_history[i][j] = af_fibo_history[i-1][j];
                }
            }
            af_fibo_history[0][0] = (double)time1;
            af_fibo_history[0][1] = price1;
            af_fibo_history[0][2] = (double)time2;
            af_fibo_history[0][3] = price2;
        }
    }

    for (i = 0; i < AF_NumFibosInt && af_fibo_history[i][0] > 0.0; i++)
    {
        draw_fibo((datetime)af_fibo_history[i][0], af_fibo_history[i][1], (datetime)af_fibo_history[i][2], af_fibo_history[i][3], (color)af_fibo_colors[i], i);
    }

}


void draw_fibo(datetime time1, double price1, datetime time2, double price2, color fibo_color, int id)
{
    int i;
    datetime start = time1;
    datetime end = Time[0];
    double range = price2 - price1;

    draw_base(time1, price1, time2, price2, fibo_color, id);
    for (i = 0; i < NB_FIBO_LEVELS; i++)
    {
        if (FiboRatios[i] >= AF_MinLevelDiplayed)
        {
            draw_line(start, price1 + FiboRatios[i] * range, FiboLabels[i], fibo_color, 0, id);
        }
    }
}


void draw_line(datetime start, double level2, string label, color col, int style, int id)
{
    string line_name = "CHT_AF_FiboLine" + IntegerToString(id) + "(" + label + "," + DoubleToString(level2, _Digits) + "," + IntegerToString(AF_Period) + "," + IntegerToString(ExtDepth) + "," + IntegerToString(ExtDeviation) + "," + IntegerToString(ExtBackstep) + ")";
    string label_name = "CHT_AF_FiboLabel" + IntegerToString(id) + "(" + label + "," + DoubleToString(level2, _Digits) + "," + IntegerToString(AF_Period) + "," + IntegerToString(ExtDepth) + "," + IntegerToString(ExtDeviation) + "," + IntegerToString(ExtBackstep) + ")";

    ObjectCreate(0,line_name, OBJ_TREND, 0, start, level2, Time[0] + 800*Period(), level2);

    ObjectSetInteger(0,line_name,OBJPROP_STYLE,AF_LevelStyle);
    ObjectSetInteger(0,line_name,OBJPROP_COLOR,col);
    ObjectSetInteger(0,line_name,OBJPROP_WIDTH,1);
    ObjectSetInteger(0,line_name,OBJPROP_RAY_RIGHT,false);

    if (AF_LabelsVisible == true)
    {
        ObjectCreate(0,label_name, OBJ_TEXT, 0, Time[0] + 500 * Period(), level2);
        ObjectSetString(0,label_name,OBJPROP_TEXT,label+ " - " +DoubleToString(level2,_Digits));
        ObjectSetInteger(0,label_name,OBJPROP_FONTSIZE,AF_LabelSize);
        ObjectSetString(0,label_name,OBJPROP_FONT,AF_LabelFont);
        ObjectSetInteger(0,label_name,OBJPROP_COLOR,col);
    }

    if (style != 0)
    {
        if (style == 3)
        {
            ObjectSetInteger(0,line_name,OBJPROP_STYLE,STYLE_SOLID);
            ObjectSetInteger(0,line_name,OBJPROP_WIDTH,3);
        }
        else if (style == 2)
        {
            ObjectSetInteger(0,line_name,OBJPROP_STYLE,STYLE_DOT);
            ObjectSetInteger(0,line_name,OBJPROP_WIDTH,2);
        }
        else if (style == 1)
        {
            ObjectSetInteger(0,line_name,OBJPROP_STYLE,STYLE_SOLID);
            ObjectSetInteger(0,line_name,OBJPROP_WIDTH,2);
        }

    }
}


void draw_base(datetime time1, double price1, datetime time2, double price2, color col, int id)
{
    string base_name = "CHT_AF_FiboBase" + IntegerToString(id) + "(" + "," + IntegerToString(AF_Period) + "," + IntegerToString(ExtDepth) + "," + IntegerToString(ExtDeviation) + "," + IntegerToString(ExtBackstep) + ")";

    ObjectCreate(0,base_name, OBJ_TREND, 0, time1, price1, time2, price2);
    ObjectSetInteger(0,base_name,OBJPROP_COLOR,col);
    ObjectSetInteger(0,base_name,OBJPROP_WIDTH,1);
    ObjectSetInteger(0,base_name,OBJPROP_RAY_RIGHT,false);
    
}


void af_delete()
{
   ObjectsDeleteAll(0,"CHT_AF");
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

