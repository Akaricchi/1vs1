#define PMF_JUMP_HELD 1
#define PMF_DUCKED 4
#define PMF_ONGROUND 8

.float pmove_flags;
float physic_button_crouch;
float pmove_onground;
float physic_maxspeedmod;
float physic_jump_velocity_factor;
float physic_can_use_jetpack;
float physic_start_teleport_time;
float physic_start_crouch;

void PM_ClientMovement_UpdateStatus(float ground)
{
	if (physic_movetype == MOVETYPE_WALK)
		physic_velocity_z -= physic_gravity_factor * sv_gravity * frametime;

	if(ground)
	{
		//tracebox(self.origin + '0 0 1', self.mins, self.maxs, self.origin - '0 0 1', MOVE_NORMAL, self);
		tracebox(self.origin, self.mins, self.maxs, self.origin + normalize(physic_velocity) - '0 0 0.125', MOVE_NORMAL, self);
		float f;
		if (trace_fraction < 1.0 && trace_plane_normal_z > 0.7)// && (f = self.velocity * trace_plane_normal) <= 0)
		{
			physic_flags |= FL_ONGROUND;

			// this code actually "predicts" an impact; so let's clip velocity first
			self.velocity -= f * trace_plane_normal;
		}
		else
		{
			physic_flags &~= FL_ONGROUND;
		}
	}

	// set watertype/waterlevel
	vector origin1 = self.origin;
	origin1_z += self.mins_z + 1;
	physic_waterlevel = WATERLEVEL_NONE;

	float thepoint = pointcontents(origin1);

	physic_watertype = (thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME);

	if(physic_watertype)
	{
		physic_waterlevel = WATERLEVEL_WETFEET;
		origin1_z = self.origin_z + (self.mins_z + self.maxs_z) * 0.5;
		thepoint = pointcontents(origin1);
		if(thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME)
		{
			physic_waterlevel = WATERLEVEL_SWIMMING;
			origin1_z = self.origin_z + 22;
			thepoint = pointcontents(origin1);
			if(thepoint == CONTENT_WATER || thepoint == CONTENT_LAVA || thepoint == CONTENT_SLIME)
				physic_waterlevel = WATERLEVEL_SUBMERGED;
		}
	}

}

void PM_ClientMovement_Move()
{
	float bump;
	float t;
	float f;
	vector neworigin;
	vector currentorigin2;
	vector neworigin2;
	vector primalvelocity;

	vector trace1_endpos = '0 0 0';
	vector trace2_endpos = '0 0 0';
	vector trace3_endpos = '0 0 0';
	float trace1_fraction = 0;
	float trace2_fraction = 0;
	float trace3_fraction = 0;
	vector trace1_plane_normal = '0 0 0';
	vector trace2_plane_normal = '0 0 0';
	vector trace3_plane_normal = '0 0 0';
	primalvelocity = physic_velocity;
	for(bump = 0, t = input_timelength; bump < 8 && physic_velocity != '0 0 0'; bump++)
	{
		neworigin = self.origin + t * physic_velocity;
		tracebox(self.origin, self.mins, self.maxs, neworigin, MOVE_NORMAL, self);
		trace1_endpos = trace_endpos;
		trace1_fraction = trace_fraction;
		trace1_plane_normal = trace_plane_normal;
		if(trace1_fraction < 1 && trace1_plane_normal_z == 0)
		{
			// may be a step or wall, try stepping up
			// first move forward at a higher level
			currentorigin2 = self.origin;
			currentorigin2_z += sv_stepheight;
			neworigin2 = neworigin;
			neworigin2_z += sv_stepheight;
			tracebox(currentorigin2, self.mins, self.maxs, neworigin2, MOVE_NORMAL, self);
			trace2_endpos = trace_endpos;
			trace2_fraction = trace_fraction;
			trace2_plane_normal = trace_plane_normal;
			if(!trace_startsolid)
			{
				// then move down from there
				currentorigin2 = trace2_endpos;
				neworigin2 = trace2_endpos;
				neworigin2_z = self.origin_z;
				tracebox(currentorigin2, self.mins, self.maxs, neworigin2, MOVE_NORMAL, self);
				trace3_endpos = trace_endpos;
				trace3_fraction = trace_fraction;
				trace3_plane_normal = trace_plane_normal;
				// accept the new trace if it made some progress
				if(fabs(trace3_endpos_x - trace1_endpos_x) >= 0.03125 || fabs(trace3_endpos_y - trace1_endpos_y) >= 0.03125)
				{
					trace1_endpos = trace2_endpos;
					trace1_fraction = trace2_fraction;
					trace1_plane_normal = trace2_plane_normal;
					trace1_endpos = trace3_endpos;
				}
			}
		}

		// check if it moved at all
		if(trace1_fraction >= 0.001)
			setorigin(self, trace1_endpos);

		// check if it moved all the way
		if(trace1_fraction == 1)
			break;

		// this is only really needed for nogravityonground combined with gravityunaffectedbyticrate
		// <LordHavoc> I'm pretty sure I commented it out solely because it seemed redundant
		// this got commented out in a change that supposedly makes the code match QW better
		// so if this is broken, maybe put it in an if(cls.protocol != PROTOCOL_QUAKEWORLD) block
		//if(trace1_plane_normal_z > 0.7)
		//	physic_flags |= FL_ONGROUND;

		t -= t * trace1_fraction;

		f = (physic_velocity * trace1_plane_normal);
		physic_velocity = physic_velocity - f * trace1_plane_normal;
	}
	//physic_velocity = primalvelocity;
}

