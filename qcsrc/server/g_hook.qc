/*============================================

      Wazat's Nexuiz Grappling Hook

        Contact: Wazat1@gmail.com


Installation instructions:
--------------------------

1. Place hook.c in your gamec source directory with the other source files.

2. Add this line to the bottom of progs.src:

gamec/hook.c

3. Open defs.h and add these lines to the very bottom:

// Wazat's grappling hook
.entity		hook;
void GrapplingHookFrame();
void RemoveGrapplingHook(entity pl);
void SetGrappleHookBindings();
// hook impulses
float GRAPHOOK_FIRE		= 20;
float GRAPHOOK_RELEASE		= 21;
// (note: you can change the hook impulse #'s to whatever you please)

4. Open client.c and add this to the top of PutClientInServer():

	RemoveGrapplingHook(self); // Wazat's Grappling Hook

5. Find ClientConnect() (in client.c) and add these lines to the bottom:

	// Wazat's grappling hook
	SetGrappleHookBindings();

6. Still in client.c, find PlayerPreThink and add this line just above the call to W_WeaponFrame:

 	GrapplingHookFrame();

7. Build and test the mod.  You'll want to bind a key to "+hook" like this:
bind ctrl "+hook"

And you should be done!


============================================*/

float g_balance_grapplehook_airfriction;
float g_balance_grapplehook_damage;
float g_balance_grapplehook_damage_interval;
float g_balance_grapplehook_dontpull;
float g_balance_grapplehook_force_rubber;
float g_balance_grapplehook_force_rubber_overstretch;
float g_balance_grapplehook_gravity;
float g_balance_grapplehook_health;
float g_balance_grapplehook_length_min;
float g_balance_grapplehook_speed_fly;
float g_balance_grapplehook_speed_pull;
float g_balance_grapplehook_stretch;
float g_grappling_hook_tarzan;
vector hook_shotorigin;

.string aiment_classname;
.float aiment_deadflag;
.float hook_attack_time;
.float hookable;

void SetMovetypeFollow(entity ent, entity e)
{
	ent.movetype = MOVETYPE_FOLLOW; // make the hole follow
	ent.solid = SOLID_NOT; // MOVETYPE_FOLLOW is always non-solid
	ent.aiment = e; // make the hole follow bmodel
	if (ent.aiment.takedamage)
		ent.hook_attack_time = time + g_balance_grapplehook_damage_interval;
	ent.punchangle = e.angles; // the original angles of bmodel
	ent.view_ofs = ent.origin - e.origin; // relative origin
	ent.v_angle = ent.angles - e.angles; // relative angles
	ent.aiment_classname = strzone(e.classname);
	ent.aiment_deadflag = e.deadflag;
}
void UnsetMovetypeFollow(entity ent)
{
	ent.hook_attack_time = 0;
	ent.movetype = MOVETYPE_FLY;
	PROJECTILE_MAKETRIGGER(ent);
	ent.aiment = world;
}
float LostMovetypeFollow(entity ent)
{
/*
	if(ent.movetype != MOVETYPE_FOLLOW)
		if(ent.aiment)
			error("???");
*/
	if(ent.aiment)
	{
		if(ent.aiment.classname != ent.aiment_classname)
			return 1;
		if(ent.aiment.deadflag != ent.aiment_deadflag)
			return 1;
	}
	return 0;
}

.float hook_length;
.float hook_switchweapon;

void RemoveGrapplingHook(entity pl)
{
	if(pl.hook == world)
		return;
	remove(pl.hook);
	pl.hook = world;
	if(pl.movetype == MOVETYPE_FLY)
		pl.movetype = MOVETYPE_WALK;

	//pl.disableclientprediction = FALSE;
}

void GrapplingHookThink();
void GrapplingHook_Stop()
{
	pointparticles(particleeffectnum("grapple_impact"), self.origin, '0 0 0', 1);
	sound (self, CHAN_PROJECTILE, "weapons/hook_impact.wav", VOL_BASE, ATTN_NORM);

	self.state = 1;
	self.think = GrapplingHookThink;
	self.nextthink = time;
	self.touch = SUB_Null;
	self.velocity = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.hook_length = -1;
}

