//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:32

/obj/item/assembly/infra
	name = "infrared emitter"
	desc = "Emits a visible or invisible beam and is triggered when the beam is interrupted."
	icon_state = "infrared"
//	origin_tech = list(TECH_MAGNET = 2)
	matter = list(DEFAULT_WALL_MATERIAL = 1000, "glass" = 500, "waste" = 100)

	wires = WIRE_PULSE

	secured = FALSE

	var/on = FALSE
	var/visible = FALSE
	var/obj/effect/beam/i_beam/first = null

	proc
		trigger_beam()


	activate()
		if(!..())	return FALSE//Cooldown check
		on = !on
		update_icon()
		return TRUE


	toggle_secure()
		secured = !secured
		if(secured)
			processing_objects.Add(src)
		else
			on = FALSE
			if(first)	qdel(first)
			processing_objects.Remove(src)
		update_icon()
		return secured


	update_icon()
		overlays.Cut()
		attached_overlays = list()
		if(on)
			overlays += "infrared_on"
			attached_overlays += "infrared_on"

		if(holder)
			holder.update_icon()
		return


	process()//Old code
		if(!on)
			if(first)
				qdel(first)
				return

		if((!(first) && (secured && (istype(loc, /turf) || (holder && istype(holder.loc, /turf))))))
			var/obj/effect/beam/i_beam/I = new /obj/effect/beam/i_beam((holder ? holder.loc : loc) )
			I.master = src
			I.density = TRUE
			I.set_dir(dir)
			step(I, I.dir)
			if(I)
				I.density = FALSE
				first = I
				I.vis_spread(visible)
				spawn(0)
					if(I)
						//world << "infra: setting limit"
						I.limit = 8
						//world << "infra: processing beam \ref[I]"
						I.process()
					return
		return


	attack_hand()
		qdel(first)
		..()
		return


	Move()
		var/t = dir
		..()
		set_dir(t)
		qdel(first)
		return


	holder_movement()
		if(!holder)	return FALSE
//		set_dir(holder.dir)
		qdel(first)
		return TRUE


	trigger_beam()
		if((!secured)||(!on)||(cooldown > 0))	return FALSE
		pulse(0)
		if(!holder)
			visible_message("\icon[src] *beep* *beep*")
		cooldown = 2
		spawn(10)
			process_cooldown()
		return


	interact(mob/user as mob)//TODO: change this this to the wire control panel
		if(!secured)	return
		user.set_machine(src)
		var/dat = text("<TT><b>Infrared Laser</b>\n<b>Status</b>: []<BR>\n<b>Visibility</b>: []<BR>\n</TT>", (on ? text("<A href='?src=\ref[];state=0'>On</A>", src) : text("<A href='?src=\ref[];state=1'>Off</A>", src)), (visible ? text("<A href='?src=\ref[];visible=0'>Visible</A>", src) : text("<A href='?src=\ref[];visible=1'>Invisible</A>", src)))
		dat += "<BR><BR><A href='?src=\ref[src];refresh=1'>Refresh</A>"
		dat += "<BR><BR><A href='?src=\ref[src];close=1'>Close</A>"
		user << browse(dat, "window=infra")
		onclose(user, "infra")
		return


	Topic(href, href_list)
		if(..()) return TRUE
		if(!usr.canmove || usr.stat || usr.restrained() || !in_range(loc, usr))
			usr << browse(null, "window=infra")
			onclose(usr, "infra")
			return

		if(href_list["state"])
			on = !(on)
			update_icon()

		if(href_list["visible"])
			visible = !(visible)
			spawn(0)
				if(first)
					first.vis_spread(visible)

		if(href_list["close"])
			usr << browse(null, "window=infra")
			return

		if(usr)
			attack_self(usr)

		return


	verb/rotate()//This could likely be better
		set name = "Rotate Infrared Laser"
		set category = null
		set src in usr

		set_dir(turn(dir, 90))
		return



/***************************IBeam*********************************/

/obj/effect/beam/i_beam
	name = "i beam"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "ibeam"
	var/obj/effect/beam/i_beam/next = null
	var/obj/item/assembly/infra/master = null
	var/limit = null
	var/visible = 0.0
	var/left = null
	anchored = 1.0


/obj/effect/beam/i_beam/proc/hit()
	if(master)
		master.trigger_beam()
	qdel(src)
	return

/obj/effect/beam/i_beam/proc/vis_spread(v)
	//world << "i_beam \ref[src] : vis_spread"
	visible = v
	spawn(0)
		if(next)
			//world << "i_beam \ref[src] : is next [next.type] \ref[next], calling spread"
			next.vis_spread(v)
		return
	return

/obj/effect/beam/i_beam/process()

	if((loc && loc.density) || !master)
		qdel(src)
		return

	if(left > 0)
		left--
	if(left < 1)
		if(!(visible))
			invisibility = 101
		else
			invisibility = FALSE
	else
		invisibility = FALSE


	//world << "now [left] left"
	var/obj/effect/beam/i_beam/I = new /obj/effect/beam/i_beam(loc)
	I.master = master
	I.density = TRUE
	I.set_dir(dir)
	//world << "created new beam \ref[I] at [I.x] [I.y] [I.z]"
	step(I, I.dir)

	if(I)
		//world << "step worked, now at [I.x] [I.y] [I.z]"
		if(!(next))
			//world << "no next"
			I.density = FALSE
			//world << "spreading"
			I.vis_spread(visible)
			next = I
			spawn(0)
				//world << "limit = [limit] "
				if((I && limit > 0))
					I.limit = limit - 1
					//world << "calling next process"
					I.process()
				return
		else
			//world << "is a next: \ref[next], deleting beam \ref[I]"
			qdel(I)
	else
		//world << "step failed, deleting \ref[next]"
		qdel(next)
	spawn(10)
		process()
		return
	return

/obj/effect/beam/i_beam/Bump()
	qdel(src)
	return

/obj/effect/beam/i_beam/Bumped()
	hit()
	return

/obj/effect/beam/i_beam/Crossed(atom/movable/AM as mob|obj)
	if(istype(AM, /obj/effect/beam))
		return
	spawn(0)
		hit()
		return
	return

/obj/effect/beam/i_beam/Destroy()
	if(master.first == src)
		master.first = null
	if(next)
		qdel(next)
		next = null
	..()
