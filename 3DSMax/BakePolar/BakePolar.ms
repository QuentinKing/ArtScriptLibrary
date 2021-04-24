/*

	Bakes polar coordinates of each vertex on a mesh on to it's vertex color
	
	When the vizilization is saved to the vertex color, so the theta / radius is remapped to [0, 1] for clarity

*/

(
	rollout ro_BakePolar "Bake Polar Coordinates To Vertex Data" width:275 height:335
	(
		pickbutton 'btn_bakeObj' "Pick Object to Bake" pos:[45,17] width:184 height:24 message:"Select Object" align:#left
		pickbutton 'btn_targetObject' "Pick Target Object" pos:[45,47] width:184 height:24 enabled:false message:"Select Object" align:#left

		GroupBox 'grp_container' "" pos:[28,0] width:228 height:286 align:#left
		radiobuttons 'rdo_polarRelative' "Bake Polar Coordinates Relative To:" pos:[47,137] width:128 height:78 labels:#("Object Pivot", "World Origin", "Object Center of Mass", "Target Object") align:#left
		dropdownList 'ddl_axis' "Around Axis" pos:[50,80] width:175 height:40 items:#("X", "Y", "Z") selection:3 align:#left
		
		spinner 'spn_thetaChannel' "Vertex Channel" pos:[46,228] width:111 height:16 range:[1,100,2] type:#integer scale:1 align:#left
				
		checkbox 'chk_visualize' "Visualize Output in Vertex Color" pos:[38,258] width:199 height:19 checked:true align:#left
		
		button 'btn_Bake' "Bake" pos:[74,300] width:126 height:21 align:#left
		
		on btn_bakeObj picked obj do
		(
			btn_bakeObj.caption = "Object: " + obj.name
		)
		
		on btn_targetObject picked obj do
		(
			btn_targetObject.caption = "Target: " + obj.name
		)
		
		on rdo_polarRelative changed arg do
		(
			btn_targetObject.enabled = (rdo_polarRelative.state == 4)
		)
		
		on btn_Bake pressed do
		(
			if (btn_bakeObj.object == undefined) then
			(
				MessageBox "Please select a source object to bake on to!"
				return()
			)
			
			local obj = btn_bakeObj.object 
			
			if ((ClassOf obj) != Editable_Poly) then
			(
				local convertToPoly = queryBox "The object to bake is not an Editable Poly. Would you like to convert it to an Editable Poly?" title:"Not an Editable Poly" beep:true
				if (convertToPoly) then
				(
					ConvertTo obj Editable_Poly
				)
				else
				(
					return()
				)
			)
			
			if (rdo_polarRelative.state == 4 and btn_targetObject == undefined) then
			(
				MessageBox "Please select a target object to bake from!"
				return()
			)
			
			if (obj.mesh.verts.count == 0) then
			(
				MessageBox "The object has no verts!"
				return()
			)
			
			undo on
			(
				local relativePosition = [0, 0, 0]
				if (rdo_polarRelative.state == 1) then
				(
					-- Object pivot
					relativePosition = obj.pos
				)
				else if (rdo_polarRelative.state == 2) then
				(
					-- World Origin
					relativePosition = [0, 0, 0]
				)
				else if (rdo_polarRelative.state == 3) then
				(
					-- Object Center of Mass
					-- Defining as the average vertex position, which has issues but its useful for a quick bake. Can always use the other options for more precise control
					local t = [0, 0, 0]
					i = 0
					for vert in obj.mesh.verts do
					(
						pos = polyop.getvert obj vert.index
						t += pos
						i += 1
					)
					t = (t / i)
					relativePosition = t
				)
				else if (rdo_polarRelative.state == 4) then
				(
					-- Other Object
					relativePosition = btn_targetObject.object.pos
				)
				
				polyop.setMapSupport obj spn_thetaChannel.value true
				local maxRadius = -1.0
				for vert=1 to (polyop.getNumVerts obj) do
				(
					local pos = polyop.getVert obj vert
					
					local polarX = if (ddl_axis.selection == 1) then pos.Y else pos.X
					local polarY = if (ddl_axis.selection == 1 or ddl_axis.selection == 2) then pos.Z else pos.Y
					
					local refPolarX = if (ddl_axis.selection == 1) then relativePosition.Y else relativePosition.X
					local refPolarY = if (ddl_axis.selection == 1 or ddl_axis.selection == 2) then relativePosition.Z else relativePosition.Y
					
					local yDiff = polarY - refPolarY
					local xDiff = polarX - refPolarX
					local theta = ((atan2 yDiff xDiff) / 360.0) * 2.0 * 3.14159265 -- atan2 is in degrees cause autodesk hates math, and goes from -180 to 180
					local radius = (distance [polarX, polarY, 0] [refPolarX, refPolarY, 0])
					
					maxRadius = (amax radius maxRadius)
					
					polyop.setMapVert obj spn_thetaChannel.value vert (Point3 theta radius 0.0)
				)
				
				if (chk_visualize.checked) then
				(
					for vert=1 to (polyop.getNumVerts obj) do
					(
						-- Convert to range [0-1]
						local theta = (polyop.getMapVert obj spn_thetaChannel.value vert)[1]
						theta = (theta / 2.0 / 3.14159265)
						
						local radius = (polyop.getMapVert obj spn_thetaChannel.value vert)[2]
						radius = (radius / maxRadius)
						
						polyop.setVertColor obj 0 vert (Color (radius*255) (theta*255) 0 255)
					)
				)
				
				MessageBox "Bake Finished"
			)
		)
	)

	try ( DestroyDialog(ro_BakePolar) ) catch ()
	CreateDialog ro_BakePolar
)
