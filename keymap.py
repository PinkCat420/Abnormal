import bpy

addon_keymaps = []

# Define all the keymaps in a list of dictionaries
keymap_definitions = [
    # SELECTION KEYMAP
    {'idname': 'New Click Selection', 'type': 'RIGHTMOUSE', 'value': 'PRESS'},
    {'idname': 'Add Click Selection', 'type': 'RIGHTMOUSE', 'value': 'PRESS', 'shift': True},
    {'idname': 'New Loop Selection', 'type': 'RIGHTMOUSE', 'value': 'PRESS', 'alt': True},
    {'idname': 'Add Loop Selection', 'type': 'RIGHTMOUSE', 'value': 'PRESS', 'alt': True, 'shift': True},
    {'idname': 'New Shortest Path Selection', 'type': 'RIGHTMOUSE', 'value': 'PRESS', 'ctrl': True},
    {'idname': 'Add Shortest Path Selection', 'type': 'RIGHTMOUSE', 'value': 'PRESS', 'ctrl': True, 'shift': True},
    {'idname': 'Invert Selection', 'type': 'I', 'value': 'PRESS'},
    {'idname': 'Select Linked', 'type': 'L', 'value': 'PRESS', 'ctrl': True},
    {'idname': 'Select Hover Linked', 'type': 'L', 'value': 'PRESS'},
    {'idname': 'Select All', 'type': 'A', 'value': 'PRESS'},
    {'idname': 'Deselect All', 'type': 'A', 'value': 'PRESS', 'alt': True},
    {'idname': 'Box Select Start', 'type': 'B', 'value': 'PRESS'},
    {'idname': 'Box Select Start Selection', 'type': 'LEFTMOUSE', 'value': 'PRESS', 'any': True},
    {'idname': 'Box New Selection', 'type': 'LEFTMOUSE', 'value': 'RELEASE', 'any': True},
    {'idname': 'Box Add Selection', 'type': 'LEFTMOUSE', 'value': 'RELEASE', 'shift': True},
    {'idname': 'Box Remove Selection', 'type': 'LEFTMOUSE', 'value': 'RELEASE', 'ctrl': True},
    {'idname': 'Lasso Select Start', 'type': 'V', 'value': 'PRESS'},
    {'idname': 'Lasso Select Start Selection', 'type': 'LEFTMOUSE', 'value': 'PRESS', 'any': True},
    {'idname': 'Lasso New Selection', 'type': 'LEFTMOUSE', 'value': 'RELEASE', 'any': True},
    {'idname': 'Lasso Add Selection', 'type': 'LEFTMOUSE', 'value': 'RELEASE', 'shift': True},
    {'idname': 'Lasso Remove Selection', 'type': 'LEFTMOUSE', 'value': 'RELEASE', 'ctrl': True},
    {'idname': 'Circle Select Start', 'type': 'C', 'value': 'PRESS'},
    {'idname': 'Circle Select Start Selection', 'type': 'LEFTMOUSE', 'value': 'PRESS', 'any': True},
    {'idname': 'Circle End Selection', 'type': 'LEFTMOUSE', 'value': 'RELEASE', 'any': True},
    {'idname': 'Circle Add Selection', 'type': 'LEFTMOUSE', 'value': 'PRESS'},
    {'idname': 'Circle Remove Selection', 'type': 'LEFTMOUSE', 'value': 'PRESS', 'ctrl': True},
    {'idname': 'Circle Increase Size 1', 'type': 'RIGHT_BRACKET', 'value': 'PRESS'},
    {'idname': 'Circle Increase Size 2', 'type': 'WHEELUPMOUSE', 'value': 'PRESS', 'alt': True},
    {'idname': 'Circle Decrease Size 1', 'type': 'LEFT_BRACKET', 'value': 'PRESS'},
    {'idname': 'Circle Decrease Size 2', 'type': 'WHEELDOWNMOUSE', 'value': 'PRESS', 'alt': True},
    {'idname': 'Circle Resize Mode Start', 'type': 'F', 'value': 'PRESS'},
    {'idname': 'Circle Resize Confirm', 'type': 'F', 'value': 'RELEASE', 'any': True},

    # SHORTCUTS KEYMAP
    {'idname': 'Rotate Normals', 'type': 'R', 'value': 'PRESS'},
    {'idname': 'Toggle X-Ray', 'type': 'Z', 'value': 'PRESS'},
    {'idname': 'Hide Unselected', 'type': 'H', 'value': 'PRESS', 'shift': True},
    {'idname': 'Hide Selected', 'type': 'H', 'value': 'PRESS'},
    {'idname': 'Unhide', 'type': 'H', 'value': 'PRESS', 'alt': True},
    {'idname': 'Reset Gizmo Rotation', 'type': 'R', 'value': 'PRESS', 'alt': True},
    {'idname': 'Toggle Gizmo', 'type': 'G', 'value': 'PRESS'},
    {'idname': 'Mirror Normals Start', 'type': 'M', 'value': 'PRESS'},
    {'idname': 'Mirror Normals X', 'type': 'X', 'value': 'PRESS'},
    {'idname': 'Mirror Normals Y', 'type': 'Y', 'value': 'PRESS'},
    {'idname': 'Mirror Normals Z', 'type': 'Z', 'value': 'PRESS'},
    {'idname': 'Smooth Normals', 'type': 'S', 'value': 'PRESS'},
    {'idname': 'Flatten Normals Start', 'type': 'F', 'value': 'PRESS'},
    {'idname': 'Flatten Normals X', 'type': 'X', 'value': 'PRESS'},
    {'idname': 'Flatten Normals Y', 'type': 'Y', 'value': 'PRESS'},
    {'idname': 'Flatten Normals Z', 'type': 'Z', 'value': 'PRESS'},
    {'idname': 'Align Normals Start', 'type': 'E', 'value': 'PRESS'},
    {'idname': 'Align Normals Pos X', 'type': 'X', 'value': 'PRESS'},
    {'idname': 'Align Normals Pos Y', 'type': 'Y', 'value': 'PRESS'},
    {'idname': 'Align Normals Pos Z', 'type': 'Z', 'value': 'PRESS'},
    {'idname': 'Align Normals Neg X', 'type': 'X', 'value': 'PRESS', 'shift': True},
    {'idname': 'Align Normals Neg Y', 'type': 'Y', 'value': 'PRESS', 'shift': True},
    {'idname': 'Align Normals Neg Z', 'type': 'Z', 'value': 'PRESS', 'shift': True},
    {'idname': 'Copy Active Normal', 'type': 'C', 'value': 'PRESS', 'ctrl': True},
    {'idname': 'Paste Stored Normal', 'type': 'V', 'value': 'PRESS', 'ctrl': True},
    {'idname': 'Paste Active Normal to Selected', 'type': 'V', 'value': 'PRESS', 'shift': True, 'ctrl': True},
    {'idname': 'Set Normals Outside', 'type': 'N', 'value': 'PRESS', 'shift': True},
    {'idname': 'Set Normals Inside', 'type': 'N', 'value': 'PRESS', 'shift': True, 'ctrl': True},
    {'idname': 'Flip Normals', 'type': 'R', 'value': 'PRESS', 'shift': True},
    {'idname': 'Reset Vectors', 'type': 'R', 'value': 'PRESS', 'ctrl': True},
    {'idname': 'Set Normals From Faces', 'type': 'F', 'value': 'PRESS', 'ctrl': True},
    {'idname': 'Average Individual Normals', 'type': 'Q', 'value': 'PRESS'},
    {'idname': 'Average Selected Normals', 'type': 'W', 'value': 'PRESS'},
    {'idname': 'Cancel Modal', 'type': 'ESC', 'value': 'PRESS'},
    {'idname': 'Confirm Modal', 'type': 'TAB', 'value': 'PRESS'},
    {'idname': 'History Undo', 'type': 'Z', 'value': 'PRESS', 'ctrl': True},
    {'idname': 'History Redo', 'type': 'Z', 'value': 'PRESS', 'ctrl': True, 'shift': True},

    # TOOLS KEYMAP
    {'idname': 'Rotate X Axis', 'type': 'X', 'value': 'PRESS'},
    {'idname': 'Rotate Y Axis', 'type': 'Y', 'value': 'PRESS'},
    {'idname': 'Rotate Z Axis', 'type': 'Z', 'value': 'PRESS'},
    {'idname': 'Target Move Start', 'type': 'G', 'value': 'PRESS'},
    {'idname': 'Target Center Reset', 'type': 'G', 'value': 'PRESS', 'alt': True},
    {'idname': 'Target Move X Axis', 'type': 'X', 'value': 'PRESS'},
    {'idname': 'Target Move Y Axis', 'type': 'Y', 'value': 'PRESS'},
    {'idname': 'Target Move Z Axis', 'type': 'Z', 'value': 'PRESS'},
    {'idname': 'Filter Mask From Selected', 'type': 'G', 'value': 'PRESS', 'ctrl': True},
    {'idname': 'Clear Filter Mask', 'type': 'G', 'value': 'PRESS', 'alt': True},
    {'idname': 'Confirm Tool 1', 'type': 'LEFTMOUSE', 'value': 'PRESS', 'any': True},
    {'idname': 'Confirm Tool 2', 'type': 'RET', 'value': 'PRESS', 'any': True},
    {'idname': 'Confirm Tool 3', 'type': 'LEFTMOUSE', 'value': 'RELEASE', 'any': True},
    {'idname': 'Cancel Tool 1', 'type': 'ESC', 'value': 'PRESS', 'any': True},
    {'idname': 'Cancel Tool 2', 'type': 'RIGHTMOUSE', 'value': 'PRESS', 'any': True},
    {'idname': 'UI Click', 'type': 'LEFTMOUSE', 'value': 'PRESS'},
    {'idname': 'UI Click', 'type': 'LEFTMOUSE', 'value': 'RELEASE'},
    {'idname': 'UI Panel Scroll Up 1', 'type': 'WHEELDOWNMOUSE', 'value': 'PRESS'},
    {'idname': 'UI Panel Scroll Up 2', 'type': 'WHEELOUTMOUSE', 'value': 'PRESS'},
    {'idname': 'UI Panel Scroll Down 1', 'type': 'WHEELUPMOUSE', 'value': 'PRESS'},
    {'idname': 'UI Panel Scroll Down 2', 'type': 'WHEELINMOUSE', 'value': 'PRESS'},
    {'idname': 'Toggle Cyclic Status', 'type': 'F', 'value': 'PRESS'},
    {'idname': 'Reset Point Rotate', 'type': 'R', 'value': 'PRESS', 'alt': True},
    {'idname': 'Reset Point Sharpness', 'type': 'S', 'value': 'PRESS', 'alt': True},
    {'idname': 'Point Rotate Start', 'type': 'R', 'value': 'PRESS'},
    {'idname': 'Point Sharpness Start', 'type': 'S', 'value': 'PRESS'},
    {'idname': 'Delete Selected Points', 'type': 'X', 'value': 'PRESS'},
    {'idname': 'Pass Thru 1', 'type': 'LEFTMOUSE', 'value': 'PRESS', 'any': True},
    {'idname': 'Pass Thru 2', 'type': 'LEFTMOUSE', 'value': 'RELEASE', 'any': True},
    {'idname': 'Pass Thru 3', 'type': 'LEFTMOUSE', 'value': 'CLICK', 'any': True},
    {'idname': 'Pass Thru 4', 'type': 'N', 'value': 'PRESS'},
]


def register():
    # handle the keymap
    wm = bpy.context.window_manager
    kc = wm.keyconfigs.addon
    if kc:
        km = wm.keyconfigs.addon.keymaps.new(name='Abnormal', space_type='EMPTY')
        for kmi_props in keymap_definitions:
            kmi = km.keymap_items.new(**kmi_props)

        addon_keymaps.append(km)


def unregister():
    for km in addon_keymaps:
        for i in range(len(km.keymap_items)):
            km.keymap_items.remove(km.keymap_items[0])
    addon_keymaps.clear()
