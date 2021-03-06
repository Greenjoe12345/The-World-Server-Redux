var/list/department_radio_keys = list(
	  ":r" = "right ear",		".r" = "right ear",
	  ":l" = "left ear",		".l" = "left ear",
	  ":i" = "intercom",		".i" = "intercom",
	  ":h" = "department",		".h" = "department",
	  ":+" = "special",			".+" = "special", //activate radio-specific special functions
	  ":c" = "Command",			".c" = "Command",
	  ":n" = "Science",			".n" = "Science",
	  ":m" = "Hospital",		".m" = "Hospital",
	  ":e" = "Fire", 			".e" = "Fire",
	  ":s" = "Police",			".s" = "Police",
	  ":w" = "whisper",			".w" = "whisper",
	  ":t" = "Mercenary",		".t" = "Mercenary",
	  ":x" = "Raider",			".x" = "Raider",
	  ":u" = "Factory",			".u" = "Factory",
	  ":d" = "Diner",			".d" = "Diner",
	  ":o" = "Legal",			".o" = "Legal",
	  ":v" = "Government",		".v" = "Government",
	  ":p" = "AI Private",		".p" = "AI Private",
	  ":y" = "Explorer",		".y" = "Explorer",
	  ":j" = "Pax Synthetica",	".j" = "Pax Synthetica",

	  ":R" = "right ear",	".R" = "right ear",
	  ":L" = "left ear",	".L" = "left ear",
	  ":I" = "intercom",	".I" = "intercom",
	  ":H" = "department",	".H" = "department",
	  ":C" = "Command",		".C" = "Command",
	  ":N" = "Science",		".N" = "Science",
	  ":M" = "Hospital",	".M" = "Hospital",
	  ":E" = "Fire",		".E" = "Fire",
	  ":S" = "Police",		".S" = "Police",
	  ":W" = "whisper",		".W" = "whisper",
	  ":T" = "Mercenary",	".T" = "Mercenary",
	  ":X" = "Raider",		".X" = "Raider",
	  ":U" = "Factory",		".U" = "Factory",
	  ":D" = "Diner",		".D" = "Diner",
	  ":O" = "Legal",		".O" = "Legal",
	  ":V" = "Government",	".V" = "Government",
	  ":P" = "AI Private",	".P" = "AI Private",
	  ":Y" = "Explorer",	".Y" = "Explorer",

	  //kinda localization -- rastaf0
	  //same keys as above, but on russian keyboard layout. This file uses cp1251 as encoding.
	  ":ê" = "right ear",	".ê" = "right ear",
	  ":ä" = "left ear",	".ä" = "left ear",
	  ":ø" = "intercom",	".ø" = "intercom",
	  ":ð" = "department",	".ð" = "department",
	  ":ñ" = "Command",		".ñ" = "Command",
	  ":ò" = "Science",		".ò" = "Science",
	  ":ü" = "Hospital",	".ü" = "Hospital",
	  ":ó" = "Fire",		".ó" = "Fire",
	  ":û" = "Police",		".û" = "Police",
	  ":ö" = "whisper",		".ö" = "whisper",
	  ":å" = "Mercenary",	".å" = "Mercenary",
	  ":é" = "Factory",		".é" = "Factory",
)


var/list/channel_to_radio_key = new
proc/get_radio_key_from_channel(var/channel)
	var/key = channel_to_radio_key[channel]
	if(!key)
		for(var/radio_key in department_radio_keys)
			if(department_radio_keys[radio_key] == channel)
				key = radio_key
				break
		if(!key)
			key = ""
		channel_to_radio_key[channel] = key

	return key

/mob/living/proc/binarycheck()

	if (istype(src, /mob/living/silicon/pai))
		return

	if (!ishuman(src))
		return

	var/mob/living/carbon/human/H = src
	if (H.l_ear || H.r_ear)
		var/obj/item/device/radio/headset/dongle
		if(istype(H.l_ear,/obj/item/device/radio/headset))
			dongle = H.l_ear
		else
			dongle = H.r_ear
		if(!istype(dongle)) return
		if(dongle.translate_binary) return 1

