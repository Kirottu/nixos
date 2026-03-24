{
  config = {
    hm.programs.git = {
      enable = true;
      signing = {
        signByDefault = true;
        format = "openpgp";
      };
      settings = {
        user.name = "Arno Vaara";
        user.email = "arnovaara@kirottu.com";
        init.defaultBranch = "main";
      };
    };
    hm.programs.gh = {
      enable = true;
    };
    impermanence.userFiles = [
      ".config/gh/hosts.yml"
    ];
  };
}
