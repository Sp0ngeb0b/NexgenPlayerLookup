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
class NexgenPlayerLookupDataBase extends NexgenPlayerLookupConfig config(NexgenPlayerLookup);

// Database entries
var config int lastInstalledVersion;         // Last installed version
var config string PlayerData[25000];         // Name1$Name2$Name3 and so on
var config string PlayerIps[25000];          // IP1$IP2$IP3 and so on
var config string PlayerHostnames[25000];    // HN1$HN2$HN3 and so on
var config string PlayerAction[25000];       // NexgenID$HardwareID$MACHash$NumWarns$NumMute$NumKicks$NumBans#numVisits#LastVisitTime
var config string PlayerIndexes[25000];      // Indexes in the database of this player


// Variables for DB repairing in version 2.02
var bool bRepairingDatabase;
var NexgenPlayerLookup Controller;
var int lastEntry;
var string InvalidData[25000];
var string InvalidIP[25000];
var string InvalidHostname[25000];

// Constants for DB repairing in version 2.02
const UpdatesPerStage = 500;
const IterationsPerStage = 5000;


/***************************************************************************************************
 *
 *  $DESCRIPTION  Check if we need to perform database repairing. If yes, copy the corrupted entries
 *                to a temporary array and delete them from the DB.
 *
 **************************************************************************************************/
