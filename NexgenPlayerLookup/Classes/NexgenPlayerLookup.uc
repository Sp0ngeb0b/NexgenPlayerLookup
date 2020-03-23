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
/*##################################################################################################
##  Changelog:
##
##  Version 2.02:
##  [Added]:     - DB repairing algorithm in NexgenPlayerLookupDatabase.uc.
##  [Fix]:       - DB getting corrupted due to bad implementation of the PlayerIndexes.
##  [Fix]:       - Search by ID not working.
##  [Fix]:       - Not all search results were transfered.
##  [Fix]:       - Hostnames not being saved.
##  [Changed]:   - Internal string variables no longer require splitting, since the max String length
##                 only applies for config strings.
##
##  Version 2.01:
##  [Fix]:       - Login timeouts. Explanation: I made several attempts to find the reason why
##                 clients are timing out. I changed the plugin so that the admin client is only
##                 spawned when the client passed the initial login. But that didn't fix the issue.
##                 I noticed that the amount of timeouts is dependent of the total config array size.
##                 So I got the idea that - for whatever reasons - the clients are timing out because
##                 they do *something* with the large arrays when joining. I have absolutely no idea
##                 what they are doing with it, since it's only spawned and relevant server side.
##                 Anyways, putting the config data in a seperate, server side only package fixed
##                 the timeouts.
##
##  Version 2.00:
##  [Changes]:   - Database has been restructured. Player identifier (Nexgen ID) is now saved inside
##                 the first PlayerAction of the belonging client. PlayerIndexes array has been
##                 added, containing all belonging indexes of one client in the client's first entry.
##               - Database changes are only made on gameend from now on. All joined players and their
##                 data are saved inside the JoinedPlayer structure first. This drastically reduces
##                 impact on serverperfomance on player joins.
##               - Data transfer between server -> client has been completely overworked. Implemented
##                 Nexgen112's ExtendedNetClientController to provide fast and reliable data transfers
##                 with guaranteed no packageloss.
##               - Database searches are now performed serverside and only the results are being sent
##                 to the client. This abolishes the need to request the complete data.
##               - The complete control panel has been revised.
##               - Total amount of entries has been increased to 25.000
##
##  [Fixes]:     - Drastically reduction of serverperfomance on player joins. Fixes the 'join-lag'
##                 and possible timeouts.
##               - Data getting lost during sending to admins.
##               - Huge lag spikes when performing searches.
##
##  [Added]:     - Ability to directly perform complete database searches within a few seconds.
##               - Player's Hardware ID and MAC Hash can now also be recognized by the plugin.
##                 This requires the server to run ACE + NexgenABM.
##               - Admin can now also search by Hardware ID and MAC Hash.
##               - The complete lookup of a player can now be saved clientside to a txt file.
##
##################################################################################################*/
class NexgenPlayerLookup extends NexgenPlugin;

var NexgenPlayerLookupConfig conf;               // Plugin configuration dummy.
var Actor ipToCountry;                           // IpToCountry Actor (if available)

var int versionNum;                              // Plugin version number.
var int nextFreeEntry;                           // Next free entry in the database

var bool bRepairingDB;                           // Used to block saving config while repairing DB


// Structure for joined players
struct JoinedPlayers {
	var string ID;
	var string HWID;
	var string MAC;
	var string Names;
	var string IPs;
	var string Hostnames;
	var int warnings;
	var int mutes;
  var int kicks;
  var int bans;
};
var JoinedPlayers JP[64];

var bool tempDataSaved;                          // Has notifyBeforeLevelChange() already been called?

const maxStrLen = 1023;                          // Max string length supported by UT
const separator = "#";                           // Global separator used in the database
const HostnameTimeout = 30;                      // Max seconds waiting to receive a client's hostname
const ActionDataCount = 6;                       // Number of indivual elements in the PlayerAction string