/mob/living/proc/get_default_language()
	return default_language

//Takes a list of the form list(message, verb, whispering) and modifies it as needed
//Returns 1 if a speech problem was applied, 0 otherwise
/mob/living/proc/handle_speech_problems(var/list/message_data)
	var/message = message_data[1]
	var/verb = message_data[2]
	var/whispering = message_data[3]
	. = 0

	if((HULK in mutations) && health >= 25 && length(message))
		message = "[uppertext(message)]!!!"
		verb = pick("yells","roars","hollers")
		whispering = 0
		. = 1
	if(slurring)
		message = slur(message)
		verb = pick("slobbers","slurs")
		. = 1
	if(stuttering)
		message = stutter(message)
		verb = pick("stammers","stutters")
		. = 1

	message_data[1] = message
	message_data[2] = verb
	message_data[3] = whispering

/mob/living/proc/handle_message_mode(message_mode, message, verb, speaking, used_radios, alt_name)
	if(message_mode == "intercom")
		for(var/obj/item/device/radio/intercom/I in view(1, null))
			I.talk_into(src, message, verb, speaking)
			used_radios += I
	return 0

/mob/living/proc/handle_speech_sound()
	var/list/returns[2]
	returns[1] = null
	returns[2] = null
	return returns

/mob/living/proc/get_speech_ending(verb, var/ending)
	if(ending=="!")
		return pick("exclaims","shouts","yells")
	if(ending=="?")
		return pick("asks", "enquires", "questions")
	return verb


/mob/living/say(var/message, var/datum/language/speaking = null, var/verb="says", var/alt_name="", var/whispering = 0)
//	var/spoken_emote = FALSE
	//If you're muted for IC chat
	if(client)
		if(message)
			client.handle_spam_prevention(MUTE_IC)
			if((client.prefs.muted & MUTE_IC) || say_disabled)
				src << "<span class='warning'>You cannot speak in IC (Muted).</span>"
				return

	//Redirect to say_dead if talker is dead
	if(stat)
		if(stat == DEAD && !forbid_seeing_deadchat)
			return say_dead(message)
		return

	//Parse the mode
	var/message_mode = parse_message_mode(message, "headset")

	//Allow them use to markup, if used.
	message = process_chat_markup(message, list("~", "_"))

	//Maybe they are using say/whisper to do a quick emote, so do those
	switch(copytext(message,1,2))
		if("*") return emote(copytext(message,2))
		if("^") return custom_emote(1, copytext(message,2))
