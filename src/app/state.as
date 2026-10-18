namespace SBCC {
    Meta::Plugin@ pluginMeta = Meta::ExecutingPlugin();

    namespace App {
        [Setting hidden name="Show counter"]
        bool showCounter = true;
        [Setting hidden name="Hide with game UI"]
        bool hideWithGame = true;
        [Setting hidden name="Hide with Openplanet UI"]
        bool hideWithOp = false;
        [Setting hidden name="Lock position"]
        bool lockPosition = false;
        [Setting hidden name="Counter position"]
        vec2 counterPosition = vec2(30, 350);

        int counterFont = -1;
        vec2 counterDrawPosition;
        vec2 counterSize;
        bool draggingCounter = false;
        vec2 counterDragOffset;

        string MenuTitle() {
            return Icons::FlagCheckered + " " + pluginMeta.Name;
        }
    }
}
