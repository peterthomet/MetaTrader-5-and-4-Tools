//+------------------------------------------------------------------+
//|                                                    AdoColumn.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#include <Object.mqh>
#include "..\AdoTypes.mqh"
//--------------------------------------------------------------------
/// \brief  \~russian Класс, представляющий столбец в AdoTable
///         \~english Represents a column of an AdoTable
class CAdoColumn : public CObject
  {
private:
   string            _Name;
   ENUM_ADOTYPES     _Type;

public:
   // properties

   /// \brief  \~russian Возвращает имя столбца
   ///         \~english Gets column name
   const string ColumnName() { return _Name; }
   /// \brief  \~russian Задает имя столбца
   ///         \~english Sets column name
   void ColumnName(const string value) { _Name=value; }

   /// \brief  \~russian Возвращает тип столбца
   ///         \~english Gets type of a value stored in the column
   const ENUM_ADOTYPES ColumnType() { return _Type; }
   /// \brief  \~russian Задает тип столбца
   ///         \~english Sets type of a value stored in the column
   void ColumnType(const ENUM_ADOTYPES value) { _Type=value; }

   /// \brief  \~russian Возвращает тип объекта
   ///         \~english Gets type of the object
   virtual int Type() { return ADOTYPE_COLUMN; }
  };
//+------------------------------------------------------------------+
