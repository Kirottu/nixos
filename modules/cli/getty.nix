{ config, lib, ... }:
{
  options.cli.getty = {
    enable = lib.mkEnableOption "Getty configuration";

    dm = {
      enable = lib.mkEnableOption "TTY1 autologin";
      command = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "Command that is autostarted on TTY1";
      };
    };
  };

  config = lib.mkIf config.cli.getty.enable {
    environment.etc.issue.text =
      {
        diagonals = ''
          [1;31m
                        #      #                                              
                       **      **#                                            
                      ***      *%*                                            
                      ***%      **%                                           
                    #%####     ###%#                                          
                    ##%*###   ##*#%#                                          
                    ##%%#*#%*#*#*%##%                                         
                    #**%#%%*#***%**#                                          
                    **+#%**#**#%#+**                                          
                     *%*#****%%#***%          [0mPraise [1mHarold[0m,[1;31m
                      #**##+%##**##           [0mchosen of the [1mMarker[0m,[1;31m
                     ***#**%***#**            [0marchitect of the [1mChurch[0m.[1;31m
                    **+*#*%##**#*%+                                           
                    #***%#******%**                  
                    ###%%*#**#*%*%#                       
                    *#%%##****#%**            [0m\l[1;31m
                     *%###****%###            [0mNixOS \S{BUILD_ID}[1;31m                
                       ******#***                                             
                       ****#*%**                                              
                         #+**%                                                
                           ##                                                 
          [0m
        '';
        bliss = ''

          In these lands, shall the light of Harold shine upon us all.

          TODO
        '';
      }
      .${config.theming.theme};

  };
}
