/*
	Bakes spherical coordinates of each vertex on a mesh on to one of its vertex channels.
	
	If the visualization is enabled, the result is remapped to the range [0, 1] for the vertex color so its easier to see.
*/

(
	rollout ro_BakeSpherical "Bake Spherical Coordinates To Vertex Data" width:275 height:266
	(
		pickbutton 'btn_bakeObj' "Pick Object to Bake" pos:[45,17] width:184 height:24 message:"Select Object" align:#left
		pickbutton 'btn_targetObject' "Pick Target Object" pos:[45,47] width:184 height:24 enabled:false message:"Select Object" align:#left
		GroupBox 'grp_container' "" pos:[28,0] width:228 height:228 align:#left
		radiobuttons 'rdo_sphericalRelative' "Bake Spherical Coordinates Relative To:" pos:[48,79] width:128 height:78 labels:#("Object Pivot", "World Origin", "Object Center of Mass", "Target Object") align:#left
		spinner 'spn_thetaChannel' "Vertex Channel" pos:[47,170] width:111 height:16 range:[1,100,2] type:#integer scale:1 align:#left
		checkbox 'chk_visualize' "Visualize Output in Vertex Color" pos:[39,200] width:199 height:19 checked:true align:#left
		button 'btn_Bake' "Bake" pos:[75,237] width:126 height:21 align:#left

		on btn_bakeObj picked obj do
		(
			btn_bakeObj.caption = "Object: " + obj.name
		)
		
		on btn_targetObject picked obj do
		(
			btn_targetObject.caption = "Target: " + obj.name
		)
		
		on rdo_sphericalRelative changed arg do
		(
			btn_targetObject.enabled = (rdo_sphericalRelative.state == 4)
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
			
			if (rdo_sphericalRelative.state == 4 and btn_targetObject == undefined) then
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
				if (rdo_sphericalRelative.state == 1) then
				(
					-- Object pivot
					relativePosition = obj.pos
				)
				else if (rdo_sphericalRelative.state == 2) then
				(
					-- World Origin
					relativePosition = [0, 0, 0]
				)
				else if (rdo_sphericalRelative.state == 3) then
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
				else if (rdo_sphericalRelative.state == 4) then
				(
					-- Other Object
					relativePosition = btn_targetObject.object.pos
				)
				
				polyop.setMapSupport obj spn_thetaChannel.value true
				local maxRadius = -1.0
				for vert=1 to (polyop.getNumVerts obj) do
				(
					local pos = polyop.getVert obj vert
					local relativePoint = pos - relativePosition
					
					local r = distance relativePoint (Point3 0 0 0)
					local theta = (atan2 (sqrt (relativePoint.x*relativePoint.x + relativePoint.y*relativePoint.y)) relativePoint.z) / 360.0 * 2.0 * 3.14159265
					local phi = ((atan2 relativePoint.y relativePoint.x) / 360.0) * 2.0 * 3.14159265
					
					maxRadius = (amax r maxRadius)
		
					polyop.setMapVert obj spn_thetaChannel.value vert (Point3 r theta phi)
				)
				
				if (chk_visualize.checked) then
				(
					for vert=1 to (polyop.getNumVerts obj) do
					(
						-- Convert to range [0-1]
						local radius = (polyop.getMapVert obj spn_thetaChannel.value vert)[1]
						radius = (radius / maxRadius)
						
						local theta = (polyop.getMapVert obj spn_thetaChannel.value vert)[2]
						theta = (theta / 3.14159265)
						
						local phi = (polyop.getMapVert obj spn_thetaChannel.value vert)[3]
						phi = (phi / 2.0 / 3.14159265)

						polyop.setVertColor obj 0 vert (Color (radius * 255) (theta * 255) (phi * 255) 255)
					)
				)
				
				MessageBox "Bake Finished"
			)
		)
	)

	try ( DestroyDialog(ro_BakeSpherical) ) catch ()
	CreateDialog ro_BakeSpherical
)
