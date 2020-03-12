//+------------------------------------------------------------------+
//|                                               OleDbParameter.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#include "..\Base\DbParameter.mqh"
//--------------------------------------------------------------------
/// \brief  \~russian  ласс, представл€ющий параметр команды OLE DB
///         \~english Represents command parameter in an OLE DB data source
class COleDbParameter : public CDbParameter
  {
public:
   /// \brief  \~russian конструктор класса
   ///         \~english constructor
                     COleDbParameter();
  };
//--------------------------------------------------------------------
COleDbParameter::COleDbParameter()
  {
   MqlTypeName("COleDbParameter");
   CreateClrObject("System.Data","System.Data.OleDb.OleDbParameter");
  }
//+------------------------------------------------------------------+
