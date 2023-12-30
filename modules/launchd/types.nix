{ lib, ... }:

let
  hasDuplicates = li: let
    li' = lib.lists.forEach li (lib.attrsets.filterAttrs (n: v: v != null));
  in (lib.lists.unique li') != li';
in

with lib; {
  StartCalendarInterval = let
    CalendarIntervalEntry = types.submodule {
      options = {
        Minute = mkOption {
          type = types.nullOr (types.ints.between 0 59);
          default = null;
          defaultText = lib.literalMD "`*`";
          description = lib.mdDoc ''
            The minute on which this job will be run.
          '';
        };

        Hour = mkOption {
          type = types.nullOr (types.ints.between 0 23);
          default = null;
          defaultText = lib.literalMD "`*`";
          description = lib.mdDoc ''
            The hour on which this job will be run.
          '';
        };

        Day = mkOption {
          type = types.nullOr (types.ints.between 1 31);
          default = null;
          defaultText = lib.literalMD "`*`";
          description = lib.mdDoc ''
            The day on which this job will be run.
          '';
        };

        Weekday = mkOption {
          type = types.nullOr (types.ints.between 0 7);
          default = null;
          defaultText = lib.literalMD "`*`";
          description = lib.mdDoc ''
            The weekday on which this job will be run (0 and 7 are Sunday).
          '';
        };

        Month = mkOption {
          type = types.nullOr (types.ints.between 1 12);
          default = null;
          defaultText = lib.literalMD "`*`";
          description = lib.mdDoc ''
            The month on which this job will be run.
          '';
        };
      };
    };
  in
    types.addCheck (types.listOf CalendarIntervalEntry) (li: li != [] && !(hasDuplicates li));
}
