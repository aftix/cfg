# SPDX-FileType: SOURCE
# SPDX-FileCopyrightText: (C) 2026 aftix
# SPDX-License-Identifier: EUPL-1.2
args: let
  inherit (args) lib config;
in {
  options.aftix.discord = {
    enable = lib.mkEnableOption "discord configured with nixcord";
  };

  config = lib.mkIf config.aftix.discord.enable {
    programs.nixcord = {
      enable = true;

      homeDirectory = config.home.homeDirectory;

      discord = {
        krisp.enable = true;
        equicord.enable = true;
        commandLineArgs = ["--enable-features=VaapiVideoDecoder" "--ozone-platform-hint=auto" "--enable-wayland-ime"];
        installPackage = true;
      };

      config = {
        enabledThemeLinks = [
          "https://raw.githubusercontent.com/refact0r/system24/main/theme/system24.theme.css"
        ];
        frameless = true;

        plugins = {
          autoZipper.enable = true;
          betterAudioPlayer.enable = true;
          betterBlockedUsers.enable = true;
          betterForwards.enable = true;
          betterInvites.enable = true;
          cancelFriendRequest.enable = true;
          cleanerChannelGroups.enable = true;
          clickableRoles.enable = true;
          clipUpload.enable = true;
          declutter.enable = true;
          disableCameras.enable = true;
          downloadAllAttachments.enable = true;
          dragFavoriteEmotes.enable = true;
          dragify.enable = true;
          fileUpload.enable = true;
          findReply.enable = true;
          fixFileExtensions.enable = true;
          ghosted.enable = true;
          homeTyping.enable = true;
          iRememberYou.enable = true;
          keyboardNavigation.enable = true;
          noNitroUpsell.enable = true;
          normalizeMessageLinks.enable = true;
          notificationTitle.enable = true;
          pinIcon.enable = true;
          recentDmSwitcher.enable = true;
          scheduledMessages.enable = true;
          searchFix.enable = true;
          sedEnhanced.enable = true;
          showMessageEmbeds.enable = true;
          splitLargeMessages.enable = true;
          statusPresets.enable = true;
          toneIndicators.enable = true;
          unitConverter.enable = true;
          zipPreview.enable = true;
        };
      };
    };
  };
}
