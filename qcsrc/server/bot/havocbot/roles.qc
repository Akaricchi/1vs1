float bot_ai_friends_aware_pickup_radius;

.float max_armorvalue;
.float havocbot_role_timeout;

.void() havocbot_previous_role;
.void() havocbot_role;

void havocbot_goalrating_items(float ratingscale, vector org, float sradius)
{
	local entity head;
	local entity player;
	local float rating, d, discard, distance, friend_distance, enemy_distance;
	ratingscale = ratingscale * 0.0001; // items are rated around 10000 already
	head = findchainfloat(bot_pickup, TRUE);

	while (head)
	{
		distance = vlen(head.origin - org);
		friend_distance = 10000; enemy_distance = 10000;
		rating = 0;

		if(!head.solid || distance > sradius || (head == self.ignoregoal && time < self.ignoregoaltime) )
		{
			head = head.chain;
			continue;
		}

		// Check if the item can be picked up safely
		if(head.classname == "droppedweapon")
		{
			traceline(head.origin, head.origin + '0 0 -1500', TRUE, world);

			d = pointcontents(trace_endpos + '0 0 1');
			if(d & CONTENT_WATER || d & CONTENT_SLIME || d & CONTENT_LAVA)
			{
				head = head.chain;
				continue;
			}
			if(tracebox_hits_trigger_hurt(head.origin, head.mins, head.maxs, trace_endpos))
			{
				head = head.chain;
				continue;
			}
		}
		else
		{
			// Ignore items under water
			traceline(head.origin + head.maxs, head.origin + head.maxs, MOVE_NORMAL, head);
			if(trace_dpstartcontents & DPCONTENTS_LIQUIDSMASK)
			{
				head = head.chain;
				continue;
			}
		}

		if(teams_matter)
		{
			discard = FALSE;

			FOR_EACH_PLAYER(player)
			{

				if ( self == player || player.deadflag )
					continue;

				d = vlen(player.origin - head.origin); // distance between player and item

				if ( player.team == self.team )
				{
					if ( clienttype(player) != CLIENTTYPE_REAL || discard )
						continue;

					if( d > friend_distance)
						continue;

					friend_distance = d;

					discard = TRUE;

					if( head.health && player.health > self.health )
						continue;

					if( head.armorvalue && player.armorvalue > self.armorvalue)
						continue;

					if( head.weapons )
					if( (player.weapons & head.weapons) != head.weapons)
						continue;

					if (head.ammo_shells && player.ammo_shells > self.ammo_shells)
						continue;

					if (head.ammo_nails && player.ammo_nails > self.ammo_nails)
						continue;

					if (head.ammo_rockets && player.ammo_rockets > self.ammo_rockets)
						continue;

					if (head.ammo_cells && player.ammo_cells > self.ammo_cells )
						continue;

					discard = FALSE;
				}
				else
				{
					// If enemy only track distances
					// TODO: track only if visible ?
					if( d < enemy_distance )
						enemy_distance = d;
				}
			}

			// Rate the item only if no one needs it, or if an enemy is closer to it
			if ( (enemy_distance < friend_distance && distance < enemy_distance) ||
				(friend_distance > bot_ai_friends_aware_pickup_radius ) || !discard )
				rating = head.bot_pickupevalfunc(self, head);

		}
		else
			rating = head.bot_pickupevalfunc(self, head);

		if(rating > 0)
			navigation_routerating(head, rating * ratingscale, 2000);
		head = head.chain;
	}
};

void havocbot_goalrating_controlpoints_dom(float ratingscale, vector org, float sradius)
{
	local entity head;
	head = findchain(classname, "dom_controlpoint");
	while (head)
	{
		if (vlen(head.origin - org) < sradius)
		{
			if(head.cnt > -1) // this is just being fought for
				navigation_routerating(head, ratingscale, 5000);
			else if(head.goalentity.cnt == 0) // unclaimed point
				navigation_routerating(head, ratingscale * 0.5, 5000);
			else if(head.goalentity.team != self.team) // other team's point
				navigation_routerating(head, ratingscale * 0.2, 5000);
		}
		head = head.chain;
	}
};

void havocbot_goalrating_controlpoints_conq(float ratingscale, vector org, float sradius)
{
	local entity head;
	head = findchain(classname, "conquest_cp");
	while (head)
	{
		if (vlen(head.origin - org) < sradius)
		{
			if(!head.team)
				navigation_routerating(head, ratingscale * 0.5, 5000);
			else if(head.team != self.team) // other team's point
				navigation_routerating(head, ratingscale, 5000);
		}
		head = head.chain;
	}
};

void havocbot_goalrating_frozen_teammates(float ratingscale, vector org, float sradius)
{
	local entity head;
	local float distance;

	// don't chase players if we're under water
	if(self.waterlevel>WATERLEVEL_WETFEET)
		return;

	FOR_EACH_PLAYER(head)
	{
		if (self != head)
		if (head.deadflag == DEAD_FREEZE)
		if (head.team == self.team)
		{
			distance = vlen(head.origin - org);
			if (distance < 50 || distance > sradius)
				continue;

			if(head.flags & FL_INWATER || head.flags & FL_PARTIALGROUND)
				continue;

			// not falling
			if(head.flags & FL_ONGROUND == 0)
				continue;

			navigation_routerating(head, ratingscale, 5000);
			break;
		}
	}
}

