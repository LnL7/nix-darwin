{ pkgs
, options
, config
, version
, revision
, nixpkgsRevision
, extraSources ? []
, prefix ? ../..
}:

with pkgs;

let
  lib = pkgs.lib;

  optionsDoc = buildPackages.nixosOptionsDoc {
    inherit options revision;
    transformOptions = opt: opt // {
      # Clean up declaration sites to not refer to the nix-darwin source tree.
      # TODO: handle `extraSources`? (it's not set anywhere)
      declarations = map
        (decl:
          if lib.hasPrefix (toString prefix) (toString decl) then
            let
              subpath = lib.removePrefix "/"
                (lib.removePrefix (toString prefix) (toString decl));
            in {
              url = "https://github.com/LnL7/nix-darwin/blob/${revision}/${subpath}";
              name = "<nix-darwin/${subpath}>";
            }
          # TODO: handle this in a better way (may require upstream
          # changes to nixpkgs)
          else if decl == "lib/modules.nix" then
            {
              url = "https://github.com/NixOS/nixpkgs/blob/${nixpkgsRevision}/${decl}";
              name = "<nixpkgs/${decl}>";
            }
          else decl)
        opt.declarations;
    };
  };

  sources = lib.sourceFilesBySuffices ./. [".xml"];

  modulesDoc = builtins.toFile "modules.xml" ''
    <section xmlns:xi="http://www.w3.org/2001/XInclude" id="modules">
    ${(lib.concatMapStrings (path: ''
      <xi:include href="${path}" />
    '') (lib.catAttrs "value" (config.meta.doc or [])))}
    </section>
  '';

  generatedSources = runCommand "generated-docbook" {} ''
    mkdir $out
    ln -s ${modulesDoc} $out/modules.xml
    ln -s ${optionsDoc.optionsDocBook} $out/options-db.xml
    printf "%s" "${version}" > $out/version
  '';

  copySources =
    ''
      cp -prd $sources/* . || true
      ln -s ${generatedSources} ./generated
      chmod -R u+w .
    '';

  toc = builtins.toFile "toc.xml"
    ''
      <toc role="chunk-toc">
        <d:tocentry xmlns:d="http://docbook.org/ns/docbook" linkend="book-darwin-manual"><?dbhtml filename="index.html"?>
          <d:tocentry linkend="ch-options"><?dbhtml filename="options.html"?></d:tocentry>
          <d:tocentry linkend="ch-release-notes"><?dbhtml filename="release-notes.html"?></d:tocentry>
        </d:tocentry>
      </toc>
    '';

  manualXsltprocOptions = toString [
    "--param section.autolabel 1"
    "--param section.label.includes.component.label 1"
    "--stringparam html.stylesheet 'style.css overrides.css highlightjs/mono-blue.css'"
    "--stringparam html.script './highlightjs/highlight.pack.js ./highlightjs/loader.js'"
    "--param xref.with.number.and.title 1"
    "--param toc.section.depth 3"
    "--stringparam admon.style ''"
    "--stringparam callout.graphics.extension .svg"
    "--stringparam current.docid manual"
    "--param chunk.section.depth 0"
    "--param chunk.first.sections 1"
    "--param use.id.as.filename 1"
    "--stringparam generate.toc 'book toc appendix toc'"
    "--stringparam chunk.toc ${toc}"
  ];

  manual-combined = runCommand "darwin-manual-combined"
    { inherit sources;
      nativeBuildInputs = [ buildPackages.libxml2.bin buildPackages.libxslt.bin ];
      meta.description = "The NixOS manual as plain docbook XML";
    }
    ''
      ${copySources}

      xmllint --xinclude --output ./manual-combined.xml ./manual.xml
      xmllint --xinclude --noxincludenode \
         --output ./man-pages-combined.xml ./man-pages.xml

      # outputs the context of an xmllint error output
      # LEN lines around the failing line are printed
      function context {
        # length of context
        local LEN=6
        # lines to print before error line
        local BEFORE=4

        # xmllint output lines are:
        # file.xml:1234: there was an error on line 1234
        while IFS=':' read -r file line rest; do
          echo
          if [[ -n "$rest" ]]; then
            echo "$file:$line:$rest"
            local FROM=$(($line>$BEFORE ? $line - $BEFORE : 1))
            # number lines & filter context
            nl --body-numbering=a "$file" | sed -n "$FROM,+$LEN p"
          else
            if [[ -n "$line" ]]; then
              echo "$file:$line"
            else
              echo "$file"
            fi
          fi
        done
      }

      function lintrng {
        xmllint --debug --noout --nonet \
          --relaxng ${docbook5}/xml/rng/docbook/docbook.rng \
          "$1" \
          2>&1 | context 1>&2
          # ^ redirect assumes xmllint doesn’t print to stdout
      }

      lintrng manual-combined.xml
      lintrng man-pages-combined.xml

      mkdir $out
      cp manual-combined.xml $out/
      cp man-pages-combined.xml $out/
    '';

  olinkDB = runCommand "manual-olinkdb"
    { inherit sources;
      nativeBuildInputs = [ buildPackages.libxml2.bin buildPackages.libxslt.bin ];
    }
    ''
      xsltproc \
        ${manualXsltprocOptions} \
        --stringparam collect.xref.targets only \
        --stringparam targets.filename "$out/manual.db" \
        --nonet \
        ${docbook_xsl_ns}/xml/xsl/docbook/xhtml/chunktoc.xsl \
        ${manual-combined}/manual-combined.xml

      cat > "$out/olinkdb.xml" <<EOF
      <?xml version="1.0" encoding="utf-8"?>
      <!DOCTYPE targetset SYSTEM
        "file://${docbook_xsl_ns}/xml/xsl/docbook/common/targetdatabase.dtd" [
        <!ENTITY manualtargets SYSTEM "file://$out/manual.db">
      ]>
      <targetset>
        <targetsetinfo>
            Allows for cross-referencing olinks between the manpages
            and manual.
        </targetsetinfo>

        <document targetdoc="manual">&manualtargets;</document>
      </targetset>
      EOF
    '';

in rec {
  inherit generatedSources;

  # TODO: Use `optionsDoc.optionsJSON` directly once upstream
  # `nixosOptionsDoc` is more customizable.
  optionsJSON = runCommand "options.json"
    { meta.description = "List of nix-darwin options in JSON format"; }
    ''
      mkdir -p $out/{share/doc,nix-support}
      cp -a ${optionsDoc.optionsJSON}/share/doc/nixos $out/share/doc/darwin
      substitute \
        ${optionsDoc.optionsJSON}/nix-support/hydra-build-products \
        $out/nix-support/hydra-build-products \
        --replace \
          '${optionsDoc.optionsJSON}/share/doc/nixos' \
          "$out/share/doc/darwin"
    '';

  # Generate the NixOS manual.
  manualHTML = runCommand "darwin-manual-html"
    { inherit sources;
      nativeBuildInputs = [ buildPackages.libxml2.bin buildPackages.libxslt.bin ];
      meta.description = "The Darwin manual in HTML format";
      allowedReferences = ["out"];
    }
    ''
      # Generate the HTML manual.
      dst=$out/share/doc/darwin
      mkdir -p $dst
      xsltproc \
        ${manualXsltprocOptions} \
        --stringparam target.database.document "${olinkDB}/olinkdb.xml" \
        --stringparam id.warnings "1" \
        --nonet --output $dst/ \
        ${docbook_xsl_ns}/xml/xsl/docbook/xhtml/chunktoc.xsl \
        ${manual-combined}/manual-combined.xml \
        |& tee xsltproc.out
      grep "^ID recommended on" xsltproc.out &>/dev/null && echo "error: some IDs are missing" && false
      rm xsltproc.out

      mkdir -p $dst/images/callouts
      cp ${docbook_xsl_ns}/xml/xsl/docbook/images/callouts/*.svg $dst/images/callouts/

      cp ${./style.css} $dst/style.css
      cp ${./overrides.css} $dst/overrides.css
      cp -r ${pkgs.documentation-highlighter} $dst/highlightjs

      mkdir -p $out/nix-support
      echo "nix-build out $out" >> $out/nix-support/hydra-build-products
      echo "doc manual $dst" >> $out/nix-support/hydra-build-products
    ''; # */

  # Alias for backward compatibility. TODO(@oxij): remove eventually.
  manual = manualHTML;

  # Index page of the NixOS manual.
  manualHTMLIndex = "${manualHTML}/share/doc/darwin/index.html";

  manualEpub = runCommand "darwin-manual-epub"
    { inherit sources;
      buildInputs = [ libxml2.bin libxslt.bin zip ];
    }
    ''
      # Generate the epub manual.
      dst=$out/share/doc/darwin

      xsltproc \
        ${manualXsltprocOptions} \
        --stringparam target.database.document "${olinkDB}/olinkdb.xml" \
        --nonet --xinclude --output $dst/epub/ \
        ${docbook_xsl_ns}/xml/xsl/docbook/epub/docbook.xsl \
        ${manual-combined}/manual-combined.xml

      mkdir -p $dst/epub/OEBPS/images/callouts
      cp -r ${docbook_xsl_ns}/xml/xsl/docbook/images/callouts/*.svg $dst/epub/OEBPS/images/callouts # */
      echo "application/epub+zip" > mimetype
      manual="$dst/darwin-manual.epub"
      zip -0Xq "$manual" mimetype
      cd $dst/epub && zip -Xr9D "$manual" *

      rm -rf $dst/epub

      mkdir -p $out/nix-support
      echo "doc-epub manual $manual" >> $out/nix-support/hydra-build-products
    '';


  # Generate the NixOS manpages.
  manpages = runCommand "darwin-manpages"
    { inherit sources;
      nativeBuildInputs = [ buildPackages.libxml2.bin buildPackages.libxslt.bin ];
      allowedReferences = ["out"];
    }
    ''
      # Generate manpages.
      mkdir -p $out/share/man
      xsltproc --nonet \
        --maxdepth 6000 \
        --param man.output.in.separate.dir 1 \
        --param man.output.base.dir "'$out/share/man/'" \
        --param man.endnotes.are.numbered 0 \
        --param man.break.after.slash 1 \
        --stringparam target.database.document "${olinkDB}/olinkdb.xml" \
        ${docbook_xsl_ns}/xml/xsl/docbook/manpages/docbook.xsl \
        ${manual-combined}/man-pages-combined.xml
    '';

}
