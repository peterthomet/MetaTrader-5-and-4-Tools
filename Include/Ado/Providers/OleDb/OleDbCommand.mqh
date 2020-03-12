//+------------------------------------------------------------------+
//|                                                 OleDbCommand.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#include "..\Base\DbCommand.mqh"
#include "OleDbParameterList.mqh"
#include "OleDbDataReader.mqh"
//--------------------------------------------------------------------
/// \brief  \~russian Класс, представляющий исполняемую команду в источнике данных OLE DB
///         \~english Represents an SQL statement or stored procedure to execute against an OLE DB data source
class COleDbCommand : public CDbCommand
  {
protected:
   virtual CDbParameterList *CreateParameters() { return new COleDbParameterList(); }
   virtual CDbDataReader *CreateReader() { return new COleDbDataReader(); }

public:
   /// \brief  \~russian конструктор
   ///         \~english constructor
                     COleDbCommand();
  };
//--------------------------------------------------------------------
COleDbCommand::COleDbCommand()
  {
   MqlTypeName("COleDbCommand");
   CreateClrObject("System.Data","System.Data.OleDb.OleDbCommand");
  }
//+------------------------------------------------------------------+
