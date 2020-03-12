//+------------------------------------------------------------------+
//|                                                AdoColumnList.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#include <Arrays\List.mqh>
#include "AdoColumn.mqh"
#include "..\AdoTypes.mqh"
//--------------------------------------------------------------------
/// \brief  \~russian Класс, представляющий коллекцию столбцов
///         \~english Represents columns collection
class CAdoColumnList : public CList
  {
public:
   /// \brief  \~russian Создает объект типа CAdoColumn. Виртуальный метод
   ///         \~english Creates new column. Virtual
   virtual CObject *CreateElement() { return new CAdoColumn(); }

   /// \brief  \~russian Возвращает тип объекта
   ///         \~english Gets object type
   virtual int Type() { return ADOTYPE_COLUMNLIST; }

   /// \brief  \~russian Возвращает столбец по индексу 
   ///         \~english Gets column by index
   CAdoColumn       *GetColumn(const int index);
   /// \brief  \~russian Возвращает столбец по имени 
   ///         \~english Gets column by name
   CAdoColumn       *GetColumn(const string name);

   /// \brief  \~russian Создает и добавляет колнку к коллекции
   ///         \~english Creates and adds new column to the collection
   /// \~russian \param name Имя столбца 
   /// \~english \param name Column name
   /// \~russian \param type Тип столбца
   /// \~english \param type Column type
   CAdoColumn       *AddColumn(const string name,const ENUM_ADOTYPES type);
  };
//--------------------------------------------------------------------
CAdoColumn *CAdoColumnList::GetColumn(const int index)
  {
   return GetNodeAtIndex(index);
  }
//--------------------------------------------------------------------
CAdoColumn *CAdoColumnList::GetColumn(const string name)
  {
   for(int i=0; i<Total(); i++)
     {
      CAdoColumn *col=GetColumn(i);
      if(col!=NULL)
         if(col.ColumnName()==name)
            return col;
     }

   return NULL;
  }
//--------------------------------------------------------------------
CAdoColumn *CAdoColumnList::AddColumn(const string name,const ENUM_ADOTYPES type)
  {
   CAdoColumn *newCol=CreateElement();
   newCol.ColumnName(name);
   newCol.ColumnType(type);
   Add(newCol);
   return newCol;
  }
//+------------------------------------------------------------------+
