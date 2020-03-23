/*##################################################################################################
##
##  Nexgen Player Lookup System version 2.02
##  Copyright (C) 2013 Patrick "Sp0ngeb0b" Peltzer
##
##  This program is free software; you can redistribute and/or modify
##  it under the terms of the Open Unreal Mod License version 1.1.
##
##  Contact: spongebobut@yahoo.com | www.unrealriders.de
##
##################################################################################################*/
class NexgenPlayerLookupAdminClient extends NexgenNetClientController;

// Object links.
var NexgenPlayerLookup xControl;        // The plugin server controller (server side).
var NexgenPlayerLookupConfig conf;      // Plugin configuration (server side).
var NexgenPlayerLookupDataContainer DC; // Data Container on the client side.
var NexgenPlayerLookupPanel NAP;        // The lookup panel for this client.

// Search variables.
var string SearchPending[5000];         // Local search Data buffer array.
var int searchIndex;                    // Current Index in DB during a search /
                                        // Next SearchPending data to be sent.
var int searchIndex2;                   // Next free SearchPending entry.
var int searchResults;                  // Total amount of search results.
var int searchType;                     // Type of current search.
var string searchString;                // Current search keyword.
var bool bSearchPending;                // Whether a Search is active and needs to be continued.
var bool bSearchResultPending;          // Whether the search result process is active.

// Command Constants.
const CMD_NPL_PREFIX = "NPL";           // Common ABM command prefix.
const CMD_PD_PLAYER  = "PDP";           // Player data command.
const CMD_PD_DONE    = "PDD";           // Signal when all player Data has been sent.
const CMD_SRCH_INIT  = "SRCHI";         // Search Init command.
const CMD_SRCH_Player  = "SRCHP";       // Search Data command.
const CMD_SRCH_DONE    = "SRCHD";       // Signal when all search Data has been sent.

// Other Constants.
const SearchPerStage = 256;             // Max amount of indexes to be worked off in one tick.
const SearchResultsPerStage = 64;       // Max amount of SearchPending entries to be sent in one tick.



/***************************************************************************************************
 *
 *  $DESCRIPTION  Replication block.
 *
 **************************************************************************************************/
