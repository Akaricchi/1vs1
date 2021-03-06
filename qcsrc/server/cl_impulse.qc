// from dpmod
void printsurfaceinfo(entity e, vector v)
{
	local float surfnum, numpoints, vnum;
	local string s;
	local vector n;
	surfnum = getsurfacenearpoint(e, v);
	if (surfnum >= 0)
	{
		sprint(self, "texture: ");
		s = getsurfacetexture(e, surfnum);
		sprint(self, s);
		sprint(self, " normal: ");
		n = getsurfacenormal(e, surfnum);
		sprint(self, vtos(n));
		sprint(self, " ");
		numpoints = getsurfacenumpoints(e, surfnum);
		sprint(self, ftos(numpoints));
		sprint(self, " verts:");
		vnum = 0;
		while (vnum < numpoints)
		{
			sprint(self, " ");
			n = getsurfacepoint(e, surfnum, vnum);
			sprint(self, vtos(n));
			vnum = vnum + 1;
		}
		sprint(self, " point tested: ");
		sprint(self, vtos(v));
		sprint(self, " nearest point on surface: ");
		n = getsurfaceclippedpoint(e, surfnum, v);
		sprint(self, vtos(n));
		sprint(self, "\n");
	}
};

/*
 * Impulse map:
 *
 * 0 reserved (no input)
 * 1 to 9, 14: weapon shortcuts
 * 10: next weapon according to linear list
 * 11: most recently used weapon
 * 12: previous weapon according to linear list
 * 13: best weapon according to priority list
 * 15: next weapon according to priority list
 * 16: previous weapon according to priority list
 * 17: throw weapon
 * 18: next weapon according to sbar_hudselector 1 list
 * 19: previous weapon according to sbar_hudselector 1 list
 * 20: reload if needed
 *
 * 30 to 39: create waypoints
 * 47: clear personal waypoints
 * 48: clear team waypoints
 *
 * TODO:
 * 200 to 209: prev weapon shortcuts
 * 210 to 219: best weapon shortcuts
 * 220 to 229: next weapon shortcuts
 * 230 to 253: individual weapons (up to 24)
 */

