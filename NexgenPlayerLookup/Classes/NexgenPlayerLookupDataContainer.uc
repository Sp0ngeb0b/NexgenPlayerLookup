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
class NexgenPlayerLookupDataContainer extends Info;

var string PlayerID;               // The client's Nexgen ID
var string PlayerHWID;             // The client's Hardware ID
var string PlayerMAC;              // The client's MAC Hash
var string PlayerNames[64];        // Name1$Name2$Name3 and so on
var string PlayerIps[64];          // IP1$IP2$IP3 and so on
var string PlayerHostnames[64];    // HN1$HN2$HN3 and so on
var string PlayerAction;           // NexgenID$HardwareID$MACHash$NumWarns$NumMute$NumKicks$NumBans#numVisits#LastVisitTime



/***************************************************************************************************
 *
 *  $DESCRIPTION  Resets all variables to their default.
 *
 **************************************************************************************************/
simulated function clear() {
  local int i;
  
  PlayerID="";
  PlayerHWID="";
  PlayerMAC="";
  PlayerAction="";
  
  for(i=0;i<ArrayCount(PlayerNames);i++) {
    PlayerNames[i]="";
    PlayerIps[i]="";
    PlayerHostnames[i]="";
  }
}



defaultproperties
{
}
