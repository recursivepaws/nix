{
  den.aspects.hightouch = {
    homeManager =
      { pkgs, lib, ... }:
      let
        extractSlackTokens = pkgs.writeShellApplication {
          name = "extract-slack-tokens";
          runtimeInputs = with pkgs; [
            sqlite
            openssl
            binutils
          ];
          text = ''
            cookies_db="$HOME/.config/Slack/Cookies"
            ldb_dir="$HOME/.config/Slack/Local Storage/leveldb"

            # --- xoxd ---
            tmp=$(mktemp --suffix=.db)
            cp "$cookies_db" "$tmp"

            value=$(sqlite3 "$tmp" "SELECT value FROM cookies WHERE name='d' AND host_key LIKE '%.slack.com';" | head -1)
            enc_hex=$(sqlite3 "$tmp" "SELECT hex(encrypted_value) FROM cookies WHERE name='d' AND host_key LIKE '%.slack.com';" | head -1)
            rm -f "$tmp"

            if [[ -n "$value" ]]; then
              xoxd="$value"
            elif [[ -n "$enc_hex" ]]; then
              # PBKDF2-HMAC-SHA1("peanuts","saltysalt",1,16)
              # 1 iteration => key = HMAC-SHA1(key="peanuts", data="saltysalt\x00\x00\x00\x01")[0:16]
              key_hex=$(printf 'saltysalt\x00\x00\x00\x01' |
                openssl dgst -sha1 -hmac 'peanuts' -binary |
                od -A n -t x1 | tr -d ' \n' |
                cut -c1-32)

              # Strip 3-byte v10 prefix (6 hex chars), write cipher to temp file,
              # decrypt (openssl strips PKCS7 padding). IV = 16 space bytes (0x20).
              cipher_bin=$(mktemp)
              decrypted_bin=$(mktemp)
              printf '%b' "$(printf '%s' "''${enc_hex:6}" | sed 's/../\\x&/g')" >"$cipher_bin"
              openssl enc -aes-128-cbc -d \
                -K "$key_hex" \
                -iv '20202020202020202020202020202020' \
                -in "$cipher_bin" >"$decrypted_bin" 2>/dev/null
              rm -f "$cipher_bin"

              # Cookie value is URL-encoded (+ -> %2B, / -> %2F, etc.)
              # Extract the URL-encoded token, then decode %XX sequences.
              url_encoded=$(grep -ao 'xoxd-[A-Za-z0-9%_-]*' <"$decrypted_bin")
              xoxd=$(printf '%b' "''${url_encoded//%/\\x}")
              rm -f "$decrypted_bin"
            fi

            # --- xoxc ---
            xoxc=$(strings "$ldb_dir"/*.ldb | grep -o 'xoxc-[A-Za-z0-9_-]*' | head -1)
            printf 'export SLACK_MCP_XOXC_TOKEN="%s"\nexport SLACK_MCP_XOXD_TOKEN="%s"\n' "$xoxc" "$xoxd"
          '';
        };
        slackHook = pkgs.writeShellScript "claude-hook-slack" ''
          if command -v extract-slack-tokens >/dev/null 2>&1; then
            eval "$(extract-slack-tokens)"
            echo "info: extracted slack tokens"
          else
            echo "warning: extract-slack-tokens is unavailable; slack mcp might not work"
          fi
        '';
      in
      {
        home.packages = with pkgs; [
          slack
          extractSlackTokens
        ];

        programs.zsh.initContent = lib.mkOrder 950 ''
          _claude_pre_hooks+=(${slackHook})
        '';
      };
  };
}
