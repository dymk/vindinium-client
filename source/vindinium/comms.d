module vindinium.comms;

/**
 * Server communications module
 */

private {
    import vindinium;
    import stdx.data.json;

    import std.net.curl;
    import std.string;
    import std.stdio;
    import std.exception;
}

enum Flags {
    Get = 0x1,
    Set = 0x2,
    Both = 0x3
}

struct Vindinium {
    /// Game modes
    enum Mode {
        Training,
        Arena
    }

    /// The AI's private API key
    string key;

    /// Server to play the game on
    const string server;

    /// Mode that the hero is playing in
    Mode mode;

    /// Number of turns to play the game
    uint turns;

    /// Name of the map to play: "m{1..6}"
    string map;

    // Connection shared between game instances
    private HTTP conn;

    this(string key, string server, Mode mode, uint turns, string map) {
        this.conn = HTTP();
        this.key = key;
        this.server = server;
        this.mode = mode;
        this.turns = turns;
        this.map = map;

        conn.addRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        conn.setUserAgent("Vindinium-D-Client/0.0.1");
    }

    VindiniumGame connect() {
        string uri;
        final switch(mode)
        with(Mode) {
            case Training:
                uri = server ~ "/api/training";
                break;

            case Arena:
                uri = server ~ "/api/arena";
                break;
        }

        string post_data = format("key=%s&turns=%s&map=%s", key, turns, map);
        string response = post(uri, post_data, conn).assumeUnique;

        return VindiniumGame(conn, key, response);
    }
}

struct VindiniumGame {

    /// Commands that the hero can be issued
    enum Command {
        Stay,
        North,
        South,
        East,
        West
    }

    private {
        HTTP conn;
        string key;
        GameResponse *gr;
    }

    package
    this(ref HTTP conn, string key, string initial_game) {
        this.conn = conn;
        this.key = key;
        this.gr = new GameResponse();

        parse_response(initial_game);
    }

    // delegate to gameresponse
    string play_url() @property { return gr.play_url; }
    string view_url() @property { return gr.view_url; }
    bool   finished() @property { return gr.game.finished; }
    uint   turn()     @property { return gr.game.turn; }

    auto state() @property const { return gr; }

    void send_command(Command cmd)
    in { assert(!finished); }
    body {
        string cmd_str;
        final switch(cmd)
        with(Command) {
            case Stay: cmd_str = "Stay"; break;
            case North: cmd_str = "North"; break;
            case South: cmd_str = "South"; break;
            case East: cmd_str = "East"; break;
            case West: cmd_str = "West"; break;
        }

        auto post_data = format("key=%s&dir=%s", key, cmd_str);
        string response = post(play_url, post_data, conn).assumeUnique;

        // TODO: merge changes instead of overwriting the game response
        parse_response(response);
    }

    private void parse_response(string resp) {
        auto json = parseJSONValue(resp);
        gr.update_from_json(json);
    }
}
