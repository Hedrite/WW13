// ported from /tg/station. Now a process since apparently we don't have functioning subsystems? - Kachnov

#define MC_AVERAGE_FAST(average, current) (0.7 * (average) + 0.3 * (current))
#define MC_AVERAGE(average, current) (0.8 * (average) + 0.2 * (current))
#define MC_AVERAGE_SLOW(average, current) (0.9 * (average) + 0.1 * (current))

var/datum/controller/process/time_track/time_track = null

/datum/controller/process/time_track
	var/time_dilation_current = 0

	var/time_dilation_avg_fast = 0
	var/time_dilation_avg = 0
	var/time_dilation_avg_slow = 0

	var/first_run = TRUE

	var/last_tick_realtime = 0
	var/last_tick_byond_time = 0
	var/last_tick_tickcount = 0

	var/time_elapsed = 0

/datum/controller/process/time_track/setup()
	name = "Time Tracking"
	schedule_interval = 50

	if (!time_track)
		time_track = src

/datum/controller/process/time_track/doWork()
	..()

	if (!time_elapsed)
		time_elapsed = world.time

	var/current_realtime = time_elapsed // fake real time of day. somewhat flawed because it assumes we doWork() at the right time
	var/current_byondtime = world.time
	var/current_tickcount = world.time/world.tick_lag

	if (!first_run)
		var/tick_drift = max(0, (((current_realtime - last_tick_realtime) - (current_byondtime - last_tick_byond_time)) / world.tick_lag))

		time_dilation_current = tick_drift / (current_tickcount - last_tick_tickcount) * 100

		time_dilation_avg_fast = MC_AVERAGE_FAST(time_dilation_avg_fast, time_dilation_current)
		time_dilation_avg = MC_AVERAGE(time_dilation_avg, time_dilation_avg_fast)
		time_dilation_avg_slow = MC_AVERAGE_SLOW(time_dilation_avg_slow, time_dilation_avg)
	else
		first_run = FALSE

	last_tick_realtime = current_realtime
	last_tick_byond_time = current_byondtime
	last_tick_tickcount = current_tickcount

	time_elapsed += schedule_interval