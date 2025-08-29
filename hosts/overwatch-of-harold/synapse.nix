{ ... }:
{
  config = {
    services.matrix-synapse = {
      enable = false;
      configureRedisLocally = true;
    };
  };
}
