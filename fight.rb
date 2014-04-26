require 'cinch'
require 'time'
require 'yaml'

#Code by Dustin Hendrickson
#dustin.hendrickson@gmail.com


class Fight
include Cinch::Plugin
prefix "@"

#Configuration Variables=======
MAX_EXPERIENCE_PER_WIN = 10
MAX_EXPERIENCE_PER_TIE = 5

LEVEL_FACTOR = 100

TIMER_RANGE_MIN = 120
TIMER_RANGE_MAX = 240

MINIMUM_DAMAGE = 1
#==============================

#Read the config file in for items and set arrays.
EQUIPMENT = YAML.load_file('plugins/fight/equipment.yml')

WEAPONS = EQUIPMENT['weapons']
ARMOR = EQUIPMENT['armor']

#Timer Method to run the Attack Function every interval.
timer 120, method: :attack

#Regex to grab the command trigger string.
match /^@fight (\S+) ?(.+)?/, method: :fight, :use_prefix => false

#Run the functions based on passed in command.
def fight(m, command, param)
	case command
		when 'info'
		  info m, param
		when 'create'
		  create m
		when 'ai'
			fightai m
		when 'help'
		  help m
	end
end

#Internal Reddis Function List
def get_exp(param)
	@bot.database.get("user:#{param}:exp")
end

def reset_exp(param)
	@bot.database.set("user:#{param}:exp", 0)
end

def save_exp(param,exp)
	@bot.database.set("user:#{param}:exp", get_exp(param).to_i + exp.to_i)
end

def get_level(param)
	@bot.database.get("user:#{param}:level")
end

def save_level(param, level)
	@bot.database.set("user:#{param}:level", level)
end

def get_weapon(param)
	@bot.database.get("user:#{param}:weapon")
end

def save_weapon(param, weapon)
	@bot.database.set("user:#{param}:weapon", weapon)
end

def get_armor(param)
	@bot.database.get("user:#{param}:armor")
end

def save_armor(param, armor)
	@bot.database.set("user:#{param}:armor", armor)
end

#This function takes a username and displays that user's account details.
def info (m, param)
	if param.nil?
		if get_level(m.user.nick).to_i >= 1
			info_weapon = WEAPONS[get_level(m.user.nick).to_i][get_weapon(m.user.nick).to_i]
			info_armor = ARMOR[get_level(m.user.nick).to_i][get_armor(m.user.nick).to_i]
			@bot.msg(m.user.nick,"-> 02#{m.user.nick}: Level [07#{get_level(m.user.nick)}] EXP: [03#{get_exp(m.user.nick)}/03#{get_level(m.user.nick).to_i*LEVEL_FACTOR}] Weapon: [06#{info_weapon['name']} | DMG: 131- #{info_weapon['damage']} | ELE: 14#{info_weapon['element']}] Armor: [06#{info_armor['name']} | ARM: 050-#{info_armor['armor']} | ELE: 14#{info_armor['element']}] AP: [#{@bot.database.get('user:Dustin:AP')}]")
		else
			@bot.msg(m.user.nick,"04-> You have not created a character.")
		end
	else
		if get_level(param).to_i >= 1
			info_weapon = WEAPONS[get_level(param).to_i][get_weapon(param).to_i]
			info_armor = ARMOR[get_level(param).to_i][get_armor(param).to_i]
			@bot.msg(m.user.nick,"-> 04#{param}: Level [07#{get_level(param)}] EXP: [03#{get_exp(param)}/03#{get_level(param).to_i*LEVEL_FACTOR}] Weapon: [06#{info_weapon['name']} | DMG: 131-#{info_weapon['damage']} | ELE: 14#{info_weapon['element']}] Armor: [06#{info_armor['name']} | ARM: 050-#{info_armor['armor']} | ELE: 14#{info_armor['element']}]")
		else
			@bot.msg(m.user.nick,"04-> #{param} has not created a character.")
		end
	end
end

