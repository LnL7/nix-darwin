{ lib, fetchurl, writeShellApplication, aria2 }:

# These URLs are from https://github.com/insidegui/VirtualBuddy/blob/main/data/ipsws_v1.json
let
  addFetchScript = fetcher: let
    inherit (fetcher) name url outputHash;
  in fetcher // {
    fetchScript = writeShellApplication {
      name = "fetch-${name}";
      runtimeInputs = [ aria2 ];
      text = ''
        aria2c -x4 "${url}" -o "${name}"
        hash=$(nix-hash --type sha256 --to-sri "$(nix-hash --flat --type sha256 "${name}")")
        if [[ "$hash" != "${outputHash}" ]]; then
          echo "error: hashes don't match"
          echo "expected = ${outputHash}"
          echo "   got   = $hash"
          echo "remove ${name} and try again"
          exit 1
        fi
        nix-store --add-fixed sha256 "${name}"
        rm "${name}"
      '';
    };
  };
in lib.mapAttrs (key: fetcher: addFetchScript fetcher) {
  "12.3.1" = fetchurl {
    name = "UniversalMac_12.3.1_21E258_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SpringFCS/fullrestores/002-79219/851BEDF0-19DB-4040-B765-0F4089D1530D/UniversalMac_12.3.1_21E258_Restore.ipsw";
    hash = "sha256-ywRDUlVx6l5UqlqP2cUndFkYkjEUBRg3QfSgL5k+GNU=";
  };

  "12.4" = fetchurl {
    name = "UniversalMac_12.4_21F79_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SpringFCS/fullrestores/012-06874/9CECE956-D945-45E2-93E9-4FFDC81BB49A/UniversalMac_12.4_21F79_Restore.ipsw";
    hash = "sha256-H56SH3e7y1z3gCY4nW9zMc3WdbwIH/rHf8AEBafoIrM=";
  };

  "12.5" = fetchurl {
    name = "UniversalMac_12.5_21G72_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerFCS/fullrestores/012-42731/BD9917E0-262C-41C5-A69F-AC316A534A39/UniversalMac_12.5_21G72_Restore.ipsw";
    hash = "sha256-Set08zE7Cwwi1MBV9WciFD/a4eXMsdy/d5oaTE3LxCs=";
  };

  "12.5.1" = fetchurl {
    name = "UniversalMac_12.5.1_21G83_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerFCS/fullrestores/012-51674/A7019DDB-3355-470F-A355-4162A187AB6C/UniversalMac_12.5.1_21G83_Restore.ipsw";
    hash = "sha256-l6XGHiHp3fJRWOydyme0giBfndMR0nShpZkVtLsELIM=";
  };

  "12.6" = fetchurl {
    name = "UniversalMac_12.6_21G115_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallFCS/fullrestores/012-40537/0EC7C669-13E9-49FB-BD64-9EECC1D174B2/UniversalMac_12.6_21G115_Restore.ipsw";
    hash = "sha256-URP408d/1yXqY1fO1XZLxXGD0tOISSxYxG/ycp0GWOU=";
  };

  "12.6.1" = fetchurl {
    name = "UniversalMac_12.6.1_21G217_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallFCS/fullrestores/012-66032/8D8D90C6-A876-4FFF-BBF4-D158939B3841/UniversalMac_12.6.1_21G217_Restore.ipsw";
    hash = "sha256-ZZdnJlNkRttOgr3bqrAwaArfBMN+sze7aMOIiGA1w7s=";
  };

  "13.0" = fetchurl {
    name = "UniversalMac_13.0_22A380_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallFCS/fullrestores/012-92188/2C38BCD1-2BFF-4A10-B358-94E8E28BE805/UniversalMac_13.0_22A380_Restore.ipsw";
    hash = "sha256-U3AIkA/jTutwPZKM5hNwi/vWv0RSiZSAWPxhe+Ty0JA=";
  };

  "13.0.1" = fetchurl {
    name = "UniversalMac_13.0.1_22A400_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallFCS/fullrestores/012-93802/A7270B0F-05F8-43D1-A9AD-40EF5699E82C/UniversalMac_13.0.1_22A400_Restore.ipsw";
    hash = "sha256-WNxmFJR83MlxzH0a6IKz2u5cNLjHIdUROaDP9G07VD8=";
  };

  "13.1" = fetchurl {
    name = "UniversalMac_13.1_22C65_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallFCS/fullrestores/012-60270/0A7F49BA-FC31-4AD9-8E45-49B1FB9128A6/UniversalMac_13.1_22C65_Restore.ipsw";
    hash = "sha256-mN0Wf7QrNF77rcYsi/dPqpjsPX5geQhdyS75jHeXsUs=";
  };

  "13.2" = fetchurl {
    name = "UniversalMac_13.2_22D49_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023WinterFCS/fullrestores/032-35688/0350BB21-2B4B-4850-BF77-70B830283B28/UniversalMac_13.2_22D49_Restore.ipsw";
    hash = "sha256-uoBzLvzA/JrITFf1BM7QnbxDHEnitjO5q9RzDlWsZqU=";
  };

  "13.2.1" = fetchurl {
    name = "UniversalMac_13.2.1_22D68_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023WinterFCS/fullrestores/032-48346/EFF99C1E-C408-4E7A-A448-12E1468AF06C/UniversalMac_13.2.1_22D68_Restore.ipsw";
    hash = "sha256-AxAiDIpUDcU6kuyfngiU22J9j5f9GMMnXrloZabl/gQ=";
  };

  "13.3" = fetchurl {
    name = "UniversalMac_13.3_22E252_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023WinterSeed/fullrestores/002-75537/8250FA0E-0962-46D6-8A90-57A390B9FFD7/UniversalMac_13.3_22E252_Restore.ipsw";
    hash = "sha256-kf4dVYQ5JfJCtKlM4QaQc/miLyKkDrd6Vhi4d+DsnyQ=";
  };

  "13.3.1" = fetchurl {
    name = "UniversalMac_13.3.1_22E261_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023WinterFCS/fullrestores/032-66602/418BC37A-FCD9-400A-B4FA-022A19576CD4/UniversalMac_13.3.1_22E261_Restore.ipsw";
    hash = "sha256-bp2bMFKOyVHYo3cXOzVZMmRxlMMmNH78XlSt4f5xy8g=";
  };

  "13.4" = fetchurl {
    name = "UniversalMac_13.4_22F66_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringFCS/fullrestores/032-84884/F97A22EE-9B5E-4FD5-94C1-B39DCEE8D80F/UniversalMac_13.4_22F66_Restore.ipsw";
    hash = "sha256-RyGSky5BUtINBQRkHfTIV0kpkD8vMkT0W0avfVsuRgY=";
  };

  "13.4.1" = fetchurl {
    name = "UniversalMac_13.4.1_22F82_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringFCS/fullrestores/042-01877/2F49A9FE-7033-41D0-9D0C-64EFCE6B4C22/UniversalMac_13.4.1_22F82_Restore.ipsw";
    hash = "sha256-67s3efxolHWJRYlXLCKHr7ZA0FO+gneKUPTOwljXhBs=";
  };

  "13.5" = fetchurl {
    name = "UniversalMac_13.5_22G74_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SummerFCS/fullrestores/032-69606/D3E05CDF-E105-434C-A4A1-4E3DC7668DD0/UniversalMac_13.5_22G74_Restore.ipsw";
    hash = "sha256-pCpboSako1uunz3NZFZavCIy6fOVTGWM9cq1vZL50ZE=";
  };

  "13.5.1" = fetchurl {
    name = "UniversalMac_13.5.1_22G90_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SummerFCS/fullrestores/042-25658/2D6BE8DB-5549-4F85-8C54-39FC23BABC68/UniversalMac_13.5.1_22G90_Restore.ipsw";
    hash = "sha256-sWlmMRtUqlJJzS7pCemFTgkjw/hQ4psFBhRTfXq+ZX4=";
  };

  "13.5.2" = fetchurl {
    name = "UniversalMac_13.5.2_22G91_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SummerFCS/fullrestores/042-43686/945D434B-DA5D-48DB-A558-F6D18D11AD69/UniversalMac_13.5.2_22G91_Restore.ipsw";
    hash = "sha256-aJGu4KsLlmle8W+lPwa97aQQb2jeUWZxmE60atLg47g=";
  };

  "13.6" = fetchurl {
    name = "UniversalMac_13.6_22G120_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallFCS/fullrestores/042-55833/C0830847-A2F8-458F-B680-967991820931/UniversalMac_13.6_22G120_Restore.ipsw";
    hash = "sha256-m/CVc5uLLV69IPfo3pOPELxEn5hD3iHEpBrlTXNSZyg=";
  };

  "14.0" = fetchurl {
    name = "UniversalMac_14.0_23A344_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallFCS/fullrestores/042-54934/0E101AD6-3117-4B63-9BF1-143B6DB9270A/UniversalMac_14.0_23A344_Restore.ipsw";
    hash = "sha256-xaE3uQWj+fxPt7uhar+mJckRkVT5N1n1caockV09lmQ=";
  };

  "14.1" = fetchurl {
    name = "UniversalMac_14.1_23B74_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallFCS/fullrestores/042-86430/DBE44960-58A6-4715-948B-D64F33F769BD/UniversalMac_14.1_23B74_Restore.ipsw";
    hash = "sha256-GrcFAMwwbGnm476WawKXcKG0wycejuxXpW5Zl9+qDl4=";
  };

  "14.1.1" = fetchurl {
    name = "UniversalMac_14.1.1_23B81_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallFCS/fullrestores/042-89681/55BD14DB-5535-4203-9359-E2C070E43FBE/UniversalMac_14.1.1_23B81_Restore.ipsw";
    hash = "sha256-9/1QInuv4Q0XHe60kZv1UFhbyufvKSQjXA1ihGuD2Zo=";
  };

  "14.2" = fetchurl {
    name = "UniversalMac_14.2_23C64_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallFCS/fullrestores/052-15117/DC2EE605-ABF3-41AE-9652-D137A8AA5907/UniversalMac_14.2_23C64_Restore.ipsw";
    hash = "sha256-vfxHhMP99iJjVwf76hcqoRj93C1RmKOYJUkrEpfHWsY=";
  };

  "14.2.1" = fetchurl {
    name = "UniversalMac_14.2.1_23C71_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallFCS/fullrestores/052-22662/ECE59A41-DACC-4CA5-AB23-FDED1A4567DE/UniversalMac_14.2.1_23C71_Restore.ipsw";
    hash = "sha256-fkROGjG4m0lycQGVN/nIuAgdUofssIVio6asXz2exm8=";
  };

  ## Developer Betas or Release Candidates

  "12.4b1" = fetchurl {
    name = "UniversalMac_12.4_21F5048e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SpringSeed/fullrestores/002-85721/A21FF659-8493-4A16-A989-2C3141F48D8C/UniversalMac_12.4_21F5048e_Restore.ipsw";
    hash = "sha256-RHrFu2XKic2pGD63rKqAir9xtUCYYtiS6kyZgJ5shNA=";
  };

  "12.4b2" = fetchurl {
    name = "UniversalMac_12.4_21F5058e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SpringSeed/fullrestores/002-87587/BC2EBE80-F0F4-4B56-BCDC-340E0AD8E985/UniversalMac_12.4_21F5058e_Restore.ipsw";
    hash = "sha256-4z+v7yGJxkQ2YJBZOdwyLSiSxNUBDtLnIH6+/h9OaK4=";
  };

  "12.4b3" = fetchurl {
    name = "UniversalMac_12.4_21F5063e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SpringSeed/fullrestores/002-90009/DA6BD192-1698-48B3-AB6D-9D3A045ED1B1/UniversalMac_12.4_21F5063e_Restore.ipsw";
    hash = "sha256-SH3vPanvtKH1JXN3kJx9Eo9ZbDIn0gKZw3S7w8l1iO4=";
  };

  "12.4b4" = fetchurl {
    name = "UniversalMac_12.4_21F5071b_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SpringSeed/fullrestores/002-95106/0F7A6388-C4B5-4B8E-B8B2-F62C030699D0/UniversalMac_12.4_21F5071b_Restore.ipsw";
    hash = "sha256-PdoqOKXXpqUNoFtwcz49eG+3k3QXWl4vHlhsZJ94ctU=";
  };

  "12.5b1" = fetchurl {
    name = "UniversalMac_12.5_21G5027d_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallSeed/fullrestores/002-93712/5F234425-6096-43FC-B518-1E9D7B4D0254/UniversalMac_12.5_21G5027d_Restore.ipsw";
    hash = "sha256-5MpM7TvPZ/zquVJuR/Gu8Egi6g3Y4WQsKNi/VJZifCg=";
  };

  "12.5b2" = fetchurl {
    name = "UniversalMac_12.5_21G5037d_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallSeed/fullrestores/012-10648/1CC63FC5-5A22-4A5A-9A7B-C19C8C4A6731/UniversalMac_12.5_21G5037d_Restore.ipsw";
    hash = "sha256-EytzaJmDC8ewbly5d6b2xyZ69Zr99vW6KMNF0uVcIZE=";
  };

  "12.5b3" = fetchurl {
    name = "UniversalMac_12.5_21G5046c_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallSeed/fullrestores/012-18271/FFF202B2-E4B6-4A3E-9681-42A0F3F81B11/UniversalMac_12.5_21G5046c_Restore.ipsw";
    hash = "sha256-NCxRy9IBJIJ/rEP4bFmJ7CdAyvOgEydWq5L2byvhLgs=";
  };

  "12.5b4" = fetchurl {
    name = "UniversalMac_12.5_21G5056b_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallSeed/fullrestores/012-26441/AE0AC638-2773-49D3-BF84-950B10BF39E9/UniversalMac_12.5_21G5056b_Restore.ipsw";
    hash = "sha256-psj41hDtWvi9gAsKPjcofImvw4WQFKE9GMeVnzu9VEs=";
  };

  "12.5b5" = fetchurl {
    name = "UniversalMac_12.5_21G5063a_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallSeed/fullrestores/012-36748/52342C55-6598-4A86-AAB8-8901145792C8/UniversalMac_12.5_21G5063a_Restore.ipsw";
    hash = "sha256-AfoRC0VP92mn/96FrgNmIqESCWkpB+xgFJdAXOrPlWE=";
  };

  "12.5rc1" = fetchurl {
    name = "UniversalMac_12.5_21G69_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerFCS/fullrestores/012-40368/5DD0A524-140A-46AF-91ED-5F28EA9DEC01/UniversalMac_12.5_21G69_Restore.ipsw";
    hash = "sha256-Cc17jNj74VfRZGForale9wz8xLTvXFUQigsvKNRV6wY=";
  };

  "13.0b1" = fetchurl {
    name = "UniversalMac_13.0_22A5266r_Restore.ipsw";
    url = "https://archive.org/download/UniversalMac_13.0_22A5266r_Restore.ipsw/UniversalMac_13.0_22A5266r_Restore.ipsw";
    hash = "sha256-0ZGG/SflRSVYnkpT+a1jGn0TYIl+ADAz34hhKZnP4kk=";
  };

  "13.0b2" = fetchurl {
    name = "UniversalMac_13.0_22A5286j_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerSeed/fullrestores/012-30346/9DD787A7-044B-4650-86D4-84E80B6B9C36/UniversalMac_13.0_22A5286j_Restore.ipsw";
    hash = "sha256-M4xkDOnnJVP9JSn+DgNJKpuNHS1MvyZ5bYSIdQ7y8p4=";
  };

  "13.0b3" = fetchurl {
    name = "UniversalMac_13.0_22A5295h_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerSeed/fullrestores/012-34274/130176F5-C4CB-4664-A2F0-F29CA1281694/UniversalMac_13.0_22A5295h_Restore.ipsw";
    hash = "sha256-LbNHYPVKVKpwXUmqZInQ1Nr9gaYni4IKjelvzpl72LI=";
  };

  "13.0b3 (22A5295i)" = fetchurl {
    name = "UniversalMac_13.0_22A5295i_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerSeed/fullrestores/012-38309/6EDC76A0-4432-4C64-83C5-F43C885A75D6/UniversalMac_13.0_22A5295i_Restore.ipsw";
    hash = "sha256-0V/qRmbpKS9895jX4gykwnE3gYbuJMp/FCdoYP734wg=";
  };

  "13.0b4" = fetchurl {
    name = "UniversalMac_13.0_22A5311f_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerSeed/fullrestores/012-43316/6CE4D83A-E44C-4DD1-B47F-DE168355662E/UniversalMac_13.0_22A5311f_Restore.ipsw";
    hash = "sha256-KcER556MLoEm9rw0ZuC3UKajSWjMFyyu+cRGEa2gI8g=";
  };

  "13.0b5" = fetchurl {
    name = "UniversalMac_13.0_22A5321d_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerSeed/fullrestores/012-51397/8EF0874D-388A-4F62-B58A-89F968DD3082/UniversalMac_13.0_22A5321d_Restore.ipsw";
    hash = "sha256-Qm0nDpcyhRgYMC4ubBXKMPH92Ba+/JEAMYySRj6YxMg=";
  };

  "13.0b6" = fetchurl {
    name = "UniversalMac_13.0_22A5331f_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerSeed/fullrestores/012-61458/80300AD0-69E5-4429-AE3E-A936CA83B5FC/UniversalMac_13.0_22A5331f_Restore.ipsw";
    hash = "sha256-etUkffhqcsud2hhR2d2Ode3HToUMrNHD6RvBvIsN5mg=";
  };

  "13.0b7" = fetchurl {
    name = "UniversalMac_13.0_22A5342f_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerSeed/fullrestores/012-66750/108EF06D-FBEE-4910-BA83-56A5C9B54110/UniversalMac_13.0_22A5342f_Restore.ipsw";
    hash = "sha256-c88dvRAtVvcw8cwxDy3VqiXnPHPAlMIQVoRASL3YYKk=";
  };

  "13.0b8" = fetchurl {
    name = "UniversalMac_13.0_22A5352e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerSeed/fullrestores/012-70113/6F1F08B7-9A1B-48A9-93DB-55EE21121C87/UniversalMac_13.0_22A5352e_Restore.ipsw";
    hash = "sha256-stKXohQRAojbpLQQcvesmipivpLvG0luURGNXc4uncU=";
  };

  "13.0b9" = fetchurl {
    name = "UniversalMac_13.0_22A5358e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerSeed/fullrestores/012-71790/AF5A04A6-FF20-44C1-9BFF-43081BDB4D8C/UniversalMac_13.0_22A5358e_Restore.ipsw";
    hash = "sha256-DV/E3WyawFJTJ6jbIiNdusZqrI8J8q7v0QyTL97m1Sg=";
  };

  "13.0b10" = fetchurl {
    name = "UniversalMac_13.0_22A5365d_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerSeed/fullrestores/012-83054/16ECAA12-3A1B-4663-B49B-B1563ECD4314/UniversalMac_13.0_22A5365d_Restore.ipsw";
    hash = "sha256-nfWXOgiFgEAfXIgouLFTsNeGAtGfOrn/5geG3Qpxjt0=";
  };

  "13.0b11" = fetchurl {
    name = "UniversalMac_13.0_22A5373b_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022SummerSeed/fullrestores/012-84563/2FC38C63-3213-4BB6-8E41-2B066332CBE6/UniversalMac_13.0_22A5373b_Restore.ipsw";
    hash = "sha256-VRE4ZVgk1sFmH4xqBgQPLZ1V+uBqyrhENUHbf526PgY=";
  };

  "13.0rc1" = fetchurl {
    name = "UniversalMac_13.0_22A379_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallFCS/fullrestores/071-08994/1118ADF4-1CC9-4554-9333-B1F64CF0C820/UniversalMac_13.0_22A379_Restore.ipsw";
    hash = "sha256-1mWHFt/bzk0/yyE5aO79abkjhHEnkWL6hC4J03QRxkc=";
  };

  "13.1b1" = fetchurl {
    name = "UniversalMac_13.1_22C5033e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallSeed/fullrestores/012-82062/10E6B723-51B8-4B2C-BA3B-12A18ED4E719/UniversalMac_13.1_22C5033e_Restore.ipsw";
    hash = "sha256-wpVJLiDvvYWxi/eUoV0fcQBJ/AFnq9gh8xex4X8mHI0=";
  };

  "13.1b2" = fetchurl {
    name = "UniversalMac_13.1_22C5044e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallSeed/fullrestores/032-02019/670C9BA6-67EB-4AE6-A02E-88976F6F3118/UniversalMac_13.1_22C5044e_Restore.ipsw";
    hash = "sha256-QlMUsWk5mHtz8VnwHlnGy/vnLAaIJOKF9HF4nBs9i8I=";
  };

  "13.1b3" = fetchurl {
    name = "UniversalMac_13.1_22C5050e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallSeed/fullrestores/032-06252/946CBF92-8F27-49B1-A692-81F54C73D2F0/UniversalMac_13.1_22C5050e_Restore.ipsw";
    hash = "sha256-y9ZIejk2Zst/1KwYTRZ68jKS0iTGZ2Zu+U1PFZhqftk=";
  };

  "13.1b4" = fetchurl {
    name = "UniversalMac_13.1_22C5059b_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2022FallSeed/fullrestores/032-08112/957EA73A-7C95-4B3C-B99C-2C2C47555832/UniversalMac_13.1_22C5059b_Restore.ipsw";
    hash = "sha256-6wQVedVUfWjj60eJJgZFgP3lOILsAiIC2swhKcJxKn4=";
  };

  "13.2b1" = fetchurl {
    name = "UniversalMac_13.2_22D5027d_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023WinterSeed/fullrestores/032-12640/6B472BA3-E678-4251-92D1-7AA23B66F53E/UniversalMac_13.2_22D5027d_Restore.ipsw";
    hash = "sha256-qZMg/+rlTWeKkmIeW5kP2vYfNU15t6GElXkpvxgPWVQ=";
  };

  "13.2b2" = fetchurl {
    name = "UniversalMac_13.2_22D5038i_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023WinterSeed/fullrestores/032-33181/62ECE236-5806-4136-AD08-EDC026FD80A5/UniversalMac_13.2_22D5038i_Restore.ipsw";
    hash = "sha256-hW8M6uBCh6mTD+2Q7+OiB/UuKFK8FbEKj/0XeH0MbfE=";
  };

  "13.3b1" = fetchurl {
    name = "UniversalMac_13.3_22E5219e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023WinterSeed/fullrestores/032-01932/676E0981-4535-4942-A4AE-E14C604CE719/UniversalMac_13.3_22E5219e_Restore.ipsw";
    hash = "sha256-Oagbaroj5FSDc+0oP/+UlZIXPcj4wa+zyr8KDy13vU0=";
  };

  "13.3b2" = fetchurl {
    name = "UniversalMac_13.3_22E5230e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023WinterSeed/fullrestores/032-54760/AE02E378-FD59-474D-93AB-C52617103C72/UniversalMac_13.3_22E5230e_Restore.ipsw";
    hash = "sha256-08iLueGAXbjbKu07JqYKXagyKMZoTjlcfdjWCS8eysk=";
  };

  "13.3b3" = fetchurl {
    name = "UniversalMac_13.3_22E5236f_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023WinterSeed/fullrestores/032-60411/1DDA996F-B620-4770-8FFE-87AB2043784D/UniversalMac_13.3_22E5236f_Restore.ipsw";
    hash = "sha256-PVsd6mXMPDXAr7kj67qzGnp426AgCm5JqrsxfHMO+hM=";
  };

  "13.3b4" = fetchurl {
    name = "UniversalMac_13.3_22E5246b_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023WinterSeed/fullrestores/032-63669/7C0F9BA8-35C0-457F-AF56-6943D58A2CDB/UniversalMac_13.3_22E5246b_Restore.ipsw";
    hash = "sha256-7rPfsg6CxIsZl7B012EwrV5fq6QY2PZPIsyWbT3sy40=";
  };

  "13.4b1" = fetchurl {
    name = "UniversalMac_13.4_22F5027f_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringSeed/fullrestores/032-69187/B11709E0-1CF5-4460-A069-D12E1243E2AD/UniversalMac_13.4_22F5027f_Restore.ipsw";
    hash = "sha256-ZI7tCIbLXKfDLPtniSrb0dkurzZqhbLM5Ccf869vJbs=";
  };

  "13.4b2" = fetchurl {
    name = "UniversalMac_13.4_22F5037d_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringSeed/fullrestores/032-69885/ECFA1532-C633-4ACE-9D2C-3B5FD19510D4/UniversalMac_13.4_22F5037d_Restore.ipsw";
    hash = "sha256-NsP4lzPu89CTBiIUDa7MaZap4pObbCb7Bky+qORYpmM=";
  };

  "13.4b3" = fetchurl {
    name = "UniversalMac_13.4_22F5049e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringSeed/fullrestores/032-76661/573284E7-4A4A-440C-AC01-6065C7A8E667/UniversalMac_13.4_22F5049e_Restore.ipsw";
    hash = "sha256-1V9d90PgVU80HzF7aXXhVSJnX4zjOOl7yDHquvlEqno=";
  };

  "13.4b4" = fetchurl {
    name = "UniversalMac_13.4_22F5059b_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringSeed/fullrestores/032-79565/BA9CBFB7-152C-4FB6-B0B3-47769997BFA1/UniversalMac_13.4_22F5059b_Restore.ipsw";
    hash = "sha256-W7c3BIQcFQD+RdgEnjAn/tvSK2LylyqZRpYD2ZlT5b8=";
  };

  "13.4rc1" = fetchurl {
    name = "UniversalMac_13.4_22F62_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringFCS/fullrestores/032-44024/731F1533-53BE-4CEB-AA05-74F333CA904A/UniversalMac_13.4_22F62_Restore.ipsw";
    hash = "sha256-5oeroNSN6DX8ViVZGTUzGh9rPE8GdF7/7AMLx1FOQbM=";
  };

  "13.4rc2" = fetchurl {
    name = "UniversalMac_13.4_22F63_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringFCS/fullrestores/032-83954/6E06237C-1B56-4932-A8E1-3A07A3EE03A8/UniversalMac_13.4_22F63_Restore.ipsw";
    hash = "sha256-z9XMRmiAtfgFnw1sDOZ+gjFqySMzij9vlCQFLyZl1Hk=";
  };

  # Was actually in the release channel but I think it fits here better
  "13.4.1 (WWDC23 M2 Macs)" = fetchurl {
    name = "UniversalMac_13.4.1_22F2083_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringFCS/fullrestores/042-01864/A8378F91-BA71-40DF-8F0D-606A16F1836B/UniversalMac_13.4.1_22F2083_Restore.ipsw";
    hash = "sha256-67s3efxolHWJRYlXLCKHr7ZA0FO+gneKUPTOwljXhBs=";
  };

  "13.5b1" = fetchurl {
    name = "UniversalMac_13.5_22G5027e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringSeed/fullrestores/032-86178/CE6C5645-C5C3-41A9-B986-D5F0BD7BB10B/UniversalMac_13.5_22G5027e_Restore.ipsw";
    hash = "sha256-XmJ+j6pvTZodqO/Cvx2QLcl43O6+FJBKz5atOaK459Y=";
  };

  "13.5b2" = fetchurl {
    name = "UniversalMac_13.5_22G5038d_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringSeed/fullrestores/032-92523/E476F5EC-D046-4A76-889B-F19DA354459E/UniversalMac_13.5_22G5038d_Restore.ipsw";
    hash = "sha256-3PohpMoQX46m10C/H+UPt2HzQRTTiZQ8T39oLPW38vs=";
  };

  "13.5b3" = fetchurl {
    name = "UniversalMac_13.5_22G5048d_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringSeed/fullrestores/032-93679/1D39F2AC-8FD4-46A3-A159-478C76472B16/UniversalMac_13.5_22G5048d_Restore.ipsw";
    hash = "sha256-9v0sJNI9WyRXbLooLc/swjgssBaNHVLz+TLr6LSrhUk=";
  };

  "13.5b4" = fetchurl {
    name = "UniversalMac_13.5_22G5059d_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringSeed/fullrestores/042-03209/55CBE04D-FD90-483B-A6D7-45E0FBC1C94F/UniversalMac_13.5_22G5059d_Restore.ipsw";
    hash = "sha256-b0KWmAvWoHuIjNt9R9hrSj4bWbhTtCN2aMPIN/eGVQ4=";
  };

  "13.5b5" = fetchurl {
    name = "UniversalMac_13.5_22G5072a_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SpringSeed/fullrestores/042-09570/8DA0B0AA-6FD4-42C4-A54E-BC0D53B92AC0/UniversalMac_13.5_22G5072a_Restore.ipsw";
    hash = "sha256-YQjEilnurIVhSwHSeMGHcDtWDMQfB2MPprwfyQZHLZM=";
  };

  "14.0b1" = fetchurl {
    name = "UniversalMac_14.0_23A5257q_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SummerSeed/fullrestores/032-94355/CBE8CBE1-750D-487E-A393-B90FEF60CEBA/UniversalMac_14.0_23A5257q_Restore.ipsw";
    hash = "sha256-+81gI6uvp/Ru2XMRlYZh9QNYpPKSApHQFPcoScd2Pqs=";
  };

  "14.0b2" = fetchurl {
    name = "UniversalMac_14.0_23A5276g_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SummerSeed/fullrestores/032-95861/67600C59-8516-4A46-B9D7-4007D395CEF5/UniversalMac_14.0_23A5276g_Restore.ipsw";
    hash = "sha256-q9WWcgfNkgKNrIPMExmzwZNZIFXdlqrg3WT1inxLLBA=";
  };

  "14.0b3" = fetchurl {
    name = "UniversalMac_14.0_23A5286g_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SummerSeed/fullrestores/042-06324/379026FA-C14F-4095-99FD-19F607D10EBF/UniversalMac_14.0_23A5286g_Restore.ipsw";
    hash = "sha256-vVHCrkrvNgehNWGnnXUwF1n9tJcb1wuifQi4i8BsD5A=";
  };

  "14.0b3 (23A5286i)" = fetchurl {
    name = "UniversalMac_14.0_23A5286i_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SummerSeed/fullrestores/042-13887/3B4075C1-B695-49EA-82D9-4B720699D341/UniversalMac_14.0_23A5286i_Restore.ipsw";
    hash = "sha256-O97KjU8hkPVoY9VeEPhsWs5dWTh3OaFNrrDrlNcTGCs=";
  };

  "14.0b4" = fetchurl {
    name = "UniversalMac_14.0_23A5301h_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SummerSeed/fullrestores/042-25548/9EA6EC3D-5A7D-4D53-A17C-70EE71393921/UniversalMac_14.0_23A5301h_Restore.ipsw";
    hash = "sha256-B6smMQU50hv7V7/cSvT6RmOPquSXdwX9BxQqKdirLHo=";
  };

  "14.0b5" = fetchurl {
    name = "UniversalMac_14.0_23A5312d_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SummerSeed/fullrestores/042-27168/7E046825-8EBA-4AAE-8ECC-DDD51B9306D2/UniversalMac_14.0_23A5312d_Restore.ipsw";
    hash = "sha256-hx1/xFpCwo1+KC52OtMtDFxlLHIWHetrk4NDw0kUP9s=";
  };

  "14.0b6" = fetchurl {
    name = "UniversalMac_14.0_23A5328b_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SummerSeed/fullrestores/042-37824/AA6B32A0-3C2C-4BEB-95A1-64E601934330/UniversalMac_14.0_23A5328b_Restore.ipsw";
    hash = "sha256-MDOpUQewfU25Ns50RvZNUWwd9FaNjl3uBkbbOMqCn8A=";
  };

  "14.0b7" = fetchurl {
    name = "UniversalMac_14.0_23A5337a_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023SummerSeed/fullrestores/042-41500/D1789AEF-013B-4112-8A1E-401589023267/UniversalMac_14.0_23A5337a_Restore.ipsw";
    hash = "sha256-UVBDbNQ0rtkjwUkgktcTm8jkweGNfzrOYTSvQ9yMNoc=";
  };

  "14.0rc1" = fetchurl {
    name = "UniversalMac_14.0_23A339_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallFCS/fullrestores/002-81996/596571C1-9856-4BB3-B5BF-B5A48F4B406E/UniversalMac_14.0_23A339_Restore.ipsw";
    hash = "sha256-JjUOHbqJOI3TkEbVc8pqikNjr+gkoQhG2fbaKZ4dLf4=";
  };

  "14.1b1" = fetchurl {
    name = "UniversalMac_14.1_23B5046f_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallSeed/fullrestores/042-60177/C4B6F5B3-8B66-461A-A048-4A9925F36FCD/UniversalMac_14.1_23B5046f_Restore.ipsw";
    hash = "sha256-nGU5Jfpa0VVv3aYk97M3bhmRRNa8rS07EQxBMoiQh3U=";
  };

  "14.1b2" = fetchurl {
    name = "UniversalMac_14.1_23B5056e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallSeed/fullrestores/042-65885/0FA6C4A7-C21A-4A5F-84C8-8FEE0D98A153/UniversalMac_14.1_23B5056e_Restore.ipsw";
    hash = "sha256-Xs55AzexOAs/201gFGOeidXN7Xlju0bAF0oiiv4G/Jc=";
  };

  "14.1b3" = fetchurl {
    name = "UniversalMac_14.1_23B5067a_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallSeed/fullrestores/042-73325/B24FC9CF-34D1-44A6-B977-FA718FE83DEB/UniversalMac_14.1_23B5067a_Restore.ipsw";
    hash = "sha256-V+ZrkrBKCH0gqji5Usw/xN8T+RpZdNvkDFCnWTauAaU=";
  };

  "14.1rc1" = fetchurl {
    name = "UniversalMac_14.1_23B73_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallFCS/fullrestores/042-10900/347B734E-BC0B-41FA-9671-8000FCB5B0BB/UniversalMac_14.1_23B73_Restore.ipsw";
    hash = "sha256-nZGVpR+0VzPHeHZLoU4dZ8Q5gSUbpqeVt5pgJvzuMco=";
  };

  "14.2b1" = fetchurl {
    name = "UniversalMac_14.2_23C5030f_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallSeed/fullrestores/042-71093/ECEFE157-E28B-40B4-9F21-CFD075129029/UniversalMac_14.2_23C5030f_Restore.ipsw";
    hash = "sha256-AOU19qgCjWJi5Zi2N0xVNYHzdhS/z+i4pndqubQWEME=";
  };

  "14.2b2" = fetchurl {
    name = "UniversalMac_14.2_23C5041e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallSeed/fullrestores/042-92143/F642F928-DEE0-4C3F-A416-85745C778855/UniversalMac_14.2_23C5041e_Restore.ipsw";
    hash = "sha256-mMhPpETzF1AQRm0tfMNwyn6czs22DxNYYftxDPZYlnA=";
  };

  "14.2b3" = fetchurl {
    name = "UniversalMac_14.2_23C5047e_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallSeed/fullrestores/042-99526/0A9085CC-B36A-400A-86D8-B9FE23B1DA29/UniversalMac_14.2_23C5047e_Restore.ipsw";
    hash = "sha256-bhQzFlM2DejjkeFs9nlTsdPIn4ntVmx1GcWw7Cjg3m0=";
  };

  "14.2b4" = fetchurl {
    name = "UniversalMac_14.2_23C5055b_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023WinterFCS/fullrestores/052-05962/A8344C85-06CE-43C7-9FF6-7B477A4DB8BA/UniversalMac_14.2_23C5055b_Restore.ipsw";
    hash = "sha256-TLdLTiIkVeiogxGD4+/jxhiQFsjpufNsEnXlX+Blhkc=";
  };

  "14.2rc1" = fetchurl {
    name = "UniversalMac_14.2_23C63_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023FallFCS/fullrestores/052-14744/7215DBB4-BEAD-4A9C-9202-276ABA6832D5/UniversalMac_14.2_23C63_Restore.ipsw";
    hash = "sha256-knjCuw4ib94IgvQxbAh3mShq3PHceaDV7hUoVlmn4B0=";
  };

  "14.3b1" = fetchurl {
    name = "UniversalMac_14.3_23D5033f_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023WinterSeed/fullrestores/052-04657/4126C431-B3EA-42C2-BC36-ED83715B8700/UniversalMac_14.3_23D5033f_Restore.ipsw";
    hash = "sha256-IYMDLuuYMSkXvPigERasaWdBCz/Sw4CPBurrFLMMuyo=";
  };

  "14.3b2" = fetchurl {
    name = "UniversalMac_14.3_23D5043d_Restore.ipsw";
    url = "https://updates.cdn-apple.com/2023WinterSeed/fullrestores/052-23267/60655998-DD9A-40BF-BFAB-6D2A4442DE83/UniversalMac_14.3_23D5043d_Restore.ipsw";
    hash = "sha256-fxrABSY7yqGu64zoS+YIn1XbCH7jBKUfs62Fh3dI3RY=";
  };
}
