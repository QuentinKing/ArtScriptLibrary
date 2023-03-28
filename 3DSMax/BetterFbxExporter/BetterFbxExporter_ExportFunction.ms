/*
	This file defines the function to export the current maxfile to FBX
*/

/*
*
* GLOBALS
*
*/

-- These variables essentially exists to provide more flexibility to export scripts. By default, this exporter only spits out one .fbx model file per run.
-- HOWEVER, you can write a custom export script to append to this list in order to export multiple model files from one file. 
-- An example of when you might need to do this is when a character has multiple different costumes and each costume needs to be its own file
global _MESH_SUBSETS = #() -- A list of "structs" where each struct contains the mesh objects and a file suffix
global _ANIMATION_OBJS = #() -- A list of objects

fn _REMOVE_MESH_FROM_OBJ obj =
(
	if (IsProperty obj "mesh") then
	(
		obj.baseObject = Dummy()
	)
)

/*
	PARAMETERS:
	
	exportPath: String
	  The filepath to export to
	
	exportMode : Int, either 1, 2, or 3
	  1 -> Exports all selected objects
	  2 -> Exports all visible objects in the scene
	  3 -> Export everything in the file

	animationMode : integer
	  1 -> Only Mesh
	  2 -> Only Animations
	  3 -> Both
	  4 -> All as single file
	  
	bakeStep : integer
	  The step value in keyframes when baking animations
	  
	animationClips : List of vectors
	  The list of animation clips. This is a list of vectors in the format [ClipName : String, StartKey : Int,  EndKey : Int]
	  
	exportScripts : list of strings
	  A list of export scripts to run before exporting located in the sub folder "ExportScripts"
	  
	enableSmoothingGroups : Boolean
	  Exports smoothing group data if true
	
	enableSplitPerVertex : Boolean
	  Splits normals per vertex if true
	
	enableTangentsAndBinormals : Boolean
	  Exports tangents and binormal data if true
	 
	enableTurboSmooth : Boolean
	  Exports turbosmooth modifiers if true
	  
	embedTextures : Boolean 
	  Embeds the textures into the exported fbx
*/
global _EXPORT_FILE_TO_FBX
fn _EXPORT_FILE_TO_FBX exportPath exportMode enableSmoothingGroups enableSplitPerVertex enableTangentsAndBinormals enableTurboSmooth embedTextures animationMode bakeStep animationClips exportScripts =
(
	_MESH_SUBSETS = #()
	_ANIMATION_OBJS = #()
	
	print "BETTERFBX: Starting Export"
	holdMaxFile() 
	
	with undo off
	(
		/*
		*
		*	DETERMINE EXPORT OBJECTS
		*
		*/
		if (exportMode == 1) then
		(
			-- Export selected
		)
		if (exportMode == 2) then
		(
			-- Export visible
			max select none
			for o in objects do
			(
				if (not o.isHidden) then
				(
					selectmore o
				)
			)
		)
		else if (exportMode == 3) then
		(
			-- Export everything
			max select none
			for o in objects do
			(
				selectmore o
			)
		)
		
		/*
		* 
		*	DETERMINE DEFAULT MESH / ANIMATION OBJECTS
		* 
		*/
		local meshObjects = #()
		local animationObjects = #()
		
		for obj in $selection do
		(
			if ((ClassOf obj == Biped_Object) or (ClassOf obj == BoneGeometry) or (try(ClassOf obj.transform.controller == BipSlave_Control) catch(false))) then
			(
				append animationObjects obj
			)
			else
			(
				if (obj.transform.isAnimated) then
				(
					append animationObjects obj
					if (IsProperty obj "mesh") then
					(
						append meshObjects obj
					)
				)
				else
				(
					append meshObjects obj
				)
			)
		)

		append _MESH_SUBSETS #(meshObjects, "")
		_ANIMATION_OBJS = animationObjects
		
		/*
		*
		*	FBX PARAMETERS
		*
		*/
		-- Set custom FBX Parameters
		FbxExporterSetParam "BakeFrameStep" bakeStep
		
		FbxExporterSetParam "SmoothingGroups" enableSmoothingGroups
		FbxExporterSetParam "NormalsPerPoly" enableSplitPerVertex
		FbxExporterSetParam "TangentSpaceExport" enableTangentsAndBinormals
		FbxExporterSetParam "SmoothMeshExport" enableTurboSmooth
		FbxExporterSetParam "EmbedTextures" embedTextures
		
		-- Constant parameters to always set, feel free to change these
		FbxExporterSetParam "BakeAnimation" True
		FbxExporterSetParam "UpAxis" "Y"
		FbxExporterSetParam "BakeResampleAnimation" False
		FbxExporterSetParam "FilterKeyReducer" True

		-- Clear take accumulator 
		FBXExporterSetParam "SplitAnimationIntoTakes" "-clear"
		
		/*
		*
		*  EXPORT SCRIPTS
		*
		*/
		local dirPath = (GetFilenamePath (GetThisScriptFilename())) + "ExportScripts/"
		for exportScript in exportScripts do
		(
			local scriptPath = (dirPath + exportScript)
			if ((getfiles scriptPath).count != 0) then
			(
				try 
				(
					fileIn scriptPath
					print ("BETTERFBX: Ran export script:" + exportScript)
				)
				catch
				(
					print ("BETTERFBX: Error encountered in export script: " + exportScript)
				)
			)
			else
			(
				print ("BETTERFBX: Tried to run export script [" + exportScript + "] but it could not be found in the export script folder")
			)
		)
		
		/*
		*
		* EXPORT
		*
		*/
		
		/*
		animationMode
		  1 -> Only Mesh
		  2 -> Only Animations
		  3 -> Both
		  4 -> All as single file
		*/
		local bipedStates = #()
		local bipedControllers = (for o in objects where (o.controller != undefined and (o.controller as string) == "Controller:Body") collect o)
		
		-- Export mesh file
		if (animationMode == 1 or animationMode == 3) then
		(
			FbxExporterSetParam "Animation" false
			ClearSelection()
			
			-- Set figure mode for all bipeds
			for bipedController in bipedControllers do 
			(
				-- Need to save what state the biped is in so we can change it back from the animation export
				if (bipedController.controller.figureMode) then
				(
					append bipedStates 1
				)
				else if (bipedController.controller.footstepMode) then
				(
					append bipedStates 2
				)
				else if (bipedController.controller.motionMode) then
				(
					append bipedStates 3
				)
				else if (bipedController.controller.mixerMode) then
				(
					append bipedStates 4
				)
				
				bipedController.controller.figureMode = true 
			)
			
			for modelFile in _MESH_SUBSETS do
			(		
				select modelFile[1]
				
				local modelExportPath =  (GetFilenamePath exportPath) + (GetFilenameFile exportPath) + modelFile[2] + ".fbx"
			
				if (selection.count == 0) then
				(
					print ("BETTERFBX: SKIPPING " + modelExportPath + " (no objects selected)")
				)
				else
				(
					print ("BETTERFBX:  EXPORTING " + modelExportPath)
					exportFile modelExportPath #noPrompt selectedOnly:true using:FBXEXP
				)
			)
		)
			
		-- Export animations
		if (animationMode == 2 or animationMode == 3) then
		(
			FbxExporterSetParam "Animation" true
			ClearSelection()
			
			-- Recover biped state
			for i = 1 to bipedControllers.count do 
			(
				local bipedController = bipedControllers[i]
				bipedController.controller.figureMode = false				
				
				if (bipedStates[i] == 1) then
				(
					bipedController.controller.figureMode = true
				)
				else if (bipedStates[i] == 2) then
				(
					bipedController.controller.footstepMode = true
				)
				else if (bipedStates[i] == 3) then
				(
					bipedController.controller.motionMode = true
				)
				else if (bipedStates[i] == 4) then
				(
					bipedController.controller.mixerMode = true
				)
			)

			select _ANIMATION_OBJS
			
			-- Make sure we never include mesh data in animation files, note that this is destructive so the animation export should be last
			for obj in $selection do
			(
				_REMOVE_MESH_FROM_OBJ obj
			)
			
			if (animationClips != undefined) then
			(
				if (_ANIMATION_OBJS.count == 0) then
				(
					print "BETTERFBX: Skipping animation export since no animation objects were defined"
				)
				else
				(
					for animationClip in animationClips do
					(
						local exportDir = (GetFilenamePath exportPath)
						local exportName = (GetFilenameFile exportPath)
						
						local animationExportPath = exportDir + exportName + "@" + animationClip[1] + ".fbx"
						
						animationRange = interval animationClip[2] animationClip[3]
						FbxExporterSetParam "BakeFrameStart" animationClip[2]
						FbxExporterSetParam "BakeFrameEnd" animationClip[3]
						
						print ("BETTERFBX: EXPORTING " + animationExportPath)
						exportFile animationExportPath #noPrompt selectedOnly:true using:FBXEXP
					)
				)
			)
		)
		
		-- Export as one file
		if (animationMode == 4) then
		(
			FbxExporterSetParam "Animation" true
			ClearSelection()
			
			local animationTakeObj = (_SaveAnimationTakes animationClips)
			
			for modelFile in _MESH_SUBSETS do
			(
				select modelFile[1]
				selectmore _ANIMATION_OBJS
				if (animationTakeObj != undefined) then
				(
					selectmore animationTakeObj
				)
				local modelExportPath =  (GetFilenamePath exportPath) + (GetFilenameFile exportPath) + modelFile[2] + ".fbx"

				-- Bake animation from earliest keyframe to latest
				local bakeStart = animationRange.start
				local bakeEnd = animationRange.end
				
				if (animationClips != undefined) then
				(
					for animationClip in animationClips do
					(
						bakeStart = amin bakeStart animationClip[2]
						bakeEnd = amax bakeEnd animationClip[3]
					)
				)
				animationRange = (interval bakeStart bakeEnd)
				
				FbxExporterSetParam "BakeFrameStart" bakeStart
				FbxExporterSetParam "BakeFrameEnd" bakeEnd
				
				if (selection.count == 0) then
				(
					print ("BETTERFBX: SKIPPING " + exportPath + " (no objects selected)")
				)
				else
				(
					print ("BETTERFBX: EXPORTING " + exportPath)
					exportFile modelExportPath #noPrompt  selectedOnly:true using:FBXEXP
				)
			)
		)
	)
	
	fetchMaxFile quiet:true
	print "BETTERFBX: Finished Export"
)
