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
class NexgenPlayerLookupPanel extends NexgenPanel;

// Links
var NexgenPlayerLookupAdminClient xClient;           // Client belonging to this GUI
var NexgenTextFile InfoFile;                         // The local txt file to save lookup.

// GUI objects
var NexgenSimplePlayerListBox playerList;            // The online player list.
var NexgenSimpleListBox resultList;                  // The search result list.
var NexgenSimpleListBox nameList;                    // Playernames list
var NexgenSimpleListBox ipList;                      // IPs list.
var NexgenSimpleListBox hostnameList;                // Hostname list.
var NexgenEditControl ClientID;                      // Edit Control for Nexgen Client ID.
var NexgenEditControl HardwareID;                    // Edit Control for Hardware ID.
var NexgenEditControl MACHash;                       // Edit Control for MAC Hash.
var UMenuLabelControl statusLabel;                   // Status label control.
var UMenuLabelControl additionalDataLabel;           // Additional data (num of visits, last seen)
var UMenuLabelControl actionLabel;                   // Player's actions (mutes, warns, kicks, bans)
var UWindowSmallButton SelectPlayerList;             // Button to bring the player list to front.
var UWindowSmallButton SelectSearchResults;          // Button to bring the result list to front.
var UWindowSmallButton searchButton;                 // Button to initiate a search.
var NexgenEditControl searchInp;                     // Search keyword input.
var UWindowComboControl SearchType;                  // Specifies what data is to be searched for.
var UWindowSmallButton SaveToFileButton;             // Button to save current lookup to a local txt file.
var NexgenEditControl selectionInp;                  // Shows current selection.
var UWindowSmallButton copyButton;                   // Button to copy current selection.

// Control variables
var bool bPlayerDataRequested;                       // Playerdata requested?
var bool bSearchDataRequested;                       // Search data requested?
var bool bSearchDataAvailable;                       // Search data available?

// Misc variables
var Color StatusColor;                               // Color of the status label.



