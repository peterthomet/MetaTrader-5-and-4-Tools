//+------------------------------------------------------------------+
//|                                                     AdoTable.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#include "AdoColumnList.mqh"
#include "AdoRecordList.mqh"
#include "AdoRecord.mqh"
#include "..\AdoTypes.mqh"
//--------------------------------------------------------------------
/// \brief  \~russian Класс, представляющий таблицу с данными
///         \~english Represents table
class CAdoTable
  {
private:
   CAdoColumnList   *_Columns;
   CAdoRecordList   *_Records;
   string            _TableName;

protected:
   /// \brief  \~russian Создает коллекцию столбцов таблицы. Виртуальный метод
   ///         \~english Creates column collection for the table
   virtual CAdoColumnList *CreateColumns() { return new CAdoColumnList(); }
   /// \brief  \~russian Создает коллекцию записей таблицы. Виртуальный метод
   ///         \~english Creates row collection for the table
   virtual CAdoRecordList *CreateRecords() { return new CAdoRecordList(); }

public:
   /// \brief  \~russian деструктор класса
   ///         \~english destructor
                    ~CAdoTable();

   // proprerties

   /// \brief  \~russian Возвращает имя таблицы
   ///         \~english Gets table name
   const string TableName() { return _TableName; }
   /// \brief  \~russian Задает имя таблицы
   ///         \~english Sets table name
   void TableName(const string value) { _TableName=value; }

   /// \brief  \~russian Возвращает коллекцию столбцов
   ///         \~english Gets column collection 
   CAdoColumnList   *Columns();
   /// \brief  \~russian Возвращает коллекцию записей
   ///         \~english Gets row collection
   CAdoRecordList   *Records();

   /// \brief  \~russian Проверяет есть ли записи в таблице
   ///         \~english Checks if the table has rows
   const bool HasRows() { return Records().Total()>0; }

   // method

   /// \brief  \~russian Создает запись с необходимой структурой. Следует использовать только этот метод!
   ///         \~english Creates new row with neccessary scheme. You should use this method only!
   CAdoRecord       *CreateRecord();
  };
//--------------------------------------------------------------------
CAdoTable::~CAdoTable(void)
  {
   if(CheckPointer(_Columns)) delete _Columns;
   if(CheckPointer(_Records)) delete _Records;
  }
//--------------------------------------------------------------------
CAdoColumnList *CAdoTable::Columns()
  {
   if(!CheckPointer(_Columns))
      _Columns=CreateColumns();

   return _Columns;
  }
//--------------------------------------------------------------------
CAdoRecordList *CAdoTable::Records(void)
  {
   if(!CheckPointer(_Records))
      _Records=CreateRecords();

   return _Records;
  }
//--------------------------------------------------------------------
CAdoRecord *CAdoTable::CreateRecord()
  {
   CAdoRecord *rec=Records().CreateElement();
   rec.SetColumns(Columns());
   return rec;
  }
//+------------------------------------------------------------------+