float Physic_MaxSpeedMod()
{
	return physic_maxspeedmod;
}

float Physic_JumpVelocityFactor()
{
	return physic_jump_velocity_factor;
}

void Physic_CheckGroundHook()
{
}

void Physic_CheckWaterJumpHook()
{
}

float Physic_CanUseJetPack()
{
	return (physic_can_use_jetpack && (input_buttons & 32));
}

float Physic_JetPackVelocityFactor(float fvel)
{
	return 1;
}

void Physic_JetPackHook(float fuel_fact)
{
}

void Physic_OnJumpHook()
{
}

void Physic_OnCrouchHook()
{
}

void Physic_LandingHook()
{
}

void Physic_FrameBeginHook()
{
	if not(physic_plug)
		PM_ClientMovement_UpdateStatus(TRUE);
}

void Physic_FrameEndHook()
{
	physic_teleport_time -= frametime;
	PM_ClientMovement_Move();
}

entity physic;

.vector pmove_origin;
.vector pmove_velocity;
vector CSQCPhysic_SetCamera()
{
	vector v;
	if(physic && servercommandframe && clientcommandframe)
	{
		float frametime_save = frametime;
		float i;
		float n = clientcommandframe + 1;
		entity oldself = self;
		self = physic;
		self.origin = self.pmove_origin;
		pmove_org = self.origin;
		self.velocity = physic_velocity = self.pmove_velocity;
		physic_teleport_time = physic_start_teleport_time;
		if (physic_plug_pre)
			physic_plug_pre();

		physic_crouch = physic_start_crouch;
		if (physic_start_crouch)
		{
			setsize(self, self.crouch_mins, self.crouch_maxs);
			self.view_ofs = self.crouch_view_ofs;
		}
		else
		{
			setsize(self, self.stand_mins, self.stand_maxs);
			self.view_ofs = self.stand_view_ofs;
		}
		
		for (i = servercommandframe + 1; i <= n; i++)
		{
			if not(RetrieveMovementFrame(i))
				break;

			frametime = input_timelength;
			physic_button_crouch = input_buttons & 16;
			physic_movement = input_movevalues;
			physic_v_angle = input_angles;
			physic_button_jump = input_buttons & 2;
			self.angles_y = input_angles_y;
			
			PlayerPhysics();
		}

		if (physic_plug_post)
			physic_plug_post();
		self = oldself;
		frametime = frametime_save;
		v = physic.origin + physic.view_ofs;

		if (CVAR(chase_active)) {
			makevectors(input_angles);
			tracebox(v, '-1 -1 -1', '1 1 1', v - v_forward * CVAR(chase_back), MOVE_NORMAL, world);
			v = trace_endpos;
			tracebox(v, '-1 -1 -1', '1 1 1', v + v_up * CVAR(chase_up), MOVE_NORMAL, world);
			v = trace_endpos;
		}
		if not(CVAR(chase_active))
			R_SetView(VF_ORIGIN, v);
	}
	else {
		v = pmove_org + '0 0 1' * getstati(STAT_VIEWHEIGHT);
		if (camera_correction_needed) {
			if not(CVAR(chase_active))
				R_SetView(VF_ORIGIN, v);

			camera_correction_needed = FALSE;
		}
	}

	return v;
}

void Physic_InitCheck()
{
	if (self.cnt)
		return;
	localcmd("cmd csqc_physic_reinit\n");
	self.nextthink = time + 1;
}

