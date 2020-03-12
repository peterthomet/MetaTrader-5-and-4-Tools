//+------------------------------------------------------------------+
//|                                             OleDbTransaction.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#include "..\Base\DbTransaction.mqh"
//--------------------------------------------------------------------
/// \brief  \~russian  ласс, представл€ющий транзакцию OLE DB
///         \~english Represents transaction in an OLE DB data source
class COleDbTransaction : public CDbTransaction
  {
public:
   /// \brief  \~russian конструктор класса
   ///         \~english constructor
                     COleDbTransaction();
  };
//--------------------------------------------------------------------
COleDbTransaction::COleDbTransaction()
  {
   MqlTypeName("COleDbTransaction");
  }
//+------------------------------------------------------------------+
