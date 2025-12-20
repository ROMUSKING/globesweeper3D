extends EditorPlugin

func _enter_tree():
    # Disable 'Use Multiple Windows' setting when editor starts
    if ProjectSettings.has_setting("interface/editor/use_multiple_windows"):
        ProjectSettings.set_setting("interface/editor/use_multiple_windows", false)
        print("Disabled 'Use Multiple Windows' setting")
    else:
        print("Warning: 'use_multiple_windows' setting not found")

func _exit_tree():
    pass