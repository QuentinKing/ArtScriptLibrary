/*
	UI Interface that connects into the export function script that should be located with this script
	
	Settings can be saved as preset files to quickly define different export settings
*/

/*
	PERSISTENT GLOBALS:
	
	These global values represent settings that are scene specific! Ie, they change from scene to scene.
	These should be set everytime an export happens, as they get saved into the maxfile.
*/

persistent global gEXPORT_lastPresetUsed
persistent global gEXPORT_animationClips -- An array of vectors. Vector is in the format [ClipName, StartKey, EndKey]

-- Clear out persistent values before  opening a new file so it doesn't carry over from scene to scene (but that data is still saved within the scene)
global gClearPersistent
fn gClearPersistent =
(
	gEXPORT_lastPresetUsed = undefined
	gEXPORT_animationClips = undefined
)
callbacks.removeScripts #filePreOpen id:#clearPersistent
callbacks.removeScripts #systemPreNew id:#clearPersistent
callbacks.removeScripts #systemPreReset  id:#clearPersistent
callbacks.addScript #filePreOpen "gClearPersistent()" id:#clearPersistent
callbacks.addScript #systemPreNew "gClearPersistent()" id:#clearPersistent
callbacks.addScript #systemPreReset "gClearPersistent()" id:#clearPersistent

