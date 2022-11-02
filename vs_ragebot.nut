//Squirrel
//This script work with Speedrunner Tools

::RageBot <- function(hPlayer, fDistance = 1000)
{
	const RAGEBOT_VERSION = "Stable_Script_v1.0.0";
	
	if ((hPlayer = Ent(hPlayer)) == null || !hPlayer.IsPlayer()) return Say(null, "[RageBot] Invalid player specified.", false);
	if (!("RageBot" in g_STLib))
	{
		g_STLib.RageBot <-
		{
			playersList = []
			time = array(MAXCLIENTS + 1, 0.0)
			dist = array(MAXCLIENTS + 1, 0.0)
			Think = function()
			{
				local bFound = false;
				for (local i = 0; i < playersList.len(); i++)
				{
					hPlayer = playersList[i];
					if (!IsPlayer(hPlayer))
					{
						printl(CPGetTime() + " >> [RageBot] Auto-removed.");
						playersList.remove(i);
						i--;
						NetProps.SetPropInt(hPlayer, "m_afButtonForced", 0);
						continue;
					}
					bFound = true;
					if (!hPlayer.IsSurvivor() || hPlayer.IsDying() || hPlayer.IsDead()) continue;
					local client = hPlayer.GetEntityIndex();
					if ((Time() - time[client]) > RandomFloat(0.0, 0.5))
					{
						local hEntity = null;
						while (hEntity = Entities.FindByClassname(hEntity, "infected"))
						{
							if (hEntity.GetHealth() > 0 && NetProps.GetPropInt(hEntity, "movetype") != MOVETYPE_NONE)
							{
								if (GetDistance(hPlayer, hEntity) < dist[client])
								{
									if (hPlayer.GetButtonMask() & IN_ATTACK || hPlayer.GetButtonMask() & IN_RELOAD)
									{
										NetProps.SetPropInt(hPlayer, "m_afButtonForced", 0);
										continue;
									}
									
									local hTrace =
									{
										start = hPlayer.EyePosition()
										end = hEntity.GetOrigin() + Vector(0, 0, 34)
										ignore = hPlayer
										mask = TRACE_MASK_SHOT
									}
									TraceLine(hTrace);
									if (hTrace.hit && hTrace.enthit == hEntity)
									{
										local vecPos = hEntity.GetOrigin() - hPlayer.EyePosition();
										vecPos += NetProps.GetPropInt(hEntity, "m_fFlags") & FL_ONGROUND ? Vector(0, 0, 55) : Vector(0, 0, 10);
										
										local fPitch = asin(vecPos.z/vecPos.Length())*180/PI*-1;
										local length = sqrt(pow(vecPos.x, 2.0) + pow(vecPos.y, 2.0));
										local fYaw = acos(vecPos.x/length)*180/PI;
										if (asin(vecPos.y/length) < 0) fYaw*=-1;
										
										TeleportEntity(hPlayer, null, Vector(fPitch, fYaw, 0), null);
										
										NetProps.SetPropInt(hPlayer, "m_afButtonForced", IN_ATTACK);
										
										time[client] = Time();
										continue;
									}
								}
								else NetProps.SetPropInt(hPlayer, "m_afButtonForced", 0);
							}
						}
					}
				}
				if (!bFound) caller.Kill();
			}
		}
	}
	this = g_STLib.RageBot;
	local idx = playersList.find(hPlayer);
	if (!fDistance)
	{
		if (idx == null) return Say(null, "[RageBot] Not found for removal: " + hPlayer, false);
		playersList.remove(idx);
		NetProps.SetPropInt(hPlayer, "m_afButtonForced", NetProps.GetPropInt(hPlayer, "m_afButtonForced") & ~IN_ATTACK);
		return printl(CPGetTime() + " >> [RageBot] Removed successfully: " + hPlayer);
	}
	dist[hPlayer.GetEntityIndex()] = fDistance;
	if (idx != null) return;
	playersList.append(hPlayer);
	OnGameFrame("g_STLib.RageBot.Think", 0.040);
}

SendToServerConsole("echo [ST] RageBot " + RAGEBOT_VERSION);

