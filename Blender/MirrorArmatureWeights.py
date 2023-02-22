import bpy
import math

class MirrorWeightsUI(bpy.types.Panel):
    bl_label = "Mirror Weights Panel"
    bl_idname = "OBJECT_PT_simple_ui"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "Mirror Weights"

    def draw(self, context):
        layout = self.layout
        row = layout.row()
        row.prop_search(context.scene, "mesh_obj", bpy.data, "objects", text="Skinned Mesh")
        row = layout.row()
        row.prop_search(context.scene, "armature_obj", bpy.data, "objects", text="Armature")
        row = layout.row()
        row.prop(context.scene, "src_group_suffix")
        row = layout.row()
        row.prop(context.scene, "tar_group_suffix")
        row = layout.row()
        row.prop(context.scene, "mirror_axis")
        row = layout.row()
        row.prop(context.scene, "mirror_weight_dist_threshold")
        row = layout.row()
        row.operator("object.mirror_weights_operator", text="Mirror Weights")


class MirrorWeightsOperator(bpy.types.Operator):
    bl_idname = "object.mirror_weights_operator"
    bl_label = "Mirror Weights Operator"

    def execute(self, context):
        # Get the armature and mesh
        armature = bpy.context.scene.armature_obj
        mesh = bpy.context.scene.mesh_obj
        edit_bones = armature.data.edit_bones
        bones = armature.pose.bones

        # Build dictionary of bones to mirror
        bones_to_mirror = {}
        for bone in bones:
            if bone.name.endswith(context.scene.src_group_suffix):
                bone_id = bone.name.rstrip(context.scene.src_group_suffix)
                for other_bone in bones:
                    if other_bone.name == (bone_id + context.scene.tar_group_suffix):
                        bones_to_mirror[bone.name] = other_bone.name
        
        for bone in bones:
            if bone.name in bones_to_mirror:
                # Find the left and right vertex groups
                left_bone_name = bones_to_mirror[bone.name]
                right_bone_name = bone.name
                left_group = None
                right_group = None
                
                for vg in mesh.vertex_groups:
                    if vg.name == right_bone_name:
                        right_group = vg
                    if vg.name == left_bone_name:
                        left_group = vg
                        
                if left_group != None and right_group != None:
                    
                    # Create new temp vertex group that will store the mirrored values
                    temp_vg = mesh.vertex_groups.new(name='TempGroup')
                    
                    # Mirror the values from the source group
                    for vert in mesh.data.vertices:
                                
                        # Get the weights of the source vertex group for the current vertex
                        source_weights = [g.weight for g in vert.groups if g.group == right_group.index]
                        
                        if (len(source_weights) > 0):
                            # Find the mirrored vertex and apply theses values on the new group
                            target_pos = [0,0,0]
                            
                            if context.scene.mirror_axis == 'OP1':
                                target_pos = [-vert.co.x, vert.co.y, vert.co.z]
                            elif context.scene.mirror_axis == 'OP2':
                                target_pos = [vert.co.x, -vert.co.y, vert.co.z]
                            elif context.scene.mirror_axis == 'OP3':
                                target_pos = [vert.co.x, vert.co.y, -vert.co.z]
                            
                            for opp_vert in mesh.data.vertices:
                                dist = math.dist(opp_vert.co, target_pos)
                                # Some small epsilon that you can change
                                if dist < context.scene.mirror_weight_dist_threshold:
                                    temp_vg.add([opp_vert.index], source_weights[0], 'REPLACE')
                                    
                    # Delete target group and rename our mirrored group
                    temp_name = left_group.name
                    mesh.vertex_groups.remove(left_group)
                    temp_vg.name = temp_name
                    
        return {'FINISHED'}


def register():
    bpy.utils.register_class(MirrorWeightsUI)
    bpy.utils.register_class(MirrorWeightsOperator)
    bpy.types.Scene.src_group_suffix = bpy.props.StringProperty(name="Source Group Suffix", default="_R")
    bpy.types.Scene.tar_group_suffix = bpy.props.StringProperty(name="Target Group Suffix", default="_L")
    bpy.types.Scene.mirror_weight_dist_threshold = bpy.props.FloatProperty(name="Distance Threshold", default=0.0001, precision=4)
    bpy.types.Scene.mesh_obj = bpy.props.PointerProperty(type=bpy.types.Object)
    bpy.types.Scene.armature_obj = bpy.props.PointerProperty(type=bpy.types.Object)
    bpy.types.Scene.mirror_axis = bpy.props.EnumProperty(
        name= "Mirror Axis",
        description= "sample text",
        items= [('OP1', "X", ""),
                ('OP2', "Y", ""),
                ('OP3', "Z", "")
        ]
    )


def unregister():
    bpy.utils.unregister_class(MirrorWeightsUI)
    bpy.utils.unregister_class(MirrorWeightsOperator)
    del bpy.types.Scene.src_group_suffix
    del bpy.types.Scene.tar_group_suffix
    del bpy.types.Scene.mirror_axis
    del bpy.types.Scene.mesh_obj
    del bpy.types.Scene.armature_obj
    del bpy.types.Scene.mirror_weight_dist_threshold


if __name__ == "__main__":
    register()