void GrapplingHookThink()
{
	float spd, dist, newlength;
	vector dir, org, end, v0, dv;
	if(PLAYER_DEAD(self.owner) || self.owner.hook != self)	// how did that happen?
	{														// well, better fix it anyway
		remove(self);
		return;
	}
	if(LostMovetypeFollow(self))
	{
		RemoveGrapplingHook(self.owner);
		return;
	}

	self.nextthink = time;

	makevectors(self.owner.v_angle);
	org = self.owner.origin + self.owner.view_ofs + v_forward * hook_shotorigin_x + v_right * hook_shotorigin_y + v_up * hook_shotorigin_z;

#if 0
	tracebox(org, self.mins, self.maxs, self.origin, MOVE_NOMONSTERS, self.owner);
	// do not hit players with this, as they tend to get in the way just too often
	// NOTE: this assumes sky brushes cannot get in the way
	// if they can, assume the map is broken! :P
	if(trace_fraction < 1 && (!self.aiment || trace_ent != self.aiment))
	{
		// 0. stop it
		if(self.state != 1)
			GrapplingHook_Stop();

		// 1. detach the hook
		if(self.aiment)
			UnsetMovetypeFollow(self);

		// 2. cut it off
		setorigin(self, trace_endpos);

		// 3. reattach the hook
		if(trace_ent)
			if(trace_ent.movetype != MOVETYPE_NONE)
				SetMovetypeFollow(self, trace_ent);
	}
#endif

	if(self.hook_length < 0)
		self.hook_length = vlen(org - self.origin);

	if(self.state == 1)
	{
		dir = self.origin - org;
		dist = vlen(dir);
		dir = normalize(dir);

		if (self.aiment) {
			if not(PlayerCanFire(self.owner, FALSE)) {
				RemoveGrapplingHook(self.owner);
				return;
			}
			if (g_balance_grapplehook_damage_interval)
			if (self.hook_attack_time)
			if (self.aiment.takedamage)
			while (self.hook_attack_time <= time)
			{
				Damage(self.aiment, self.owner, self.owner, g_balance_grapplehook_damage, WEP_HOOK, self.origin, '0 0 0');
				self.hook_attack_time += g_balance_grapplehook_damage_interval;
			}
		}

		if(g_grappling_hook_tarzan)
		{
			v0 = self.owner.velocity;

			// first pull the rope...
			if(self.owner.hook_state & HOOK_PULLING)
			{
				newlength = self.hook_length;
				newlength = max(newlength - g_balance_grapplehook_speed_pull * frametime, g_balance_grapplehook_length_min);

				if(newlength < dist - g_balance_grapplehook_stretch) // overstretched?
				{
					newlength = dist - g_balance_grapplehook_stretch;
					if(self.owner.velocity * dir < 0) // only if not already moving in hook direction
						self.owner.velocity = self.owner.velocity + frametime * dir * g_balance_grapplehook_force_rubber_overstretch;
				}

				self.hook_length = newlength;
			}

			if(self.owner.hook_state & HOOK_RELEASING)
			{
				newlength = dist;
				self.hook_length = newlength;
			}
			else
			{
				// then pull the player
				spd = bound(0, (dist - self.hook_length) / g_balance_grapplehook_stretch, 1);
				if not(g_balance_grapplehook_dontpull) {
					self.owner.velocity = self.owner.velocity * (1 - frametime * g_balance_grapplehook_airfriction);
					self.owner.velocity = self.owner.velocity + frametime * dir * spd * g_balance_grapplehook_force_rubber;
					self.owner.flags &~= FL_ONGROUND;
				}

				dv = ((self.owner.velocity - v0) * dir) * dir;
				if(g_grappling_hook_tarzan >= 2)
				{
					if(self.aiment.movetype == MOVETYPE_WALK || self.aiment.hookable)
					{
						self.owner.velocity = self.owner.velocity - dv * 0.5;
						self.aiment.velocity = self.aiment.velocity - dv * 0.5;
						self.aiment.flags &~= FL_ONGROUND;
						self.aiment.pusher = self.owner;
						self.aiment.pushltime = time + g_maxpushtime;
					}
				}
			}
		}
		else
		{
			end = self.origin - dir*50;
			dist = vlen(end - org);
			if(dist < 200)
				spd = dist * (g_balance_grapplehook_speed_pull / 200);
			else
				spd = g_balance_grapplehook_speed_pull;
			if(spd < 50)
				spd = 0;
			self.owner.velocity = dir*spd;
			self.owner.movetype = MOVETYPE_FLY;

			self.owner.flags &~= FL_ONGROUND;
		}
	}

	makevectors(self.angles_x * '-1 0 0' + self.angles_y * '0 1 0');
	te_beam(self.owner, self.origin + v_forward * (-9), org);
}

