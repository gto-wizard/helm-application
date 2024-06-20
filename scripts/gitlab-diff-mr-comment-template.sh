#!/bin/sh

set -euo pipefail

ENVIRONMENT=$1
DIFF=$2

#define the template.
cat  << EOF
<details>
<summary>

$ENVIRONMENT Changes:

</summary>

\`\`\`diff
$DIFF
\`\`\`

</details>
EOF
