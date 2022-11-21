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

int countDecimal(double val)
{
  int digits=0;
  while(NormalizeDouble(val,digits)!=NormalizeDouble(val,8)) digits++;
  return digits;
}

double myCeil (double value, double step) {
   return (MathCeil (value/step)*step);
}