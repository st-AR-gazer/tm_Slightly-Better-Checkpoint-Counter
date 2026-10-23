namespace SBCC {
    namespace App {
        const vec2 defaultPosition = vec2(30, 968);
        const vec4 defaultColor = vec4(1, 1, 1, 1);

        [Setting hidden name="Show counter"]
        bool showCounter = true;
        [Setting hidden name="Hide with game UI"]
        bool hideWithGame = true;
        [Setting hidden name="Hide with Openplanet UI"]
        bool hideWithOp = false;
        [Setting hidden name="Lock position"]
        bool lockPosition = false;
        [Setting hidden name="Center horizontally"]
        bool centerHorizontally = true;
        [Setting hidden name="Counter position"]
        vec2 counterPosition = defaultPosition;
        [Setting hidden name="Counter color"]
        vec4 counterColor = defaultColor;
        [Setting hidden name="Nudge step (px)"]
        int nudgeStep = 1;
        [Setting hidden name="Checkpoint sound"]
        bool checkpointSound = true;
        [Setting hidden name="Checkpoint sound choice"]
        int checkpointSoundChoice = Sound::defaultChoice;
        [Setting hidden name="Checkpoint sound volume"]
        int checkpointVolume = 25;
    }
}
