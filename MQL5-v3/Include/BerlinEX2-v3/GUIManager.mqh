class GUIManager
{
    string program_name;
    public:
        void OnInit(string _program_name, ENUM_BASE_CORNER base_corner=CORNER_LEFT_LOWER)
        {
            int offset = base_corner == CORNER_LEFT_LOWER ? 0 : 13;

            program_name = _program_name;
            LabelCreate(ChartID(), program_name + "_trade_type",        4, offset + 48,      "Trade Type: -",         9, C'248, 248, 248', base_corner);
            LabelCreate(ChartID(), program_name + "_current_step",      4, offset + 35,      "Current Step: -",     9, C'248, 248, 248', base_corner);
            LabelCreate(ChartID(), program_name + "_weighted_price",    4, offset + 22,      "Weighted Price: -",     9, C'248, 248, 248', base_corner);
            LabelCreate(ChartID(), program_name + "_last_opened_price", 4, offset + 9,       "Last Opened Price: -",  9, C'248, 248, 248', base_corner);

            ChartRedraw();
        }

        void OnDeinit()
        {
            ObjectDelete(ChartID(), program_name + "_trade_type");
            ObjectDelete(ChartID(), program_name + "_current_step");
            ObjectDelete(ChartID(), program_name + "_weighted_price");
            ObjectDelete(ChartID(), program_name + "_last_opened_price");

            ChartRedraw();
        }

        void updateProgramTradeType(string trade_type)
        {
            LabelTextChange(ChartID(), program_name + "_trade_type", "Trade Type: " + trade_type);

            ChartRedraw();
        }

        void updateCurrentStep(int step)
        {
            LabelTextChange(ChartID(), program_name + "_current_step", "Current Step: " + IntegerToString(step));

            ChartRedraw();
        }

        void updateWeightedPrice(double price, int digits=8)
        {
            LabelTextChange(ChartID(), program_name + "_weighted_price", "Weighted Price: " + DoubleToString(price, digits));

            ChartRedraw();
        }

        void updateLastOpenedPrice(double price, int digits=8)
        {
            LabelTextChange(ChartID(), program_name + "_last_opened_price", "Last Opened Price: " + DoubleToString(price, digits));

            ChartRedraw();
        }
};


