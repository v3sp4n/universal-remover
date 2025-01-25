
imguiSettings = imgui.ImBool(false)

local zone = {
	status = false,
	name = "",
	distanceRemove = 10,
	distanceSpawned = 15,
	position = {x=0,y=0,z=0},
}

local selectMenu = ""
function imgui.OnDrawFrame()
	local sw,sh = getScreenResolution()
	-- imgui.SetNextWindowSize(imgui.ImVec2(500,500),1)
	imgui.SetNextWindowPos(imgui.ImVec2(sw/2-500/2,sh/2-300/2), imgui.Cond.FirstUseEver)
	imgui.Begin("universal remover // by vespan", imguiSettings, 64+32)


	imgui.BeginChild("menu's", imgui.ImVec2(370,35), false)
		for _, name in pairs({ "vehicles", "players", "objects" }) do
			if imgui.ActiveButton(name, imgui.ImVec2(112,0), name==selectMenu) then
				selectMenu = name
			end
			imgui.SameLine()
		end
	imgui.EndChild()

	imgui.Spacing()

	if selectMenu ~= "" then 
	
		local var = imgui.ImBool( j[selectMenu].status )
		if imgui.Checkbox("status",var) then
			j[selectMenu].status = var.v; j()
		end	
		imgui.SameLine()
		if hotkey.imgui(nil,"hotkey:", selectMenu) then
			j.hotkeys[selectMenu] = hotkey.getKeys(selectMenu); j()
		end

		if j[selectMenu].size ~= nil then
			local var = imgui.ImInt( j[selectMenu].size )
			if imgui.SliderInt("size",var,5,18) then
				j[selectMenu].size = var.v; j()
			end
		end

		local var = imgui.ImInt( j[selectMenu].minDistance )
		if imgui.SliderInt("min.distance for spawn",var,5,30) then
			j[selectMenu].minDistance = var.v; j()
		end

		if j[selectMenu].color ~= nil then
			local var = imgui.ImFloat4( unpack(j[selectMenu].color) )
			if imgui.ColorEdit4("emptry color",var,512) then
				j[selectMenu].color = {var.v[1], var.v[2], var.v[3], var.v[4]}; j()
			end
		end

		if j[selectMenu].zone ~= nil then
			if imgui.Button('zone') then
				imgui.OpenPopup("zone")
			end

			if imgui.BeginPopupModal("zone", imgui.ImBool(true), 64) then

				imgui.Text(("zone position %0.2f,%0.2f,%0.2f"):format(zone.position.x, zone.position.y, zone.position.z))
				if imgui.SmallButton("put my position") then
					local x,y,z = getCharCoordinates(PLAYER_PED)
					zone.position = {x=x,y=y,z=z}
				end
				imgui.SameLine()
				if imgui.SmallButton("put my targetBlip") then
					local exitBlip, x,y,z = getTargetBlipCoordinates()
					if exitBlip then
						zone.position = {x=x,y=y,z=z}
					end
				end
				local settingsZone = function(z--[[ebalo off]])
					local var = imgui.ImBuffer(z.name,256)
					if imgui.InputText("name zone", var) then z.name = var.v; j() end
					local var = imgui.ImFloat(z.distanceRemove)
					if imgui.DragFloat("position distance remove", var, 0.05, 1, 500) then z.distanceRemove = var.v; j() end
					local var = imgui.ImFloat(z.distanceSpawned)
					if imgui.DragFloat("position distance spawn", var, 0.05, 1, 500) then z.distanceSpawned = var.v; j() end
				end
				settingsZone(zone)

				if imgui.Button('add current zone!', imgui.ImVec2(-1,0)) then
					table.insert(j[selectMenu].zone, zone); j()
				end

				imgui.BeginChild('zone\'s', imgui.ImVec2(400,300), false) 

					imgui.Columns(4, "zone\'s__column", false)
					imgui.SetColumnWidth(0, 40)
					imgui.SetColumnWidth(1, 200)
						for k,v in pairs(j[selectMenu].zone) do
							local var = imgui.ImBool(v.status)
							if imgui.Checkbox("##status__"..k,var) then v.status = var.v j() end
							imgui.NextColumn()
							imgui.SetCursorPosY(imgui.GetCursorPosY()+2)
							imgui.CenterColumnText(v.name)
							imgui.NextColumn()
							imgui.SetCursorPosY(imgui.GetCursorPosY()+4)
							if imgui.SmallButton("settings##"..k) then imgui.OpenPopup("settings_"..k) end
							imgui.NextColumn()
							imgui.SetCursorPosY(imgui.GetCursorPosY()+4)
							if imgui.SmallButton("remove##"..k) then table.remove(j[selectMenu].zone, k) j() end
							imgui.NextColumn()
							imgui.Separator()

							if imgui.BeginPopup("settings_"..k) then
								settingsZone(j[selectMenu].zone[k])
								imgui.EndPopup()
							end
						end
					imgui.Columns(1)

				imgui.EndChild()

				imgui.EndPopup()
			end
		end
	else
		imgui.Text('author vespan\nwww.blast.hk/threads/173175/')
	end


	imgui.End()
end

function imgui.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end

function imgui.ActiveButton(label,size,bool,col)
    local b,col = false,(col == nil and imgui.GetStyle().Colors[23] or col)
    imgui.PushStyleColor(23,(bool and imgui.GetStyle().Colors[25] or col))
    if imgui.Button(label,(size and size or imgui.ImVec2(0,0))) then b = true end
    imgui.PopStyleColor()
    return b
end