replication {

	// Replicate to server...
	reliable if (role == ROLE_SimulatedProxy && client.hasRight("playerlookup"))
    requestPlayerData, search;
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes the client controller. This function is automatically called after
 *                the critical variables have been set, such as the client variable.
 *  $PARAM        creator  The Actor that has added the controller to the client.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function initialize(optional Actor creator) {
	xControl = NexgenPlayerLookup(creator);
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Modifies the setup of the Nexgen remote control panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function setupControlPanel() {
  if(client.hasRight("playerlookup")) {
    NAP = NexgenPlayerLookupPanel(client.mainWindow.mainPanel.addPanel("Player Lookups", class'NexgenPlayerLookupPanel', , "game"));
    DC = spawn(Class'NexgenPlayerLookupDataContainer', self);
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Timer tick function. Called when the game performs its next tick.
 *                The following actions are performed:
 *                 - Continues an active search.
 *                 - Add the next Search Data to Output buffer/queue.
 *                 - Processes pending data in the output buffer.
 *                 - Check for unacknowledged packets.
 *                 - Processes pending data in the input buffer.
 *                 - Move next data from queue to buffer
 *  $PARAM        delta  Time elapsed (in seconds) since the last tick.
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function tick(float deltaTime) {

  // Continue search or sending search result if neccessary (only Server side)
  if(bSearchPending) processSearch();
  else if(bSearchResultPending) processSearchResult();

  super.tick(deltaTime);

}


 /***************************************************************************************************
 *
 *  $DESCRIPTION  Sends the Data of one specific client to the other machine.
 *  $PARAM        ID  The client ID of the specific client.
 *
 **************************************************************************************************/
function requestPlayerData(string ID) {
  local int index, i, firstEntry, indexes[64];

  if(!client.hasRight("playerlookup") || bSearchPending || bSearchResultPending) return;

  firstEntry = xControl.getEntryByID(ID, indexes);
  if(firstEntry != -1) {
    sendStr(CMD_NPL_PREFIX @ CMD_PD_Player @ "PlayerAction" @ class'NexgenPlayerLookup'.static.formatCmdArgFixed(conf.get("PlayerAction", firstEntry)));

    for(i=0;i<ArrayCount(indexes);i++) {
      if(indexes[i] == -1) break;

      sendStr(CMD_NPL_PREFIX @ CMD_PD_Player @ "PlayerNames" @ class'NexgenPlayerLookup'.static.formatCmdArgFixed(conf.get("PlayerData", indexes[i])) @ index);
      sendStr(CMD_NPL_PREFIX @ CMD_PD_Player @ "PlayerIps" @ class'NexgenPlayerLookup'.static.formatCmdArgFixed(conf.get("PlayerIps", indexes[i])) @ index);
      sendStr(CMD_NPL_PREFIX @ CMD_PD_Player @ "PlayerHostnames" @ class'NexgenPlayerLookup'.static.formatCmdArgFixed(conf.get("PlayerHostnames", indexes[i])) @ index);

      index++;
    }
  }

  // Finish command
  sendStr(CMD_NPL_PREFIX @ CMD_PD_Done);

}


 /***************************************************************************************************
 *
 *  $DESCRIPTION  Performs a database search for a specific string and one data type. Results are
 *                being saved inside the SearchPending buffer array.
 *  $PARAM        srchString  (Partial)-Search String.
 *  $PARAM        type  Specifies the data type: 0=ID,1=Name,2=IP,3=Hostname,4=HWID,5=MAC Hash
 *
 **************************************************************************************************/
function search(string srchString, int type) {
  local int i;

  if(!client.hasRight("playerlookup") || bSearchPending || bSearchResultPending) return;

  // Reset old search variables
  for(i=0;i<ArrayCount(SearchPending);i++) SearchPending[i] = "";
  searchIndex = 0;
  searchIndex2 = 0;
  searchResults = 0;
  searchString = srchString;
  searchType = type;

  // Init new search
  bSearchPending = True;
  bSearchResultPending = False;

}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called every tick if a search is active and fills the search buffer. Splitted into
 *                several calls to avoid complete performance overload of the server.
 *
 **************************************************************************************************/
function processSearch() {
  local int j, i;
    local string Data[256];

   for(j=0;j<SearchPerStage;j++) {
    if(SearchIndex == conf.getArrayCount()) {
      sendStr(CMD_NPL_PREFIX @ CMD_SRCH_INIT @ searchResults);
      SearchIndex = 0;
      bSearchPending = False;
      bSearchResultPending = True;
      return;
    }

    switch(searchType) {
      case 0:
        if(class'NexgenPlayerLookup'.static.getID(conf.get("PlayerAction", SearchIndex)) ~= searchString) {
          SearchPending[0] = class'NexgenPlayerLookup'.static.getID(conf.get("PlayerAction", SearchIndex));
          sendStr(CMD_NPL_PREFIX @ CMD_SRCH_INIT @ "1");
          SearchIndex = 0;
          bSearchPending = False;
          bSearchResultPending = True;
          return;
        }
      break;
      case 1:
        if(InStr(CAPS(conf.get("PlayerData", SearchIndex)), CAPS(searchString)) != -1) {
          class'NexgenPlayerLookup'.static.deCrunshData(conf.get("PlayerData", SearchIndex), Data);
          for(i=0;i<ArrayCount(Data);i++) {
            if(Data[i] == "") break;
            if(InStr(CAPS(Data[i]), CAPS(searchString)) != -1) {
              searchResults++;
              if(SearchPending[searchIndex2] == "") SearchPending[searchIndex2] = class'NexgenPlayerLookup'.static.getID(conf.get("PlayerAction", xControl.getFirstEntry(SearchIndex)))$xControl.separator$Data[i];
              else SearchPending[searchIndex2] = SearchPending[searchIndex2]$xControl.separator$Data[i];
           }
          }
          class'NexgenPlayerLookup'.static.clearArray(Data);
          if(SearchPending[searchIndex2] != "") searchIndex2++;
        }
      break;
      case 2:
        if(InStr(CAPS(conf.get("PlayerIps", SearchIndex)), CAPS(searchString)) != -1) {
          class'NexgenPlayerLookup'.static.deCrunshData(conf.get("PlayerIps", SearchIndex), Data);
          for(i=0;i<ArrayCount(Data);i++) {
            if(Data[i] == "") break;
            if(InStr(CAPS(Data[i]), CAPS(searchString)) != -1) {
              searchResults++;
              if(SearchPending[searchIndex2] == "") SearchPending[searchIndex2] = class'NexgenPlayerLookup'.static.getID(conf.get("PlayerAction", xControl.getFirstEntry(SearchIndex)))$xControl.separator$Data[i];
              else SearchPending[searchIndex2] = SearchPending[searchIndex2]$xControl.separator$Data[i];
            }
          }
          class'NexgenPlayerLookup'.static.clearArray(Data);
          searchIndex2++;
        }
      break;
      case 3:
        if(InStr(CAPS(conf.get("PlayerHostnames", SearchIndex)), CAPS(searchString)) != -1) {
          class'NexgenPlayerLookup'.static.deCrunshData(conf.get("PlayerHostnames", SearchIndex), Data);
          for(i=0;i<ArrayCount(Data);i++) {
            if(Data[i] == "") break;
            if(InStr(CAPS(Data[i]), CAPS(searchString)) != -1) {
              searchResults++;
              if(SearchPending[searchIndex2] == "") SearchPending[searchIndex2] = class'NexgenPlayerLookup'.static.getID(conf.get("PlayerAction", xControl.getFirstEntry(SearchIndex)))$xControl.separator$Data[i];
              else SearchPending[searchIndex2] = SearchPending[searchIndex2]$xControl.separator$Data[i];
            }
          }
          class'NexgenPlayerLookup'.static.clearArray(Data);
          searchIndex2++;
        }
      break;
      case 4:
        if(class'NexgenPlayerLookup'.static.getHWID(conf.get("PlayerAction", SearchIndex)) ~= searchString) {
          SearchPending[searchIndex2] = class'NexgenPlayerLookup'.static.getID(conf.get("PlayerAction", SearchIndex))$xControl.separator$class'NexgenPlayerLookup'.static.getHWID(conf.get("PlayerAction", SearchIndex));
          searchResults++;
          searchIndex2++;
        }
      break;
      case 5:
        if(class'NexgenPlayerLookup'.static.getMAC(conf.get("PlayerAction", SearchIndex)) ~= searchString) {
          SearchPending[searchIndex2] = class'NexgenPlayerLookup'.static.getID(conf.get("PlayerAction", SearchIndex))$xControl.separator$class'NexgenPlayerLookup'.static.getMAC(conf.get("PlayerAction", SearchIndex));
          searchResults++;
          searchIndex2++;
        }
      break;
    }
    SearchIndex++;
  }
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Called every tick and sends the SearchPending buffer entries to the output buffer/
 *                queue.
 *
 **************************************************************************************************/
function processSearchResult() {
  local int i;

  for(i=0; i<SearchResultsPerStage; i++) {
    if(SearchPending[SearchIndex] == "" || SearchIndex == ArrayCount(SearchPending)) {
      sendStr(CMD_NPL_PREFIX @ CMD_SRCH_DONE);
      bSearchResultPending = False;
      return;
    }

    sendStr(CMD_NPL_PREFIX @ CMD_SRCH_Player @ class'NexgenPlayerLookup'.static.formatCmdArgFixed(SearchPending[SearchIndex]) @ SearchIndex);
    SearchIndex++;
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a string was received from the other machine.
 *  $PARAM        str  The string that was send by the other machine.
 *
 **************************************************************************************************/
simulated function recvStr(string str) {
	local string cmd;
	local string args[10];
	local int argCount;

	// Check controller role.
	if (role != ROLE_Authority) {
		// Commands accepted by client.
		if(class'NexgenUtil'.static.parseCmd(str, cmd, args, argCount, CMD_NPL_PREFIX)) {
      switch (cmd) {
        case CMD_PD_PLAYER:   exec_PD_Player(args); break;
        case CMD_PD_DONE:     exec_PD_Done(); break;
        case CMD_SRCH_INIT:   exec_SRCH_INIT(args); break;
        case CMD_SRCH_PLAYER: exec_SRCH_Player(args); break;
        case CMD_SRCH_DONE:   exec_SRCH_Done(); break;
      }
    }
	}
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes a new search client-side.
 *  $PARAM        args[0]  Total amount of search results.
 *
 **************************************************************************************************/
simulated function exec_SRCH_INIT(string args[10]) {
  local int i;

  // Clear existing search.
  for(i=0;i<ArrayCount(SearchPending);i++) SearchPending[i] = "";

  // Notifiy GUI
  if(NAP != none) NAP.SearchInit(int(args[0]));
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a string was received from the other machine.
 *  $PARAM        args[0]  The variable to update (PlayerData, PlayerIps, PlayerHostnames,
 *                         PlayerAction)
 *  $PARAM        args[1]  The new value
 *  $PARAM        args[2]  New index in DC
 *
 **************************************************************************************************/
simulated function exec_PD_Player(string args[10]) {

  switch(args[0]) {
    case "PlayerNames":
      DC.PlayerNames[int(args[2])] = args[1]; break;
      break;
    case "PlayerIps":
      DC.PlayerIps[int(args[2])] = args[1]; break;
      break;
    case "PlayerHostnames":
      DC.PlayerHostnames[int(args[2])] = args[1]; break;
      break;
    case "PlayerAction":
      DC.PlayerID   = class'NexgenPlayerLookup'.static.getID(args[1]);
      DC.PlayerHWID = class'NexgenPlayerLookup'.static.getHWID(args[1]);
      DC.PlayerMAC  = class'NexgenPlayerLookup'.static.getMAC(args[1]);
      DC.PlayerAction = args[1];
      break;
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a string was received from the other machine.
 *  $PARAM        args[0]  The new value
 *  $PARAM        args[1]  New index in DC
 *
 **************************************************************************************************/
simulated function exec_SRCH_Player(string args[10]) {
  SearchPending[int(args[1])] = args[0];
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Informs GUI when the PlayerData has been received.
 *
 **************************************************************************************************/
simulated function exec_PD_Done() {
  if(NAP != none) NAP.PlayerDataReceived();
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Informs GUI when the search process has finished.
 *
 **************************************************************************************************/
simulated function exec_SRCH_Done() {
  if(NAP != none) NAP.SearchDone();
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     ctrlID="NexgenPlayerLookupAdminClient"
     WindowSize=1
}