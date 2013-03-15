# Fight Plugin



## Installation

Before you can install fight, you must have a working instance of Cadbot running.  Please see the [README](https://github.com/cadwallion/cadbot_cinch)
for instructions on how to install and configure Cadbot.

<<<<<<< HEAD
If you're not installing via Git Clone, just create a new folder in the plugin directory called "fight" and copy the files into the folder.

Usage
----

Once you've got the plugin folder setup start or restart your cadbot_cinch bot.
=======
To install Fight, first clone this repository to the `plugin` directory in your bot's `plugins` directory:

```
cd BOT_DIRECTORY/plugins && git clone git://github.com/dustinhendrickson/fight.git 
```
>>>>>>> bdbc2f766754742b8830ec2c88611dad89c68ad8

If you have customized where your plugins directory is located in your bot, be sure to update the clone 
location accordingly. Restart your bot and the plugin will be automatically loaded.

## Usage

Fight adds two commands to your bot: `@fight create` and `@fight info username`.

`fight create` - Creates a new character at level 1.  Use this to be able to start fighting with other users.
`fight info username` - Displays information about `username`, including Level, Exp, and Equipment.

## Game Info

Fighting other people and winning results in gaining EXP, every `(100 * Level)` EXP gives you new level. Every 
levelup you recieve a new random weapon and piece of armor. Weapons do damage from 1-WeaponDamage. Armor 
protects `0-ArmorAmount`. To win a fight you have to do more damage then you take in a fight. Bonus EXP 
is awarded for defeating an opponent higher level then you. This is an IDLE RPG, which means at 
intervals the bot will pick two people with accounts in the channel and make them fight.
