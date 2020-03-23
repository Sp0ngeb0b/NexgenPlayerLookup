####################################################################################################
##
##  Nexgen Player Lookup System
##  [NexgenPlayerLookup202 - For Nexgen 112]
##
##  Version: 2.02
##  Release Date: June 2014
##  Author: Patrick "Sp0ngeb0b" Peltzer
##  Contact: spongebobut@yahoo.com  -  www.unrealriders.de
##
####################################################################################################
##   Table of Content
##
##   1. What's new in version 2.00?
##   2. About
##   3. Requirements
##   4. Server Install
##   5. Upgrading from a previous version
##   6. Credits and thanks
##   7. Info for programmers
##   8. FAQs
##   9. Changelog
##
####################################################################################################

####################################################################################################
##
##  1. What's new in version 2.00?
##
####################################################################################################
Better. Faster. Smoother. Bugfree.

Nexgen Player Lookup is back! The concept of a complete lookup database for an UnrealTournament game-
server is a must have for every server admin. But unfortunately, my original work in version 1.00
was more or less buggy and limited. I couldn't accept the fact that this brilliant idea might get
forgotten completely due to unclever development, so I got up and completely rebuild the system on
base of my advanced knowledge in programming and developing for UT and put version 2.00 out of the
ground. It adresses all of the things that disturbed me on version 1.00 and offers a reliable system
with a lot new features! Short facts:

- Restructured Database faster access and operation + 25.000 possible entries
- New system on updating the database which completely ereases the impact on playerjoins and prevents
  possible timeouts
- Complete admin access to database searches at any time in a few seconds
- 100% fast and reliable data transfer to the admin
- No outlagging during data transfer
- Hardware IDs and MAC Hashes can now be recorded aswell
- Completely overworked admin panel

Version 2.01 fixes the timeouts for good. Please note the new install/updating process.

Version 2.02 brings some important fixes for several bugs included in the former versions. Importantly,
a huge mistake which corrupts the entire Database has been repaired, aswell as coming with an auto-
matic database repair method.

Read more in the detailed changelog below.


####################################################################################################
##
##  2. About
##
####################################################################################################
Nexgen Player Lookup is a plugin for the NexgenServerController which offers a worked out
database system for UnrealTournament. It will keep track of every single player who ever connected to
your server and stores all important data:

- Player Names
- Player IPs
- Player Hostnames
- Player Hardware ID
- Player MAC Hash
- Actions against this player (amount of warnings/mutes/kicks/bans)
- Number of visits on your server
- Last visit timestamp

For identifying, NexgenPlayerLookup uses the unique Nexgen ID of every player.

... but wait, this is not all:

The main advantage of NexgenPlayerLookup is that it doesn't require any additional resources (like
a web database), ofcourse except Nexgen. You can run this directly and only on your server!
The database is able to store a maximum of 25.000 entries. Besides this, the plugin comes with a
powerful in-game tab located in the NexgenServerController. You can give your admins the right to
use this tab, which will give them access to do lookups for online players, and also includes the
ability to perform complete database searches for a specific Nexgen ID, Player Name, Player IP,
Player Hostname, Hardware ID and MAC Hash!


####################################################################################################
##
##  3. Requirements
##
####################################################################################################
Requires:
Nexgen 1.12

