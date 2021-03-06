//+------------------------------------------------------------------+
//|                                              SimpleAutoTL_v2.mq5 |
//| Simple Auto TL v2.0                       Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "2.0"

#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   0

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_width1  1

#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_width2  1

int WinNo=ChartWindowFind();

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input int InpFastPeriod=20;           // Fast Period
input int InpHiLoPeriod=60;           // HiLo Period
input double InpSize=0.6;             // Modoshi Size
input bool InpShowHistory=true;       // Show History
input int InpKeepPeriod=500;          // Keep Period
input int InpMaxBars=1000;            // MaxBars
input color InpColor=clrDodgerBlue;    // Line Color

double InpXSize=0.3;   //   X Size

int UP_FLG=0;
int DN_FLG=1;
int UP_I=2;
int UP=3;
int DN_I=4;
int DN=5;
int A=6;
int B=7;

double wk[][8];
double HI[];
double LO[];
double HI2[];
double LO2[];
double LATR[];

double UPPER_X[];
double LOWER_X[];
double UPPER[];
double LOWER[];

int LAtrPeriod=100;
double LAtrAlpha=2.0/(LAtrPeriod+1.0);
int LineNo=0;
double xFactor;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectDeleteByName("AutoTL");

   SetIndexBuffer(0,UPPER,INDICATOR_DATA);
   SetIndexBuffer(1,LOWER,INDICATOR_DATA);
   SetIndexBuffer(2,LATR,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,HI,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,LO,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,UPPER_X,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,LOWER_X,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,HI2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,LO2,INDICATOR_CALCULATIONS);

   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDeleteByName("AutoTL");
  }
