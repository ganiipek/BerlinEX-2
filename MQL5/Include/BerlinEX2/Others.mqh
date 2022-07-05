template <typename T> void AddValueInArray(T& A[], T value){
   int size = ArraySize(A);
   ArrayResize(A, size+1);
   A[size] = value;
}

template <typename T> void RemoveValueFromArray(T& A[], T value){
   bool isShiftOn = false;
   for(int i=0; i < ArraySize(A) - 1; i++) {
      if(A[i] == value) {
         isShiftOn = true;
      }
      if(isShiftOn == true) {
         A[i] = A[i + 1];
      }
   }
   ArrayResize(A, ArraySize(A) - 1);
}

template <typename T> void RemoveIndexFromArray(T& A[], int iPos)
{
   int iLast;
   for(iLast = ArraySize(A) - 1; iPos < iLast; ++iPos) 
      A[iPos] = A[iPos + 1];
   ArrayResize(A, iLast);
}

bool commentSep(string comment, string &result[], string sep="#")
{
  ushort u_sep;     // The code of the separator character
  // string result[];  // An array to get strings

  u_sep = StringGetCharacter(sep, 0);
  int k = StringSplit(comment, u_sep, result);
  if (k > 0)
  {
    return true;
  }

  return false;
}

datetime NewCandleTime = TimeCurrent();
bool IsNewCandle()
{
   // If the time of the candle when the function ran last
   // is the same as the time this candle started,
   // return false, because it is not a new candle.
   if (NewCandleTime == iTime(Symbol(), 0, 0)) return false;
   
   // Otherwise, it is a new candle and we need to return true.
   else
   {
      // If it is a new candle, then we store the new value.
      NewCandleTime = iTime(Symbol(), 0, 0);
      return true;
   }
}


bool CrossOver(double &value1[], double &value2[])
{
   if(ArraySize(value1) > 0 && ArraySize(value2) > 0)
   {
      if(value2[1] > value1[1] && value2[0] < value1[0]) return true;
   }
   
   return false;
}

bool CrossUnder(double &value1[], double &value2[])
{
   if(ArraySize(value1) > 0 && ArraySize(value2) > 0)
   {
      if(value2[1] < value1[1] && value2[0] > value1[0]) return true;
   }
   
   return false;
}

ENUM_ORDER_TYPE_FILLING GetFilling(const string Symb, const uint Type = ORDER_FILLING_IOC)
{
  const ENUM_SYMBOL_TRADE_EXECUTION ExeMode = (ENUM_SYMBOL_TRADE_EXECUTION)::SymbolInfoInteger(Symb, SYMBOL_TRADE_EXEMODE);
  const int FillingMode = (int)::SymbolInfoInteger(Symb, SYMBOL_FILLING_MODE);

  return ((FillingMode == 0 || (Type >= ORDER_FILLING_RETURN) || ((FillingMode & (Type + 1)) != Type + 1)) ? (((ExeMode == SYMBOL_TRADE_EXECUTION_EXCHANGE) || (ExeMode == SYMBOL_TRADE_EXECUTION_INSTANT)) ? ORDER_FILLING_RETURN : ((FillingMode == SYMBOL_FILLING_IOC) ? ORDER_FILLING_IOC : ORDER_FILLING_FOK)) : (ENUM_ORDER_TYPE_FILLING)Type);
}

bool TrendCreate(const long            chart_ID=0,        // çizelge kimliği
                 const string          name="TrendLine",  // çizelge ismi
                 datetime              time1=0,           // ilk noktanın zamanı
                 double                price1=0,          // ilk noktanın fiyatı
                 datetime              time2=0,           // ikinci noktanın zamanı
                 double                price2=0,          // ikinci noktanın fiyatı
                 const color           clr=clrRed,        // çizgi rengi
                 const int             width=1,           // çizgi genişliği
                 const bool            back=false,        // arkaplan nesnesi
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // çizgi stili
                 const bool            selection=false,    // taşıma için vurgula
                 const int             sub_window=0,      // alt pencere indisi
                 const bool            ray_left=false,    // çizginin sola doğru sürekliliği
                 const bool            ray_right=false,   // çizginin sağa doğru sürekliliği
                 const bool            hidden=true,       // nesne listesinde gizle
                 const long            z_order=0)         // fare ttıklaması önceliği
{
   ResetLastError();

   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2))
     {
      Print(__FUNCTION__,
            ": trend çizgisinin oluşturulması başarısız oldu! Hata kodu = ",GetLastError());
      return(false);
     }
   //--- çizgi rengini ayarla
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   //--- çizgi görünüm stilini ayarla
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
   //--- çizgi genişliğini ayarla
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
   //--- ön-planda (false) veya arkaplanda (true) göster
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   //--- çizgiyi fare ile taşıma modunu etkinleştir (true) veya devre dışı bırak (false)
   //--- ObjectCreate fonksiyonu ile bir nesne oluşturulurken,
   //--- nesne ön tanımlı olarak vurgulanamaz veya taşınamaz. Bu yöntemin içinde, parametre için ön tanımlı olarak 'true' değerinin
   //--- seçilmesi, nesnenin vurgulanmasını ve taşınmasını mümkün kılar
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   //--- çizginin sola doğru sürekli gösterimi modunu etkinleştir (true) veya devre dışı bırak (false)
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_LEFT,ray_left);
   //--- çizginin sağa doğru sürekli gösterimi modunu etkinleştir (true) veya devre dışı bırak (false)
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right);
   //--- nesne listesinde grafiksel nesnenin adını sakla (true) veya göster (false)
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   //--- çizelge üzerinde fare tıklaması olayının alınması için özellik ayarla
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   //--- başarılı çalıştırma
   return(true);
}

int countDecimal(double val)
{
  int digits=0;
  while(NormalizeDouble(val,digits)!=NormalizeDouble(val,8)) digits++;
  return digits;
}

bool LabelCreate(const long              chart_ID=0,               // chart's ID
                 const string            name="Label",             // label name
                 const int               x=0,                      // X coordinate
                 const int               y=0,                      // Y coordinate
                 const string            text="Label",             // text
                 const int               font_size=12,
                 const color             clr=clrRed,               // color
                 ENUM_ANCHOR_POINT       ANCHOR=ANCHOR_LEFT,
                 const string            font = "Arial",
                 const bool              back=false,               // in the background
                 const bool              selection=false,          // highlight to move
                 const bool              hidden=true,              // hidden in the object list
                 const long              z_order=10)                // priority for mouse click
  {
//--- reset the error value
   ResetLastError();
//--- create a text label
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,0,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create text label! Error code = ",GetLastError());
      return(false);
     }
//--- set label coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR, ANCHOR);
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the type of text alignment in the object
   ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN, ALIGN_CENTER);
//--- set color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
  
  
 bool LabelTextChange(const long    chart_ID=0,   // chart's ID
                     const string   name="Label", // object name
                     const string   text="Text",
                     const color    clr=C'248, 248, 248'               // color
                     
                     )  // text
  {
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ChartRedraw();
   return(true);
  }