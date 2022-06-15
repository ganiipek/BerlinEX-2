#include <Trade/Trade.mqh>
#include <BerlinEX2/Others.mqh>

enum ENUM_POSITION_PROGRAM_STATE
{
   POSITION_PROGRAM_STATE_ERROR,
   POSITION_PROGRAM_STATE_PREPARED,
   POSITION_PROGRAM_STATE_SEND_OPEN,
   POSITION_PROGRAM_STATE_IN_PROCESS,
   POSITION_PROGRAM_STATE_SEND_CLOSE,
   POSITION_PROGRAM_STATE_CLOSED
};

struct SPosition
{
   ulong                         ticket;  
   double                        volume;
   ENUM_ORDER_TYPE               order_type;
   int                           step;
   int                           magic_number;
   ENUM_POSITION_PROGRAM_STATE   program_state;

   string ToString()
   {
      return StringFormat("ticket: %s, step: %s, magic_number: %s, program_state: %s", 
         IntegerToString(ticket), 
         IntegerToString(step), 
         IntegerToString(magic_number),
         EnumToString(program_state)
      );
   }
};

class PositionManager
{
   SPosition position_list[];
   bool debug;
   int magic_number;
   
   void add(SPosition &position)
   {
      int array_size = ArraySize(position_list);
      ArrayResize(position_list, array_size + 1);
      position_list[array_size] = position;

      if(debug)
      {
         PrintFormat("[%s-%s] positionManager (add) --> %s",
            _Symbol,
            IntegerToString(magic_number),
            position.ToString()
         );
      }
   }

   void remove(SPosition &position)
   {
      bool isShiftOn = false;
      for(int i=0; i < ArraySize(position_list) - 1; i++) 
      {
         if(position_list[i].ticket == position.ticket) 
         {
            isShiftOn = true;
         }
         if(isShiftOn == true) 
         {
            position_list[i] = position_list[i + 1];
         }
      }
      ArrayResize(position_list, ArraySize(position_list) - 1);

      if(debug)
      {
         PrintFormat("[%s-%s] positionManager (remove) --> %s",
            _Symbol,
            IntegerToString(magic_number),
            position.ToString()
         );
      }
      
   }

   public:
      PositionManager(bool _debug, int _magic_number)
      {
         debug = _debug;
         magic_number = _magic_number;
      }

      bool send(double order_price, ENUM_ORDER_TYPE type, double volume, int step)
      {
         MqlTradeRequest request = {};
         MqlTradeResult result   = {};

         request.action          = TRADE_ACTION_DEAL;
         request.price           = order_price;
         request.symbol          = _Symbol;
         request.type            = type;
         request.volume          = volume;
         request.type_filling    = GetFilling(_Symbol);
         request.comment         = "Step#" + IntegerToString(step);
         
         if(OrderSend(request, result))
         {
            if (result.retcode == 10009)
            {
               SPosition position;
               position.ticket         = result.deal;
               position.step           = step;
               position.volume         = volume;
               position.order_type     = type;
               position.magic_number   = magic_number;
               position.program_state  = POSITION_PROGRAM_STATE_IN_PROCESS;
   
               add(position);
               return true;
            }
         }

         return false;
      }

      void hedging()
      {
         for(int i=0; i < ArraySize(position_list); i++) 
         {
            ENUM_ORDER_TYPE   type  = position_list[i].order_type == ORDER_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
            double            price = type == ORDER_TYPE_BUY ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

            send(price, type, position_list[i].volume, position_list[i].step);
         }
      }

      void close(ulong ticket)
      {
         for(int i=0; i < ArraySize(position_list); i++) 
         {
            if(position_list[i].ticket == ticket) 
            {
               position_list[i].program_state = POSITION_PROGRAM_STATE_SEND_CLOSE;

               CTrade trade;
               trade.PositionClose(ticket);
            }
         }
      }

      void closeAll()
      {
         for(int i=0; i<ArraySize(position_list); i++) 
         {
            close(position_list[i].ticket);
         }
      }

      void closeAll(int step)
      {
         for(int i=0; i<ArraySize(position_list); i++) 
         {
            if(position_list[i].step <= step) 
            {
               close(position_list[i].ticket);
            }
         }
      }

      int getPositionCount()
      {
         return ArraySize(position_list);
      }

      double getProfit()
      {
         double profit = 0;
         for(int i=0; i < ArraySize(position_list); i++) 
         {
            if(PositionSelectByTicket(position_list[i].ticket))
            {
               profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + getComission(position_list[i].ticket);
            }
         }
         return profit;
      }

      double getComission(long position_ticket)
      {
         HistorySelectByPosition(position_ticket);
         int total_deals = HistoryDealsTotal();

         double commission = 0;
         for(int k=0; k<total_deals; k++)
         {
            long deal_ticket  = (long) HistoryDealGetTicket(k);
            commission       += HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION) + HistoryDealGetDouble(deal_ticket, DEAL_FEE);
         }
         return commission*2;
      }

      

      void OnTick()
      {
         for(int i=0; i < ArraySize(position_list); i++)
         {
            if(position_list[i].program_state == POSITION_PROGRAM_STATE_SEND_CLOSE)
            {
               if(PositionSelectByTicket(position_list[i].ticket))
               {
                  close(position_list[i].ticket);
               }
               else
               {
                  position_list[i].program_state = POSITION_PROGRAM_STATE_CLOSED;
                  remove(position_list[i]);
               }
            }
         }
      }
};