//		if("!") spoken_emote = TRUE

	//If there's no punctuation, add punctuation.
	var/p_ending = copytext(message, length(message))
	var/p_message = "[message]."
	if(!(p_ending in list(".","?","!")))
		if(message)
			message = p_message

	//Parse the radio code and consume it
	if (message_mode)
		if (message_mode == "headset")
			message = copytext(message,2)	//it would be really nice if the parse procs could do this for us.
		else if (message_mode == "whisper")
			whispering = 1
			message_mode = null
			message = copytext(message,3)
		else
			message = copytext(message,3)

	//Clean up any remaining space on the left
	message = trim_left(message)

	//Parse the language code and consume it
	if(!speaking)
		speaking = parse_language(message)
	if(speaking)
		message = copytext(message,2+length(speaking.key))
	else
		speaking = get_default_language()

	//HIVEMIND languages always send to all people with that language
	if(speaking && (speaking.flags & HIVEMIND))
		speaking.broadcast(src,trim(message))
		return 1

	//If it looks like accidental IC-OOK/emoting
	if((copytext(message, 1, 2) in list("say","me")) || (findtext(lowertext(copytext(message, 1, 5)), "ooc")))
		if(alert("Your message \"[message]\" looks like it was meant for OOC instead of IC, say it in IC still?", "Confirm if meant for IC?", "No", "Yes") != "Yes")
			return

	//Self explanatory.
	if(is_muzzled() && !(speaking && (speaking.flags & SIGNLANG)))
		src << "<span class='danger'>You're muzzled and cannot speak!</span>"
		return



	//Clean up any remaining junk on the left like spaces.
	message = trim_left(message)

	//Autohiss handles auto-rolling tajaran R's and unathi S's/Z's
	message = handle_autohiss(message, speaking)

	//Whisper vars
	var/w_scramble_range = 5	//The range at which you get ***as*th**wi****
	var/w_adverb				//An adverb prepended to the verb in whispers
	var/w_not_heard
		//The message for people in watching range

	//Handle language-specific verbs and adverb setup if necessary
	if(!whispering) //Just doing normal 'say' (for now, may change below)
		verb = say_quote(message, speaking)
	else if(whispering && speaking.whisper_verb) //Language has defined whisper verb
		verb = speaking.whisper_verb
		w_not_heard = "[verb] something"
	else //Whispering but language has no whisper verb, use say verb
		w_adverb = pick("quietly", "softly")
		verb = speaking.speech_verb
		w_not_heard = "[speaking.speech_verb] something [w_adverb]"

	//For speech disorders (hulk, slurring, stuttering)
	if(!(speaking && (speaking.flags & NO_STUTTER || speaking.flags & SIGNLANG)))
		var/list/message_data = list(message, verb, whispering)
		if(handle_speech_problems(message_data))
			message = message_data[1]
			whispering = message_data[3]

			if(verb != message_data[2]) //They changed our verb
				if(whispering)
					w_adverb = pick("quietly", "softly")
				verb = message_data[2]

	//Whisper may have adverbs, add those if one was set
	if(w_adverb) verb = "[verb] [w_adverb]"

	//If something nulled or emptied the message, forget it
	if(!message || message == "")
		return 0

	//Radio message handling
	var/list/obj/item/used_radios = new
	if(handle_message_mode(message_mode, message, verb, speaking, used_radios, alt_name, whispering))
		return 1

	//For languages with actual speech sounds
	var/list/handle_v = handle_speech_sound()
	var/sound/speech_sound = handle_v[1]
	var/sound_vol = handle_v[2]

	//Default range and italics, may be overridden past here
	var/message_range = world.view
	var/italics = 0

	//Speaking into radios
	if(used_radios.len)
		italics = 1
		message_range = 1
		if(speaking)
			message_range = speaking.get_talkinto_msg_range(message)
		var/msg
		if(!speaking || !(speaking.flags & NO_TALK_MSG))
			msg = "<span class='notice'>\The [src] talks into \the [used_radios[1]]</span>"
		for(var/mob/living/M in hearers(5, src))
			if((M != src) && msg)
				M.show_message(msg)

			if (speech_sound)
				sound_vol *= 0.5



	//Set vars if we're still whispering by this point
	if(whispering)
		italics = 1
		message_range = 1
		sound_vol *= 0.5

	//Handle nonverbal and sign languages here
	if (speaking)
		if (speaking.flags & SIGNLANG)
			log_say("(SIGN) [message]", src)
			return say_signlang(message, pick(speaking.signlang_verb), speaking)

		if (speaking.flags & NONVERBAL)
			if (prob(30))
				src.custom_emote(1, "[pick(speaking.signlang_verb)].")

	//These will contain the main receivers of the message
	var/list/listening = list()
	var/list/listening_obj = list()

	//Atmosphere calculations (speaker's side only, for now)
	var/turf/T = get_turf(src)

	if(T)
		//make sure the air can transmit speech - speaker's side
		var/datum/gas_mixture/environment = T.return_air()
		var/pressure = (environment) ? environment.return_pressure() : 0
		if(pressure < SOUND_MINIMUM_PRESSURE)
			message_range = 1

		//sound distortion pressure, to help clue people in that the air is thin, even if it isn't a vacuum yet
		if(pressure < ONE_ATMOSPHERE * 0.4)
			italics = TRUE
			sound_vol *= 0.5 //muffle the sound a bit, so it's like we're actually talking through contact

		//DO NOT FUCKING CHANGE THIS TO GET_OBJ_OR_MOB_AND_BULLSHIT() -- Hugs and Kisses ~Ccomp
		var/list/hear = hear(message_range, T)

		for(var/mob/M in mob_list)
			if(M.locs.len && (M.locs[1] in hear))
				listening |= M
			else if(M.stat == DEAD && M.is_preference_enabled(/datum/client_preference/ghost_ears))
				listening |= M

		var/list/results = get_mobs_and_objs_in_view_fast(T, world.view, remote_ghosts = client ? TRUE : FALSE)
		var/list/hearing_objs = results["objs"]

		for(var/obj/O in hearing_objs)
			if(O.locs.len && (O.locs[1] in hear))
				listening_obj |= O

	var/speech_bubble_test = say_test(message)
	var/image/speech_bubble = image('icons/mob/talk.dmi', src, "h[speech_bubble_test]")
	speech_bubble.layer = ABOVE_MOB_LAYER
	spawn(30)
		qdel(speech_bubble)

	var/list/speech_bubble_recipients = list()
	for(var/mob/M in listening)
		if(M.client)
			speech_bubble_recipients += M.client
		M.hear_say(message, verb, speaking, alt_name, italics, src, speech_sound, sound_vol)

		if(M && src) //If we still exist, when the spawn processes
			var/dst = get_dist(get_turf(M),get_turf(src))

			if(whispering) //Don't even bother with these unless whispering
				if(dst > message_range && dst <= w_scramble_range) //Inside whisper scramble range
					M.hear_say(stars(message), verb, speaking, alt_name, italics, src, speech_sound, sound_vol*0.2)
				if(dst > w_scramble_range && dst <= world.view) //Inside whisper 'visible' range
					M.show_message("<span class='game say'><span class='name'>[src.name]</span> [w_not_heard].</span>", 2)

	animate_speechbubble(speech_bubble, speech_bubble_recipients, 30)
