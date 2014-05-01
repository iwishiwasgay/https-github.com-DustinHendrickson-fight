require 'cinch'
require 'time'
require 'yaml'

# Code by Dustin Hendrickson
# dustin.hendrickson@gmail.com


class Fight
include Cinch::Plugin
prefix '@'

# Configuration Variables=======
MAX_EXPERIENCE_PER_WIN = 10
MAX_EXPERIENCE_PER_TIE = 5

ELEMENT_BONUS = 3

LEVEL_FACTOR = 100

MINIMUM_DAMAGE = 1
#===============================
# Color Defenitions
RED = '04'
BLUE = '12'
GREEN = '03'
BLACK = '01'
BROWN = '05'
PURPLE = '06'
YELLOW = '08'
TEAL = '11'
ORANGE = '07'
PINK = '13'
GREY = '14'
BOLD = ''
CF = '' #CLEAR FORMATTING

# Read the config file in for items and set arrays.
EQUIPMENT = YAML.load_file('plugins/fight/equipment.yml')

WEAPONS = EQUIPMENT['weapons']
ARMOR = EQUIPMENT['armor']

# Timer Method to run the Attack Function every interval.
timer 120, method: :attack

# Regex to grab the command trigger string.
match /^@fight (\S+) ?(.+)?/, method: :fight, :use_prefix => false

# Run the functions based on passed in command.
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

# Internal Reddis Function List
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

# This function takes a username and displays that user's account details.
def info (m, param)
	if param.nil?
		if get_level(m.user.nick).to_i >= 1
			info_weapon = WEAPONS[get_level(m.user.nick).to_i][get_weapon(m.user.nick).to_i]
			info_armor = ARMOR[get_level(m.user.nick).to_i][get_armor(m.user.nick).to_i]
			@bot.msg(m.user.nick,"#{BOLD}-> #{BLUE}#{m.user.nick}#{CF}: Level [#{ORANGE}#{get_level(m.user.nick)}#{CF}] EXP: [#{GREEN}#{get_exp(m.user.nick)}#{CF}/#{GREEN}#{get_level(m.user.nick).to_i*LEVEL_FACTOR}#{CF}] Weapon: [#{PURPLE}#{info_weapon['name']}#{CF} | DMG: #{PINK}1- #{info_weapon['damage']}#{CF} | ELE: #{wrapInElementColor(info_weapon['element'])}] Armor: [#{PURPLE}#{info_armor['name']}#{CF} | ARM: #{BROWN}0-#{info_armor['armor']}#{CF} | ELE: #{wrapInElementColor(info_armor['element'])}]")
		else
			@bot.msg(m.user.nick, "#{RED}#{BOLD}-> You have not created a character.")
		end
	else
		if get_level(param).to_i >= 1
			info_weapon = WEAPONS[get_level(param).to_i][get_weapon(param).to_i]
			info_armor = ARMOR[get_level(param).to_i][get_armor(param).to_i]
			@bot.msg(m.user.nick,"#{BOLD}-> #{RED}#{param}#{CF}: Level [#{ORANGE}#{get_level(param)}#{CF}] EXP: [#{GREEN}#{get_exp(param)}#{CF}/#{GREEN}#{get_level(param).to_i*LEVEL_FACTOR}#{CF}] Weapon: [#{PURPLE}#{info_weapon['name']}#{CF} | DMG: #{PINK}1-#{info_weapon['damage']}#{CF} | ELE: #{wrapInElementColor(info_weapon['element'])}] Armor: [#{PURPLE}#{info_armor['name']}#{CF} | ARM: #{BROWN}0-#{info_armor['armor']}#{CF} | ELE: #{wrapInElementColor(info_armor['element'])}]")
		else
			@bot.msg(m.user.nick,"#{RED}#{BOLD}-> #{param} has not created a character.")
		end
	end
end