void GrapplingHookTouch (void)
{
	if(SUB_OwnerCheck())
		return;
	if(SUB_NoImpactCheck())
	{
		RemoveGrapplingHook(self.owner);
		return;
	}

	if(other == world)
	{
		vector tic;
		tic = self.velocity * sys_ticrate;
		tic = tic + normalize(tic) * vlen(self.maxs - self.mins);
		traceline(self.origin - tic, self.origin + tic, MOVE_NORMAL, self);
		if(trace_fraction >= 1)
		{
			dprint("Odd... did not hit...?\n");
		}
		else if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
		{
			dprint("Detected and prevented the sky-grapple bug.\n");
			RemoveGrapplingHook(self.owner);
			return;
		}
	}

	GrapplingHook_Stop();

	if(other)
		if(other.movetype != MOVETYPE_NONE)
			SetMovetypeFollow(self, other);

	//self.owner.disableclientprediction = TRUE;
}

void GrapplingHook_Damage (entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if(self.health > 0)
	{
		self.health = self.health - damage;
		if (self.health <= 0)
		{
			if(attacker != self.owner)
			{
				self.owner.pusher = attacker;
				self.owner.pushltime = time + g_maxpushtime;
			}
			RemoveGrapplingHook(self.owner);
		}
	}
}

void FireGrapplingHook (void)
{
	local entity missile;
	local vector org;

	makevectors(self.v_angle);

	// UGLY WORKAROUND: play this on CHAN_WEAPON2 so it can't cut off fire sounds
	sound (self, CHAN_WEAPON2, "weapons/hook_fire.wav", VOL_BASE, ATTN_NORM);
	org = self.origin + self.view_ofs + v_forward * hook_shotorigin_x + v_right * hook_shotorigin_y + v_up * hook_shotorigin_z;
	pointparticles(particleeffectnum("grapple_muzzleflash"), org, '0 0 0', 1);

	missile = spawn ();
	missile.owner = self;
	self.hook = missile;
	missile.classname = "grapplinghook";

	missile.movetype = (g_balance_grapplehook_gravity ? MOVETYPE_TOSS : MOVETYPE_FLY);
	PROJECTILE_MAKETRIGGER(missile);

	setmodel (missile, "models/hook.md3"); // precision set below
	setsize (missile, '-3 -3 -3', '3 3 3');
	setorigin (missile, org);

	missile.state = 0; // not latched onto anything

	missile.velocity = v_forward * g_balance_grapplehook_speed_fly;
	W_SetupProjectileVelocity(missile);

	missile.angles = vectoangles (missile.velocity);
	//missile.glow_color = 250; // 244, 250
	//missile.glow_size = 120;
	missile.touch = GrapplingHookTouch;
	missile.think = GrapplingHookThink;
	missile.nextthink = time + 0.1;

	missile.effects = /*EF_FULLBRIGHT | EF_ADDITIVE |*/ EF_LOWPRECISION;

	missile.health = g_balance_grapplehook_health;//120
	missile.event_damage = GrapplingHook_Damage;
	missile.takedamage = DAMAGE_AIM;
	missile.damageforcescale = 0;
}

//  void GrapplingHookFrame()
//  {
//         // this function has been modified for Nexuiz
// -       if (self.BUTTON_HOOK && g_grappling_hook)
//         {
// -               if (!self.hook && self.hook_time <= time && !self.button6_pressed_before)
// -                       if (timeoutStatus != 2) //only allow the player to fire the grappling hook if the game is not paused (timeout)
// -                               FireGrapplingHook();
//         }
// -       else
//         {
//                 if (self.hook)
//                         RemoveGrapplingHook(self);
//         }
// -       self.button6_pressed_before = self.BUTTON_HOOK;
//         /*
//         // if I have no hook or it's not pulling yet, make sure I'm not flying!
//         if((self.hook == world || !self.hook.state) && self.movetype == MOVETYPE_FLY)

