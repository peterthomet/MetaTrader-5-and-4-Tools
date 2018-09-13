
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
 *
 *  Copyright 2012, Thierry Chappuis
 *=============================================================================*/

#property copyright "Copyright 2012, Thierry Chappuis"
#property link      "tc77@pygnol.ch"

#property indicator_chart_window

#property indicator_buffers 3

#property indicator_color1 White
#property indicator_color2 Blue
#property indicator_color3 Red

/* Input parameters */

// AutoFibo
extern int AF_Period = 0;
extern int AF_NumBars = 200;
extern double AF_MinLevelDiplayed = -5;
extern int AF_LevelStyle = 0;
extern bool AF_LabelsVisible = true;
extern string AF_LabelFont = "Arial";
extern int AF_LabelSize = 6;
extern string AF_PriceCycleAlgo = "ZigZag";

extern bool AF_DrawBody2Body = false;
extern int AF_NumFibos = 1;
extern color AF_FiboColor = Yellow;
extern color AF_FiboColor2 = Orange;
extern color AF_FiboColor3 = Magenta;
extern color AF_FiboColor4 = Aqua;

// ZigZag
extern int ExtDepth = 12;
extern int ExtDeviation = 5;
extern int ExtBackstep = 3;
extern bool ZigZag_Visible = true;

string AF_Name;

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
string FiboLabels[20] =
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

/* Error management */
bool error_alert_triggered = 0;