def getElementBonus(elementAttacker, elementDefender)
	case [elementAttacker, elementDefender]
		when ['Fire', 'Life']
			return "+#{RED}#{ELEMENT_BONUS}#{CF}"
		when ['Water', 'Fire']
			return "+#{TEAL}#{ELEMENT_BONUS}#{CF}"
		when ['Life', 'Water']
			return "+#{GREEN}#{ELEMENT_BONUS}#{CF}"
		when ['Life', 'Fire']
			return "-#{GREEN}#{ELEMENT_BONUS}#{CF}"
		when ['Fire', 'Water']
			return "-#{RED}#{ELEMENT_BONUS}#{CF}"
		when ['Water', 'Life']
			return "-#{TEAL}#{ELEMENT_BONUS}#{CF}"
	else
		return ""
	end
end

def getElementTag(element)
	case element
		when "Fire"
			return "#{RED}F#{CF}"
		when "Water"
			return "#{TEAL}W#{CF}"
		when "Life"
			return "#{GREEN}L#{CF}"
		else
			return "#{GREY}N#{CF}"
		end
end

def wrapInElementColor(stringToWrap)
	case stringToWrap
		when "Fire"
			return "#{RED}#{stringToWrap}#{CF}"
		when "Water"
			return "#{TEAL}#{stringToWrap}#{CF}"
		when "Life"
			return "#{GREEN}#{stringToWrap}#{CF}"
		else
			return "#{GREY}#{stringToWrap}#{CF}"
		end
end

# Checks to see if user has leveled up.
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

		channel.msg '----------------------------------------------------'
		channel.msg "#{BOLD}-> #{BLUE}#{param}#{CF} reaches level #{ORANGE}#{get_level(param)}#{CF}! Equips a new [#{PURPLE}#{new_weapon['name']}#{CF} | DMG: #{PINK}1-#{new_weapon['damage']}#{CF} | ELE: #{wrapInElementColor(new_weapon['element'])}] and [#{PURPLE}#{new_armor['name']}#{CF} | ARM: #{BROWN}0-#{new_armor['armor']}#{CF} | ELE: #{wrapInElementColor(new_armor['element'])}]"
	end
end

# Displays help documentation.
def help(m)
	@bot.msg(m.user.nick,"#{BOLD}-> Command List:#{BOLD}-> #{ORANGE}@fight create#{CF} (Creates a new character at level 1), #{ORANGE}@fight info Username#{CF} (Displays Level, Exp, Equipment, if no username is given, will display your own stats.) #{ORANGE}@fight ai#{CF} (Pairs you against an AI fight.)")
	@bot.msg(m.user.nick,"#{BOLD}-> Game Info:#{BOLD}-> The bot will periodically pick 2 random registered users in the room and make them fight eachother, winning results in gaining EXP, every (#{LEVEL_FACTOR} * Level) EXP gives you new level. Each new level you will recieve a random new weapon and armor piece of your level. Weapons do damage from 1-WeaponDamage. Armor protects 0-ArmorAmount. To win a fight you have to do more damage then you take in a single exchange of swings. Bonus EXP is awarded for defeating an opponent higher level then you.")
end

# Create a new character.
def create(m)
	randweapon = rand(5)
	randarmor = rand(5)
	save_weapon(m.user.nick, randweapon)
	save_armor(m.user.nick, randarmor)
	reset_exp(m.user.nick)
	save_level(m.user.nick, 1)
	starterweapon = WEAPONS[1][randweapon]
	starterarmor = ARMOR[1][randarmor]
	m.reply "#{BOLD}-> New character created for #{BLUE}#{m.user.nick}#{CF}. Starting with [#{PURPLE}#{starterweapon['name']}#{CF} | DMG: #{PINK}1-#{starterweapon['damage']}#{CF} | ELE: #{wrapInElementColor(starterweapon['element'])} ] and [#{PURPLE}#{starterarmor['name']}#{CF} | ARM: #{BROWN}0-#{starterarmor['armor']}#{CF} | ELE: #{wrapInElementColor(starterarmor['element'])}]"
end

# Create a new AI character.
def createAI(level)
	randweapon = rand(5)
	randarmor = rand(5)
	save_weapon('AI', randweapon)
	save_armor('AI', randarmor)
	reset_exp('AI')
	save_level('AI', level)
