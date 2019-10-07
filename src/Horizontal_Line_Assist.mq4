//+------------------------------------------------------------------+
//|                                                  Line_Helper.mq4 |
//|                                          Copyright 2019, poruru. |
//|              https://github.com/poruru210/Horizontal_Line_Assist |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, poruru."
#property link      "https://github.com/poruru210/Horizontal_Line_Assist"
#property version   "1.10"
#property description "Provides a function to assist in drawing horizontal lines."
#property icon "res\\icon.ico"
#property strict
#property indicator_chart_window

#resource "res\\H.bmp"
#resource "res\\T.bmp"
#resource "res\\V.bmp"

input string title1                    = "";        // 【マグネット】
input int  magnet_pixel                = 5;         // 最大吸着距離[ピクセル]

input string title2                    = "";        // 【ワンクリック削除<Shift+左クリック>】
input bool enable_easy_delete_object   = true;      // 利用する

input string title3                    = "";        // 【ワンクリックコピー<Ctrl+左クリック>】
input bool enable_easy_copy_property   = true;      // 利用する

input string title4                    = "";        // 【前足抜けチェック】
input bool enable_prev_value_check     = false;     // 利用する

input string title5                    = "";        // 【トレンドラインを水平線として利用】
input bool is_use_TLINE_as_HLINE       = true;      // 利用する

input string title6                    = "";        // 【オブジェクト自動選択解除】
input bool enabele_auto_deselect       = true;      // 利用する

input string title7                    = "";        // 【残時間表示】
input bool   is_disp_bar_time          = false;     // 利用する
input int    time_font_size            = 8;         // フォントサイズ
input color  time_font_color           = clrYellow; // フォント色
input int    time_offset_x             = -15;       // 位置オフセットX
input int    time_offset_y             = -50;       // 位置オフセットY

string   G_COLOR_FORMAT = "%d%d_COLOR";
string   G_STYLE_FORMAT = "%d%d_STYLE";
string   G_WIDTH_FORMAT = "%d%d_WIDTH";
string   G_OP_PERIOD    = "OP_PERIOD";

int      TIMER_INTERVAL = 250; //EventTiemr interval(ms)

string   HLINE_FORMAT   = "Horizontal Line %d";
string   TLINE_FORMAT   = "Trendline %d";
string   VLINE_FORMAT   = "Vertical Line %d";

string   TIP_OBJ_NAME   = "TIP_OBJ_H";
int      TIP_OBJ_WIDTH  = 16;
int      TIP_OBJ_HEIGHT = 16;
string   TIP_HEIH_TEXT  = "H";
string   TIP_LOW_TEXT   = "L";

string   CONTEXT_BTN_H          = "BTN_H";
string   CONTEXT_BTN_T          = "BTN_T";
string   CONTEXT_BTN_V          = "BTN_V";
int      CONTEXT_AUTO_CLOSE_SEC = 3;

string   REMAINE_TIME_OBJ_NAME   = "time";
string   REMAINE_TIME_FONT       = "Verdana";

double   newPrice = 0.0;
datetime newTime;
string   selected_obj_name=NULL;
int      selected_obj_type;
bool     isDispContext=false;
datetime timeContextDisp;
bool     isDispTip=false;

