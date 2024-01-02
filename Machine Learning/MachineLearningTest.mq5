
matrix weights1,weights2,weights3;               // matrices of weights 
matrix output1,output2,result;                   // matrices of neural layer outputs 
input int layer1=200;                            // the size of the first hidden layer 
input int layer2=200;                            // the size of the second hidden layer 
input int Epochs=20000;                          // the number of training epochs 
input double learningrate=3e-6;                            // learning rate 
input ENUM_ACTIVATION_FUNCTION activationfunction=AF_SWISH; // activation function 


void OnStart() 
{ 
   matrix data, target; 

   CreateData(data,target,1000);
   Train(data,target,Epochs);
   CreateData(data,target,10);
   Test(data,target);                    
} 


void CreateData(matrix &data,matrix &target,const int count) 
{
   data.Init(count,3);
   target.Init(count,1);

   data.Random(-10,10);

   vector X1=MathPow(data.Col(0)+data.Col(1)+data.Col(2), 2);
   vector X2=MathPow(data.Col(0),2)+MathPow(data.Col(1),2)+MathPow(data.Col(2),2);

   target.Col(X1/X2,0);
}


void Train(matrix &data,matrix &target,const int epochs=10000) 
{
   CreateNet();
   
   for(int ep=0;ep<epochs;ep++)
   {
      FeedForward(data);
     
      PrintFormat("Epoch %d, loss %.5f",ep,result.Loss(target,LOSS_MSE)); 

      Backprop(data,target);
   }
} 


void CreateNet() 
{
   weights1.Init(4,layer1);
   weights2.Init(layer1+1,layer2);
   weights3.Init(layer2+1,1);
   weights1.Random(-0.1, 0.1); 
   weights2.Random(-0.1, 0.1); 
   weights3.Random(-0.1, 0.1); 
} 


void FeedForward(matrix &data) 
{ 
   matrix temp=data;

   temp.Resize(temp.Rows(),weights1.Rows());
   temp.Col(vector::Ones(temp.Rows()),weights1.Rows()-1);
   
   output1=temp.MatMul(weights1); 

   output1.Activation(temp,activationfunction);
   
   temp.Resize(temp.Rows(),weights2.Rows());
   temp.Col(vector::Ones(temp.Rows()),weights2.Rows()-1);

   output2 = temp.MatMul(weights2); 

   output2.Activation(temp,activationfunction);

   temp.Resize(temp.Rows(),weights3.Rows());
   temp.Col(vector::Ones(temp.Rows()),weights3.Rows()-1);
   
   result=temp.MatMul(weights3); 
} 


bool Backprop(matrix &data,matrix &target)
{ 
   if(target.Rows()!=result.Rows()||target.Cols()!=result.Cols())
      return false;

   matrix temp;

   matrix loss=(target-result)*2;

   matrix gradient=loss.MatMul(weights3.Transpose());

   output2.Activation(temp,activationfunction);
   temp.Resize(temp.Rows(),weights3.Rows());
   temp.Col(vector::Ones(temp.Rows()),weights3.Rows()-1);
   weights3=weights3+temp.Transpose().MatMul(loss)*learningrate; 
   output2.Derivative(temp,activationfunction);
   gradient.Resize(gradient.Rows(),gradient.Cols()-1);
   loss=gradient*temp; 

   gradient=loss.MatMul(weights2.Transpose());

   output1.Activation(temp,activationfunction);
   temp.Resize(temp.Rows(),weights2.Rows());
   temp.Col(vector::Ones(temp.Rows()),weights2.Rows()-1);
   weights2=weights2+temp.Transpose().MatMul(loss)*learningrate; 
   output1.Derivative(temp,activationfunction);
   gradient.Resize(gradient.Rows(),gradient.Cols()-1);
   loss=gradient*temp; 

   temp=data; 
   temp.Resize(temp.Rows(),weights1.Rows());
   temp.Col(vector::Ones(temp.Rows()),weights1.Rows()-1);
   weights1=weights1+temp.Transpose().MatMul(loss)*learningrate; 

   return true; 
} 


void Test(matrix &data,matrix &target) 
{
   FeedForward(data);
   
   PrintFormat("Test loss %.5f",result.Loss(target,LOSS_MSE)); 

   ulong total=data.Rows();
   for(ulong i=0;i<total;i++)
      PrintFormat("(%.2f + %.2f + %.2f)^2 / (%.2f^2 + %.2f^2 + %.2f^2) =  Net %.2f, Target %.2f",data[i,0],data[i,1],data[i,2],data[i,0],data[i,1],data[i,2],result[i,0],target[i,0]);
}