//+------------------------------------------------------------------+
//|                                                                  |
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

   for(int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
     {
      if(InpShowHistory)  ObjectDeleteByBarNo("AutoTL",rates_total-InpKeepPeriod);

      UPPER[i]=EMPTY_VALUE;
      LOWER[i]=EMPTY_VALUE;
      UPPER_X[i]=EMPTY_VALUE;
      LOWER_X[i]=EMPTY_VALUE;
      HI[i]=EMPTY_VALUE;
      LO[i]=EMPTY_VALUE;
      
      LATR[i]=EMPTY_VALUE;
      if(i==rates_total-1 )continue;

      //----
      double atr0 = (i==0) ? high[i]-low[i] : MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      double atr1 = (i==0) ? atr0 : LATR[i-1];
      atr0=fmax(atr1*0.667,fmin(atr0,atr1*1.333));
      LATR[i]=LAtrAlpha*atr0+(1.0-LAtrAlpha)*atr1;

      //---
      if(ArrayRange(wk,0)!=rates_total) ArrayResize(wk,rates_total);

      //----
      double size=InpSize*LATR[i];
      if(i<=InpHiLoPeriod+1)continue;
      //---
      HI[i]=high[ArrayMaximum(high,i-(InpHiLoPeriod-1),InpHiLoPeriod)];
      LO[i]=low[ArrayMinimum(low,i-(InpHiLoPeriod-1),InpHiLoPeriod)];
      HI2[i]=high[ArrayMaximum(high,i-(InpFastPeriod-1),InpFastPeriod)];
      LO2[i]=low[ArrayMinimum(low,i-(InpFastPeriod-1),InpFastPeriod)];
      if(HI[i-1]==EMPTY_VALUE)continue;

      UPPER[i]=(HI[i]>HI[i-1])? HI[i]:UPPER[i-1];
      LOWER[i]=(LO[i]<LO[i-1])? LO[i]:LOWER[i-1];
      UPPER_X[i]=(HI[i]>HI[i-1])? i:UPPER_X[i-1];
      LOWER_X[i]=(LO[i]<LO[i-1])? i:LOWER_X[i-1];

      if(i<rates_total-InpMaxBars)continue;
      //---
      if(i<=InpHiLoPeriod+2)
        {
         wk[i][UP_FLG]=0.0;
         wk[i][DN_FLG]=0.0;
         wk[i][UP ]=UPPER[i];
         wk[i][DN ]=LOWER[i];
         wk[i][UP_I]=UPPER_X[i];
         wk[i][DN_I]=LOWER_X[i];
         wk[i][A]=0.0;
         wk[i][B]=0.0;
        }
      else
        {
         wk[i][UP_FLG]=wk[i-1][UP_FLG];
         wk[i][DN_FLG]=wk[i-1][DN_FLG];
         wk[i][UP ]=wk[i-1][UP ];
         wk[i][DN ]=wk[i-1][DN ];
         wk[i][UP_I]=wk[i-1][UP_I];
         wk[i][DN_I]=wk[i-1][DN_I];
         wk[i][A ]=wk[i-1][A ];
         wk[i][B ]=wk[i-1][B ];
        }
      //---
      double up =wk[i][UP];
      double dn =wk[i][DN];
      int up_i =(int)wk[i][UP_I];
      int dn_i =(int)wk[i][DN_I];
      int up_flg =(int)wk[i][UP_FLG];
      int dn_flg =(int)wk[i][DN_FLG];
      

      //---
      xFactor=LATR[i]*InpXSize;
      if(UPPER_X[i]>LOWER_X[i] && i-LOWER_X[i]>=InpFastPeriod)
        {
         if(HI2[i]==high[i] )
           {
            up=high[i];
            up_i=i;
            up_flg=1;
            wk[i][UP]=up;
            wk[i][UP_I]=(int)up_i;
            wk[i][UP_FLG]=(int)up_flg;
           }

         if(up_flg==1 && high[i]+size<up)
           {
            up_flg=0;
            wk[i][UP_FLG]=(int)up_flg;

            double lower[][2];            
            //update
            convex_lower(lower,low,up_i,up_i-(int(LOWER_X[i])-1));
            int sz=int(ArraySize(lower)*0.5);
            if(sz>1)
              {
               double best_d=0;
               int best=0;
               for(int j=0;j<sz-1;j++)
                 {
                  double d=dimension_up(lower[j+1][0],lower[j+1][1],lower[j][0],lower[j][1],LOWER[up_i],up_i,xFactor);
                  if(d>best_d) {  best=j; best_d=d; }
                 }
               if(best_d>0)
                 {
                  int n=(InpShowHistory)? i : 1;
                  drawTrend(1,n,InpColor,(int)lower[best+1][0],lower[best+1][1],(int)lower[best][0],lower[best][1],time,STYLE_SOLID,1,true);
                          
                 }
              }
           }
        }

      if(UPPER_X[i]<LOWER_X[i] && i-UPPER_X[i]>=InpFastPeriod)
        {
         if(LO2[i]==low[i])
           {
            dn=low[i];
            dn_i=i;
            dn_flg=1;
            wk[i][DN]=dn;
            wk[i][DN_I]=(int)dn_i;
            wk[i][DN_FLG]=(int)dn_flg;

           }
         if(dn_flg==1 && low[i]-size > dn )
           {
            dn_flg=0;
            wk[i][DN_FLG]=(int)wk[i][DN_FLG];

            double upper[][2];
            // update tl
            convex_upper(upper,high,dn_i,dn_i-(int(UPPER_X[i])-1));
            int sz=int(ArraySize(upper)*0.5);
            if(sz>1)
              {
               double best_d=0;
               int best=0;
               for(int j=0;j<sz-1;j++)
                 {
                  double d=dimension_dn(upper[j+1][0],upper[j+1][1],upper[j][0],upper[j][1],UPPER[dn_i],dn_i,xFactor);
                  if(d>best_d) {  best=j;best_d=d;   }
                 }
               if(best_d>0)
                 {
                  int n=(InpShowHistory)? i : 2;
                  drawTrend(1,n,InpColor,(int)upper[best+1][0],upper[best+1][1],(int)upper[best][0],upper[best][1],time,STYLE_SOLID,1,true);

                 }

              }
           }
        }

      //---

     }

//---   
   return(rates_total);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawTrend(int no1,int no2,
               const color clr,const int x0,const double y0,const int x1,const double y1,
               const datetime &time[],const ENUM_LINE_STYLE style,const int width,const bool isRay)
  {

   if(-1<ObjectFind(0,StringFormat("AutoTL_%d_#%d",no1,no2)))
     {
      ObjectMove(0,StringFormat("AutoTL_%d_#%d",no1,no2),0,time[x0],y0);
      ObjectMove(0,StringFormat("AutoTL_%d_#%d",no1,no2),1,time[x1],y1);
     }
   else
     {
      ObjectCreate(0,StringFormat("AutoTL_%d_#%d",no1,no2),OBJ_TREND,WinNo,time[x0],y0,time[x1],y1);
      ObjectSetInteger(0,StringFormat("AutoTL_%d_#%d",no1,no2),OBJPROP_COLOR,clr);
      ObjectSetInteger(0,StringFormat("AutoTL_%d_#%d",no1,no2),OBJPROP_STYLE,style);
      ObjectSetInteger(0,StringFormat("AutoTL_%d_#%d",no1,no2),OBJPROP_WIDTH,width);
      ObjectSetInteger(0,StringFormat("AutoTL_%d_#%d",no1,no2),OBJPROP_RAY_RIGHT,isRay);
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
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectDeleteByBarNo(string prefix,int no)
  {
   int total=ObjectsTotal(0),
   length=StringLen(prefix);
   for(int i=total-1; i>=0; i--)
     {
      string objName=ObjectName(0,i);
      if(StringSubstr(objName,0,length)==prefix)
        {
         string res[];
         StringSplit(objName,'#',res);
         if(ArraySize(res)==2 && int(res[1])<no) ObjectDelete(0,objName);
        }
     }
  }  

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
