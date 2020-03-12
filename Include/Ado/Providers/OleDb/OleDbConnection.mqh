//+------------------------------------------------------------------+
//|                                              OleDbConnection.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#include "..\Base\DbConnection.mqh"
#include "OleDbTransaction.mqh"
//--------------------------------------------------------------------
/// \brief  \~russian  ласс, позвол€ющий устанавливать подключение к источнику данных OLE DB
///         \~english Represents a connection to an OLE DB data source
class COleDbConnection : public CDbConnection
  {
protected:
   virtual CDbTransaction *CreateTransaction() { return new COleDbTransaction(); }

public:
   /// \brief  \~russian конструктор
   ///         \~english constructor
                     COleDbConnection();
  };
//--------------------------------------------------------------------
COleDbConnection::COleDbConnection()
  {
   MqlTypeName("COleDbConnection");
   CreateClrObject("System.Data","System.Data.OleDb.OleDbConnection");
  }
//+------------------------------------------------------------------+
