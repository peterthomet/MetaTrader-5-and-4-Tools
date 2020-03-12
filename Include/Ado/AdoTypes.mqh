//+------------------------------------------------------------------+
//|                                                     AdoTypes.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#define ADOTYPE_VALUELIST  3010
#define ADOTYPE_RECORD     3020
#define ADOTYPE_RECORDLIST 3030
#define ADOTYPE_COLUMN     3040
#define ADOTYPE_COLUMNLIST 3050

//--------------------------------------------------------------------
#define ADOTYPE_VALUE      3000
/// \brief \~russian Перечень типов, которые может принимать CAdoValue
/// \~english The types, which can be stored in CAdoValue
enum ENUM_ADOTYPES
  {
   ADOTYPE_BOOL      = ADOTYPE_VALUE + 1,
   ADOTYPE_LONG      = ADOTYPE_VALUE + 2,
   ADOTYPE_DOUBLE    = ADOTYPE_VALUE + 3,
   ADOTYPE_STRING    = ADOTYPE_VALUE + 4,
   ADOTYPE_DATETIME  = ADOTYPE_VALUE + 5
  };
//+------------------------------------------------------------------+
