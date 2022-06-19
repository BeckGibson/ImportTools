try (cui.unRegisterDialogBar importtools)catch()
try (DestroyDialog importtools)catch()

rollout importtools "Import Tools"
(
	label lblTitle "Import settings:"
	checkbox CheckPivot "Move to 0,0,0" tooltip: "Resets objects to 0,0,0 on import"
	checkbox CheckXform "Reset xForm" tooltip: "Resets xForm of objects on import"
	checkbox CheckMat "Clean Materials" tooltip: "Removes materials and sets new default material"
	checkbox CheckCamLight "Remove Lights + Cameras" tooltip: "Removes imported lights are cameras, doesn't touch what's in the scene already"
	checkbox CheckSettings "Show Import Settings" tooltip: "Shows the import dialogue for changing import settings"
	checkbox CheckCombine "Combine Elements" tooltip: "Combines all elements of an fbx into a single mesh, does not combine meshes from seperate files"

	label lblBlank1 "" height:5
	button btnImport "Import Objects" width:125 height: 50 tooltip:"Import mesh files"
	label lblBlank0 "" height:5
	checkbox CheckMerge "Show Merge Settings" tooltip: "Shows the merge dialogue for choosing which objects to merge into the scene"
	button btnMerge "Merge Files" width:125 height: 50 tooltip:"Merge Max Files"
	label lblBlank2 "" height:5
	button btnCombine "Combine All" width:125 tooltip:"Combine all Geometry"
	label lblBlank3 "" height:5
	checkbox CheckWarnings "Ignore Warnings" tooltip:"Ignore all warning messages associated with this script"
	
	
	global CamLight = false --variables for tickboxes
	global ChangePivot = false
	global ChangeXform = false
	global CleanMats = false
	global ImportSettings = false
	global MergeSettings = false
	global CombineTheElements = false
	global ToggleWarnings = false
	
	function defaultMat =  --function to add default mat to selected objects
	(
		select $* --selects all 
		obj=selection as Array
		if obj.count==0 then (messageBox "Select Objects")
		else
		(
			for items in obj do
			(
				newmat = Standardmaterial() --creates standard material
				newmat.name = items.name as string + "_MAT" --calls material name of object _MAT
				items.material = newmat --assigns the material
			)
		)
	)
	
	function CombineElements = --combine all
	(
		count = 2
		CombineNode = 1
		select $* --select all
		selectionArray = selection as Array --create array
		
		for obj in selectionArray do --for every object in array
		(
			if superClassOf obj != GeometryClass then --if the object in the array is not geometry
			(
				obj.isFrozen = true --freeze it
			)
		)
		
		convertTo selection Editable_Poly --converts everything to edit poly (if it can be converted)
		
		CombineArray = selection as Array --create array of selection
		for start=1 to CombineArray.count do --
		(
			if CombineArray[CombineNode] != undefined and CombineArray[CombineNode].isFrozen == true then --if the combine node is not undefined and is frozen
			(
				while CombineArray[CombineNode] != undefined and CombineArray[CombineNode].isFrozen == true do --as long as it's defined and is frozen
				(
					CombineNode = CombineNode + 1 --move onto the next object in the array (find one that isn't frozen)
				)
			)
			if CombineArray[count] != undefined and CombineArray[count].isFrozen == true then --if the object to combine is defined and is frozen
			(
				while CombineArray[count] != undefined and CombineArray[count].isFrozen == true do --as long as it's defined and is frozen
				(
					count = count + 1 --move onto the next object in the array to find one that isn't frozen
				)
			)
			if count == CombineNode then --if the object to combine to and the object to combine are the same
			(
				count = count + 1 --move the object to combine up in the array
			)
			if CombineArray[count] != undefined and CombineArray[count].isFrozen == false then --if the object to combine is defined and not frozen
			(
				polyop.attach CombineArray[CombineNode] CombineArray[count] --combined it
				count = count + 1 --move onto the next object
			)
		)
	)
	
	function Import =
	(
		local count = 1
		local SettingsChangedOnce = false
		
		--- taken from sciptspot - gets selected files as string array
		theDialog = dotNetObject "System.Windows.Forms.OpenFileDialog" --create a OpenFileDialog
		theDialog.title = "Select one or more mesh file" --set the title
		theDialog.Multiselect = true --allow multiple files to be selected
		theDialog.Filter = "All Files (*.*)|*.*| FBX Files (*.fbx)|*.fbx|Obj Files (*.obj)|*.obj" --specify the filter
		theDialog.FilterIndex = 2 --set the filter drop-down list to All Files
		result = theDialog.showDialog() --display the dialog, get result into variable
		result.ToString() --when closed, convert the result to string
		result.Equals result.OK --returns TRUE if OK was pressed, FALSE otherwise
		result.Equals result.Cancel --returns TRUE if Cancel was pressed, FALSE otherwise
		theFilenames = theDialog.fileNames --the selected filenames will be returned as an array
		----------
		
		for start=1 to theFilenames.count do
		(
			if ImportSettings == false or SettingsChangedOnce == true then
			(	
				for start=1 to theFilenames.count do
				(
					select $* --select everything
					freeze selection --freezes it
					toImport = theFilenames[count] as string --takes filename from array
					importFile toImport #noprompt --imports the file without showing prompts
					count= count+1 --increases the count for the loop
					if CombineTheElements == true then
					(
						CombineElements()
					)
				)
			)
			else
			(
				toImport = theFilenames[count] as string --takes filename from array
				importFile toImport --imports the file without showing prompts
				count= count+1 --increases the count for the loop
				SettingsChangedOnce = true
				if CombineElements == true then
					(
						CombineElements()
						select $* --select everything
						freeze selection --freeze it (stops the import() function touching the objects native to the scene)
					)
			)
		)
	)
	
	function MergeImport = --function to merge in max files
	(
		local count = 1
		
		--- taken from sciptspot - gets selected files as string array
		theDialog = dotNetObject "System.Windows.Forms.OpenFileDialog" --create a OpenFileDialog
		theDialog.title = "Select one or more Max file" --set the title
		theDialog.Multiselect = true --allow multiple files to be selected
		theDialog.Filter = "All Files (*.*)|*.*| Max Files (*.max)|*.max" --specify the filter
		theDialog.FilterIndex = 2 --set the filter drop-down list to All Files
		result = theDialog.showDialog() --display the dialog, get result into variable
		result.ToString() --when closed, convert the result to string
		result.Equals result.OK --returns TRUE if OK was pressed, FALSE otherwise
		result.Equals result.Cancel --returns TRUE if Cancel was pressed, FALSE otherwise
		theFilenames = theDialog.fileNames --the selected filenames will be returned as an array
		----------
		
		for start=1 to theFilenames.count do
		(
			toImport = theFilenames[count] as string --gets filename from array
			if MergeSettings == false then
			(
				mergeMaxFile toImport #autoRenameDups #renameMtlDups --merges the max file in, auto renames duplicate meshes and materials
			)
			else
			(
				mergeMaxFile toImport #autoRenameDups #renameMtlDups #prompt --merges the max file in, auto renames duplicate meshes and materials, displays merge dialog
			)
			count= count+1
		)
		
	)

	function FnXform =
	(
		select $*
		obj=selection as Array
		if obj.count==0 then (messageBox "Select Objects")
		else
		(
			local parentArray = #() --array for parents of all objects
			local i = 1
			local count = 1
			
			for start=1 to obj.count do
			(
				if obj[count].parent == undefined then --if object doesn't have a parent,
				(
					AppendItem = obj[count] --copy it
					deleteItem obj count --delete original
					append obj AppendItem --append to end of array
				)
				else
				(
					count = count + 1 --check next object in array if first is a child
				)
			)
			for items in obj  where items.isFrozen == False do
			(
				append parentArray items.parent --adds the parent of an object to the parrent array (adds undefined if no parent)
				items.parent = undefined --sets parent to undefined (deletes parent links in heiracy)
				ResetXForm(items) --reset xform
				collapseStack(items) --collapse modifier stack
			)
			
			for items in obj do
			(
				items.parent = ParentArray[i] --assigns original parent back to object from parent array
				i = i + 1
			)
		)
	)
	
	function RemoveCameras = --function to remove cameras when importing files
	(
		select $* --select all
		selectionArray = selection as Array --creates array
		deselect $ --deselect all
		
		for obj in selectionArray where superClassOf obj == Camera and obj.isFrozen == false do --for each object in the array, where the object is a camera and isn't frozen (i.e was not in the scene before the recent import)
		(
			selectmore obj --append it to the selection
		)
		delete selection --delete the selection
		
	)
	
	function RemoveLights = --function to remove lights when importing files
	(
		select $* --select all
		selectionArray = selection as Array --create array
		deselect $ --deselect all
		
		for obj in selectionArray where superClassOf obj == light and obj.isFrozen == false or superClassOf obj == node and obj.isFrozen == false do --for each object in the array, where the object is a light and isn't frozen
		(
			selectmore obj --append it to the selection
		)
		delete selection --delete the selection
		
	)
	
	
	--swithces the global tickbox varibles on or off
	on CheckCamLight changed theState do
	(
		CamLight = NOT CamLight
	)
	
	on CheckPivot changed theState do
	(
		ChangePivot = NOT ChangePivot
	)
	
	on CheckXform changed theState do
	(
		ChangeXform = NOT changeXform
		if ChangeXform == true and ToggleWarnings == false then --if warning messages are turned ON, displays this message
		(
			messageBox "Resetting Xform of objects whose parents have parents can have undesired affects. Single level parent and child objects will work normally." title: "Warning"
		)
	)
	
	on CheckMat changed theState do
	(
		CleanMats = NOT CleanMats
	)
	
	on CheckSettings changed theState do
	(
		ImportSettings = NOT ImportSettings
	)
	
	on CheckMerge changed theState do
	(
		MergeSettings = NOT MergeSettings
	)
	
	on CheckCombine changed theState do
	(
		CombineTheElements = NOT CombineTheElements
		if CombineTheElements == true and ToggleWarnings == false then --if warning messages are ON, displays this message
		(
			messageBox "Combining large mesh files on import can cause 3ds Max to stop responding" title: "Warning"
		)
	)
	
	on CheckWarnings changed theState do
	(
		ToggleWarnings = NOT ToggleWarnings
	)
	
	on btnImport pressed do --when 'import objects' pressed
	(
		select $* --select everything
		freeze selection --freeze it (stops the import() function touching the objects native to the scene)
		Import() --run import function 
		if CamLight == true then --if "remove Lights + cameras" is ticked
		(
			RemoveCameras()
			RemoveLights()
		)
		if ChangePivot == true then --if "move to 000 is ticked"
		(
			select $* --select all
			PivotArray = selection as Array --create array of selection
			for each in PivotArray where each.isFrozen == false do --for each object in the array, if it's not forzen (not native to the scene)
			(
				each.pos = [0,0,0] --move object to 000
			)
		)
		if ChangeXform == true then --if "reset xForm" is ticked
		(
			FnXform()
		)
		
		if CleanMats == true then --if "clean materials" is ticked
		(
			defaultMat()
		)
			
		select $* --select everything
		unfreeze selection --unfreeze everything
	)
	
	on btnMerge pressed do --when "merge files" is pressed
	(
		MergeImport()
	)
	
	on btnCombine pressed do
	(
		CombineElements()
		select $*
		unfreeze selection
	)

)
CreateDialog importtools
cui.registerDialogBar importtools
cui.dockDialogBar importtools #cui_dock_left