void Ent_Physic(float isnew)
{
	float f = ReadShort();
	physic = self;
	if (f & 1)
	{
		if (cvar("cl_movement_replay"))
			cvar_clientsettemp("cl_movement_replay", "0");

		self.cnt = 1;
		sv_stepheight = ReadCoord();
		sv_gravity = ReadCoord();
		sv_maxairspeed = ReadCoord();
		sv_maxspeed = ReadCoord();
		sv_friction = ReadCoord();
		sv_accelerate = ReadCoord();
		sv_airaccelerate = ReadCoord();
		sv_airaccel_sideways_friction = ReadCoord();
		sv_airaccel_qw = ReadCoord();
		sv_stopspeed = ReadCoord();
		sv_airstopaccelerate = ReadCoord();
		sv_airstrafeaccelerate = ReadCoord();
		sv_maxairstrafespeed = ReadCoord();
		sv_aircontrol = ReadCoord();
		sv_warsowbunny_turnaccel = ReadCoord();
		sv_warsowbunny_airforwardaccel = ReadCoord();
		sv_warsowbunny_accel = ReadCoord();
		sv_warsowbunny_topspeed = ReadCoord();
		sv_warsowbunny_backtosideratio = ReadCoord();
		sv_jumpvelocity = ReadCoord();
		sv_friction_on_land = ReadCoord();
		g_jetpack_acceleration_side = ReadCoord();
		g_jetpack_acceleration_up = ReadCoord();
		g_jetpack_antigravity = ReadCoord();
		g_jetpack_maxspeed_side = ReadCoord();
		g_jetpack_maxspeed_up = ReadCoord();
		float switches = ReadByte();
		sv_slicksurfaces = switches & 1;
		sv_slicksurfaces_allowjump = switches & 2;
		sv_pogostick = switches & 4;
		sv_disable_crouch = switches & 8;
		sv_gameplayfix_q2airaccelerate = switches & 16;
	}
	else if not(self.cnt)
	{
		self.think = Physic_InitCheck;
		self.nextthink = time;
	}
	if (f & 2)
	{
		self.crouch_mins_x = ReadCoord();
		self.crouch_mins_y = ReadCoord();
		self.crouch_mins_z = ReadCoord();
		self.crouch_maxs_x = ReadCoord();
		self.crouch_maxs_y = ReadCoord();
		self.crouch_maxs_z = ReadCoord();
		self.stand_mins_x = ReadCoord();
		self.stand_mins_y = ReadCoord();
		self.stand_mins_z = ReadCoord();
		self.stand_maxs_x = ReadCoord();
		self.stand_maxs_y = ReadCoord();
		self.stand_maxs_z = ReadCoord();
		self.crouch_view_ofs_x = ReadCoord();
		self.crouch_view_ofs_y = ReadCoord();
		self.crouch_view_ofs_z = ReadCoord();
		self.stand_view_ofs_x = ReadCoord();
		self.stand_view_ofs_y = ReadCoord();
		self.stand_view_ofs_z = ReadCoord();
	}
	if (f & 4)
	{
		self.pmove_origin_x = ReadCoord();
		self.pmove_origin_y = ReadCoord();
		self.pmove_origin_z = ReadCoord();
		self.pmove_velocity_x = ReadCoord();
		self.pmove_velocity_y = ReadCoord();
		self.pmove_velocity_z = ReadCoord();
		physic_is_player = f & 8;
		physic_deadflag = f & 16;
		physic_ladder = f & 32;	
		physic_ladder_iswater = f & 64;	
		physic_can_use_jetpack = f & 128;
		physic_start_crouch = f & 256;
		if (physic_ladder && physic_ladder_iswater)
		{
			physic_ladder_speed = ReadCoord();
			physic_ladder_watertype = ReadCoord();
			physic_ladder_top = ReadCoord();
		}
		if (f & 512)
		{
			physic_maxspeedmod = ReadCoord();
			physic_jump_velocity_factor = ReadCoord();
		}
		else
		{
			physic_maxspeedmod = 1;
			physic_jump_velocity_factor = 1;
		}
		if (f & 1024)
			physic_movetype = ReadByte();
		else
			physic_movetype = MOVETYPE_WALK;
		if (physic_movetype == MOVETYPE_NOCLIP)
			self.dphitcontentsmask = 0;
		else
			self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP;
		if (f & 2048)
			physic_gravity_factor = ReadCoord();
		else
			physic_gravity_factor = 1;
		if (f & 4096)
			physic_start_teleport_time = ReadCoord();
		else
			physic_start_teleport_time = -1;
	}
}
