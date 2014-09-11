vindinium-client
======

Simple Vindinium client library for D

See https://github.com/dymk/vindinium-starter-d for an example project using this

To create a game, use the `Vindinium` struct:
 - `this(string key, string server, Mode mode, uint turns, string map)`

where Mode is defined as:
```d
enum Mode {
    Training,
    Arena
}
```

Call `.connect()` on the struct to create a `VindiniumGame`:
```d
  import vindinium;
  auto vin = Vindinium(key, server, mode, turns, map);
  auto game = vin.connect();
```

Send commands to the client until the game is finished:
```d
  while(!game.finished) {
    auto cmd = uniform!(VindiniumGame.Command);
    game.send_command(cmd);

    writefln("Turn %3d: Issued command: %s", game.turn, cmd);
  }
```

Access the current game state (data structures are in `comm.d`) through `.state`:
```d
  auto board = game.state.game.board;
  auto hero  = game.state.hero;
  // etc
```
