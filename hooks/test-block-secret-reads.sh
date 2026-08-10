#!/bin/bash
# Synthetic-payload suite for block-secret-reads.sh (exit 2 = blocked, 0 = allowed)
# shellcheck disable=SC2016  # payloads are literal strings fed to the hook; expanding them breaks the test
H=${1:-$(cd "$(dirname "$0")" && pwd)/block-secret-reads.sh}
pass=0; fail=0
t(){ printf '%s' "$3" | "$H" >/dev/null 2>&1; r=$?
  if [[ "$r" == "$2" ]]; then s=PASS; ((pass++)); else s=FAIL; ((fail++)); fi
  echo "$s exp=$2 got=$r | $1"; }
b(){ t "$1" 2 "$(jq -nc --arg c "$2" '{tool_name:"Bash",tool_input:{command:$c}}')"; }
a(){ t "$1" 0 "$(jq -nc --arg c "$2" '{tool_name:"Bash",tool_input:{command:$c}}')"; }

echo "== Read/Grep: blocked =="
t "Read ~/.ssh/id_rsa"        2 '{"tool_name":"Read","tool_input":{"file_path":"/home/cong/.ssh/id_rsa"}}'
t "Read .env"                 2 '{"tool_name":"Read","tool_input":{"file_path":"/home/cong/proj/.env"}}'
t "Read .aws/credentials"     2 '{"tool_name":"Read","tool_input":{"file_path":"/home/cong/.aws/credentials"}}'
t "Read bare ~/.ssh"          2 '{"tool_name":"Read","tool_input":{"file_path":"/home/cong/.ssh"}}'
t "Grep bare ~/.ssh"          2 '{"tool_name":"Grep","tool_input":{"pattern":"x","path":"/home/cong/.ssh"}}'
t "Grep bare ~/.aws"          2 '{"tool_name":"Grep","tool_input":{"pattern":"x","path":"/home/cong/.aws"}}'
t "Grep bare ~/.kube"         2 '{"tool_name":"Grep","tool_input":{"pattern":"x","path":"/home/cong/.kube"}}'
t "Grep bare gcloud"          2 '{"tool_name":"Grep","tool_input":{"pattern":"x","path":"/home/cong/.config/gcloud"}}'
t "Grep ~/.ssh/ trailing"     2 '{"tool_name":"Grep","tool_input":{"pattern":"x","path":"/home/cong/.ssh/"}}'
t "Grep glob **/.env"         2 '{"tool_name":"Grep","tool_input":{"pattern":"x","glob":"**/.env"}}'

echo "== Read/Grep: allowed =="
t "Read .env.example"         0 '{"tool_name":"Read","tool_input":{"file_path":"/home/cong/proj/.env.example"}}'
t "Read main.py"              0 '{"tool_name":"Read","tool_input":{"file_path":"/home/cong/proj/main.py"}}'
t "Read tokenizer.json"       0 '{"tool_name":"Read","tool_input":{"file_path":"/home/cong/m/tokenizer.json"}}'
t "Grep ~/.config/nvim"       0 '{"tool_name":"Grep","tool_input":{"pattern":"x","path":"/home/cong/.config/nvim"}}'
t "Grep /home/cong/code"      0 '{"tool_name":"Grep","tool_input":{"pattern":"x","path":"/home/cong/code"}}'
t "Read ~/.sshrc-notes.md"    0 '{"tool_name":"Read","tool_input":{"file_path":"/home/cong/.sshrc-notes.md"}}'
t "Read ~/.awsome/x.py"       0 '{"tool_name":"Read","tool_input":{"file_path":"/home/cong/.awsome/x.py"}}'

echo "== Bash print verbs: blocked =="
b "cat .env"                  'cat .env'
b "cat ~/.aws/credentials"    'cat ~/.aws/credentials'
b "head -50 ~/.npmrc"         'head -50 ~/.npmrc'
b "base64 id_ed25519"         'base64 ~/.ssh/id_ed25519'

echo "== Bash print verbs: allowed =="
a "ls -la ~/.ssh"             'ls -la ~/.ssh'
a "vllm max-num-batched"      'vllm serve m --max-num-batched-tokens 8192'
a "echo TOKEN=x"              'echo TOKEN=abc >> notes.txt'
a "stat ~/.aws/credentials"   'stat ~/.aws/credentials'