bool isMouseRightPressed = false;
bool isMouseLeftPressed  = false;
bool isShiftKeyPressed   = false;
bool isCtrlKeyPressed    = false;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(){      
   SetDefaultGlobalValues(OBJ_HLINE, PERIOD_M1);
   SetDefaultGlobalValues(OBJ_HLINE, PERIOD_M5);
   SetDefaultGlobalValues(OBJ_HLINE, PERIOD_M15);
   SetDefaultGlobalValues(OBJ_HLINE, PERIOD_M30);
   SetDefaultGlobalValues(OBJ_HLINE, PERIOD_H1);
   SetDefaultGlobalValues(OBJ_HLINE, PERIOD_H4);
   SetDefaultGlobalValues(OBJ_HLINE, PERIOD_D1);
   
   SetDefaultGlobalValues(OBJ_TREND, PERIOD_M1);
   SetDefaultGlobalValues(OBJ_TREND, PERIOD_M5);
   SetDefaultGlobalValues(OBJ_TREND, PERIOD_M15);
   SetDefaultGlobalValues(OBJ_TREND, PERIOD_M30);
   SetDefaultGlobalValues(OBJ_TREND, PERIOD_H1);
   SetDefaultGlobalValues(OBJ_TREND, PERIOD_H4);
   SetDefaultGlobalValues(OBJ_TREND, PERIOD_D1);
   
   SetDefaultGlobalValues(OBJ_VLINE, PERIOD_M1);
   SetDefaultGlobalValues(OBJ_VLINE, PERIOD_M5);
   SetDefaultGlobalValues(OBJ_VLINE, PERIOD_M15);
   SetDefaultGlobalValues(OBJ_VLINE, PERIOD_M30);
   SetDefaultGlobalValues(OBJ_VLINE, PERIOD_H1);
   SetDefaultGlobalValues(OBJ_VLINE, PERIOD_H4);
   SetDefaultGlobalValues(OBJ_VLINE, PERIOD_D1);
   
   ChartSetInteger(0, CHART_EVENT_OBJECT_CREATE, true);
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   ChartSetInteger(0, CHART_EVENT_MOUSE_WHEEL, true);
   
   EventSetMillisecondTimer(TIMER_INTERVAL);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
   EventKillTimer();
   DelGlobalValueIfExist(G_OP_PERIOD);
   HideContextMenu();
   HideTip();
   ObjectDelete(0, REMAINE_TIME_OBJ_NAME);

}


