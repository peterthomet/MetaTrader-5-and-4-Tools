//+------------------------------------------------------------------+
//|                                              OleDbDataReader.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#include "..\Base\DbDataReader.mqh"
//--------------------------------------------------------------------
/// \brief  \~russian Класс для чтения данных из источника OLE DB в прямом направлении
///         \~english Reads a forward-only stream of rows from an OLE DB data source
class COleDbDataReader : public CDbDataReader
  {
public:
   /// \brief  \~russian конструктор класса
   ///         \~english constructor
                     COleDbDataReader();
  };
//--------------------------------------------------------------------
COleDbDataReader::COleDbDataReader()
  {
   MqlTypeName("COleDbDataReader");
  }
//+------------------------------------------------------------------+
