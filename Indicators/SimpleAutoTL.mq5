//+------------------------------------------------------------------+
//|                                                SimpleAutoTL.mq5  |
//| Simple Auto TL                            Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.01"
#property indicator_chart_window
#property strict

#property indicator_buffers 9
#property indicator_plots 4

#property indicator_type1         DRAW_LINE 
#property indicator_color1        clrSilver
#property indicator_width1 1
#property indicator_type2         DRAW_LINE 
#property indicator_color2        clrSilver
#property indicator_width2 1
#property indicator_type3         DRAW_SECTION 
#property indicator_color3        clrRed
#property indicator_width3 1
#property indicator_type4         DRAW_SECTION
#property indicator_color4        clrRed
#property indicator_width4 1

input int InpConvexPeriod=40; //  Minimum Period
input int InpHiLoPeriod=50;   //  HiLo Period
input int InpShowGuide=1;     //  Show Guide (1:show ,0:hide)  
input int InpMaxBars=1000;   //   MaxBars
double InpXSize=0.3;   //   X Size

double ATR[];
double H[];
double L[];

double HI[];
double LO[];
double UPPER_X[];
double LOWER_X[];

double UPPER[];
double LOWER[];
double UPTL[];
double DNTL[];
double AtrAlpha=2.0/(100.0+1.0);
double xFactor;
int WinNo=ChartWindowFind();
int min_rates_total=InpConvexPeriod+InpHiLoPeriod+2;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectDeleteByName("AutoTL_");

   if(InpShowGuide==0)
     {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);
      PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE);
      PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_NONE);
     }
   else
     {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);
      PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_SECTION);
      PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_SECTION);
     }

   SetIndexBuffer(0,UPPER,INDICATOR_DATA);//---
   SetIndexBuffer(1,LOWER,INDICATOR_DATA);//---
   SetIndexBuffer(2,H,INDICATOR_DATA);
   SetIndexBuffer(3,L,INDICATOR_DATA);
   SetIndexBuffer(4,UPPER_X,INDICATOR_DATA);//---
   SetIndexBuffer(5,LOWER_X,INDICATOR_DATA);//---
   SetIndexBuffer(6,HI,INDICATOR_DATA);
   SetIndexBuffer(7,LO,INDICATOR_DATA);
   SetIndexBuffer(8,ATR,INDICATOR_CALCULATIONS);

///  --- 
//--- digits
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDeleteByName("AutoTL_");
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
//---
   int i;