void havocbot_goalrating_enemyplayers(float ratingscale, vector org, float sradius)
{
	local entity head;
	local float t, noteam, distance;
	noteam = ((self.team == 0) || !teams_matter); // fteqcc sucks

	if (bot_nofire)
		return;

	// don't chase players if we're under water
	if(self.waterlevel>WATERLEVEL_WETFEET)
		return;

	FOR_EACH_PLAYER(head)
	{
		// TODO: Merge this logic with the bot_shouldattack function
		if (self != head)
		if (head.health > 0)
		if ((noteam && (!bot_ignore_bots || clienttype(head) == CLIENTTYPE_REAL)) || head.team != self.team)
		{
			distance = vlen(head.origin - org);
			if (distance < 100 || distance > sradius)
				continue;

			if(g_minstagib)
			if(head.items & IT_STRENGTH)
				continue;

			// rate only visible enemies
			/*
			traceline(self.origin + self.view_ofs, head.origin, MOVE_NOMONSTERS, self);
			if (trace_fraction < 1 || trace_ent != head)
				continue;
			*/

			if(head.flags & FL_INWATER || head.flags & FL_PARTIALGROUND)
				continue;

			// not falling
			if(head.flags & FL_ONGROUND == 0)
			{
				traceline(head.origin, head.origin + '0 0 -1500', TRUE, world);
				t = pointcontents(trace_endpos + '0 0 1');
				if( t != CONTENT_SOLID )
				if(t & CONTENT_WATER || t & CONTENT_SLIME || t & CONTENT_LAVA)
					continue;
				if(tracebox_hits_trigger_hurt(head.origin, head.mins, head.maxs, trace_endpos))
					continue;
			}

			t = (self.health + self.armorvalue ) / (head.health + head.armorvalue );
			navigation_routerating(head, t * ratingscale, 2000);
		}
	}
};

// choose a role according to the situation
void() havocbot_role_dm;

//DOM:
//go to best items, or control points you don't own
void havocbot_role_dom()
{
	if(self.deadflag != DEAD_NO)
		return;

	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		havocbot_goalrating_controlpoints_dom(10000, self.origin, 15000);
		havocbot_goalrating_items(8000, self.origin, 8000);
		//havocbot_goalrating_enemyplayers(3000, self.origin, 2000);
		//havocbot_goalrating_waypoints(1, self.origin, 1000);
		navigation_goalrating_end();
	}
};

//FT:
void havocbot_role_ft()
{
	if(self.deadflag != DEAD_NO)
		return;

	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		havocbot_goalrating_frozen_teammates(15000, self.origin, 8000);
		havocbot_goalrating_items(8000, self.origin, 8000);
		havocbot_goalrating_enemyplayers(8000, self.origin, 2000);
		//havocbot_goalrating_waypoints(1, self.origin, 1000);
		navigation_goalrating_end();
	}
};

//Conquest:
void havocbot_role_conquest()
{
	if(self.deadflag != DEAD_NO)
		return;

	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		havocbot_goalrating_controlpoints_conq(25000, self.origin, 15000);
		havocbot_goalrating_items(8000, self.origin, 8000);
		havocbot_goalrating_enemyplayers(8000, self.origin, 2000);
		//havocbot_goalrating_waypoints(1, self.origin, 1000);
		navigation_goalrating_end();
	}
};

//DM:
//go to best items
void havocbot_role_dm()
{
	if(self.deadflag != DEAD_NO)
		return;

	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		havocbot_goalrating_items(10000, self.origin, 10000);
		havocbot_goalrating_enemyplayers(20000, self.origin, 10000);
		//havocbot_goalrating_waypoints(1, self.origin, 1000);
		navigation_goalrating_end();
	}
};

//Race:
//go to next checkpoint, and annoy enemies
.float race_checkpoint;
void havocbot_role_race()
{
	if(self.deadflag != DEAD_NO)
		return;

	entity e;
	if (self.bot_strategytime < time)
	{
		self.bot_strategytime = time + bot_ai_strategyinterval;
		navigation_goalrating_start();
		/*
		havocbot_goalrating_items(100, self.origin, 10000);
		havocbot_goalrating_enemyplayers(500, self.origin, 20000);
		*/

		for(e = world; (e = find(e, classname, "trigger_race_checkpoint")) != world; )
		{
			if(e.cnt == self.race_checkpoint)
			{
				navigation_routerating(e, 1000000, 5000);
			}
			else if(self.race_checkpoint == -1)
			{
				navigation_routerating(e, 1000000, 5000);
			}
		}

		navigation_goalrating_end();
	}
};

void havocbot_chooserole_dm()
{
	self.havocbot_role = havocbot_role_dm;
};

void havocbot_chooserole_race()
{
	self.havocbot_role = havocbot_role_race;
};

void havocbot_chooserole_dom()
{
	self.havocbot_role = havocbot_role_dom;
};

void havocbot_chooserole_ft()
{
	self.havocbot_role = havocbot_role_ft;
};

void havocbot_chooserole_conquest()
{
	self.havocbot_role = havocbot_role_conquest;
};

void havocbot_chooserole()
{
	dprint("choosing a role...\n");
	navigation_clearroute();
	self.bot_strategytime = 0;
	if (g_ctf)
		havocbot_chooserole_ctf();
	else if (g_domination)
		havocbot_chooserole_dom();
	else if (g_keyhunt)
		havocbot_chooserole_kh();
	else if (g_race || g_cts)
		havocbot_chooserole_race();
	else if (g_onslaught)
		havocbot_chooserole_ons();
	else if (g_conquest)
		havocbot_chooserole_conquest();
	else if (g_freeze)
		havocbot_chooserole_ft();
	else // assume anything else is deathmatch
		havocbot_chooserole_dm();
};

void havocbot_role_init()
{
	CACHE_CVAR(bot_ai_friends_aware_pickup_radius);
};