void ImpulseCommands (void)
{
	local float imp;
	vector org;
	float i;
	float m;
	entity e, e2;

	imp = self.impulse;
	if (!imp || gameover)
		return;
	self.impulse = 0;

	if (timeoutStatus == 2) //don't allow any impulses while the game is paused
		return;

	if (imp >= 1 && imp <= 9)
	{
		// weapon switching impulses
		if(self.deadflag == DEAD_NO)
			W_NextWeaponOnImpulse(imp);
		else
			self.impulse = imp; // retry in next frame
	}
	else if(imp >= 10 && imp <= 20)
	{
		if(self.deadflag == DEAD_NO)
		{
			switch(imp)
			{
				case 10:
					W_NextWeapon (0);
					break;
				case 11:
					W_SwitchWeapon (self.cnt); // previously used
					break;
				case 12:
					W_PreviousWeapon (0);
					break;
				case 13:
					W_SwitchWeapon (w_getbestweapon(self));
					break;
				case 14:
					W_NextWeaponOnImpulse(0);
					break;
				case 15:
					W_NextWeapon (2);
					break;
				case 16:
					W_PreviousWeapon (2);
					break;
				case 17:
					if (vehicle_extract_player(self, FALSE))
						break;

					if (g_nadgets)
						HG_Trigger();
					else
						W_ThrowWeapon(W_CalculateProjectileVelocity(self.velocity, v_forward * 750), '0 0 0', TRUE);

					break;
				case 18:
					W_NextWeapon (1);
					break;
				case 19:
					W_PreviousWeapon (1);
					break;
				case 20:
					W_Reload ();
					break;
			}
		}
		else
			self.impulse = imp; // retry in next frame
	}
	else if(imp >= 200 && imp <= 229)
	{
		if(self.deadflag == DEAD_NO)
		{
			// custom order weapon cycling
			i = mod(imp, 10);
			m = (imp - (210 + i)); // <0 for prev, =0 for best, >0 for next
			W_CycleWeapon(self.(cvar_cl_weaponpriorities[i]), m);
		}
		else
			self.impulse = imp; // retry in next frame
	}
	else if(imp >= 230 && imp <= 253)
	{
		if(self.deadflag == DEAD_NO) {
			if (self.gameclient == CLIENT_XONOTIC) {
				if (imp >= 234)
					imp--;
			}
			W_SwitchWeapon (imp - 230 + WEP_FIRST);
		} else
			self.impulse = imp; // retry in next frame
	}
	// deploy waypoints
	else if (imp >= 30 && imp <= 49)
	{
		entity wp;
		switch(imp)
		{
			case 30:
				wp = WaypointSprite_DeployPersonal("waypoint", self.origin);
				if(wp)
				{
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_WAYPOINT, '0 1 1');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "personal waypoint spawned at location\n");
				break;
			case 31:
				wp = WaypointSprite_DeployPersonal("waypoint", self.cursor_trace_endpos);
				if(wp)
				{
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_WAYPOINT, '0 1 1');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "personal waypoint spawned at crosshair\n");
				break;
			case 32:
				if(vlen(self.death_origin))
				{
					wp = WaypointSprite_DeployPersonal("waypoint", self.death_origin);
					if(wp)
					{
						WaypointSprite_UpdateTeamRadar(wp, RADARICON_WAYPOINT, '0 1 1');
						WaypointSprite_Ping(wp);
					}
					sprint(self, "personal waypoint spawned at death location\n");
				}
				break;
			case 33:
				if(self.deadflag == DEAD_NO && teams_matter)
				{
					wp = WaypointSprite_Attach("helpme", TRUE);
					if(wp)
						WaypointSprite_UpdateTeamRadar(wp, RADARICON_HELPME, '1 0.5 0'); // TODO choose better color
					if(!wp)
						wp = self.waypointsprite_attachedforcarrier; // flag sprite?
					if(wp)
						WaypointSprite_Ping(wp);
					sprint(self, "HELP ME attached\n");
				}
				break;
			case 34:
				wp = WaypointSprite_DeployFixed("here", FALSE, self.origin);
				if(wp)
				{
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_HERE, '0 1 0');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "HERE spawned at location\n");
				break;
			case 35:
				wp = WaypointSprite_DeployFixed("here", FALSE, self.cursor_trace_endpos);
				if(wp)
				{
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_HERE, '0 1 0');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "HERE spawned at crosshair\n");
				break;
			case 36:
				if(vlen(self.death_origin))
				{
					wp = WaypointSprite_DeployFixed("here", FALSE, self.death_origin);
					if(wp)
					{
						WaypointSprite_UpdateTeamRadar(wp, RADARICON_HERE, '0 1 0');
						WaypointSprite_Ping(wp);
					}
					sprint(self, "HERE spawned at death location\n");
				}
				break;
			case 37:
				wp = WaypointSprite_DeployFixed("danger", FALSE, self.origin);
				if(wp)
				{
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_DANGER, '1 0.5 0');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "DANGER spawned at location\n");
				break;
			case 38:
				wp = WaypointSprite_DeployFixed("danger", FALSE, self.cursor_trace_endpos);
				if(wp)
				{
					WaypointSprite_UpdateTeamRadar(wp, RADARICON_DANGER, '1 0.5 0');
					WaypointSprite_Ping(wp);
				}
				sprint(self, "DANGER spawned at crosshair\n");
				break;
			case 39:
				if(vlen(self.death_origin))
				{
					wp = WaypointSprite_DeployFixed("danger", FALSE, self.death_origin);
					if(wp)
					{
						WaypointSprite_UpdateTeamRadar(wp, RADARICON_DANGER, '1 0.5 0');
						WaypointSprite_Ping(wp);
					}
					sprint(self, "DANGER spawned at death location\n");
				}
				break;
			case 47:
				WaypointSprite_ClearPersonal();
				sprint(self, "personal waypoint cleared\n");
				break;
			case 48:
				WaypointSprite_ClearOwned();
				sprint(self, "all waypoints cleared\n");
				break;
		}
	}
	else if(imp >= 103 && imp <= 107)
	{
		if(g_waypointeditor)
		{
			switch(imp)
			{
				case 103:
					waypoint_schedulerelink(waypoint_spawn(self.origin, self.origin, 0));
					bprint(strcat("Waypoint spawned at ",vtos(self.origin),"\n"));
					break;
				case 104:
					e = navigation_findnearestwaypoint(self, FALSE);
					if (e)
					if not(e.wpflags & WAYPOINTFLAG_GENERATED)
					{
						bprint(strcat("Waypoint removed at ",vtos(e.origin),"\n"));
						waypoint_remove(e);
					}
					break;
				case 105:
					waypoint_schedulerelinkall();
					break;
				case 106:
					waypoint_saveall();
					break;
				case 107:
					for(e = findchain(classname, "waypoint"); e; e = e.chain)
					{
						e.colormod_x = 1;
						e.effects &~= EF_NODEPTHTEST | EF_RED | EF_BLUE;
					}
					e2 = navigation_findnearestwaypoint(self, FALSE);
					navigation_markroutes(e2);
					i = 0;
					m = 0;
					for(e = findchain(classname, "waypoint"); e; e = e.chain)
					{
						if(e.wpcost >= 10000000)
						{
							print("unreachable: ", etos(e), " ", vtos(e.origin), "\n");
							e.colormod_x = 0.1;
							e.effects |= EF_NODEPTHTEST | EF_BLUE;
							++i;
							++m;
						}
					}
					if(i)
						print(ftos(i), " waypoints cannot be reached from here in any way (marked with blue light)\n");
					navigation_markroutes_inverted(e2);
					i = 0;
					for(e = findchain(classname, "waypoint"); e; e = e.chain)
					{
						if(e.wpcost >= 10000000)
						{
							print("cannot reach me: ", etos(e), " ", vtos(e.origin), "\n");
							e.colormod_x = 0.1;
							if not(e.effects & EF_NODEPTHTEST) // not already reported before
								++m;
							e.effects |= EF_NODEPTHTEST | EF_RED;
							++i;
						}
					}
					if(i)
						print(ftos(i), " waypoints cannot walk to here in any way (marked with red light)\n");
					if(m)
						print(ftos(m), " waypoints have been marked total\n");
					i = 0;
					for(e = findchain(classname, "info_player_deathmatch"); e; e = e.chain)
					{
						org = e.origin;
						tracebox(e.origin, PL_MIN, PL_MAX, e.origin - '0 0 512', MOVE_NOMONSTERS, world);
						setorigin(e, trace_endpos);
						if(navigation_findnearestwaypoint(e, FALSE))
						{
							setorigin(e, org);
							e.effects &~= EF_NODEPTHTEST;
							e.model = "";
						}
						else
						{
							setorigin(e, org);
							print("spawn without waypoint: ", etos(e), " ", vtos(e.origin), "\n");
							e.effects |= EF_NODEPTHTEST;
							setmodel(e, self.model);
							e.frame = self.frame;
							e.skin = self.skin;
							setsize(e, '0 0 0', '0 0 0');
							++i;
						}
					}
					if(i)
						print(ftos(i), " spawnpoints have no nearest waypoint (marked by player model)\n");
					break;
			}
		}
	}
}