/* Initialization function */
int init()
{
    int i, j;

    AF_Name = WindowExpertName();

    SetIndexBuffer(0, ZigzagBuffer);
    SetIndexBuffer(1, HighMapBuffer);
    SetIndexBuffer(2, LowMapBuffer);

    if (ZigZag_Visible == true)
    {
        SetIndexStyle(0, DRAW_SECTION);
    }
    else
    {
        SetIndexStyle(0, DRAW_NONE);
    }
    SetIndexStyle(1, DRAW_NONE);
    SetIndexStyle(2, DRAW_NONE);

    SetIndexLabel(0, "AF_ZigZag");

    SetIndexEmptyValue(0, 0.0);
    SetIndexEmptyValue(1, 0.0);
    SetIndexEmptyValue(2, 0.0);

    if (AF_NumFibos > AF_FIBO_HISTORY_MAX_LENGTH)
    {
        AF_NumFibos = AF_FIBO_HISTORY_MAX_LENGTH;
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

    IndicatorShortName(AF_Name + "(" + AF_Period + "," + ExtDepth + "," + ExtDeviation + "," + ExtBackstep + ")");
    return(0);
}

/* Entry point */
int start()
{
    int err = 0;

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
                AF_Period,
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

    return (err);
}

int deinit()
{
    af_delete();
    Comment("");
    return(0);
}

int zigzag()
{
    int i, counted_bars = IndicatorCounted();
    int limit,counterZ,whatlookfor;
    int shift,back,lasthighpos,lastlowpos;
    double val,res;
    double curlow,curhigh,lasthigh,lastlow;

    if (counted_bars==0 && downloadhistory) // history was downloaded
    {
        ArrayInitialize(ZigzagBuffer,0.0);
        ArrayInitialize(HighMapBuffer,0.0);
        ArrayInitialize(LowMapBuffer,0.0);
    }
    if (counted_bars==0)
    {
        limit=Bars-ExtDepth;
        downloadhistory=true;
    }
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
        val=Low[iLowest(NULL,0,MODE_LOW,ExtDepth,shift)];
        if(val==lastlow) val=0.0;
        else
        {
            lastlow=val;
            if((Low[shift]-val)>(ExtDeviation*Point)) val=0.0;
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
        val=High[iHighest(NULL,0,MODE_HIGH,ExtDepth,shift)];
        if(val==lasthigh) val=0.0;
        else
        {
            lasthigh=val;
            if((val-High[shift])>(ExtDeviation*Point)) val=0.0;
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
            if (LowMapBuffer[shift]!=0.0 && LowMapBuffer[shift]<lastlow && HighMapBuffer[shift]==0.0)
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
            if (HighMapBuffer[shift]!=0.0 && HighMapBuffer[shift]>lasthigh && LowMapBuffer[shift]==0.0)
            {
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
            return;
        }
    }

    return(0);
}

void auto_fibo()
{
    int i, j, k, y;
    double zz[4];
    int zzpos[4];

    bool new_fibo = false;
    datetime time1, time2;
    double low, high, price1, price2;

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
            for (i = AF_NumFibos - 1; i > 0; i--)
            {
                for (j = 0; j < 4; j++)
                {
                    af_fibo_history[i][j] = af_fibo_history[i-1][j];
                }
            }
            af_fibo_history[0][0] = time1;
            af_fibo_history[0][1] = price1;
            af_fibo_history[0][2] = time2;
            af_fibo_history[0][3] = price2;
        }
    }

    for (i = 0; i < AF_NumFibos && af_fibo_history[i][0] > 0.0; i++)
    {
        draw_fibo(af_fibo_history[i][0], af_fibo_history[i][1], af_fibo_history[i][2], af_fibo_history[i][3], af_fibo_colors[i], i);
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


void draw_line(datetime start, double level, string label, color col, int style, int id)
{
    string line_name = "CHT_AF_FiboLine" + id + "(" + label + "," + DoubleToStr(level, Digits) + "," + AF_Period + "," + ExtDepth + "," + ExtDeviation + "," + ExtBackstep + ")";
    string label_name = "CHT_AF_FiboLabel" + id + "(" + label + "," + DoubleToStr(level, Digits) + "," + AF_Period + "," + ExtDepth + "," + ExtDeviation + "," + ExtBackstep + ")";

    ObjectCreate(line_name, OBJ_TREND, 0, start, level, Time[0] + 800*Period(), level);
    ObjectSet(line_name, OBJPROP_STYLE, AF_LevelStyle);
    ObjectSet(line_name, OBJPROP_COLOR, col);
    ObjectSet(line_name, OBJPROP_WIDTH, 1);
    ObjectSet(line_name, OBJPROP_RAY, false);

    if (AF_LabelsVisible == true)
    {
        ObjectCreate(label_name, OBJ_TEXT, 0, Time[0] + 500 * Period(), level);
        ObjectSetText(label_name, label+ " - " +DoubleToStr(level,Digits), AF_LabelSize, AF_LabelFont, EMPTY);
        ObjectSet(label_name, OBJPROP_COLOR, col);
    }

    if (style != 0)
    {
        if (style == 3)
        {
            ObjectSet(line_name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSet(line_name, OBJPROP_WIDTH, 3);
        }
        else if (style == 2)
        {
            ObjectSet(line_name, OBJPROP_STYLE, STYLE_DOT);
            ObjectSet(line_name, OBJPROP_WIDTH, 2);
        }
        else if (style == 1)
        {
            ObjectSet(line_name, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSet(line_name, OBJPROP_WIDTH, 2);
        }

    }
}

void draw_base(datetime time1, double price1, datetime time2, double price2, color col, int id)
{
    string base_name = "CHT_AF_FiboBase" + id + "(" + "," + AF_Period + "," + ExtDepth + "," + ExtDeviation + "," + ExtBackstep + ")";

    ObjectCreate(base_name, OBJ_TREND, 0, time1, price1, time2, price2);
    ObjectSet(base_name, OBJPROP_COLOR, col);
    ObjectSet(base_name, OBJPROP_WIDTH, 2);
    ObjectSet(base_name, OBJPROP_RAY, false);
}

void af_delete()
{
    string name;
    for (int i = ObjectsTotal() - 1; i >= 0; i--)
    {
        name = ObjectName(i);
        if (StringSubstr(name, 0, 7) == "CHT_AF_")
        {
            ObjectDelete(name);
        }
    }
}