-- Defines the export function _EXPORT_FILE_TO_FBX
fileIn "BetterFbxExporter_ExportFunction.ms" 
(
	gSaveDir = ""
	gSaveModelFileName = ""
	fn ParseFilePath savePath =
	(
		gSaveDir = (GetFilenamePath savePath)
		
		local filename = (GetFileNameFile savePath)
		local clipIndex = (FindString filename "@")
		
		if (clipIndex != undefined) then
		(
			gSaveModelFileName = (substring filename 1 (clipIndex-1))
		)
		else
		(
			gSaveModelFileName = filename
		)
	)
	
	fn SortAnimationClip a b = 
	(
		return a[2] - b[2]
	)
	
	rollout ro_ExportPaths "Config" width:400 height:190
	(
		label 'lbl_exportPath' "Export Path" pos:[8,8] width:79 height:24 align:#left
		button 'btn_chooseExportPath' "..." pos:[70,5] width:55 height:18 align:#left
		edittext 'edt_exportPath' "" pos:[3,28] width:377 height:18 enabled:false align:#left
		
		dropdownList 'ddl_preset' "Export Preset" pos:[63,65] width:271 height:40 align:#left
		button 'btn_savePreset' "Save Preset" pos:[206,148] width:165 height:18 align:#left
		GroupBox 'grp_savePreset' "Save Current Configuration" pos:[19,126] width:362 height:52 align:#left
		edittext 'edt_newPresetName' "" pos:[27,148] width:167 height:18 align:#left
		
		local refreshCallback = undefined
		local savePresetCallback = undefined
		local loadPresetCallback = undefined
		
		fn SetPath filePath =
		(
			edt_exportPath.text = filePath
		)
		
		fn Refresh =
		(
			local presetDir = ((GetFilenamePath (GetThisScriptFilename())) + "Presets/") 	
			local presetFiles = GetFiles (presetDir + "*.ini")
				
			local presets = #()
			for preset in presetFiles do
			(
				local presetName = GetFilenameFile preset
				append presets presetName
			)
			ddl_preset.items = presets
			
			edt_exportPath.text = gSaveDir + gSaveModelFileName + ".fbx"
		)
		
		on btn_chooseExportPath pressed do
		(
			local defaultExportName = (getfilenamefile maxfilename)
			local savePath = getSaveFileName caption:"Export FBX Destination" filename:defaultExportName types:"FBX(*.fbx)" historyCategory:"UnityExport"
			if (savePath != undefined and savePath != "") then
			(
				ParseFilePath savePath
			)
			
			if (refreshCallback != undefined) then
			(
				refreshCallback()
			)
		)
		
		on ddl_preset selected index do
		(
			local presetName = ddl_preset.items[index]
			
			if (loadPresetCallback != undefined) then
			(
				loadPresetCallback presetName
			)
			
			refreshCallback()
			
			edt_newPresetName.text = presetName
		)
		
		on btn_savePreset pressed do
		(
			if (edt_newPresetName.text == "") then
			(
				MessageBox "Please enter a preset name!"
				return()
			)
			
			if (savePresetCallback != undefined) then
			(
				savePresetCallback()
			)
			
			refreshCallback()
		)
	)

	rollout ro_ExportOptions "Settings" width:400 height:400
	(
		radiobuttons 'rdo_exportObjects' "Objects to Export" pos:[35,8] width:109 height:62 labels:#("Export Selection   ", "Export Visible   ", "Export Everything") align:#left
		checkbox 'chk_splitVertex' "Split Per-Vertex Normals" pos:[202,56] width:150 height:18 align:#left
		checkbox 'chk_tangentsAndBinormals' "Tangents and Binormals" pos:[29,80] width:150 height:18 align:#left
		checkbox 'chk_smoothingGroups' "Smoothing Groups" pos:[29,54] width:150 height:18 align:#left
		checkbox 'chk_turboSmooth' "Turbosmooth" pos:[202,79] width:150 height:18 align:#left
		checkbox 'chk_embedTextures' "Embed Textures" pos:[29,105] width:150 height:18 align:#left
		
		local refreshCallback = undefined
		
		fn Refresh =
		(
			
		)

	)

	rollout ro_AnimationOptions "Animations" width:400 height:477
	(
		spinner 'spn_BakeStep' "Bake Step" pos:[122,65] width:116 height:16 enabled:true range:[1,100,1] type:#integer scale:1 align:#left		
		radiobuttons 'rdo_animationSetting' "Animation Mode" pos:[25,10] width:394 height:46 labels:#("Export Only Mesh", "Export Only Animations", "Export Mesh / Animations Separately", "Export All As Single File") columns:2 align:#left
		
		edittext 'edt_clipName' "Clip Name" pos:[85,113] width:193 height:18 align:#left
		spinner 'spn_clipStart' "Clip Start" pos:[26,143] width:133 height:16 range:[-10000,10000,0] type:#integer scale:1 align:#left
		spinner 'spn_clipEnd' "Clip End" pos:[206,143] width:133 height:16 range:[-10000,10000,0] type:#integer scale:1 align:#left
		GroupBox 'grp_animationClips' "Animation Clips" pos:[13,88] width:360 height:295 align:#left
		button 'btn_addClip' "Add Animation Clip" pos:[26,183] width:154 height:18 align:#left
		button 'btn_removeClips' "Remove Selected Clips" pos:[206,183] width:154 height:18 align:#left
		
		dotNetControl 'lv_AnimationClips' "system.windows.forms.listView" pos:[23,213] width:340 height:150 align:#left
		
		local refreshCallback = undefined

		fn BuildAnimationClipList =
		(
			lv_AnimationClips.Clear()
			
			local lv_Header =#("Animation Clip Name", "Clip Start", "Clip End")
		
			lv_AnimationClips.view=(dotNetClass "system.windows.forms.view").details
			lv_AnimationClips.FullRowSelect=true
			lv_AnimationClips.GridLines=true
			lv_AnimationClips.MultiSelect=true
			lv_AnimationClips.CheckBoxes=false
			lv_AnimationClips.HideSelection=false
			lv_AnimationClips.IsAccessible=true
			lv_AnimationClips.LabelEdit=false
			
			lv_AnimationClips.columns.add lv_Header[1] 300
			lv_AnimationClips.columns.add lv_Header[2] 100
			lv_AnimationClips.columns.add lv_Header[3] 100
			
			if (gEXPORT_animationClips != undefined) then
			(
				-- Sort list by start frame
				if ((ClassOf gEXPORT_animationClips) == Array) then
				(
					qsort gEXPORT_animationClips SortAnimationClip
				)
				
				local rows = #()
				
				for animationClip in gEXPORT_animationClips do
				(
					local li = DotNetObject "System.Windows.Forms.ListViewItem" animationClip[1]
					
					li.Subitems.add (animationClip[2] as string) -- Start key
					li.Subitems.add (animationClip[3] as string) -- End key
					
					li.BackColor = li.backcolor.fromARGB 240 240 240

					append rows li
				)

				lv_AnimationClips.items.addRange rows
				lv_AnimationClips.Update()
			)
		)
		
		fn Refresh =
		(
			BuildAnimationClipList()
		)
		
		on ro_AnimationOptions open do
		(
			BuildAnimationClipList()
		)
		
		on edt_clipName changed newText do
		(			
			if (refreshCallback != undefined) then
			(
				refreshCallback()
			)
		)

		on btn_addClip pressed do
		(
			if (gEXPORT_animationClips == undefined) then
			(
				gEXPORT_animationClips = #()
			)
			
			if (edt_clipName.text == "") then
			(
				Messagebox ("Please specify a name for the animation clip")
				return()
			)			
			
			if (spn_clipEnd.value <= spn_clipStart.value) then
			(
				Messagebox ("The end frame must be larger than the start frame")
				return()
			)
			
			append gEXPORT_animationClips #(edt_clipName.text, spn_clipStart.value, spn_clipEnd.value)
		
			BuildAnimationClipList()
		)
		
		on btn_removeClips pressed do
		(
			local indicesToRemove = #() 
			for i=0 to (lv_AnimationClips.SelectedIndices.Count-1) do
			(
				append indicesToRemove lv_AnimationClips.SelectedIndices.Item[i]
			)
			
			local newAnimationClips = #()
			for i=1 to gEXPORT_animationClips.count do
			(
				local oldClip = gEXPORT_animationClips[i]
				
				if ((FindItem indicesToRemove (i-1)) == 0) then
				(
					append newAnimationClips oldClip
				)
			)
			
			gEXPORT_animationClips = newAnimationClips
			
			BuildAnimationClipList()
		)
	)
		
	rollout ro_ExportScripts "Scripts" width:400 height:100
	(
		button 'btn_addExportScript' "+" pos:[320,25] width:60 height:23 align:#left
		button 'btn_removeExportScript' "-" pos:[320,52] width:60 height:23 align:#left
		listbox 'lbx_exportScripts' "Export Scripts" pos:[22,5] width:289 height:4 align:#left
		
		local refreshCallback = undefined
		
		fn Refresh =
		(
			
		)
		
		on btn_addExportScript pressed do
		(
			local maxScriptPath = getOpenFileName caption:"Add Export Script" types:"Maxscript(*.ms)|*.ms" historyCategory:"UnityExportScripts"
			if (maxScriptPath != undefined) then
			(
				local maxScriptName = (GetFilenameFile maxScriptPath) + ".ms"
				lbx_exportScripts.items = (append lbx_exportScripts.items maxScriptName)
			)
		)
		
		on btn_removeExportScript pressed do
		(
			local scripts = lbx_exportScripts.items
			if (lbx_exportScripts.selection != 0) then
			(
				deleteItem scripts lbx_exportScripts.selection 
			)
			lbx_exportScripts.items = scripts
		)
	)

	rollout ro_Export "Export" width:400 height:400
	(
		button 'btn_export' "Export" width:180 height:30
		
		local refreshCallback = undefined
		local exportCallback = undefined
		
		fn Refresh =
		(
			
		)
		
		on btn_export pressed do
		(
			if (exportCallback != undefined) then
			(
				exportCallback()
			)
			else
			(
				print "BETTERFBX: Export button callback not assigned!"
			)
		)
	)

	
	fn CallExport =
	(
		-- Keep these variable names the same as defined in the export function for clarity sake
		local exportPath = (gSaveDir + gSaveModelFileName + ".fbx")
		local exportMode = ro_ExportOptions.rdo_exportObjects.state
		local bakeStep = ro_AnimationOptions.spn_BakeStep.value
		local animationClips = gEXPORT_animationClips
		local exportScripts = ro_ExportScripts.lbx_exportScripts.items
		
		-- 1 = Only Mesh, 2 = Only Animations, 3 = Both, 4 = All as single file
		local animationMode =  ro_AnimationOptions.rdo_animationSetting.state
		
		local enableSmoothingGroups = ro_ExportOptions.chk_smoothingGroups.checked
		local enableSplitPerVertex = ro_ExportOptions.chk_splitVertex.checked
		local enableTangentsAndBinormals = ro_ExportOptions.chk_tangentsAndBinormals.checked 
		local enableTurboSmooth = ro_ExportOptions.chk_turboSmooth.checked 
		
		local embedTextures = ro_ExportOptions.chk_embedTextures.checked
		
		-- Call export function
		-- lol probably a nicer looking way to format this
		_EXPORT_FILE_TO_FBX exportPath exportMode enableSmoothingGroups enableSplitPerVertex enableTangentsAndBinormals enableTurboSmooth embedTextures animationMode bakeStep animationClips exportScripts
		
		gEXPORT_lastPresetUsed = ro_ExportPaths.ddl_preset.items[ro_ExportPaths.ddl_preset.selection]
	)
	
	fn RefreshUI =
	(
		ro_ExportPaths.refresh()
		ro_ExportOptions.refresh()
		ro_AnimationOptions.refresh()
		ro_ExportScripts.refresh()
		ro_Export.refresh()
	)
	
	fn SavePreset =
	(
		local newPresetName = ro_ExportPaths.edt_newPresetName.text
		
		local presetPath = ((GetFilenamePath (GetThisScriptFilename())) + "Presets/" + newPresetName + ".ini") 	
		
		if ((GetFiles presetPath).count != 0) then
		(
			local updatePreset = QueryBox "That preset name is already used, would you like to update it's settings?" title:"Update Preset?" beep:true
			if (not updatePreset) then (return())
		)
		
		-- Save all UI Settings into ini file
		SetINISetting presetPath "ro_ExportOptions" "rdo_exportObjects" (ro_ExportOptions.rdo_exportObjects.state as string)
		SetINISetting presetPath "ro_AnimationOptions" "spn_BakeStep" (ro_AnimationOptions.spn_BakeStep.value as string)
		SetINISetting presetPath "ro_AnimationOptions" "rdo_animationSetting" (ro_AnimationOptions.rdo_animationSetting.state as string)
		
		SetINISetting presetPath "ro_ExportOptions" "chk_splitVertex" (ro_ExportOptions.chk_splitVertex.checked as string)
		SetINISetting presetPath "ro_ExportOptions" "chk_tangentsAndBinormals" (ro_ExportOptions.chk_tangentsAndBinormals.checked as string)
		SetINISetting presetPath "ro_ExportOptions" "chk_smoothingGroups" (ro_ExportOptions.chk_smoothingGroups.checked as string)
		SetINISetting presetPath "ro_ExportOptions" "chk_turboSmooth" (ro_ExportOptions.chk_turboSmooth.checked as string)
		
		SetINISetting presetPath "ro_ExportOptions" "chk_embedTextures" (ro_ExportOptions.chk_embedTextures.checked as string)
		
		local exportScripts = ro_ExportScripts.lbx_exportScripts.items
		local exportScriptsString = ""
		for script in exportScripts do
		(
			if (exportScriptsString != "") then
			(
				exportScriptsString += ("," + script)
			)
			else
			(
				exportScriptsString += script
			)
		)
		SetINISetting presetPath "ro_ExportScripts" "lbx_exportScripts" exportScriptsString
	)
	
	fn LoadPreset presetName quiet:false =
	(
		local presetPath = ((GetFilenamePath (GetThisScriptFilename())) + "Presets/" + presetName + ".ini") 

		if ((GetFiles presetPath).count == 0) then
		(
			if (not quiet) then
			(
				MessageBox ("Could not locate preset: " + presetName)
			)
			return()
		)
		
		ro_ExportPaths.edt_newPresetName.text = presetName

		local exportOptionObjects = (GetINISetting presetPath "ro_ExportOptions" "rdo_exportObjects"	)
		if (exportOptionObjects != "") then (ro_ExportOptions.rdo_exportObjects.state = (exportOptionObjects as integer))
			
		local exportOptionSplitVertex = (GetINISetting presetPath "ro_ExportOptions" "chk_splitVertex"	)
		if (exportOptionSplitVertex != "") then (ro_ExportOptions.chk_splitVertex.checked = (exportOptionSplitVertex as BooleanClass))
			
		local exportOptionTangentsBinormals = (GetINISetting presetPath "ro_ExportOptions" "chk_tangentsAndBinormals"	)
		if (exportOptionTangentsBinormals != "") then (ro_ExportOptions.chk_tangentsAndBinormals.checked = (exportOptionTangentsBinormals as BooleanClass))
			
		local exportOptionSmoothingGroups = (GetINISetting presetPath "ro_ExportOptions" "chk_smoothingGroups"	)
		if (exportOptionSmoothingGroups != "") then (ro_ExportOptions.chk_smoothingGroups.checked = (exportOptionSmoothingGroups as BooleanClass))
			
		local exportOptionTurboSmooth = (GetINISetting presetPath "ro_ExportOptions" "chk_turboSmooth"	)
		if (exportOptionTurboSmooth != "") then (ro_ExportOptions.chk_turboSmooth.checked = (exportOptionTurboSmooth as BooleanClass))	
			
		local animationOptionsBakeStep = (GetINISetting presetPath "ro_AnimationOptions" "spn_BakeStep")
		if (animationOptionsBakeStep != "") then (ro_AnimationOptions.spn_BakeStep.value  = (animationOptionsBakeStep as integer))
		
		local animationOptionsAnimationMode = (GetINISetting presetPath "ro_AnimationOptions" "rdo_animationSetting")
		if (animationOptionsAnimationMode != "") then (ro_AnimationOptions.rdo_animationSetting.state = (animationOptionsAnimationMode as integer))
			
		local embedTextures = (GetINISetting presetPath "ro_ExportOptions" "chk_embedTextures")
		if (embedTextures != "") then (ro_ExportOptions.chk_embedTextures.checked  = (embedTextures as BooleanClass))
			
		local copyTextures = (GetINISetting presetPath "ro_ExportOptions" "chk_copyTextures")
		if (copyTextures != "") then (ro_ExportOptions.chk_copyTextures.checked  = (copyTextures as BooleanClass))
			
		local saveMaterials = (GetINISetting presetPath "ro_ExportOptions" "chk_saveMaterials")
		if (saveMaterials != "") then (ro_ExportOptions.chk_saveMaterials.checked  = (saveMaterials as BooleanClass))

		local exportScriptsString = (GetINISetting presetPath "ro_ExportScripts" "lbx_exportScripts")
		local exportScriptNames = (FilterString exportScriptsString ",")
		ro_ExportScripts.lbx_exportScripts.items = exportScriptNames
	)
	
	fn Main =
	(
		local defaultExportName = (getfilenamefile maxfilename)
		
		-- Prompt file save first
		savePath = getSaveFileName caption:"Export FBX Mesh Destination" filename:defaultExportName types:"FBX(*.fbx)|*.fbx" historyCategory:"BetterFbxExport"
		
		-- Show exporter window
		if (savePath != undefined and savePath != "") then
		(
			ParseFilePath savePath
			
			unityRolloutFloater = newRolloutFloater "Better Fbx Export" 400 950
			
			addRollout ro_ExportPaths unityRolloutFloater
			ro_ExportPaths.refreshCallback = RefreshUI
			ro_ExportPaths.savePresetCallback = SavePreset
			ro_ExportPaths.loadPresetCallback = LoadPreset
			
			addRollout ro_ExportOptions unityRolloutFloater
			ro_ExportOptions.refreshCallback = RefreshUI
			
			addRollout ro_AnimationOptions unityRolloutFloater
			ro_AnimationOptions.refreshCallback = RefreshUI
			
			addRollout ro_ExportScripts unityRolloutFloater
			ro_ExportScripts.refreshCallback = RefreshUI
			
			addRollout ro_Export unityRolloutFloater
			ro_Export.refreshCallback = RefreshUI
			ro_Export.exportCallback = CallExport
			
			RefreshUI()
			
			if (gEXPORT_lastPresetUsed != undefined and gEXPORT_lastPresetUsed != "") then
			(
				-- Load last used preset if it exists
				local i = findItem ro_ExportPaths.ddl_preset.items gEXPORT_lastPresetUsed
				if (i != 0) then
				(
					ro_ExportPaths.ddl_preset.selection = i
				)

				LoadPreset gEXPORT_lastPresetUsed quiet:true
			)
			else
			(
				-- Load first preset (if it exists)
				if (ro_ExportPaths.ddl_preset.items.count != 0) then
				(
					LoadPreset ro_ExportPaths.ddl_preset.items[1] quiet:true
				)
			)
		)
	)

	Main()
)
















