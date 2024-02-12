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
   Sender=1, // Sender
   Receiver=2 // Receiver
};

enum TypeMessages
{
   SERVICE_MSG_ROLE,
   SERVICE_MSG_PORT,
   SERVICE_MSG_IP,
   SERVICE_MSG_COMMAND,
   SERVICE_MSG_CLIENTS,
   SERVICE_MSG_CONNECTED
};

input ushort Port=50000; // Tcp Port
input TypeRole Role=Sender;
input string SenderIP="127.0.0.1"; // Sender IP Address (Used if Role is Receiver)
input string SymbolTranslation="EURUSDExternal=EURUSD;GBPUSDExternal=GBPUSD"; // Symbol Translation (Used if Role is Receiver)

ServerSocket* Server=NULL;
ClientSocket* Clients[];
ClientSocket* Client=NULL;
long chartid_tm;
ulong timer1;
string symbolexternal[];
string symbolinternal[];
const string vc="TradeCopierServiceFlag";


void OnStart()
{
   if(InstanceCheck() || !GetTradeManagerChartID())
      return;
   
   LoadTranslationTable();      
   
   if(Role==Sender)
      SenderStart();

   if(Role==Receiver)
      ReceiverStart();

   GlobalVariableDel(vc);
}


void SenderStart()
{
   Server=new ServerSocket(Port,false);
   if(!Server.Created())
      return;

   do
   {
      BroadcastSettings();
      AcceptNewConnections();
      for(int i=ArraySize(Clients)-1;i>=0;i--)
         BroadcastMessages(i);
      Sleep(1);
   }
   while(!IsStopped());

   for(int i=0;i<ArraySize(Clients);i++)
      delete Clients[i];

   delete Server;
   Server=NULL;
}


void ReceiverStart()
{
   bool isclientconnected=false;
   while(!IsStopped())
   {
      BroadcastSettings(isclientconnected);
      if(!Client)
      {
         Client=new ClientSocket(SenderIP,Port);
      }
      else
      {
         if(Client.IsSocketConnected())
         {
            isclientconnected=true;
            string message;
            do
            {
               message=Client.Receive("\r\n");
               if(message!="")
               {
                  EventChartCustom(chartid_tm,6601,SERVICE_MSG_COMMAND,0,Translate(message));
                  //Print(message);
               }
            }
            while(message!="");
         }
         else
         {
            isclientconnected=false;
            delete Client;
            Client=NULL;            
         }
      }
      Sleep(1);
   }

   if(Client)
   {
      delete Client;
      Client=NULL;            
   }
}


bool InstanceCheck()
{
   if(GlobalVariableCheck(vc))
   {
      Print("Terminated, one Instance of this Service already running!");
      return true;
   }
   else
   {
      GlobalVariableTemp(vc);
      GlobalVariableSet(vc,1);
   }
   return false;
}


void LoadTranslationTable()
{
   ushort separator=';';
   StringSplit(SymbolTranslation,separator,symbolexternal);
   int n=ArraySize(symbolexternal);
   ArrayResize(symbolinternal,n);
   for(int i=0;i<n;i++)
   {
      int s=symbolexternal[i].Find("=");
      if(s>0)
      {
         symbolinternal[i]=symbolexternal[i].Substr(s+1,-1);
         symbolexternal[i]=symbolexternal[i].Substr(0,s);
         //Print(symbolexternal[i]+"="+symbolinternal[i]);
      }
   }
}


string Translate(string& str)
{
   int n=ArraySize(symbolexternal);
   for(int i=0;i<n;i++)
      StringReplace(str,symbolexternal[i],symbolinternal[i]);
   return str;
}


bool GetTradeManagerChartID()
{
   bool found=false;
   long chartid=ChartFirst();
   while(chartid>-1)
   {
      if(ChartGetString(chartid,CHART_EXPERT_NAME)=="Trade Manager")
      {
         chartid_tm=chartid;
         found=true;
         break;
      }
      chartid=ChartNext(chartid);
   }
   return found;
}


void BroadcastSettings(bool isclientconnected=false)
{
   if(GetTickCount64()-timer1>=5000)
   {
      EventChartCustom(chartid_tm,6601,SERVICE_MSG_ROLE,0,IntegerToString(Role));
      EventChartCustom(chartid_tm,6601,SERVICE_MSG_PORT,0,IntegerToString(Port));
      EventChartCustom(chartid_tm,6601,SERVICE_MSG_IP,0,SenderIP);
      EventChartCustom(chartid_tm,6601,SERVICE_MSG_CLIENTS,0,IntegerToString(ArraySize(Clients)-1));
      EventChartCustom(chartid_tm,6601,SERVICE_MSG_CONNECTED,0,IntegerToString(isclientconnected));
      timer1=GetTickCount64();
   }
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
         //Print("New Client connected");
      }
   }
   while(NewClient!=NULL);
}


void BroadcastMessages(int clientindex)
{
   ClientSocket* client=Clients[clientindex];

   string command;
   do
   {
      command=client.Receive("\r\n");
      if(command!="" && command!="HEARTBEAT")
      {
         int cnt=ArraySize(Clients);
         for(int i=0;i<cnt;i++)
         {
            if(i!=clientindex)
            {
               Clients[i].Send(command+"\r\n");
            }
         }
      }
   }
   while(command!="");

   if(!client.IsSocketConnected())
   {
      delete client;
      int cnt=ArraySize(Clients);
      for(int i=clientindex+1;i<cnt;i++)
         Clients[i-1]=Clients[i];
      ArrayResize(Clients,cnt-1);
   }
}

