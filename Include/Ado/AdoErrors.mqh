//+------------------------------------------------------------------+
//|                                                    AdoErrors.mqh |
//|                                             Copyright GF1D, 2010 |
//|                                             garf1eldhome@mail.ru |
//+------------------------------------------------------------------+
#property copyright "GF1D, 2010"
#property link      "garf1eldhome@mail.ru"

#define ADOERR_FIRST    5000
#define ADOERR_LAST     5100
//#define ADOERR_CONNECTION_ERROR    5001
//#define ADOERR_TRANSACTION_ERROR    5002

//-------------------------------------------------------------------------
/// \brief  \~russian Проверяет возникла ли ошибка, связанная с AdoSuite
///         \~english Checks if there was an error caused by AdoSuite
bool CheckAdoError()
  {
   return _LastError>=ERR_USER_ERROR_FIRST+ADOERR_FIRST && _LastError<=ERR_USER_ERROR_FIRST+ADOERR_LAST;
  }
//-------------------------------------------------------------------------
/// \brief  \~russian Сбрасывает ошибку, если она связана с AdoSuite 
///         \~english Resets the last Ado error if there was one
void ResetAdoError()
  {
   if(CheckAdoError()) ResetLastError();
  }
//+------------------------------------------------------------------+