#Checks to see if user has leveled up.
def calculate_level(param)
	current_level = get_level(param).to_i
	required_exp_new_level = current_level * LEVEL_FACTOR
	if get_exp(param).to_i >= required_exp_new_level
		new_level = current_level + 1
		save_level(param, new_level)
		reset_exp(param)
		randweapon = rand(5)
		randarmor = rand(5)
		save_weapon(param, randweapon)
		save_armor(param, randarmor)
		new_weapon = WEAPONS[new_level][randweapon]
		new_armor = ARMOR[new_level][randarmor]

		chan = @bot.channels.sample
		channel = Channel(chan)

		channel.msg "----------------------------------------------------"

		channel.msg "-> 02#{param} reaches level 07#{get_level(param)}! Equips a new [06#{new_weapon['name']} | DMG: 131-#{new_weapon['damage']} | ELE: 14#{new_weapon['element']}] and [06#{new_armor['name']} | ARM: 050-#{new_armor['armor']} | ELE: 14#{new_armor['element']}]"
	end
end

#Displays help documentation.
def help(m)
	@bot.msg(m.user.nick,"-> Command List:-> 07@fight create (Creates a new character at level 1), 07@fight info Username (Displays Level,Exp,Equipment)")
	@bot.msg(m.user.nick,"-> Game Info:-> Fighting other people and winning results in gaining EXP, every (#{LEVEL_FACTOR} * Level) EXP gives you new level. Each new level you recieve a new weapon and armor piece of your level.. Weapons do damage from 1-WeaponDamage. Armor protects 0-ArmorAmount. To win a fight you have to do more damage then you take in a fight. Bonus EXP is awarded for defeating an opponent higher level then you.")
end

#Create a new character.
def create(m)
	randweapon = rand(5)
	randarmor = rand(5)
	save_weapon(m.user.nick, randweapon)
	save_armor(m.user.nick, randarmor)
	reset_exp(m.user.nick)
	save_level(m.user.nick, 1)
	starterweapon = WEAPONS[1][randweapon]
	starterarmor = ARMOR[1][randarmor]
	m.reply "-> New character created for 02#{m.user.nick}. Starting with [06#{starterweapon['name']} | DMG: 131-#{starterweapon['damage']} | ELE: 14#{starterweapon['element']} ] and [06#{starterarmor['name']} | ARM: 050-#{starterarmor['armor']} | ELE: 14#{starterarmor['element']}]"
end

#Create a new AI character.
def createai(level)
	randweapon = rand(5)
	randarmor = rand(5)
	save_weapon("AI", randweapon)
	save_armor("AI", randarmor)
	reset_exp("AI")
	save_level("AI", level)
end

def fightai(m)
	attack(:a => m, :b => "ai")
end

