#define PROCESS_ACCURACY 10

/****************************************************
				INTERNAL ORGANS DEFINES
****************************************************/


// Brain is defined in brain_item.dm.
/obj/item/organ/kidneys
	name = "kidneys"
	icon_state = "kidneys"
	gender = PLURAL
	organ_tag = "kidneys"
	parent_organ = "groin"

/obj/item/organ/kidneys/process()

	..()

	if(!owner)
		return

	// Coffee is really bad for you with busted kidneys.
	// This should probably be expanded in some way, but fucked if I know
	// what else kidneys can process in our reagent list.
	var/datum/reagent/coffee = locate(/datum/reagent/drink/coffee) in owner.reagents.reagent_list
	if(coffee)
		if(is_bruised())
			owner.adjustToxLoss(0.1 * PROCESS_ACCURACY)
		else if(is_broken())
			owner.adjustToxLoss(0.3 * PROCESS_ACCURACY)

/obj/item/organ/eyes
	name = "eyeballs"
	icon_state = "eyes"
	gender = PLURAL
	organ_tag = "eyes"
	parent_organ = "head"
	var/list/eye_colour = list(0,0,0)

/obj/item/organ/eyes/proc/update_colour()
	if(!owner)
		return
	eye_colour = list(
		owner.r_eyes ? owner.r_eyes : FALSE,
		owner.g_eyes ? owner.g_eyes : FALSE,
		owner.b_eyes ? owner.b_eyes : FALSE
		)

/obj/item/organ/eyes/take_damage(amount, var/silent=0)
	var/oldbroken = is_broken()
	..()
	if(is_broken() && !oldbroken && owner && !owner.stat)
		owner << "<span class='danger'>You go blind!</span>"

/obj/item/organ/eyes/process() //Eye damage replaces the old eye_stat var.
	..()
	if(!owner)
		return
	if(is_bruised())
		owner.eye_blurry = 20
	if(is_broken())
		owner.eye_blind = 20

/obj/item/organ/liver
	name = "liver"
	icon_state = "liver"
	organ_tag = "liver"
	parent_organ = "groin"

/obj/item/organ/liver/process()

	..()

	if(!owner)
		return

	if (germ_level > INFECTION_LEVEL_ONE)
		if(sprob(1))
			owner << "<span class = 'red'>Your skin itches.</span>"
	if (germ_level > INFECTION_LEVEL_TWO)
		if(sprob(1))
			spawn owner.vomit()

	if(owner.life_tick % PROCESS_ACCURACY == FALSE)

		//High toxins levels are dangerous
		if(owner.getToxLoss() >= 60 && !owner.reagents.has_reagent("anti_toxin"))
			//Healthy liver suffers on its own
			if (damage < min_broken_damage)
				damage += 0.2 * PROCESS_ACCURACY
			//Damaged one shares the fun
			else
				var/obj/item/organ/O = spick(owner.internal_organs)
				if(O)
					O.damage += 0.2  * PROCESS_ACCURACY

		//Detox can heal small amounts of damage
		if (damage && damage < min_bruised_damage && owner.reagents.has_reagent("anti_toxin"))
			damage -= 0.2 * PROCESS_ACCURACY

		if(damage < 0)
			damage = FALSE

		// Get the effectiveness of the liver.
		var/filter_effect = 3
		if(is_bruised())
			filter_effect -= 1
		if(is_broken())
			filter_effect -= 2

		// Do some reagent processing.
		if(owner.chem_effects[CE_ALCOHOL_TOXIC])
			if(filter_effect < 3)
				owner.adjustToxLoss(owner.chem_effects[CE_ALCOHOL_TOXIC] * 0.1 * PROCESS_ACCURACY)
			else
				take_damage(owner.chem_effects[CE_ALCOHOL_TOXIC] * 0.1 * PROCESS_ACCURACY, sprob(1)) // Chance to warn them

/obj/item/organ/appendix
	name = "appendix"
	icon_state = "appendix"
	parent_organ = "groin"
	organ_tag = "appendix"
	var/inflamed = FALSE

/obj/item/organ/appendix/update_icon()
	..()
	if(inflamed)
		icon_state = "appendixinflamed"
		name = "inflamed appendix"

/obj/item/organ/appendix/process()
	..()
	if(inflamed && owner)
		inflamed++
		if(sprob(5))
			owner << "<span class='warning'>You feel a stinging pain in your abdomen!</span>"
			owner.emote("me",1,"winces slightly.")
		if(inflamed > 200)
			if(sprob(3))
				take_damage(0.1)
				owner.emote("me",1,"winces painfully.")
				owner.adjustToxLoss(1)
		if(inflamed > 400)
			if(sprob(1))
				germ_level += srand(2,6)
				if (owner.nutrition > 100)
					owner.vomit()
				else
					owner << "<span class='danger'>You gag as you want to throw up, but there's nothing in your stomach!</span>"
					owner.Weaken(10)
		if(inflamed > 600)
			if(sprob(1))
				owner << "<span class='danger'>Your abdomen is a world of pain!</span>"
				owner.Weaken(10)

				var/obj/item/organ/external/E = owner.get_organ(parent_organ)
				var/datum/wound/W = new /datum/wound/internal_bleeding(20)
				E.wounds += W
				E.germ_level = max(INFECTION_LEVEL_TWO, E.germ_level)
				owner.adjustToxLoss(25)
				removed()
				qdel(src)