function PostBeginPlay() {
  local int i, orgIndex;

  if(lastInstalledVersion == 200 || lastInstalledVersion == 201) {
    bRepairingDatabase=True;
    foreach AllActors(class'NexgenPlayerLookup', Controller) break;
    if(Controller == none) {
      bRepairingDatabase=False;
      return;
    }

    Controller.control.nscLog(Controller.pluginName$": Invalid Database repairing started. STAGE 1 running ...");
    Controller.bRepairingDB = True;
    
    i = 1;

    do {
      if(get("PlayerIndexes", i) == string(i)) {
       // Controller.control.nscLog(Controller.pluginName$": PlayerIndexes["$i$"] is"@PlayerIndexes[i]);
       
       if(InStr(get("PlayerAction", i), "Multi Entry for index ") == -1) continue;

       orgIndex = int(Mid(get("PlayerAction", i), 22));
        if(get("PlayerData", i) != "") {
          if(InvalidData[orgIndex] == "") {
            InvalidData[orgIndex] = get("PlayerData", i);
          } else if(InStr(InvalidData[orgIndex], get("PlayerData", i)) == -1) InvalidData[orgIndex] = InvalidData[orgIndex] $ Controller.separator $ get("PlayerData", i);
          set("PlayerData", i, "");
        }
        if(get("PlayerIps", i) != "") {
          if(InvalidIP[orgIndex] == "") {
            InvalidIP[orgIndex] = get("PlayerIps", i);
          } else if(InStr(InvalidIP[orgIndex], get("PlayerIps", i)) == -1) InvalidIP[orgIndex] = InvalidIP[orgIndex] $ Controller.separator $ get("PlayerIps", i);;
          set("PlayerIps", i, "");
        }
        if(get("PlayerHostnames", i) != "") {
          if(InvalidHostname[orgIndex] == "") {
            InvalidHostname[orgIndex] = get("PlayerHostnames", i);
          } else if(InStr(InvalidHostname[orgIndex], get("PlayerHostnames", i)) == -1) InvalidHostname[orgIndex] = InvalidHostname[orgIndex] $ Controller.separator $ get("PlayerHostnames", i);
          set("PlayerHostnames", i, "");
        }
        set("PlayerIndexes", i, "");
        set("PlayerAction", i, "");
        if(Controller.nextFreeEntry > i) Controller.nextFreeEntry = i;
      }
      i++;
    } until(i==getArrayCount());
    Controller.determineNextFreeEntry();
    Controller.control.nscLog(Controller.pluginName$": STAGE 1 finished.");
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Performs the DB repairing.
 *
 **************************************************************************************************/
function Tick(float Delta) {
  local int i, indexes[64];
  local int currentIterations, updatedEntries;
  local int position;
  local string Data[256];

  if(bRepairingDatabase) {
    while(currentIterations < IterationsPerStage && updatedEntries < UpdatesPerStage && lastEntry < getArrayCount()) {
      if(InvalidData[lastEntry] != "") {
        if(get("PlayerIndexes", lastEntry) != "") Controller.deCrunshData(get("PlayerIndexes", lastEntry), Data);
        indexes[0] = lastEntry;
        for(i=0;i<ArrayCount(indexes)-1;i++) {
          if(Data[i] == "") indexes[i+1] = -1;
          else indexes[i+1] = int(Data[i]);
        }
        while(Len(InvalidData[lastEntry]) > Controller.maxStrLen) {
          position = Controller.maxStrLen - 2;
          while(Mid(InvalidData[lastEntry], position, 1) != Controller.separator) position--;
          Controller.addName(indexes, Left(InvalidData[lastEntry], position));
          InvalidData[lastEntry] = Mid(InvalidData[lastEntry], position+1);
        }
        Controller.addName(indexes, InvalidData[lastEntry]);
        updatedEntries++;
      }
      if(InvalidIP[lastEntry] != "") {
        Controller.deCrunshData(get("PlayerIndexes", lastEntry), Data);
        indexes[0] = lastEntry;
        for(i=0;i<ArrayCount(indexes)-1;i++) {
          if(Data[i] == "") indexes[i+1] = -1;
          else indexes[i+1] = int(Data[i]);
        }
        while(Len(InvalidIp[lastEntry]) > Controller.maxStrLen) {
          position = Controller.maxStrLen - 2;
          while(Mid(InvalidIp[lastEntry], position, 1) != Controller.separator) position--;
          Controller.addIp(indexes, Left(InvalidIp[lastEntry], position));
          InvalidIp[lastEntry] = Mid(InvalidIp[lastEntry], position+1);
        }
        Controller.addIp(indexes, InvalidIp[lastEntry]);
        updatedEntries++;
      }
      if(InvalidHostname[lastEntry] != "") {
        Controller.deCrunshData(get("PlayerIndexes", lastEntry), Data);
        indexes[0] = lastEntry;
        for(i=0;i<ArrayCount(indexes)-1;i++) {
          if(Data[i] == "") indexes[i+1] = -1;
          else indexes[i+1] = int(Data[i]);
        }
        while(Len(InvalidHostname[lastEntry]) > Controller.maxStrLen) {
          position = Controller.maxStrLen - 2;
          while(Mid(InvalidHostname[lastEntry], position, 1) != Controller.separator) position--;
          Controller.addHostname(indexes, Left(InvalidHostname[lastEntry], position));
          InvalidHostname[lastEntry] = Mid(InvalidHostname[lastEntry], position+1);
        }
        Controller.addHostname(indexes, InvalidHostname[lastEntry]);
        updatedEntries++;
      }
      lastEntry++;
      currentIterations++;
    }
    
    if(currentIterations == 0 && lastEntry==getArrayCount()) {
      setLIV(Controller.versionNum);
      saveConfig();
	    bRepairingDatabase = False;
	    Controller.bRepairingDB = False;
	    Controller.control.nscLog(Controller.pluginName$": STAGE 2 finished. Invalid Database repaired - Version 2.02 successfully installed.");
    }
  }
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the overall database array count.
 *  $RETURN       The array size of the database.
 *
 **************************************************************************************************/
function int getArrayCount() {
  return ArrayCount(PlayerAction);
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the lastInstalledVersion value.
 *  $RETURN       The lastInstalledVersion of the plugin.
 *
 **************************************************************************************************/
function int getLIV() {
  return lastInstalledVersion;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Adjusts the version number of the plugin.
 *  $PARAM        value  The new version number.
 *
 **************************************************************************************************/
function setLIV(int value) {
  lastInstalledVersion = value;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the value of an entry in the database.
 *  $PARAM        Varname  The identifier of the variable.
 *  $PARAM        index    The array index of the entry.
 *  $RETURN       The value of the specified database entry.
 *
 **************************************************************************************************/
function string get(string Varname, int index) {
  switch(varName) {
    case "PlayerData":      return PlayerData[index];      break;
    case "PlayerIps":       return PlayerIps[index];       break;
    case "PlayerHostnames": return PlayerHostnames[index]; break;
    case "PlayerAction":    return PlayerAction[index];    break;
    case "PlayerIndexes":   return PlayerIndexes[index];   break;
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Changes the value of a specifiec entry in the database.
 *  $PARAM        Varname  The specifier of the variable.
 *  $PARAM        index    The array index of the entry.
 *  $PARAM        value    The new value.
 *
 **************************************************************************************************/
function set(string Varname, int index, string value) {
  switch(varName) {
    case "PlayerData":      PlayerData[index]      = value;      break;
    case "PlayerIps":       PlayerIps[index]       = value;      break;
    case "PlayerHostnames": PlayerHostnames[index] = value;      break;
    case "PlayerAction":    PlayerAction[index]    = value;      break;
    case "PlayerIndexes":   PlayerIndexes[index]   = value;      break;
  }
}


defaultproperties
{
}