def attack( options={} )
	chan = @bot.channels.sample
	channel = Channel(chan)

	#Setup default options if ai fight was passed to the function.
	if options[:b] == "ai"

		usernameA = options[:a].user.nick
		usernameB = "AI"
		createai(get_level(usernameA).to_i)
	else
		#Loop till we find a valid user
		usernameA = ''
		i = 0
		while usernameA == 'FightBot' || usernameA == ''
			usernameA = chan.users.keys.sample.nick
			if get_level(usernameA).to_i <= 0
				usernameA = ''
			end
			i +=1
			if i >= 50
				usernameA = ''
				break
			end
		end

		#Loop till we find a valid user to fight against userA.
		usernameB = ''
		i = 0
		while usernameB == 'FightBot' || usernameB == '' || usernameA == usernameB || get_level(usernameB).to_i <= 0
			usernameB = chan.users.keys.sample.nick
			if get_level(usernameB).to_i <= 0
				usernameB = ''
			end
			i +=1
			if i >= 50
				usernameB = ''
				break
			end
		end

	end

	#We don't want to do anything if any of the users didnt get set.
	if usernameA != '' && usernameB != ''

			attacker_level = get_level(usernameA).to_i
			defender_level = get_level(usernameB).to_i

			attacker_weapon = WEAPONS[attacker_level][get_weapon(usernameA).to_i]
			defender_weapon = WEAPONS[defender_level][get_weapon(usernameB).to_i]

			attacker_armor = ARMOR[attacker_level][get_armor(usernameA).to_i]
			defender_armor = ARMOR[defender_level][get_armor(usernameB).to_i]

			attacker_damage = rand(attacker_weapon['damage']) + MINIMUM_DAMAGE
			defender_damage = rand(defender_weapon['damage']) + MINIMUM_DAMAGE

			attacker_armor = rand(attacker_armor['armor'])
			defender_armor = rand(defender_armor['armor'])

			attacker_damage_done = attacker_damage - defender_armor
			defender_damage_done = defender_damage - attacker_armor

			#Make sure we can do math on the numbers.
			if attacker_damage_done < 0
				attacker_damage_done = 0
			end

			if defender_damage_done < 0
				defender_damage_done = 0
			end

			channel.msg "----------------------------------------------------"
			channel.msg "-> 02#{usernameA} [07#{get_level(usernameA)}] attacks 04#{usernameB} with their 06#{attacker_weapon['name']} [DMG:02#{attacker_damage}-04#{defender_armor}:ARM] = 02#{attacker_damage_done} Damage Inflicted"
			channel.msg "-> 04#{usernameB} [07#{get_level(usernameB)}] counters 02#{usernameA} with their 06#{defender_weapon['name']} [DMG:04#{defender_damage}-02#{attacker_armor}:ARM] = 04#{defender_damage_done} Damage Inflicted"
			channel.msg "----------------------------------------------------"

			#Here we start to calculate the battle results
			#Check to see if the attacker did more damage than the defender and sets EXP.
			if attacker_damage_done > defender_damage_done
				base_exp = rand(MAX_EXPERIENCE_PER_WIN)+1
				if get_level(usernameB).to_i > get_level(usernameA).to_i
					bonus_exp = (base_exp * (get_level(usernameB).to_i - get_level(usernameA).to_i))
				else
					bonus_exp = 0
				end
				earned_exp = base_exp + bonus_exp
				channel.msg "-> 02#{usernameA}[07#{get_level(usernameA)}][03#{get_exp(usernameA)}/03#{get_level(usernameA).to_i*LEVEL_FACTOR}] beats 04#{usernameB} [07#{get_level(usernameB)}][03#{get_exp(usernameB)}/03#{get_level(usernameB).to_i*LEVEL_FACTOR}] and gains 03#{base_exp}+03#{bonus_exp}=03#{earned_exp} EXP."
				save_exp(usernameA, earned_exp)
				calculate_level(usernameA)
			end

			#Defender Wins
			if attacker_damage_done < defender_damage_done
				base_exp = rand(MAX_EXPERIENCE_PER_WIN)+1
				if get_level(usernameA).to_i > get_level(usernameB).to_i
					bonus_exp = (base_exp * (get_level(usernameA).to_i - get_level(usernameB).to_i))
				else
					bonus_exp = 0
				end
				earned_exp = base_exp + bonus_exp
				channel.msg "-> 04#{usernameB}[07#{get_level(usernameB)}][03#{get_exp(usernameB)}/03#{get_level(usernameB).to_i*LEVEL_FACTOR}] beats 02#{usernameA}[07#{get_level(usernameA)}][03#{get_exp(usernameA)}/03#{get_level(usernameA).to_i*LEVEL_FACTOR}] and gains 03#{base_exp}+03#{bonus_exp}=03#{earned_exp} EXP."
				save_exp(usernameB, earned_exp)
				calculate_level(usernameB)
			end

			#Tie
			if attacker_damage_done == defender_damage_done
				earned_exp = rand(MAX_EXPERIENCE_PER_TIE)+1
				channel.msg "-> 02#{usernameA}[07#{get_level(usernameA)}][03#{get_exp(usernameA)}/03#{get_level(usernameA).to_i*LEVEL_FACTOR}] ties 04#{usernameB}[07#{get_level(usernameB)}][03#{get_exp(usernameB)}/03#{get_level(usernameB).to_i*LEVEL_FACTOR}] and both gain 03#{earned_exp} EXP."
				save_exp(usernameA, earned_exp)
				save_exp(usernameB, earned_exp)
				calculate_level(usernameA)
				calculate_level(usernameB)
			end

		end #End Account Check

	end #End Null Users Check.

end #End Of Attack

#end #End Class
