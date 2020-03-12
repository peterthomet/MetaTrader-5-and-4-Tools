//+------------------------------------------------------------------+
//|                                            OdbcParameterList.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#include "OdbcParameter.mqh"
#include "..\Base\DbParameterList.mqh"

//--------------------------------------------------------------------
/// \brief  \~russian  ласс, представл€ющий коллекцию параметров команды ODBC
///         \~english Represents parameter collection in an ODBC data source
class COdbcParameterList : public CDbParameterList
{
protected:
   virtual CDbParameter* CreateParameter() { return new COdbcParameter(); }
   
public:
   /// \brief  \~russian конструктор класса
   ///         \~english constructor

   COdbcParameterList();
};

//--------------------------------------------------------------------
COdbcParameterList::COdbcParameterList()
{
   MqlTypeName("COdbcParameterList");
}