/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {
  local NexgenContentPanel p;
  local int r;

	// Get client controller.
	xClient = NexgenPlayerLookupAdminClient(client.getController(class'NexgenPlayerLookupAdminClient'.default.ctrlID));

	// Create layout & add components.
	createWindowRootRegion();
	splitRegionV(150, defaultComponentDist);
  splitRegionH(106, defaultComponentDist, , true);
  
  p = addContentPanel();
  p.splitRegionH(16, defaultComponentDist);
  
  p.splitRegionV(64);
	p.splitRegionH(16, defaultComponentDist);
	p.addLabel("Status:", true);
  statusLabel = p.addLabel("NexgenPlayerLookup version"@Class'NexgenPlayerLookup'.default.pluginVersion$" - Waiting for input.", true);
  
  additionalDataLabel = p.addLabel("", true);
  p.splitRegionH(16, defaultComponentDist);
  
  actionLabel = p.addLabel("", true);

  // p = p.addContentPanel();
  p.divideRegionV(2, defaultComponentDist);
  p.divideRegionH(2, defaultComponentDist);
  p.divideRegionH(2, defaultComponentDist);
  p.splitRegionH(16, defaultComponentDist);
  p.splitRegionH(16, defaultComponentDist);
  p.splitRegionH(16, defaultComponentDist);
  p.splitRegionH(16, defaultComponentDist);
  p.addLabel("Names", true, TA_Center);
  nameList = NexgenSimpleListBox(p.addListBox(class'NexgenSimpleListBox'));
  
  p.addLabel("Hostnames", true, TA_Center);
  hostnameList = NexgenSimpleListBox(p.addListBox(class'NexgenSimpleListBox'));
  
  p.addLabel("IPs", true, TA_Center);
  ipList = NexgenSimpleListBox(p.addListBox(class'NexgenSimpleListBox'));
  
  p.addLabel("Nexgen ID", true, TA_Center);
  p.splitRegionH(16, defaultComponentDist);
  ClientID = p.addEditBox();
  p.splitRegionH(16, defaultComponentDist);
  p.addLabel("Hardware ID", true, TA_Center);
  p.splitRegionH(16, defaultComponentDist);
  HardwareID = p.addEditBox();
  p.splitRegionH(16, defaultComponentDist);
  p.addLabel("MAC Hash", true, TA_Center);
  p.splitRegionH(16, defaultComponentDist);
  MACHash = p.addEditBox();

  splitRegionH(16, defaultComponentDist);
  
  p = addContentPanel();
  p.divideRegionH(5, defaultComponentDist);
  SearchType = p.addListCombo();
  SearchInp  = p.addEditBox();
  searchButton = p.addButton("Search Database", , AL_Center);
  SaveToFileButton = p.addButton("Save current Lookup to File");
  p.splitRegionV(48, defaultComponentDist, , true);
  selectionInp = p.addEditBox();
	copyButton = p.addButton("Copy");
  
  divideRegionV(2, defaultComponentDist);

  r = currRegion;
  resultList = NexgenSimpleListBox(addListBox(class'NexgenSimpleListBox'));
  selectRegion(r);
  playerList = NexgenSimplePlayerListBox(addListBox(class'NexgenSimplePlayerListBox'));
  
  SelectPlayerList    = addButton("Player List", , AL_Right);
  SelectSearchResults = addButton("Search Results", , AL_Left);

	// Configure components.
	playerList.bShowCountryFlag = false;
	statusLabel.TextColor = StatusColor;
	ClientID.editBox.bCanEdit = False;
	HardwareID.editBox.bCanEdit = False;
	MACHash.editBox.bCanEdit = False;
	ClientID.register(self);
	HardwareID.register(self);
  MACHash.register(self);
  searchInp.register(self);
  searchInp.setMaxLength(32);
  SelectPlayerList.bDisabled = True;
  SearchType.addItem("Client ID", "0");
	SearchType.addItem("Player Name", "1");
	SearchType.addItem("Player IP", "2");
	SearchType.addItem("Hostname", "3");
	SearchType.addItem("Hardware ID", "4");
	SearchType.addItem("MAC Hash", "5");
  SearchType.setSelectedIndex(0);
  SaveToFileButton.register(self);
  SaveToFileButton.bDisabled = True;
  selectionInp.SetDisabled(True);
  copyButton.register(self);
  
  // Force tree sorting (to prevent runaway loop crash for large amount of items)
	resultList.items.bTreeSort = True;
  nameList.items.bTreeSort = True;
	ipList.items.bTreeSort = True;
	hostnameList.items.bTreeSort = True;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Notifies the dialog of an event (caused by user interaction with the interface).
 *  $PARAM        control    The control object where the event was triggered.
 *  $PARAM        eventType  Identifier for the type of event that has occurred.
 *  $REQUIRE      control != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function notify(UWindowDialogControl control, byte eventType) {
	local NexgenSimpleListItem item;

	super.notify(control, eventType);


  if(control == SelectPlayerList && !SelectPlayerList.bDisabled && eventType == DE_Click) {
    playerList.BringToFront();
    SelectPlayerList.bDisabled = True;
    SelectSearchResults.bDisabled = False;
  }

  else if(control == SelectSearchResults && !SelectSearchResults.bDisabled && eventType == DE_Click) {
    resultList.BringToFront();
    SelectPlayerList.bDisabled = False;
    SelectSearchResults.bDisabled = True;
  }

  if(bPlayerDataRequested || bSearchDataRequested) return;

  // Player selected?
	else if (control == playerList && eventType == DE_Click) {
    playerSelected();
    
    // Deselect
    if(resultList.selectedItem != None) {
      resultList.selectedItem.bSelected = false;
		  resultList.selectedItem = None;
    }
  }
  
  // Result selected?
	else if (control == resultList && eventType == DE_Click) {
    resultSelected();

    // Deselect
    if(playerList.selectedItem != None) {
	 	  playerList.selectedItem.bSelected = false;
	  	playerList.selectedItem = None;
    }
  }

  // Player info selected?
  else if( control == nameList && eventType == DE_Click) nameSelected();
	else if( control == ipList && eventType == DE_Click) ipSelected();
	else if( control == hostnameList && eventType == DE_Click) hostnameSelected();
	else if( control == ClientID && eventType == DE_Click) selectionInp.setValue(ClientID.getValue());
  else if( control == HardwareID && eventType == DE_Click && HardwareID.getValue() != "") selectionInp.setValue(HardwareID.getValue());
  else if( control == MACHash && eventType == DE_Click && MACHash.getValue() != "") selectionInp.setValue(MACHash.getValue());
  
	// Search?
	else if(control == searchButton && eventType == DE_Click || control == searchInp && eventType == DE_EnterPressed) {
	  if(searchInp.GetValue() == "" || len(searchInp.GetValue()) < 3) {
      statusLabel.setText("Your search must atleast be 3 characters long.");
      return;
    }
    
    if(playerList.selectedItem != None) {
		  playerList.selectedItem.bSelected = false;
		  playerList.selectedItem = None;
    }
    clearList(4);

    searchButton.bDisabled = True;
    searchInp.SetDisabled(True);
    SearchType.Button.bDisabled = True;
    SearchType.bCanEdit = True;
    bSearchDataAvailable = False;
    bSearchDataRequested = True;
    
    resultList.BringToFront();
    SelectPlayerList.bDisabled = False;
    SelectSearchResults.bDisabled = True;
    
    statusLabel.setText("Searching ... Please wait.");
    xClient.search(searchInp.GetValue(), SearchType.getSelectedIndex());
	}
	
	// Copy Specific Info button clicked?
	else if (control == copyButton && eventType == DE_Click && selectionInp.GetValue() != "") {
    client.player.CopyToClipboard(selectionInp.GetValue());

	}
	
  // Save to File Button button clicked?
	else if (control == SaveToFileButton && eventType == DE_Click && !SaveToFileButton.bDisabled) {
    saveToFile();
	}
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Saves the current ACE Info to a local txt file in client's System folder.
 *
 **************************************************************************************************/
function saveToFile() {
  local string timeStemp, FileName;
  local int i;
  local NexgenSimpleListItem item;

  // Construct FileName
  timeStemp = Class'NexgenUtil'.static.serializeDate(xClient.level.year, xClient.level.month, xClient.level.day, xClient.level.hour, xClient.level.minute);
  FileName = "./[NexgenPlayerLookup]_"$timeStemp$"_"$ClientID.GetValue();

  // Create file actor
  if(InfoFile == none) InfoFile = xClient.spawn(class'NexgenTextFile', xClient);

  // Initialize new file
  if(InfoFile == none || !InfoFile.openFile(FileName$".tmp", FileName$".txt")) {
    client.showMsg("<C00>Failed to create log file!");
    return;
  }

  // Write Data to file
  InfoFile.println("----------------------------------------------------------------------------------------------------------------------------------------", true);
  InfoFile.println("Nexgen Player Lookup for Client ID:"@ClientID.GetValue(), true);
  InfoFile.println("", true);
  InfoFile.println("Time:"@Class'NexgenUtil'.static.serializeDate(xClient.level.year, xClient.level.month, xClient.level.day, xClient.level.hour, xClient.level.minute), true);
  InfoFile.println("NPL Version: "@Class'NexgenPlayerLookup'.default.pluginVersion, true);
  InfoFile.println("----------------------------------------------------------------------------------------------------------------------------------------", true);
  InfoFile.println("Nexgen Client ID:"@ClientID.GetValue(), true);
  InfoFile.println("Hardware ID:"@HardwareID.getValue(), true);
  InfoFile.println("MAC Hash:"@MACHash.getValue(), true);
  InfoFile.println("", true);
  InfoFile.println(actionLabel.Text, true);
  InfoFile.println(additionalDataLabel.Text, true);
  InfoFile.println("", true);
  InfoFile.println("Names:", true);
  InfoFile.println("------------", true);
  if(nameList.items.next != none) {
    item = NexgenSimpleListItem(nameList.items.next);
    while(item != none) {
      InfoFile.println(item.displayText, true);
      if(item.next != none) item = NexgenSimpleListItem(item.next);
      else item = none;
    }
  }
  InfoFile.println("", true);
  InfoFile.println("IP Adresses:", true);
  InfoFile.println("-------------------", true);
  if(ipList.items.next != none) {
    item = NexgenSimpleListItem(ipList.items.next);
    while(item != none) {
      InfoFile.println(item.displayText, true);
      if(item.next != none) item = NexgenSimpleListItem(item.next);
      else item = none;
    }
  }
  InfoFile.println("", true);
  InfoFile.println("Hostnames:", true);
  InfoFile.println("-------------------", true);
  if(hostnameList.items.next != none) {
    item = NexgenSimpleListItem(hostnameList.items.next);
    while(item != none) {
      InfoFile.println(item.displayText, true);
      if(item.next != none) item = NexgenSimpleListItem(item.next);
      else item = none;
    }
  }
  
  InfoFile.closeFile();

  // Inform player
  client.showMsg("<C02>Data saved in UnrealTournament -> System folder.");
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the data of one player has been received.
 *
 **************************************************************************************************/
function PlayerDataReceived() {
  bPlayerDataRequested = False;
  requestByID(xClient.DC.PlayerID);
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Server-side search process finished and data transfer has been started.
 *
 **************************************************************************************************/
function SearchInit(int indexes) {
  statusLabel.setText("Searching ... Please wait."@indexes$" results are being sent.");
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Search data has been successfully received.
 *
 **************************************************************************************************/
function SearchDone() {
  local int i, j;
  local string Data[256];
  local NexgenPlayerLookupItem item;

  // Deselect
  if(playerList.selectedItem != None) {
	  playerList.selectedItem.bSelected = false;
	  playerList.selectedItem = None;
  }
  if(resultList.selectedItem != None) {
	  resultList.selectedItem.bSelected = false;
	  resultList.selectedItem = None;
  }

  statusLabel.setText("Search Done.");
  bSearchDataRequested = False;
  bSearchDataAvailable = True;

  searchButton.bDisabled = False;
  searchInp.SetDisabled(False);
  SearchType.Button.bDisabled = False;
  SearchType.bCanEdit = False;
  
  // Add results to list
  for(i=0;i<ArrayCount(xClient.SearchPending);i++) {
    if(xClient.SearchPending[i] == "") break;
    
    switch(SearchType.getSelectedIndex()) {
      case 0: // ID
        item = NexgenPlayerLookupItem(resultList.items.append(class'NexgenPlayerLookupItem'));
			  item.displayText = class'NexgenPlayerLookup'.static.getID(xClient.SearchPending[i]);
			  item.clientID = item.displayText;
      return;
      case 1:
        if(class'NexgenPlayerLookup'.static.deCrunshData(Mid(xClient.SearchPending[i], 33), Data)) {
          for(j=0;j<ArrayCount(Data);j++) {
            if(Data[j] == "") break;
            item = NexgenPlayerLookupItem(resultList.items.append(class'NexgenPlayerLookupItem'));
			      item.displayText = Data[j];
			      item.clientID = class'NexgenPlayerLookup'.static.getID(xClient.SearchPending[i]);
          }
          class'NexgenPlayerLookup'.static.clearArray(Data);
        }
      break;
      case 2:
        if(class'NexgenPlayerLookup'.static.deCrunshData(Mid(xClient.SearchPending[i], 33), Data)) {
          for(j=0;j<ArrayCount(Data);j++) {
            if(Data[j] == "") break;
            item = NexgenPlayerLookupItem(resultList.items.append(class'NexgenPlayerLookupItem'));
			      item.displayText = Data[j];
			      item.clientID = class'NexgenPlayerLookup'.static.getID(xClient.SearchPending[i]);
          }
          class'NexgenPlayerLookup'.static.clearArray(Data);
        }
        break;
      case 3:
        if(class'NexgenPlayerLookup'.static.deCrunshData(Mid(xClient.SearchPending[i], 33), Data)) {
          for(j=0;j<ArrayCount(Data);j++) {
            if(Data[j] == "") break;
            item = NexgenPlayerLookupItem(resultList.items.append(class'NexgenPlayerLookupItem'));
			      item.displayText = Data[j];
			      item.clientID = class'NexgenPlayerLookup'.static.getID(xClient.SearchPending[i]);
          }
          class'NexgenPlayerLookup'.static.clearArray(Data);
        }
      break;
      case 4: // HW ID
        item = NexgenPlayerLookupItem(resultList.items.append(class'NexgenPlayerLookupItem'));
			  item.displayText = class'NexgenPlayerLookup'.static.getHWID(xClient.SearchPending[i]);
			  item.clientID = class'NexgenPlayerLookup'.static.getID(xClient.SearchPending[i]);
      break;
      case 5: // MAC Hash
        item = NexgenPlayerLookupItem(resultList.items.append(class'NexgenPlayerLookupItem'));
			  item.displayText = class'NexgenPlayerLookup'.static.getHWID(xClient.SearchPending[i]);
			  item.clientID = class'NexgenPlayerLookup'.static.getID(xClient.SearchPending[i]);
      break;
    }
  }
  resultList.sort();
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called each time a player was selected in the playerlist.
 *
 **************************************************************************************************/
function playerSelected() {
	local NexgenPlayerList item;

	item = NexgenPlayerList(playerList.selectedItem);
	if (item == none) return;
	
	// Clear all lists
	clearList(3);
	
  if(!requestByID(item.pClientID)) {
	  statusLabel.setText("Receiving data for selected player ...");
    bPlayerDataRequested = True;
	  xClient.DC.clear();
    xClient.requestPlayerData(item.pClientID);
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called each time a player was selected in the playerlist.
 *
 **************************************************************************************************/
function resultSelected() {
	local NexgenPlayerLookupItem item;

	item = NexgenPlayerLookupItem(resultList.selectedItem);
	if (item == none || !bSearchDataAvailable) return;

	// Clear all lists
	clearList(3);

	// Add info
	if(!requestByID(item.clientID)) {
  	statusLabel.setText("Receiving data for selected result ...");
	  xClient.DC.clear();
    xClient.requestPlayerData(item.ClientID);
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called each time an item in the nameList is selected. If a search is active, it
 *                automatically creates the entries in the iplist.
 *
 **************************************************************************************************/
function nameSelected() {
  local NexgenSimpleListItem item;
  local int indexes[64];
  local int i;
  
  item = NexgenSimpleListItem(nameList.selectedItem);
  if (item == none) return;

  // Update search value
  selectionInp.setValue(item.displayText);
  
  // Deselect in other lists
  if(ipList.selectedItem != None) {
    ipList.selectedItem.bSelected = false;
		ipList.selectedItem = None;
  }
    
  if(hostnameList.selectedItem != None) {
    hostnameList.selectedItem.bSelected = false;
		hostnameList.selectedItem = None;
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called each time an item in the ipList is selected. If a search is active, it
 *                automatically creates the entries in the namelist.
 *
 **************************************************************************************************/
function ipSelected() {
  local NexgenSimpleListItem item;
  local int indexes[64];
  local int i;

  item = NexgenSimpleListItem(ipList.selectedItem);
	if (item == none) return;
	
  // Update search value
  selectionInp.setValue(item.displayText);
  
  // Deselect in other lists
  if(nameList.selectedItem != None) {
    nameList.selectedItem.bSelected = false;
		nameList.selectedItem = None;
  }
    
  if(hostnameList.selectedItem != None) {
    hostnameList.selectedItem.bSelected = false;
		hostnameList.selectedItem = None;
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called each time an item in the ipList is selected. If a search is active, it
 *                automatically creates the entries in the namelist.
 *
 **************************************************************************************************/
function hostnameSelected() {
  local NexgenSimpleListItem item;
  local int indexes[64];
  local int i;

  item = NexgenSimpleListItem(hostnameList.selectedItem);
	if (item == none) return;

  // Update search value
  selectionInp.setValue(item.displayText);


  if(nameList.selectedItem != None) {
    nameList.selectedItem.bSelected = false;
	  nameList.selectedItem = None;
  }

  if(ipList.selectedItem != None) {
    ipList.selectedItem.bSelected = false;
		ipList.selectedItem = None;
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Decrunshes the names of a specified entry and creates for each name a new item in
 *                the name list.
 *  $PARAM        index The index of the entry.
 *
 **************************************************************************************************/
function deCrunchNamesList(string NameString) {
  local int index;
  local string Data[256];

  if(class'NexgenPlayerLookup'.static.deCrunshData(NameString, Data)) {
    for(index=0;index<ArrayCount(Data);index++) {
      if(Data[index] == "") break;
        
      createListItem(0, Data[index]);
    }
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Decrunshes the IPs of a specified entry and creates for each IP a new item in
 *                the ip list.
 *  $PARAM        index The index of the entry.
 *
 **************************************************************************************************/
function deCrunchIpsList(string IpString) {
  local int index;
  local string Data[256];

  if(class'NexgenPlayerLookup'.static.deCrunshData(IpString, Data)) {
    for(index=0;index<ArrayCount(Data);index++) {
      if(Data[index] == "") break;

      createListItem(1, Data[index]);
    }
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Decrunshes the Hostnames of a specified entry and creates for each Hostname a new item in
 *                the hostname list.
 *  $PARAM        index The index of the entry.
 *
 **************************************************************************************************/
function deCrunchHostnamesList(string HostnameString) {
  local int index;
  local string Data[256];

  if(class'NexgenPlayerLookup'.static.deCrunshData(HostnameString, Data)) {
    for(index=0;index<ArrayCount(Data);index++) {
      if(Data[index] == "") break;

      if(Data[index] != "!Disabled") createListItem(2, Data[index]);
    }
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Sets the action-label for a specified entry.
 *  $PARAM        index The index of the first entry in the database.
 *
 **************************************************************************************************/
function setActions(string ActionString) {
  local int warns, mutes, kicks, bans, visits;
  local int year, month, day, hour, minute;
  local string lastDate;
  local string warningsText, mutesText, kicksText, bansText, visitsText, minutesText, hoursText, dateText;

  
  // Get information
  if(class'NexgenPlayerLookup'.static.deCrunshActions(ActionString, warns, mutes, kicks, bans, visits, lastDate)) {

    if(warns == 0 && mutes == 0 && kicks == 0 && bans == 0) {
      actionLabel.setText("No actions found against this player.");
    } else {

      if(warns == 1) warningsText = warns$" warning";
      else warningsText = warns$" warnings";
      if(mutes == 1) mutesText = mutes$" mute";
      else mutesText = mutes$" mutes";
      if(kicks == 1) kicksText = kicks$" kick";
      else kicksText = kicks$" kicks";
      if(bans == 1) bansText = bans$" ban";
      else bansText = bans$" bans";
      
      actionLabel.setText(warningsText$", "$mutesText$", "$kicksText$" and "$bansText$" against this player.");
    
    }
    
    // Transform date
    if(class'NexgenUtil'.static.readDate(lastDate, year, month, day, hour, minute)) {
    
      if(minute < 10) minutesText = "0"$minute;
      else minutesText = string(minute);
      
      if(hour < 10) hoursText = "0"$hour;
      else hoursText = string(hour);
      dateText = day$"."@transformMonth(month)@year$" at "$hoursText$":"$minutesText;
    } else dateText = "Not available.";
    
    if(visits > 0) visitsText = string(visits);
    else visitsText = "No information.";
    
    additionalDataLabel.setText("Total visit count:"@visitsText$"         Last visit:"@dateText);
    
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Displays the data of one specified ID (by selecting an item in playerlist)
 *  $PARAM        ID The ID belonging to the player.
 *
 **************************************************************************************************/
function bool requestByID(string ID) {
  local int i, firstEntry;

  if(xClient.DC.PlayerID ~= ID) {
    ClientID.setValue(ID);
    HardwareID.setValue(xClient.DC.PlayerHWID);
    MACHash.setValue(xClient.DC.PlayerMAC);
    setActions(xClient.DC.PlayerAction);
  
    for(i=0;i<ArrayCount(xClient.DC.PlayerNames);i++) {
      deCrunchNamesList(xClient.DC.PlayerNames[i]);
      deCrunchIpsList(xClient.DC.PlayerIps[i]);
      deCrunchHostnamesList(xClient.DC.PlayerHostnames[i]);
    }
  } else return false;
  
  nameList.sort();
  ipList.sort();
  hostnameList.sort();
  SaveToFileButton.bDisabled = False;
  statusLabel.setText("Player lookup done.");
  return true;
}
  
  
/***************************************************************************************************
 *
 *  $DESCRIPTION  Clears a specified list
 *  $PARAM        type 0=Name List | 1=ID List | 2=Hostname List | 3=1+2+3 | 4=all 4 Lists
 *
 **************************************************************************************************/
function clearList(int type) {

  switch(type) {
  
    case 0:
      if(nameList.selectedItem != None) {
		    nameList.selectedItem.bSelected = false;
			  nameList.selectedItem = None;
	  	}
	    nameList.items.clear();
    break;
    case 1:
      if(ipList.selectedItem != None) {
		    ipList.selectedItem.bSelected = false;
			  ipList.selectedItem = None;
	    }
	    ipList.items.clear();
    break;
    case 2:
      if(hostnameList.selectedItem != None) {
		    hostnameList.selectedItem.bSelected = false;
			  hostnameList.selectedItem = None;
	    }
	    hostnameList.items.clear();
    break;
    case 4:
      if(resultList.selectedItem != None) {
		    resultList.selectedItem.bSelected = false;
			  resultList.selectedItem = None;
	    }
	    resultList.items.clear();
    case 3:
      clearList(0);
      clearList(1);
      clearList(2);
      ClientID.setValue("");
      HardwareID.setValue("");
      MACHash.setValue("");
      actionLabel.setText("");
      additionalDataLabel.setText("");
      SaveToFileButton.bDisabled = True;
    break;
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates a new entry in a specified list.
 *  $PARAM        i           0=Name List | 1=ID List
 *  $PARAM        displayText The text of the new item
 *
 **************************************************************************************************/
function createListItem(int i, string displayText) {
	local NexgenSimpleListItem item;

	switch(i) {
		case 0:
			item = NexgenSimpleListItem(nameList.items.append(class'NexgenSimpleListItem'));
			item.displayText = displayText;
			break;
		case 1:
			item = NexgenSimpleListItem(ipList.items.append(class'NexgenSimpleListItem'));
			item.displayText = displayText;
			break;
    case 2:
    	item = NexgenSimpleListItem(hostnameList.items.append(class'NexgenSimpleListItem'));
			item.displayText = displayText;
			break;
	}
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Notifies the client of a player event. Additional arguments to the event should be
 *                combined into one string which then can be send along with the playerEvent call.
 *  $PARAM        playerNum  Player identification number.
 *  $PARAM        eventType  Type of event that has occurred.
 *  $PARAM        args       Optional arguments.
 *  $REQUIRE      playerNum >= 0
 *
 **************************************************************************************************/
function playerEvent(int playerNum, string eventType, optional string args) {

	// Player has joined the game?
	if (eventType == client.PE_PlayerJoined) {
		addPlayerToList(playerList, playerNum, args);
	}

	// Player has left the game?
	if (eventType == client.PE_PlayerLeft) {
		playerList.removePlayer(playerNum);
		playerSelected();
	}

	// Attribute changed?
	if (eventType == client.PE_AttributeChanged) {
		updatePlayerInfo(playerList, playerNum, args);
		playerSelected();
	}
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Transforms a given month in a number to a string.
 *  $PARAM        month  The number of the month.
 *  $RETURN       The name of the month
 *
 **************************************************************************************************/
function string transformMonth(int month) {
  switch (month) {
    case 0:
    case 1: return "January";
    case 2: return "February";
    case 3: return "March";
    case 4: return "April";
    case 5: return "May";
    case 6: return "June";
    case 7: return "July";
    case 8: return "August";
    case 9: return "September";
    case 10: return "October";
    case 11: return "November";
    case 12: return "December";
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     panelIdentifier="NexgenPlayerLookupPanel"
     StatusColor=(R=25,G=25,B=112)
}