Optional:
IpToCountry (enables Hostname detecting)
NexgenWarn (allows keeping track of warnings of each player)
NexgenABM (enables to store each player's Hardware ID and MAC Hash)


####################################################################################################
##
##  4. Server Install
##
####################################################################################################
 1. Make sure your server has been shut down.

 2. Copy NexgenPlayerLookup202.u and NexgenPlayerLookupDataBase.u to the system folder of
    your UT server.

 3. If your server is using redirect upload the NexgenPlayerLookup202.u.uz file
    to the redirect server.

 4. Open your servers configuration file and add the following server package:

      ServerPackages=NexgenPlayerLookup202

    Also add the following server actors in the exact order:

      ServerActors=NexgenPlayerLookupDataBase.NexgenPlayerLookupDataBase
      ServerActors=NexgenPlayerLookup202.NexgenPlayerLookup

    Note that the actors should be added AFTER the Nexgen controller server actor
    (ServerActors=Nexgen112.NexgenActor).

    Also note that if you want to use the Hostname lookup feature, the plugin's ServerActor must be
    loaded AFTER the IpToCountry.LinkActor ServerActor.
    
    !!! Don't add NexgenPlayerLookupDataBase as ServerPackage! It's serverside only !!!

 5. Restart your server. If the installation was succesful, you can now assign a new admin right
    to the registered accounts on your server ('Perform player lookups'). The Lookup control panel
    will then be located under Nexgen's 'Game' tab.


####################################################################################################
##
##  5. Upgrading from a previous version
##
####################################################################################################
 1. Make sure your server has been shut down.
 
 2. Create a backup of your existing NexgenPlayerLookup.ini file.

 3. Delete any existing NexgenPlayerLookup and NexgenPlayerLookupDataBase files from the system
    folder of your UT server. Now copy NexgenPlayerLookup202.u and NexgenPlayerLookupDataBase.u
    to the system folder of your UT server.

 4. If your server is using redirect delete any existing NexgenPlayerLookup files.
    Now upload NexgenPlayerLookup202.u.uz to the redirect server.

 5. Open NexgenPlayerLookup.ini.

 6. Modify the first line so it looks like this: [NexgenPlayerLookupDataBase.NexgenPlayerLookupDataBase]

 7. Save the changes and close the file.

 8. Goto the [Engine.GameEngine] section and edit the server package and
    server actor lines for Nexgen. They should look like this (exact order!):

      ServerActors=NexgenPlayerLookupDataBase.NexgenPlayerLookupDataBase
      ServerActors=NexgenPlayerLookup202.NexgenPlayerLookup

      ServerPackages=NexgenPlayerLookup202
      
    !!! Don't add NexgenPlayerLookupDataBase as ServerPackage! It's serverside only !!!

 9. Save changes to the servers configuration file and close it.

 10. Restart your server. NexgenPlayerLookup will automatically adjust your existing database.
 
 11. IMPORTANT: If you are updating from version 2.00 or 2.01, make sure the DB repairing has
     finished before using the server! Look out for the line

     "Invalid Database repaired - Version 2.02 successfully installed."
     
     in your server's ucc.log!!!!!!!


####################################################################################################
##
##  6. Credits and thanks
##
####################################################################################################
- Defrost for developing Nexgen and especially for his nearly forgotten work on the great TCP
  implementation in Nexgen 1.12. (http://www.unrealadmin.org/forums/showthread.php?t=26835)
  
- Thanks to Matthew "MSuLL" Sullivan for parts of his work from 'HostnameBan'
  (http://www.unrealadmin.org/forums/showthread.php?t=16076) and his previous idea and work on
  UniversalUnreal (http://www.unrealadmin.org/forums/forumdisplay.php?f=199)
  
- [es]Rush and MSuLL for creating IpToCountry.
  (http://www.unrealadmin.org/forums/showthread.php?t=29924)

- AnthraX for his priceless work on ACE (http://utgl.unrealadmin.org/ace/)

- To my admin team from the 'ComboGib >GRAPPLE< Server <//UrS//>', for their intensive testing, bug-
  finding and feedback, and ofcourse for simply beeing the best team to have. Big thanks guys! :)
  
- aZ.Boy for bug reporting and additional BETA testing


####################################################################################################
##
##  7. Info for programmers
##
####################################################################################################
This mod is open source. You can view/and or use the source code of it partially or entirely without
my permission. You are also more then welcome to recompile this mod for another Nexgen version.
Nonetheless I would like you to follow these limitations:

- If you use parts of this code for your own projects, please give credits to me in your readme.
  (Patrick 'Sp0ngeb0b' Peltzer)

- If you recompile or edit this plugin, please leave the credits part of the readme intact.
  Also note that you have to pay attention to the naming of your version to avoid missmatches.
  All official updates will be made ONLY by me and therefore counting up version numbers are
  forbidden (e.g. NexgenPlayerLookup203). Instead, add an unique suffix (e.g. NexgenPlayerLookup200_bla).

While working with Nexgen's 1.12 TCP functions, I encountered a far-reaching bug in Nexgen's core
file which will prevent empty strings in an array to be transfered correctly. A detailed explanation
and solution can be found here: http://www.unrealadmin.org/forums/showthread.php?t=31280

Version 2.01 fixes the client timeouts. Read the detailed changelog in NexgenPlayerLookup.uc for
further explanation.


####################################################################################################
##
##  8. FAQs
##
####################################################################################################
Q: What mods are required to run this plugin?
A: Only Nexgen112 and subversions. All other mods listed in (3) are optional and will expand the
   experience of NexgenPlayerLookup.

Q: Why should I update to version 2.00?
A: To cut a long story short: Version 2.00 outclasses 1.00 in many ways. Read (1) and (9) for a
   detailed explanation.

Q: How do I enable Hardware ID and MAC Hash detecting?
A: You need to have NexgenABM installed. If it detects the player's hardware info, NexgenPlayerLookup
   will do it aswell.

Q: The hardware info of some players are not saved?
A: Hardware info is limited by ACE to players only. Probably the specifc clients have only been
   connected as spectators yet.

Q: Will the NexgenPlayerLookupDataBase package cause package missmatches?
A: The package is only supposed to be serverside. New releases of the plugin will also require new
   versions of this package. But since it's only serverside, no renaming is needed. You can simply
   overwrite this file on the server. Never add it as a ServerPackage, nor add it to your redirect
   though.

Q: I'm updating from version 2.00/2.01, will my database be recovered?
A: There was a heavy bug in the previous versions, leading to the database becoming corrupted and
   the mod not working correctly. Version 2.02 comes with an automatic database repairing method,
   which should repair the database and recover all data, so nothing is lost. Make sure you create
   a backup of your (corrupted) database before updating, and wait until the repairing has been
   finished before using the server (restarting/mapswitching etc). The is log output in the servers
   ucc.log which indicates the status of the repairing.
   
   
####################################################################################################
##
##  9. Changelog
##
####################################################################################################
- Version 2.02:
  [Added]:    - DB repairing algorithm for version 2.00 and 2.01.
  
  [Fixes]:    - DB getting heavily corrupted.
              - Search by ID not working.
              - Not all search results were transfered.
              - Hostnames not being saved.
              
- [Changed]:  - Internal optimizing.


- Version 2.01:
  [Fix]        - Login timeouts (both, Connection and Nexgen timeouts) have been fixed for good.
  

- Version 2.00:
  [Changes]:   - Database has been restructured for faster access and operation.
               - Database changes are only made on game-end from now on. This drastically reduces
                 impact on the serverperfomance during player joins.
               - Data transfer between server -> client has been completely overworked. Now
                 provides fast and reliable data transfers with guaranteed no packageloss.
               - Database searches are now performed serverside and only the results are being sent
                 to the client. This abolishes the need to request the complete data.
               - The control panel has been completely revised.
               - Total amount of entries has been increased to 25.000

  [Fixes]:     - Drastically reduction of serverperfomance on player joins. Fixes the 'join-lag'
                 and possible timeouts.
               - Data getting lost during sending to admins.
               - Huge lag spikes when performing searches.

  [Added]:     - Ability to directly perform complete database searches within a few seconds.
               - Player's Hardware ID and MAC Hash can now also be recognized by the plugin.
               - Admins can now also search by Hardware ID and MAC Hash.
               - The complete lookup of a player can now be saved clientside to a txt file.



Bug reports / feedback can be send directly to me.



Sp0ngeb0b, June 2014

admin@unrealriders.de / spongebobut@yahoo.com
www.unrealriders.de
#unrealriders @ QuakeNet