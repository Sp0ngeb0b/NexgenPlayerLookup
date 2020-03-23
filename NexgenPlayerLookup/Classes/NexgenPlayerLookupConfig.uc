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
class NexgenPlayerLookupConfig extends Info config(NexgenPlayerLookup);



/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the overall database array count. Must be implemented in subclass.
 *  $RETURN       The array size of the database.
 *
 **************************************************************************************************/
function int getArrayCount() {
  return 0;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the lastInstalledVersion value. Should be implemented in subclass.
 *  $RETURN       The lastInstalledVersion of the plugin.
 *
 **************************************************************************************************/
function int getLIV() {
  return 0;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Adjusts the version number of the plugin. Should be implemented in subclass.
 *  $PARAM        value  The new version number.
 *
 **************************************************************************************************/
function setLIV(int value) {
  // to implement in subclass
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Returns the value of an entry in the database. Must be implemented in subclass.
 *  $PARAM        Varname  The identifier of the variable.
 *  $PARAM        index    The array index of the entry.
 *  $RETURN       The value of the specified database entry.
 *
 **************************************************************************************************/
function string get(string Varname, int index) {
  // to implement in subclass
  return "";
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Changes the value of a specifiec entry in the database.
 *                Must be implemented in subclass.
 *  $PARAM        Varname  The specifier of the variable.
 *  $PARAM        index    The array index of the entry.
 *  $PARAM        value    The new value.
 *
 **************************************************************************************************/
function set(string Varname, int index, string value) {
  // to implement in subclass
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
}