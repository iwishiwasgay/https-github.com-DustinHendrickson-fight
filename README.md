Fight Plugin
====

An IRC bot plugin written for [CadBot_Cinch](https://github.com/cadwallion/cadbot_cinch) IRC Bot.

Installation
----
Navigate to the plugin directory of your cadbot_cinch install and run the following:

```
git clone git://github.com/dustinhendrickson/fight.git
```

That's it, it's installed!

Usage
----

Once you're installed, start up your bot.

Make sure to check cadbot_cinch readme for how to install the bot and set up the configuration files if you haven't already.

Command List
----

```
@fight create 
-Creates a new character at level 1

@fight info username
-Displays Level,Exp,Weapons/Armor
```

Game Info
----

Fighting other people and winning results in gaining EXP, every (100 * Level) EXP gives you new level. Every levelup you recieve a new random weapon and piece of armor. Weapons do damage from 1-WeaponDamage. Armor protects 0-ArmorAmount. To win a fight you have to do more damage then you take in a fight. Bonus EXP is awarded for defeating an opponent higher level then you. This is an IDLE RPG, which means at intervals the bot will pick two people with accounts in the channel and make them fight.