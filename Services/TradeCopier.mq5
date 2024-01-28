//
// TradeCopier.mq5
//

#property service
#property copyright "Copyright 2024, getYourNet IT Services"
#property link      "http://www.getyournet.ch"
#property version   "1.00"

//#define SOCKET_LIBRARY_USE_EVENTS
#include <SocketLibrary.mqh>

enum TypeRole
{
   Sender, // Sender
   Receiver // Receiver
};

input ushort InternalPort=51000; // Internal Port (Unique for each Terminal)
input ushort CommonPort=52000; // Common Port
input TypeRole Role=Sender;
input string SenderIP="127.0.0.1"; // Sender IP Address (Used if Role is Receiver)

ServerSocket* Server=NULL;
ClientSocket* Clients[];


void OnStart()
{
   Server=new ServerSocket(CommonPort,false);
   if(!Server.Created())
      return;

   while(!IsStopped())
   {
      AcceptNewConnections();
      
      for(int i=ArraySize(Clients)-1;i>=0;i--)
         HandleIncomingData(i);

      Sleep(1);
   }

   for(int i=0;i<ArraySize(Clients);i++)
      delete Clients[i];

   delete Server;
}


void AcceptNewConnections()
{
   ClientSocket* NewClient=NULL;
   do
   {
      NewClient=Server.Accept();
      if(NewClient!=NULL)
      {
         int sz=ArraySize(Clients);
         ArrayResize(Clients,sz+1);
         Clients[sz]=NewClient;
      }
   }
   while(NewClient!=NULL);
}


void HandleIncomingData(int clientindex)
{
   ClientSocket* client=Clients[clientindex];

   bool forceclose = false;
   string command;

   do
   {
      command = client.Receive("\r\n");

      if(command=="quote")
      {
         client.Send(Symbol() + "," + DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_BID), 6) + "," + DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_ASK), 6) + "\r\n");
      }
      else if(command=="close")
      {
         forceclose = true;

      }
      else if(StringFind(command,"FILE:")==0)
      {
         // ** See the example file-send script... **
      
         // Extract the base64 file data - the message minus the FILE: header - and 
         // put it into an array 
         string strFileData = StringSubstr(command, 5);
         uchar arrBase64[];
         StringToCharArray(strFileData, arrBase64, 0, StringLen(strFileData));
         
         // Do base64 decoding on the data, converting it to the zipped data 
         uchar arrZipped[], dummyKey[];
         if (CryptDecode(CRYPT_BASE64, arrBase64, dummyKey, arrZipped))
         {
            
            // Unzip the data 
            uchar arrOriginal[];
            if (CryptDecode(CRYPT_ARCH_ZIP, arrZipped, dummyKey, arrOriginal))
            {
               // Okay, we should now have the raw file 
               int f = FileOpen("receive.dat", FILE_BIN | FILE_WRITE);
               if (f == INVALID_HANDLE)
               {
                  Print("Unable to open receive.dat for writing");
               }
               else
               {
                  FileWriteArray(f, arrOriginal);
                  FileClose(f);
                  
                  Print("Created receive.dat file");
               }
            }
            else
            {
               Print("Unzipping of file data failed");               
            }
         }
         else
         {
            Print("Decoding from base64 failed");
         }
         
      }
      else if (command != "")
      {
         // Potentially handle other commands etc here.
         // For example purposes, we'll simply print messages to the Experts log
         Print("<- ",command);
      }
   }
   while(command!="");

   if(!client.IsSocketConnected() || forceclose)
   {
      Print("Client has disconnected");

      delete client;
      int ctClients = ArraySize(Clients);
      for(int i = clientindex + 1; i < ctClients; i++)
         Clients[i - 1] = Clients[i];
      ctClients--;
      ArrayResize(Clients, ctClients);
   }
}
