namespace SBCC {
    namespace Offsets {

        // Ty ArEyeses for letting me use your reflection code :PeepoHeart:
        // And ty XertroV for finding the offsets in the first place xD

        const uint replayFromRules = 0x9F0 - 0x938;
        const uint bufferFromRespawns = 0x8;
        const uint bufferLength = 0x8;
        const uint checkpointStride = 0x8;
        const uint landmarkIdMask = 0x03000000;
        uint16 arenaReplay;
        uint16 ghostCheckpoints;

        bool Initialize() {
            try {
                auto rules = Reflection::GetType("CSmArena").GetMember("Rules");
                auto respawns = Reflection::GetType("CGameCtnGhost").GetMember("NbRespawns");
                if (rules is null ||
                    respawns is null ||
                    rules.Offset == 0 ||
                    respawns.Offset == 0 ||
                    rules.Offset + replayFromRules > 0xFFFF ||
                    respawns.Offset + bufferFromRespawns + bufferLength > 0xFFFF
                ) {
                    throw("Required reflected members are unavailable");
                }
                arenaReplay = uint16(rules.Offset + replayFromRules);
                ghostCheckpoints = uint16(respawns.Offset + bufferFromRespawns);
                return true;
            } catch {
                Counter::status = "Checkpoint offsets unavailable";
                log(Counter::status + ": " + getExceptionInfo(), LogLevel::Error);
                return false;
            }
        }
    }
}