//---
   for(i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
     {
      ATR[i]=EMPTY_VALUE;
      UPPER[i]=EMPTY_VALUE;
      LOWER[i]=EMPTY_VALUE;
      UPPER_X[i]=EMPTY_VALUE;
      LOWER_X[i]=EMPTY_VALUE;
      HI[i]=EMPTY_VALUE;
      LO[i]=EMPTY_VALUE;
      H[i]=EMPTY_VALUE;
      L[i]=EMPTY_VALUE;
      double atr0 = (i==0) ? high[i]-low[i] : MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);                 
      double atr1 = (i==0) ? atr0 : ATR[i-1];
      atr0=fmax(atr1*0.667,fmin(atr0,atr1*1.333));
      ATR[i] = AtrAlpha * atr0 + (1.0 - AtrAlpha) * atr1;
      //---
      if(i==rates_total-1 || i<=min_rates_total || i<rates_total-InpMaxBars)continue;
      xFactor=ATR[i]*InpXSize;
      //---
      HI[i]=high[ArrayMaximum(high,i-(InpHiLoPeriod-1),InpHiLoPeriod)];
      LO[i]=low[ArrayMinimum(low,i-(InpHiLoPeriod-1),InpHiLoPeriod)];
      if(HI[i-1]==EMPTY_VALUE)continue;

      UPPER[i]=(HI[i]>HI[i-1])? HI[i]:UPPER[i-1];
      LOWER[i]=(LO[i]<LO[i-1])? LO[i]:LOWER[i-1];
      UPPER_X[i]=(HI[i]>HI[i-1])? i:UPPER_X[i-1];
      LOWER_X[i]=(LO[i]<LO[i-1])? i:LOWER_X[i-1];
      //---

      double upper[][2];
      double lower[][2];

      //---
      if(i-UPPER_X[i]>InpConvexPeriod)
        {
         convex_upper(upper,high,i,i-(int(UPPER_X[i])-1) );
         int sz=int(ArraySize(upper)*0.5);
         if(sz>1)
           {
            double best_d=0;
            int best=0;
            for(int j=0;j<sz-1;j++)
              {
               double d=dimension_dn(upper[j+1][0],upper[j+1][1],upper[j][0],upper[j][1],UPPER[i],i,xFactor);
               if(d>best_d)
                 {
                  best=j;
                  best_d=d;
                 }
              }
            if(best_d>0)
              {
               if(InpShowGuide==1)
               {
                  for(int j=(int)UPPER_X[i];j<=i;j++) H[j]=EMPTY_VALUE;
                  H[(int)UPPER_X[i]]=UPPER[i];
                  for(int j=0;j<sz-1;j++) H[int(upper[j][0])]=upper[j][1];
               }
               drawTrend(1,1,clrGold,(int)upper[best+1][0],upper[best+1][1],(int)upper[best][0],upper[best][1],time,STYLE_SOLID,1,true);

              }

           }
        }
      else
         ObjectDeleteByName("AutoTL_1");

      if(i-LOWER_X[i]>InpConvexPeriod)
        {
         convex_lower(lower,low,i,i-(int(LOWER_X[i])-1) );
         int sz=int(ArraySize(lower)*0.5);
         if(sz>1)
           {
            double best_d=0;
            int best=0;
            for(int j=0;j<sz-1;j++)
              {
               double d=dimension_up(lower[j+1][0],lower[j+1][1],lower[j][0],lower[j][1],LOWER[i],i,xFactor);
               if(d>best_d)
                 {
                  best=j;
                  best_d=d;
                 }
              }
            if(best_d>0)
              {
               if(InpShowGuide==1)
               {
                  for(int j=(int)LOWER_X[i];j<=i;j++) L[j]=EMPTY_VALUE;
                  L[int(LOWER_X[i])]=LOWER[i];
                  for(int j=0;j<sz-1;j++) L[int(lower[j][0])]=lower[j][1];
               }
               drawTrend(2,2,clrGold,(int)lower[best+1][0],lower[best+1][1],(int)lower[best][0],lower[best][1],time,STYLE_SOLID,1,true);
              }
           }
        }
      else
         ObjectDeleteByName("AutoTL_2");

      //---

      //---

     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//---
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double dimension_dn(double x1,double y1,double x2,double  y2,double top,double i,double xfacter)
  {
   if(x1>=x2 || y1<=y2)return 0.0;
   double a= (y2-y1)/(x2-x1);
   double b=y1-a*x1;   //b=y-ax
   double x0=(top-b)/a;  //x=(y-b)/a
   double y3 = a*i+b;    //y=ax+b  
   return xfacter*(i-x0)*(top-y3);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double dimension_up(double x1,double y1,double x2,double  y2,double btm,double i,double xfacter)
  {
   if(x1>=x2 || y1>=y2)return 0.0;
   double a= (y2-y1)/(x2-x1);
   double b=y1-a*x1;   //b=y-ax
   double x0=(btm-b)/a;  //x=(y-b)/a
   double y3 = a*i+b;    //y=ax+b  
   return xfacter*(i-x0)*(y3-btm);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void convex_upper(double &upper[][2],const double &high[],const int i,const int len)
  {
   ArrayResize(upper,len,len);
   int k=0;
   for(int j=0;j<len;j++)
     {
      while(k>=2 && 
            (cross(upper[k-2][0],upper[k-2][1],
            upper[k-1][0],upper[k-1][1],
            i-j,high[i-j]))<=0)
        {
         k--;
        }

      upper[k][0]= i-j;
      upper[k][1]= high[i-j];
      k++;
     }
   ArrayResize(upper,k,len);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void convex_lower(double &lower[][2],const double &low[],const int i,const int len)
  {
   ArrayResize(lower,len,len);
   int k=0;
   for(int j=0;j<len;j++)
     {
      while(k>=2 && 
            (cross(lower[k-2][0],lower[k-2][1],
            lower[k-1][0],lower[k-1][1],
            i-j,low[i-j]))>=0)
        {
         k--;
        }

      lower[k][0]= i-j;
      lower[k][1]= low[i-j];
      k++;
     }
   ArrayResize(lower,k,len);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double cross(const double ox,double oy,
             const double ax,double ay,
             const double bx,double by)
  {
   return ((ax - ox) * (by - oy) - (ay - oy) * (bx - ox));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawTrend(int no1,int no2,
               const color clr,const int x0,const double y0,const int x1,const double y1,
               const datetime &time[],const ENUM_LINE_STYLE style,const int width,const bool isRay)
  {

   if(-1<ObjectFind(0,StringFormat("AutoTL_%d_%d",no1,no2)))
     {
      ObjectMove(0,StringFormat("AutoTL_%d_%d",no1,no2),0,time[x0],y0);
      ObjectMove(0,StringFormat("AutoTL_%d_%d",no1,no2),1,time[x1],y1);
     }
   else
     {
      ObjectCreate(0,StringFormat("AutoTL_%d_%d",no1,no2),OBJ_TREND,WinNo,time[x0],y0,time[x1],y1);
      ObjectSetInteger(0,StringFormat("AutoTL_%d_%d",no1,no2),OBJPROP_COLOR,clr);
      ObjectSetInteger(0,StringFormat("AutoTL_%d_%d",no1,no2),OBJPROP_STYLE,style);
      ObjectSetInteger(0,StringFormat("AutoTL_%d_%d",no1,no2),OBJPROP_WIDTH,width);
      ObjectSetInteger(0,StringFormat("AutoTL_%d_%d",no1,no2),OBJPROP_RAY_RIGHT,isRay);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectDeleteByName(string prefix)
  {
   int total=ObjectsTotal(0),
   length=StringLen(prefix);
   for(int i=total-1; i>=0; i--)
     {
      string objName=ObjectName(0,i);
      if(StringSubstr(objName,0,length)==prefix)
        {
         ObjectDelete(0,objName);
        }
     }
  }
//+------------------------------------------------------------------+