/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes the plugin. Note that if this function returns false the plugin will
 *                be destroyed and is not to be used anywhere.
 *  $RETURN       True if the initialization succeeded, false if it failed.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool initialize() {
  local Actor A;
  
  // Search for config actor
  foreach AllActors(Class'NexgenPlayerLookupConfig', conf) {
    break;
  }
  
  // Give out debugging log if configuered incorrectly
  if(conf == none) {
    control.nscLog(pluginName$": FATAL ERROR: DataBase Actor not found!");
    control.nscLog(pluginName$": Make sure 'ServerActors=NexgenPlayerLookupDataBase.NexgenPlayerLookupDataBase' is loaded BEFORE 'ServerActors=NexgenPlayerLookup"$versionNum$".NexgenPlayerLookup' ! ! ! !");
    control.nscLog(pluginName$": Also check that you are using the right version of the DataBase actor.");
    return false;
  }
  
  // Install new version if neccessary
	if(conf.getLIV() < versionNum) install();

	// Find next free database entry
	determineNextFreeEntry();
	
	// Locate IpToCountry
	foreach AllActors(class'Actor', A, 'IpToCountry') {
    ipToCountry = A;
    break;
	}

	// Add new right type
  control.sConf.addRightDefiniton("playerlookup", "Perform player lookups.");

	return true;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Installs the plugin.
 *
 **************************************************************************************************/
function install() {

  if(conf.getLIV() < 200) {
    install200();
    conf.setLIV(versionNum);
	  conf.saveConfig();
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Installs version 2.00.
 *
 **************************************************************************************************/
function install200() {
  local int i, firstEntry;

  // Perform database adjustments.
  for(i=0;i<conf.getArrayCount();i++) {
    if(conf.get("PlayerData", i) == "") break;
    firstEntry = getFirstEntry(i);

    if(firstEntry != i) {
      if(conf.get("PlayerIndexes", firstEntry) == "") conf.set("PlayerIndexes", firstEntry, string(i));
      else conf.set("PlayerIndexes", firstEntry, conf.get("PlayerIndexes", firstEntry) $ separator $ i);
    } else {
      conf.set("PlayerAction", firstEntry, Left(conf.get("PlayerData", firstEntry), 32) $ separator $ separator $ separator $ conf.get("PlayerAction", firstEntry));
    }
    conf.set("PlayerData", i, Mid(conf.get("PlayerData", i), 33));
  }

  // Log Changes
  control.nscLog(pluginName$": Version "$pluginVersion$" successfully installed.");
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes the nextFreeEntry variable.
 *
 **************************************************************************************************/
function determineNextFreeEntry() {
  local int i;

  for(i=0;i<conf.getArrayCount();i++) {
    if(conf.get("PlayerAction", i) == "") break;
  }
  nextFreeEntry = i;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a new client has been created. Use this function to setup the new
 *                client with your own extensions (in order to support the plugin).
 *  $PARAM        client  The client that was just created.
 *  $REQUIRE      client != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function clientCreated(NexgenClient client) {
	local NexgenPlayerLookupClient xClient;
	
	xClient = NexgenPlayerLookupClient(client.addController(class'NexgenPlayerLookupClient', self));

}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called whenever a player has joined the game (after its login has been accepted).
 *  $PARAM        client  The player that has joined the game.
 *  $REQUIRE      client != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function playerJoined(NexgenClient client) {
  local int i;
  local string Names[256], IPs[256];
  local NexgenPlayerLookupClient xClient;
  local NexgenPlayerLookupAdminClient adminClient;

  // Spawn admin client controller
  if(client.hasRight("playerlookup")) {
    adminClient = NexgenPlayerLookupAdminClient(client.addController(class'NexgenPlayerLookupAdminClient', self));
    if(adminClient != none) adminClient.Conf = conf;
  }
  
  // Enable hostname detection
  if(ipToCountry != none) {
    xClient = NexgenPlayerLookupClient(client.getController(class'NexgenPlayerLookupClient'.default.ctrlID));
    if(xClient != none) xClient.SetTimer(1.0, true);
  }
  
  for(i=0;i<ArrayCount(JP);i++) {
    if(JP[i].ID == "") break;

    // Update info
    if(JP[i].ID == client.playerID) {
      if(deCrunshData(JP[i].Names, Names) && !checkArrayForData(Names, client.playerName, false)) {
        JP[i].Names = JP[i].Names$separator$client.playerName;
      }
      if(deCrunshData(JP[i].IPs, IPs) && !checkArrayForData(IPs, client.ipAddress, false)) {
        JP[i].IPs = JP[i].IPs$separator$client.ipAddress;
      }
      return;
    }
  }
  
  if(i == ArrayCount(JP)) return;
  
  // Create new entry
  JP[i].ID    = client.playerID;
  JP[i].Names = client.playerName;
  JP[i].IPs   = client.ipAddress;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called by an instance of the HostnameDetector when the hostname has been found.
 *  $PARAM        client  The player whose hostname has been detected.
 *  $PARAM        Hostname The specific hostname.
 *
 **************************************************************************************************/
function reveiceHostname(NexgenClient client, string Hostname) {
  local string Hostnames[256];
  local int JoinedPlayers;

  // Pre checks
  if(client == none || Hostname == "") return;


  for(JoinedPlayers=0; JoinedPlayers<ArrayCount(JP); JoinedPlayers++) {
    if(JP[JoinedPlayers].ID == "") return;

    if(JP[JoinedPlayers].ID == client.playerID) {

      // Check whether hostname is in String
      if(deCrunshData(JP[JoinedPlayers].Hostnames, Hostnames)) {
        if(!checkArrayForData(Hostnames, hostname, false)) {
          JP[JoinedPlayers].Hostnames = JP[JoinedPlayers].Hostnames$separator$Hostname;
        }
      } else JP[JoinedPlayers].Hostnames = Hostname;
      return;
    }
  }
  
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Adds a name to the database.
 *  $PARAM        indexes[64]  Database entries of the player.
 *  $PARAM        client The NexgenClient of the player.
 *
 **************************************************************************************************/
function addName(int indexes[64], string Name) {
  local int i, index, nextFreeEntry;
  local bool bNameAdded;
  
  for(i = 0; i<ArrayCount(indexes); i++) {

    if(indexes[i] == -1) break;  // No more entries in database
    index = indexes[i];

    // Check length
    if(Len(conf.get("PlayerData", index)) + Len(separator) + Len(Name) <= maxStrLen) {

      // Name can be added
      conf.set("PlayerData", index, conf.get("PlayerData", index)$separator$Name);
      
      bNameAdded = true;
      break;
    }
  }
  
  if(!bNameAdded) {

    // String would be to long, we have to add a new entry
    nextFreeEntry = getNextFreeEntry();
    
    if(nextFreeEntry == -1) return;

    conf.set("PlayerData", nextFreeEntry, Name);
    conf.set("PlayerAction", nextFreeEntry, "Multi Entry for index"@indexes[0]);
    if(conf.get("PlayerIndexes", indexes[0]) == "") conf.set("PlayerIndexes", indexes[0], string(nextFreeEntry));
    else conf.set("PlayerIndexes", indexes[0], conf.get("PlayerIndexes", indexes[0])$separator$nextFreeEntry);

  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Adds an IP to the database.
 *  $PARAM        indexes[64]  Database entries of the player.
 *  $PARAM        client The NexgenClient of the player.
 *
 **************************************************************************************************/
function addIp(int indexes[64], string IP) {
  local int i, index, nextFreeEntry;
  local bool bIpAdded;

  for(i = 0; i<ArrayCount(indexes); i++) {
  
    if(indexes[i] == -1) break;  // No more entries in database
    index = indexes[i];
  
    // Check length
    if(Len(conf.get("PlayerIps", index)) + Len(separator) + Len(IP) <= maxStrLen) {
  
      // Ip can be added
      if(conf.get("PlayerIps", index) == "") conf.set("PlayerIps", index, IP);
      else conf.set("PlayerIps", index, conf.get("PlayerIps", index)$separator$IP);
      
      bIpAdded = True;
      break;
    }
  }

  if(!bIpAdded) {
  
    // String would be to long, we have to add a new entry
    nextFreeEntry = getNextFreeEntry();
    
    if(nextFreeEntry == -1) return;
    
    conf.set("PlayerIps", nextFreeEntry, IP);
    conf.set("PlayerAction", nextFreeEntry, "Multi Entry for index"@indexes[0]);
    if(conf.get("PlayerIndexes", indexes[0]) == "") conf.set("PlayerIndexes", indexes[0], string(nextFreeEntry));
    else conf.set("PlayerIndexes", indexes[0], conf.get("PlayerIndexes", indexes[0])$separator$nextFreeEntry);
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Adds an hostname to the database.
 *  $PARAM        indexes[64]  Database entries of the player.
 *  $PARAM        client The NexgenClient of the player.
 *  $PARAM        hostname The hostname which has to be added.
 *
 **************************************************************************************************/
function addHostname(int indexes[64], string Hostname) {
  local int i, index, nextFreeEntry;
  local bool bHostnameAdded;

  for(i = 0; i<ArrayCount(indexes); i++) {

    if(indexes[i] == -1) break;  // No more entries in database
    index = indexes[i];

    // Check length
    if(Len(conf.get("PlayerHostnames", index)) + Len(separator) + Len(Hostname) <= maxStrLen) {

      // Hostname can be added
      if(conf.get("PlayerHostnames", index) == "") conf.set("PlayerHostnames", index, hostname);
      else conf.set("PlayerHostnames", index, conf.get("PlayerHostnames", index)$separator$hostname);

      bHostnameAdded = True;
      break;
    }
  }

  if(!bHostnameAdded) {

    // String would be to long, we have to add a new entry
    nextFreeEntry = getNextFreeEntry();

    if(nextFreeEntry == -1) return;
    conf.set("PlayerAction", nextFreeEntry, "Multi Entry for index"@indexes[0]);
    conf.set("PlayerHostnames", nextFreeEntry, hostname);
    if(conf.get("PlayerIndexes", indexes[0]) == "") conf.set("PlayerIndexes", indexes[0], string(nextFreeEntry));
    else conf.set("PlayerIndexes", indexes[0], conf.get("PlayerIndexes", indexes[0])$separator$nextFreeEntry);
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a general event has occurred in the system.
 *  $PARAM        type      The type of event that has occurred.
 *  $PARAM        argument  Optional arguments providing details about the event.
 *
 **************************************************************************************************/
function notifyEvent(string type, optional string arguments) {
  local NexgenClient Sender, Receiver;
  local int JoinedPlayers;

  // ACE info available?
  if(type == "ace_login") {
    Sender = control.getClientByNum(int(class'NexgenUtil'.static.getProperty(arguments, "client")));

    for(JoinedPlayers=0; JoinedPlayers<ArrayCount(JP); JoinedPlayers++) {
      if(JP[JoinedPlayers].ID == Sender.playerID) {
        JP[JoinedPlayers].HWID = class'NexgenUtil'.static.getProperty(arguments, "HWid");
        JP[JoinedPlayers].MAC  = class'NexgenUtil'.static.getProperty(arguments, "MAC");
        return;
      } else if(JP[JoinedPlayers].ID == "") return;
    }
    return;
  }


  // Update additonal info.
  if(type != "player_warned" && type != "player_muted" && type != "player_kicked" && type != "player_banned") return;

	Sender = control.getClientByNum(int(class'NexgenUtil'.static.getProperty(arguments, "client")));
	Receiver = control.getClientByNum(int(class'NexgenUtil'.static.getProperty(arguments, "target")));

	if(Sender == Receiver) return; // user performed action on himself, we don't care about it

	
	for(JoinedPlayers=0; JoinedPlayers<ArrayCount(JP); JoinedPlayers++) {
    if(JP[JoinedPlayers].ID == "") return;
    
    if(JP[JoinedPlayers].ID == Receiver.playerID) break;
  }
  
  if(JoinedPlayers == ArrayCount(JP)) return;

  if(type == "player_warned") {
    JP[JoinedPlayers].warnings++;
  }
  else if(type == "player_muted" && bool(class'NexgenUtil'.static.getProperty(arguments, "muted"))) {
    JP[JoinedPlayers].mutes++;
  }
  else if(type == "player_kicked") {
    JP[JoinedPlayers].kicks++;
	}
  else if(type == "player_banned") {
    JP[JoinedPlayers].bans++;
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Deals with a client that has changed his/her name during the game.
 *  $PARAM        client  The client that has changed his/her name.
 *  $REQUIRE      client.playerName != client.player.playerReplicationInfo.playerName
 *
 **************************************************************************************************/
function playerNameChanged(NexgenClient client, string oldName, bool bWasForcedChanged) {
  local string Names[256];
  local int JoinedPlayers;

  for(JoinedPlayers=0; JoinedPlayers<ArrayCount(JP); JoinedPlayers++) {
    if(JP[JoinedPlayers].ID == "") return;

    if(JP[JoinedPlayers].ID == client.playerID) {
    
      // Check whether name is in String
      if(deCrunshData(JP[JoinedPlayers].Names, Names)) {
        if(!checkArrayForData(Names, client.playerName, false)) {
          JP[JoinedPlayers].Names = JP[JoinedPlayers].Names$separator$client.playerName;
        }
      }
      return;
    }
  }
}



/***************************************************************************************************
 *
 *  $DESCRIPTION  Retrieves the index of an entry in the database with the specified ID
 *  $PARAM        ID ID to be searched for.
 *  $PARAM        Out array Indexes -> Returns all indexes of the ID in the database (0=first, 31=last)
 *  $RETURN       The first index (-1 if ID is not in database)
 *
 **************************************************************************************************/
function int getEntryByID(string ID, optional out int indexes[64]) {
  local int i;
  local string Data[256];

  for(i=0;i<conf.getArrayCount();i++) {
    if(static.getID(conf.get("PlayerAction", i)) == ID) {
      deCrunshData(conf.get("PlayerIndexes", i), Data);
      indexes[0] = i;
  
      // Initialize vars
      for(i=0;i<ArrayCount(indexes)-1;i++) {
        if(Data[i] == "") indexes[i+1] = -1;
        else indexes[i+1] = int(Data[i]);
      }
      return indexes[0];
    }
  }
  
  return -1;

}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Retrieves the first index of a database entry.
 *  $PARAM        i  One index of the entries
 *  $RETURN       The first index belonging to this entry.
 *
 **************************************************************************************************/
function int getFirstEntry(int i) {
  if(Left(conf.get("PlayerAction", i), Len("Multi Entry for index ")) == "Multi Entry for index ") {
    return int(Mid(conf.get("PlayerAction", i), Len("Multi Entry for index ")));
  } else return i;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Retrieves the index of the next free entry in the database and automatically moves
 *                one index further.
 *  $RETURN       The index (-1 if it's full)
 *
 **************************************************************************************************/
function int getNextFreeEntry() {
  local int i, oldNextFreeEntry;
  
  if(nextFreeEntry == conf.getArrayCount()) return -1;

  oldNextFreeEntry = nextFreeEntry;
  
  for(i=nextFreeEntry;i<conf.getArrayCount();i++) {
    if(conf.get("PlayerAction", i) == "") break;
  }
  nextFreeEntry = i;
  
  return oldNextFreeEntry;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the server is about to perform a server travel. Note that the server
 *                travel may fail to switch to the desired map. In that case the server will
 *                continue running the current game or a second notifyBeforeLevelChange() call may
 *                occur when trying to switch to another map. So be carefull what you do in this
 *                function!!!
 *
 **************************************************************************************************/
function notifyBeforeLevelChange() {
  local int indexes[64];
  local int firstEntry, i, index, JoinedPlayers, j;
  local string Data[256], Names[256], IPs[256], Hostnames[256];
  local bool bNameFound, bIpFound, bHostnameFound;
  local int warns, mutes, kicks, bans, visits;
  local string lastDate, hardwareID, MACHash;
  local int year, month, day, hour, minute;

  // Return if we already received a notifyBeforeLevelChange() call
  if(tempDataSaved || bRepairingDB) return;
  tempDataSaved = true;

  // Update database
  for(JoinedPlayers=0; JoinedPlayers<ArrayCount(JP); JoinedPlayers++) {
  
    if(JP[JoinedPlayers].ID == "") break;
  
    // Search for entry
    firstEntry = getEntryByID(JP[JoinedPlayers].ID, indexes);

    if(firstEntry != -1) {
    
      // Loop which checks whether each name of the current player is in the database and if not adds it
      if(deCrunshData(JP[JoinedPlayers].names, Names)) {
        for(j=0;j<ArrayCount(Names);j++) {
          if(Names[j] == "") break;
          for(index = 0; index<ArrayCount(indexes); index++) {

            if(indexes[index] == -1) break;  // No more entries in database

            i = indexes[index];

            // Check whether current name is in String
            if(deCrunshData(conf.get("PlayerData", i), Data)) {
              if(checkArrayForData(Data, Names[j], false)) {
                bNameFound = true;
                break;
              }
            }
          }
          if(!bNameFound) {
            addName(indexes, Names[j]);
            firstEntry = getEntryByID(JP[JoinedPlayers].ID, indexes);  // Update Indexes (In case new entry has been created)
          }
          clearArray(Data);
          bNameFound = false;
        }
      }
      
      clearArray(Names);    // Fix attempt
      clearArray(Data);
      
      // Loop which checks whether each IP of the current player is in the database and if not adds it
      if(deCrunshData(JP[JoinedPlayers].IPs, IPs)) {
        for(j=0;j<ArrayCount(IPs);j++) {
          if(IPs[j] == "") break;
          for(index = 0; index<ArrayCount(indexes); index++) {

            if(indexes[index] == -1) break;  // No more entries in database

            i = indexes[index];

            // Check whether current name is in String
            if(deCrunshData(conf.get("PlayerIPs", i), Data)) {
              if(checkArrayForData(Data, IPs[j], false)) {
                bIpFound = true;
                break;
              }
            }
          }
          if(!bIpFound) {
            addIp(indexes, IPs[j]);
            firstEntry = getEntryByID(JP[JoinedPlayers].ID, indexes);  // Update Indexes (In case new entry has been created)
          }
          clearArray(Data);
          bIpFound = false;
        }
      }
      
      clearArray(IPs);    // Fix attempt
      clearArray(Data);
      
      // Loop which checks whether each Hostname of the current player is in the database and if not adds it
      if(deCrunshData(JP[JoinedPlayers].Hostnames, Hostnames)) {
        for(j=0;j<ArrayCount(Hostnames);j++) {
          if(Hostnames[j] == "") break;
          for(index = 0; index<ArrayCount(indexes); index++) {

            if(indexes[index] == -1) break;  // No more entries in database

            i = indexes[index];

            // Check whether current name is in String
            if(deCrunshData(conf.get("PlayerHostnames", i), Data)) {
              if(checkArrayForData(Data, Hostnames[j], false)) {
                bHostnameFound = true;
                break;
              }
            }
          }
          if(!bHostnameFound) {
            addHostname(indexes, Hostnames[j]);
            firstEntry = getEntryByID(JP[JoinedPlayers].ID, indexes);  // Update Indexes (In case new entry has been created)
          }
          clearArray(Data);
          bHostnameFound = false;
        }
      }
      
      clearArray(Hostnames);    // Fix attempt
      clearArray(Data);

      // Update Additional info
      if(deCrunshActions(conf.get("PlayerAction", firstEntry), warns, mutes, kicks, bans, visits, lastDate)) {
        if(static.getHWID(conf.get("PlayerAction", firstEntry)) != "") hardwareID = static.getHWID(conf.get("PlayerAction", firstEntry));
        else hardwareID = JP[JoinedPlayers].HWID;
        if(static.getMAC(conf.get("PlayerAction", firstEntry)) != "") MACHash = static.getMAC(conf.get("PlayerAction", firstEntry));
        else MACHash = JP[JoinedPlayers].MAC;

        conf.set("PlayerAction", firstEntry, crunshActions(static.getID(conf.get("PlayerAction", firstEntry)), hardwareID, MACHash, warns + JP[JoinedPlayers].warnings, mutes + JP[JoinedPlayers].mutes,
                                                      kicks + JP[JoinedPlayers].kicks, bans + JP[JoinedPlayers].bans, visits+1, getDate()));
      }
    }
    
    else {

      i = getNextFreeEntry();

      if(i != -1) {
        conf.set("PlayerData", i, JP[JoinedPlayers].names);
        conf.set("PlayerIps", i, JP[JoinedPlayers].IPs);
        conf.set("PlayerAction", i, crunshActions(JP[JoinedPlayers].ID, JP[JoinedPlayers].HWID, JP[JoinedPlayers].MAC, JP[JoinedPlayers].warnings, JP[JoinedPlayers].mutes,
                                              JP[JoinedPlayers].kicks, JP[JoinedPlayers].bans,
                                              1, getDate()));
      }
    }
  }
  conf.SaveConfig();
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the current Date in a specifc form so it can be saved
 *
 **************************************************************************************************/
function string getDate() {
  local int year, month, day, hour, minute;

	year = level.year;
	month = level.month;
	day = level.day;
	hour = level.hour;
	minute = level.minute;

  return class'NexgenUtil'.static.serializeDate(year, month, day, hour, minute);
}


/***************************************************************************************************
 *
 *  Below are some static functions which are used to crunsh/decrunsh our data strings
 *
 **************************************************************************************************/
/***************************************************************************************************
 *
 *  $DESCRIPTION  Decrunshes a specifc string and gives out the substrings in an array
 *  $PARAM        data The original data string.
 *  $PARAM        type Specifies what kind of string we have (0=PlayerNames, 1=IPs, 2=Hostnames)
 *  $PARAM        Out array -> Contains all splitted substrings
 *  $RETURN       Whether the decrunsh was successfull
 *
 **************************************************************************************************/
static function bool deCrunshData(string data, out string array[256]) {
  local int nextFreeSlot, j;
  local string temp;
  
  ClearArray(array);       // Fix attempt

  temp = data;
  if(temp == "") return false;

  nextFreeSlot = 0;

  // Split data
  do {

    j = InStr(temp, separator);
    if(j==-1) array[nextFreeSlot] = temp;
    else {
      array[nextFreeSlot] = left(temp, j);
      temp = mid(temp, j+1);
    }

    nextFreeSlot++;

  } until(j==-1 || nextFreeSlot == ArrayCount(array));

  return true;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks whether a given string contains the searched expression
 *  $PARAM        array[256] Splitted substrings.
 *  $PARAM        data The expression we are searching for.
 *  $PARAM        contains (optional)
 *  $PARAM        entry (optional, out)
 *  $RETURN       True if one of the substrings is equal to the expression, False if not.
 *
 **************************************************************************************************/
static function bool checkArrayForData(string array[256], string data, bool contains, optional out int entry) {
  local int i;

  for(i=0;i<ArrayCount(array);i++) {
    if(array[i] == "") return false;
    
    if(!contains && array[i] == data) {
      entry = i;
      return true;
    } else if(contains && InStr(CAPS(array[i]), CAPS(data)) != -1) {
      entry = i;
      return true;
    }
  }

  return false;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns an empty string array.
 *  $PARAM        out clearedArray[256] The cleaned array.
 *
 **************************************************************************************************/
static function clearArray(out string clearedArray[256]) {
  local int i;

  for(i=0;i<ArrayCount(clearedArray);i++) {
    clearedArray[i] = "";
  }
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the ID (first 32 characters of the String)
 *  $RETURN       The ID
 *
 **************************************************************************************************/
static function string getID(string data) {
  local string ID;
  
  ID = left(data, InStr(data, separator));
  if(Len(ID) != 32) ID = Left(data, 32);
  return ID;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the Hardware ID
 *  $RETURN       The Hardware ID
 *
 **************************************************************************************************/
static function string getHWID(string data) {
  local string ID;
  
  ID = Mid(data, InStr(data, separator) + Len(separator));
  if(InStr(ID, separator) != -1) ID = left(ID, InStr(ID, separator));
  return ID;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the MAC Hash
 *  $RETURN       The MAC hash.
 *
 **************************************************************************************************/
static function string getMAC(string data) {
  local string ID;

  ID = Mid(data, InStr(data, separator) + Len(separator));
  ID = Mid(ID, InStr(ID, separator) + Len(separator));
  ID = left(ID, InStr(ID, separator));

  return ID;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Decrunshes the action string and gives back the interpretated data.
 *  $PARAM        data          The original string.
 *  $PARAM        out warning   Number of warnings for this entry.
 *  $PARAM        out mutes     Number of mutes for this entry.
 *  $PARAM        out kicks     Number of kicks for this entry.
 *  $PARAM        out bans      Number of bans for this entry.
 *  $PARAM        out visits    Visits count for this entry.
 *  $PARAM        out lastDate  Last saved time the player belonging to the entry was on the server.
 *  $RETURN       True if the decrunshing was successfull, false of not;
 *
 **************************************************************************************************/
static function bool deCrunshActions(string data, out int warnings, out int mutes, out int kicks,
                                     out int bans, out int visits, out string lastDate) {
  local int i;
  local string subString;
  local string currString;

  if(data == "") return false;

  subString = data;

  for(i=0;i<3;i++) {
    subString = Mid(subString, InStr(subString, separator) + Len(separator));
  }


  for(i=0;i<ActionDataCount;i++) {
    // Split next data
    if(InStr(subString, separator) != -1) {
      currString = Left(subString, InStr(subString, separator));

      switch(i) {
        case 0: warnings = int(currString);
        break;
        case 1: mutes = int(currString);
        break;
        case 2: kicks = int(currString);
        break;
        case 3: bans = int(currString);
        break;
        case 4: visits = int(currString);
        break;
      }
      subString = mid(subString, InStr(subString, separator)+Len(separator));
    } else {
      lastDate = subString;
      break;
    }
  }
  return true;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Crunshes additional information for an entry to one string.
 *  $PARAM        NexgenID  Nexgen ID of the specific client.
 *  $PARAM        HWID      Hardware ID of the specific client.
 *  $PARAM        MAC       MAC Hash of the specific client.
 *  $PARAM        warning   Number of warnings for this entry.
 *  $PARAM        mutes     Number of mutes for this entry.
 *  $PARAM        kicks     Number of kicks for this entry.
 *  $PARAM        bans      Number of bans for this entry.
 *  $PARAM        visits    Visits count for this entry.
 *  $PARAM        lastDate  Last saved time the player belonging to the entry was on the server.
 *  $RETURN       The crunshed string.
 *
 **************************************************************************************************/
static function string crunshActions(string NexgenID, string HWID, string MAC, int warning, int mutes, int kicks,
                                     int bans, int visits, string lastDate) {

  return NexgenID$separator$HWID$separator$MAC$separator$warning$separator$mutes$separator$kicks$separator$bans$separator$visits$separator$lastDate;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Corrected version of the static formatCmdArg function in NexgenUtil. Empty strings
 *                are formated correctly now (original source of all trouble).
 *
 **************************************************************************************************/
static function string formatCmdArgFixed(coerce string arg) {
	local string result;

	result = arg;

	// Escape argument if necessary.
	if (result == "") {
		result = "\"\"";                      // Fix (originally, arg was assigned instead of result -_-)
	} else {
		result = class'NexgenUtil'.static.replace(result, "\\", "\\\\");
		result = class'NexgenUtil'.static.replace(result, "\"", "\\\"");
		result = class'NexgenUtil'.static.replace(result, chr(0x09), "\\t");
		result = class'NexgenUtil'.static.replace(result, chr(0x0A), "\\n");
		result = class'NexgenUtil'.static.replace(result, chr(0x0D), "\\r");

		if (instr(arg, " ") > 0) {
			result = "\"" $ result $ "\"";
		}
	}

	// Return result.
	return result;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
     versionNum=202
     pluginName="Nexgen Player Lookup System"
     pluginAuthor="Sp0ngeb0b"
     pluginVersion="2.02"
}
