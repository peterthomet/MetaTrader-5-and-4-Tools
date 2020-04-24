kbd {
  font-family: Consolas, "Lucida Console", monospace;
  display: inline-block;
  border-radius: 3px;
  padding: 0px 4px;
  box-shadow: 1px 1px 1px #777;
  margin: 2px;
  font-size: small;
  vertical-align: text-bottom;
  background: #eee;
  font-weight: 500;
  color: #555;
  cursor: pointer;
  font-variant: small-caps;
  font-weight: 600;

  /* This two work */
  /* letter-spacing: 0.5px; */
  letter-spacing: 1px;


  /* Prevent selection */
  -webkit-touch-callout: none;
  -webkit-user-select: none;
  -khtml-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

kbd:hover, kbd:hover * {
  color: black;
  /* box-shadow: 1px 1px 1px #333; */
}
kbd:active, kbd:active * {
  color: black;
  box-shadow: 1px 1px 0px #ddd inset;
}

kbd kbd {
  padding: 0px;
  margin: 0 1px;
  box-shadow: 0px 0px 0px black;
  vertical-align: baseline;
  background: none;
}

kbd kbd:hover {
  box-shadow: 0px 0px 0px black;
}

kbd:active kbd {
  box-shadow: 0px 0px 0px black;
  background: none;
}

/* Deep blue */
kbd.deep-blue, .deep-blue kbd {
  background: steelblue;
  color: #eee;
}

kbd.deep-blue:hover, kbd.deep-blue:hover *, .deep-blue kbd:hover {
  color: white;
}

/* Dark apple */
kbd.dark-apple, .dark-apple kbd {
  background: black;
  color: #ddd;
}

kbd.dark-apple:hover, kbd.dark-apple:hover *, .dark-apple kbd:hover {
  color: white;
}

/* Type writer */
kbd.type-writer, .type-writer kbd {
  border-radius: 10px;
  background: #333;
  color: white;
}





# Indicators and EA Snippets for MetaTrader 5 and 4
Some MT5/MT4 indicators and tools I use for my trading. Feel free to contribute improvements and let me know your ideas.

[![](http://img.youtube.com/vi/1ea2rmEVieE/maxresdefault.jpg)](http://www.youtube.com/watch?v=1ea2rmEVieE "MetaTrader 5 Trading Tools")


## Trade Manager Keys


### <kbd>Ctrl</kbd> Activates and Deactivates the Command Mode

   Keys in Command Mode:
   
   **<kbd>1</kbd>** Open a Buy Trade
   **<kbd>3</kbd>** Open a Sell Trade
   **<kbd>5</kbd>** Activate/Deactivate Hard Single Break Even Mode
   **<kbd>6</kbd>** Activate/Deactivate Soft Basket Break Even Mode
   **<kbd>8</kbd>** Activate/Deactivate Close Basket at Break Even
   **<kbd>0</kbd>** Close all Trades
   **<kbd>,</kbd>** Decrease Trade Volume
   **<kbd>.</kbd>** Increase Trade Volume
   **<kbd>A</kbd>** Decrease Stop Loss
   **<kbd>S</kbd>** Increase Stop Loss
   **<kbd>D</kbd>** Decrease Take Profit
   **<kbd>F</kbd>** Increase Take Profit
   
   
### <kbd>Shift</kbd> Activates and Deactivates the Single Trade Management Mode

   Keys in Single Trade Management Mode:

   **<kbd>A</kbd>** Decrease Stop Loss
   **<kbd>S</kbd>** Increase Stop Loss
   **<kbd>D</kbd>** Decrease Take Profit
   **<kbd>F</kbd>** Increase Take Profit
   **<kbd>G</kbd>** Activate Previous Trade
   **<kbd>H</kbd>** Activate Next Trade

