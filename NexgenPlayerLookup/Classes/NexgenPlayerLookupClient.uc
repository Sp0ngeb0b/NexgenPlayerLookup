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
class NexgenPlayerLookupClient extends NexgenClientController;

// Actor links
var NexgenPlayerLookup xControl;

// Other variables.
var int HostnameTries;                  // Amount of Hostname detection tries (every second).


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
 *  $DESCRIPTION  Timer function. Called every second. The following actions are performed:
 *                - Hostname detecting (only if ipToCountry is available)
 *
 **************************************************************************************************/
function Timer() {
  local string DataBack;
	local string playerIP, Host;
	local Actor IpToCountry;

  HostnameTries++;

  // Timeout detected
  if (HostnameTries > xControl.HostnameTimeout) {
    SetTimer(0.0, false);
    return;
  }
  
  playerIP = client.ipAddress;
  if (playerIP != "") {
  
    // Request info
  	DataBack = xControl.ipToCountry.GetItemName(PlayerIP);
  	
    // Check response
	  if(DataBack == "!Added to queue" || DataBack == "!Waiting in queue" || DataBack == "!Resolving now" || DataBack == "!Queue full" || DataBack == "!Disabled") {
	  	return;
  	}

	  Host = SelElem(DataBack, 2);

    // Invalid response, give up
  	if(Host == "") {
      SetTimer(0.0, false);
      return;
  	}
    xControl.reveiceHostname(client, Host);
    SetTimer(0.0, false);
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Decrypting code copied from HostnameBan.
 *
 **************************************************************************************************/
function string SelElem(string Str, int Elem, optional string Char) {
	local int pos;

	if(Char=="") Char=":";

	while(Elem>1) {
		Str=Mid(Str, InStr(Str, Char)+1);
		Elem--;
	}
	pos=InStr(Str, Char);

	if(pos != -1) Str=Left(Str, pos);

	return Str;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     ctrlID="NexgenPlayerLookupClient"
}
