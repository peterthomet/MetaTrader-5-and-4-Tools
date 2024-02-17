# Indicators and EA Snippets for MetaTrader 5

<br/>

> :warning: MT4 abandoned. Only the code for MT5 is up to date and gets further updates.

<br/>

Some MT5 indicators and tools I use for my trading. Feel free to contribute improvements and let me know your ideas.

My major developments are the **[Trade Manager](/Trade%20Manager/Trade%20Manager.mq5)**, a **[Currency Strength indicator](/Currency%20Index/CurrencyStrength.mq5)** and a **[Pivot Points indicator](/Pivots/MultiPivots.mq5)**. A special facility allows for up to 20 times faster backtesting of currency strength related strategies. A SQLite database is used to **[build up a store of currency strength data](/EA%20Snippets/CurrencyStrength/CurrencyStrengthWrite3.mq5)**. This database can then be used for backtesting with the **[Trade Manager](/Trade%20Manager/Trade%20Manager.mq5)**, or any other tool, without time consuming calculations.

For those who want to install everything in one shot, I have added a zip file of my **[entire MQL5 content](/MQL5%20Entire%20Content)**. Just install a new MT5 terminal and replace the folder MQL5 with the content of the zip file. In options, charts, set max bars to 1000000, some tools need this.

<br/>

[![](http://img.youtube.com/vi/1ea2rmEVieE/maxresdefault.jpg)](http://www.youtube.com/watch?v=1ea2rmEVieE "MetaTrader 5 Trading Tools")

<br/>
<br/>

## Trade Manager Keys


### <code>Ctrl</code> Activates and Deactivates the Command Mode

   Keys in Command Mode:
   
   **<code>1</code>** Open a Buy Trade<br>
   **<code>3</code>** Open a Sell Trade<br>
   **<code>5</code>** Activate/Deactivate Hard Single Break Even Mode<br>
   **<code>6</code>** Activate/Deactivate Soft Basket Break Even Mode<br>
   **<code>8</code>** Activate/Deactivate Close Basket at Break Even<br>
   **<code>0</code>** Close all Trades<br>
   **<code>,</code>** Decrease Trade Volume<br>
   **<code>.</code>** Increase Trade Volume<br>
   **<code>A</code>** Decrease Stop Loss<br>
   **<code>S</code>** Increase Stop Loss<br>
   **<code>D</code>** Decrease Take Profit<br>
   **<code>F</code>** Increase Take Profit<br>
   **<code>X</code>** Toggle Currency to open Buy/Sell Bag (7 Trades)<br>
   **<code>Y</code>** Reset open Buy/Sell Bag to current Pair<br>
   **<code>V</code>** Toggle View of opened Trades by Pairs or Currencies<br>
   **<code>L</code>** Toggle Lipstick (Drawings of Asia Range and NY Open)<br>

   
### <code>Shift</code> Activates and Deactivates the Single Trade Management Mode

   Keys in Single Trade Management Mode:

   **<code>A</code>** Decrease Stop Loss<br>
   **<code>S</code>** Increase Stop Loss<br>
   **<code>D</code>** Decrease Take Profit<br>
   **<code>F</code>** Increase Take Profit<br>
   **<code>G</code>** Activate Previous Trade<br>
   **<code>H</code>** Activate Next Trade<br>

<br/>
<br/>

MT5 uses the key codes not the characters. The characters listed here are based on this QWERTZ keyboard layout. If your keyboard layout is different, be sure you use the same keys, not the corresponding characters.

<br/>

![QWERTZ Keyboard Layout](./docs/images/QWERTZ-2.png)

<br/>
<br/>

## Trade Manager Sample, Setup a Basket with balanced Risk


[![](http://img.youtube.com/vi/IGt1eQA1peg/maxresdefault.jpg)](http://www.youtube.com/watch?v=IGt1eQA1peg "Trade Manager | Setup Basket with balanced Risk")

<br/>
<br/>

## Trade Manager Aggregated View and Close of Trades


[![](http://img.youtube.com/vi/XUngix22JGs/maxresdefault.jpg)](http://www.youtube.com/watch?v=XUngix22JGs "Trade Manager | Trade Manager Aggregated View of Trades")

<br/>
<br/>

## Trade Manager Add Pending Orders with Drag and Drop and Proper Risk


[![](http://img.youtube.com/vi/UVdEPk4fzwE/maxresdefault.jpg)](http://www.youtube.com/watch?v=UVdEPk4fzwE "Trade Manager | Add Pending Orders with Drag and Drop and Proper Risk")

<br/>
<br/>

## Forex Currency Strength Analysis Tool


[![](http://img.youtube.com/vi/g5eWgzQYdiU/maxresdefault.jpg)](http://www.youtube.com/watch?v=g5eWgzQYdiU "Forex Currency Strength Analysis Tool")

<br/>
<br/>

## Seconds Charts for MetaTrader 5


[![](http://img.youtube.com/vi/ElzsQ5niUTk/maxresdefault.jpg)](http://www.youtube.com/watch?v=ElzsQ5niUTk "Seconds Charts for MetaTrader 5")

<br/>
<br/>

## Synchronized Chart Scroll and Session Marking for MetaTrader 5


[![](http://img.youtube.com/vi/tWLcVPxSsCo/maxresdefault.jpg)](http://www.youtube.com/watch?v=tWLcVPxSsCo "Synchronized Chart Scroll and Session Marking for MetaTrader 5")

<br/>
<br/>

## Trade Copier Service for Trade Manager for MetaTrader 5


[![](http://img.youtube.com/vi/wVk4FK8SvyU/maxresdefault.jpg)](http://www.youtube.com/watch?v=wVk4FK8SvyU "Trade Copier Service for Trade Manager for MetaTrader 5")