void GrapplingHookFrame()
{
	float button_hook = BUTTON_HOOK_PRESSED;
	if(g_grappling_hook && timeoutStatus != 2 && self.weapon != WEP_HOOK)
	{
		// offhand hook controls
		if(button_hook)
		{
			if not(self.hook || (self.hook_state & HOOK_WAITING_FOR_RELEASE))
			if (time > game_starttime)
			{
				self.hook_state |= HOOK_FIRING;
				self.hook_state |= HOOK_WAITING_FOR_RELEASE;
			}
		}
		else
		{
			self.hook_state |= HOOK_REMOVING;
			self.hook_state &~= HOOK_WAITING_FOR_RELEASE;
		}

		self.hook_state &~= HOOK_RELEASING;
		if(self.BUTTON_CROUCH)
		{
			self.hook_state &~= HOOK_PULLING;
			//self.hook_state |= HOOK_RELEASING;
		}
		else
		{
			self.hook_state |= HOOK_PULLING;
			//self.hook_state &~= HOOK_RELEASING;
		}
	}
	else if(!(self.items & IT_JETPACK) && !g_grappling_hook && self.switchweapon != WEP_HOOK)
	{
		if(button_hook && !self.hook_switchweapon)
			W_SwitchWeapon(WEP_HOOK);
	}
	self.hook_switchweapon = button_hook;

	if(!g_grappling_hook && self.weapon != WEP_HOOK)
	{
		self.hook_state &~= HOOK_FIRING;
		self.hook_state |= HOOK_REMOVING;
	}

	if (self.hook_state & HOOK_FIRING)
	{
		if (self.hook)
			RemoveGrapplingHook(self);
		FireGrapplingHook();
		self.hook_state &~= HOOK_FIRING;
	}
	else if(self.hook_state & HOOK_REMOVING)
	{
		if (self.hook)
			RemoveGrapplingHook(self);
		self.hook_state &~= HOOK_REMOVING;
	}

	/*
	// if I have no hook or it's not pulling yet, make sure I'm not flying!
	if((self.hook == world || !self.hook.state) && self.movetype == MOVETYPE_FLY)
	{
		self.movetype = MOVETYPE_WALK;
	}
	if(self.impulse == GRAPHOOK_FIRE && self.hook_time <= time && g_grappling_hook)
	{
		// fire hook
		FireGrapplingHook();
		return;
	}
	else if(self.hookimpulse == GRAPHOOK_RELEASE)
	{
		// remove hook, reset movement type
		RemoveGrapplingHook(self);
		return;
	}
	*/
	/*else // make sure the player's movetype is correct
	{
		//if(self.hook == world && self.movetype == MOVETYPE_FLY)
		if((self.hook == world || !self.hook.state) && self.movetype == MOVETYPE_FLY)
		{
			self.movetype = MOVETYPE_WALK;
		}
	}*/
	// note: The hook entity does the actual pulling
}

void GrappleHookInit()
{
	CACHE_CVAR(g_balance_grapplehook_airfriction);
	CACHE_CVAR(g_balance_grapplehook_damage);
	CACHE_CVAR(g_balance_grapplehook_damage_interval);
	CACHE_CVAR(g_balance_grapplehook_dontpull);
	CACHE_CVAR(g_balance_grapplehook_force_rubber);
	CACHE_CVAR(g_balance_grapplehook_force_rubber_overstretch);
	CACHE_CVAR(g_balance_grapplehook_gravity);
	CACHE_CVAR(g_balance_grapplehook_health);
	CACHE_CVAR(g_balance_grapplehook_length_min);
	CACHE_CVAR(g_balance_grapplehook_speed_fly);
	CACHE_CVAR(g_balance_grapplehook_speed_pull);
	CACHE_CVAR(g_balance_grapplehook_stretch);
	CACHE_CVAR(g_grappling_hook_tarzan);
	if(g_grappling_hook)
		hook_shotorigin = '8 -8 -12';
	else
		hook_shotorigin = shotorg_adjust('26.2148 9.2059 -15.9772', TRUE, FALSE, FALSE);
}

void SetGrappleHookBindings()
{
	// this function has been modified for Nexuiz
	// don't remove these lines! old server or demos coud overwrite the new aliases
	stuffcmd(self, "alias +hook +button6\n");
	stuffcmd(self, "alias -hook -button6\n");
}