bool LabelCreate(const long              chart_ID=0,               // chart's ID
                 const string            name="Label",             // label name
                 const int               x=0,                      // X coordinate
                 const int               y=0,                      // Y coordinate
                 const string            text="Label",             // text
                 const int               font_size=12,
                 const color             clr=clrRed,               // color
                 ENUM_BASE_CORNER        base_corner=CORNER_LEFT_LOWER,
                 ENUM_ANCHOR_POINT       ANCHOR=ANCHOR_LEFT,
                 const string            font = "Arial",
                 const bool              back=false,               // in the background
                 const bool              selection=false,          // highlight to move
                 const bool              hidden=true,              // hidden in the object list
                 const long              z_order=10)                // priority for mouse click
{
    ResetLastError();
    
    if(!ObjectCreate(chart_ID, name, OBJ_LABEL, 0, 0, 0))
    {
        Print(__FUNCTION__,
            ": failed to create text label! Error code = ",GetLastError());
        return(false);
    }

    ObjectSetInteger(chart_ID, name, OBJPROP_YDISTANCE,y);
    ObjectSetInteger(chart_ID, name, OBJPROP_XDISTANCE,x);
    ObjectSetInteger(chart_ID, name, OBJPROP_CORNER, base_corner);
    ObjectSetInteger(chart_ID, name, OBJPROP_ANCHOR, ANCHOR);
    ObjectSetString( chart_ID, name, OBJPROP_TEXT,text);
    ObjectSetString( chart_ID, name, OBJPROP_FONT,font);
    ObjectSetInteger(chart_ID, name, OBJPROP_FONTSIZE,font_size);
    ObjectSetInteger(chart_ID, name, OBJPROP_ALIGN, ALIGN_CENTER);
    ObjectSetInteger(chart_ID, name, OBJPROP_COLOR,clr);
    ObjectSetInteger(chart_ID, name, OBJPROP_BACK,back);
    ObjectSetInteger(chart_ID, name, OBJPROP_SELECTABLE,selection);
    ObjectSetInteger(chart_ID, name, OBJPROP_SELECTED,selection);
    ObjectSetInteger(chart_ID, name, OBJPROP_HIDDEN,hidden);
    ObjectSetInteger(chart_ID, name, OBJPROP_ZORDER,z_order);

    ChartRedraw();

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

bool HLineCreate(const long            chart_ID=0,        // chart's ID
                 const string          name="HLine",      // line name
                 double                price=0,           // line price
                 const color           clr=clrRed,        // line color
                 const int             sub_window=0,      // subwindow index
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style
                 const int             width=1,           // line width
                 const bool            back=false,        // in the background
                 const bool            selection=true,    // highlight to move
                 const bool            hidden=true,       // hidden in the object list
                 const long            z_order=0)         // priority for mouse click
{
    //--- if the price is not set, set it at the current Bid price level
    if(!price)
        price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
    //--- reset the error value
    ResetLastError();
    //--- create a horizontal line
    if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
        {
        Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
        return(false);
        }
    //--- set line color
    ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
    //--- set line display style
    ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
    //--- set line width
    ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
    //--- display in the foreground (false) or background (true)
    ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
    //--- enable (true) or disable (false) the mode of moving the line by mouse
    //--- when creating a graphical object using ObjectCreate function, the object cannot be
    //--- highlighted and moved by default. Inside this method, selection parameter
    //--- is true by default making it possible to highlight and move the object
    ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
    ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
    //--- hide (true) or display (false) graphical object name in the object list
    ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
    //--- set the priority for receiving the event of a mouse click in the chart
    ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
    //--- successful execution
    return(true);
}

bool HLineMove(const long   chart_ID=0,   // chart's ID
               const string name="HLine", // line name
               double       price=0)      // line price
{
    //--- if the line price is not set, move it to the current Bid price level
    if(!price)
        price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
    //--- reset the error value
    ResetLastError();
    //--- move a horizontal line
    if(!ObjectMove(chart_ID,name,0,0,price))
        {
        Print(__FUNCTION__,
            ": failed to move the horizontal line! Error code = ",GetLastError());
        return(false);
        }
    //--- successful execution
    return(true);
}

bool EditCreate( 
                const string           name="Edit",              // object name
                const int              x=0,                      // X coordinate
                const int              y=0,                      // Y coordinate
                const string           text="0.5",              // text
                const color            back_clr=clrWhite,        // background color
                const ENUM_BASE_CORNER corner=CORNER_RIGHT_UPPER, // chart corner for anchoring
                const ENUM_ALIGN_MODE  align=ALIGN_CENTER,       // alignment type
                const bool             read_only=false,          // ability to edit
                const int              width=30,                 // width
                const int              height=18,                // height
                const string           font="Arial",             // font
                const int              font_size=10,             // font size
                const color            clr=clrBlack,             // text color
                const color            border_clr=clrNONE,       // border color
                const bool             back=false,               // in the background
                const bool             selection=false,          // highlight to move
                const bool             hidden=true,              // hidden in the object list
                const long             z_order=0)                // priority for mouse click
{
   long             chart_ID=0;
   int              sub_window=0;
   ResetLastError();
   if(!ObjectCreate(chart_ID,name,OBJ_EDIT,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create \"Edit\" object! Error code = ",GetLastError());
      return(false);
     }
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN,align);
   ObjectSetInteger(chart_ID,name,OBJPROP_READONLY,read_only);
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   return(true);
}

bool ButtonCreate(
                  const string            name="Button",            // button name
                  const int               x=0,                      // X coordinate
                  const int               y=0,                      // Y coordinate
                  const string            text="Button",            // text
                  const color             back_clr=clrAqua,  // background color
                  const ENUM_BASE_CORNER  corner=CORNER_RIGHT_UPPER, // chart corner for anchoring
                  const ENUM_ANCHOR_POINT anchor=ANCHOR_RIGHT, // chart corner for anchoring
                  const int               width=50,                 // button width
                  const int               height=15,                // button height
                  const string            font="Arial",             // font
                  const int               font_size=8,             // font size
                  const color             clr=clrBlack,             // text color
                  const color             border_clr=clrNONE,       // border color
                  const bool              state=false,              // pressed/released
                  const bool              back=false,               // in the background
                  const bool              selection=false,          // highlight to move
                  const bool              hidden=true,              // hidden in the object list
                  const long              z_order=10)                // priority for mouse click
{
   ResetLastError();
   long              chart_ID=0;
   int               sub_window=0;
   
   if(!ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create the button! Error code = ",GetLastError());
      return(false);
     }
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
   return(true);
}

bool ButtonTextChange(const long   chart_ID=0,    // chart's ID
                      const string name="Button", // button name
                      const string text="Text", // text
                      const color  clr=clrBlack // text color
                      )   
{
    //--- reset the error value
    ResetLastError();
    //--- change object text
    ObjectSetString(chart_ID,name,OBJPROP_TEXT, text);
    ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,clr);
    //--- set border color
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,clr);

    //--- successful execution
    return(true);
}