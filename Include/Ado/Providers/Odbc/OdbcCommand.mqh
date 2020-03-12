//+------------------------------------------------------------------+
//|                                                  OdbcCommand.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#include "..\Base\DbCommand.mqh"
#include "OdbcParameterList.mqh"
#include "OdbcDataReader.mqh"
//--------------------------------------------------------------------
/// \brief  \~russian Класс, представляющий исполняемую команду в источнике данных ODBC
///         \~english Represents an SQL statement or stored procedure to execute against an ODBC data source
class COdbcCommand : public CDbCommand
  {
protected:
   virtual CDbParameterList *CreateParameters() { return new COdbcParameterList(); }
   virtual CDbDataReader *CreateReader() { return new COdbcDataReader(); }

public:
   /// \brief  \~russian конструктор
   ///         \~english constructor
                     COdbcCommand();
  };
//--------------------------------------------------------------------
COdbcCommand::COdbcCommand()
  {
   MqlTypeName("COdbcCommand");
   CreateClrObject("System.Data","System.Data.Odbc.OdbcCommand");
  }
//+------------------------------------------------------------------+
