//+------------------------------------------------------------------+
//|                                           OleDbParameterList.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#include "OleDbParameter.mqh"
#include "..\Base\DbParameterList.mqh"
//--------------------------------------------------------------------
/// \brief  \~russian  ласс, представл€ющий коллекцию параметров команды OLE DB
///         \~english Represents parameter collection in an OLE DB data source
class COleDbParameterList : public CDbParameterList
  {
protected:
   virtual CDbParameter *CreateParameter() { return new COleDbParameter(); }

public:
   /// \brief  \~russian конструктор класса
   ///         \~english constructor
                     COleDbParameterList();
  };
//--------------------------------------------------------------------
COleDbParameterList::COleDbParameterList()
  {
   MqlTypeName("COleDbParameterList");
  }
//+------------------------------------------------------------------+