echo "== Bash search verbs: blocked =="
b "grep -r AWS ~/.aws/creds"  'grep -r AWS ~/.aws/credentials'
b "grep API_KEY .env"         'grep API_KEY .env'
b "rg -n Host ~/.ssh/config"  'rg -n Host ~/.ssh/config'
b "grep foo ~/.aws"           'grep foo ~/.aws'
b "grep .env.local (P1-2)"    'grep PASSWORD .env.local'
b "grep .env.production"      'grep PASSWORD .env.production'
b "quoted \$HOME/.ssh (P1-3)" 'grep -R . "$HOME/.ssh"'
b "quoted .aws"               'grep -R . "$HOME/.aws"'
b "quoted alternation pattern" "rg 'PASSWORD|TOKEN' .env"
b "safe grep then leaking"    'grep -c ok safe.log; grep PASSWORD .env'
b "safe && leaking"           'grep -c ok safe.log && grep PASSWORD .env'
b "safe | leaking"            'grep -c ok safe.log | grep PASSWORD .env'
b "rg --color then leak"      'rg --color always foo src; rg PASSWORD .env'
b "mixed secret + template"   'grep PASSWORD .env .env.example'
b "command substitution"      'echo $(grep PASSWORD .env)'
b "subshell"                  '(grep PASSWORD .env)'
b "backtick substitution"     'echo `grep PASSWORD .env`'
b "absolute path grep"        '/usr/bin/grep PASSWORD .env'
b "trailing comment allowlist" 'grep PASSWORD .env # compare with .env.example'
b "two substitutions"         'echo "$(grep -c x .env)" "$(grep PASSWORD .env)"'
b "benign parent dir"         'grep KEY /tmp/tokenizer/.env'
b "rg --glob=.env"            'rg --glob=.env PASSWORD .'
b "grep --include=.env"       'grep -R --include=.env PASSWORD .'
b "rg --glob=*.env"           'rg --glob=*.env PASSWORD .'
b "comma-separated globs"     'rg --glob=.env,.envrc PASSWORD .'
b "rg --glob .ssh/*"          'rg --glob ".ssh/*" PRIVATE ~'
b "attached redirection"      'grep PASSWORD<.env'
b "spaced redirection"        'grep PASSWORD <.env'
b "direnv .envrc"             'grep PASSWORD .envrc'
b "underscore suffix"         'grep X .env_prod'
b "dotenv directory"          'grep -r X .env/'
b "brace expansion"           'grep PASSWORD .env{,.example}'
b "attached && operator"      'grep PASSWORD .env&&:'
b "attached ; operator"       'grep PASSWORD .env;:'
b "attached pipe"             'grep PASSWORD .env|cat'
b "verb with attached <"      'grep<pat PASSWORD .env'
b "verb with attached <<<"    'grep<<<ignored PASSWORD .env'
b "escaped .env"              'grep PASSWORD .e\nv'
b "escaped .netrc"            'grep KEY .n\etrc'
b "escaped ~/.aws path"       'grep KEY ~/.a\ws/credentials'
b "escaped cat target"        'cat .e\nv'
b "benign substring in name"  'grep KEY .env-tokenizer'
b "template-looking backup"   'grep KEY .env.example.backup'
t "Grep relative .ssh"        2 '{"tool_name":"Grep","tool_input":{"pattern":"x","path":".ssh"}}'
t "Grep relative .aws/"       2 '{"tool_name":"Grep","tool_input":{"pattern":"x","path":".aws/"}}'
t "Read relative .kube"       2 '{"tool_name":"Read","tool_input":{"file_path":".kube"}}'
# No flag escape hatch: an aggregate flag never exempts a credential target,
# because proving which invocation owns the flag needs a real shell parser.
b "-c on credential file"     'grep -c AWS ~/.aws/credentials'
b "-l on .env"                'grep -l KEY .env'
b "-q on .env"                'grep -q X .env && echo yes'
b "--count on .env"           'grep --count X .env'
b "-e consumes -c"            'grep -e -c .env'
b "clustered -ec"             'grep -ec .env'
b "literal -c pattern"        'grep -- -c .env'
# Accepted false positives — conservative by design, documented in the doc's
# False Positives section. Listed here so a future change cannot flip them silently.
b "FP: .env as pattern"       'grep .env README.md'
b "FP: example in a string"   "printf '%s' 'grep PASSWORD .env'"
b "FP: .env* prefix collision" 'grep -r x .environment/'

echo "== Bash search verbs: allowed =="
a "grep -i credential log"    'grep -i credential /var/log/app.log'
a "rg secret src/"            'rg secret src/'
a "grep token README.md"      'grep token README.md'
a "rg --color always foo src" 'rg --color always foo src'
a "grep X .env.example"       'grep X .env.example'
a "rg PASS .env.template"     'rg PASS .env.template'
a "quoted \$HOME/.env.example" 'grep X "$HOME/.env.example"'
a "grep X ./.env.sample"      'grep X ./.env.sample'

echo
echo "pass=$pass fail=$fail"
[[ $fail -eq 0 ]]