//+------------------------------------------------------------------+
//| called when the Timer event occurs                          |
//+------------------------------------------------------------------+
 void OnTimer(){
   AutoCloseContextMenu();
   UpdateRemainTime();
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
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+

void OnChartEvent(const int    id,
                  const long   &lparam,
                  const double &dparam,
                  const string &sparam)
  {
      //ref. https://www.mql5.com/ja/docs/constants/chartconstants/enum_chartevents
      switch(id){
         case CHARTEVENT_KEYDOWN:
            //OnChartKeyDown(lparam);
            break;
         case CHARTEVENT_MOUSE_MOVE:
            OnChartMouseMove((int)lparam, (int)dparam, sparam);
            break;
         case CHARTEVENT_MOUSE_WHEEL:
            break;
         case CHARTEVENT_OBJECT_CREATE:
            OnChartObjectCreate(sparam);
            break;
         case CHARTEVENT_OBJECT_CHANGE:
            OnChartObjectChange(sparam);
            break;
         case CHARTEVENT_OBJECT_DELETE:
            break;
         case CHARTEVENT_CLICK:
            OnChartClick((int)lparam, (int)dparam);
            break;
         case CHARTEVENT_OBJECT_CLICK:
            OnChartObjectClick((int)lparam, (int)dparam, sparam);
            break;
         case CHARTEVENT_OBJECT_DRAG:
            OnChartObjectDrag(sparam);
            break;
         case CHARTEVENT_OBJECT_ENDEDIT:
            break;
         case CHARTEVENT_CHART_CHANGE:
            OnChartObjectChange(sparam);
            break;
      }
  }
  
void OnChartKeyDown(long key_code){
  
}
  
void OnChartObjectCreate(string object_name){
   if(GlobalVariableCheck(G_OP_PERIOD)){
      int object_type = ObjectType(object_name);
      int period      = (int)GlobalVariableGet(G_OP_PERIOD);
      ObjectSetInteger(0, object_name, OBJPROP_COLOR, GetColor(object_type, period));
      ObjectSetInteger(0, object_name, OBJPROP_STYLE, GetStyle(object_type, period));
      ObjectSetInteger(0, object_name, OBJPROP_WIDTH, GetWidth(object_type, period));
   }
}

void OnChartClick(int x, int y){
   if(isDispContext){
      HideContextMenu();
   }
}

void OnChartObjectClick(int x, int y, string object_name){
   if(OnMenuClick(object_name)){
      return;
   }
         
   if(DeleteObjectWithShiftKey(object_name)){
      return;
   }
           
   selected_obj_name = object_name;
   selected_obj_type = ObjectType(object_name);
         
   CopyPropertiesWithCtrlKey();
}

void OnChartMouseMove(int x, int y, string object_name){

   GetModifierKeyAndMouseButtonState((uint)object_name);
         
   if(DispContextMenu(x, y)){
      return;
   }
   
   if(is_use_TLINE_as_HLINE && isMouseLeftPressed && selected_obj_type==OBJ_TREND){
      double price = ObjectGetDouble(0, selected_obj_name, OBJPROP_PRICE1);
      ObjectSetDouble(0, selected_obj_name, OBJPROP_PRICE2, price);       
   }
 
   if(!isDispContext && MagnetTo(x, y)){
      return;
   }
}

void OnChartObjectDrag(string object_name){
   if(isDispTip){
      if(selected_obj_type == OBJ_HLINE){
         ObjectSetDouble(0, object_name, OBJPROP_PRICE, newPrice);
      }
      else if(is_use_TLINE_as_HLINE && selected_obj_type == OBJ_TREND){
         ObjectSetDouble(0, selected_obj_name, OBJPROP_PRICE1, newPrice);
         ObjectSetDouble(0, selected_obj_name, OBJPROP_PRICE2, newPrice);  
      }
      ObjectSetInteger(0, selected_obj_name, OBJPROP_SELECTED, false);
   }
   
   selected_obj_name = NULL;
   HideTip();
}

void OnChartObjectChange(string object_name){
   BackupObjectProperties(object_name, ObjectType(object_name));
   if(enabele_auto_deselect){
      ObjectSet(object_name, OBJPROP_SELECTED, false);  
   }
}

bool MagnetTo(int x, int y){
   HideTip();
   int window;
   datetime time;
   double price;
   if(ChartXYToTimePrice(0, x, y, window, time, price) && time <= Time[0]){
      int i=iBarShift(NULL, 0, time);

      double high_price      = High[i];
      double low_price       = Low[i];
      color  fore_color      = clrWhite;
      
      int pixel_x,pixel_y;  
      if(ChartTimePriceToXY(0, 0, time, high_price, pixel_x, pixel_y) && MathAbs(pixel_y - y) < magnet_pixel){
         x = pixel_x - TIP_OBJ_WIDTH / 2;
         y = pixel_y - TIP_OBJ_HEIGHT - 5;
         if(enable_prev_value_check && high_price <= High[i+1]){
            fore_color = clrRed;
         } 
         DispTip(TIP_HEIH_TEXT, x, y, time, high_price, fore_color);
         return true;
      }
      
      if(ChartTimePriceToXY(0, 0, time, low_price, pixel_x, pixel_y) && MathAbs(pixel_y - y) < magnet_pixel){
         x = pixel_x - TIP_OBJ_WIDTH / 2;
         y = pixel_y + 5;
         if(enable_prev_value_check && low_price >= Low[i+1]){
            fore_color = clrRed;
         } 
         DispTip(TIP_LOW_TEXT, x, y, time, low_price, fore_color);
         return true;
      }
   }
   return false;
}

void DispTip(string text, int x, int y, datetime time, double price, color fore_color){
   //create hints label.  
   ObjectCreate(0, TIP_OBJ_NAME, OBJ_BUTTON, 0, 0, 0);
      
   //set properties.
   ObjectSetInteger(0, TIP_OBJ_NAME, OBJPROP_COLOR, fore_color);
   ObjectSetInteger(0, TIP_OBJ_NAME, OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, TIP_OBJ_NAME, OBJPROP_BORDER_COLOR, clrBlack);
   ObjectSetInteger(0, TIP_OBJ_NAME, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, TIP_OBJ_NAME, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, TIP_OBJ_NAME, OBJPROP_XSIZE, TIP_OBJ_WIDTH);
   ObjectSetInteger(0, TIP_OBJ_NAME, OBJPROP_YSIZE, TIP_OBJ_HEIGHT);
   ObjectSetInteger(0, TIP_OBJ_NAME, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, TIP_OBJ_NAME, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, TIP_OBJ_NAME, OBJPROP_HIDDEN, true); 
   ObjectSetInteger(0, TIP_OBJ_NAME, OBJPROP_ZORDER, 0);  
      
   ObjectSetString(0, TIP_OBJ_NAME, OBJPROP_FONT, "Arial");
   ObjectSetString(0, TIP_OBJ_NAME, OBJPROP_TEXT, text);
   newPrice = price;
   newTime = time;
   isDispTip = true;
}

void HideTip(){
   ObjectDelete(0, TIP_OBJ_NAME);
   isDispTip = false;
}


bool DeleteObjectWithShiftKey(string object_name){
      if(enable_easy_delete_object &&IsDeletableObjectType(object_name) && isShiftKeyPressed && isMouseLeftPressed){
         ObjectDelete(0, object_name);
         selected_obj_name = NULL;
         return true;
      }
      return false;
}

bool IsDeletableObjectType(string object_name){
   int type = ObjectType(object_name);
   return type == OBJ_HLINE
       || type == OBJ_TREND
       || type == OBJ_VLINE 
       || type == OBJ_RECTANGLE;
}

bool DispContextMenu(double posX, double posY)
{
   if(!isMouseRightPressed){
      return false;
   }
   
   if(isDispTip){
      CreateDrawLineButtons(posX, posY);
   }
  
   isDispContext=true;
   timeContextDisp=TimeCurrent();
   return true;
}

void CreateDrawLineButtons(double posX, double posY){
   ObjectCreate(0,CONTEXT_BTN_H,OBJ_BITMAP_LABEL,0,0,0);
   ObjectSet(CONTEXT_BTN_H,OBJPROP_SELECTABLE,false);
   ObjectSet(CONTEXT_BTN_H,OBJPROP_XDISTANCE,posX-30);
   ObjectSet(CONTEXT_BTN_H,OBJPROP_YDISTANCE,posY);
   ObjectSetString(0,CONTEXT_BTN_H,OBJPROP_BMPFILE,0, "::res\\H.bmp"); 

   ObjectCreate(0,CONTEXT_BTN_T,OBJ_BITMAP_LABEL,0,0,0);
   ObjectSet(CONTEXT_BTN_H,OBJPROP_SELECTABLE,false);
   ObjectSet(CONTEXT_BTN_T,OBJPROP_XDISTANCE,posX-30);
   ObjectSet(CONTEXT_BTN_T,OBJPROP_YDISTANCE,posY+TIP_OBJ_HEIGHT);
   ObjectSetString(0,CONTEXT_BTN_T,OBJPROP_BMPFILE,0, "::res\\T.bmp"); 

   ObjectCreate(0,CONTEXT_BTN_V,OBJ_BITMAP_LABEL,0,0,0);
   ObjectSet(CONTEXT_BTN_H,OBJPROP_SELECTABLE,false);
   ObjectSet(CONTEXT_BTN_V,OBJPROP_XDISTANCE,posX-30);
   ObjectSet(CONTEXT_BTN_V,OBJPROP_YDISTANCE,posY + TIP_OBJ_HEIGHT + TIP_OBJ_HEIGHT);
   ObjectSetString(0,CONTEXT_BTN_V,OBJPROP_BMPFILE,0, "::res\\V.bmp");
}

void HideContextMenu(){
   ObjectDelete(0, CONTEXT_BTN_H);
   ObjectDelete(0, CONTEXT_BTN_T);
   ObjectDelete(0, CONTEXT_BTN_V);
   newPrice=0.0;

   isDispContext=false;
   ChartRedraw(0);
}

void AutoCloseContextMenu(){
   if(isDispContext && TimeCurrent() > timeContextDisp + CONTEXT_AUTO_CLOSE_SEC){
      HideContextMenu();
   }
}

bool OnMenuClick(string object_name){

   if(object_name == CONTEXT_BTN_H){
      GlobalVariableSet(G_OP_PERIOD, Period());
      object_name = StringFormat(HLINE_FORMAT, GetTickCount());
      ObjectCreate(0, object_name, OBJ_HLINE, 0, 0, newPrice);
      ObjectSetInteger(0, object_name, OBJPROP_COLOR, GetColor(OBJ_HLINE, Period()));
      ObjectSetInteger(0, object_name, OBJPROP_STYLE, GetStyle(OBJ_HLINE, Period()));
      ObjectSetInteger(0, object_name, OBJPROP_WIDTH, GetWidth(OBJ_HLINE, Period()));
      return true;
   }
   else if(object_name == CONTEXT_BTN_T){      
      GlobalVariableSet(G_OP_PERIOD, Period());
      object_name = StringFormat(TLINE_FORMAT, GetTickCount());
      ObjectCreate(object_name, OBJ_TREND, 0, newTime, newPrice, TimeCurrent()+2764800, newPrice);
      ObjectSetInteger(0, object_name, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(0, object_name, OBJPROP_COLOR, GetColor(OBJ_TREND, Period()));
      ObjectSetInteger(0, object_name, OBJPROP_STYLE, GetStyle(OBJ_TREND, Period()));
      ObjectSetInteger(0, object_name, OBJPROP_WIDTH, GetWidth(OBJ_TREND, Period()));
      return true;
   }
   else if(object_name == CONTEXT_BTN_V){
      GlobalVariableSet(G_OP_PERIOD, Period());
      object_name = StringFormat(VLINE_FORMAT, GetTickCount());
      ObjectCreate(0,object_name, OBJ_VLINE, 0, newTime, 0);
      ObjectSetInteger(0, object_name, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(0, object_name, OBJPROP_COLOR, GetColor(OBJ_VLINE, Period()));
      ObjectSetInteger(0, object_name, OBJPROP_STYLE, GetStyle(OBJ_VLINE, Period()));
      ObjectSetInteger(0, object_name, OBJPROP_WIDTH, GetWidth(OBJ_VLINE, Period()));
      return true;
   }
   return false;
}

int GetColor(int object_type, int period){
   string key = StringFormat(G_COLOR_FORMAT, period, object_type);
   if(GlobalVariableCheck(key)){
      return (int)GlobalVariableGet(key);
   }
   else{
      return clrRed;
   }
}

int GetStyle(int object_type, int period){
   string key = StringFormat(G_STYLE_FORMAT, period, object_type);
   if(GlobalVariableCheck(key)){
      return (int)GlobalVariableGet(key);
   }
   else{
        return STYLE_SOLID;
   }
}

int GetWidth(int object_type, int period){
   string key = StringFormat(G_WIDTH_FORMAT, period, object_type);
   if(GlobalVariableCheck(key)){
      return (int)GlobalVariableGet(key);
   }
   else{
      return 1;  
   }
}

void BackupObjectProperties(string object_name, int object_type){
   if(object_type==OBJ_HLINE||object_type==OBJ_TREND||object_type==OBJ_VLINE){
      GlobalVariableSet(StringFormat(G_COLOR_FORMAT, Period(), object_type), ObjectGetInteger(0, object_name, OBJPROP_COLOR));
      GlobalVariableSet(StringFormat(G_STYLE_FORMAT, Period(), object_type), ObjectGetInteger(0, object_name, OBJPROP_STYLE));
      GlobalVariableSet(StringFormat(G_WIDTH_FORMAT, Period(), object_type), ObjectGetInteger(0, object_name, OBJPROP_WIDTH));
   }
}

bool CopyPropertiesWithCtrlKey(){
   if(enable_easy_copy_property && isCtrlKeyPressed){
      BackupObjectProperties(selected_obj_name, selected_obj_type);
      return true;
   }
   return false;
}

void GetModifierKeyAndMouseButtonState(uint sparam){
   isMouseLeftPressed  = ((sparam&0x01)==0x01);
   isMouseRightPressed = ((sparam&0x02)==0x02);
   isShiftKeyPressed   = ((sparam&0x04)==0x04);
   isCtrlKeyPressed    = ((sparam&0x08)==0x08);
}

void SetDefaultGlobalValues(int object_type, int period){
   SetColorIfNotExist(object_type, period);
   SetStyleIfNotExist(object_type, period);
   SetWidthIfNotExist(object_type, period);
}

void SetColorIfNotExist(int object_type, int period){
   string key = StringFormat(G_COLOR_FORMAT, period, object_type);
   if(GlobalVariableCheck(key)){
      return;
   }
   else{
      GlobalVariableSet(key, clrRed);
   }
}

void SetStyleIfNotExist(int object_type, int period){
   string key = StringFormat(G_STYLE_FORMAT, period, object_type);
   if(GlobalVariableCheck(key)){
      return;
   }
   else{
      GlobalVariableSet(key, STYLE_SOLID);
   }
}

void SetWidthIfNotExist(int object_type, int period){
   string key = StringFormat(G_WIDTH_FORMAT, period, object_type);
   if(GlobalVariableCheck(key)){
      return;
   }
   else{
      GlobalVariableSet(key, 1);
   }
}

void DelGlobalValueIfExist(string gvariable_name){
   if(GlobalVariableCheck(gvariable_name)){
      GlobalVariableDel(gvariable_name);
   }
}
 
void UpdateRemainTime(){
   if(!is_disp_bar_time){
      return;
   }
   double i;
   int m,s;
   m=Time[0]+Period()*60-TimeCurrent();
   i=m/60.0;
   s=m%60;
   m=(m-m%60)/60;

   if(ObjectFind(REMAINE_TIME_OBJ_NAME) != 0)
   {
      //create hints label.  
      ObjectCreate(0, REMAINE_TIME_OBJ_NAME, OBJ_LABEL, 0, 0, 0);
         
      //set properties.
      ObjectSetInteger(0, REMAINE_TIME_OBJ_NAME, OBJPROP_COLOR, time_font_color);
      ObjectSetInteger(0, REMAINE_TIME_OBJ_NAME, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, REMAINE_TIME_OBJ_NAME, OBJPROP_HIDDEN, true); 
      ObjectSetInteger(0, REMAINE_TIME_OBJ_NAME, OBJPROP_ZORDER, 0);  
         
      ObjectSetString(0, REMAINE_TIME_OBJ_NAME, OBJPROP_FONT, REMAINE_TIME_FONT);
      ObjectSetInteger(0, REMAINE_TIME_OBJ_NAME, OBJPROP_FONTSIZE, time_font_size);      
   }
   
   int pixel_x,pixel_y;  
   ChartTimePriceToXY(0, 0, Time[0], High[0], pixel_x, pixel_y);
   string text = StringFormat("NEXT %d:%02d", m, s);
   ObjectSetString(0, REMAINE_TIME_OBJ_NAME, OBJPROP_TEXT, text);
   ObjectSetInteger(0,REMAINE_TIME_OBJ_NAME, OBJPROP_XDISTANCE, pixel_x + time_offset_x);
   ObjectSetInteger(0,REMAINE_TIME_OBJ_NAME, OBJPROP_YDISTANCE, pixel_y + time_offset_y);  
 }