end

def fightai(m)
	attack(:a => m, :b => 'AI')
end

def attack( options={} )
	chan = @bot.channels.sample
	channel = Channel(chan)

	# Setup default options if ai fight was passed to the function.
	if options[:b] == 'AI'
		usernameA = options[:a].user.nick
		usernameB = 'AI'
		createAI(get_level(usernameA).to_i)
	else
		# Loop till we find a valid user
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

		# Loop till we find a valid user to fight against userA.
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
				# We can't find anyone to fight against, but we have someone
				# who wants to fight, so we'll pair them with an AI.
				if usernameA != ''
					usernameB = 'AI'
					createAI(get_level(usernameA).to_i)
				end
				break
			end
		end
	end

	# We don't want to do anything if any of the users didnt get set.
	if usernameA != '' && usernameB != ''
			attacker_level = get_level(usernameA).to_i
			defender_level = get_level(usernameB).to_i

			attacker_weapon = WEAPONS[attacker_level][get_weapon(usernameA).to_i]
			defender_weapon = WEAPONS[defender_level][get_weapon(usernameB).to_i]

			attacker_armorworn = ARMOR[attacker_level][get_armor(usernameA).to_i]
			defender_armorworn = ARMOR[defender_level][get_armor(usernameB).to_i]

			attacker_damage = rand(attacker_weapon['damage']) + MINIMUM_DAMAGE
			defender_damage = rand(defender_weapon['damage']) + MINIMUM_DAMAGE

			attacker_armor = rand(attacker_armorworn['armor'])
			defender_armor = rand(defender_armorworn['armor'])

			#============================================================================
			# Element Definitions =======================================================
			#============================================================================
			attacker_weapon_element_bonus = getElementBonus(attacker_weapon['element'], defender_armorworn['element'])
			defender_weapon_element_bonus = getElementBonus(defender_weapon['element'], attacker_armorworn['element'])

			attacker_base_damage = attacker_damage
			defender_base_damage = defender_damage

			attacker_bonus_modifier = attacker_weapon_element_bonus[0]
			case attacker_bonus_modifier
				when "+"
					attacker_damage += ELEMENT_BONUS
				when "-"
					attacker_damage -= ELEMENT_BONUS
			end

			defender_bonus_modifier = defender_weapon_element_bonus[0]
			case defender_bonus_modifier
				when "+"
					defender_damage += ELEMENT_BONUS
				when "-"
					defender_damage -= ELEMENT_BONUS
			end
			#============================================================================

			if attacker_base_damage < 0
				attacker_base_damage = 0
			end

			if defender_base_damage < 0
				defender_base_damage = 0
			end

			if attacker_damage < 0
				attacker_damage = 0
			end

			if defender_damage < 0
				defender_damage = 0
			end

			# Calculate Damage
			attacker_damage_done = attacker_damage - defender_armor
			defender_damage_done = defender_damage - attacker_armor

			# Make sure we can do math on the numbers.
			if attacker_damage_done < 0
				attacker_damage_done = 0
			end

			if defender_damage_done < 0
				defender_damage_done = 0
			end

			channel.msg '----------------------------------------------------'
			channel.msg "-> #{BLUE}#{usernameA}#{CF}[#{ORANGE}#{get_level(usernameA)}#{CF}] attacks #{RED}#{usernameB}#{CF} with #{PURPLE}#{attacker_weapon['name']}#{CF} #{getElementTag(attacker_weapon['element'])}[DMG:#{BLUE}#{attacker_base_damage}#{CF}#{attacker_weapon_element_bonus}#{CF}-#{RED}#{defender_armor}#{CF}:ARM]#{getElementTag(defender_armorworn['element'])} = #{BLUE}#{attacker_damage_done}#{CF} Damage Inflicted"
			channel.msg "-> #{RED}#{usernameB}#{CF}[#{ORANGE}#{get_level(usernameB)}#{CF}] counters #{BLUE}#{usernameA}#{CF} with #{PURPLE}#{defender_weapon['name']}#{CF} #{getElementTag(defender_weapon['element'])}[DMG:#{RED}#{defender_base_damage}#{CF}#{defender_weapon_element_bonus}#{CF}-#{BLUE}#{attacker_armor}#{CF}:ARM]#{getElementTag(attacker_armorworn['element'])} = #{RED}#{defender_damage_done}#{CF} Damage Inflicted"
			channel.msg '----------------------------------------------------'

			# Here we start to calculate the battle results
			# Check to see if the attacker did more damage than the defender and sets EXP.
			if attacker_damage_done > defender_damage_done
				base_exp = rand(MAX_EXPERIENCE_PER_WIN)+1
				if get_level(usernameB).to_i > get_level(usernameA).to_i
					bonus_exp = (base_exp * (get_level(usernameB).to_i - get_level(usernameA).to_i))
				else
					bonus_exp = 0
				end
				earned_exp = base_exp + bonus_exp
				channel.msg "#{BOLD}-> #{BLUE}#{usernameA}#{CF}[#{ORANGE}#{get_level(usernameA)}#{CF}][#{GREEN}#{get_exp(usernameA)}#{CF}/#{GREEN}#{get_level(usernameA).to_i*LEVEL_FACTOR}#{CF}] beats #{RED}#{usernameB}#{CF} [#{ORANGE}#{get_level(usernameB)}#{CF}][#{GREEN}#{get_exp(usernameB)}#{CF}/#{GREEN}#{get_level(usernameB).to_i*LEVEL_FACTOR}#{CF}] and gains #{GREEN}#{base_exp}#{CF}+#{GREEN}#{bonus_exp}#{CF}=#{GREEN}#{earned_exp}#{CF} EXP."
				save_exp(usernameA, earned_exp)
				calculate_level(usernameA)
			end

			# Defender Wins
			if attacker_damage_done < defender_damage_done
				base_exp = rand(MAX_EXPERIENCE_PER_WIN)+1
				if get_level(usernameA).to_i > get_level(usernameB).to_i
					bonus_exp = (base_exp * (get_level(usernameA).to_i - get_level(usernameB).to_i))
				else
					bonus_exp = 0
				end
				earned_exp = base_exp + bonus_exp
				channel.msg "#{BOLD}-> #{RED}#{usernameB}#{CF}[#{ORANGE}#{get_level(usernameB)}#{CF}][#{GREEN}#{get_exp(usernameB)}#{CF}/#{GREEN}#{get_level(usernameB).to_i*LEVEL_FACTOR}#{CF}] beats #{BLUE}#{usernameA}#{CF}[#{ORANGE}#{get_level(usernameA)}#{CF}][#{GREEN}#{get_exp(usernameA)}#{CF}/#{GREEN}#{get_level(usernameA).to_i*LEVEL_FACTOR}#{CF}] and gains #{GREEN}#{base_exp}#{CF}+#{GREEN}#{bonus_exp}#{CF}=#{GREEN}#{earned_exp}#{CF} EXP."
				save_exp(usernameB, earned_exp)
				calculate_level(usernameB)
			end

			# Tie
			if attacker_damage_done == defender_damage_done
				earned_exp = rand(MAX_EXPERIENCE_PER_TIE)+1
				channel.msg "#{BOLD}-> #{BLUE}#{usernameA}#{CF}[#{ORANGE}#{get_level(usernameA)}#{CF}][#{GREEN}#{get_exp(usernameA)}#{CF}/#{GREEN}#{get_level(usernameA).to_i*LEVEL_FACTOR}#{CF}] ties #{RED}#{usernameB}#{CF}[#{ORANGE}#{get_level(usernameB)}#{CF}][#{GREEN}#{get_exp(usernameB)}#{CF}/#{GREEN}#{get_level(usernameB).to_i*LEVEL_FACTOR}#{CF}] and both gain #{GREEN}#{earned_exp}#{CF} EXP."
				save_exp(usernameA, earned_exp)
				save_exp(usernameB, earned_exp)
				calculate_level(usernameA)
				calculate_level(usernameB)
			end
	end # End Null Users Check.
end # End Of Attack

end # End Class
