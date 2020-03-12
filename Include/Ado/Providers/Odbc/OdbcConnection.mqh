//+------------------------------------------------------------------+
//|                                               OdbcConnection.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#include "..\Base\DbConnection.mqh"
#include "OdbcTransaction.mqh"
//--------------------------------------------------------------------
/// \brief  \~russian  ласс, позвол€ющий устанавливать подключение к источнику данных ODBC
///         \~english Represents a connection to an ODBC data source
class COdbcConnection : public CDbConnection
  {
protected:
   virtual CDbTransaction *CreateTransaction() { return new COdbcTransaction(); }

public:
   /// \brief  \~russian конструктор
   ///         \~english constructor
                     COdbcConnection();
  };
//--------------------------------------------------------------------
COdbcConnection::COdbcConnection()
  {
   MqlTypeName("COdbcConnection");
   CreateClrObject("System.Data","System.Data.Odbc.OdbcConnection");
  }
//+------------------------------------------------------------------+
