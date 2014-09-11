module vindinium.game_objs;

import stdx.data.json;
import std.conv;
import std.bitmanip;

struct Pos {
    uint x, y;

    void update_from_json(JSONValue json) {
        auto pos = json.get!(JSONValue[string]);

        this.x = pos["x"].get!double.to!uint;
        this.y = pos["y"].get!double.to!uint;
    }
}

struct Hero {
    int id;
    string name;
    string user_id;
    uint elo;
    Pos pos;
    uint life;
    uint gold;
    uint mine_count;
    Pos spawn;
    bool crashed;

    void update_from_json(JSONValue json) {
        auto hero = json.get!(JSONValue[string]);

        this.id         = hero["id"].get!double.to!int;
        this.name       = hero["name"].get!string;
        this.pos.update_from_json(hero["pos"]);
        this.life       = hero["life"].get!double.to!uint;
        this.gold       = hero["gold"].get!double.to!uint;
        this.mine_count = hero["mineCount"].get!double.to!uint;
        this.spawn.update_from_json(hero["spawnPos"]);
        this.crashed    = hero["crashed"].get!bool;

        // might not be in the JSON response, as they're training dummies
        if("elo" in hero)    this.elo = hero["elo"].get!double.to!uint;
        if("userId" in hero) this.user_id    = hero["userId"].get!string;
    }
}

struct Board {
    struct Tile {
        enum Type : ubyte {
            Empty,
            Wood,
            Hero,
            Tavern,
            Mine
        }

    private:
        mixin(bitfields!(
            // type of the item
            Type, "_type", 3,
            // is the tavern neutral?
            bool, "_neutral", 1,
            // hero ID
            uint, "_id", 4));

    public:
        Type type() { return _type; }
        bool neutral() {
            assert(type == Type.Mine);
            return _neutral;
        }

        uint id() {
            assert(type == Type.Hero || type == Type.Mine);
            return  _id;
        }

        this(Type type, uint id) {
            assert(type == Type.Hero || type == Type.Mine);
            this._type = type;
            this._id   = id;
            this._neutral = false;
        }

        this(Type type) {
            this._type = type;
            this._neutral = true;
        }
    }

    // board dimentions
    uint size;

    // [x][y]
    Tile[][] tiles;

    void update_from_json(JSONValue json) {
        auto board = json.get!(JSONValue[string]);

        immutable size = board["size"].get!double.to!uint;
        auto tiles_str = board["tiles"].get!string;

        assert((size * size) == (tiles_str.length/2),
            "Size vs actual tile string length mismatch!");

        if(this.size != size) {
            // reallocate tiles
            this.tiles = new Tile[][](size, size);
        }
        this.size = size;

        uint idx = 0;
        foreach(y; 0..size) {
        foreach(x; 0..size) {
            Tile t;
            string tile = tiles_str[idx .. idx + 2];

            if(tile == "  ") {
                t = Tile(Tile.Type.Empty);
            }
            else if(tile == "##") {
                t = Tile(Tile.Type.Wood);
            }
            else if(tile[0] == '@') {
                t = Tile(Tile.Type.Hero, tile[1 .. 2].to!uint);
            }
            else if(tile == "[]") {
                t = Tile(Tile.Type.Tavern);
            }
            else if(tile[0] == '$') {
                if(tile[1] == '-') {
                    t = Tile(Tile.Type.Mine);
                }
                else {
                    t = Tile(Tile.Type.Mine, tile[1 .. 2].to!uint);
                }
            }
            else {
                assert(false, "Invalid tile on board: `" ~ tile ~ "`");
            }

            this.tiles[x][y] = t;
            idx += 2;
        }
        }
    }
}

struct Game {
    string id;
    uint turn;
    uint max_turns;
    Hero[] heros;
    Board board;
    bool finished;

    void update_from_json(JSONValue json) {
        auto game = json.get!(JSONValue[string]);

        this.id          = game["id"].get!string;
        this.turn        = game["turn"].get!double.to!uint;
        this.max_turns   = game["maxTurns"].get!double.to!uint;

        auto heroes_json = game["heroes"].get!(JSONValue[]);
        if(!this.heros.length) {
            this.heros = new Hero[](heroes_json.length);
        }

        foreach(i, hero_json; heroes_json) {
            this.heros[i].update_from_json(hero_json);
        }

        this.board.update_from_json(game["board"]);
        this.finished = game["finished"].get!bool;
    }
}

struct GameResponse {
    Game game; /// initial game state
    Hero hero; /// the player's hero
    string token;
    string view_url;
    string play_url;

    void update_from_json(JSONValue json) {
        auto gr = json.get!(JSONValue[string]);

        this.game.update_from_json(gr["game"]);
        this.hero.update_from_json(gr["hero"]);
        this.token    = gr["token"].get!string;
        this.view_url = gr["viewUrl"].get!string;
        this.play_url = gr["playUrl"].get!string;
    }
}