//	if(!spoken_emote)
//		animate_chat(message, speaking, italics, speech_bubble_recipients, 40)

	for(var/obj/O in listening_obj)
		spawn(0)
			if(O) //It's possible that it could be deleted in the meantime.
				O.hear_talk(src, message, verb, speaking)

	if(whispering)
		log_whisper(message,src)
	else
		log_say(message, src)
	return 1

/mob/living/proc/say_signlang(var/message, var/verb="gestures", var/datum/language/language)
	var/turf/T = get_turf(src)
	//We're in something, gesture to people inside the same thing
	if(loc != T)
		for(var/mob/M in loc)
			M.hear_signlang(message, verb, language, src)

	//We're on a turf, gesture to visible as if we were a normal language
	else
		var/list/potentials = get_mobs_and_objs_in_view_fast(T, world.view)
		var/list/mobs = potentials["mobs"]
		for(var/hearer in mobs)
			var/mob/M = hearer
			M.hear_signlang(message, verb, language, src)
	return 1

/obj/effect/speech_bubble
	var/mob/parent

/mob/living/proc/GetVoice()
	return name

/mob/proc/speech_bubble_appearance()
	return "normal"

/proc/animate_speechbubble(image/I, list/show_to, duration)
	var/matrix/M = matrix()
	M.Scale(0,0)
	I.transform = M
	I.alpha = 0
	for(var/client/C in show_to)
		C.images += I
	animate(I, transform = 0, alpha = 255, time = 5, easing = ELASTIC_EASING)
	sleep(duration-5)
	animate(I, alpha = 0, time = 5, easing = EASE_IN)
	sleep(5)
	for(var/client/C in show_to)
		C.images -= I
